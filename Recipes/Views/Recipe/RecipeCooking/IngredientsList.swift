//
//  IngredientsList.swift
//  Recipes
//
//  Created by Eliott on 14-12-2025.
//

import SQLiteData
import SwiftUI

struct CookingIngredient: Identifiable {
  var isCompleted: Bool
  let name: String

  var id: String { name }
}

struct IngredientsList: View {
  @Binding var cookingIngredients: [CookingIngredient]
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading) {
      List {
        ForEach($cookingIngredients) { $ingredient in
          HStack {
            Button {
              $ingredient.isCompleted.wrappedValue.toggle()
            } label: {
              Label(
                ingredient.isCompleted ? "Completed" : "Not completed",
                systemImage: ingredient.isCompleted ? "checkmark.circle.fill" : "circle"
              )
              .labelStyle(.iconOnly)
              .foregroundStyle(Color.accentColor)
              .font(.system(size: 24))
            }

            Text(ingredient.name)
              .foregroundStyle(ingredient.isCompleted ? .tertiary : .primary)
              .font(.headline)
          }
        }
      }
      .listStyle(.inset)
    }
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .title) {
        Text("Ingredients")
          .font(.title2)
          .fontWeight(.bold)
      }
      ToolbarItem(placement: .primaryAction) {
        Button {
          dismiss()
        } label: {
          Label("Close", systemImage: "xmark")
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var cookingIngredients: [CookingIngredient] = [
    CookingIngredient(isCompleted: false, name: "2 cups of flour"),
    CookingIngredient(isCompleted: true, name: "1 cup of sugar"),
    CookingIngredient(isCompleted: false, name: "3 eggs"),
  ]

  IngredientsList(cookingIngredients: $cookingIngredients)
}
