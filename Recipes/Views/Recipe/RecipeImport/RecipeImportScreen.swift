//
//  RecipeImportScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-11-08.
//

import SwiftUI

struct RecipeImportScreen: View {
  enum Phase: Equatable {
    case initial
    case importing
    case success
    case failure(String)
  }

  @Environment(\.dismiss) private var dismiss
  @State private var recipeUrl: String = ""
  @State private var phase: Phase = .initial

  private var isImporting: Bool {
    phase == .importing
  }

  private var submitDisabled: Bool {
    isImporting || recipeUrl.isEmpty
  }

  var body: some View {
    NavigationStack {
      Group {
        if case .failure(let errorMessage) = phase {
          ContentUnavailableView(
            "Import Failed",
            systemImage: "exclamationmark.triangle",
            description: Text(errorMessage)
          )
        } else {
          ImportForm(
            recipeUrl: $recipeUrl,
            onSumbit: handleImport,
            isImporting: isImporting
          )
        }
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            recipeUrl = ""
            dismiss()
          }
          .disabled(isImporting)
        }

        ToolbarItem(placement: .primaryAction) {
          if case .failure = phase {
            Button("Close") {
              dismiss()
            }
            .buttonStyle(.glassProminent)
          } else {
            Button {
              handleImport()
            } label: {
              Label("Import", systemImage: "checkmark")
            }
            .buttonStyle(.glassProminent)
            .disabled(submitDisabled)
          }
        }
      }
    }
  }

  func handleImport() {
    let trimmed = recipeUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    guard let url = URL(string: trimmed) else {
      phase = .failure("Please enter a valid recipe URL.")
      return
    }

    if isImporting {
      return
    }
    phase = .importing

    Task {
      do {
        try await RecipeImportManager.importRecipe(from: url)
        phase = .success
      } catch {
        phase = .failure(error.localizedDescription)
      }
    }
  }
}

struct ImportForm: View {
  @Binding var recipeUrl: String
  var onSumbit: () -> Void
  var isImporting: Bool

  var body: some View {
    Form {
      Text("Import a recipe")
        .font(.title2)
        .padding()
      Text("Recipe URL")
        .font(.caption)
        .foregroundColor(.secondary)
      TextField("URL", text: $recipeUrl)
        .keyboardType(.URL)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .disabled(isImporting)
      if isImporting {
        HStack {
          ProgressView()
          Text("Importing…")
            .foregroundStyle(.secondary)
        }
      }
    }
    .submitLabel(.send)
    .onSubmit(onSumbit)
  }
}

#Preview {
  RecipeImportScreen()
}
