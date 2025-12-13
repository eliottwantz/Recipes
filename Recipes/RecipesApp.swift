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

  init() {
    Storage.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .tint(.accent)
    }
    .environment(\.appRouter, appRouter)

  }
}
