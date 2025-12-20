//
//  HighlightedTimeText.swift
//  Recipes
//
//  Created by Eliott on 20-12-2025.
//

import SwiftUI

struct HighlightedTimeText: View {
  let text: String
  let font: Font
  let lineSpacing: CGFloat
  let onTimeTap: (Int, Int, Int) -> Void

  init(
    text: String,
    font: Font = .system(size: 18),
    lineSpacing: CGFloat = 8,
    onTimeTap: @escaping (Int, Int, Int) -> Void
  ) {
    self.text = text
    self.font = font
    self.lineSpacing = lineSpacing
    self.onTimeTap = onTimeTap
  }

  var body: some View {
    Text(attributedText)
      .environment(
        \.openURL,
        OpenURLAction { url in
          handleTimeURL(url)
          return .handled
        })
  }

  private var attributedText: AttributedString {
    var attributedString = AttributedString(text)

    // Apply base styling
    attributedString.font = font
    attributedString.foregroundColor = .primary

    // Detect times in the text
    let detectedTimes = text.detectTimes()

    // Apply styling to each detected time
    for detectedTime in detectedTimes {
      // Convert String.Index range to AttributedString.Index range
      if let attrRange = Range(detectedTime.range, in: attributedString) {
        // Apply accent color
        attributedString[attrRange].foregroundColor = .accentColor

        // Apply semibold weight
        attributedString[attrRange].font = font.weight(.semibold)

        // Apply underline
        attributedString[attrRange].underlineStyle = .single

        // Add link for tap handling
        // URL format: recipetimer://?h=hours&m=minutes&s=seconds
        let urlString =
          "recipetimer://?h=\(detectedTime.hours)&m=\(detectedTime.minutes)&s=\(detectedTime.seconds)"
        if let url = URL(string: urlString) {
          attributedString[attrRange].link = url
        }
      }
    }

    return attributedString
  }

  private func handleTimeURL(_ url: URL) {
    guard url.scheme == "recipetimer" else { return }

    // Parse URL query parameters: recipetimer://?h=hours&m=minutes&s=seconds
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let queryItems = components.queryItems
    else {
      return
    }

    // Extract hours, minutes, and seconds from query parameters
    var hours: Int?
    var minutes: Int?
    var seconds: Int?

    for item in queryItems {
      switch item.name {
      case "h":
        hours = item.value.flatMap { Int($0) }
      case "m":
        minutes = item.value.flatMap { Int($0) }
      case "s":
        seconds = item.value.flatMap { Int($0) }
      default:
        break
      }
    }

    // Ensure all components are present
    guard let h = hours, let m = minutes, let s = seconds else {
      return
    }

    onTimeTap(h, m, s)
  }
}

#Preview {
  VStack(alignment: .leading, spacing: 20) {
    HighlightedTimeText(
      text: "Cook the garlic for 3 minutes until fragrant",
      onTimeTap: { h, m, s in
        print("Tapped time: \(h)h \(m)m \(s)s")
      }
    )

    HighlightedTimeText(
      text: "Sauté for 5 minutes, then simmer for 10 minutes",
      onTimeTap: { h, m, s in
        print("Tapped time: \(h)h \(m)m \(s)s")
      }
    )

    HighlightedTimeText(
      text: "Let it rest for five minutes before serving",
      onTimeTap: { h, m, s in
        print("Tapped time: \(h)h \(m)m \(s)s")
      }
    )

    HighlightedTimeText(
      text: "Bake for 1 hour and 30 minutes at 350°F",
      onTimeTap: { h, m, s in
        print("Tapped time: \(h)h \(m)m \(s)s")
      }
    )
  }
  .padding()
}
