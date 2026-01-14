//
//  Constants.swift
//  Recipes
//
//  Created by Eliott on 22-12-2025.
//

import Foundation

nonisolated enum Constants {
  static let appGroupID = "group.com.develiott.Recipes"
  static let bundleID = "com.develiott.Recipes"
  static let urlScheme = "com.develiott.recipes"

  static var videoRecipeAPIURL: URL? {
    guard let urlString = Bundle.main.infoDictionary?["VIDEO_RECIPE_API_URL"] as? String,
          !urlString.isEmpty else {
      return nil
    }
    return URL(string: urlString)
  }
}
