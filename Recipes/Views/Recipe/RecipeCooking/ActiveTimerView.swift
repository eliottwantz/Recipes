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
  let onCancel: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(recipeName)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
          .lineLimit(1)

        Text(timerInterval: Date.now...endDate, countsDown: true)
          .font(.system(.title2, design: .rounded))
          .fontWeight(.bold)
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
