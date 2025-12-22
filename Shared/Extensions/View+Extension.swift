//
//  View+Extension.swift
//  Recipes
//
//  Created by Eliott on 2025-11-09.
//

import SwiftUI

extension View {
  @ViewBuilder func `if`<Content: View>(
    _ condition: Bool,
    transform: (Self) -> Content
  ) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

private struct CardModifier: ViewModifier {
  let cornerRadius: CGFloat

  init(cornerRadius: CGFloat? = nil) {
    self.cornerRadius = cornerRadius ?? 20
  }

  func body(content: Content) -> some View {
    content
      .darkSecondaryLightPrimaryBackgroundColor()
      .clipShape(.rect(cornerRadius: cornerRadius))
      .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
  }
}

extension View {
  func card(cornerRadius: CGFloat? = nil) -> some View {
    modifier(
      CardModifier(cornerRadius: cornerRadius)
    )
  }
}
