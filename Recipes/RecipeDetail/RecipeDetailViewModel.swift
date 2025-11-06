import SQLiteData
import SwiftUI

@Observable
class RecipeDetailViewModel {
  let recipe: Recipe
  private(set) var ingredients: [RecipeIngredient] = []
  private(set) var instructions: [RecipeInstruction] = []
  private(set) var isLoading = false
  private(set) var error: String?

  @ObservationIgnored @Dependency(\.defaultDatabase) private var defaultDatabase

  init(recipe: Recipe) {
    self.recipe = recipe
    Task {
      await loadDetails()
    }
  }

  private func loadDetails() async {
    isLoading = true
    error = nil

    do {
      let results = try await defaultDatabase.read { db in
        try RecipeDetail(recipeId: recipe.id).fetch(db)
      }
      ingredients = results.ingredients
      instructions = results.instructions
    } catch {
      self.error = error.localizedDescription
    }

    isLoading = false
  }

  func retry() {
    Task {
      await loadDetails()
    }
  }
}

extension RecipeDetailViewModel {
  private struct RecipeDetail: FetchKeyRequest {
    let recipeId: Recipe.ID

    struct Value {
      let ingredients: [RecipeIngredient]
      let instructions: [RecipeInstruction]

      static var placeholder: Value { .init(ingredients: [], instructions: []) }
    }

    func fetch(_ db: Database) throws -> Value {
      try Value(
        ingredients:
          RecipeIngredient
          .where { $0.recipeId == recipeId }
          .order(by: \.position)
          .fetchAll(db),
        instructions:
          RecipeInstruction
          .where { $0.recipeId == recipeId }
          .order(by: \.position)
          .fetchAll(db)
      )
    }
  }
}
