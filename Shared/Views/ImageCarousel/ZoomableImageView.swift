//
//  ZoomableImageView.swift
//  SwiftExplorations
//
//  Image view with zoom capabilities via pinch and double-tap gestures
//

import SwiftUI

#if os(iOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

struct ZoomableImageView: View {
  let carouselImage: CarouselImage
  let imageIndex: Int
  @Binding var isZoomed: Bool

  // Zoom state
  @State private var scale: CGFloat = 1.0
  @State private var lastScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var lastOffset: CGSize = .zero

  // Gesture state
  @GestureState private var magnificationGestureScale: CGFloat = 1.0
  @GestureState private var panGestureOffset: CGSize = .zero

  // Constants
  private let minScale: CGFloat = 1.0
  private let maxScale: CGFloat = 15.0

  var body: some View {
    GeometryReader { geometry in
      Group {
        if let image = carouselImage.image {
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
        } else {
          // Fallback if image cannot be loaded
          Color.gray.opacity(0.3)
        }
      }
      .scaleEffect(scale * magnificationGestureScale)
      .offset(
        x: offset.width + panGestureOffset.width,
        y: offset.height + panGestureOffset.height
      )
      .gesture(createMagnificationGesture(in: geometry))
      .simultaneousGesture(
        scale > minScale ? createDragGesture(in: geometry) : nil
      )
      .onTapGesture(count: 2) {
        handleDoubleTap(in: geometry)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  // MARK: - Gestures

  /// Creates pinch-to-zoom magnification gesture
  private func createMagnificationGesture(in geometry: GeometryProxy) -> some Gesture {
    MagnificationGesture()
      .updating($magnificationGestureScale) { value, state, _ in
        scale = value
      }
      .onEnded { value in
        // Calculate new scale within bounds
        var newScale = scale * value
        newScale = min(max(newScale, minScale), maxScale)

        // Constrain offset based on new scale to prevent image going off-screen
        let fittedImageSize = calculateFittedImageSize(in: geometry)
        let constrainedOffset = constrainOffset(
          offset: lastOffset,
          scale: newScale,
          imageSize: fittedImageSize,
          viewSize: geometry.size
        )

        // Update without animation for smooth transition
        scale = newScale
        offset = constrainedOffset
        lastOffset = constrainedOffset
        isZoomed = newScale > minScale

        // Reset offset if zoomed out to minimum
        if newScale == minScale {
          offset = .zero
          lastOffset = .zero
        }
      }
  }

  /// Creates drag gesture for panning when zoomed
  private func createDragGesture(in geometry: GeometryProxy) -> some Gesture {
    DragGesture()
      .updating($panGestureOffset) { value, state, _ in
        // Only allow panning when zoomed in
        if scale > minScale {
          // Calculate the proposed new offset
          let proposedOffset = CGSize(
            width: lastOffset.width + value.translation.width,
            height: lastOffset.height + value.translation.height
          )

          // Get the actual fitted image size
          let fittedImageSize = calculateFittedImageSize(in: geometry)

          // Constrain offset to prevent panning beyond image bounds
          let maxOffsetX = max(0, (fittedImageSize.width * scale - geometry.size.width) / 2)
          let maxOffsetY = max(0, (fittedImageSize.height * scale - geometry.size.height) / 2)

          // Apply bounds to the gesture offset (relative to lastOffset)
          let constrainedOffsetX = min(max(proposedOffset.width, -maxOffsetX), maxOffsetX)
          let constrainedOffsetY = min(max(proposedOffset.height, -maxOffsetY), maxOffsetY)

          state = CGSize(
            width: constrainedOffsetX - lastOffset.width,
            height: constrainedOffsetY - lastOffset.height
          )
        }
      }
      .onEnded { value in
        if scale > minScale {
          // Calculate new offset with bounds checking
          let newOffset = CGSize(
            width: lastOffset.width + value.translation.width,
            height: lastOffset.height + value.translation.height
          )

          // Get the actual fitted image size
          let fittedImageSize = calculateFittedImageSize(in: geometry)

          // Constrain offset to prevent image from moving too far
          let maxOffsetX = max(0, (fittedImageSize.width * scale - geometry.size.width) / 2)
          let maxOffsetY = max(0, (fittedImageSize.height * scale - geometry.size.height) / 2)

          // Update without animation for smooth transition
          offset.width = min(max(newOffset.width, -maxOffsetX), maxOffsetX)
          offset.height = min(max(newOffset.height, -maxOffsetY), maxOffsetY)
          lastOffset = offset
        }
      }
  }

  /// Handles double-tap gesture to zoom in/out
  private func handleDoubleTap(in geometry: GeometryProxy) {
    withAnimation(.easeOut(duration: 0.25)) {
      if scale > minScale {
        // Zoom out to minimum
        scale = minScale
        isZoomed = false
        offset = .zero
        lastOffset = .zero
      } else {
        // Calculate scale to fill screen height
        let targetScale = calculateHeightFillingScale(for: geometry)
        scale = min(targetScale, maxScale)
        isZoomed = true
      }
    }

  }

  // MARK: - Helper Functions

  /// Constrains offset to keep image within view bounds based on current scale
  private func constrainOffset(
    offset: CGSize,
    scale: CGFloat,
    imageSize: CGSize,
    viewSize: CGSize
  ) -> CGSize {
    // Calculate maximum allowed offset based on current scale
    let maxOffsetX = max(0, (imageSize.width * scale - viewSize.width) / 2)
    let maxOffsetY = max(0, (imageSize.height * scale - viewSize.height) / 2)

    // Constrain offset within bounds
    let constrainedX = min(max(offset.width, -maxOffsetX), maxOffsetX)
    let constrainedY = min(max(offset.height, -maxOffsetY), maxOffsetY)

    return CGSize(width: constrainedX, height: constrainedY)
  }

  /// Calculates the scale needed to fill screen height
  private func calculateHeightFillingScale(for geometry: GeometryProxy) -> CGFloat {
    let imageAspectRatio = carouselImage.aspectRatio

    // Fallback to 2x if aspect ratio is invalid
    guard imageAspectRatio > 0 else {
      return 2.0
    }

    let screenHeight = geometry.size.height
    let screenWidth = geometry.size.width

    // When using .fit aspect ratio, the image width is limited by screen width
    // Calculate the fitted image height
    let fittedImageHeight = screenWidth / imageAspectRatio

    // Calculate the scale needed to make the fitted image fill screen height
    return screenHeight / fittedImageHeight
  }

  /// Calculates the actual size of the image when fitted to the screen
  private func calculateFittedImageSize(in geometry: GeometryProxy) -> CGSize {
    let imageAspectRatio = carouselImage.aspectRatio

    // Fallback if aspect ratio is invalid
    guard imageAspectRatio > 0 else {
      return geometry.size
    }

    let screenWidth = geometry.size.width
    let screenHeight = geometry.size.height
    let screenAspectRatio = screenWidth / screenHeight

    // When using .aspectRatio(contentMode: .fit), the image is scaled to fit within bounds
    // while maintaining its aspect ratio
    if imageAspectRatio > screenAspectRatio {
      // Image is wider - width is constrained by screen width
      let fittedWidth = screenWidth
      let fittedHeight = screenWidth / imageAspectRatio
      return CGSize(width: fittedWidth, height: fittedHeight)
    } else {
      // Image is taller - height is constrained by screen height
      let fittedHeight = screenHeight
      let fittedWidth = screenHeight * imageAspectRatio
      return CGSize(width: fittedWidth, height: fittedHeight)
    }
  }
}
