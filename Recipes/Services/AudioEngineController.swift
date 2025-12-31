//
//  AudioEngineController.swift
//  Recipes
//
//  Created by Eliott on 2025-12-31.
//

@preconcurrency import AVFoundation
import Foundation
import Speech

/// Manages AVAudioEngine on a dedicated background thread to avoid MainActor dispatch issues
/// This class is intentionally not MainActor-isolated to allow audio operations on background threads
nonisolated final class AudioEngineController: @unchecked Sendable {
  private nonisolated(unsafe) let engine: AVAudioEngine
  private let converter: AVAudioConverter?

  private nonisolated init(engine: AVAudioEngine, converter: AVAudioConverter?) {
    self.engine = engine
    self.converter = converter
  }

  /// Start the audio engine on a background thread
  nonisolated static func start(
    analyzerFormat: AVAudioFormat,
    continuation: AsyncStream<AnalyzerInput>.Continuation
  ) throws -> AudioEngineController {
    let engine = AVAudioEngine()
    let inputNode = engine.inputNode
    let inputFormat = inputNode.outputFormat(forBus: 0)

    // Create converter if formats don't match
    var converter: AVAudioConverter?
    if inputFormat != analyzerFormat {
      converter = AVAudioConverter(from: inputFormat, to: analyzerFormat)
    }

    // Install tap on input node
    inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, _ in
      processAudioBuffer(
        buffer,
        converter: converter,
        targetFormat: analyzerFormat,
        continuation: continuation
      )
    }

    engine.prepare()
    try engine.start()

    let controller = AudioEngineController(engine: engine, converter: converter)
    return controller

  }

  /// Stop the audio engine
  nonisolated func stop() async {
    engine.inputNode.removeTap(onBus: 0)
    engine.stop()
  }

  private nonisolated static func processAudioBuffer(
    _ buffer: AVAudioPCMBuffer,
    converter: AVAudioConverter?,
    targetFormat: AVAudioFormat,
    continuation: AsyncStream<AnalyzerInput>.Continuation
  ) {
    let convertedBuffer: AVAudioPCMBuffer

    if let converter {
      // Convert buffer to analyzer format
      guard
        let outputBuffer = AVAudioPCMBuffer(
          pcmFormat: targetFormat,
          frameCapacity: AVAudioFrameCount(
            targetFormat.sampleRate * Double(buffer.frameLength) / buffer.format.sampleRate)
        )
      else { return }

      var error: NSError?
      let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
        outStatus.pointee = .haveData
        return buffer
      }

      guard status != .error, error == nil else {
        print(
          "SpeechRecognizer: Audio conversion error - \(error?.localizedDescription ?? "unknown")")
        return
      }

      convertedBuffer = outputBuffer
    } else {
      convertedBuffer = buffer
    }

    let input = AnalyzerInput(buffer: convertedBuffer)
    continuation.yield(input)
  }
}
