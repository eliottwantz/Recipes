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
import os

struct AlarmData: Identifiable {
  let alarm: Alarm
  let endDate: Date
  let recipeId: Recipe.ID
  let recipeName: String
  let instructionStep: Int?

  var id: UUID { alarm.id }
}

@Observable
final class TimerManager {
  typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<CookingAlarmMetadata>

  @ObservationIgnored static let shared = TimerManager()
  private var alarmsMap = [UUID: AlarmData]()

  var upcomingAlarmsCount: Int {
    alarmsMap.count
  }

  var hasUpcomingAlarms: Bool {
    !alarmsMap.isEmpty
  }

  var sortedAlarms: [AlarmData] {
    alarmsMap.values
      .sorted { $0.endDate < $1.endDate }
      .sorted {
        $0.recipeName.compare(
          $1.recipeName,
          options: [.caseInsensitive, .diacriticInsensitive],
          range: nil,
          locale: Locale.current
        ) == .orderedAscending
      }
  }

  @ObservationIgnored nonisolated private let alarmManager = AlarmManager.shared
  @ObservationIgnored @Dependency(\.defaultDatabase) private var database
  @ObservationIgnored
  @FetchAll private var timers: [CookingTimer]

  private init() {
    observeAlarms()
    cleanupExpiredTimers()
  }

  func scheduleAlarm(with userInput: CookingTimerForm) {
    Task {
      guard await requestAuthorization() else {
        logger.info("Not authorized to schedule alarms.")
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
          alarmID: id,
          recipeID: userInput.recipeId,
          recipeName: userInput.recipeName,
          instructionStep: userInput.instructionStep
        ),
        tintColor: .accent
      )

      let alarmConfiguration = AlarmConfiguration.timer(
        duration: userInput.interval,
        attributes: attributes,
        secondaryIntent: OpenAppIntent(
          alarmID: id.uuidString,
          recipeID: userInput.recipeId.uuidString,
          instructionStep: userInput.instructionStep
        )
      )

      ImageManager.saveImageForLiveActivity(
        userInput.imageData,
        for: id
      )

      do {
        let alarm = try await alarmManager.schedule(id: id, configuration: alarmConfiguration)
        logger.info("✅ Alarm scheduled successfully: \(id)")
        #if DEBUG
          print("✅ Alarm state: \(alarm.state)")
        #endif

        let endDate = Date.now.addingTimeInterval(userInput.interval)
        let alarmData = AlarmData(
          alarm: alarm,
          endDate: endDate,
          recipeId: userInput.recipeId,
          recipeName: userInput.recipeName,
          instructionStep: userInput.instructionStep
        )
        alarmsMap[id] = alarmData
        saveTimerToDatabase(
          timer: CookingTimer(
            id: id,
            recipeId: userInput.recipeId,
            recipeName: userInput.recipeName,
            instructionStep: userInput.instructionStep,
            endDate: endDate
          ))
      } catch {
        logger.error("Error encountered when scheduling alarm: \(error.localizedDescription)")
      }
    }
  }

  func unscheduleAlarm(with alarmID: UUID) {
    logger.info("Unscheduling alarm with ID: \(alarmID)")
    cleanupAlarm(with: alarmID)
    do {
      try alarmManager.cancel(id: alarmID)
    } catch {
      logger.error("Error cancelling alarm with ID \(alarmID): \(error.localizedDescription)")
    }
  }

  private func cleanupAlarm(with alarmID: UUID) {
    logger.info("🔔 Cleaning up alarm with ID: \(alarmID)")
    alarmsMap[alarmID] = nil
    deleteTimerFromDatabase(id: alarmID)
    ImageManager.deleteImage(for: alarmID)
  }

  private func observeAlarms() {
    Task {
      for await alarms in alarmManager.alarmUpdates {
        logger.info("New alarm state update for \(alarms.count) alarms")
        updateAlarmState(with: alarms)
      }
    }
  }

  private func updateAlarmState(with remoteAlarms: [Alarm]) {
    // Update existing alarm states.
    let alarmsByID = Dictionary(uniqueKeysWithValues: remoteAlarms.map { ($0.id, $0) })
    remoteAlarms.forEach { updated in
      if let existingAlarmData = alarmsMap[updated.id] {
        #if DEBUG
          print(
            "Updating alarm state \(updated.state) for ID: \(updated.id), recipe: \(existingAlarmData.recipeName)"
          )
        #endif
        if updated.state == .alerting {
          logger.info("🔔 Removing alerting alarm with ID: \(updated.id)")
          cleanupAlarm(with: updated.id)
        }
      } else {
        // New alarm detected
        for timer in timers {
          if let alarm = alarmsByID[timer.id] {
            let alarmData = AlarmData(
              alarm: alarm,
              endDate: timer.endDate,
              recipeId: timer.recipeId,
              recipeName: timer.recipeName,
              instructionStep: timer.instructionStep
            )
            alarmsMap[timer.id] = alarmData
            logger.info("✅ Restored timer: \(timer.id) - \(timer.recipeName)")
          } else {
            // Timer in database but no matching alarm - clean up
            logger.info("🧹 Cleaning up orphaned timer: \(timer.id)")
            cleanupAlarm(with: timer.id)
          }
        }

        if timers.isEmpty {
          logger.info("No timers found in database to restore.")
          alarmsByID.forEach {
            do {
              try alarmManager.cancel(id: $0.key)
            } catch {
              logger.error(
                "Error cancelling orphaned alarm with ID \($0.key): \(error.localizedDescription)")
            }
          }
        }
      }
    }

    if remoteAlarms.isEmpty && !timers.isEmpty {
      logger.info("No active alarms but timers exist in database, cleaning up all timers.")
      for timer in timers {
        cleanupAlarm(with: timer.id)
      }
    }

    let knownAlarmIDs = Set(alarmsMap.keys)
    let incomingAlarmIDs = Set(remoteAlarms.map(\.id))

    // Clean-up removed alarms.
    let removedAlarmIDs = Set(knownAlarmIDs.subtracting(incomingAlarmIDs))
    removedAlarmIDs.forEach {
      cleanupAlarm(with: $0)
    }
  }

  private func requestAuthorization() async -> Bool {
    switch alarmManager.authorizationState {
    case .notDetermined:
      do {
        let state = try await alarmManager.requestAuthorization()
        return state == .authorized
      } catch {
        logger.error("Error occurred while requesting authorization: \(error)")
        return false
      }
    case .denied: return false
    case .authorized: return true
    @unknown default: return false
    }
  }

  // MARK: - Database Operations

  private func saveTimerToDatabase(timer: CookingTimer) {
    withErrorReporting {
      try database.write { db in
        try CookingTimer.insert { timer }.execute(db)
        logger.info("✅ Timer saved to database: \(timer.id)")
      }
    }
  }

  private func deleteTimerFromDatabase(id: UUID) {
    withErrorReporting {
      try database.write { db in
        try CookingTimer.delete().where { $0.id == id }.execute(db)
        logger.info("✅ Timer deleted from database: \(id)")
      }
    }
  }

  func cleanupTimersForRecipe(_ recipeId: Recipe.ID) {
    for timer in timers.filter({ $0.recipeId == recipeId }) {
      unscheduleAlarm(with: timer.id)
    }
  }

  func cleanupExpiredTimers() {
    for timer in timers {
      if timer.endDate < Date.now {
        logger.info("⏰ Timer \(timer.id) has expired, removing from database")
        cleanupAlarm(with: timer.id)
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

private nonisolated let logger = Logger(
  subsystem: "com.develiott.Recipes", category: "TimerManager")
