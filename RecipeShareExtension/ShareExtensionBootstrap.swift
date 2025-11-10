//
//  ShareExtensionBootstrap.swift
//  RecipeShareExtension
//
//  Created by Eliott on 2025-10-25.
//

import OSLog
import SQLiteData

enum ShareExtensionBootstrap {
  private static let logger = Logger(subsystem: "RecipesShareExtension", category: "Bootstrap")
  private static var isConfigured = false

  static func configure() {
    guard !isConfigured else { return }
    prepareDependencies {
      do {
        try $0.bootstrapDatabase()
        isConfigured = true
      } catch {
        logger.error(
          "Failed to configure shared database: \(error.localizedDescription, privacy: .public)")
      }
    }
  }
}
