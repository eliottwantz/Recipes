//
//  AppRouter.swift
//  Recipes
//
//  Created by Eliott on 2025-11-05.
//

import Dependencies
import SQLiteData
import SwiftUI
import os

@Observable
public final class AppRouter {
  static let shared = AppRouter()

  enum Tab {
    case recipeList
    case settings
  }

  var selectedTab: Tab = .recipeList
  var navigationPath = NavigationPath()

  /// Active cooking session - controls fullScreenCover presentation
  var activeCookingSession: CookingSession?

  struct CookingSession: Identifiable, Equatable {
    let id: Recipe.ID
    var currentStep: Int

    init(recipeId: Recipe.ID, currentStep: Int = 0) {
      self.id = recipeId
      self.currentStep = currentStep
    }
  }

  private init() {}

  func navigateToRecipe(_ recipeId: Recipe.ID, cookingStep: Int? = nil) {
    @Dependency(\.defaultDatabase) var database
    let recipeExists = withErrorReporting {
      let recipeId = try database.read { db in
        try Recipe.where { $0.id == recipeId }.select(\.id).fetchOne(db)
      }
      return recipeId != nil
    }

    guard let recipeExists else { return }
    guard recipeExists else {
      TimerManager.shared.cleanupTimersForRecipe(recipeId)
      return
    }

    selectedTab = .recipeList
    navigationPath = NavigationPath()
    navigationPath.append(recipeId)

    if let step = cookingStep {
      openCookingScreen(for: recipeId, step: step)
    }
  }

  func openCookingScreen(for recipeId: Recipe.ID, step: Int = 0) {
    activeCookingSession = CookingSession(recipeId: recipeId, currentStep: step)
  }

  func closeCookingScreen() {
    activeCookingSession = nil
  }

  @discardableResult
  func handleDeepLink(_ url: URL) -> Bool {
    guard url.scheme == Constants.urlScheme else { return false }

    logger.info("🚧 Handling deep link URL: \(url.absoluteString)")

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

private let logger = Logger(subsystem: "com.develiott.Recipes", category: "AppRouter")
