//
//  RecipeEditView.swift
//  Recipes
//
//  Created by Eliott on 2025-11-08.
//

import Dependencies
import SwiftUI

struct RecipeEditView: View {
  @Binding var recipeDetails: RecipeImportManager.ExtractedRecipeDetail
  @State private var isSaving = false
  @Environment(\.dismiss) private var dismiss

  @Dependency(\.defaultDatabase) private var database
  private let importManager = RecipeImportManager()

  var body: some View {
    NavigationStack {
      Form {
        Section("Recipe Details") {
          TextField("Title", text: $recipeDetails.recipe.title)
          TextField("Summary", text: bindingForOptionalString(for: \.summary))
          HStack {
            TextField(
              "Prep Time", value: bindingForOptionalInt(for: \.prepTimeMinutes), format: .number)
            Text("minutes")
              .foregroundColor(.secondary)
          }
          HStack {
            TextField(
              "Cook Time", value: bindingForOptionalInt(for: \.cookTimeMinutes), format: .number)
            Text("minutes")
              .foregroundColor(.secondary)
          }
          HStack {
            TextField("Servings", value: bindingForOptionalInt(for: \.servings), format: .number)
          }
        }

        Section("Ingredients") {
          ForEach($recipeDetails.ingredients) { $ingredient in
            TextField("Ingredient", text: $ingredient.text, axis: .vertical)
          }
          .onDelete(perform: deleteIngredient)
          .onMove(perform: moveIngredient)

          Button("Add Ingredient") {
            addIngredient()
          }
        }

        Section("Instructions") {
          ForEach($recipeDetails.instructions) { $instruction in
            TextField("Instruction", text: $instruction.text, axis: .vertical)
          }
          .onDelete(perform: deleteInstruction)
          .onMove(perform: moveInstruction)

          Button("Add Instruction") {
            addInstruction()
          }
        }
      }
      .navigationTitle("Edit Recipe")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Save") {
            saveRecipe()
          }
          .buttonStyle(.glassProminent)
          .disabled(isSaving)
        }
      }
    }
  }

  private func binding<T>(for keyPath: WritableKeyPath<Recipe, T>) -> Binding<T> {
    Binding(
      get: { recipeDetails.recipe[keyPath: keyPath] },
      set: { recipeDetails.recipe[keyPath: keyPath] = $0 }
    )
  }

  private func bindingForOptionalString(for keyPath: WritableKeyPath<Recipe, String?>) -> Binding<
    String
  > {
    Binding(
      get: { recipeDetails.recipe[keyPath: keyPath] ?? "" },
      set: { recipeDetails.recipe[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
    )
  }

  private func bindingForOptionalInt(for keyPath: WritableKeyPath<Recipe, Int?>) -> Binding<Int> {
    Binding(
      get: { recipeDetails.recipe[keyPath: keyPath] ?? 0 },
      set: { recipeDetails.recipe[keyPath: keyPath] = $0 == 0 ? nil : $0 }
    )
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
      position: recipeDetails.ingredients.count,
      text: ""
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
      recipeId: recipeDetails.instructions.first?.recipeId ?? UUID(),
      position: recipeDetails.instructions.count,
      text: ""
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

  private func saveRecipe() {
    isSaving = true

    Task {
      do {
        let normalizedDetails = recipeDetails.normalized()
        try importManager.persist(normalizedDetails, in: database)
        await MainActor.run {
          isSaving = false
          dismiss()
        }
      } catch {
        await MainActor.run {
          isSaving = false
          // Handle error - could show an alert
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var recipeDetails = RecipeImportManager.ExtractedRecipeDetail(
    recipe: Recipe(
      id: UUID(),
      title: "Sample Recipe",
      summary: "A delicious sample recipe",
      prepTimeMinutes: 15,
      cookTimeMinutes: 30,
      servings: 4
    ),
    ingredients: [
      RecipeIngredient(id: UUID(), recipeId: UUID(), position: 0, text: "1 cup flour"),
      RecipeIngredient(id: UUID(), recipeId: UUID(), position: 1, text: "2 eggs"),
    ],
    instructions: [
      RecipeInstruction(
        id: UUID(), recipeId: UUID(), position: 0,
        text:
          "Adhaero ratione tricesimus curiositas validus cura casso cinis acceptus degenero. Verus casso vallum inventore corrupti. Magnam tolero tersus acervus ait coepi porro carcer tantillus demoror."
      ),
      RecipeInstruction(
        id: UUID(), recipeId: UUID(), position: 1,
        text:
          "Universe vetus adfero caelum. Deputo adimpleo totidem delego suasoria conqueror statim tam deficio. Crur custodia amo aeneus magnam certus cena usque."
      ),
    ]
  )

  return RecipeEditView(recipeDetails: $recipeDetails)
}
