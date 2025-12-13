//
//  Color+Extension.swift
//  Recipes
//
//  Created by Eliott on 2025-10-18.
//

import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

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
  /// Returns `.black` or `.white` to maximize contrast against the receiving color.
  /// Returns `.black` or `.white` to maximize contrast against the receiving color.
  func contrastingForegroundColor() -> Color {
    let uiColor = UIColor(self)

    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

    let R = sRGBToLinear(r)
    let G = sRGBToLinear(g)
    let B = sRGBToLinear(b)

    let luminance = relativeLuminance(r: R, g: G, b: B)

    // Return white for dark backgrounds, black for light backgrounds
    return luminance > 0.5 ? .black : .white
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
