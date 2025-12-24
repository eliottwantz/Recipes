//
//  TimerIntents.swift
//  Recipes
//
//  Created by Eliott on 21-12-2025.
//

import AlarmKit
import AppIntents
import Foundation
import SwiftUI

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
  @MainActor
  func perform() async throws -> some IntentResult & OpensIntent {
    try AlarmManager.shared.stop(id: UUID(uuidString: alarmID)!)
    AppRouter.shared.handleDeepLink(URL(string: deepLink)!)
    return .result()
  }

  static let title: LocalizedStringResource = "Open App"
  static let description = IntentDescription("Opens the app")
  static let supportedModes: IntentModes = [.foreground(.immediate)]
  static let isDiscoverable = false

  @Parameter(title: "alarmID")
  var alarmID: String

  @Parameter(title: "deepLink")
  var deepLink: String

  init(alarmID: String, deepLink: String) {
    self.alarmID = alarmID
    self.deepLink = deepLink
  }

  init() {
    self.alarmID = ""
    self.deepLink = ""
  }
}
