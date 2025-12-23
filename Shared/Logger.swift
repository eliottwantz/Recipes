//
//  Logger.swift
//  Recipes
//
//  Created by Eliott on 21-12-2025.
//

import os

extension Logger {
  nonisolated static let ui = Logger(subsystem: Constants.bundleID, category: "UI")
}
