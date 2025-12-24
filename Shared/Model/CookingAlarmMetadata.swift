//
//  CookingAlarmMetadata.swift
//  Recipes
//
//  Created by Eliott on 17-12-2025.
//

import AlarmKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import os

nonisolated struct CookingAlarmMetadata: AlarmMetadata {
  let alarmID: UUID
  let recipeID: UUID
  let recipeName: String
  let instructionStep: Int?

  var deepLink: URL {
    var urlString = "\(Constants.urlScheme)://recipe/\(recipeID)"
    if let step = instructionStep {
      urlString += "?step=\(step)"
    }
    return URL(string: urlString)!
  }
}
