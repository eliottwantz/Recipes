//
//  RecipesApp.swift
//  Recipes
//
//  Created by Eliott on 2025-10-08.
//

import SwiftUI

@main
struct RecipesApp: App {
  init() {
    Storage.configure()
    Task.detached {
      await TimerManager.shared.cleanupExpiredTimers()
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onOpenURL { url in
          AppRouter.shared.handleDeepLink(url)
        }
    }
  }
}
