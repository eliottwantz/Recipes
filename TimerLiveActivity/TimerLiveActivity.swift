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
        .activityBackgroundTint(Color(.systemBackground).opacity(0.45))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 8) {
            if let id = context.attributes.metadata?.alarmID,
              let image = ImageManager.loadLiveActivityImage(for: id)
            {
              image
                .resizable()
                .scaledToFill()
                .frame(width: 39, height: 39, alignment: .center)
                .clipShape(.rect(corners: .concentric))
                .accessibilityLabel("The recipe image")
            }

            if let step = context.attributes.metadata?.instructionStep {
              Text(String("Step \(step + 1)"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.horizontal, 5)
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
        HStack(spacing: 4) {
          if let id = context.attributes.metadata?.alarmID,
            let image = ImageManager.loadLiveActivityImage(for: id)
          {
            image
              .resizable()
              .scaledToFill()
              .frame(width: 26, height: 26, alignment: .center)
              .clipShape(.rect(corners: .concentric))
              .accessibilityLabel("The recipe image")
          }
          if let step = context.attributes.metadata?.instructionStep {
            Text(String("Step \(step + 1)"))
              .foregroundStyle(.primary)
              .fontWeight(.semibold)
          }
        }
      } compactTrailing: {
        countdown(
          attributes: context.attributes,
          state: context.state,
          maxWidth: 44
        )
      } minimal: {
        AlarmProgressView(
          mode: context.state.mode,
          tintColor: context.attributes.tintColor
        )
      }
      .keylineTint(context.attributes.tintColor)
      .widgetURL(context.attributes.metadata?.deepLink)
    }
  }

  // MARK: - Lock Screen View
  @ViewBuilder
  func lockScreenView(attributes: Attributes, state: AlarmPresentationState) -> some View {
    if let metadata = attributes.metadata {
      VStack(spacing: 6) {
        // MARK: Image and Step
        HStack(spacing: 12) {
          if let image = ImageManager.loadLiveActivityImage(for: metadata.alarmID) {
            image
              .resizable()
              .scaledToFill()
              .frame(width: 62, height: 62, alignment: .center)
              .clipShape(.rect(corners: .concentric))
              .accessibilityLabel("The recipe image")
          }

          VStack(alignment: .leading, spacing: 6) {
            Text(metadata.recipeName)
              .font(.title3)
              .fontWeight(.semibold)
              .multilineTextAlignment(.leading)
              .lineLimit(1)
              .frame(maxWidth: .infinity, alignment: .leading)

            if let step = metadata.instructionStep {
              Text(String("Step \(step + 1)"))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // MARK: Countdown and Cancel Button
        HStack {
          HStack {
            countdown(attributes: attributes, state: state, maxWidth: 280)
              .font(.system(size: 42, design: .rounded))
              .fontWeight(.semibold)
            Spacer()
          }
          .frame(maxWidth: .infinity)

          CancelButton(alarmID: metadata.alarmID.uuidString)
        }
      }
      .padding(.all, 16)
    } else {
      HStack {
        countdown(attributes: attributes, state: state, maxWidth: 150)
          .font(.system(size: 40, design: .rounded))
          .fontWeight(.semibold)
        Spacer()
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
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
    .fontWeight(.semibold)
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
      Label("Cancel timer", systemImage: "xmark")
        .labelStyle(.iconOnly)
        .font(.system(size: 18))
        .padding(3)
    }
    .buttonStyle(.borderedProminent)
    .buttonBorderShape(.circle)
    .tint(.gray.opacity(0.3))
  }
}
