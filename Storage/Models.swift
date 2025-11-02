import Foundation
import SQLiteData

@Table("recipes")
public nonisolated struct RecipeRecord: Identifiable, Hashable, Sendable {
  public let id: UUID
  var title = ""
  var summary: String?
  var prepTimeMinutes: Int?
  var cookTimeMinutes: Int?
  var servings: Int?
  var createdAt: Date = .now
  var updatedAt: Date = .now
}

@Table("recipe_ingredients")
nonisolated struct RecipeIngredientRecord: Identifiable, Hashable, Sendable {
  let id: UUID
  var recipeId: RecipeRecord.ID
  var position: Int
  var text = ""
}

@Table("recipe_instructions")
nonisolated struct RecipeInstructionRecord: Identifiable, Hashable, Sendable {
  let id: UUID
  var recipeId: RecipeRecord.ID
  var position: Int
  var text = ""
}
