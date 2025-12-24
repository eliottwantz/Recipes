//
//  AppRouter.swift
//  Recipes
//
//  Created by Eliott on 2025-11-05.
//

import Dependencies
import SQLiteData
import SwiftUI

@Observable
public final class AppRouter {
  var selectedTab: Tab
  var navigationPath = NavigationPath()

  /// Pending deep link destination to open cooking screen with a specific step
  var pendingCookingStep: Int?

  @ObservationIgnored @Dependency(\.defaultDatabase) private var database

  enum Tab {
    case recipeList
    case settings
  }

  init(selectedTab: Tab = .recipeList) {
    self.selectedTab = selectedTab
  }

  /// Navigate to a specific recipe, optionally opening the cooking screen at a specific step
  func navigateToRecipe(_ recipeId: Recipe.ID, cookingStep: Int? = nil) {
    let recipeExists = withErrorReporting {
      let recipeId = try database.read { db in
        try Recipe.where { $0.id == recipeId }.select(\.id).fetchOne(db)
      }
      return recipeId != nil
    }

    guard let recipeExists else { return }
    guard recipeExists else {
      // Recipe was deleted, clean up associated timers
      TimerManager.shared.cleanupTimersForRecipe(recipeId)
      return
    }

    // Reset navigation and set up new path
    selectedTab = .recipeList
    navigationPath = NavigationPath()
    pendingCookingStep = cookingStep

    // Push the recipe onto the navigation stack
    navigationPath.append(recipeId)
  }

  /// Handle a deep link URL
  /// - Returns: true if the URL was handled, false otherwise
  @discardableResult
  func handleDeepLink(_ url: URL) -> Bool {
    guard url.scheme == Constants.urlScheme else { return false }

    // Expected format: com.develiott.recipes://recipe/{recipeID}?step={instructionStep}
    guard url.host == "recipe" else { return false }

    let pathComponents = url.pathComponents.filter { $0 != "/" }
    guard let recipeIdString = pathComponents.first,
      let recipeId = UUID(uuidString: recipeIdString)
    else {
      return false
    }

    // Parse optional step parameter
    var cookingStep: Int?
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let stepString = components.queryItems?.first(where: { $0.name == "step" })?.value,
      let step = Int(stepString)
    {
      cookingStep = step
    }

    navigateToRecipe(recipeId, cookingStep: cookingStep)
    return true
  }
}

extension EnvironmentValues {
  @Entry var appRouter: AppRouter = AppRouter()
}
