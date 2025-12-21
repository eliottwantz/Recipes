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
  @Fetch var recipeDetails: RecipeDetails
  @Dependency(\.defaultDatabase) private var defaultDatabase
  @State private var showEditSheet = false
  @State private var showCookingScreen = false
  @State private var scaleFactor: Double = 1.0

  init(recipeId: Recipe.ID) {
    self._recipeDetails = RecipeDetails.fetch(recipeId: recipeId)
  }

  var body: some View {
    VStack {
      RecipeDetailView(recipeDetails: recipeDetails, scaleFactor: $scaleFactor)
        .toolbar {
          ToolbarItemGroup(placement: .primaryAction) {
            Button {
              showCookingScreen = true
            } label: {
              Label("Start cooking", systemImage: "play.circle")
            }
            Menu("More", systemImage: "ellipsis") {
              Button {
                showEditSheet = true
              } label: {
                Label("Edit recipe", systemImage: "pencil")
              }
            }
          }
        }
        .sheet(isPresented: $showEditSheet) {
          RecipeEditScreen(recipeDetails: recipeDetails)
            .interactiveDismissDisabled()
        }
        .fullScreenCover(isPresented: $showCookingScreen) {
          RecipeCookingScreen(recipeDetails: recipeDetails, scaleFactor: scaleFactor)
        }
        .onChange(of: showCookingScreen) { _, newValue in
          // Reset scale factor when returning from cooking mode
          if !newValue {
            scaleFactor = 1.0
          }
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
    RecipeDetailScreen(recipeId: recipe.id)
  } else {
    Text("No recipe")
  }
}
