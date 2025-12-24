//
//  RecipeDetailScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-11-09.
//

import Dependencies
import SQLiteData
import SwiftUI
import SwiftUINavigation

struct RecipeDetailScreen: View {
  @Fetch var recipeDetails: RecipeDetails
  @Dependency(\.defaultDatabase) private var defaultDatabase
  @State private var showEditSheet = false
  @State private var scaleFactor: Double = 1.0

  private var appRouter = AppRouter.shared

  init(recipeId: Recipe.ID) {
    self._recipeDetails = RecipeDetails.fetch(recipeId: recipeId)
  }

  var body: some View {
    @Bindable var appRouter = AppRouter.shared

    VStack {
      RecipeDetailView(recipeDetails: recipeDetails, scaleFactor: $scaleFactor)
        .toolbar {
          ToolbarItemGroup(placement: .primaryAction) {
            Button {
              appRouter.openCookingScreen(for: recipeDetails.id)
            } label: {
              Label("Start cooking", systemImage: "play.circle")
            }
            Menu("More", systemImage: "ellipsis") {
              Button {
                //                showEditSheet = true
                appRouter.destination = .editRecipe(recipeDetails)
              } label: {
                Label("Edit recipe", systemImage: "pencil")
              }
            }
          }
        }
        .sheet(item: $appRouter.destination.editRecipe) { recipeDetails in
          RecipeEditScreen(recipeDetails: recipeDetails)
            .interactiveDismissDisabled()
        }
        .fullScreenCover(item: $appRouter.destination.cooking) { $session in
          RecipeCookingScreen(
            recipeDetails: recipeDetails,
            scaleFactor: scaleFactor,
            currentStep: $session.currentStep
          )
        }
        .onChange(of: appRouter.destination) { oldValue, newValue in
          if oldValue != nil && newValue == nil {
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
