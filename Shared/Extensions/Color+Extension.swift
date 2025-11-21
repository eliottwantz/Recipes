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

#if os(iOS)
  extension Color {
    static let systemBackground = Color(uiColor: .systemBackground)
    static let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
    static let tertiarySystemBackground = Color(uiColor: .tertiarySystemBackground)
  }
#endif

#if os(macOS)
  extension Color {
    static let systemBackground = Color(nsColor: .windowBackgroundColor)
    static let secondarySystemBackground = Color(nsColor: .controlBackgroundColor)
    static let tertiarySystemBackground = Color(nsColor: .underPageBackgroundColor)
  }
#endif

extension Color {
  /// Returns `.black` or `.white` to maximize contrast against the receiving color.
  /// Returns `.black` or `.white` to maximize contrast against the receiving color.
  func contrastingForegroundColor() -> Color {
    #if os(iOS)
      let uiColor = UIColor(self)
    #elseif os(macOS)
      let uiColor = NSColor(self)
    #endif

    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    #if os(iOS)
      uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    #elseif os(macOS)
      // Convert to sRGB color space
      guard let rgbColor = uiColor.usingColorSpace(.sRGB) else {
        return .primary
      }
      rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    #endif

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
