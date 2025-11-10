//
//  FormTimePickerLabeledContent.swift
//  Recipes
//
//  Created by Eliott on 2025-11-09.
//

import SwiftUI

struct FormTimePickerLabeledContent: View {
  let labelText: String
  @Binding var totalMinutes: Int
  @State private var isPresented = false
  
  init(_ labelText: String, totalMinutes: Binding<Int>) {
    self.labelText = labelText
    self._totalMinutes = totalMinutes
  }

  private var hours: Int {
    Int(totalMinutes / 60)
  }

  private var minutes: Int {
    totalMinutes.remainderReportingOverflow(dividingBy: 60).partialValue
  }

  var body: some View {
    LabeledContent(labelText) {
      Button {
        isPresented.toggle()
      } label: {
        TimeView(totalMinutes: totalMinutes)
      }
    }
    .popover(isPresented: $isPresented, attachmentAnchor: .point(.bottom)) {
      TimePicker(totalMinutes: $totalMinutes)
        .presentationCompactAdaptation(.none)
    }
  }
}

private struct TimePicker: View {
  @Binding var totalMinutes: Int
  @State private var hour: Int
  @State private var minute: Int
  private let hours = Array(0...100)
  private let minutes = Array(0...59)

  init(totalMinutes: Binding<Int>) {
    self._totalMinutes = totalMinutes
    let tm = totalMinutes.wrappedValue
    let (h, m) = computeTimeFromTotalMinutes(tm)
    _hour = State(initialValue: h)
    _minute = State(initialValue: m)
  }

  private var localTotalMinutes: Int {
    hour * 60 + minute
  }

  var body: some View {
    HStack(spacing: 0) {
      Picker("Hour", selection: $hour) {
        ForEach(hours, id: \.self) { h in
          Text(
            Measurement(value: Double(h), unit: UnitDuration.hours),
            format: .measurement(width: .wide)
          )
          .tag(h)
        }
      }
      .pickerStyle(.wheel)
      .frame(maxWidth: .infinity)
      .clipped()

      Picker("Minute", selection: $minute) {
        ForEach(minutes, id: \.self) { m in
          Text(
            Measurement(value: Double(m), unit: UnitDuration.minutes),
            format: .measurement(width: .wide)
          )
          .tag(m)
        }
      }
      .pickerStyle(.wheel)
      .frame(maxWidth: .infinity)
      .clipped()
    }
    .onChange(of: localTotalMinutes) { oldValue, newValue in
      totalMinutes = newValue
      print("Total minutes: \(totalMinutes), hour: \(hour), minute: \(minute)")
    }
  }
}

private struct TimeView: View {
  let totalMinutes: Int

  var formattedTime: String {
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60

    switch (hours, minutes) {
    case (0, 0):
      return "No time"
    case (_, 0):
      return "\(hours) h"
    case (0, _):
      return "\(minutes) min"
    default:
      return "\(hours) h \(minutes) min"
    }
  }

  var body: some View {
    Text(formattedTime)
  }
}

private func computeTimeFromTotalMinutes(_ totalMinutes: Int) -> (hour: Int, minute: Int) {
  let h = totalMinutes / 60
  let m = totalMinutes % 60
  return (hour: h, minute: m)
}

#Preview {
  VStack(spacing: 12) {
    TimeView(totalMinutes: 65)
    TimeView(totalMinutes: 120)
    TimeView(totalMinutes: 5)
    TimeView(totalMinutes: 0)
  }
}

#Preview {
  @Previewable @State var minutes = 72
  TimePicker(totalMinutes: $minutes)
}

#Preview {
  @Previewable @State var minutes = 125
  Form {
    FormTimePickerLabeledContent("Prep time", totalMinutes: $minutes)
  }
}
