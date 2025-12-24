//
//  String+IngredientParsing.swift
//  Recipes
//
//  Created by Eliott on 21-12-2025.
//

import Foundation

struct ParsedIngredient {
  let originalText: String
  let quantity: Double?
  let unit: String?
  let quantityUnitRange: Range<String.Index>?
  let remainder: String

  /// Returns the scaled ingredient text
  func scaled(by multiplier: Double) -> String {
    guard let quantity = quantity, let range = quantityUnitRange, multiplier != 1.0 else {
      return originalText
    }

    let scaledQuantity = quantity * multiplier
    let formattedQuantity = IngredientParsingHelper.formatQuantity(scaledQuantity)

    var result = originalText
    let beforeRange = originalText[..<range.lowerBound]
    let afterRange = originalText[range.upperBound...]

    // Reconstruct with scaled quantity
    if let unit = unit {
      result = beforeRange + formattedQuantity + " " + unit + afterRange
    } else {
      result = beforeRange + formattedQuantity + afterRange
    }

    return result
  }

  /// Returns the original text with quantity+unit styled
  func attributedText() -> (fullText: String, quantityUnitRange: Range<String.Index>?) {
    return (originalText, quantityUnitRange)
  }
}

extension String {
  /// Parses ingredient text to extract quantity and unit
  func parseIngredient() -> ParsedIngredient {
    let trimmed = self.trimmingCharacters(in: .whitespaces)

    // Pattern to match quantity at the start
    // Supports: integers, decimals, fractions (unicode and ASCII), mixed numbers
    // Order matters: match more complex patterns first
    let quantityPattern =
      #"^(\d+[\s]+\d+[\s]?\/[\s]?\d+|\d+[\s]?\/[\s]?\d+|\d+[\s]?[½¼¾⅓⅔⅛⅜⅝⅞]|\d*[\s]?[½¼¾⅓⅔⅛⅜⅝⅞]|\d+[\.,]\d+|\d+)"#

    guard
      let quantityRegex = try? NSRegularExpression(pattern: quantityPattern, options: [])
    else {
      return ParsedIngredient(
        originalText: self, quantity: nil, unit: nil, quantityUnitRange: nil, remainder: self)
    }

    let nsString = trimmed as NSString
    let quantityMatches = quantityRegex.matches(
      in: trimmed, options: [], range: NSRange(location: 0, length: nsString.length))

    guard let quantityMatch = quantityMatches.first,
      let quantityRange = Range(quantityMatch.range, in: trimmed)
    else {
      return ParsedIngredient(
        originalText: self, quantity: nil, unit: nil, quantityUnitRange: nil, remainder: self)
    }

    let quantityText = String(trimmed[quantityRange])
    let quantityValue = IngredientParsingHelper.parseQuantity(quantityText)

    // Look for unit immediately after quantity
    let afterQuantity = String(trimmed[quantityRange.upperBound...])
    // Updated pattern to handle French units like "c à s" (without dots) and "c. à s." (with dots)
    let unitPattern =
      #"^[\s]?(ml|mL|l|L|liter|litre|litres|tsp|teaspoon|teaspoons|tbsp|tablespoon|tablespoons|cup|cups|fl[\s]?oz|fluid[\s]?ounce|fluid[\s]?ounces|pint|pints|quart|quarts|gallon|gallons|c\.?[\s]?à[\s]?thé|c\.?[\s]?à[\s]?soupe|c\.?[\s]?à[\s]?s\.?|c\.?[\s]?à[\s]?café|c\.?[\s]?à[\s]?c\.?|tasse|tasses|g|gram|grams|gramme|grammes|kg|kilogram|kilograms|kilogramme|kilogrammes|oz|ounce|ounces|lb|lbs|pound|pounds|livre|livres|once|onces)\b"#

    if let unitRegex = try? NSRegularExpression(pattern: unitPattern, options: .caseInsensitive) {
      let unitMatches = unitRegex.matches(
        in: afterQuantity, options: [],
        range: NSRange(location: 0, length: (afterQuantity as NSString).length))

      if let unitMatch = unitMatches.first,
        let unitRangeInAfter = Range(unitMatch.range, in: afterQuantity)
      {
        let unitText = String(afterQuantity[unitRangeInAfter]).trimmingCharacters(
          in: .whitespaces)

        // Calculate full range including quantity and unit
        let unitEndIndex = trimmed.index(
          quantityRange.upperBound,
          offsetBy: afterQuantity.distance(
            from: afterQuantity.startIndex, to: unitRangeInAfter.upperBound))
        let fullRange = quantityRange.lowerBound..<unitEndIndex

        let remainder = String(trimmed[unitEndIndex...])

        return ParsedIngredient(
          originalText: self,
          quantity: quantityValue,
          unit: unitText,
          quantityUnitRange: fullRange,
          remainder: remainder
        )
      }
    }

    // No unit found, just quantity (e.g., "4 eggs")
    let remainder = String(trimmed[quantityRange.upperBound...])
    return ParsedIngredient(
      originalText: self,
      quantity: quantityValue,
      unit: nil,
      quantityUnitRange: quantityRange,
      remainder: remainder
    )
  }
}

// MARK: - Helper

private enum IngredientParsingHelper {
  // Unicode fraction map
  static let unicodeFractionMap: [String: Double] = [
    "½": 0.5,
    "¼": 0.25,
    "¾": 0.75,
    "⅓": 0.333333,
    "⅔": 0.666667,
    "⅛": 0.125,
    "⅜": 0.375,
    "⅝": 0.625,
    "⅞": 0.875,
  ]

  // Reverse map for formatting
  static let decimalToFraction: [(value: Double, fraction: String)] = [
    (0.875, "⅞"),
    (0.75, "¾"),
    (0.666667, "⅔"),
    (0.625, "⅝"),
    (0.5, "½"),
    (0.375, "⅜"),
    (0.333333, "⅓"),
    (0.25, "¼"),
    (0.125, "⅛"),
  ]

  static func parseQuantity(_ text: String) -> Double? {
    let trimmed = text.trimmingCharacters(in: .whitespaces)

    // Check for unicode fractions
    for (fraction, value) in unicodeFractionMap {
      if trimmed.contains(fraction) {
        // Check for mixed number (e.g., "1 ½")
        let parts = trimmed.components(separatedBy: " ")
        if parts.count == 2, let whole = Double(parts[0].replacingOccurrences(of: ",", with: ".")) {
          return whole + value
        }
        return value
      }
    }

    // Check for ASCII fractions (e.g., "1/2", "3/4")
    if trimmed.contains("/") {
      let parts = trimmed.components(separatedBy: " ")

      // Mixed number (e.g., "1 1/2")
      if parts.count == 2, let whole = Double(parts[0].replacingOccurrences(of: ",", with: ".")) {
        if let fractionValue = parseFraction(parts[1]) {
          return whole + fractionValue
        }
      }

      // Simple fraction (e.g., "1/2")
      if let fractionValue = parseFraction(trimmed) {
        return fractionValue
      }
    }

    // Check for decimal (handle both . and ,)
    let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
    return Double(normalized)
  }

  static func parseFraction(_ text: String) -> Double? {
    let parts = text.split(separator: "/")
    guard parts.count == 2,
      let numerator = Double(parts[0].trimmingCharacters(in: .whitespaces)),
      let denominator = Double(parts[1].trimmingCharacters(in: .whitespaces)),
      denominator != 0
    else {
      return nil
    }
    return numerator / denominator
  }

  static func formatQuantity(_ quantity: Double) -> String {
    // Check if it's a whole number
    if quantity.truncatingRemainder(dividingBy: 1) == 0 {
      return String(format: "%.0f", quantity)
    }

    // Extract whole and fractional parts
    let whole = Int(quantity)
    let fraction = quantity - Double(whole)

    // Try to match to a common fraction
    for (value, fractionSymbol) in decimalToFraction {
      if abs(fraction - value) < 0.01 {  // Tolerance for floating point
        if whole > 0 {
          return "\(whole) \(fractionSymbol)"
        } else {
          return fractionSymbol
        }
      }
    }

    // Check if fractional part is very small (round to whole)
    if fraction < 0.05 {
      return String(format: "%.0f", quantity.rounded())
    }

    // Format as decimal with reasonable precision
    if whole > 0 {
      return String(format: "%.1f", quantity)
    } else {
      return String(format: "%.2f", quantity)
    }
  }
}
