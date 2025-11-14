//
//  ZoomableImageView.swift
//  Recipes
//
//  Created by Eliott on 2025-11-14.
//

import SwiftUI

// Full-screen viewer overlay with close button and drag-to-dismiss
struct FullScreenImageViewer: View {
  let image: Image
  let close: () -> Void

  // Drag-to-dismiss state
  @GestureState private var dragOffset: CGSize = .zero
  @State private var backgroundOpacity: Double = 1.0

  var body: some View {
    ZStack {
      ZoomableImageView(image: image)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(.rect)
    .gesture(
      DragGesture()
        .updating($dragOffset) { value, state, _ in
          state = value.translation
          let distance = hypot(value.translation.width, value.translation.height)
          backgroundOpacity = max(0.4, 1.0 - Double(distance / 600))
          print("Update dragOffset: \(value.translation)")
        }
        .onEnded { value in
          let distance = hypot(value.translation.width, value.translation.height)
          if distance > 140 {
            withAnimation(.spring()) {
              close()
            }
          } else {
            withAnimation(.spring()) {
              backgroundOpacity = 1.0
            }
          }
        }
    )
    .transition(.opacity.combined(with: .scale))
  }
}

// A zoomable, pannable image container that clamps panning so you can't drag the image completely off screen.
private struct ZoomableImageView: View {
  @GestureState private var isInteracting: Bool = false
  @State private var scale: CGFloat = 1.0
  @State private var lastScale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var lastOffset: CGSize = .zero

  let image: Image
  let minScale: CGFloat
  let maxScale: CGFloat

  init(
    image: Image,
    minScale: CGFloat = 1.0,
    maxScale: CGFloat = 4.0
  ) {
    self.image = image
    self.minScale = minScale
    self.maxScale = maxScale
  }

  var body: some View {
    GeometryReader { geo in
      let viewSize = geo.size

      // Double-tap to zoom
      let doubleTap = TapGesture(count: 2)
        .onEnded {
          withAnimation(.spring()) {
            if scale <= minScale + 0.01 {
              scale = min(maxScale, 2.0)  // Zoom in to a nice level
            } else {
              scale = minScale
              offset = .zero
              lastOffset = .zero
            }
            lastScale = scale
          }
        }

      // Pinch to zoom
      let magnification = MagnificationGesture()
        .updating($isInteracting) { _, state, _ in
          state = true
        }
        .onChanged { value in
          let raw = lastScale * value
          let newScale = min(max(raw, minScale), maxScale)
          scale = newScale
          // Clamp offset when scale changes
          offset = clamp(offset: lastOffset, scale: newScale, containerSize: viewSize)
        }
        .onEnded { value in
          lastScale = scale
          offset = clamp(offset: offset, scale: scale, containerSize: viewSize)
          lastOffset = offset
        }

      // Pan to move
      let drag = DragGesture()
        .updating($isInteracting) { _, state, _ in
          state = true
        }
        .onChanged { gesture in
          let proposed = CGSize(
            width: lastOffset.width + gesture.translation.width,
            height: lastOffset.height + gesture.translation.height)
          offset = clamp(offset: proposed, scale: scale, containerSize: viewSize)
        }
        .onEnded { gesture in
          lastOffset = offset
        }

      image
        .resizable()
        .scaledToFit()
        .frame(width: viewSize.width, height: viewSize.height)
        .scaleEffect(scale)
        .offset(offset)
        .gesture(drag.simultaneously(with: magnification).simultaneously(with: doubleTap))
        .animation(.interactiveSpring(), value: isInteracting)
        .animation(.spring(), value: scale)
    }
    .background(Color.black.opacity(0.0001))  // enable gestures even if transparent
  }

  // Clamp offset so that the image remains visible and doesn't drift entirely off screen
  private func clamp(offset: CGSize, scale: CGFloat, containerSize: CGSize) -> CGSize {
    // The image rendered is scaledToFit inside the container.
    // Effective content size = containerSize * scale.
    let contentWidth = containerSize.width * scale
    let contentHeight = containerSize.height * scale

    // If content smaller than container, no need to pan; clamp to zero
    guard contentWidth > containerSize.width || contentHeight > containerSize.height else {
      return .zero
    }

    // Compute max allowed translation so at least an edge is visible
    let maxX = max(0, (contentWidth - containerSize.width) / 2)
    let maxY = max(0, (contentHeight - containerSize.height) / 2)

    return CGSize(
      width: max(-maxX, min(maxX, offset.width)),
      height: max(-maxY, min(maxY, offset.height))
    )
  }
}
