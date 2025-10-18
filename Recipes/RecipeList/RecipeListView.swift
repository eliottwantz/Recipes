import SQLiteData
import SwiftUI

struct RecipeListView: View {
  @FetchAll(
    Recipe
      .order { $0.updatedAt.desc() },
    animation: .default
  )
  private var recipes

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
          NavigationLink {
            RecipeDetailView(recipe: recipe)
          } label: {
            RecipeRow(recipe: recipe)
          }
        }
        .listStyle(.plain)
      }
    }
    .navigationTitle("Recipes")
  }
}

private struct RecipeRow: View {
  let recipe: Recipe

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(recipe.title)
        .font(.headline)
        .foregroundStyle(.primary)
      if !recipe.summary.isEmpty {
        Text(recipe.summary)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(3)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
  }
}

#Preview {
  StorageBootstrap.configurePreview()
  return NavigationStack {
    RecipeListView()
  }
}
