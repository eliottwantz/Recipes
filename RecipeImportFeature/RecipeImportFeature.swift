//
//  RecipeImportFeature.swift
//  RecipeImportFeature
//
//  Created by Eliott on 2025-10-24.
//

import Foundation

public struct RecipeImportPipeline {
  public init() {}

  public func importedRecipe(from url: URL, session: URLSession) async throws -> ImportedRecipe {
    guard url.scheme?.lowercased().hasPrefix("http") == true else {
      throw RecipeImportError.unsupportedScheme(url.scheme)
    }

    let html = try await fetchHTML(from: url, session: session)
    let json = try extractRecipeJSON(from: html)
    return try ImportedRecipe(json: json)
  }

  public nonisolated func fetchHTML(from url: URL, session: URLSession) async throws -> String {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw RecipeImportError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      throw RecipeImportError.httpError(statusCode: httpResponse.statusCode)
    }

    if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased(),
      contentType.contains("html") == false
    {
      throw RecipeImportError.unsupportedContentType(contentType)
    }

    guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
    else {
      throw RecipeImportError.unreadableHTML
    }
    return html
  }

  public nonisolated func extractRecipeJSON(from html: String) throws -> [String: Any] {
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
        let candidates = Self.collectRecipeCandidates(from: jsonObject)
        if let first = candidates.first {
          return first
        }
      } catch {
        continue
      }
    }
    throw RecipeImportError.missingRecipeJSON
  }

  private nonisolated static func collectRecipeCandidates(from object: Any) -> [[String: Any]] {
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

  private nonisolated static func typeContainsRecipe(_ value: Any?) -> Bool {
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
}

public struct ImportedRecipe {
  public let title: String
  public let summary: String?
  public let ingredients: [String]
  public let instructions: [String]
  public let prepMinutes: Int?
  public let cookMinutes: Int?
  public let servings: Int?

  public init(json: [String: Any]) throws {
    guard let name = json["name"] as? String else {
      throw RecipeImportError.missingRequiredField("name")
    }
    title = name.trimmingCharacters(in: .whitespacesAndNewlines)
    summary = (json["description"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

    ingredients = ImportedRecipe.parseIngredients(json["recipeIngredient"])
    instructions = ImportedRecipe.parseInstructions(json["recipeInstructions"])
    prepMinutes = ImportedRecipe.parseDuration(json["prepTime"])
    cookMinutes = ImportedRecipe.parseDuration(json["cookTime"])
    servings = ImportedRecipe.parseServings(json["recipeYield"])
  }

  private static func parseIngredients(_ value: Any?) -> [String] {
    if let string = value as? String {
      return [string.trimmingCharacters(in: .whitespacesAndNewlines)]
    }
    if let array = value as? [String] {
      return array.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    if let array = value as? [Any] {
      return array.compactMap { element in
        if let string = element as? String {
          return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let dictionary = element as? [String: Any], let text = dictionary["text"] as? String {
          return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
      }
    }
    return []
  }

  private static func parseInstructions(_ value: Any?) -> [String] {
    if let string = value as? String {
      return [string.trimmingCharacters(in: .whitespacesAndNewlines)]
    }
    if let array = value as? [String] {
      return array.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    if let array = value as? [Any] {
      return array.flatMap { element -> [String] in
        if let string = element as? String {
          return [string.trimmingCharacters(in: .whitespacesAndNewlines)]
        }
        if let dictionary = element as? [String: Any] {
          if let text = dictionary["text"] as? String {
            return [text.trimmingCharacters(in: .whitespacesAndNewlines)]
          }
          if let inner = dictionary["itemListElement"] {
            return parseInstructions(inner)
          }
        }
        return []
      }
    }
    if let dictionary = value as? [String: Any] {
      if let text = dictionary["text"] as? String {
        return [text.trimmingCharacters(in: .whitespacesAndNewlines)]
      }
      if let inner = dictionary["itemListElement"] {
        return parseInstructions(inner)
      }
    }
    return []
  }

  private static func parseDuration(_ value: Any?) -> Int? {
    guard let string = value as? String else { return nil }
    return DurationParser.minutes(fromISO8601Duration: string)
  }

  private static func parseServings(_ value: Any?) -> Int? {
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
}

// MARK: - Errors

public enum RecipeImportError: Error, LocalizedError, Equatable {
  case unsupportedScheme(String?)
  case invalidResponse
  case httpError(statusCode: Int)
  case unsupportedContentType(String)
  case unreadableHTML
  case missingRecipeJSON
  case missingRequiredField(String)
  case unimplemented

  public var errorDescription: String? {
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
  private static let isoFormatter: ISO8601DateFormatter = {
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

  private static let referenceDate: Date = {
    isoFormatter.date(from: "1970-01-01T00:00:00Z") ?? Date(timeIntervalSince1970: 0)
  }()

  private static var calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }()

  static func minutes(fromISO8601Duration duration: String) -> Int? {
    let trimmed = duration.trimmingCharacters(in: .whitespacesAndNewlines)

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
