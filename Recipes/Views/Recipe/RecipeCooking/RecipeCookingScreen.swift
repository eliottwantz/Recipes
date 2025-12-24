//
//  RecipeCookingScreen.swift
//  Recipes
//
//  Created by Eliott on 12-12-2025.
//

import SQLiteData
import SwiftUI

struct RecipeCookingScreen: View {
  @Binding var currentStep: Int
  @State private var showIngredientsSheet = false
  @State private var searchTerm = ""
  @State private var currentDetent: PresentationDetent = .fraction(0.45)
  @State private var cookingIngredients: [CookingIngredient]
  @State private var showTimerPicker = false
  @State private var timerHours = 0
  @State private var timerMinutes = 0
  @State private var timerSeconds = 0
  private var timerManager = TimerManager.shared
  private var appRouter = AppRouter.shared

  let recipeDetails: RecipeDetails
  let scaleFactor: Double

  init(recipeDetails: RecipeDetails, scaleFactor: Double = 1.0, currentStep: Binding<Int>) {
    self.recipeDetails = recipeDetails
    self.scaleFactor = scaleFactor
    self._currentStep = currentStep
    self._cookingIngredients = State(
      initialValue: recipeDetails.ingredients.map { ingredient in
        let parsed = ingredient.text.parseIngredient()
        let scaledText = parsed.scaled(by: scaleFactor)
        return CookingIngredient(isCompleted: false, name: scaledText)
      }
    )
  }

  var body: some View {
    GeometryReader { geometry in
      NavigationStack {
        ZStack {
          ZStack {
            TabView(selection: $currentStep) {
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
                currentStepIndex: $currentStep, totalSteps: recipeDetails.instructions.count
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
                appRouter.closeCookingScreen()
              }
            }
            ToolbarItemGroup(placement: .primaryAction) {
              Button {
                showIngredientsSheet = false
                showTimerPicker.toggle()
              } label: {
                Label("Start timer", systemImage: "timer")
              }
              .badge(timerManager.upcomingAlarmsCount)
              .popover(isPresented: $showTimerPicker) {
                VStack(spacing: 0) {
                  // Active Timers Section
                  if timerManager.hasUpcomingAlarms {
                    ScrollView {
                      VStack(spacing: 12) {
                        ForEach(Array(timerManager.sortedAlarms)) { alarmData in
                          ActiveTimerView(
                            alarm: alarmData.alarm,
                            endDate: alarmData.endDate,
                            recipeName: alarmData.recipeName,
                            instructionStep: alarmData.instructionStep,
                            onCancel: {
                              timerManager.unscheduleAlarm(with: alarmData.id)
                            }
                          )
                        }
                      }
                      .padding()
                    }
                    .frame(maxHeight: 300)
                  }

                  // Timer Picker Section
                  CountdownTimerPickerView(
                    hours: $timerHours,
                    minutes: $timerMinutes,
                    seconds: $timerSeconds,
                    onStart: {
                      let currentInstruction = recipeDetails.instructions[currentStep]
                      timerManager.scheduleAlarm(
                        with: .init(
                          recipeId: recipeDetails.recipe.id,
                          recipeName: recipeDetails.recipe.name,
                          instructionStep: currentInstruction.position,
                          hour: timerHours,
                          min: timerMinutes,
                          sec: timerSeconds,
                          imageData: recipeDetails.photos.first?.photoData ?? nil
                        ))
                    },
                    close: {
                      showTimerPicker = false
                    }
                  )
                  .padding(.horizontal)
                  .frame(width: geometry.size.width, height: 300)
                }
                .presentationCompactAdaptation(.popover)
              }

              Button {
                showTimerPicker = false
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
            CookingIngredientsListView(cookingIngredients: $cookingIngredients)
              .presentationDetents([.fraction(0.45), .large], selection: $currentDetent)
              .presentationDragIndicator(.hidden)
              .presentationContentInteraction(.scrolls)
              .presentationBackgroundInteraction(.enabled)
          }
        }
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
        HighlightedTimeText(
          text: instruction.text,
          font: Font.system(size: 18, weight: .semibold),
          lineSpacing: 8,
          onTimeTap: { hours, minutes, seconds in
            timerHours = hours
            timerMinutes = minutes
            timerSeconds = seconds
            showIngredientsSheet = false
            showTimerPicker = true
          }
        )
        .frame(maxWidth: .infinity, alignment: .leading)
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
  @Previewable @State var currentStep = 0

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

  return RecipeCookingScreen(recipeDetails: recipeDetails, currentStep: $currentStep)
}
