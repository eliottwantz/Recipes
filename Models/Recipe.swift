import Foundation
import SQLiteData

@Table("recipes")
struct Recipe: Identifiable, Hashable, Sendable {
  let id: UUID
  var title = ""
  var summary = ""
  var ingredients = ""
  var instructions = ""
  var prepTimeMinutes: Int?
  var cookTimeMinutes: Int?
  var servings: Int?
  var createdAt: Date = .now
  var updatedAt: Date = .now
}
