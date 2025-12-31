//
//  ChatGPTPromptService.swift
//  Recipes
//
//  Created by Eliott on 2025-12-31.
//

import Foundation

struct ChatGPTPromptService {

  /// Generates a ChatGPT prompt for recipe recommendations based on available ingredients
  /// - Parameter ingredients: Raw text input from user (comma or newline separated)
  /// - Returns: Formatted prompt string
  static func generateRecipePrompt(ingredients: String) -> String {
    let cleanedIngredients =
      ingredients
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard !cleanedIngredients.isEmpty else {
      return
        "Please suggest some recipes with common ingredients and provide the links and sources."
    }

    return """
      I have these ingredients available: \(cleanedIngredients)

      Please search for recipes online that use these ingredients and provide:
      - Recipe names
      - Links to the original recipes
      - Sources/websites

      Focus on recipes where I have most of the main ingredients. Include 3-5 recipe suggestions.
      """
  }

  /// Creates a ChatGPT deeplink URL with the recipe prompt
  /// - Parameter ingredients: Raw text input from user
  /// - Returns: URL for opening ChatGPT app with the prompt, or nil if URL is invalid
  static func createChatGPTDeeplink(ingredients: String) -> URL? {
    let prompt = generateRecipePrompt(ingredients: ingredients)

    // URL encode the prompt
    guard let encodedPrompt = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    else {
      return nil
    }

    let deeplinkString = "https://chatgpt.com/?new-chat=true&prompt=\(encodedPrompt)"
    return URL(string: deeplinkString)
  }
}
