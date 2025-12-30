//
//  RecipeProcessingView.swift
//  Recipes
//
//  Created by Eliott on 2025-12-28.
//

import SwiftUI

struct RecipeProcessingView: View {
  enum Status: Equatable {
    case extractingText
    case parsingRecipe
  }

  let status: Status
  let onCancel: () -> Void

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        ProgressView()
          .scaleEffect(1.5)

        Text(title)
          .font(.headline)

        Text(subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .navigationTitle("Import from Photo")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .cancel, action: onCancel)
        }
      }
    }
    .interactiveDismissDisabled()
  }

  private var title: LocalizedStringKey {
    switch status {
    case .extractingText:
      "Reading photo..."
    case .parsingRecipe:
      "Parsing recipe..."
    }
  }

  private var subtitle: LocalizedStringKey {
    switch status {
    case .extractingText:
      "Extracting text from image"
    case .parsingRecipe:
      "Identifying ingredients and instructions"
    }
  }
}

#Preview {
  RecipeProcessingView(status: .extractingText) {}
}
