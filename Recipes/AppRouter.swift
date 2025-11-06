//
//  AppRouter.swift
//  Recipes
//
//  Created by Eliott on 2025-11-05.
//

import SwiftUI
import SwiftUINavigation

@Observable
public final class AppRouter {
  var selectedTab: Tab

  enum Tab {
    case recipeList
    case settings
  }

  init(selectedTab: Tab = .recipeList) {
    self.selectedTab = selectedTab
  }
}

extension EnvironmentValues {
  @Entry var appRouter: AppRouter = AppRouter()
}
