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
