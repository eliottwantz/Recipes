//
//  RecipesApp.swift
//  Recipes
//
//  Created by Eliott on 2025-10-08.
//

import SwiftUI

@main
struct RecipesApp: App {
  @State private var appRouter = AppRouter()
//  @State private var timerManager = TimerManager()

  init() {
    Storage.configure()
    Task.detached {
      await TimerManager.shared.cleanupExpiredTimers()
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .environment(\.appRouter, appRouter)
//    .environment(\.timerManager, timerManager)
  }
}
