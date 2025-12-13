//
//  RecipeListScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-11-08.
//

import Dependencies
import SQLiteData
import SwiftUI

struct RecipeListView: View {
  let recipes: [Recipe]
  @State private var showRecipeImportScreen: Bool = false
  @State private var recipePhotos: [Recipe.ID: RecipePhoto] = [:]
  @Dependency(\.defaultDatabase) private var database

  @Environment(\.editMode) private var editMode
  @Binding var selection: Set<Recipe.ID>

  @State private var showDeleteConfirmation: Bool = false
  @State private var recipeToDelete: Recipe?

  @State private var recipeToEditDetails: RecipeDetails? = nil

  init(recipes: [Recipe], selection: Binding<Set<Recipe.ID>>) {
    self.recipes = recipes
    self._selection = selection
  }

  var body: some View {
    Group {
      if recipes.isEmpty {
        ContentUnavailableView(
          "No Recipes Yet",
          systemImage: "text.book.closed",
          description: Text("Add a new recipe to start building your collection.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(selection: $selection) {
          ForEach(recipes) { recipe in
            RecipeCard(recipe: recipe, photo: recipePhotos[recipe.id])
              .background {
                NavigationLink(value: recipe) { EmptyView() }.opacity(0)
              }
              .contextMenu {
                Button {
                  startRecipeEdit(for: recipe)
                } label: {
                  Label("Edit recipe", systemImage: "pencil")
                }
                Divider()
                Button(role: .destructive) {
                  recipeToDelete = recipe
                  showDeleteConfirmation = true
                } label: {
                  Label("Delete", systemImage: "trash")
                }
                .tint(nil)
              }
              .listRowInsets(.init(top: 10, leading: 12, bottom: 10, trailing: 0))
          }
        }
        .listStyle(.plain)
        .alert(
          "Delete Recipe",
          isPresented: $showDeleteConfirmation,
          presenting: recipeToDelete
        ) { recipe in
          Button("Cancel", role: .cancel) {}
          Button("Confirm", role: .destructive) {
            deleteRecipe(recipe.id)
          }
        } message: { recipe in
          Text("Delete \(recipe.name). This action cannot be undone.")
        }
        .sheet(item: $recipeToEditDetails) { recipeDetails in
          RecipeEditScreen(recipeDetails: recipeDetails)
            .interactiveDismissDisabled()
        }
      }
    }
    .task {
      await loadRecipePhotos()
    }
  }

  private func loadRecipePhotos() async {
    withErrorReporting {
      let photos = try database.read { db in
        try RecipePhoto
          .where { recipes.map(\.id).contains($0.recipeId) }
          .order(by: \.position)
          .fetchAll(db)
      }

      var photoMap: [Recipe.ID: RecipePhoto] = [:]
      for photo in photos {
        if photoMap[photo.recipeId] == nil {
          photoMap[photo.recipeId] = photo
        }
      }

      recipePhotos = photoMap
    }
  }

  private func deleteRecipe(_ recipeId: Recipe.ID) {
    withErrorReporting {
      try database.write { db in
        try Recipe.find(recipeId).delete().execute(db)
      }
    }
    editMode?.wrappedValue = .inactive
  }

  private func startRecipeEdit(for recipe: Recipe) {
    withErrorReporting {
      let recipeDetails = try database.read { db in
        try RecipeDetails.FetchKeyRequest(recipeId: recipe.id)
          .fetch(db)
      }
      recipeToEditDetails = recipeDetails
    }
  }

}

private struct RecipeCard: View {
  let recipe: Recipe
  let photo: RecipePhoto?

  var totalTimeMinutes: Int {
    recipe.prepTimeMinutes + recipe.cookTimeMinutes
  }

  var body: some View {
    HStack(spacing: 16) {
      Group {
        if let photo = photo, let image = photo.image {
          image
            .resizable()
            .scaledToFill()
        } else {
          Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
              Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            )
        }
      }
      .aspectRatio(5 / 4, contentMode: .fill)
      .frame(width: 120)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .contentShape(RoundedRectangle(cornerRadius: 12))

      VStack(alignment: .leading) {
        Text(recipe.name)
          .font(.headline)
          .lineLimit(2)
        HStack {
          if recipe.servings > 0 || totalTimeMinutes > 0 {
            HStack(spacing: 8) {
              if recipe.servings > 0 {
                HStack(spacing: 4) {
                  Image(systemName: "person.2.fill")
                    .font(.footnote)
                  Text("\(recipe.servings)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
              }

              if totalTimeMinutes > 0 {
                HStack(spacing: 4) {
                  Image(systemName: "clock.fill")
                    .font(.footnote)
                  TimeView(totalMinutes: totalTimeMinutes)
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
              }
            }
            .foregroundStyle(.secondary)
            .padding(4)
            .background(Capsule().fill(Color.gray.opacity(0.3)))
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  @Previewable @State var selection = Set<Recipe.ID>()

  let recipes = Storage.configure { database in
    return try database.read { db in
      try Recipe.all.fetchAll(db)
    }
  }
  return RecipeListView(recipes: recipes, selection: $selection)
}
