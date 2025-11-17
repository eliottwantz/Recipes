//
//  ImageCarouselViewer.swift
//  SwiftExplorations
//
//  Full-screen image carousel viewer with zoom, TabView navigation, and drag-to-dismiss
//

import SwiftUI

enum DragDirection {
  case vertical, horizontal
}

struct ImageCarouselViewer: View {
  let images: [CarouselImage]
  let initialIndex: Int
  @Binding var isPresented: Bool

  @State private var currentIndex: Int
  @State private var dismissOffset: CGFloat = 0
  @State private var dragOffsetY: CGFloat = 0
  @State private var backgroundOpacity: Double = 1.0
  @State private var isImageZoomed: Bool = false
  @State private var initialDragDirection: DragDirection? = nil
  @State private var scrollPosition: Int? = nil
  @State private var hasDraggedUp: Bool = false

  // Constants
  private let dismissThreshold: CGFloat = 150

  init(images: [CarouselImage], initialIndex: Int, isPresented: Binding<Bool>) {
    self.images = images
    self.initialIndex = initialIndex
    self._isPresented = isPresented
    self._currentIndex = State(initialValue: initialIndex)
    self._scrollPosition = State(initialValue: initialIndex)
  }

  var body: some View {
    ZStack {
      GeometryReader { geometry in
        // Dark background
        Color.black
//          .opacity(backgroundOpacity)
          .ignoresSafeArea()

        imageCarousel(geometry: geometry)
          .offset(y: dismissOffset + dragOffsetY)
          .simultaneousGesture(
            DragGesture()
              .onChanged { value in
                guard !isImageZoomed else { return }

                if initialDragDirection == nil {
                  if abs(value.translation.height) > abs(value.translation.width) {
                    initialDragDirection = .vertical
                    hasDraggedUp = false
                  } else {
                    initialDragDirection = .horizontal
                  }
                }
                if initialDragDirection == .vertical {
                  if value.translation.height < dragOffsetY {
                    hasDraggedUp = true
                  }

                  // Update background opacity during drag
                  if value.translation.height > 0 {
                    dragOffsetY = value.translation.height
//                    let progress = min(value.translation.height / (geometry.size.height / 2), 1.0)
//                    backgroundOpacity = 1.0 - (progress * 0.5)
                  } else {
//                    backgroundOpacity = 1.0
                  }
                }
              }
              .onEnded { value in
                if initialDragDirection == .vertical {
                  handleDismissEnd(value: value)
                }
                initialDragDirection = nil
              }
          )
      }
    }
    .ignoresSafeArea()
  }

  // MARK: - Components

  private func imageCarousel(geometry: GeometryProxy) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 0) {
        ForEach(images.indices, id: \.self) { index in
          ZoomableImageView(
            carouselImage: images[index],
            imageIndex: index,
            isZoomed: $isImageZoomed
          )
          .frame(width: geometry.size.width, height: geometry.size.height)
          .id(index)
        }
      }
    }
    .scrollTargetBehavior(.paging)
    .scrollDisabled(initialDragDirection == .vertical)
    .scrollPosition(id: $scrollPosition)
    .onChange(of: scrollPosition) { _, new in
      if let new {
        currentIndex = new
        isImageZoomed = false
      }
    }
    .onChange(of: currentIndex) { _, new in
      scrollPosition = new
      isImageZoomed = false
    }
  }

  // MARK: - Gesture Handling

  private func handleDismissEnd(value: DragGesture.Value) {
    if !hasDraggedUp && value.translation.height > 20 {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
        dismissOffset = 1000
        backgroundOpacity = 0
      }

      Task {
        try await Task.sleep(for: .milliseconds(200))
        dismiss()
      }
    } else {
      // Return to original position
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        dismissOffset = 0
        dragOffsetY = 0
        backgroundOpacity = 1.0
      }
    }
    hasDraggedUp = false
  }

  // MARK: - Actions

  private func dismiss() {
    backgroundOpacity = 0
    isPresented = false
  }
}
