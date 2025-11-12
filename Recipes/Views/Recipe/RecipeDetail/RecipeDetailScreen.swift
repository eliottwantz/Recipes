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

  init(recipeId: Recipe.ID) {
    self._recipeDetails = RecipeDetails.Fetch(recipeId: recipeId)
  }

  var body: some View {
    VStack {
      RecipeDetailView(recipeDetails: recipeDetails)
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
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
    }
    .navigationTitle(recipeDetails.recipe.name)
    .navigationBarTitleDisplayMode(.inline)
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
