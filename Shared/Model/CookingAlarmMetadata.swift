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
  var recipeName: String
  var instructionStep: Int?
  var alarmID: UUID
  let recipeImageURL: URL?
}

extension CookingAlarmMetadata {
  private static let groupIdentifier = "group.com.develiott.Recipes"
  private static let recipeImageName = "cooking-liveactivity-image"

  static func persistRecipeImageDataToAppGroup(_ data: Data?) -> URL? {
    guard let data else { return nil }

    guard let image = UIImage(data: data),
      let fileData = image.jpegData(compressionQuality: 0.85)
    else { return nil }

    guard
      let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: Self.groupIdentifier)
    else { return nil }

    let fileURL = containerURL.appendingPathComponent(recipeImageName, conformingTo: .jpeg)
    do {
      try fileData.write(to: fileURL, options: .atomic)
      return fileURL
    } catch {
      Logger.storage.error("Error writing image data to app group container: \(error)")
      return nil
    }
  }

  func recipeImageFromAppGroup() -> Image? {
    guard let recipeImageURL else { return nil }

    guard FileManager.default.fileExists(atPath: recipeImageURL.path()),
      let uiImage = UIImage(contentsOfFile: recipeImageURL.path())
    else { return nil }
    return Image(uiImage: uiImage)
  }
}
