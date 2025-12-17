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
        //        DynamicIslandExpandedRegion(.leading) {
        //          Text("Leading")
        //        }
        //        DynamicIslandExpandedRegion(.trailing) {
        //          Text("Trailing")
        //        }
        //        DynamicIslandExpandedRegion(.bottom) {
        //          Text("Bottom")
        //        }

        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing, spacing: 4) {
            Text(context.attributes.metadata?.recipeName ?? "Timer")
              .font(.headline)
              .lineLimit(1)
            Text("Timer")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          HStack(spacing: 16) {
            HStack(spacing: 12) {
              countdown(attributes: context.attributes, state: context.state, maxWidth: 150)
                .font(.system(size: 40, design: .rounded))

              AlarmProgressView(mode: context.state.mode, tintColor: context.attributes.tintColor)
                .frame(width: 40, height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Button(
              intent: CancelTimerIntent(
                alarmID: context.attributes.metadata?.alarmID.uuidString ?? "")
            ) {
              Image(systemName: "xmark")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.gray.opacity(0.5))
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
          }
        }
      } compactLeading: {
        //        recipeImageView(imageData: context.attributes.metadata?.recipeImageData, size: 24)
        //        Text("L")
        countdown(attributes: context.attributes, state: context.state, maxWidth: 44)
      } compactTrailing: {
        //        countdown(state: context.state, maxWidth: 44)
        AlarmProgressView(mode: context.state.mode, tintColor: context.attributes.tintColor)
        //        Text("T")
      } minimal: {
        AlarmProgressView(mode: context.state.mode, tintColor: context.attributes.tintColor)
        //        Text("M")
      }
      .keylineTint(context.attributes.tintColor)
    }
  }

  func lockScreenView(attributes: Attributes, state: AlarmPresentationState) -> some View {
    VStack(spacing: 16) {
      if let recipeName = attributes.metadata?.recipeName {
        HStack {
          Text(recipeName)
            .font(.headline)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      HStack(spacing: 12) {
        HStack {
          countdown(attributes: attributes, state: state, maxWidth: 150)
            .font(.system(size: 40, design: .rounded))
          Spacer()

          //          AlarmProgressView(mode: state.mode)
          //            .frame(width: 50, height: 50)
        }
        .frame(maxWidth: .infinity)

        if let alarmID = attributes.metadata?.alarmID.uuidString {
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
