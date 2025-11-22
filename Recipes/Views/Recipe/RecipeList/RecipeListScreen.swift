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
  @FetchAll(Recipe.order(by: \.name))
  private var recipes

  @State private var showRecipeImportScreen: Bool = false
  @State private var searchText: String = ""

  @State private var sortBy: SortBy = .name
  @State private var sortDirection: SortDirection = .asc

  @State private var editMode: EditMode = .inactive

  var searchId: String {
    "\(searchText)_\(sortBy)_\(sortDirection)"
  }

  var body: some View {
    NavigationStack {
      RecipeListView(recipes: recipes)
        .navigationTitle("All recipes")
        .toolbarTitleDisplayMode(.inlineLarge)
        .searchable(text: $searchText)
        .task(id: searchId) {
          await updateSearchQuery()
        }
        .environment(\.editMode, $editMode)
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            if editMode == .active {
              Button {
                editMode = .inactive
              } label: {
                Label("Done", systemImage: "checkmark")
              }
              .buttonStyle(.glassProminent)
            } else {
              Menu {
                Section("Sorting") {
                  let systemImage: String = sortDirection == .asc ? "chevron.up" : "chevron.down"
                  Button {
                    if sortBy == .name {
                      sortDirection = sortDirection == .asc ? .desc : .asc
                    }
                    sortBy = .name
                  } label: {
                    if sortBy == .name {
                      Label("Name", systemImage: systemImage)
                    } else {
                      Text("Name")
                    }
                  }

                  Button {
                    if sortBy == .createdAt {
                      sortDirection = sortDirection == .asc ? .desc : .asc
                    }
                    sortBy = .createdAt
                  } label: {
                    if sortBy == .createdAt {
                      Label("Date added", systemImage: systemImage)
                    } else {
                      Text("Date added")
                    }
                  }
                }

                Section {
                  Button {
                    editMode = .active
                  } label: {
                    Label("Select recipes", systemImage: "checkmark.circle")
                  }
                }
              } label: {
                Label("Options", systemImage: "ellipsis")
              }
            }
          }
        }
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

  private func updateSearchQuery() async {
    do {
      try await $recipes.load(
        Recipe
          .where { $0.name.lower().contains(searchText) }
          .order {
            switch (sortBy, sortDirection) {
            case (.name, .asc):
              $0.name.asc()
            case (.name, .desc):
              $0.name.desc()
            case (.createdAt, .asc):
              $0.createdAt.asc()
            case (.createdAt, .desc):
              $0.createdAt.desc()
            }
          }
      )
    } catch {
      print("Error in search query: \(error.localizedDescription)")
    }
  }
}

#Preview {
  Storage.configure()
  return RecipeListScreen()

}
