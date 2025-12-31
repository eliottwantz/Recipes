//
//  IngredientMatchingService.swift
//  Recipes
//
//  Created by Eliott on 2025-12-31.
//

import Dependencies
import Foundation
import SQLiteData
import SwiftUI

struct IngredientMatchingService {

  /// Finds recipes that match the given user ingredients
  /// - Parameters:
  ///   - userIngredients: Raw text input from user (comma or newline separated)
  ///   - database: Database connection
  /// - Returns: Array of RecipeMatch sorted by match percentage (highest first)
  static func findMatches(
    userIngredients: String,
    database: any DatabaseReader
  ) throws -> [RecipeMatch] {

    // Parse user ingredients
    let parsedUserIngredients = parseUserIngredients(userIngredients)

    guard !parsedUserIngredients.isEmpty else {
      return []
    }

    // Fetch all recipes with their ingredients
    let allRecipes = try database.read { db in
      try Recipe.fetchAll(db)
    }

    var matches: [RecipeMatch] = []

    for recipe in allRecipes {
      // Fetch recipe details
      let recipeDetails = try database.read { db in
        try RecipeDetails.FetchKeyRequest(recipeId: recipe.id).fetch(db)
      }

      guard !recipeDetails.ingredients.isEmpty else { continue }

      // Extract ingredient base names from recipe
      let recipeIngredientNames = recipeDetails.ingredients.map { ingredient in
        extractIngredientBaseName(ingredient.text)
      }

      // Find matches and misses
      var matchedIngredients: [String] = []
      var missingIngredients: [String] = []

      for recipeIngredient in recipeIngredientNames {
        if matchesAny(recipeIngredient: recipeIngredient, userIngredients: parsedUserIngredients) {
          matchedIngredients.append(recipeIngredient)
        } else {
          missingIngredients.append(recipeIngredient)
        }
      }

      // Calculate match percentage
      let totalIngredients = recipeIngredientNames.count
      let matchPercentage =
        totalIngredients > 0
        ? Double(matchedIngredients.count) / Double(totalIngredients)
        : 0.0

      // Only include recipes with at least one match
      if !matchedIngredients.isEmpty {
        let match = RecipeMatch(
          recipeDetails: recipeDetails,
          matchedIngredients: matchedIngredients,
          missingIngredients: missingIngredients,
          matchPercentage: matchPercentage
        )
        matches.append(match)
      }
    }

    // Sort by match percentage (highest first), then by number of matched ingredients
    matches.sort { first, second in
      if abs(first.matchPercentage - second.matchPercentage) < 0.001 {
        return first.matchScore > second.matchScore
      }
      return first.matchPercentage > second.matchPercentage
    }

    return matches
  }

  // MARK: - Private Helpers

  /// Parses user input into individual ingredient names
  private static func parseUserIngredients(_ input: String) -> [String] {
    // Split by comma or newline
    let separators = CharacterSet(charactersIn: ",\n")
    let ingredients = input.components(separatedBy: separators)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .map { $0.lowercased() }

    return ingredients
  }

  /// Extracts the base ingredient name from recipe ingredient text
  /// Example: "2 cups diced tomatoes" -> "tomatoes"
  private static func extractIngredientBaseName(_ ingredientText: String) -> String {
    // Simple approach: take last significant word(s) from ingredient text
    // Skip quantity, units, and common descriptors
    let skipWords = [
      "of", "the", "a", "an", "for", "to", "with", "fresh", "dried", "diced", "chopped", "sliced",
      "minced", "grated",
    ]
    let units = [
      "ml", "l", "tsp", "tbsp", "cup", "cups", "oz", "lb", "lbs", "g", "kg", "teaspoon",
      "teaspoons", "tablespoon", "tablespoons",
    ]

    let words = ingredientText.lowercased()
      .components(
        separatedBy: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",;()"))
      )
      .map { $0.trimmingCharacters(in: CharacterSet.punctuationCharacters) }
      .filter { word in
        !word.isEmpty && !skipWords.contains(word) && !units.contains(word) && Double(word) == nil  // Skip numbers
      }

    // Return the first meaningful word
    return words.first ?? ingredientText.lowercased()
  }

  /// Checks if a recipe ingredient matches any of the user's ingredients using fuzzy matching
  private static func matchesAny(recipeIngredient: String, userIngredients: [String]) -> Bool {
    let recipeIngredientLower = recipeIngredient.lowercased()

    for userIngredient in userIngredients {
      let userIngredientLower = userIngredient.lowercased()

      // Exact match
      if recipeIngredientLower == userIngredientLower {
        return true
      }

      // Contains match (e.g., "tomato" matches "cherry tomatoes")
      if recipeIngredientLower.contains(userIngredientLower)
        || userIngredientLower.contains(recipeIngredientLower)
      {
        return true
      }

      // Fuzzy match (handle plurals and common variations)
      if fuzzyMatch(recipeIngredientLower, userIngredientLower) {
        return true
      }
    }

    return false
  }

  /// Simple fuzzy matching for common ingredient variations
  private static func fuzzyMatch(_ a: String, _ b: String) -> Bool {
    // Remove common suffixes for plural matching
    let aSingular = removePlural(a)
    let bSingular = removePlural(b)

    if aSingular == bSingular {
      return true
    }

    // Levenshtein distance check (allow 1-2 character difference for typos)
    let distance = levenshteinDistance(aSingular, bSingular)
    let maxDistance = min(aSingular.count, bSingular.count) <= 4 ? 1 : 2

    return distance <= maxDistance
  }

  /// Removes common plural suffixes
  private static func removePlural(_ word: String) -> String {
    if word.hasSuffix("ies") {
      return String(word.dropLast(3)) + "y"
    }
    if word.hasSuffix("es") {
      return String(word.dropLast(2))
    }
    if word.hasSuffix("s") && !word.hasSuffix("ss") {
      return String(word.dropLast())
    }
    return word
  }

  /// Calculates Levenshtein distance between two strings
  private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
    let s1Array = Array(s1)
    let s2Array = Array(s2)

    var dist = Array(
      repeating: Array(repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)

    for i in 0...s1Array.count {
      dist[i][0] = i
    }

    for j in 0...s2Array.count {
      dist[0][j] = j
    }

    for i in 1...s1Array.count {
      for j in 1...s2Array.count {
        if s1Array[i - 1] == s2Array[j - 1] {
          dist[i][j] = dist[i - 1][j - 1]
        } else {
          dist[i][j] = min(
            dist[i - 1][j] + 1,  // deletion
            dist[i][j - 1] + 1,  // insertion
            dist[i - 1][j - 1] + 1  // substitution
          )
        }
      }
    }

    return dist[s1Array.count][s2Array.count]
  }
}
