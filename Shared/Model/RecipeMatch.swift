//
//  RecipeMatch.swift
//  Recipes
//
//  Created by Eliott on 2025-12-31.
//

import Foundation

struct RecipeMatch: Identifiable, Equatable {
  let recipeDetails: RecipeDetails
  let matchedIngredients: [String]
  let missingIngredients: [String]
  let matchPercentage: Double

  var id: Recipe.ID {
    recipeDetails.id
  }

  var matchScore: Int {
    matchedIngredients.count
  }
}
