//
//  RecipeEditFormView.swift
//  Recipes
//
//  Created by Eliott on 2025-11-11.
//

import PhotosUI
import SQLiteData
import SwiftUI

struct RecipeEditFormView: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var recipeDetails: RecipeDetails

  @State private var isSaving = false
  @State private var selectedPhotoItems: [PhotosPickerItem] = []

  init(recipeDetails: Binding<RecipeDetails>) {
    self._recipeDetails = recipeDetails
  }

  var body: some View {
    Form {
      LabeledContent("Name") {
        TextField("Name", text: $recipeDetails.recipe.name)
          .multilineTextAlignment(.trailing)
          .foregroundStyle(.tint)
      }

      Section("Recipe Details") {
        FormIntegerPickerLabeledContent(
          "Servings",
          amount: $recipeDetails.recipe.servings
        )

        FormTimePickerLabeledContent(
          "Preparation Time",
          totalMinutes: $recipeDetails.recipe.prepTimeMinutes
        )
        FormTimePickerLabeledContent(
          "Cook Time",
          totalMinutes: $recipeDetails.recipe.cookTimeMinutes
        )
      }

      Section("Ingredients") {
        ForEach($recipeDetails.ingredients) { $ingredient in
          TextField("Ingredient", text: $ingredient.text, axis: .vertical)
        }
        .onDelete(perform: deleteIngredient)
        .onMove(perform: moveIngredient)

        Button("Add Ingredient", action: addIngredient)
      }

      Section("Instructions") {
        ForEach($recipeDetails.instructions) { $instruction in
          TextField("Instruction", text: $instruction.text, axis: .vertical)
        }
        .onDelete(perform: deleteInstruction)
        .onMove(perform: moveInstruction)

        Button("Add Instruction", action: addInstruction)
      }

      Section("Notes") {
        TextField(
          "Add a note",
          text: Binding($recipeDetails.recipe.notes),
          axis: .vertical
        )
        .multilineTextAlignment(.leading)
      }

      Section("Nutrition") {
        TextField(
          "Add nutritional facts",
          text: Binding($recipeDetails.recipe.nutrition),
          axis: .vertical
        )
        .multilineTextAlignment(.trailing)
        .foregroundStyle(.tint)

      }

      Section("Photos") {
        ForEach(recipeDetails.photos) { photo in
          HStack {
            if let uiImage = UIImage(data: photo.photoData) {
              Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Text("Photo \(photo.position + 1)")
              .font(.body)
          }
        }
        .onDelete(perform: deletePhoto)
        .onMove(perform: movePhoto)

        PhotosPicker(
          selection: $selectedPhotoItems,
          maxSelectionCount: 10,
          matching: .images
        ) {
          Label("Add Photos", systemImage: "photo.on.rectangle.angled")
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
          Task {
            await loadPhotos(from: newItems)
          }
        }
      }

      LabeledContent("Website") {
        TextField("Website URL", text: Binding($recipeDetails.recipe.website))
          .multilineTextAlignment(.trailing)
          .foregroundStyle(.tint)
          .keyboardType(.URL)
          .textContentType(.URL)
          .autocapitalization(.none)
      }
    }
    .environment(\.editMode, .constant(EditMode.active))
  }

  nonisolated private func loadPhotos(from items: [PhotosPickerItem]) async {
    for item in items {
      if let data = try? await item.loadTransferable(type: Data.self) {
        let newPhoto = await RecipePhoto(
          id: UUID(),
          recipeId: recipeDetails.recipe.id,
          position: recipeDetails.photos.count,
          photoData: data
        )
        await MainActor.run {
          recipeDetails.photos.append(newPhoto)
        }
      }
    }
    await MainActor.run {
      selectedPhotoItems = []
    }
  }

  private func deleteIngredient(at offsets: IndexSet) {
    recipeDetails.ingredients.remove(atOffsets: offsets)
    reindexIngredients()
  }

  private func moveIngredient(from source: IndexSet, to destination: Int) {
    recipeDetails.ingredients.move(fromOffsets: source, toOffset: destination)
    reindexIngredients()
  }

  private func addIngredient() {
    let newIngredient = RecipeIngredient(
      id: UUID(),
      recipeId: recipeDetails.recipe.id,
      position: recipeDetails.ingredients.count
    )
    recipeDetails.ingredients.append(newIngredient)
  }

  private func reindexIngredients() {
    for (index, _) in recipeDetails.ingredients.enumerated() {
      recipeDetails.ingredients[index].position = index
    }
  }

  private func addInstruction() {
    let newInstruction = RecipeInstruction(
      id: UUID(),
      recipeId: recipeDetails.recipe.id,
      position: recipeDetails.instructions.count
    )
    recipeDetails.instructions.append(newInstruction)
  }

  private func deleteInstruction(at offsets: IndexSet) {
    recipeDetails.instructions.remove(atOffsets: offsets)
    reindexInstructions()
  }

  private func moveInstruction(from source: IndexSet, to destination: Int) {
    recipeDetails.instructions.move(fromOffsets: source, toOffset: destination)
    reindexInstructions()
  }

  private func reindexInstructions() {
    for (index, _) in recipeDetails.instructions.enumerated() {
      recipeDetails.instructions[index].position = index
    }
  }

  private func deletePhoto(at offsets: IndexSet) {
    recipeDetails.photos.remove(atOffsets: offsets)
    reindexPhotos()
  }

  private func movePhoto(from source: IndexSet, to destination: Int) {
    recipeDetails.photos.move(fromOffsets: source, toOffset: destination)
    reindexPhotos()
  }

  private func reindexPhotos() {
    for (index, _) in recipeDetails.photos.enumerated() {
      recipeDetails.photos[index].position = index
    }
  }
}

#Preview("Scratch") {
  @Previewable @State var recipeDetails = RecipeDetails(
    recipe: .init(id: UUID()),
    ingredients: [],
    instructions: [],
    photos: []
  )
  RecipeEditFormView(recipeDetails: $recipeDetails)
}

#Preview("Existing") {
  @Previewable @State var recipeDetails = Storage.configure { database in
    return try database.read { db in
      print("FETCHING RECIPE FOR PREVIEW")
      let recipe = try Recipe.all.fetchOne(db)
      guard let recipe else { fatalError("No recipe found. Seed the database first.") }
      let results = try RecipeDetails.FetchKeyRequest(recipeId: recipe.id).fetch(db)
      return RecipeDetails(
        recipe: recipe,
        ingredients: results.ingredients,
        instructions: results.instructions,
        photos: results.photos
      )
    }
  }

  RecipeEditFormView(recipeDetails: $recipeDetails)
}
