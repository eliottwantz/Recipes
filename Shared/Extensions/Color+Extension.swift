//
//  Color+Extension.swift
//  Recipes
//
//  Created by Eliott on 2025-10-18.
//

import SwiftUI

extension EnvironmentValues {
  var isDark: Bool {
    colorScheme == .dark
  }
}

private struct DarkPrimaryLightSecondaryModifier: ViewModifier {
  @Environment(\.isDark) private var isDark

  func body(content: Content) -> some View {
    content
      .background(Color(isDark ? .systemBackground : .secondarySystemBackground))
  }
}

private struct DarkSecondaryLightPrimaryModifier: ViewModifier {
  @Environment(\.isDark) private var isDark

  func body(content: Content) -> some View {
    content
      .background(Color(isDark ? .secondarySystemBackground : .systemBackground))
  }
}

extension View {
  func darkPrimaryLightSecondaryBackgroundColor() -> some View {
    modifier(DarkPrimaryLightSecondaryModifier())
  }
  func darkSecondaryLightPrimaryBackgroundColor() -> some View {
    modifier(DarkSecondaryLightPrimaryModifier())
  }
}

extension Color {
  /// Returns `.black` or `.white` to maximize contrast against the receiving color.
  func contrastingForegroundColor() -> Color {
    //    #if canImport(UIKit)
    let uiColor = UIColor(self)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
      let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
      return luminance > 0.55 ? .black : .white
    }

    var white: CGFloat = 0
    if uiColor.getWhite(&white, alpha: &alpha) {
      return white > 0.6 ? .black : .white
    }
    //    #endif

    return .white
  }
}
