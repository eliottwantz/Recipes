//
//  ShareExtensionBootstrap.swift
//  RecipeShareExtension
//
//  Created by Codex on 2025-10-25.
//

import SQLiteData
import OSLog

enum ShareExtensionBootstrap {
  private static let logger = Logger(subsystem: "RecipesShareExtension", category: "Bootstrap")

  static func configure() {
    prepareDependencies { values in
      do {
        values.defaultDatabase = try SharedStorageBootstrap.makeDatabase()
      } catch {
        logger.error("Failed to configure shared database: \(error.localizedDescription, privacy: .public)")
      }
    }
  }
}
