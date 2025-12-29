//
//  PhotoRecipeImportManager.swift
//  Recipes
//
//  Created by Eliott on 2025-12-28.
//

import Foundation

struct PhotoRecipeImportManager {
  private let textRecognitionService = TextRecognitionService()
  private let recipeParsingService = RecipeParsingService()

  enum ImportError: LocalizedError {
    case ocrFailed(Error)
    case parsingFailed(Error, ocrText: String)

    var errorDescription: String? {
      switch self {
      case .ocrFailed(let error):
        return "Failed to read text from image: \(error.localizedDescription)"
      case .parsingFailed(let error, _):
        return "Failed to parse recipe: \(error.localizedDescription)"
      }
    }

    var ocrText: String? {
      if case .parsingFailed(_, let text) = self {
        return text
      }
      return nil
    }
  }

  enum ImportResult {
    case success(RecipeDetails)
    case partialSuccess(RecipeDetails, ocrText: String, error: Error)
  }

  nonisolated func importRecipe(from imageData: Data) async throws -> ImportResult {
    // Step 1: OCR
    let ocrText: String
    do {
      ocrText = try await textRecognitionService.recognizeText(from: imageData)
    } catch {
      throw ImportError.ocrFailed(error)
    }

    // Step 2: AI Parsing
    do {
      var recipeDetails = try await recipeParsingService.parseRecipe(from: ocrText)

      // Add the source image as a recipe photo
      let photo = RecipePhoto(
        id: UUID(),
        recipeId: recipeDetails.recipe.id,
        position: 0,
        photoData: imageData
      )
      recipeDetails.photos = [photo]

      return .success(recipeDetails)
    } catch {
      // Fallback: Return empty recipe with OCR text in notes and source image
      let recipeId = UUID()
      let photo = RecipePhoto(
        id: UUID(),
        recipeId: recipeId,
        position: 0,
        photoData: imageData
      )
      let fallbackDetails = RecipeDetails(
        recipe: Recipe(
          id: recipeId,
          name: "",
          notes: ocrText
        ),
        ingredients: [],
        instructions: [],
        photos: [photo]
      )
      return .partialSuccess(fallbackDetails, ocrText: ocrText, error: error)
    }
  }
}
