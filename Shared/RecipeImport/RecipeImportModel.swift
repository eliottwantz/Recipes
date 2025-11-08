//
//  RecipeImportModel.swift
//  Recipes
//
//  Created by Eliott on 2025-11-05.
//
import SwiftUI

@Observable
final class RecipeImportModel {
  var showAddForm = false
  var recipeUrl = ""
  var isImporting = false
  var importError: String?

  var submitDisabled: Bool {
    isImporting || recipeUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func handleImport() {
    let trimmed = recipeUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    guard let url = URL(string: trimmed) else {
      importError = "Please enter a valid recipe URL."
      return
    }

    if isImporting {
      return
    }
    isImporting = true

    Task {
      do {
        try await RecipeImportManager.importRecipe(from: url)
        isImporting = false
        recipeUrl = ""
        showAddForm = false
      } catch {
        isImporting = false
        importError = error.localizedDescription
      }
    }
  }
}
