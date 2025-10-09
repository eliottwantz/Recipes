//
//  ContentView.swift
//  Recipes
//
//  Created by Eliott on 2025-10-08.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            RecipeListView()
        }
    }
}

#Preview {
    StorageBootstrap.configure()
    return ContentView()
}
