import CloudKit
import Dependencies
import Foundation
import OSLog
import SQLiteData

enum Storage {
  static let appGroupIdentifier = "group.com.develiott.Recipes"
  static let databaseFilename = "Recipes.sqlite"

  static func sharedDatabaseURL() throws -> URL {
    let fileManager: FileManager = .default
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
    try! prepareDependencies {
      try $0.bootstrapDatabase()
    }
  }

  static func configure<T>(_ fetcher: (_ database: any DatabaseWriter) throws -> T) -> T {
    let result: T = try! prepareDependencies {
      try $0.bootstrapDatabase()
      return try! fetcher($0.defaultDatabase)
    }
    return result
  }
}

extension DependencyValues {
  mutating func bootstrapDatabase() throws {
    @Dependency(\.context) var context

    var configuration = Configuration()
    configuration.foreignKeysEnabled = true

    //    #if DEBUG
    //      if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
    //        configuration.prepareDatabase { db in
    //          try db.attachMetadatabase()
    //        }
    //      }
    //    #endif

    #if DEBUG
      configuration.prepareDatabase { db in
        db.trace(options: .profile) {
          if context == .preview {
            print("\($0.expandedDescription)")
          } else {
            logger.debug("\($0.expandedDescription)")
          }
        }
      }
    #endif

    let databaseURL = try Storage.sharedDatabaseURL()
    let database = try SQLiteData.defaultDatabase(
      path: databaseURL.path,
      configuration: configuration
    )

    var migrator = DatabaseMigrator()

    #if DEBUG
      migrator.eraseDatabaseOnSchemaChange = true
    #endif

    migrator.registerMigration("Create recipes table") { db in
      try #sql(
        """
        CREATE TABLE "recipes" (
            "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
            "name" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
            "prepTimeMinutes" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
            "cookTimeMinutes" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
            "servings" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
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
            "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
            "text" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT ''
        ) STRICT
        """
      ).execute(db)

    }

    migrator.registerMigration("Add optional recipe fields") { db in
      try #sql(
        """
        ALTER TABLE "recipes" ADD COLUMN "notes" TEXT
        """
      ).execute(db)

      try #sql(
        """
        ALTER TABLE "recipes" ADD COLUMN "nutrition" TEXT
        """
      ).execute(db)

      try #sql(
        """
        ALTER TABLE "recipes" ADD COLUMN "website" TEXT
        """
      ).execute(db)

      try #sql(
        """
        CREATE TABLE "recipe_photos" (
            "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
            "recipeId" TEXT NOT NULL REFERENCES "recipes"("id") ON DELETE CASCADE ON UPDATE CASCADE,
            "position" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
            "photoData" BLOB NOT NULL ON CONFLICT REPLACE DEFAULT (x'')
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
          Recipe(
            id: ids[0],
            name: "Heirloom Tomato Bruschetta",
            prepTimeMinutes: 15,
            cookTimeMinutes: 5,
            servings: 6,
            createdAt: now,
            updatedAt: now,
          )
          RecipeIngredient(id: uuid(), recipeId: ids[0], position: 0, text: "1 baguette")
          RecipeIngredient(
            id: uuid(), recipeId: ids[0], position: 1, text: "2 cups diced heirloom tomatoes")
          RecipeIngredient(
            id: uuid(), recipeId: ids[0], position: 2, text: "2 cloves garlic, minced")
          RecipeIngredient(
            id: uuid(), recipeId: ids[0], position: 3, text: "6 fresh basil leaves, chopped")
          RecipeIngredient(
            id: uuid(), recipeId: ids[0], position: 4, text: "2 tbsp extra-virgin olive oil")
          RecipeIngredient(
            id: uuid(), recipeId: ids[0], position: 5, text: "Salt and pepper to taste")

          RecipeInstruction(
            id: uuid(), recipeId: ids[0], position: 0,
            text: "Slice baguette and toast until golden.")
          RecipeInstruction(
            id: uuid(), recipeId: ids[0], position: 1,
            text: "Toss tomatoes, garlic, basil, and olive oil with salt and pepper.")
          RecipeInstruction(
            id: uuid(), recipeId: ids[0], position: 2,
            text: "Spoon tomato mixture over warm baguette slices and serve immediately.")

          Recipe(
            id: ids[1],
            name: "Creamy Mushroom Risotto",
            prepTimeMinutes: 10,
            cookTimeMinutes: 20,
            servings: 4,
            createdAt: now,
            updatedAt: now,
          )

          RecipeIngredient(
            id: uuid(), recipeId: ids[1], position: 0, text: "4 cups vegetable broth")
          RecipeIngredient(
            id: uuid(), recipeId: ids[1], position: 1, text: "1 cup arborio rice")
          RecipeIngredient(
            id: uuid(), recipeId: ids[1], position: 2, text: "8 oz cremini mushrooms, sliced")
          RecipeIngredient(
            id: uuid(), recipeId: ids[1], position: 3, text: "1 shallot, minced")
          RecipeIngredient(
            id: uuid(), recipeId: ids[1], position: 4, text: "2 cloves garlic, minced")
          RecipeIngredient(
            id: uuid(), recipeId: ids[1], position: 5, text: "1/2 cup dry white wine")
          RecipeIngredient(
            id: uuid(), recipeId: ids[1], position: 6, text: "1/2 cup grated parmesan")
          RecipeIngredient(id: uuid(), recipeId: ids[1], position: 7, text: "2 tbsp butter")
          RecipeIngredient(
            id: uuid(), recipeId: ids[1], position: 8, text: "2 tbsp olive oil")
          RecipeIngredient(
            id: uuid(), recipeId: ids[1], position: 9, text: "Salt and pepper to taste")

          RecipeInstruction(
            id: uuid(), recipeId: ids[1], position: 0,
            text: "Warm broth in a saucepan over low heat.")
          RecipeInstruction(
            id: uuid(), recipeId: ids[1], position: 1,
            text: "Sauté mushrooms in olive oil until browned.")
          RecipeInstruction(
            id: uuid(), recipeId: ids[1], position: 2,
            text: "Cook shallot and garlic in butter until fragrant, then stir in rice.")
          RecipeInstruction(
            id: uuid(), recipeId: ids[1], position: 3,
            text: "Deglaze with wine, stir until absorbed, then add broth one ladle at a time.")
          RecipeInstruction(
            id: uuid(), recipeId: ids[1], position: 3,
            text: "Fold in mushrooms and parmesan once rice is creamy and al dente.")
          RecipeInstruction(
            id: uuid(), recipeId: ids[1], position: 4, text: "Season to taste and serve hot.")
        }

      }
    #endif

    try migrator.migrate(database)

    defaultDatabase = database
    #if !targetEnvironment(simulator)
      defaultSyncEngine = try SyncEngine(
        for: defaultDatabase,
        tables: Recipe.self,
        RecipeIngredient.self,
        RecipeInstruction.self,
        RecipePhoto.self
      )
    #endif

    #if DEBUG
      if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
        print("DB PATH:\n\(database.path)")
      } else {
        logger.info("DB PATH:\n\(database.path)")
      }
    #endif
  }
}

nonisolated private let logger = Logger(subsystem: "Recepies", category: "Database")

enum StorageError: LocalizedError {
  case missingAppGroupContainer

  var errorDescription: String? {
    "The shared app group container could not be located."
  }
}
