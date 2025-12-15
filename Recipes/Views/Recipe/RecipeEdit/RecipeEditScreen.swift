//
//  RecipeEditScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-11-11.
//

import SQLiteData
import SwiftUI
import WebKit

struct RecipeEditScreen: View {
  @State var recipeDetails: RecipeDetails

  @Environment(\.dismiss) private var dismiss
  @Dependency(\.defaultDatabase) private var database

  @State private var error: Error?

  @State private var initialRecipeImportWebsiteURL: URL? = nil
  @State private var selectedDetent: PresentationDetent = .fraction(0.1)
  @State private var websitePage = WebPage()

  private var isWebsiteSheetExpanded: Bool {
    selectedDetent != .fraction(0.1)
  }

  init(recipeDetails: RecipeDetails) {
    self.recipeDetails = recipeDetails
  }

  var body: some View {
    NavigationStack {
      RecipeEditFormView(recipeDetails: $recipeDetails)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
              dismiss()
            }
          }
          ToolbarItem(placement: .primaryAction) {
            Button("Update", action: updateRecipe)
              .buttonStyle(.glassProminent)
          }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Modify Recipe")
        .navigationBarTitleDisplayMode(.inline)
        // MARK: Space for bottom sheet to not overlap content
        .safeAreaBar(edge: .bottom) {
          VStack {}
            .padding(.bottom, 70)
        }
        .sheet(item: $initialRecipeImportWebsiteURL) { url in
          Group {
            if isWebsiteSheetExpanded {
              WebView(websitePage)
            } else {
              VStack {
                Label("Original Website", systemImage: "safari.fill")
              }
            }
          }
          .interactiveDismissDisabled()
          .presentationBackgroundInteraction(.enabled)
          .presentationDetents([.fraction(0.1), .medium, .large], selection: $selectedDetent)
        }

    }
    .onAppear {
      if let website = recipeDetails.recipe.website, let url = URL(string: website) {
        initialRecipeImportWebsiteURL = url
        websitePage.load(url)
      }
    }

  }

  private func updateRecipe() {
    let normalized = recipeDetails.normalized()
    do {
      try database.write { db in
        try Recipe.update {
          $0.name = normalized.recipe.name
          $0.servings = normalized.recipe.servings
          $0.prepTimeMinutes = normalized.recipe.prepTimeMinutes
          $0.cookTimeMinutes = normalized.recipe.cookTimeMinutes
        }
        .where { $0.id.eq(normalized.recipe.id) }
        .execute(db)

        for ingredient in normalized.ingredients {
          try RecipeIngredient.update {
            $0.position = ingredient.position
            $0.text = ingredient.text
          }
          .where { $0.id.eq(ingredient.id) }
          .where { $0.recipeId.eq(normalized.recipe.id) }
          .execute(db)
        }

        for instruction in normalized.instructions {
          try RecipeInstruction.update {
            $0.position = instruction.position
            $0.text = instruction.text
          }
          .where { $0.id.eq(instruction.id) }
          .where { $0.recipeId.eq(normalized.recipe.id) }
          .execute(db)
        }
      }

      dismiss()
    } catch {
      self.error = error
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
        recipe: recipe, ingredients: results.ingredients, instructions: results.instructions)
    }
  }

  RecipeEditScreen(recipeDetails: recipeDetails)
}
