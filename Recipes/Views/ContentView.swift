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
          .tint(.accentColor)
      }

      Tab(value: AppRouter.Tab.settings) {
        Button {
          appRouter.selectedTab = .recipeList
        } label: {
          Label("Go to recipe list", systemImage: "book.pages")
        }
      } label: {
        Label("Settings", systemImage: "gear")
          .tint(.accentColor)
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
