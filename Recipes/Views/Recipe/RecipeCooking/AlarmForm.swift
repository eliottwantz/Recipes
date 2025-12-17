//
//  AlarmForm.swift
//  Recipes
//
//  Created by Eliott on 17-12-2025.
//

import AlarmKit

struct AlarmForm {
  var label = ""
  var hour = 0
  var min = 15
  var sec = 0

  var interval: TimeInterval {
    TimeInterval(hour * 60 * 60 + min * 60 + sec)
  }

  var countdownDuration: Alarm.CountdownDuration {
    .init(preAlert: interval, postAlert: nil)
  }
  
  var localizedLabel: LocalizedStringResource {
      label.isEmpty ? LocalizedStringResource("Alarm") : LocalizedStringResource(stringLiteral: label)
  }
}
