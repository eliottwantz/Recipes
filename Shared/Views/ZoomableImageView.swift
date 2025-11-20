//
//  ZoomableImageView.swift
//  SwiftExplorations
//
//  Image view with zoom capabilities via native UIScrollView
//

import SwiftUI

#if os(iOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

struct ZoomableImageView: View {
  let imageData: Data

  var body: some View {
    #if os(iOS)
      if let uiImage = UIImage(data: imageData) {
        ZoomableScrollView(image: uiImage)
          .ignoresSafeArea()
      } else {
        fallbackView
      }
    #elseif os(macOS)
      if let nsImage = NSImage(data: imageData) {
        Image(nsImage: nsImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
      } else {
        fallbackView
      }
    #endif
  }

  private var fallbackView: some View {
    Color.gray.opacity(0.3)
      .overlay(
        Image(systemName: "photo")
          .foregroundStyle(.secondary)
      )
  }
}

#if os(iOS)
  struct ZoomableScrollView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> ImageScrollView {
      let scrollView = ImageScrollView()
      scrollView.display(image: image)
      return scrollView
    }

    func updateUIView(_ uiView: ImageScrollView, context: Context) {
      if uiView.imageZoomView?.image != image {
        uiView.display(image: image)
      }
    }
  }

  class ImageScrollView: UIScrollView, UIScrollViewDelegate {
    var imageZoomView: UIImageView?
    var needsInitialZoom = false

    override init(frame: CGRect) {
      super.init(frame: frame)
      delegate = self
      showsVerticalScrollIndicator = false
      showsHorizontalScrollIndicator = false
      bouncesZoom = true
      backgroundColor = .clear
      contentInsetAdjustmentBehavior = .never
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func display(image: UIImage) {
      // Clear existing image view
      imageZoomView?.removeFromSuperview()
      imageZoomView = nil

      // Reset zoom scale
      zoomScale = 1.0

      // Create new image view
      let imageView = UIImageView(image: image)
      imageView.contentMode = .scaleAspectFit
      // Explicitly set frame to image size
      imageView.frame = CGRect(origin: .zero, size: image.size)
      addSubview(imageView)
      imageZoomView = imageView

      configureFor(imageSize: image.size)
      needsInitialZoom = true
    }

    func configureFor(imageSize: CGSize) {
      contentSize = imageSize
      setMaxMinZoomScalesForCurrentBounds()
      zoomScale = minimumZoomScale

      // Add double tap gesture if not already added
      if gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer }) == nil {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
      }
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      setMaxMinZoomScalesForCurrentBounds()

      if needsInitialZoom && bounds.width > 0 && bounds.height > 0 {
        zoomScale = minimumZoomScale
        needsInitialZoom = false
      }

      centerImage()
    }

    func setMaxMinZoomScalesForCurrentBounds() {
      guard let imageZoomView = imageZoomView else { return }

      let boundsSize = bounds.size
      let imageSize = imageZoomView.bounds.size

      guard boundsSize.width > 0, boundsSize.height > 0, imageSize.width > 0, imageSize.height > 0
      else { return }

      let xScale = boundsSize.width / imageSize.width
      let yScale = boundsSize.height / imageSize.height
      let minScale = min(xScale, yScale)

      var maxScale: CGFloat = 2.0
      if minScale < 0.1 {
        maxScale = 0.5
      }
      if minScale >= 0.1 && minScale < 0.5 {
        maxScale = 2.0
      }
      if minScale >= 0.5 {
        maxScale = max(2.0, minScale * 2)
      }

      minimumZoomScale = minScale
      maximumZoomScale = maxScale

      // If the current zoom scale is less than the new min scale (e.g. rotation), fix it
      if zoomScale < minimumZoomScale {
        zoomScale = minimumZoomScale
      }
    }

    func centerImage() {
      guard let imageZoomView = imageZoomView else { return }

      let boundsSize = bounds.size
      var frameToCenter = imageZoomView.frame

      if frameToCenter.size.width < boundsSize.width {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
      } else {
        frameToCenter.origin.x = 0
      }

      if frameToCenter.size.height < boundsSize.height {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
      } else {
        frameToCenter.origin.y = 0
      }

      imageZoomView.frame = frameToCenter
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
      return imageZoomView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
      centerImage()
    }

    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
      if zoomScale > minimumZoomScale {
        setZoomScale(minimumZoomScale, animated: true)
      } else {
        // Zoom in to tap location
        let point = gesture.location(in: imageZoomView)
        let scrollSize = bounds.size
        let size = CGSize(
          width: scrollSize.width / maximumZoomScale,
          height: scrollSize.height / maximumZoomScale
        )
        let origin = CGPoint(
          x: point.x - size.width / 2,
          y: point.y - size.height / 2
        )
        zoom(to: CGRect(origin: origin, size: size), animated: true)
      }
    }
  }
#endif
