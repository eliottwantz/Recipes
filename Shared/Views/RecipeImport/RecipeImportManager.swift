//
//  RecipeImportManager.swift
//  Recipes
//
//  Created by Eliott on 2025-11-08.
//

import Dependencies
import Foundation
import SQLiteData
import UIKit

nonisolated struct RecipeImportManager {
  @discardableResult
  @concurrent
  func importRecipe(from url: URL) async throws -> RecipeDetails {
    @Dependency(\.urlSession) var session

    guard url.scheme?.lowercased().hasPrefix("http") == true else {
      throw ImportError.unsupportedScheme(url.scheme)
    }
    let html = try await fetchHTML(from: url, session: session)
    return try await importRecipe(fromHTML: html, sourceURL: url)
  }

  @discardableResult
  @concurrent
  func importRecipe(fromHTML html: String, sourceURL: URL? = nil) async throws
    -> RecipeDetails
  {
    return try await extractRecipe(from: html, sourceURL: sourceURL)
  }

  func persist(
    _ details: RecipeDetails,
    in database: any DatabaseWriter
  ) throws {
    try database.write { db in
      try Recipe.insert { details.recipe }.execute(db)

      for ingredient in details.ingredients {
        try RecipeIngredient.insert { ingredient }.execute(db)
      }

      for instruction in details.instructions {
        try RecipeInstruction.insert { instruction }.execute(db)
      }

      for photo in details.photos {
        try RecipePhoto.insert { photo }.execute(db)
      }
    }
  }

  func extractRecipe(from html: String, sourceURL: URL? = nil) async throws -> RecipeDetails {
    let json = try extractRecipeJSON(from: html)
    guard var name = json["name"] as? String else {
      throw ImportError.missingRequiredField("name")
    }
    name = name.trimmingCharacters(in: .whitespacesAndNewlines)

    let recipeId = UUID()
    let ingredients = parseIngredients(json["recipeIngredient"], recipeId: recipeId)
    let instructions = parseInstructions(json["recipeInstructions"], recipeId: recipeId)
    let prepMinutes = parseDuration(json["prepTime"])
    let cookMinutes = parseDuration(json["cookTime"])
    let servings = parseServings(json["recipeYield"])
    let website = sourceURL?.absoluteString
    let nutrition = parseNutrition(json["nutrition"])
    let photos = await downloadRecipePhotos(from: json["image"], recipeId: recipeId)

    return RecipeDetails(
      recipe: Recipe(
        id: recipeId,
        name: name,
        prepTimeMinutes: prepMinutes ?? 0,
        cookTimeMinutes: cookMinutes ?? 0,
        servings: servings ?? 0,
        notes: nil,
        nutrition: nutrition,
        website: website
      ),
      ingredients: ingredients,
      instructions: instructions,
      photos: photos
    )
  }

  private func fetchHTML(from url: URL, session: URLSession) async throws -> String {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw ImportError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      throw ImportError.httpError(statusCode: httpResponse.statusCode)
    }

    if let contentType =
      httpResponse
      .value(forHTTPHeaderField: "Content-Type")?
      .lowercased(),
      contentType.contains("html") == false
    {
      throw ImportError.unsupportedContentType(contentType)
    }

    guard
      let html = String(data: data, encoding: .utf8)
        ?? String(data: data, encoding: .isoLatin1)
    else {
      throw ImportError.unreadableHTML
    }
    return html
  }

  private func extractRecipeJSON(from html: String) throws -> [String: Any] {
    let pattern = #"<script[^>]*type=["']application/ld\+json["'][^>]*>(.*?)</script>"#
    let regex = try NSRegularExpression(
      pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive])
    let range = NSRange(location: 0, length: html.utf16.count)

    let matches = regex.matches(in: html, options: [], range: range)
    for match in matches {
      guard match.numberOfRanges >= 2,
        let scriptRange = Range(match.range(at: 1), in: html)
      else {
        continue
      }

      let scriptContent = html[scriptRange]
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "\\u0022", with: "\"")
        .replacingOccurrences(of: "<!--", with: "")
        .replacingOccurrences(of: "-->", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

      guard let data = scriptContent.data(using: .utf8) else {
        continue
      }

      do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let candidates = collectRecipeCandidates(from: jsonObject)
        if let first = candidates.first {
          return first
        }
      } catch {
        continue
      }
    }
    throw ImportError.missingRecipeJSON
  }

  private func collectRecipeCandidates(from object: Any) -> [[String: Any]] {
    var results: [[String: Any]] = []

    if let dictionary = object as? [String: Any] {
      if typeContainsRecipe(dictionary["@type"]) {
        results.append(dictionary)
      }

      if let graph = dictionary["@graph"] {
        results.append(contentsOf: collectRecipeCandidates(from: graph))
      }
    } else if let array = object as? [Any] {
      for item in array {
        results.append(contentsOf: collectRecipeCandidates(from: item))
      }
    }

    return results
  }

  private func typeContainsRecipe(_ value: Any?) -> Bool {
    switch value {
    case let string as String:
      let normalized = string.lowercased()
      if normalized == "recipe" {
        return true
      }
      let tokens = normalized.split { $0.isLetter == false }
      return tokens.contains("recipe")
    case let array as [Any]:
      return array.contains(where: { typeContainsRecipe($0) })
    default:
      return false
    }
  }

  private func parseIngredients(_ value: Any?, recipeId: UUID) -> [RecipeIngredient] {
    if let string = value as? String {
      return [
        RecipeIngredient(
          id: UUID(), recipeId: recipeId, position: 0,
          text: string.trimmingCharacters(in: .whitespacesAndNewlines))
      ]
    }
    if let array = value as? [String] {
      return array.enumerated().map { index, text in
        RecipeIngredient(
          id: UUID(), recipeId: recipeId, position: index,
          text: text.trimmingCharacters(in: .whitespacesAndNewlines))
      }
    }
    if let array = value as? [Any] {
      return array.compactMap { element in
        if let string = element as? String {
          return RecipeIngredient(
            id: UUID(), recipeId: recipeId, position: 0,
            text: string.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let dictionary = element as? [String: Any], let text = dictionary["text"] as? String {
          return RecipeIngredient(
            id: UUID(), recipeId: recipeId, position: 0,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
      }
    }
    return []
  }

  private func parseInstructions(_ value: Any?, recipeId: UUID) -> [RecipeInstruction] {
    if let string = value as? String {
      return [
        RecipeInstruction(
          id: UUID(), recipeId: recipeId, position: 0,
          text: string.trimmingCharacters(in: .whitespacesAndNewlines))
      ]
    }
    if let array = value as? [String] {
      return array.enumerated().map { index, text in
        RecipeInstruction(
          id: UUID(), recipeId: recipeId, position: index,
          text: text.trimmingCharacters(in: .whitespacesAndNewlines))
      }
    }
    if let array = value as? [Any] {
      return array.flatMap { element -> [RecipeInstruction] in
        if let string = element as? String {
          return [
            RecipeInstruction(
              id: UUID(), recipeId: recipeId, position: 0,
              text: string.trimmingCharacters(in: .whitespacesAndNewlines))
          ]
        }
        if let dictionary = element as? [String: Any] {
          if let text = dictionary["text"] as? String {
            let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines).split(
              separator: "\r\n"
            ).joined()
            return [
              RecipeInstruction(id: UUID(), recipeId: recipeId, position: 0, text: cleanedText)
            ]
          }
          if let inner = dictionary["itemListElement"] {
            return parseInstructions(inner, recipeId: recipeId)
          }
        }
        return []
      }
    }
    if let dictionary = value as? [String: Any] {
      if let text = dictionary["text"] as? String {
        return [
          RecipeInstruction(
            id: UUID(), recipeId: recipeId, position: 0,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        ]
      }
      if let inner = dictionary["itemListElement"] {
        return parseInstructions(inner, recipeId: recipeId)
      }
    }
    return []
  }

  private func parseDuration(_ value: Any?) -> Int? {
    guard let string = value as? String else { return nil }
    return DurationParser.minutes(fromISO8601Duration: string)
  }

  private func parseServings(_ value: Any?) -> Int? {
    // Handle array - take first value
    if let array = value as? [Any], let first = array.first {
      return parseServings(first)
    }

    if let int = value as? Int {
      return int
    }
    if let number = value as? NSNumber {
      return number.intValue
    }
    if let string = value as? String {
      let scanner = Scanner(string: string)
      return scanner.scanInt()
    }
    return nil
  }

  private func parseNutrition(_ value: Any?) -> String? {
    guard let dict = value as? [String: Any] else { return nil }

    var nutritionParts: [String] = []

    if let calories = dict["calories"] as? String {
      nutritionParts.append("Calories: \(calories)")
    }
    if let protein = dict["proteinContent"] as? String {
      nutritionParts.append("Protein: \(protein)")
    }
    if let carbs = dict["carbohydrateContent"] as? String {
      nutritionParts.append("Carbs: \(carbs)")
    }
    if let fat = dict["fatContent"] as? String {
      nutritionParts.append("Fat: \(fat)")
    }

    return nutritionParts.isEmpty ? nil : nutritionParts.joined(separator: ", ")
  }

  private func downloadRecipePhotos(from value: Any?, recipeId: UUID) async -> [RecipePhoto] {
    guard let imageURL = parseImageURL(from: value) else { return [] }

    @Dependency(\.urlSession) var session

    do {
      let (data, _) = try await session.data(from: imageURL)

      // Verify it's a valid image
      guard UIImage(data: data) != nil else { return [] }

      return [
        RecipePhoto(
          id: UUID(),
          recipeId: recipeId,
          photoData: data
        )
      ]
    } catch {
      // Silently fail if image download fails
      return []
    }
  }

  private func parseImageURL(from value: Any?) -> URL? {
    // Handle array of URLs
    if let array = value as? [Any], let first = array.first {
      if let urlString = first as? String {
        return URL(string: urlString)
      }
      // Handle dictionary with @type and url
      if let dict = first as? [String: Any], let urlString = dict["url"] as? String {
        return URL(string: urlString)
      }
    }

    // Handle single URL string
    if let urlString = value as? String {
      return URL(string: urlString)
    }

    // Handle dictionary with @type and url
    if let dict = value as? [String: Any], let urlString = dict["url"] as? String {
      return URL(string: urlString)
    }

    return nil
  }

  // MARK: - Errors
  enum ImportError: Error, LocalizedError, Equatable {
    case unsupportedScheme(String?)
    case invalidResponse
    case httpError(statusCode: Int)
    case unsupportedContentType(String)
    case unreadableHTML
    case missingRecipeJSON
    case missingRequiredField(String)
    case unimplemented

    var errorDescription: String? {
      switch self {
      case .unsupportedScheme(let scheme):
        return "Unsupported URL scheme \(scheme ?? "nil")."
      case .invalidResponse:
        return "The server response was invalid."
      case .httpError(let statusCode):
        return "Request failed with status code \(statusCode)."
      case .unsupportedContentType(let type):
        return "Unsupported content type \(type)."
      case .unreadableHTML:
        return "Failed to read HTML from response."
      case .missingRecipeJSON:
        return "No JSON-LD recipe data found in the page."
      case .missingRequiredField(let field):
        return "Recipe JSON-LD missing required field \(field)."
      case .unimplemented:
        return "Recipe import manager is unimplemented for tests."
      }
    }
  }

  // MARK: - Utilities
  private enum DurationParser {
    private static let calendar: Calendar = {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = TimeZone(secondsFromGMT: 0)!
      return calendar
    }()

    static func minutes(fromISO8601Duration duration: String) -> Int? {
      let trimmed = duration.trimmingCharacters(in: .whitespacesAndNewlines)

      let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
          .withFullDate,
          .withFullTime,
          .withDashSeparatorInDate,
          .withColonSeparatorInTime,
          .withTimeZone,
        ]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
      }()

      let referenceDate: Date = {
        isoFormatter.date(from: "1970-01-01T00:00:00Z") ?? Date(timeIntervalSince1970: 0)
      }()

      if let absoluteDate = isoFormatter.date(from: trimmed) {
        let interval = absoluteDate.timeIntervalSince(referenceDate)
        return interval > 0 ? Int((interval / 60).rounded()) : nil
      }

      // Supports patterns like PT1H20M, PT45M, PT30S, P1DT2H, etc.
      let pattern = #"^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$"#
      guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return nil
      }

      let range = NSRange(location: 0, length: trimmed.utf16.count)
      guard let match = regex.firstMatch(in: trimmed, options: [], range: range) else {
        return nil
      }

      func intValue(at index: Int) -> Int {
        guard index < match.numberOfRanges,
          let range = Range(match.range(at: index), in: trimmed),
          let value = Int(trimmed[range])
        else {
          return 0
        }
        return value
      }

      let days = intValue(at: 1)
      let hours = intValue(at: 2)
      let minutes = intValue(at: 3)
      let seconds = intValue(at: 4)

      guard days > 0 || hours > 0 || minutes > 0 || seconds > 0 else {
        return nil
      }

      var components = DateComponents()
      components.day = days
      components.hour = hours
      components.minute = minutes
      components.second = seconds

      guard let date = calendar.date(byAdding: components, to: referenceDate) else {
        return nil
      }

      let interval = date.timeIntervalSince(referenceDate)
      return Int((interval / 60).rounded())
    }
  }

}

extension RecipeDetails {

}
