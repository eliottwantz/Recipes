//
//  View+Toast.swift
//  Recipes
//
//  Created by Eliott on 28-12-2025.
//

import SwiftUI

extension View {
  /// Adds a toast presenter overlay that displays toasts from ToastManager
  func toastPresenter() -> some View {
    self.modifier(ToastPresenterModifier())
  }
}

struct ToastPresenterModifier: ViewModifier {
  private var toastManager = ToastManager.shared
  @State private var dragOffset: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .top) {
        if let toast = toastManager.currentToast {
          ToastView(
            icon: toast.icon,
            title: toast.title,
            subtitle: toast.subtitle,
            tint: toast.tint
          )
          .offset(y: dragOffset)
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { value in
                // Only allow upward drag (negative translation)
                if value.translation.height < 0 {
                  dragOffset = value.translation.height
                }
              }
              .onEnded { value in
                // If dragged up past threshold, dismiss
                if value.translation.height < -30 {
                  withAnimation(.spring) {
                    dragOffset = -200  // Animate off screen
                  }
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    toastManager.dismiss()
                    dragOffset = 0
                  }
                } else {
                  // Spring back to original position
                  withAnimation(.spring) {
                    dragOffset = 0
                  }
                }
              }
          )
          .transition(.move(edge: .top).combined(with: .opacity))
          .onChange(of: toast.id) { _, _ in
            // Reset drag offset when a new toast appears
            dragOffset = 0
          }
        }
      }
      .animation(
        .spring(response: 0.35, dampingFraction: 0.55),
        value: toastManager.currentToast
      )
  }
}
