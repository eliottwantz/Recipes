//
//  CountdownTimerPickerView.swift
//  Recipes
//
//  Created by Eliott on 14-12-2025.
//

import SwiftUI

struct CountdownTimerPickerView: View {
  @Binding var hours: Int
  @Binding var minutes: Int
  @Binding var seconds: Int
  let onStart: () -> Void
  let close: () -> Void

  private let hourOptions = Array(0...23)
  private let minuteOptions = Array(0...59)
  private let secondOptions = Array(0...59)

  private var isStartDisabled: Bool {
    hours == 0 && minutes == 0 && seconds == 0
  }

  private let labelOffset = 31.0

  private func addMinutes(_ minutesToAdd: Int) {
    let totalSeconds = hours * 3600 + minutes * 60 + seconds + (minutesToAdd * 60)
    let newHours = totalSeconds / 3600
    let remainingSeconds = totalSeconds % 3600
    let newMinutes = remainingSeconds / 60
    let newSeconds = remainingSeconds % 60

    hours = min(newHours, 23)
    minutes = newMinutes
    seconds = newSeconds
  }

  var body: some View {
    VStack(spacing: 0) {
      // Quick action buttons
      HStack(spacing: 12) {
        addButton(title: "+1 min", minutesToAdd: 1)
        addButton(title: "+5 min", minutesToAdd: 5)
        addButton(title: "+10 min", minutesToAdd: 10)
      }
      .padding(.horizontal, 14)

      HStack(spacing: 0) {
        pickerRow(title: "h", range: 0..<24, selection: $hours)
        pickerRow(title: "min", range: 0..<60, selection: $minutes)
        pickerRow(title: "s", range: 0..<60, selection: $seconds)
      }

      // Bottom action buttons
      HStack(spacing: 12) {
        Button("Cancel") {
          close()
          resetPicker()
        }
        .buttonStyle(.glass)
        .tint(.secondary)
        .controlSize(.large)
        .buttonSizing(.flexible)

        Button("Start") {
          onStart()
          close()
          resetPicker()
        }
        .buttonStyle(.glassProminent)
        .tint(.accentColor)
        .controlSize(.large)
        .buttonSizing(.flexible)
        .disabled(isStartDisabled)
      }
      .padding(.horizontal)
      .padding(.top, 6)
    }
    .padding(.vertical)
  }

  private func pickerRow(title: String, range: Range<Int>, selection: Binding<Int>) -> some View {
    Picker(title, selection: selection) {
      ForEach(range, id: \.self) {
        Text("\($0)")
      }
      .background(.clear)
    }
    .pickerStyle(.wheel)
    .tint(.white)
    .overlay {
      Text(title)
        .fontWeight(.semibold)
        .frame(width: labelOffset + 5, alignment: .leading)
        .offset(x: labelOffset)
    }
    .sensoryFeedback(.decrease, trigger: selection.wrappedValue) { old, new in
      new < old
    }
    .sensoryFeedback(.increase, trigger: selection.wrappedValue) { old, new in
      new > old
    }
  }

  private func addButton(title: String, minutesToAdd: Int) -> some View {
    Button {
      withAnimation {
        addMinutes(minutesToAdd)
      }
    } label: {
      Text(title)
        .padding(.vertical, 4)
    }
    .buttonStyle(.glass)
    .controlSize(.regular)
    .buttonSizing(.flexible)
  }

  private func resetPicker() {
    Task {
      try await Task.sleep(for: .milliseconds(200))
      hours = 0
      minutes = 0
      seconds = 0
    }
  }
}

#Preview {
  @Previewable @State var hours = 0
  @Previewable @State var minutes = 5
  @Previewable @State var seconds = 30

  CountdownTimerPickerView(
    hours: $hours,
    minutes: $minutes,
    seconds: $seconds,
    onStart: {
      print("Timer started: \(hours)h \(minutes)m \(seconds)s")
    },
    close: {}
  )
}
