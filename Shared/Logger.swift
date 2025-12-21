//
//  Logger.swift
//  Recipes
//
//  Created by Eliott on 21-12-2025.
//

import os

extension Logger {
  nonisolated static let storage = Logger(subsystem: "com.develiott.Recipes", category: "Storage")
  nonisolated static let ui = Logger(subsystem: "com.develiott.Recipes", category: "UI")
}
