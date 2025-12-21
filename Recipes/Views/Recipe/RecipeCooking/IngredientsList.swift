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

            ingredientText(for: ingredient.name, isCompleted: ingredient.isCompleted)
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
        Button(role: .close) {
          dismiss()
        }
      }
    }
  }
  
  @ViewBuilder
  private func ingredientText(for text: String, isCompleted: Bool) -> some View {
    let parsed = text.parseIngredient()
    
    if let range = parsed.quantityUnitRange {
      let beforeRange = String(text[..<range.lowerBound])
      let quantityUnit = String(text[range])
      let afterRange = String(text[range.upperBound...])
    
      Text(
        """
        \(Text(beforeRange))\
        \(Text(quantityUnit)
          .foregroundStyle(Color.accentColor)
          .fontWeight(.semibold))\
        \(Text(afterRange))
        """
      )
        .foregroundStyle(isCompleted ? .tertiary : .primary)
        .font(.headline)
    } else {
      Text(text)
        .foregroundStyle(isCompleted ? .tertiary : .primary)
        .font(.headline)
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
