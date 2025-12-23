//
//  ImageManager.swift
//  Recipes
//
//  Created by Eliott on 21-12-2025.
//

import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import os

nonisolated enum ImageManager {
  private static let appGroupIdentifier = "group.com.develiott.Recipes"

  static var sharedContainerURL: URL? {
    FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupIdentifier
    )
  }

  // Save image with automatic resizing for Live Activities
  @discardableResult
  static func saveImageForLiveActivity(
    _ data: Data?,
    for liveActivityID: UUID,
  ) -> URL? {
    guard let data else { return nil }

    guard let containerURL = Self.sharedContainerURL else {
      return nil
    }

    guard let image = UIImage(data: data) else { return nil }
    // Resize image to target size (2x for retina displays)
    let targetSize = CGSize(width: 62, height: 62)
    guard let resizedImage = Self.resizeImage(image, targetSize: targetSize),
      let imageData = resizedImage.jpegData(compressionQuality: 0.8)
    else {
      return nil
    }

    let imageURL = containerURL.appendingPathComponent(
      liveActivityID.uuidString, conformingTo: .jpeg)

    do {
      try imageData.write(to: imageURL, options: .atomic)
      return imageURL
    } catch {
      logger.error("Error saving image: \(error)")
      return nil
    }
  }

  // Load image from shared container
  static func loadLiveActivityImage(for liveActivityID: UUID) -> Image? {
    guard let containerURL = Self.sharedContainerURL else {
      return nil
    }

    let imageURL = containerURL.appendingPathComponent(
      liveActivityID.uuidString, conformingTo: .jpeg)

    guard let imageData = try? Data(contentsOf: imageURL), let uiImage = UIImage(data: imageData)
    else {
      return nil
    }

    return Image(uiImage: uiImage)
  }

  // Delete image when no longer needed
  static func deleteImage(for liveActivityID: UUID) {
    guard let containerURL = Self.sharedContainerURL else {
      return
    }

    let imageURL = containerURL.appendingPathComponent(
      liveActivityID.uuidString, conformingTo: .jpeg)
    try? FileManager.default.removeItem(at: imageURL)
  }

  private static func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
    let size = image.size

    let widthRatio = targetSize.width / size.width
    let heightRatio = targetSize.height / size.height

    // Use the larger ratio to ensure the image fills the entire target size
    let scaleFactor = max(widthRatio, heightRatio)
    guard scaleFactor < 1 else { return image }

    let scaledSize = CGSize(
      width: size.width * scaleFactor,
      height: size.height * scaleFactor
    )

    // Calculate centered crop rect
    let xOffset = (scaledSize.width - targetSize.width) / 2.0
    let yOffset = (scaledSize.height - targetSize.height) / 2.0

    let renderer = UIGraphicsImageRenderer(size: targetSize)
    let resizedImage = renderer.image { _ in
      image.draw(
        in: CGRect(
          x: -xOffset,
          y: -yOffset,
          width: scaledSize.width,
          height: scaledSize.height
        ))
    }

    return resizedImage
  }

}

//private extension Logger {
nonisolated private let logger = Logger(
  subsystem: "com.develiott.Recipes",
  category: "SharedImageManager"
)
//}
