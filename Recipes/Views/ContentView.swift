//
//  ContentView.swift
//  Recipes
//
//  Created by Eliott on 2025-10-08.
//

import SwiftUI

struct ContentView: View {
  private var appRouter = AppRouter.shared

  var body: some View {
    @Bindable var appRouter = appRouter

    TabView(selection: $appRouter.selectedTab) {
      Tab(value: AppRouter.Tab.recipeList) {
        RecipeListScreen()
      } label: {
        Label("Recipes", systemImage: "book.pages")
      }

      Tab(value: AppRouter.Tab.settings) {
        SettingsScreen()
      } label: {
        Label("Settings", systemImage: "gear")
      }

    }
  }
}

#Preview {
  Storage.configure()
  return Group {
    ContentView()
  }
}
