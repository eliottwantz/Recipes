//
//  TimerManager.swift
//  Recipes
//
//  Created by Eliott on 17-12-2025.
//

@preconcurrency import AlarmKit
import AppIntents
import SwiftUI

@Observable
final class TimerManager {
  typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<CookingAlarmMetadata>
  typealias AlarmsMap = [UUID: Alarm]

  var alarmsMap = AlarmsMap()

  @ObservationIgnored nonisolated private let alarmManager = AlarmManager.shared

  init() {
    observeAlarms()
  }

  func scheduleAlarm(with userInput: AlarmForm) {
    Task {
      guard await requestAuthorization() else {
        print("Not authorized to schedule alarms.")
        return
      }

      let id = UUID()

      let alertContent = AlarmPresentation.Alert(
        title: "Timer ended",
        secondaryButton: AlarmButton(
          text: "Open App", textColor: .black, systemImageName: "arrowshape.up.circle.fill"),
        secondaryButtonBehavior: .custom
      )

      let countdownContent = AlarmPresentation.Countdown(
        title: "Cooking Timer",
      )

      let attributes = AlarmAttributes<CookingAlarmMetadata>(
        presentation: AlarmPresentation(
          alert: alertContent,
          countdown: countdownContent,
        ),
        metadata: CookingAlarmMetadata(
          recipeName: userInput.recipeName,
          alarmID: id
        ),
        tintColor: .accent
      )

      let alarmConfiguration = AlarmConfiguration.timer(
        duration: userInput.interval,
        attributes: attributes,
        secondaryIntent: OpenAppIntent(alarmID: id.uuidString)
      )

      do {
        let alarm = try await alarmManager.schedule(id: id, configuration: alarmConfiguration)
        print("✅ Alarm scheduled successfully: \(alarm)")
        print("✅ Alarm ID: \(id)")
        print("✅ Alarm state: \(alarm.state)")
        alarmsMap[id] = alarm
      } catch {
        print("Error encountered when scheduling alarm: \(error.localizedDescription)")
      }
    }
  }

  func unscheduleAlarm(with alarmID: UUID) {
    try? alarmManager.cancel(id: alarmID)
    Task {
      alarmsMap[alarmID] = nil
    }
  }

  private func observeAlarms() {
    Task {
      for await incomingAlarms in alarmManager.alarmUpdates {
        updateAlarmState(with: incomingAlarms)
      }
    }
  }

  private func updateAlarmState(with remoteAlarms: [Alarm]) {
    Task {
      // Update existing alarm states.
      remoteAlarms.forEach { updated in
        alarmsMap[updated.id] = updated
      }

      let knownAlarmIDs = Set(alarmsMap.keys)
      let incomingAlarmIDs = Set(remoteAlarms.map(\.id))

      // Clean-up removed alarms.
      let removedAlarmIDs = Set(knownAlarmIDs.subtracting(incomingAlarmIDs))
      removedAlarmIDs.forEach {
        alarmsMap[$0] = nil
      }
    }
  }

  private func requestAuthorization() async -> Bool {
    switch alarmManager.authorizationState {
    case .notDetermined:
      do {
        let state = try await alarmManager.requestAuthorization()
        return state == .authorized
      } catch {
        print("Error occurred while requesting authorization: \(error)")
        return false
      }
    case .denied: return false
    case .authorized: return true
    @unknown default: return false
    }
  }
}

extension AlarmButton {
  static var pauseButton: Self {
    AlarmButton(text: "Pause", textColor: .black, systemImageName: "pause.fill")
  }

  static var resumeButton: Self {
    AlarmButton(text: "Start", textColor: .black, systemImageName: "play.fill")
  }
}

extension EnvironmentValues {
  @Entry var timerManager: TimerManager = TimerManager()
}
