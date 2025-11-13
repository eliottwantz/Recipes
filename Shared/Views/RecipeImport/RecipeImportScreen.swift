//
//  RecipeImportScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-11-08.
//

import Dependencies
import SQLiteData
import SwiftUI

struct RecipeImportScreen: View {
  @State var recipeDetails: RecipeDetails
  var onDismiss: (() -> Void)?

  @Environment(\.dismiss) private var dismiss
  @Dependency(\.defaultDatabase) private var database
  @State private var importErrorMessage: String? = nil
  @State private var isSaving = false
  private let importManager = RecipeImportManager()

  enum Phase: Equatable {
    case initial
    case loading
    case error(String)
  }
  @State private var phase: Phase = .initial

  private var saveDisabled: Bool {
    isSaving
      || recipeDetails.recipe.name
        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  init(
    recipeDetails: RecipeDetails? = nil,
    onDismiss: (() -> Void)? = nil
  ) {
    if let recipeDetails {
      self.recipeDetails = recipeDetails
    } else {
      self.recipeDetails = .init(recipe: .init(id: UUID()), ingredients: [], instructions: [])
    }
    self.onDismiss = onDismiss
  }

  var body: some View {
    NavigationStack {
      RecipeEditFormView(recipeDetails: $recipeDetails)
        .navigationTitle("Add a recipe")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("Cancel", systemImage: "xmark") {
              dismiss()
              onDismiss?()
            }
          }
          ToolbarItem(placement: .primaryAction) {
            Button("Add", action: saveRecipe)
              .disabled(saveDisabled)
          }
        }
    }
  }

  private func saveRecipe() {
    guard !recipeDetails.recipe.name.isEmpty else { return }
    isSaving = true

    Task {
      do {
        let normalizedDetails = recipeDetails.normalized()
        try importManager.persist(normalizedDetails, in: database)
        isSaving = false
        dismiss()
        onDismiss?()
      } catch {
        isSaving = false
        // Handle error - could show an alert
      }
    }
  }
}

#Preview {
  let recipeDetails = Storage.configure { database in
    return try database.read { db in
      print("FETCHING RECIPE FOR PREVIEW")
      let recipe = try Recipe.all.fetchOne(db)
      guard let recipe else { fatalError("No recipe found. Seed the database first.") }
      let results = try RecipeDetails.FetchKeyRequest(recipeId: recipe.id).fetch(db)
      return RecipeDetails(
        recipe: recipe,
        ingredients: results.ingredients,
        instructions: results.instructions
      )
    }
  }

  NavigationStack {
    RecipeImportScreen(recipeDetails: recipeDetails)
  }
}
