//
//  RecipeParsingService.swift
//  Recipes
//
//  Created by Eliott on 2025-12-28.
//

import Foundation
import FoundationModels

struct RecipeParsingService {
  enum ParsingError: LocalizedError {
    case modelUnavailable(String)
    case parsingFailed(Error)
    case emptyResult

    var errorDescription: String? {
      switch self {
      case .modelUnavailable(let reason):
        return "AI model unavailable: \(reason)"
      case .parsingFailed(let error):
        return "Failed to parse recipe: \(error.localizedDescription)"
      case .emptyResult:
        return "Could not extract recipe information from the text."
      }
    }
  }

  /// Generable struct for AI output
  @Generable
  struct ParsedRecipe {
    @Guide(description: "The name/title of the recipe")
    var name: String

    @Guide(description: "List of ingredients, each as a single line")
    var ingredients: [String]

    @Guide(description: "Step-by-step cooking instructions")
    var instructions: [String]

    @Guide(description: "Preparation time in minutes, 0 if not found")
    var prepTimeMinutes: Int

    @Guide(description: "Cooking time in minutes, 0 if not found")
    var cookTimeMinutes: Int

    @Guide(description: "Number of servings, 0 if not found")
    var servings: Int

    @Guide(description: "Any additional notes or tips from the recipe")
    var notes: String?
  }

  static var isAvailable: Bool {
    if case .available = SystemLanguageModel.default.availability {
      return true
    }
    return false
  }

  static var unavailabilityReason: String? {
    if case .unavailable(let reason) = SystemLanguageModel.default.availability {
      return String(describing: reason)
    }
    return nil
  }

  func parseRecipe(from ocrText: String) async throws -> RecipeDetails {
    let model = SystemLanguageModel.default

    guard case .available = model.availability else {
      if case .unavailable(let reason) = model.availability {
        throw ParsingError.modelUnavailable(String(describing: reason))
      }
      throw ParsingError.emptyResult
    }

    let session = LanguageModelSession(
      instructions: """
        You are a recipe parser. Extract recipe information from the provided text.
        The text comes from OCR of a recipe image and may have formatting issues.
        Extract as much information as possible. If a field is not present, use defaults.
        For ingredients and instructions, preserve the original wording.
        """
    )

    let prompt = """
      Parse the following recipe text and extract the recipe details:

      \(ocrText)
      """

    do {
      let response = try await session.respond(
        to: prompt,
        generating: ParsedRecipe.self
      )

      let parsed = response.content
      let recipeId = UUID()

      return RecipeDetails(
        recipe: Recipe(
          id: recipeId,
          name: parsed.name.isEmpty ? "Untitled Recipe" : parsed.name,
          prepTimeMinutes: parsed.prepTimeMinutes,
          cookTimeMinutes: parsed.cookTimeMinutes,
          servings: parsed.servings,
          notes: parsed.notes
        ),
        ingredients: parsed.ingredients.enumerated().map { index, text in
          RecipeIngredient(
            id: UUID(),
            recipeId: recipeId,
            position: index,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines)
          )
        },
        instructions: parsed.instructions.enumerated().map { index, text in
          RecipeInstruction(
            id: UUID(),
            recipeId: recipeId,
            position: index,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines)
          )
        },
        photos: []
      )
    } catch let error as ParsingError {
      throw error
    } catch {
      throw ParsingError.parsingFailed(error)
    }
  }
}
