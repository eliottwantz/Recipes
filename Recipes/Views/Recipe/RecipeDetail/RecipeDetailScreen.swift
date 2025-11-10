//
//  RecipeDetailScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-11-09.
//

import Dependencies
import SQLiteData
import SwiftUI

struct RecipeDetailScreen: View {
  let recipe: Recipe

  enum Phase: Equatable {
    case loading
    case loaded(RecipeDetails)
    case failed(String)
  }
  @State private var phase: Phase = .loading

  @Dependency(\.defaultDatabase) private var defaultDatabase

  var body: some View {
    VStack {
      switch phase {
      case .loading:
        VStack {
          ProgressView("Loading recipe details...")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
          loadDetails()
        }
      case .loaded(let recipeDetails):
        RecipeDetailView(recipeDetails: recipeDetails)
      case .failed(let string):
        ContentUnavailableView(
          "Failed to Load Recipe",
          systemImage: "exclamationmark.triangle",
          description: Text(string)
        )
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Retry", action: loadDetails)
          }
        }
      }
    }
    .navigationTitle(recipe.name)
    .navigationBarTitleDisplayMode(.inline)
  }

  private func loadDetails() {
    Task {
      do {
        let results = try await defaultDatabase.read { db in
          try RecipeDetails.FetchKeyRequest(recipeId: recipe.id).fetch(db)
        }
        phase = .loaded(
          .init(
            recipe: recipe,
            ingredients: results.ingredients,
            instructions: results.instructions
          )
        )
      } catch {
        phase = .failed(error.localizedDescription)
      }
    }
  }
}

#Preview {
  let recipe = Storage.configure { database in
    return try database.read { db in
      return try Recipe.all.fetchOne(db)
    }
  }
  if let recipe {
    RecipeDetailScreen(recipe: recipe)
  } else {
    Text("No recipe")
  }
}
