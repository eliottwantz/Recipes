//
//  ToastManager.swift
//  Recipes
//
//  Created by Eliott on 28-12-2025.
//

import SwiftUI

/// Manages toast notifications that appear from the top of the screen
@Observable
final class ToastManager {
  static let shared = ToastManager()

  struct Toast: Equatable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String?
    let tint: Color

    static func == (lhs: Toast, rhs: Toast) -> Bool {
      lhs.id == rhs.id
    }
  }

  private(set) var currentToast: Toast?
  private var dismissTask: Task<Void, Never>?

  private init() {}

  /// Shows a toast notification with custom icon, title, and optional subtitle
  /// - Parameters:
  ///   - icon: SF Symbol name
  ///   - title: Title to display
  ///   - subtitle: Optional subtitle to display below title
  ///   - tint: Tint color (defaults to accent color)
  ///   - duration: How long to show the toast in seconds (defaults to 2)
  func show(
    icon: String,
    title: String,
    subtitle: String? = nil,
    tint: Color = .clear,
    duration: TimeInterval = 2.0
  ) {
    // Cancel any existing dismiss task
    dismissTask?.cancel()

    // Replace current toast immediately
    currentToast = Toast(icon: icon, title: title, subtitle: subtitle, tint: tint)

    // Schedule auto-dismiss
    dismissTask = Task {
      try? await Task.sleep(for: .seconds(duration))
      dismiss()
    }
  }

  /// Dismisses the current toast immediately
  func dismiss() {
    dismissTask?.cancel()
    dismissTask = nil
    currentToast = nil
  }
}
