//
//  RecipeCookingScreen.swift
//  Recipes
//
//  Created by Eliott on 12-12-2025.
//

import Combine
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
  @State private var showTimerConfirmation = false

  // Hands-free mode
  @State private var faceTrackingManager = FaceTrackingManager()
  @State private var winkCancellable: AnyCancellable?

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
              if FaceTrackingManager.isSupported {
                Button {
                  if faceTrackingManager.isTracking {
                    faceTrackingManager.stopTracking()
                    winkCancellable?.cancel()
                    winkCancellable = nil
                  } else {
                    faceTrackingManager.startTracking()
                    winkCancellable = faceTrackingManager.winkEventSubject
                      .receive(on: DispatchQueue.main)
                      .sink { [self] event in
                        handleWinkEvent(event)
                      }
                  }
                } label: {
                  Label(
                    "Hands-free mode",
                    systemImage: faceTrackingManager.isTracking
                      ? "hand.raised.fill" : "hand.raised.slash"
                  )
                }
              }

              Button {
                showIngredientsSheet = false
                showTimerPicker.toggle()
              } label: {
                Label("Start timer", systemImage: "timer")
              }
              .sensoryFeedback(
                .success, trigger: timerManager.upcomingAlarmsCount,
                condition: { oldValue, newValue in
                  newValue > oldValue
                }
              )
              .badge(timerManager.upcomingAlarmsCount)
              .popover(isPresented: $showTimerPicker) {
                TimerPopover(geometry: geometry)
                  .presentationCompactAdaptation(.popover)
                  .overlay {
                    if showTimerConfirmation {
                      TimerConfirmationOverlay {
                        showTimerConfirmation = false
                        showTimerPicker = false
                      }
                    }
                  }
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
              .currentPageIndicatorTintColor = UIColor(.accent)
          }
          .onDisappear {
            faceTrackingManager.stopTracking()
            winkCancellable?.cancel()
          }
        }
        .onChange(of: timerManager.upcomingAlarmsCount) { oldValue, newValue in
          #if DEBUG
            print(
              "🔔 TimerManager upcomingAlarmsCount trigger changed from \(oldValue) to \(newValue)"
            )
          #endif
          guard newValue > oldValue else { return }
          showTimerConfirmation = true
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

  // MARK: - Hands-free mode
  private func handleWinkEvent(_ event: FaceTrackingManager.WinkEvent) {
    let totalSteps = recipeDetails.instructions.count

    switch event {
    case .rightEyeWink:
      // Right wink = next step
      if currentStep < totalSteps - 1 {
        withAnimation {
          currentStep += 1
        }
      }
    case .leftEyeWink:
      // Left wink = previous step
      if currentStep > 0 {
        withAnimation {
          currentStep -= 1
        }
      }
    }
  }

  private struct TimerConfirmationOverlay: View {
    struct AnimationValues {
      enum ConfirmationIcon: String {
        case timer = "timer"
        case checkmark = "checkmark.circle.fill"
      }
      var confirmationIcon: ConfirmationIcon = .timer
      var timerButtonRotation: Double = 0
      var timerButtonOffset: CGFloat = 0
      var timerButtonScale: CGFloat = 1.0
    }

    @State private var animationValues = AnimationValues()
    let onEnd: () -> Void

    var body: some View {
      GeometryReader { geometry in
        ZStack {
          // Dark blur background
          Rectangle()
            .fill(.ultraThinMaterial)

          // Large animated timer icon
          Image(systemName: animationValues.confirmationIcon.rawValue)
            .resizable()
            .foregroundStyle(.accent)
            .frame(width: 300 / 2, height: 300 / 2)
            .aspectRatio(1.0, contentMode: .fit)
            .rotationEffect(.degrees(animationValues.timerButtonRotation))
            .scaleEffect(animationValues.timerButtonScale)
            .offset(y: animationValues.timerButtonOffset)
            .contentTransition(.symbolEffect(.replace))
        }
      }
      .transition(.opacity)
      .onAppear {
        animateTimerButton()
      }
    }

    private func animateTimerButton() {
      print("Animating timer button...")
      Task {
        try await Task.sleep(for: .milliseconds(200))

        withAnimation(.spring(response: 0.6)) {
          animationValues.timerButtonRotation += 360
        }

        try await Task.sleep(for: .seconds(0.35))
        animationValues.confirmationIcon = .checkmark
        withAnimation(.easeIn) {
          animationValues.timerButtonScale = 1.5
        }

        try await Task.sleep(for: .seconds(0.85))
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
          animationValues.timerButtonOffset = 0
          animationValues.timerButtonScale = 1.0
        }

        try await Task.sleep(for: .seconds(0.6))
        withAnimation {
          onEnd()
          animationValues.confirmationIcon = .timer
          animationValues.timerButtonScale = 1
          animationValues.timerButtonOffset = 0
          animationValues.timerButtonRotation = 0
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

  @ViewBuilder
  private func TimerPopover(geometry: GeometryProxy) -> some View {
    VStack {
      VStack(spacing: 0) {
        // Active Timers Section
        if timerManager.hasUpcomingAlarms {
          VStack {
            ScrollView {
              LazyVStack(spacing: 10) {
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
                  .transition(.move(edge: .leading).combined(with: .opacity))
                }
              }
              .animation(
                .spring(response: 0.35, dampingFraction: 0.55),
                value: timerManager.sortedAlarms
              )
            }
            .listStyle(.grouped)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .frame(height: 300)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
    }
    .frame(width: geometry.size.width)
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
              .foregroundStyle(Color.accentContrasting)
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
              .foregroundStyle(Color.accentContrasting)
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
