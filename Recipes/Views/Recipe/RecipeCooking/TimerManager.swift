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
  typealias AlarmsMap = [UUID: (Alarm, LocalizedStringResource)]

  var alarmsMap = AlarmsMap()

  @ObservationIgnored nonisolated private let alarmManager = AlarmManager.shared

  init() {

  }

  func scheduleAlarm(with userInput: AlarmForm) {
    let attributes = AlarmAttributes(
      presentation: alarmPresentation(with: userInput), metadata: CookingAlarmMetadata(),
      tintColor: .accent)

    let id = UUID()
    let alarmConfiguration = AlarmConfiguration(
      countdownDuration: userInput.countdownDuration,
      attributes: attributes
    )

    scheduleAlarm(
      id: id,
      label: "The alarm title",
      alarmConfiguration: alarmConfiguration
    )
  }

  func scheduleAlarm(
    id: UUID, label: LocalizedStringResource, alarmConfiguration: AlarmConfiguration
  ) {
    Task {
      do {
        guard await requestAuthorization() else {
          print("Not authorized to schedule alarms.")
          return
        }

        let alarm = try await alarmManager.schedule(id: id, configuration: alarmConfiguration)
        alarmsMap[id] = (alarm, label)
      } catch {
        print("Error encountered when scheduling alarm: \(error)")
      }
    }
  }

  func unscheduleAlarm(with alarmID: UUID) {
    try? alarmManager.cancel(id: alarmID)
    Task { @MainActor in
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
    Task { @MainActor in

      // Update existing alarm states.
      remoteAlarms.forEach { updated in
        alarmsMap[updated.id, default: (updated, "Alarm (Old Session)")].0 = updated
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

  private func alarmPresentation(with userInput: AlarmForm) -> AlarmPresentation {
    let alertContent = AlarmPresentation.Alert(
      //      title: userInput.localizedLabel,
      title: "Timer Finished",
      secondaryButton: nil,
      secondaryButtonBehavior: nil
    )

    let countdownContent = AlarmPresentation.Countdown(
      //      title: userInput.localizedLabel,
      title: "Cooking Timer",
      pauseButton: .pauseButton
    )

    let pausedContent = AlarmPresentation.Paused(
      title: "Paused",
      resumeButton: .resumeButton
    )

    return AlarmPresentation(
      alert: alertContent,
      countdown: countdownContent,
      paused: pausedContent
    )
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
