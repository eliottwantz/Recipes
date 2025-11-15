//
//  RecipeListScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-11-08.
//

import Dependencies
import SQLiteData
import SwiftUI

struct RecipeListScreen: View {
  @Environment(\.scenePhase) private var scenePhase
  @FetchAll(Recipe.order { $0.updatedAt.desc() })
  private var recipes

  @State private var showRecipeImportScreen: Bool = false

  var body: some View {
    NavigationStack {
      ZStack {
        RecipeListView(recipes: recipes)
          .navigationTitle("All recipes")
          .navigationDestination(
            for: Recipe.self,
            destination: { recipe in
              RecipeDetailScreen(recipeId: recipe.id)
            }
          )
          .safeAreaBar(edge: .bottom) {
            HStack {
              Spacer()

              Button {
                showRecipeImportScreen = true
              } label: {
                Label("Add a recipe", systemImage: "plus")
              }
              .buttonStyle(.toolbar)
            }
            .padding(.trailing)
            .padding(.bottom, 8)
          }
      }
      .sheet(isPresented: $showRecipeImportScreen) {
        RecipeImportScreen()
      }
      .onChange(of: scenePhase) { oldValue, newValue in
        if oldValue == .inactive && newValue == .active {
          Task {
            try await $recipes.load()
          }
        }
      }
    }
  }
}

#Preview {
  Storage.configure()
  return RecipeListScreen()

}
