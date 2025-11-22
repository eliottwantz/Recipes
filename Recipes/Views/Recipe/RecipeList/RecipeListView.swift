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

  init(recipes: [Recipe]) {
    self.recipes = recipes
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
        ScrollView {
          LazyVGrid(
            columns: [
              GridItem(.flexible(), spacing: 18),
              GridItem(.flexible()),
            ],
            spacing: 20
          ) {
            ForEach(recipes) { recipe in
              NavigationLink(value: recipe) {
                RecipeCard(recipe: recipe, photo: recipePhotos[recipe.id])
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.horizontal, 8)
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

  private func deleteRecipes(_ offset: IndexSet) {
    withErrorReporting {
      try database.write { db in
        let ids = offset.map { recipes[$0].id }
        try Recipe.where { ids.contains($0.id) }.delete().execute(db)
      }
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
    ZStack(alignment: .topLeading) {
        Group {
            if let photo = photo, let image = photo.image {
                GeometryReader { geometry in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
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
        .overlay {
            Color.black.opacity(0.45)
        }

      VStack(alignment: .leading) {
        Text(recipe.name)
          .font(.headline)
          .fontWeight(.medium)
          .foregroundStyle(.white)
          .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
          .lineLimit(2)
          .padding(.leading, 10)
          .padding(.top, 8)

        Spacer()

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
          .padding(6)
          .background {
            ZStack {
              Color.black
              Color.gray.opacity(0.3)
            }
            .clipShape(.rect(corners: .concentric))
            .containerShape(.rect(cornerRadius: 60))
          }
          .padding(8)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .aspectRatio(5 / 4, contentMode: .fill)
    .clipped()
    .clipShape(.rect(corners: .concentric(minimum: 26)))
    .contentShape(.rect)
  }
}

#Preview {
  let recipes = Storage.configure { database in
    return try database.read { db in
      try Recipe.all.fetchAll(db)
    }
  }
  return RecipeListView(recipes: recipes)
}
