//
//  ShareExtensionBootstrap.swift
//  RecipeShareExtension
//
//  Created by Codex on 2025-10-25.
//

import Dependencies
import Foundation
import OSLog
import RecipeImportFeature
import SQLiteData

enum ShareExtensionBootstrap {
  private static let logger = Logger(subsystem: "RecipesShareExtension", category: "Bootstrap")

  static func configure() {
    prepareDependencies { values in
      do {
        values.defaultDatabase = try sharedDatabase()
      } catch {
        logger.error("Failed to configure shared database: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  private static func sharedDatabase() throws -> any DatabaseWriter {
    var configuration = Configuration()
    configuration.foreignKeysEnabled = true

    let databaseURL = try sharedDatabaseURL()
    let database = try SQLiteData.defaultDatabase(path: databaseURL.path, configuration: configuration)

    var migrator = DatabaseMigrator()
    #if DEBUG
      migrator.eraseDatabaseOnSchemaChange = true
    #endif
    migrator.registerMigration("Create recipes table") { db in
      try #sql(
        """
        CREATE TABLE IF NOT EXISTS "recipes" (
            "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
            "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
            "summary" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
            "ingredients" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
            "instructions" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
            "prepTimeMinutes" INTEGER,
            "cookTimeMinutes" INTEGER,
            "servings" INTEGER,
            "createdAt" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
            "updatedAt" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
        ) STRICT
        """
      ).execute(db)
    }

    try migrator.migrate(database)
    return database
  }

  private static func sharedDatabaseURL() throws -> URL {
    let fileManager = FileManager.default
    guard
      let containerURL = fileManager
        .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)
    else {
      throw ShareBootstrapError.missingAppGroupContainer
    }

    if fileManager.fileExists(atPath: containerURL.path) == false {
      try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
    }

    return containerURL.appendingPathComponent(AppGroup.databaseFilename)
  }
}

private enum ShareBootstrapError: LocalizedError {
  case missingAppGroupContainer

  var errorDescription: String? {
    "The Recipes app group container is unavailable."
  }
}
