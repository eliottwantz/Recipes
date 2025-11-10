import Foundation
import SQLiteData

@Table("recipes")
public nonisolated struct Recipe: Identifiable, Hashable, Sendable {
  public let id: UUID
  var name = ""
  var prepTimeMinutes: Int
  var cookTimeMinutes: Int
  var servings: Int
  var createdAt: Date = .now
  var updatedAt: Date = .now
}

extension Recipe.Draft: Identifiable {}

@Table("recipe_ingredients")
nonisolated struct RecipeIngredient: Identifiable, Hashable, Sendable {
  let id: UUID
  var recipeId: Recipe.ID
  var position: Int = 0
  var text = ""
}

@Table("recipe_instructions")
nonisolated struct RecipeInstruction: Identifiable, Hashable, Sendable {
  let id: UUID
  var recipeId: Recipe.ID
  var position: Int = 0
  var text = ""
}
