//
//  TimerLiveActivity.swift
//  CookingLiveActivity
//
//  Created by Eliott on 17-12-2025.
//

import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

struct TimerLiveActivity: Widget {
  typealias Attributes = AlarmAttributes<CookingAlarmMetadata>

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: Attributes.self) { context in
      lockScreenView(attributes: context.attributes, state: context.state)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          if let step = context.attributes.metadata?.instructionStep {
            Text(String("Step \(step)"))
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .padding(.leading, 5)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 8) {
            Text(context.attributes.metadata?.recipeName ?? "")
              .font(.headline)
              .lineLimit(1)
              .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
              HStack(spacing: 12) {
                countdown(attributes: context.attributes, state: context.state, maxWidth: 150)
                  .font(.system(size: 40, design: .rounded))
                  .fontWeight(.semibold)
              }

              Spacer()

              if let alarmID = context.attributes.metadata?.alarmID.uuidString {
                CancelButton(alarmID: alarmID)
              }
            }
            .frame(maxWidth: .infinity)
          }
          .padding(.horizontal, 5)
        }
      } compactLeading: {
        countdown(attributes: context.attributes, state: context.state, maxWidth: 44)
      } compactTrailing: {
        AlarmProgressView(mode: context.state.mode, tintColor: context.attributes.tintColor)
      } minimal: {
        AlarmProgressView(mode: context.state.mode, tintColor: context.attributes.tintColor)
      }
      .keylineTint(context.attributes.tintColor)
    }
  }

  func lockScreenView(attributes: Attributes, state: AlarmPresentationState) -> some View {
    VStack(spacing: 16) {
      if let recipeName = attributes.metadata?.recipeName {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(recipeName)
              .font(.headline)
              .lineLimit(1)

            if let instructionStep = attributes.metadata?.instructionStep {
              Text("Step \(instructionStep)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      HStack(spacing: 12) {
        HStack {
          countdown(attributes: attributes, state: state, maxWidth: 150)
            .font(.system(size: 40, design: .rounded))
            .fontWeight(.semibold)
          Spacer()
        }
        .frame(maxWidth: .infinity)

        if let alarmID = attributes.metadata?.alarmID.uuidString {
          CancelButton(alarmID: alarmID)
        }
      }
    }
    .padding(.all, 16)
  }

  func countdown(
    attributes: Attributes, state: AlarmPresentationState, maxWidth: CGFloat = .infinity
  ) -> some View {
    Group {
      switch state.mode {
      case .countdown(let countdown):
        Text(timerInterval: Date.now...countdown.fireDate, countsDown: true)
      case .paused(let state):
        let remaining = Duration.seconds(
          state.totalCountdownDuration - state.previouslyElapsedDuration)
        let pattern: Duration.TimeFormatStyle.Pattern =
          remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
        Text(remaining.formatted(.time(pattern: pattern)))
      default:
        EmptyView()
      }
    }
    .monospacedDigit()
    .foregroundStyle(attributes.tintColor)
    .lineLimit(1)
    .minimumScaleFactor(0.6)
    .frame(maxWidth: maxWidth, alignment: .leading)
  }

}

// MARK: - Circular Progress View

struct AlarmProgressView: View {
  var mode: AlarmPresentationState.Mode
  var tintColor: Color

  var body: some View {
    Group {
      switch mode {
      case .countdown(let countdown):
        ProgressView(
          timerInterval: Date.now...countdown.fireDate,
          countsDown: true,
          label: { EmptyView() },
          currentValueLabel: { EmptyView() }
        )
      case .paused(let pausedState):
        let remaining = pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
        ProgressView(
          value: remaining,
          total: pausedState.totalCountdownDuration,
          label: { EmptyView() },
          currentValueLabel: {
            Image(systemName: "pause.fill")
              .scaleEffect(0.8)
          })
      default:
        EmptyView()
      }
    }
    .progressViewStyle(.circular)
    .tint(tintColor)
  }
}

private struct CancelButton: View {
  let alarmID: String

  var body: some View {
    Button(intent: CancelTimerIntent(alarmID: alarmID)) {
      Label("Cancel", systemImage: "xmark")
        .font(.title2)
        .fontWeight(.regular)
        .foregroundStyle(.primary)
        .labelStyle(.iconOnly)
        .padding(5)
    }
    .clipShape(.circle)
    .buttonStyle(.bordered)
    .tint(.secondary)
  }
}
