//
//  RecipeDetails.swift
//  Recipes
//
//  Created by Eliott on 2025-11-09.
//

import Foundation
import SQLiteData

nonisolated struct RecipeDetails: Equatable {
  var recipe: Recipe
  var ingredients: [RecipeIngredient]
  var instructions: [RecipeInstruction]
}

extension RecipeDetails {
  struct FetchKeyRequest: SQLiteData.FetchKeyRequest {
    let recipeId: Recipe.ID

    struct Value {
      let recipe: Recipe
      let ingredients: [RecipeIngredient]
      let instructions: [RecipeInstruction]

      static var placeholder: Value {
        .init(recipe: .init(id: UUID()), ingredients: [], instructions: [])
      }
    }

    func fetch(_ db: Database) throws -> Value {
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
