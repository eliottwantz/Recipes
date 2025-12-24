//
//  TimerIntents.swift
//  Recipes
//
//  Created by Eliott on 21-12-2025.
//

import AlarmKit
import AppIntents
import Foundation

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

    var urlString = "\(Constants.urlScheme)://recipe/\(recipeID)"
    if let step = instructionStep {
      urlString += "?step=\(step)"
    }

    guard let url = URL(string: urlString) else {
      return .result()
    }

    return .result(opensIntent: OpenURLIntent(url))
  }

  static let title: LocalizedStringResource = "Open App"
  static let description = IntentDescription("Opens the app")
  static let supportedModes: IntentModes = [.foreground(.immediate)]
  static let isDiscoverable = false

  @Parameter(title: "alarmID")
  var alarmID: String

  @Parameter(title: "recipeID")
  var recipeID: String

  @Parameter(title: "instructionStep")
  var instructionStep: Int?

  init(alarmID: String, recipeID: String, instructionStep: Int? = nil) {
    self.alarmID = alarmID
    self.recipeID = recipeID
    self.instructionStep = instructionStep
  }

  init() {
    self.alarmID = ""
    self.recipeID = ""
    self.instructionStep = nil
  }
}
