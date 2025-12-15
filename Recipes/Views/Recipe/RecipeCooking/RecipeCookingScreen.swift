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
  @State private var showIngredientsSheet = false
  @State private var searchTerm = ""
  @State private var currentDetent: PresentationDetent = .fraction(0.45)
  @State private var cookingIngredients: [CookingIngredient]
  @State private var showTimerPicker = false
  @State private var timerHours = 0
  @State private var timerMinutes = 0
  @State private var timerSeconds = 0

  let recipeDetails: RecipeDetails

  init(recipeDetails: RecipeDetails) {
    self.recipeDetails = recipeDetails
    self._cookingIngredients = State(
      initialValue: recipeDetails.ingredients.map { ingredient in
        CookingIngredient(isCompleted: false, name: ingredient.text)
      }
    )
  }

  var body: some View {
    GeometryReader { geometry in
      NavigationStack {
        ZStack {
          TabView(selection: $currentStepIndex) {
            ForEach(recipeDetails.instructions) { instruction in
              Tab(value: instruction.position) {
                CookingStepView(instruction: instruction)
              }
            }
          }
          .tabViewStyle(.page(indexDisplayMode: .automatic))

          VStack(alignment: .center) {
            Spacer()

            CookingStepButtons(
              currentStepIndex: $currentStepIndex, totalSteps: recipeDetails.instructions.count
            )
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(
          .bottom,
          showIngredientsSheet ? geometry.size.height * 0.45 : 0
        )
        .animation(.easeOut(duration: 0.25), value: showIngredientsSheet)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
              dismiss()
            }
          }
          ToolbarItemGroup(placement: .primaryAction) {
            Button {
              showTimerPicker = true
            } label: {
              Label("Start timer", systemImage: "timer")
            }
            Button {
              showIngredientsSheet.toggle()
            } label: {
              Label("Ingredients", systemImage: "list.bullet")
            }
          }
        }
        .onAppear {
          UIPageControl.appearance(whenContainedInInstancesOf: [UIViewController.self])
            .currentPageIndicatorTintColor = UIColor(.accentColor)
        }
      }
      .sheet(isPresented: $showIngredientsSheet) {
        NavigationStack {
          IngredientsList(cookingIngredients: $cookingIngredients)
            .presentationDetents([.fraction(0.45), .large], selection: $currentDetent)
            .presentationDragIndicator(.hidden)
            .presentationContentInteraction(.scrolls)
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.45)))
        }
      }
      .sheet(isPresented: $showTimerPicker) {
        CountdownTimerPickerView(
          hours: $timerHours,
          minutes: $timerMinutes,
          seconds: $timerSeconds,
          onStart: {
            // For now, just print the selected time
            // This is where AlarmKit integration will happen later
            print("Timer started: \(timerHours)h \(timerMinutes)m \(timerSeconds)s")
          }
        )
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
      }
    }
  }

  @ViewBuilder
  private func CookingStepView(instruction: RecipeInstruction) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Step \(instruction.position + 1)")
        .foregroundStyle(.secondary)
        .font(.subheadline)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, alignment: .leading)
      ScrollView {
        Text(instruction.text)
          .font(.system(size: 18))
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
          .multilineTextAlignment(.leading)
          .lineSpacing(8)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .scrollBounceBehavior(.basedOnSize, axes: .vertical)
      .scrollIndicators(.hidden)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 30)
    .padding(.bottom, 40)
    .padding(.top, showIngredientsSheet ? 10 : 30)
    .animation(.easeOut(duration: 0.25), value: showIngredientsSheet)
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
