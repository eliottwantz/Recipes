//
//  IngredientFinderScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-12-31.
//

import SwiftUI

struct IngredientFinderScreen: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  @State private var speechRecognizer = SpeechRecognizer()
  @State private var ingredientsText: String = ""
  @State private var errorMessage: String?
  /// Tracks how much of finalizedText we've already appended to ingredientsText
  @State private var lastFinalizedLength: Int = 0

  @FocusState private var isTextEditorFocused: Bool

  private var hasIngredients: Bool {
    !ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// The text to display: base text + volatile text while listening
  private var displayText: String {
    if speechRecognizer.state.isListening && !speechRecognizer.volatileText.characters.isEmpty {
      return ingredientsText + String(speechRecognizer.volatileText.characters)
    }
    return ingredientsText
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          // Input Section
          VStack(alignment: .leading, spacing: 16) {
            Text("What ingredients do you have?")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)

            // Text Editor with live transcription
            ZStack(alignment: .topLeading) {
              // Editable TextEditor (disabled while recording)
              if !speechRecognizer.state.isListening {
                TextEditor(text: $ingredientsText)
                  .frame(minHeight: 120, maxHeight: 200)
                  .padding(8)
                  .scrollContentBackground(.hidden)
                  .focused($isTextEditorFocused)
              } else {
                // Non-editable text display while recording
                Text(displayText)
                  .font(.body)
                  .frame(
                    maxWidth: .infinity, minHeight: 120, maxHeight: 200, alignment: .topLeading
                  )
                  .padding(.horizontal, 12)
                  .padding(.vertical, 16)
              }

              // Placeholder text
              if ingredientsText.isEmpty && !speechRecognizer.state.isListening {
                Text("Tap the microphone to speak your ingredients, or type them here...")
                  .font(.body)
                  .foregroundStyle(.tertiary)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 16)
                  .allowsHitTesting(false)
              }
            }
            .background(Color(uiColor: .systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
              RoundedRectangle(cornerRadius: 10)
                .stroke(
                  speechRecognizer.state.isListening ? Color.red : Color(uiColor: .systemGray4),
                  lineWidth: speechRecognizer.state.isListening ? 2 : 1
                )
            )

            // Microphone Button
            HStack {
              Spacer()

              Button {
                Task {
                  if speechRecognizer.state.isListening {
                    await speechRecognizer.stopListening()
                    // Reset tracking for next recording session
                    lastFinalizedLength = 0
                    speechRecognizer.clearTranscription()
                  } else {
                    isTextEditorFocused = false
                    // Add space separator if needed before starting
                    if !ingredientsText.isEmpty
                      && !ingredientsText.hasSuffix(" ")
                      && !ingredientsText.hasSuffix("\n")
                    {
                      ingredientsText += " "
                    }
                    lastFinalizedLength = 0
                    await speechRecognizer.startListening()
                  }
                }
              } label: {
                ZStack {
                  Circle()
                    .fill(micButtonColor)
                    .frame(width: 72, height: 72)

                  if case .processing = speechRecognizer.state {
                    ProgressView()
                      .tint(.white)
                  } else if case .downloadingModel = speechRecognizer.state {
                    ProgressView()
                      .tint(.white)
                  } else {
                    Image(systemName: speechRecognizer.state.isListening ? "stop.fill" : "mic.fill")
                      .font(.system(size: 28))
                      .foregroundStyle(.white)
                  }
                }
                .shadow(color: micButtonColor.opacity(0.4), radius: 8, y: 4)
              }
              .disabled(!canToggleMic)
              .opacity(canToggleMic ? 1 : 0.5)
              .sensoryFeedback(.impact, trigger: speechRecognizer.state.isListening)

              Spacer()
            }

            // Status Text
            Text(statusText)
              .font(.caption)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .center)

            // Clear Button
            if hasIngredients || !ingredientsText.isEmpty {
              Button(role: .destructive) {
                ingredientsText = ""
                speechRecognizer.clearTranscription()
                lastFinalizedLength = 0
              } label: {
                Label("Clear all", systemImage: "xmark.circle")
                  .font(.subheadline)
              }
              .frame(maxWidth: .infinity, alignment: .center)
            }
          }
          .padding()
          .background(Color(uiColor: .systemBackground))

          Divider()

          // ChatGPT Section
          VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
              .font(.system(size: 48))
              .foregroundStyle(.accent)

            Text("Find recipes with ChatGPT")
              .font(.headline)

            Text("ChatGPT will search online for recipes using your ingredients")
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
              .padding(.horizontal)

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
              Button {
                openChatGPT()
              } label: {
                Label("Ask ChatGPT", systemImage: "bubble.left.and.bubble.right")
                  .padding(.vertical, 12)
                  .foregroundStyle(!hasIngredients ? .secondary : Color.accentContrasting)
              }
              .buttonStyle(.glassProminent)
              .buttonSizing(.flexible)
              .disabled(!hasIngredients)

              Button {
                copyPrompt()
              } label: {
                Label("Copy Prompt", systemImage: "doc.on.doc")
                  .padding(.vertical, 12)
              }
              .buttonStyle(.glass)
              .buttonSizing(.flexible)
              .disabled(!hasIngredients)
            }
            .padding(.horizontal)
            .padding(.bottom)
          }

          if let error = errorMessage {
            Text(error)
              .font(.caption)
              .foregroundStyle(.red)
              .padding(.horizontal)
              .padding(.bottom, 8)
          }
        }
        .navigationTitle("Find Recipes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
              dismiss()
            }
          }

          ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button {
              isTextEditorFocused = false
            } label: {
              Label("Dismiss keyboard", systemImage: "keyboard.chevron.compact.down")
                .labelStyle(.iconOnly)
            }
          }
        }
        .task {
          await speechRecognizer.checkAvailability()
        }
        // Stream finalized text into ingredientsText as it arrives
        .onChange(of: speechRecognizer.finalizedText) { oldValue, newValue in
          // Only append the new portion that we haven't seen yet
          let currentLength = newValue.count
          if currentLength > lastFinalizedLength {
            let startIndex = newValue.index(newValue.startIndex, offsetBy: lastFinalizedLength)
            let newPortion = String(newValue[startIndex...])
            ingredientsText += newPortion
            lastFinalizedLength = currentLength
          }
        }
      }
      .scrollIndicators(.hidden)
      .scrollBounceBehavior(.basedOnSize, axes: .vertical)
    }
    .toastPresenter()
  }

  // MARK: - Computed Properties

  private var micButtonColor: Color {
    if speechRecognizer.state.isListening {
      return .red
    } else if !speechRecognizer.state.isSupported {
      return .gray
    } else {
      return .accent
    }
  }

  private var canToggleMic: Bool {
    switch speechRecognizer.state {
    case .ready, .listening:
      return true
    case .idle, .checkingAvailability, .downloadingModel, .processing:
      return false
    case .unsupported, .error:
      return false
    }
  }

  private var statusText: LocalizedStringKey {
    switch speechRecognizer.state {
    case .idle, .checkingAvailability:
      return "Checking speech recognition availability..."
    case .downloadingModel(let progress):
      return "Downloading speech model: \(Int(progress.fractionCompleted * 100))%"
    case .ready:
      return "Tap the microphone to start speaking"
    case .listening:
      return "Listening... Tap to stop"
    case .processing:
      return "Processing..."
    case .unsupported(let reason):
      print("SpeechRecognizer unsupported: \(reason)")
      return "Voice input unavailable. Please type your ingredients."
    case .error(let message):
      print("SpeechRecognizer error: \(message)")
      return "Voice input error. Please type your ingredients."
    }
  }

  // MARK: - Actions

  private func openChatGPT() {
    guard let url = ChatGPTPromptService.createChatGPTDeeplink(ingredients: ingredientsText) else {
      errorMessage = "Failed to create ChatGPT link"
      return
    }

    openURL(url) { success in
      if !success {
        errorMessage = "Could not open ChatGPT. Try copying the prompt instead."
      }
    }
  }

  private func copyPrompt() {
    let prompt = ChatGPTPromptService.generateRecipePrompt(ingredients: ingredientsText)
    UIPasteboard.general.string = prompt

    ToastManager.shared.show(
      icon: "doc.on.doc.fill",
      title: "Prompt copied",
      subtitle: "Paste in ChatGPT or any AI assistant",
      tint: .accent,
      duration: 2.5
    )
  }
}

#Preview {
  IngredientFinderScreen()
}
