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
  @State private var scaleFactor: Double = 1.0

  private var appRouter = AppRouter.shared

  init(recipeId: Recipe.ID) {
    self._recipeDetails = RecipeDetails.fetch(recipeId: recipeId)
  }

  private var cookingSessionBinding: Binding<AppRouter.CookingSession?> {
    Binding(
      get: {
        guard let session = appRouter.activeCookingSession,
          session.id == recipeDetails.id
        else { return nil }
        return session
      },
      set: { appRouter.activeCookingSession = $0 }
    )
  }

  var body: some View {
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
        .fullScreenCover(item: cookingSessionBinding) { session in
          RecipeCookingScreen(
            recipeDetails: recipeDetails,
            scaleFactor: scaleFactor,
            currentStep: Binding(
              get: { appRouter.activeCookingSession?.currentStep ?? 0 },
              set: { appRouter.activeCookingSession?.currentStep = $0 }
            )
          )
        }
        .onChange(of: cookingSessionBinding.wrappedValue) { oldValue, newValue in
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
