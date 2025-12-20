//
//  AlarmForm.swift
//  Recipes
//
//  Created by Eliott on 17-12-2025.
//

import AlarmKit

struct AlarmForm {
  var recipeName: String
  var instructionStep: Int?

  var hour = 0
  var min = 0
  var sec = 0

  var imageData: Data?

  var interval: TimeInterval {
    TimeInterval(hour * 60 * 60 + min * 60 + sec)
  }

  var countdownDuration: Alarm.CountdownDuration {
    .init(preAlert: interval, postAlert: nil)
  }
}
