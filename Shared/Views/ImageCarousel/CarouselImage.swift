//
//  CarouselImage.swift
//  SwiftExplorations
//
//  Platform-agnostic image model for carousel viewer
//  Supports loading images from Data (e.g., SQLite) on both iOS and macOS
//

import SwiftUI

#if os(iOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

struct CarouselImage: Identifiable {
  let id: UUID
  let data: Data

  init(id: UUID = UUID(), data: Data) {
    self.id = id
    self.data = data
  }

  // MARK: - Platform-Specific Image

  #if os(iOS)
    /// Returns UIImage from data (iOS)
    var platformImage: UIImage? {
      UIImage(data: data)
    }
  #elseif os(macOS)
    /// Returns NSImage from data (macOS)
    var platformImage: NSImage? {
      NSImage(data: data)
    }
  #endif

  // MARK: - Image Properties

  /// Returns the size of the image
  var size: CGSize {
    #if os(iOS)
      return platformImage?.size ?? .zero
    #elseif os(macOS)
      return platformImage?.size ?? .zero
    #else
      return .zero
    #endif
  }

  /// Returns the aspect ratio (width / height)
  var aspectRatio: CGFloat {
    let size = self.size
    guard size.height > 0 else { return 1.0 }
    return size.width / size.height
  }

  /// Creates a SwiftUI Image from the data
  var image: Image? {
    #if os(iOS)
      guard let uiImage = platformImage else { return nil }
      return Image(uiImage: uiImage)
    #elseif os(macOS)
      guard let nsImage = platformImage else { return nil }
      return Image(nsImage: nsImage)
    #else
      return nil
    #endif
  }
}

// MARK: - Convenience Initializers

extension CarouselImage {
  /// Creates a CarouselImage from an asset name (for testing/demo purposes)
  static func fromAsset(_ name: String, id: UUID = UUID()) -> CarouselImage? {
    #if os(iOS)
      guard let uiImage = UIImage(named: name),
        let data = uiImage.pngData()
      else {
        return nil
      }
      return CarouselImage(id: id, data: data)
    #elseif os(macOS)
      guard let nsImage = NSImage(named: name),
        let tiffData = nsImage.tiffRepresentation,
        let bitmapImage = NSBitmapImageRep(data: tiffData),
        let data = bitmapImage.representation(using: .png, properties: [:])
      else {
        return nil
      }
      return CarouselImage(id: id, data: data)
    #else
      return nil
    #endif
  }
}
