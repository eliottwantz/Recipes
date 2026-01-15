//
//  VideoRecipeImportScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-01-14.
//

import SwiftUI

struct VideoRecipeImportScreen: View {
  @Environment(\.dismiss) private var dismiss
  @State private var urlText: String = ""
  @State private var selectedLanguage: String =
    Locale.current.language.languageCode?.identifier == "fr" ? "fr" : "en"
  @State private var isLoading = false
  @State private var errorMessage: String?

  var appRouter = AppRouter.shared
  private let importService = VideoRecipeImportService()

  private var isAPIConfigured: Bool {
    SecureStorage.hasValue(for: .videoRecipeAPIKey)
  }

  private var isValidURL: Bool {
    guard let url = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
      return false
    }
    return url.scheme?.lowercased().hasPrefix("http") == true
  }

  var body: some View {
    NavigationStack {
      Form {
        if !isAPIConfigured {
          Section {
            Label("API key not configured", systemImage: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)
            Text("Go to Settings to add your API key.")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }

        Section {
          TextField("Paste video URL", text: $urlText)
            .textContentType(.URL)
            .keyboardType(.URL)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .disabled(isLoading || !isAPIConfigured)
        } header: {
          Text("Video URL")
        } footer: {
          Text("Supports YouTube, Instagram Reels, and TikTok videos")
        }

        Section {
          Picker("Language", selection: $selectedLanguage) {
            Text("English").tag("en")
            Text("Français").tag("fr")
          }
          .pickerStyle(.segmented)
          .disabled(isLoading || !isAPIConfigured)
        } header: {
          Text("Recipe Language")
        } footer: {
          Text(
            "Select the language of the video's spoken content. For YouTube videos, this must match an available caption language."
          )
        }

        if let errorMessage {
          Section {
            Label(errorMessage, systemImage: "xmark.circle.fill")
              .foregroundStyle(.red)
          }
        }
      }
      .navigationTitle("Import from Social Media")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .disabled(isLoading)
        }
        ToolbarItem(placement: .primaryAction) {
          if isLoading {
            ProgressView()
          } else {
            Button("Import", action: importRecipe)
              .disabled(urlText.isEmpty || !isAPIConfigured || !isValidURL)
          }
        }
      }
    }
  }

  private func importRecipe() {
    let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let url = URL(string: trimmedURL),
      url.scheme?.lowercased().hasPrefix("http") == true
    else {
      errorMessage = "Please enter a valid URL"
      return
    }

    errorMessage = nil
    isLoading = true

    Task {
      await performImport(from: url)
    }
  }

  nonisolated private func performImport(from url: URL) async {
    do {
      let recipeDetails: RecipeDetails

      // Check if it's a YouTube URL and use appropriate import method
      if YouTubeTranscriptService.isYouTubeURL(url) {
        recipeDetails = try await importService.importFromYouTube(
          videoURL: url, language: selectedLanguage)
      } else {
        recipeDetails = try await importService.importRecipe(
          from: url, language: selectedLanguage)
      }

      await MainActor.run {
        isLoading = false
        dismiss()
        appRouter.destination = .addRecipe(recipeDetails)
      }
    } catch {
      await MainActor.run {
        isLoading = false
        errorMessage = error.localizedDescription
      }
    }
  }
}

#Preview {
  VideoRecipeImportScreen()
}
