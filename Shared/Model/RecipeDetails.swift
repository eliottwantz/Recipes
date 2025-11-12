//
//  RecipeDetails.swift
//  Recipes
//
//  Created by Eliott on 2025-11-09.
//

import Foundation
import SQLiteData

nonisolated struct RecipeDetails {
  var recipe: Recipe
  var ingredients: [RecipeIngredient]
  var instructions: [RecipeInstruction]

  static func Fetch(recipeId: Recipe.ID) -> Fetch<RecipeDetails> {
    return SQLiteData.Fetch(
      wrappedValue: .init(recipe: .init(id: UUID()), ingredients: [], instructions: []),
      RecipeDetails.FetchKeyRequest(recipeId: recipeId)
    )
  }

  nonisolated struct FetchKeyRequest: SQLiteData.FetchKeyRequest {
    let recipeId: Recipe.ID

    func fetch(_ db: Database) throws -> RecipeDetails {
      try Value(
        recipe:
          Recipe
          .where { $0.id.eq(recipeId) }
          .limit(1)
          .fetchOne(db)!,
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

extension RecipeDetails: Equatable {
  func normalized() -> Self {
    var copy = self
    copy.recipe.name = copy.recipe.name.trimmingCharacters(in: .whitespacesAndNewlines)
    copy.ingredients = copy.ingredients.map { draft in
      var newDraft = draft
      newDraft.text = newDraft.text.trimmingCharacters(in: .whitespacesAndNewlines)
      return newDraft
    }
    copy.instructions = copy.instructions.map { draft in
      var newDraft = draft
      newDraft.text = newDraft.text.trimmingCharacters(in: .whitespacesAndNewlines)
      return newDraft
    }
    copy.ingredients.removeAll { $0.text.isEmpty }
    copy.instructions.removeAll { $0.text.isEmpty }
    return copy
  }
}
