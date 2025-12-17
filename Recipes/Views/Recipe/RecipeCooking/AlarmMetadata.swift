//
//  AlarmMetadata.swift
//  Recipes
//
//  Created by Eliott on 17-12-2025.
//

import AlarmKit
import AppIntents
import Foundation

nonisolated struct CookingAlarmMetadata: AlarmMetadata {
  var recipeName: String
  var alarmID: UUID
}

struct CancelTimerIntent: LiveActivityIntent {
  func perform() throws -> some IntentResult {
    try AlarmManager.shared.cancel(id: UUID(uuidString: alarmID)!)
    return .result()
  }

  static let title: LocalizedStringResource = "Cancel"
  static let description = IntentDescription("Cancel the timer")
  static let isDiscoverable = false

  @Parameter(title: "alarmID")
  var alarmID: String

  init(alarmID: String) {
    self.alarmID = alarmID
  }

  init() {
    self.alarmID = ""
  }
}

struct OpenAppIntent: LiveActivityIntent {
  func perform() throws -> some IntentResult {
    try AlarmManager.shared.stop(id: UUID(uuidString: alarmID)!)
    return .result()
  }

  static let title: LocalizedStringResource = "Open App"
  static let description = IntentDescription("Opens the app")
  static let openAppWhenRun = true
  static let isDiscoverable = false

  @Parameter(title: "alarmID")
  var alarmID: String

  init(alarmID: String) {
    self.alarmID = alarmID
  }

  init() {
    self.alarmID = ""
  }
}
