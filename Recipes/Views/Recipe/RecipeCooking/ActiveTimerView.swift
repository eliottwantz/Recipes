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
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(recipeName)
          .font(.headline)
          .foregroundStyle(.primary)
          .lineLimit(1)

        if let instructionStep {
          Text("Step \(instructionStep)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Text(timerInterval: Date.now...endDate, countsDown: true)
          .font(.system(size: 33, design: .rounded))
          .fontWeight(.semibold)
          .foregroundStyle(.accent)
          .monospacedDigit()
      }

      Spacer()

      Button {
        onCancel()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.title2)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
    }
    .padding()
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
  }
}
