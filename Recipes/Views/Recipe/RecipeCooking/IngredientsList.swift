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
  @State var cookingIngredients: [CookingIngredient]

  init(recipeIngredients: [RecipeIngredient]) {
    self.cookingIngredients = recipeIngredients.map { ingredient in
      CookingIngredient(isCompleted: false, name: ingredient.text)
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("All ingredients")
        .font(.title)
        .padding(.top)
        .padding(.leading)

      List {
        ForEach($cookingIngredients) { $ingredient in
          HStack {
            Button {
              $ingredient.isCompleted.wrappedValue.toggle()
            } label: {
              Label(
                ingredient.isCompleted ? "Completed" : "Not completed",
                systemImage: ingredient.isCompleted ? "checkmark.square.fill" : "square"
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
  }
}

#Preview {
  let recipeDetails = Storage.configure { database in
    return try database.read { db in
      print("FETCHING RECIPE FOR PREVIEW")
      let recipe = try Recipe.all.fetchOne(db)
      guard let recipe else { fatalError("No recipe found. Seed the database first.") }
      let results = try RecipeDetails.FetchKeyRequest(recipeId: recipe.id).fetch(db)
      return RecipeDetails(
        recipe: recipe, ingredients: results.ingredients, instructions: results.instructions)
    }
  }

  IngredientsList(recipeIngredients: recipeDetails.ingredients)
}
