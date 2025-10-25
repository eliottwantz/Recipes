import Dependencies
import Foundation
import RecipeImportFeature
import SQLiteData

protocol RecipeImportManaging {
  func importRecipe(from url: URL) async throws -> Recipe
}

struct RecipeImportManager: RecipeImportManaging {
  var importRecipe: @Sendable (_ url: URL) async throws -> Recipe

  func importRecipe(from url: URL) async throws -> Recipe {
    try await importRecipe(url)
  }

  func callAsFunction(_ url: URL) async throws -> Recipe {
    try await importRecipe(url)
  }
}

// MARK: - Live implementation

extension RecipeImportManager: DependencyKey {
  static let liveValue: RecipeImportManager = RecipeImportManager { url in
    @Dependency(\.urlSession) var urlSession
    @Dependency(\.defaultDatabase) var database
    @Dependency(\.date.now) var now

    let pipeline = RecipeImportPipeline()

    let importedRecipe = try await pipeline.importedRecipe(from: url, session: urlSession)
    return try persist(importedRecipe, in: database, now: now)
  }

  static var testValue: RecipeImportManager {
    RecipeImportManager { _ in
      throw RecipeImportError.unimplemented
    }
  }
}

// MARK: - Pipeline helpers

extension RecipeImportManager {
  fileprivate nonisolated static func persist(
    _ imported: ImportedRecipe,
    in database: any DatabaseWriter,
    now: Date
  ) throws -> Recipe {
    let recipe = Recipe(
      id: UUID(),
      title: imported.title,
      summary: imported.summary ?? "",
      ingredients: imported.ingredients.joined(separator: "\n"),
      instructions: imported.instructions.joined(separator: "\n"),
      prepTimeMinutes: imported.prepMinutes,
      cookTimeMinutes: imported.cookMinutes,
      servings: imported.servings,
      createdAt: now,
      updatedAt: now
    )

    try database.write { db in
      try Recipe.insert { recipe }.execute(db)
    }

    return recipe
  }
}

// MARK: - Debug Harness

#if DEBUG
  enum RecipeImportHarness {
    static func importSampleRecipe() throws -> Recipe {
      @Dependency(\.defaultDatabase) var database
      return try importSampleRecipe(using: database)
    }

    static func importSampleRecipe(using database: any DatabaseWriter) throws -> Recipe {
      let sampleHTML = """
        <html>
          <head>
            <script type="application/ld+json">
              {
                "@context": "https://schema.org/",
                "@type": "Recipe",
                "name": "Sample Garlic Pasta",
                "description": "Quick pasta tossed with garlic, olive oil, and herbs.",
                "recipeIngredient": [
                  "8 oz spaghetti",
                  "3 cloves garlic, minced",
                  "2 tbsp olive oil",
                  "1 tsp chili flakes",
                  "Salt and pepper to taste"
                ],
                "recipeInstructions": [
                  { "@type": "HowToStep", "text": "Cook pasta in salted water until al dente." },
                  { "@type": "HowToStep", "text": "Sauté garlic in olive oil, add chili flakes." },
                  { "@type": "HowToStep", "text": "Toss pasta with garlic oil and seasonings." }
                ],
                "prepTime": "PT10M",
                "cookTime": "PT12M",
                "recipeYield": "2 servings"
              }
            </script>
          </head>
        </html>
        """

      let pipeline = RecipeImportPipeline()
      let recipeJSON = try pipeline.extractRecipeJSON(from: sampleHTML)
      let imported = try ImportedRecipe(json: recipeJSON)
      return try RecipeImportManager.persist(imported, in: database, now: .now)
    }
  }
#endif
