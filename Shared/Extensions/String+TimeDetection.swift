//
//  String+TimeDetection.swift
//  Recipes
//
//  Created by Eliott on 20-12-2025.
//

import Foundation

struct DetectedTime {
  let range: Range<String.Index>
  let matchedText: String
  let hours: Int
  let minutes: Int
  let seconds: Int

  var totalSeconds: Int {
    hours * 3600 + minutes * 60 + seconds
  }
}

extension String {
  /// Detects time expressions in the string and returns their ranges and parsed durations
  func detectTimes() -> [DetectedTime] {
    var detectedTimes: [DetectedTime] = []

    // Build the word number pattern for regex
    let wordNumberPattern = TimeDetectionHelper.wordNumberPattern

    // Pattern 1: Compound time (e.g., "1 hour and 30 minutes", "one hour and five minutes")
    let compoundPattern =
      #"(?:(\d+|"# + wordNumberPattern + #")\s*(?:hours?|hrs?)\s*(?:and)?\s*(\d+|"#
      + wordNumberPattern + #")\s*(?:minutes?|mins?))"#

    // Pattern 2: Range time with minimum value (e.g., "5-7 minutes", "5 to 7 minutes")
    let rangePattern =
      #"(?:(\d+|"# + wordNumberPattern + #")\s*(?:to|-)\s*(?:\d+|"# + wordNumberPattern
      + #")\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?))"#

    // Pattern 3: Decimal time (e.g., "1.5 hours", "1,5 hours")
    let decimalPattern = #"(?:(\d+[.,]\d+)\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?))"#

    // Pattern 4: Simple time (e.g., "5 minutes", "five minutes", "30 sec")
    let simplePattern =
      #"(?:(\d+|"# + wordNumberPattern + #")\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?))"#

    // Combine all patterns with word boundaries
    let combinedPattern =
      #"\b(?:"# + compoundPattern + "|" + rangePattern + "|" + decimalPattern + "|" + simplePattern
      + #")\b"#

    guard let regex = try? NSRegularExpression(pattern: combinedPattern, options: .caseInsensitive)
    else {
      return []
    }

    let nsString = self as NSString
    let matches = regex.matches(
      in: self, options: [], range: NSRange(location: 0, length: nsString.length))

    for match in matches {
      guard let range = Range(match.range, in: self) else { continue }
      let matchedText = String(self[range])

      // Parse the matched text to extract time components
      if let detectedTime = TimeDetectionHelper.parseTimeExpression(matchedText, range: range) {
        detectedTimes.append(detectedTime)
      }
    }

    return detectedTimes
  }
}

// MARK: - Helper

private enum TimeDetectionHelper {
  static let wordNumberPattern =
    #"(?:one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty(?:-?(?:one|two|three|four|five|six|seven|eight|nine))?|thirty(?:-?(?:one|two|three|four|five|six|seven|eight|nine))?|forty(?:-?(?:one|two|three|four|five|six|seven|eight|nine))?|fifty(?:-?(?:one|two|three|four|five|six|seven|eight|nine))?|sixty(?:-?(?:one|two|three|four|five|six|seven|eight|nine))?|seventy(?:-?(?:one|two|three|four|five|six|seven|eight|nine))?|eighty(?:-?(?:one|two|three|four|five|six|seven|eight|nine))?|ninety(?:-?(?:one|two|three|four|five|six|seven|eight|nine))?)"#

  static let wordToNumber: [String: Int] = [
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
    "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
    "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20,
    "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60,
    "seventy": 70, "eighty": 80, "ninety": 90,
  ]

  static func parseWordNumber(_ word: String) -> Int? {
    let lowercased = word.lowercased()

    // Check if it's a simple number word
    if let number = wordToNumber[lowercased] {
      return number
    }

    // Handle hyphenated compound numbers (e.g., "twenty-three", "thirty-five")
    if lowercased.contains("-") {
      let parts = lowercased.split(separator: "-")
      if parts.count == 2,
        let tens = wordToNumber[String(parts[0])],
        let ones = wordToNumber[String(parts[1])]
      {
        return tens + ones
      }
    }

    return nil
  }

  static func parseNumber(_ text: String) -> Int? {
    // Try parsing as integer
    if let number = Int(text) {
      return number
    }

    // Try parsing as word number
    return parseWordNumber(text)
  }

  static func parseDecimalNumber(_ text: String) -> Double? {
    // Handle both US (1.5) and EU (1,5) decimal formats
    let normalized = text.replacingOccurrences(of: ",", with: ".")
    return Double(normalized)
  }

  static func normalizeUnit(_ unit: String) -> String {
    let lowercased = unit.lowercased()
    if lowercased.hasPrefix("hour") || lowercased.hasPrefix("hr") {
      return "hours"
    } else if lowercased.hasPrefix("min") {
      return "minutes"
    } else if lowercased.hasPrefix("sec") {
      return "seconds"
    }
    return lowercased
  }

  static func parseTimeExpression(_ text: String, range: Range<String.Index>) -> DetectedTime? {
    var hours = 0
    var minutes = 0
    var seconds = 0

    // Check for compound time (e.g., "1 hour and 30 minutes")
    let compoundPattern =
      #"(\d+|\w+(?:-\w+)?)\s*(?:hours?|hrs?)\s*(?:and)?\s*(\d+|\w+(?:-\w+)?)\s*(?:minutes?|mins?)"#
    if let compoundRegex = try? NSRegularExpression(
      pattern: compoundPattern, options: .caseInsensitive)
    {
      let nsText = text as NSString
      if let match = compoundRegex.firstMatch(
        in: text, options: [], range: NSRange(location: 0, length: nsText.length))
      {
        if match.numberOfRanges >= 3 {
          let hourText = nsText.substring(with: match.range(at: 1))
          let minuteText = nsText.substring(with: match.range(at: 2))

          if let h = parseNumber(hourText), let m = parseNumber(minuteText) {
            hours = h
            minutes = m
            return DetectedTime(
              range: range, matchedText: text, hours: hours, minutes: minutes, seconds: seconds)
          }
        }
      }
    }

    // Check for range time (e.g., "5-7 minutes", "5 to 7 minutes") - use minimum
    let rangePattern =
      #"(\d+|\w+(?:-\w+)?)\s*(?:to|-)\s*(?:\d+|\w+(?:-\w+)?)\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?)"#
    if let rangeRegex = try? NSRegularExpression(pattern: rangePattern, options: .caseInsensitive) {
      let nsText = text as NSString
      if let match = rangeRegex.firstMatch(
        in: text, options: [], range: NSRange(location: 0, length: nsText.length))
      {
        if match.numberOfRanges >= 3 {
          let minValueText = nsText.substring(with: match.range(at: 1))
          let unitText = nsText.substring(with: match.range(at: 2))

          if let value = parseNumber(minValueText) {
            let unit = normalizeUnit(unitText)
            switch unit {
            case "hours": hours = value
            case "minutes": minutes = value
            case "seconds": seconds = value
            default: break
            }
            return DetectedTime(
              range: range, matchedText: text, hours: hours, minutes: minutes, seconds: seconds)
          }
        }
      }
    }

    // Check for decimal time (e.g., "1.5 hours", "1,5 hours")
    let decimalPattern = #"(\d+[.,]\d+)\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?)"#
    if let decimalRegex = try? NSRegularExpression(
      pattern: decimalPattern, options: .caseInsensitive)
    {
      let nsText = text as NSString
      if let match = decimalRegex.firstMatch(
        in: text, options: [], range: NSRange(location: 0, length: nsText.length))
      {
        if match.numberOfRanges >= 3 {
          let valueText = nsText.substring(with: match.range(at: 1))
          let unitText = nsText.substring(with: match.range(at: 2))

          if let value = parseDecimalNumber(valueText) {
            let unit = normalizeUnit(unitText)
            switch unit {
            case "hours":
              let totalMinutes = Int(value * 60)
              hours = totalMinutes / 60
              minutes = totalMinutes % 60
            case "minutes":
              let totalSeconds = Int(value * 60)
              minutes = totalSeconds / 60
              seconds = totalSeconds % 60
            case "seconds":
              seconds = Int(value)
            default: break
            }
            return DetectedTime(
              range: range, matchedText: text, hours: hours, minutes: minutes, seconds: seconds)
          }
        }
      }
    }

    // Check for simple time (e.g., "5 minutes", "five minutes")
    let simplePattern = #"(\d+|\w+(?:-\w+)?)\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?)"#
    if let simpleRegex = try? NSRegularExpression(pattern: simplePattern, options: .caseInsensitive)
    {
      let nsText = text as NSString
      if let match = simpleRegex.firstMatch(
        in: text, options: [], range: NSRange(location: 0, length: nsText.length))
      {
        if match.numberOfRanges >= 3 {
          let valueText = nsText.substring(with: match.range(at: 1))
          let unitText = nsText.substring(with: match.range(at: 2))

          if let value = parseNumber(valueText) {
            let unit = normalizeUnit(unitText)
            switch unit {
            case "hours": hours = value
            case "minutes": minutes = value
            case "seconds": seconds = value
            default: break
            }
            return DetectedTime(
              range: range, matchedText: text, hours: hours, minutes: minutes, seconds: seconds)
          }
        }
      }
    }

    return nil
  }
}
