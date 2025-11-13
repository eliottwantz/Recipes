import Foundation
import SQLiteData

@Table("recipes")
nonisolated struct Recipe: Identifiable, Hashable, Sendable {
  let id: UUID
  var name = ""
  var prepTimeMinutes: Int = 0
  var cookTimeMinutes: Int = 0
  var servings: Int = 0
  var notes: String?
  var nutrition: String?
  var website: String?
  var createdAt: Date = .now
  var updatedAt: Date = .now
}

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

@Table("recipe_photos")
nonisolated struct RecipePhoto: Identifiable, Hashable, Sendable {
  let id: UUID
  var recipeId: Recipe.ID
  var position: Int = 0
  var photoData: Data = Data()
}
