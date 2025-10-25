//
//  RecipeDraft.swift
//  RecipeShareExtension
//
//  Created by Eliott on 2025-10-25.
//

import Foundation
import RecipeImportFeature

/// Mutable recipe representation that mirrors the persisted `Recipe` model.
struct RecipeDraft: Equatable {
  var title: String
  var summary: String
  var ingredients: [String]
  var instructions: [String]
  var prepTimeMinutes: Int?
  var cookTimeMinutes: Int?
  var servings: Int?

  init(
    title: String = "",
    summary: String = "",
    ingredients: [String] = [],
    instructions: [String] = [],
    prepTimeMinutes: Int? = nil,
    cookTimeMinutes: Int? = nil,
    servings: Int? = nil
  ) {
    self.title = title
    self.summary = summary
    self.ingredients = ingredients
    self.instructions = instructions
    self.prepTimeMinutes = prepTimeMinutes
    self.cookTimeMinutes = cookTimeMinutes
    self.servings = servings
  }

  init(imported: ImportedRecipe) {
    title = imported.title
    summary = imported.summary ?? ""
    ingredients = imported.ingredients
    instructions = imported.instructions
    prepTimeMinutes = imported.prepMinutes
    cookTimeMinutes = imported.cookMinutes
    servings = imported.servings
  }

  var ingredientsText: String {
    get { ingredients.joined(separator: "\n") }
    set { ingredients = RecipeDraft.normalizedLines(from: newValue) }
  }

  var instructionsText: String {
    get { instructions.joined(separator: "\n") }
    set { instructions = RecipeDraft.normalizedLines(from: newValue) }
  }

  private static func normalizedLines(from text: String) -> [String] {
    text
      .components(separatedBy: CharacterSet.newlines)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { $0.isEmpty == false }
  }
}
