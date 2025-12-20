//
//  TimerManager.swift
//  Recipes
//
//  Created by Eliott on 17-12-2025.
//

@preconcurrency import AlarmKit
import AppIntents
import Dependencies
import SQLiteData
import SwiftUI

struct AlarmData: Identifiable {
  let alarm: Alarm
  let endDate: Date
  let recipeName: String

  var id: UUID { alarm.id }
}

@Observable
final class TimerManager {
  typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<CookingAlarmMetadata>

  @ObservationIgnored static let shared = TimerManager()
  var alarmsMap: [UUID: AlarmData] = [:]

  var upcomingAlarmsCount: Int {
    alarmsMap.count
  }

  var hasUpcomingAlarms: Bool {
    !alarmsMap.isEmpty
  }

  @ObservationIgnored nonisolated private let alarmManager = AlarmManager.shared
  @ObservationIgnored @Dependency(\.defaultDatabase) private var database
  @ObservationIgnored
  @FetchAll(CookingTimer.order(by: \.endDate).order(by: \.recipeName))
  private var timers

  private init() {
    observeAlarms()
    cleanupExpiredTimers()
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

        let endDate = Date.now.addingTimeInterval(userInput.interval)
        let alarmData = AlarmData(
          alarm: alarm,
          endDate: endDate,
          recipeName: userInput.recipeName
        )
        alarmsMap[id] = alarmData
        saveTimerToDatabase(id: id, endDate: endDate, recipeName: userInput.recipeName)
      } catch {
        print("Error encountered when scheduling alarm: \(error.localizedDescription)")
      }
    }
  }

  func unscheduleAlarm(with alarmID: UUID) {
    print("Unscheduling alarm with ID: \(alarmID)")
    alarmsMap[alarmID] = nil
    deleteTimerFromDatabase(id: alarmID)
    do {
      try alarmManager.cancel(id: alarmID)
    } catch {
      print("Error cancelling alarm with ID \(alarmID): \(error.localizedDescription)")
    }
  }

  private func observeAlarms() {
    Task {
      for await alarms in alarmManager.alarmUpdates {
        print("New alarm state update for \(alarms.count) alarms")
        updateAlarmState(with: alarms)
      }
    }
  }

  private func updateAlarmState(with remoteAlarms: [Alarm]) {
    // Update existing alarm states.
    remoteAlarms.forEach { updated in
      if let existingAlarmData = alarmsMap[updated.id] {
        print(
          "Updating alarm state \(updated.state) for ID: \(updated.id), recipe: \(existingAlarmData.recipeName)"
        )
        if updated.state == .alerting {
          alarmsMap[updated.id] = nil
          deleteTimerFromDatabase(id: updated.id)
        }
      } else {
        // New alarm detected
        let alarmsByID = Dictionary(uniqueKeysWithValues: remoteAlarms.map { ($0.id, $0) })

        for timer in timers {
          if let alarm = alarmsByID[timer.id] {
            let alarmData = AlarmData(
              alarm: alarm,
              endDate: timer.endDate,
              recipeName: timer.recipeName
            )
            alarmsMap[timer.id] = alarmData
            print("✅ Restored timer: \(timer.id) - \(timer.recipeName)")
          } else {
            // Timer in database but no matching alarm - clean up
            print("🧹 Cleaning up orphaned timer: \(timer.id)")
            deleteTimerFromDatabase(id: timer.id)
          }
        }
      }
    }

    let knownAlarmIDs = Set(alarmsMap.keys)
    let incomingAlarmIDs = Set(remoteAlarms.map(\.id))

    // Clean-up removed alarms.
    let removedAlarmIDs = Set(knownAlarmIDs.subtracting(incomingAlarmIDs))
    removedAlarmIDs.forEach {
      alarmsMap[$0] = nil
      deleteTimerFromDatabase(id: $0)
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

  // MARK: - Database Operations

  private func saveTimerToDatabase(id: UUID, endDate: Date, recipeName: String) {
    withErrorReporting {
      try database.write { db in
        try CookingTimer
          .insert {
            CookingTimer(
              id: id,
              recipeName: recipeName,
              endDate: endDate,
            )
          }
          .execute(db)
        print("✅ Timer saved to database: \(id)")
      }
    }
  }

  private func deleteTimerFromDatabase(id: UUID) {
    withErrorReporting {
      try database.write { db in
        try CookingTimer.delete().where { $0.id == id }.execute(db)
        print("✅ Timer deleted from database: \(id)")
      }
    }
  }

  private func cleanupExpiredTimers() {
    for timer in timers {
      if timer.endDate < Date.now {
        print("⏰ Timer \(timer.id) has expired, removing from database")
        deleteTimerFromDatabase(id: timer.id)
      }
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
