//
//  SpeechRecognizer.swift
//  Recipes
//
//  Created by Eliott on 2025-12-31.
//

@preconcurrency import AVFoundation
import Foundation
import Speech
import SwiftUI

@Observable
final class SpeechRecognizer {
  // MARK: - State

  enum State: Equatable {
    case idle
    case checkingAvailability
    case downloadingModel(Progress)
    case ready
    case listening
    case processing
    case unsupported(reason: LocalizedStringKey)
    case error(LocalizedStringKey)

    var isListening: Bool {
      if case .listening = self { return true }
      return false
    }

    var canStartListening: Bool {
      if case .ready = self { return true }
      return false
    }

    var isSupported: Bool {
      if case .unsupported = self { return false }
      return true
    }
  }

  private(set) var state: State = .idle

  /// Real-time guesses (shown in lighter color while listening)
  private(set) var volatileText: AttributedString = ""

  /// Confirmed transcription text
  var finalizedText: String = ""

  /// Combined text for display
  var currentTranscription: String {
    finalizedText + String(volatileText.characters)
  }

  // MARK: - Private Properties

  private var transcriber: SpeechTranscriber?
  private var analyzer: SpeechAnalyzer?
  private var analyzerFormat: AVAudioFormat?
  private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
  private var inputSequence: AsyncStream<AnalyzerInput>?
  private var recognizerTask: Task<Void, Never>?

  // Audio engine is managed by AudioEngineController on a background thread
  private var audioEngineController: AudioEngineController?

  private let locale: Locale

  // MARK: - Init

  init(locale: Locale = .current) {
    self.locale = locale
  }

  // MARK: - Public Methods

  /// Check if speech recognition is available for the current locale
  func checkAvailability() async {
    state = .checkingAvailability

    // Check if SpeechTranscriber supports this locale
    let supportedLocales = await SpeechTranscriber.supportedLocales
    let isLocaleSupported = supportedLocales.contains { supported in
      supported.identifier(.bcp47) == locale.identifier(.bcp47)
    }

    guard isLocaleSupported else {
      let reason = "Speech recognition not supported for \(locale.identifier)"
      print("SpeechRecognizer: \(reason)")
      state = .unsupported(reason: .init(reason))
      return
    }

    // Check microphone permission
    let micPermission = AVAudioApplication.shared.recordPermission
    if micPermission == .denied {
      let reason = "Microphone permission denied"
      print("SpeechRecognizer: \(reason)")
      state = .unsupported(reason: .init(reason))
      return
    }

    // Try to set up the transcriber
    do {
      try await setupTranscriber()
      state = .ready
    } catch {
      print("SpeechRecognizer: Failed to setup - \(error.localizedDescription)")
      state = .unsupported(reason: .init(error.localizedDescription))
    }
  }

  /// Start listening for speech input
  func startListening() async {
    guard case .ready = state else {
      print("SpeechRecognizer: Cannot start listening - not in ready state")
      return
    }

    // Request microphone permission if needed
    let granted = await requestMicrophonePermission()
    guard granted else {
      state = .unsupported(reason: "Microphone permission denied")
      return
    }

    do {
      // Setup audio session
      try setupAudioSession()

      // Reset for new recording
      volatileText = ""

      // Setup fresh transcriber if needed
      if analyzer == nil {
        try await setupTranscriber()
      }

      // Start result handling
      startResultHandling()

      // Start audio engine on background thread
      guard let analyzerFormat, let inputBuilder else {
        throw SpeechRecognizerError.noAudioFormat
      }

      audioEngineController = try AudioEngineController.start(
        analyzerFormat: analyzerFormat,
        continuation: inputBuilder
      )

      state = .listening
    } catch {
      print("SpeechRecognizer: Failed to start listening - \(error.localizedDescription)")
      state = .error(.init(error.localizedDescription))
    }
  }

  /// Stop listening and finalize transcription
  func stopListening() async {
    guard case .listening = state else { return }

    state = .processing

    // Stop audio engine
    await audioEngineController?.stop()
    audioEngineController = nil

    // Finalize the transcription
    do {
      inputBuilder?.finish()
      try await analyzer?.finalizeAndFinishThroughEndOfInput()
    } catch {
      print("SpeechRecognizer: Error finalizing - \(error.localizedDescription)")
    }

    // Wait a moment for final results
    try? await Task.sleep(for: .milliseconds(500))

    // Append any remaining volatile text to finalized
    if !volatileText.characters.isEmpty {
      finalizedText += String(volatileText.characters)
      volatileText = ""
    }

    // Clean up
    recognizerTask?.cancel()
    recognizerTask = nil
    analyzer = nil
    transcriber = nil
    inputBuilder = nil
    inputSequence = nil

    state = .ready
  }

  /// Clear all transcription text
  func clearTranscription() {
    finalizedText = ""
    volatileText = ""
  }

  /// Toggle listening state
  func toggleListening() async {
    if state.isListening {
      await stopListening()
    } else {
      await startListening()
    }
  }

  // MARK: - Private Methods

  private func setupTranscriber() async throws {
    // Create transcriber with volatile results for real-time feedback
    transcriber = SpeechTranscriber(
      locale: locale,
      transcriptionOptions: [],
      reportingOptions: [.volatileResults],
      attributeOptions: []
    )

    guard let transcriber else {
      throw SpeechRecognizerError.failedToCreateTranscriber
    }

    // Create analyzer with transcriber module
    analyzer = SpeechAnalyzer(modules: [transcriber])

    // Get best audio format
    analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])

    // Ensure model is downloaded
    try await ensureModelDownloaded()

    // Create input stream
    (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()

    guard let inputSequence else { return }

    // Start analyzer
    try await analyzer?.start(inputSequence: inputSequence)
  }

  private func ensureModelDownloaded() async throws {
    guard let transcriber else { return }

    // Check if already installed
    let installedLocales = await SpeechTranscriber.installedLocales
    let isInstalled = installedLocales.contains { installed in
      installed.identifier(.bcp47) == locale.identifier(.bcp47)
    }

    if isInstalled {
      return
    }

    // Download model
    if let downloader = try await AssetInventory.assetInstallationRequest(supporting: [transcriber])
    {
      state = .downloadingModel(downloader.progress)
      try await downloader.downloadAndInstall()
    }
  }

  private func startResultHandling() {
    guard let transcriber else { return }

    recognizerTask = Task {
      do {
        for try await result in transcriber.results {
          if result.isFinal {
            // Append finalized text and clear volatile
            finalizedText += String(result.text.characters)
            volatileText = ""
          } else {
            // Update volatile text
            volatileText = result.text
          }
        }
      } catch {
        print("SpeechRecognizer: Result handling error - \(error.localizedDescription)")
      }
    }
  }

  private func setupAudioSession() throws {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.playAndRecord, mode: .spokenAudio)
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
  }

  private func requestMicrophonePermission() async -> Bool {
    let currentPermission = AVAudioApplication.shared.recordPermission

    switch currentPermission {
    case .granted:
      return true
    case .denied:
      return false
    case .undetermined:
      return await withCheckedContinuation { continuation in
        AVAudioApplication.requestRecordPermission { granted in
          continuation.resume(returning: granted)
        }
      }
    @unknown default:
      return false
    }
  }
}

// MARK: - Errors

enum SpeechRecognizerError: LocalizedError {
  case failedToCreateTranscriber
  case noAudioFormat
  case modelNotAvailable

  var errorDescription: String? {
    switch self {
    case .failedToCreateTranscriber:
      return "Failed to create speech transcriber"
    case .noAudioFormat:
      return "No audio format available"
    case .modelNotAvailable:
      return "Speech recognition model not available"
    }
  }
}
