//
//  VideoRecipeImportService.swift
//  Recipes
//
//  Created by Eliott on 2025-01-14.
//

import Dependencies
import Foundation
import os

nonisolated struct VideoRecipeImportService: Sendable {

  // MARK: - API Models

  nonisolated struct APIRequest: Encodable, Sendable {
    let video_url: String
    let language: String
  }

  nonisolated struct APIRecipeResponse: Decodable, Sendable {
    let name: String
    let ingredients: [String]
    let instructions: [String]
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let servings: Int
    let notes: String
  }

  // MARK: - Errors

  enum ImportError: Error, LocalizedError, Sendable {
    case missingAPIURL
    case missingAPIKey
    case invalidVideoURL
    case networkError(String)
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(String)
    case apiError(String)

    nonisolated var errorDescription: String? {
      switch self {
      case .missingAPIURL:
        return "Video import API is not configured."
      case .missingAPIKey:
        return "API key not configured. Please add your API key in Settings."
      case .invalidVideoURL:
        return "The URL provided is not valid."
      case .networkError(let message):
        return "Network error: \(message)"
      case .invalidResponse:
        return "Invalid response from server."
      case .httpError(let statusCode):
        return "Server error (HTTP \(statusCode))."
      case .decodingError:
        return "Failed to parse recipe from response."
      case .apiError(let message):
        return message
      }
    }
  }

  // MARK: - Public Methods

  @concurrent
  func importRecipe(from videoURL: URL, language: String) async throws -> RecipeDetails {
    guard let baseURL = Constants.videoRecipeAPIURL else {
      throw ImportError.missingAPIURL
    }

    // Construct full endpoint URL
    guard let apiURL = URL(string: "/api/recipe/parse", relativeTo: baseURL)?.absoluteURL else {
      throw ImportError.missingAPIURL
    }

    logger.debug("Using API url: \(apiURL.absoluteString)")

    // Get API key on main actor then continue
    let apiKey = await MainActor.run {
      SecureStorage.get(.videoRecipeAPIKey)
    }

    guard let apiKey else {
      throw ImportError.missingAPIKey
    }

    @Dependency(\.urlSession) var session

    // Build request
    var request = URLRequest(url: apiURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

    let body = APIRequest(video_url: videoURL.absoluteString, language: language)
    request.httpBody = try JSONEncoder().encode(body)

    // Make request
    let (data, response): (Data, URLResponse)
    do {
      (data, response) = try await session.data(for: request)
    } catch {
      logger.error("Network error during video recipe import: \(error.localizedDescription)")
      throw ImportError.networkError(error.localizedDescription)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw ImportError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      logger.error("HTTP error \(httpResponse.statusCode) during video recipe import.")
      throw ImportError.httpError(statusCode: httpResponse.statusCode)
    }

    // Decode response
    let apiRecipe: APIRecipeResponse
    do {
      apiRecipe = try JSONDecoder().decode(APIRecipeResponse.self, from: data)
    } catch {
      logger.error("Decoding error during video recipe import: \(error.localizedDescription)")
      throw ImportError.decodingError(error.localizedDescription)
    }

    // Convert to RecipeDetails
    return convertToRecipeDetails(apiRecipe, sourceURL: videoURL)
  }

  // MARK: - Private Methods

  nonisolated private func convertToRecipeDetails(_ response: APIRecipeResponse, sourceURL: URL)
    -> RecipeDetails
  {
    let recipeId = UUID()

    let ingredients = response.ingredients.enumerated().map { index, text in
      RecipeIngredient(
        id: UUID(),
        recipeId: recipeId,
        position: index,
        text: text.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    }

    let instructions = response.instructions.enumerated().map { index, text in
      RecipeInstruction(
        id: UUID(),
        recipeId: recipeId,
        position: index,
        text: text.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    }

    return RecipeDetails(
      recipe: Recipe(
        id: recipeId,
        name: response.name.trimmingCharacters(in: .whitespacesAndNewlines),
        prepTimeMinutes: response.prepTimeMinutes,
        cookTimeMinutes: response.cookTimeMinutes,
        servings: response.servings,
        notes: response.notes.isEmpty ? nil : response.notes,
        website: sourceURL.absoluteString
      ),
      ingredients: ingredients,
      instructions: instructions,
      photos: []
    )
  }
}

nonisolated private let logger = Logger(
  subsystem: Constants.bundleID, category: "VideoRecipeImportService"
)
