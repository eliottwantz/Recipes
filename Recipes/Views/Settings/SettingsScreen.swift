//
//  SettingsScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-01-14.
//

import SwiftUI

struct SettingsScreen: View {
  @State private var apiKey: String = ""
  @State private var hasStoredKey: Bool = false
  @State private var showSavedConfirmation: Bool = false

  var body: some View {
    NavigationStack {
      Form {
        Section {
          if hasStoredKey {
            HStack {
              Label("API key configured", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
              Spacer()
              Button("Clear", role: .destructive) {
                clearAPIKey()
              }
              .buttonStyle(.borderless)
            }
          } else {
            SecureField("Enter API Key", text: $apiKey)
              .textContentType(.password)
              .autocorrectionDisabled()
              .textInputAutocapitalization(.never)
          }
        } header: {
          Text("Social Media Import")
        } footer: {
          Text("Required to import recipes from YouTube, Instagram, or TikTok videos.")
        }

        if !hasStoredKey && !apiKey.isEmpty {
          Section {
            Button("Save API Key") {
              saveAPIKey()
            }
            .frame(maxWidth: .infinity)
          }
        }
      }
      .navigationTitle("Settings")
      .onAppear {
        checkForStoredKey()
      }
      .sensoryFeedback(.success, trigger: showSavedConfirmation)
    }
  }

  private func checkForStoredKey() {
    hasStoredKey = SecureStorage.hasValue(for: .videoRecipeAPIKey)
  }

  private func saveAPIKey() {
    guard !apiKey.isEmpty else { return }

    do {
      try SecureStorage.save(apiKey, for: .videoRecipeAPIKey)
      apiKey = ""
      hasStoredKey = true
      showSavedConfirmation = true
    } catch {
      // Handle error - could show an alert
    }
  }

  private func clearAPIKey() {
    do {
      try SecureStorage.delete(.videoRecipeAPIKey)
      hasStoredKey = false
      apiKey = ""
    } catch {
      // Handle error - could show an alert
    }
  }
}

#Preview {
  SettingsScreen()
}
