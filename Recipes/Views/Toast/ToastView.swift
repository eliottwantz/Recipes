//
//  ToastView.swift
//  Recipes
//
//  Created by Eliott on 28-12-2025.
//

import SwiftUI

/// A toast notification view that displays an icon and message in a capsule
struct ToastView: View {
  let icon: String
  let title: String
  let subtitle: String?
  let tint: Color

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title2)

      HStack(alignment: .center) {
        VStack(alignment: .center, spacing: 2) {
          Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
          
          if let subtitle {
            Text(subtitle)
              .font(.footnote.weight(.semibold))
              .foregroundStyle(.secondary)
          }
        }
      }
      .frame(minWidth: 100, alignment: .center)
    }
    .frame(minHeight: 40)
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .glassEffect(.regular.tint(tint.opacity(0.2)), in: .capsule)
    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
  }
}

#Preview {
  VStack(spacing: 20) {
    ToastView(
      icon: "hand.raised.fill",
      title: "Hands-free mode enabled",
      subtitle: "Wink to navigate steps",
      tint: .blue
    )

    ToastView(
      icon: "checkmark.circle.fill",
      title: "Recipe saved!",
      subtitle: nil,
      tint: .green
    )

    ToastView(
      icon: "star.fill",
      title: "Added to favorites",
      subtitle: "View in your collection",
      tint: .clear
    )
  }
}
