import Dependencies
import SQLiteData
import SwiftUI

struct RecipeListView: View {
  let recipes: [Recipe]
  @State private var showRecipeImportScreen: Bool = false

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
        List(recipes) { recipe in
          NavigationLink(value: recipe) {
            RecipeRow(recipe: recipe)
          }
        }
        .listStyle(.plain)
      }
    }
  }
}

private struct RecipeRow: View {
  let recipe: Recipe

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(recipe.name)
        .font(.headline)
        .foregroundStyle(.primary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
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
