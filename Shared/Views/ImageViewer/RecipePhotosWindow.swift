//
//  RecipePhotosWindow.swift
//  Recipes
//
//  Created by Eliott on 2025-11-20.
//

import Dependencies
import SQLiteData
import SwiftUI

struct RecipePhotosWindowData: Codable, Hashable {
  let recipeId: UUID
  let initialPhotoId: UUID
}

struct RecipePhotosWindow: View {
  let data: RecipePhotosWindowData
  @State private var recipeDetails: RecipeDetails?
  @State private var selectedPhotoId: UUID?

  var body: some View {
    Group {
      if let recipeDetails, !recipeDetails.photos.isEmpty {
        ImageCarouselView(photos: recipeDetails.photos, selectedPhotoID: $selectedPhotoId)
          .navigationTitle(recipeDetails.recipe.name)
      } else {
        ProgressView()
          .task {
            await loadRecipe()
          }
      }
    }
    .frame(minWidth: 800, minHeight: 600)
  }

  private func loadRecipe() async {
    // Fetch recipe details
    @Dependency(\.defaultDatabase) var database

    do {
      let details = try await database.read { db in
        try RecipeDetails.FetchKeyRequest(recipeId: data.recipeId).fetch(db)
      }
      await MainActor.run {
        self.recipeDetails = details
        // Only set initial photo if not already set (to avoid resetting on reload if that happens)
        if self.selectedPhotoId == nil {
          self.selectedPhotoId = data.initialPhotoId
        }
      }
    } catch {
      print("Failed to load recipe details: \(error)")
    }
  }
}
