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
          .navigationTitle("Recipes")
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
                Image(systemName: "plus")
                  .accessibilityLabel("Add a recipe")
                  .font(.title2)
                  .foregroundStyle(.foreground)
              }
              .frame(width: 44, height: 44)
              .glassEffect(.regular.interactive())
              .padding(.trailing)
            }
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
