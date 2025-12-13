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
            CookingStepView(instruction: instruction)
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
      .onAppear {
        UIPageControl.appearance(whenContainedInInstancesOf: [UIViewController.self])
          .currentPageIndicatorTintColor = UIColor(.accentColor)
      }
    }
    .safeAreaBar(edge: .bottom, alignment: .trailing) {
      CookingStepButtons(
        currentStepIndex: $currentStepIndex, totalSteps: recipeDetails.instructions.count
      )
      .padding(.bottom, 45)
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
    .padding(.bottom, 50)
  }

  private struct CookingStepButtons: View {
    @Binding var currentStepIndex: Int
    let totalSteps: Int

    var body: some View {
      HStack {
        if currentStepIndex > 0 {
          Button {
            withAnimation {
              currentStepIndex -= 1
            }
          } label: {
            Image(systemName: "arrow.left")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundStyle(.primary)
          }
          .buttonStyle(.glassProminent)
          .buttonBorderShape(.circle)
          .controlSize(.large)
          .sensoryFeedback(.decrease, trigger: currentStepIndex)
        }

        Spacer()

        if currentStepIndex < totalSteps - 1 {
          Button {
            withAnimation {
              currentStepIndex += 1
            }
          } label: {
            Image(systemName: "arrow.right")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundStyle(.primary)
          }
          .buttonStyle(.glassProminent)
          .buttonBorderShape(.circle)
          .controlSize(.large)
          .sensoryFeedback(.increase, trigger: currentStepIndex)
        }
      }
      .padding(.horizontal, 30)
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

  RecipeCookingScreen(recipeDetails: recipeDetails)
}
