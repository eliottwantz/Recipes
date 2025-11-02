import CloudKit
import Dependencies
import Foundation
import OSLog
import SQLiteData

enum StorageBootstrap {
  static let appGroupIdentifier = "group.com.develiott.Recipes"
  static let databaseFilename = "Recipes.sqlite"

  static func appDatabase(fileManager: FileManager = .default) throws -> any DatabaseWriter {
    @Dependency(\.context) var context

    var configuration = Configuration()
    configuration.foreignKeysEnabled = true

    #if DEBUG
      if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
        configuration.prepareDatabase { db in
          try db.attachMetadatabase()
        }
      }
    #endif

    #if DEBUG
      configuration.prepareDatabase { db in
        db.trace(options: .profile) {
          if context == .preview {
            print("\($0.expandedDescription)")
          } else {
            storageLogger.debug("\($0.expandedDescription)")
          }
        }
      }
    #endif

    let databaseURL = try sharedDatabaseURL(fileManager: fileManager)
    let database = try SQLiteData.defaultDatabase(
      path: databaseURL.path,
      configuration: configuration
    )

    #if DEBUG
      if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
        print("DB PATH:\n\(database.path)")
      } else {
        storageLogger.info("DB PATH:\n\(database.path)")
      }
    #endif

    var migrator = DatabaseMigrator()

    #if DEBUG
      migrator.eraseDatabaseOnSchemaChange = true
    #endif

    migrator.registerMigration("Create recipes table") { db in
      try #sql(
        """
        CREATE TABLE "recipes" (
            "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
            "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
            "summary" TEXT,
            "prepTimeMinutes" INTEGER,
            "cookTimeMinutes" INTEGER,
            "servings" INTEGER,
            "createdAt" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
            "updatedAt" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
        ) STRICT
        """
      ).execute(db)

      try #sql(
        """
        CREATE TABLE "recipe_ingredients" (
            "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
            "recipeId" TEXT NOT NULL REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE CASCADE,
            "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
            "text" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT ''
        ) STRICT
        """
      ).execute(db)

      try #sql(
        """
        CREATE TABLE "recipe_instructions" (
            "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
            "recipeId" TEXT NOT NULL REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE CASCADE,
            "position" INTEGER NOT NULL,
            "text" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT ''
        ) STRICT
        """
      ).execute(db)

    }

    #if DEBUG
      migrator.registerMigration("Seed recipes") { db in
        @Dependency(\.date.now) var now
        @Dependency(\.uuid) var uuid

        try db.seed {
          let ids = (0...1).map { _ in uuid() }
          RecipeRecord(
            id: ids[0],
            title: "Heirloom Tomato Bruschetta",
            summary: "Toasted baguette topped with juicy tomatoes, basil, and garlic.",
            prepTimeMinutes: 15,
            cookTimeMinutes: 5,
            servings: 6,
            createdAt: now,
            updatedAt: now,
          )
          RecipeIngredientRecord(id: uuid(), recipeId: ids[0], position: 0, text: "1 baguette")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[0], position: 1, text: "2 cups diced heirloom tomatoes")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[0], position: 2, text: "2 cloves garlic, minced")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[0], position: 3, text: "6 fresh basil leaves, chopped")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[0], position: 4, text: "2 tbsp extra-virgin olive oil")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[0], position: 5, text: "Salt and pepper to taste")

          RecipeInstructionRecord(
            id: uuid(), recipeId: ids[0], position: 0,
            text: "Slice baguette and toast until golden.")
          RecipeInstructionRecord(
            id: uuid(), recipeId: ids[0], position: 1,
            text: "Toss tomatoes, garlic, basil, and olive oil with salt and pepper.")
          RecipeInstructionRecord(
            id: uuid(), recipeId: ids[0], position: 2,
            text: "Spoon tomato mixture over warm baguette slices and serve immediately.")

          RecipeRecord(
            id: ids[1],
            title: "Creamy Mushroom Risotto",
            summary: "Classic risotto with sautéed cremini mushrooms and parmesan.",
            prepTimeMinutes: 10,
            cookTimeMinutes: 20,
            servings: 4,
            createdAt: now,
            updatedAt: now,
          )

          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[1], position: 0, text: "4 cups vegetable broth")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[1], position: 1, text: "1 cup arborio rice")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[1], position: 2, text: "8 oz cremini mushrooms, sliced")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[1], position: 3, text: "1 shallot, minced")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[1], position: 4, text: "2 cloves garlic, minced")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[1], position: 5, text: "1/2 cup dry white wine")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[1], position: 6, text: "1/2 cup grated parmesan")
          RecipeIngredientRecord(id: uuid(), recipeId: ids[1], position: 7, text: "2 tbsp butter")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[1], position: 8, text: "2 tbsp olive oil")
          RecipeIngredientRecord(
            id: uuid(), recipeId: ids[1], position: 9, text: "Salt and pepper to taste")

          RecipeInstructionRecord(
            id: uuid(), recipeId: ids[1], position: 0,
            text: "Warm broth in a saucepan over low heat.")
          RecipeInstructionRecord(
            id: uuid(), recipeId: ids[1], position: 1,
            text: "Sauté mushrooms in olive oil until browned.")
          RecipeInstructionRecord(
            id: uuid(), recipeId: ids[1], position: 2,
            text: "Cook shallot and garlic in butter until fragrant, then stir in rice.")
          RecipeInstructionRecord(
            id: uuid(), recipeId: ids[1], position: 3,
            text: "Deglaze with wine, stir until absorbed, then add broth one ladle at a time.")
          RecipeInstructionRecord(
            id: uuid(), recipeId: ids[1], position: 3,
            text: "Fold in mushrooms and parmesan once rice is creamy and al dente.")
          RecipeInstructionRecord(
            id: uuid(), recipeId: ids[1], position: 4, text: "Season to taste and serve hot.")
        }

      }
    #endif

    try migrator.migrate(database)
    return database
  }

  static func sharedDatabaseURL(fileManager: FileManager = .default) throws -> URL {
    guard
      let containerURL = fileManager.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupIdentifier
      )
    else {
      throw StorageError.missingAppGroupContainer
    }

    if fileManager.fileExists(atPath: containerURL.path) == false {
      try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
    }

    return containerURL.appendingPathComponent(databaseFilename)
  }

  static func configure() {
    prepareDependencies {
      do {
        $0.defaultDatabase = try appDatabase()
      } catch {
        assertionFailure("Failed to configure database: \(error)")
      }
      #if !targetEnvironment(simulator)
        $0.defaultSyncEngine = try! SyncEngine(
          for: $0.defaultDatabase,
          tables: Recipe.self,
        )
      #endif
    }
  }

  static func configurePreview() {
    prepareDependencies {
      do {
        $0.defaultDatabase = try appDatabase()
      } catch {
        print("Failed to configure preview database: \(error)")
      }
    }
  }

  static func configurePreviewWithInitialFetcher<T>(
    _ fetcher: (_ database: any DatabaseWriter) throws -> T
  ) -> T {
    let result: T = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
      return try! fetcher($0.defaultDatabase)
    }
    return result
  }

//  static private func appDatabase() throws -> any DatabaseWriter {
//    try Self.makeDatabase()
//  }
}

nonisolated private let storageLogger = Logger(subsystem: "Recepies", category: "Database")

enum StorageError: LocalizedError {
  case missingAppGroupContainer

  var errorDescription: String? {
    "The shared app group container could not be located."
  }
}
