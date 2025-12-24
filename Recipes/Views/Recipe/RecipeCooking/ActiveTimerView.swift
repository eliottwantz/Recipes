//
//  ActiveTimerView.swift
//  Recipes
//
//  Created by Eliott on 19-12-2025.
//

import AlarmKit
import SwiftUI

struct ActiveTimerView: View {
  let alarm: Alarm
  let endDate: Date
  let recipeName: String
  let instructionStep: Int?
  let onCancel: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      // MARK: - Image and Step
      HStack(spacing: 10) {
        if let image = ImageManager.loadLiveActivityImage(for: alarm.id) {
          image
            .resizable()
            .scaledToFill()
            .frame(width: 56, height: 56, alignment: .center)
            .clipShape(.rect(cornerRadius: 8))
            .accessibilityLabel("The recipe image")
        }

        // MARK: - Countdown and Cancel Button
        HStack {
          HStack {
            Text(timerInterval: Date.now...endDate, countsDown: true)
              .font(.system(size: 38, design: .rounded))
              .fontWeight(.semibold)
              .monospacedDigit()
              .lineLimit(1)
              .foregroundStyle(Color.accentColor)
              .minimumScaleFactor(0.6)
              .frame(maxWidth: 280, alignment: .leading)

            Spacer()
          }
          .frame(maxWidth: .infinity)

          Button {
            onCancel()
          } label: {
            Label("Cancel timer", systemImage: "xmark")
              .labelStyle(.iconOnly)
              .font(.system(size: 14))
              .padding(8)
          }
          .buttonStyle(.plain)
          .glassEffect(.regular.interactive().tint(.gray.opacity(0.3)), in: .circle)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // MARK: - Recipe Name and Step
      HStack {
        Text(recipeName)
          .font(.headline)
          .fontWeight(.semibold)
          .multilineTextAlignment(.leading)
          .lineLimit(1)
          .frame(maxWidth: .infinity, alignment: .leading)

        Spacer()

        if let instructionStep {
          Text(String("Step \(instructionStep + 1)"))
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
  }
}
