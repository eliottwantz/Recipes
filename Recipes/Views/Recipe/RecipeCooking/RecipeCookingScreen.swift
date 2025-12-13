//
//  RecipeCookingScreen.swift
//  Recipes
//
//  Created by Eliott on 12-12-2025.
//

import SQLiteData
import SwiftUI

struct RecipeCookingScreen: View {
  @Environment(\.dismiss) private var dismiss
  @State private var currentStepIndex = 0

  let recipeDetails: RecipeDetails

  var body: some View {
    NavigationStack {
      TabView(selection: $currentStepIndex) {
        ForEach(recipeDetails.instructions) { instruction in
          Tab(value: instruction.position) {
            VStack {
              CookingStepView(instruction: instruction)

              Spacer()

            }
            .frame(maxHeight: .infinity)
          }
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .automatic))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }
        }
      }
      CookingStepButtons()
    }
  }

  @ViewBuilder
  private func CookingStepView(instruction: RecipeInstruction) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Step \(instruction.position + 1)")
        .foregroundStyle(.secondary)
        .font(.subheadline)
        .fontWeight(.semibold)

      ScrollView {
        Text(instruction.text)
          .font(.body)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
          .multilineTextAlignment(.leading)
      }
      .scrollBounceBehavior(.basedOnSize, axes: .vertical)
      .scrollIndicators(.hidden)
      
      Spacer()
    }
    .frame(maxHeight: .infinity)
    .padding(30)
  }

  @ViewBuilder
  private func CookingStepButtons() -> some View {
    HStack {
      Button {
        if currentStepIndex > 0 {
          withAnimation {
            currentStepIndex -= 1
          }
        }
      } label: {
        Image(systemName: "chevron.left")
          .font(.title2)
          .foregroundStyle(currentStepIndex > 0 ? .primary : .secondary)
      }
      .disabled(currentStepIndex == 0)

      Spacer()

      Button {
        if currentStepIndex < recipeDetails.instructions.count - 1 {
          withAnimation {
            currentStepIndex += 1
          }
        }
      } label: {
        Image(systemName: "chevron.right")
          .font(.title2)
          .foregroundStyle(
            currentStepIndex < recipeDetails.instructions.count - 1 ? .primary : .secondary)
      }
      .disabled(currentStepIndex == recipeDetails.instructions.count - 1)
    }
    .padding()
    .background(.regularMaterial)
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

  RecipeCookingScreen(recipeDetails: recipeDetails)
}
