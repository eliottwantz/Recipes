//
//  FaceTrackingManager.swift
//  Recipes
//
//  Created by Eliott on 28-12-2025.
//

import ARKit
import Combine
import SwiftUI

/// Manages face tracking for hands-free gesture recognition using ARKit.
/// Detects left and right eye winks to trigger navigation actions.
@Observable
final class FaceTrackingManager: NSObject {
  enum WinkEvent {
    case leftEyeWink
    case rightEyeWink
  }

  /// Whether the device supports face tracking (requires TrueDepth camera)
  static let isSupported: Bool = ARFaceTrackingConfiguration.isSupported

  /// Whether face tracking is currently active
  private(set) var isTracking = false

  /// Publisher for wink events
  let winkEventSubject = PassthroughSubject<WinkEvent, Never>()

  private var session: ARSession?

  // Thresholds for wink detection
  private let winkThreshold: Float = 0.7  // Eye must be at least this closed
  private let openThreshold: Float = 0.3  // Other eye must be at least this open
  private let debounceInterval: TimeInterval = 0.5  // Minimum time between winks

  private var lastWinkTime: Date = .distantPast

  override init() {
    super.init()
  }

  /// Starts face tracking session
  func startTracking() {
    guard Self.isSupported else {
      print("⚠️ Face tracking not supported on this device")
      return
    }

    guard !isTracking else { return }

    let session = ARSession()
    session.delegate = self
    self.session = session

    let configuration = ARFaceTrackingConfiguration()
    configuration.isLightEstimationEnabled = false  // We don't need lighting
    session.run(configuration, options: [.resetTracking])

    isTracking = true
    print("👁️ Face tracking started")
  }

  /// Stops face tracking session
  func stopTracking() {
    guard isTracking else { return }

    session?.pause()
    session = nil
    isTracking = false
    print("👁️ Face tracking stopped")
  }
}

// MARK: - ARSessionDelegate
extension FaceTrackingManager: ARSessionDelegate {
  nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
      return
    }

    let blendShapes = faceAnchor.blendShapes

    guard
      let leftEyeBlink = blendShapes[.eyeBlinkLeft]?.floatValue,
      let rightEyeBlink = blendShapes[.eyeBlinkRight]?.floatValue
    else {
      return
    }

    Task { @MainActor in
      self.detectWink(leftEyeBlink: leftEyeBlink, rightEyeBlink: rightEyeBlink)
    }
  }

  nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
    print("❌ ARSession failed: \(error.localizedDescription)")
    Task { @MainActor in
      self.stopTracking()
    }
  }
}

// MARK: - Wink Detection Logic
extension FaceTrackingManager {
  private func detectWink(leftEyeBlink: Float, rightEyeBlink: Float) {
    let now = Date()

    // Debounce: ignore winks too close together
    guard now.timeIntervalSince(lastWinkTime) >= debounceInterval else {
      return
    }

    // Detect right eye wink from user's perspective
    // (ARKit's left eye = user's right eye due to front camera mirror)
    if leftEyeBlink >= winkThreshold && rightEyeBlink <= openThreshold {
      lastWinkTime = now
      winkEventSubject.send(.rightEyeWink)
      #if DEBUG
        print("👁️ Right eye wink detected")
      #endif
      return
    }

    // Detect left eye wink from user's perspective
    // (ARKit's right eye = user's left eye due to front camera mirror)
    if rightEyeBlink >= winkThreshold && leftEyeBlink <= openThreshold {
      lastWinkTime = now
      winkEventSubject.send(.leftEyeWink)
      #if DEBUG
        print("👁️ Left eye wink detected")
      #endif
      return
    }
  }
}
