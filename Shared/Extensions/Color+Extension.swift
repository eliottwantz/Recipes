//
//  Color+Extension.swift
//  Recipes
//
//  Created by Eliott on 2025-10-18.
//

import SwiftUI
import UIKit

extension EnvironmentValues {
  var isDark: Bool {
    colorScheme == .dark
  }
}

private struct DarkPrimaryLightSecondaryModifier: ViewModifier {
  @Environment(\.isDark) private var isDark

  func body(content: Content) -> some View {
    content
      .background(Color(isDark ? Color.systemBackground : Color.secondarySystemBackground))
  }
}

private struct DarkSecondaryLightPrimaryModifier: ViewModifier {
  @Environment(\.isDark) private var isDark

  func body(content: Content) -> some View {
    content
      .background(Color(isDark ? Color.secondarySystemBackground : Color.systemBackground))
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
  static let systemBackground = Color(uiColor: .systemBackground)
  static let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
  static let tertiarySystemBackground = Color(uiColor: .tertiarySystemBackground)
}

extension Color {

  static let accentContrasting: Color = {
    Color.accent.contrastingForegroundColor()
  }()

  /// Returns `.black` or `.white` to maximize contrast against the receiving color.
  /// Returns `.black` or `.white` to maximize contrast against the receiving color.
  private func contrastingForegroundColor() -> Color {
    let uiColor = UIColor(self)

    guard let components = uiColor.cgColor.components, components.count >= 3 else {
      // Fallback if we can't get components
      return .white
    }

    let r = components[0]
    let g = components[1]
    let b = components[2]

    let luminance = relativeLuminance(r: r, g: g, b: b)

    return luminance >= 0.5 ? .black : .white
  }

  private func sRGBToLinear(_ c: CGFloat) -> CGFloat {
    return c <= 0.04045 ? (c / 12.92) : pow((c + 0.055) / 1.055, 2.4)
  }

  private func relativeLuminance(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
    // WCAG 2.1 formula: https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
    let R = sRGBToLinear(r)
    let G = sRGBToLinear(g)
    let B = sRGBToLinear(b)
    return 0.2126 * R + 0.7152 * G + 0.0722 * B
  }
}
