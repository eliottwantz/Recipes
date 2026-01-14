//
//  RecipeDetailScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-11-09.
//

import Dependencies
import PhotosUI
import SQLiteData
import SwiftUI
import UIKit

struct RecipeDetailView: View {
  let recipeDetails: RecipeDetails
  @State private var showImageCarousel: Bool = false
  @State private var selectedPhotoID: RecipePhoto.ID? = nil
  @State private var showScalingControl: Bool = false
  @Binding var scaleFactor: Double
  @State private var scaleMode: ScalingMode = .amount

  // Photo addition state
  @Dependency(\.defaultDatabase) private var database
  @State private var showPhotosPicker: Bool = false
  @State private var selectedPhotoItems: [PhotosPickerItem] = []
  @State private var showCamera: Bool = false

  @State private var ingredientsCopiedCount = 0

  enum ScalingMode: String, CaseIterable {
    case amount
    case serving
    case ingredient

    var localizedKey: LocalizedStringKey {
      .init("ScalingMode.\(rawValue)")
    }
  }

  init(recipeDetails: RecipeDetails, scaleFactor: Binding<Double> = .constant(1.0)) {
    self.recipeDetails = recipeDetails
    self._scaleFactor = scaleFactor
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        if let notes = recipeDetails.recipe.notes, !notes.isEmpty {
          notesSection
        }

        if !recipeDetails.ingredients.isEmpty {
          ingredientsSection
        }

        if !recipeDetails.instructions.isEmpty {
          instructionsSection
        }

        photosSection

        if let nutrition = recipeDetails.recipe.nutrition, !nutrition.isEmpty {
          nutritionSection
        }

      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 13)
      .padding(.bottom, 10)
    }
    .darkPrimaryLightSecondaryBackgroundColor()
    #if os(iOS)
      .fullScreenCover(isPresented: $showImageCarousel) {
        NavigationStack {
          ImageCarouselView(
            photos: recipeDetails.photos,
            selectedPhotoID: $selectedPhotoID
          )
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Button(role: .cancel) {
                selectedPhotoID = nil
                showImageCarousel = false
              }
            }
          }
        }
        .presentationBackground(.black)
        .statusBarHidden()
      }
      .fullScreenCover(isPresented: $showCamera) {
        CameraView { imageData in
          showCamera = false
          if let imageData {
            savePhoto(data: imageData)
          }
        }
        .ignoresSafeArea()
      }
      .photosPicker(
        isPresented: $showPhotosPicker,
        selection: $selectedPhotoItems,
        maxSelectionCount: 10,
        matching: .images
      )
      .onChange(of: selectedPhotoItems) { _, newItems in
        Task {
          await loadAndSavePhotos(from: newItems)
        }
      }
    #endif
  }

  private func savePhoto(data: Data) {
    let newPhoto = RecipePhoto(
      id: UUID(),
      recipeId: recipeDetails.recipe.id,
      position: recipeDetails.photos.count,
      photoData: data
    )
    withErrorReporting {
      try database.write { db in
        try RecipePhoto.insert { newPhoto }.execute(db)
      }
    }
  }

  nonisolated private func loadAndSavePhotos(from items: [PhotosPickerItem]) async {
    for (index, item) in items.enumerated() {
      if let data = try? await item.loadTransferable(type: Data.self) {
        await MainActor.run {
          let newPhoto = RecipePhoto(
            id: UUID(),
            recipeId: recipeDetails.recipe.id,
            position: recipeDetails.photos.count + index,
            photoData: data
          )
          withErrorReporting {
            try database.write { db in
              try RecipePhoto.insert { newPhoto }.execute(db)
            }
          }
        }
      }
    }
    await MainActor.run {
      selectedPhotoItems = []
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      titleCover

      HStack(alignment: .center) {
        HStack(spacing: 8) {
          Image(systemName: "person.2.fill")
            .foregroundStyle(.secondary)
          VStack(alignment: .leading, spacing: 4) {
            Text("\(Int((Double(recipeDetails.recipe.servings) * scaleFactor).rounded()))")
              .font(.body.weight(.semibold))
              .foregroundStyle(.primary)
          }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .card(cornerRadius: 40)

        HStack(alignment: .center, spacing: 40) {
          VStack(spacing: 2) {
            HStack(spacing: 6) {
              Text("Prep")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
              Image(systemName: "clock.fill")
                .foregroundStyle(.secondary)
            }
            TimeView(totalMinutes: recipeDetails.recipe.prepTimeMinutes)
              .font(.body.weight(.semibold))
              .foregroundStyle(.primary)
          }
          .multilineTextAlignment(.center)

          VStack(alignment: .center, spacing: 2) {
            HStack(spacing: 6) {
              Text("Cook")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
              Image(systemName: "clock.fill")
                .foregroundStyle(.secondary)
            }
            TimeView(totalMinutes: recipeDetails.recipe.cookTimeMinutes)
              .font(.body.weight(.semibold))
              .foregroundStyle(.primary)
          }
          .multilineTextAlignment(.center)

        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .card(cornerRadius: 40)
      }
    }
  }

  private var titleCover: some View {
    Group {
      if let website = recipeDetails.recipe.website,
        let url = URL(string: website),
        let host = url.host,
        let photo = recipeDetails.photos.first
      {
        Link(destination: url) {
          titleImageCover
            .overlay(alignment: .bottomLeading) {
              HStack(spacing: 8) {
                Image(systemName: "safari")
                  .foregroundStyle(.white)
                Text(host)
                  .font(.footnote.weight(.semibold))
                  .foregroundStyle(.white)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(.ultraThinMaterial, in: .capsule)
              .padding()
            }
        }
      } else {
        titleImageCover
      }
    }
  }

  private var titleImageCover: some View {
    Group {
      if let photo = recipeDetails.photos.first, let image = photo.image {
        image
          .resizable()
          .scaledToFill()
          .frame(height: 220)
          .frame(maxWidth: .infinity)
          .clipped()
          .clipShape(RoundedRectangle(cornerRadius: 20))
          .overlay {
            RoundedRectangle(cornerRadius: 20)
              .fill(Color.black.opacity(0.35))
          }
          .overlay(alignment: .topLeading) {
            Text(recipeDetails.recipe.name)
              .font(.title.weight(.bold))
              .foregroundStyle(.white)
              .multilineTextAlignment(.leading)
              .shadow(radius: 2)
              .padding(16)
          }
      } else {
        Text(recipeDetails.recipe.name)
          .font(.largeTitle.weight(.bold))
          .foregroundStyle(.primary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private var ingredientsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Ingredients")
          .font(.title3.weight(.semibold))
          .foregroundStyle(.primary)

        Spacer()

        HStack(spacing: 12) {
          Button {
            withAnimation(.snappy) {
              showScalingControl.toggle()
            }
          } label: {
            //            Text(scaleButtonText)
            scaleButtonText
              .font(.subheadline.weight(.semibold))
              .padding(.horizontal, 20)
              .padding(.vertical, 4)
          }
          .glassEffect(.regular.interactive().tint(.accent.opacity(0.22)), in: .capsule)

          Menu {
            Section {
              Button {
                let ingredients = recipeDetails.ingredients
                let text =
                  ingredients
                  .map { $0.text.parseIngredient().scaled(by: scaleFactor) }
                  .joined(separator: "\n")
                UIPasteboard.general.string = text
                ToastManager.shared.show(
                  icon: "doc.on.doc",
                  title: "Clipboard",
                  subtitle: "\(ingredients.count) ingredients"
                )
                ingredientsCopiedCount += 1
              } label: {
                Label("Copy", systemImage: "doc.on.doc")
              }
              .sensoryFeedback(.success, trigger: ingredientsCopiedCount)
            }
          } label: {
            Image(systemName: "slider.horizontal.3")
              .font(.subheadline.weight(.semibold))
              .padding(6)
          }
          .glassEffect(.regular.interactive().tint(.accent.opacity(0.22)), in: .circle)
        }
      }

      if showScalingControl {
        scalingControlView
      }

      VStack(alignment: .leading, spacing: 12) {
        ForEach(Array(recipeDetails.ingredients.enumerated()), id: \.element.id) { index, line in
          ingredientTextView(for: line.text)

          if index != recipeDetails.ingredients.count - 1 {
            Divider()
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .card()
    }
  }

  private var scaleButtonText: Text {
    if scaleFactor == 1.0 {
      return Text(showScalingControl ? "Default" : "Scale")
    } else {
      return Text("Scale: x \(scaleFactor.formatted(.number.precision(.fractionLength(2))))")
    }
  }

  private var scalingControlView: some View {
    VStack(spacing: 16) {
      Picker("Scale Mode", selection: $scaleMode) {
        ForEach(ScalingMode.allCases, id: \.self) { mode in
          Text(mode.localizedKey)
            .tag(mode)
        }
      }
      .pickerStyle(.segmented)

      HStack {
        if scaleMode == .serving {
          servingScaleControl
        } else {
          amountScaleControl
        }

        if scaleFactor != 1.0 {
          Button {
            withAnimation {
              scaleFactor = 1.0
            }
          } label: {
            Image(systemName: "xmark")
              .font(.caption)
              .foregroundStyle(.secondary)
              .tint(.secondary)
              .frame(width: 12, height: 12)
              .padding(4)
              .background(Color.secondary.opacity(0.2), in: .circle)
          }
          .transition(.opacity)
        }
      }
    }
    .padding()
    .card()
  }

  private var servingScaleControl: some View {
    HStack(spacing: 16) {
      Slider(
        value: Binding(
          get: {
            Double(recipeDetails.recipe.servings) * scaleFactor
          },
          set: { newServings in
            scaleFactor = newServings / Double(recipeDetails.recipe.servings)
          }
        ),
        in: 1...30,
        step: 1
      )
      .tint(.accent)

      HStack(spacing: 8) {
        Image(systemName: "person.2.fill")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        TextField(
          "Scale amount",
          value: Binding(
            get: {
              Int((Double(recipeDetails.recipe.servings) * scaleFactor).rounded())
            },
            set: { newServings in
              scaleFactor = Double(newServings) / Double(recipeDetails.recipe.servings)
            }
          ),
          format: .number
        )
        .keyboardType(.numberPad)
        .multilineTextAlignment(.leading)
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundStyle(.accent)
        .frame(maxWidth: 50)
      }
      .frame(maxWidth: 75)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.secondary.opacity(0.2), in: .rect(cornerRadius: 12))
    }
  }

  private var amountScaleControl: some View {
    HStack(spacing: 16) {
      Slider(
        value: $scaleFactor,
        in: 0.5...10.0,
        step: 0.5
      )
      .tint(.accent)

      HStack(spacing: 8) {
        Image(systemName: "xmark")
          .font(.footnote)
          .foregroundStyle(.secondary)

        TextField(
          "Scale amount",
          value: $scaleFactor,
          format: .number
        )
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.leading)
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundStyle(.accent)
        .frame(maxWidth: 60)
      }
      .frame(maxWidth: 75)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.secondary.opacity(0.2), in: .rect(cornerRadius: 12))
    }
  }

  @ViewBuilder
  private func ingredientTextView(for text: String) -> some View {
    let parsed = text.parseIngredient()
    let scaledText = parsed.scaled(by: scaleFactor)

    // Find the quantity+unit in the scaled text
    let scaledParsed = scaledText.parseIngredient()
    if let scaledRange = scaledParsed.quantityUnitRange {
      let beforeRange = String(scaledText[..<scaledRange.lowerBound])
      let quantityUnit = String(scaledText[scaledRange])
      let afterRange = String(scaledText[scaledRange.upperBound...])

      Text(
        """
        \(Text(beforeRange))\
        \(Text(quantityUnit)
            .foregroundStyle(.accent)
            .fontWeight(.semibold))\
        \(Text(afterRange))
        """
      )
      .font(.body)
      .foregroundStyle(.primary)
    } else {
      Text(scaledText)
        .font(.body)
        .foregroundStyle(.primary)
    }
  }

  private var instructionsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Instructions")
        .font(.title3.weight(.semibold))
      VStack(alignment: .leading, spacing: 20) {
        ForEach(Array(recipeDetails.instructions.enumerated()), id: \.element.id) { index, step in
          HStack(alignment: .top) {
            Text("\(index + 1)")
              .font(.body.weight(.semibold))
              .frame(width: 22, height: 22)
              .background { Circle().fill(.tint) }
              .foregroundStyle(Color.accentContrasting)

            Text(step.text)
              .font(.body)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding()
          .card()
        }
      }
    }
  }

  private var websiteSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Source")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)

      if let website = recipeDetails.recipe.website, let url = URL(string: website) {
        Link(destination: url) {
          HStack {
            Image(systemName: "safari")
              .foregroundStyle(.tint)
            Text(website)
              .font(.body)
              .foregroundStyle(.tint)
              .lineLimit(2)
            Spacer()
            Image(systemName: "arrow.up.right")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding()
          .card()
        }
      }
    }
  }

  private var nutritionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Nutrition")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)

      Text(recipeDetails.recipe.nutrition ?? "")
        .font(.body)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .card()
    }
  }

  private var notesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Notes")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)

      Text(recipeDetails.recipe.notes ?? "")
        .font(.body)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .card()
    }
  }

  private var photosSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Photos")
          .font(.title3.weight(.semibold))
          .foregroundStyle(.primary)

        Spacer()

        Menu {
          Button {
            showCamera = true
          } label: {
            Label("Take Photo", systemImage: "camera")
          }
          Button {
            showPhotosPicker = true
          } label: {
            Label("Choose from library", systemImage: "photo.on.rectangle")
          }
        } label: {
          Image(systemName: "plus.circle.fill")
            .font(.title2)
            .foregroundStyle(.accent)
        }
      }

      if !recipeDetails.photos.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(recipeDetails.photos) { photo in
              if let image = photo.image {
                image
                  .resizable()
                  .scaledToFill()
                  .frame(width: 200, height: 200)
                  .clipShape(RoundedRectangle(cornerRadius: 20))
                  .onTapGesture {
                    selectedPhotoID = photo.id
                    showImageCarousel = true
                  }
              }
            }
          }
        }
      }
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
        recipe: recipe, ingredients: results.ingredients, instructions: results.instructions,
        photos: results.photos)
    }
  }

  NavigationStack {
    RecipeDetailView(recipeDetails: recipeDetails)
  }
}
