//
//  CameraView.swift
//  Recipes
//
//  Created by Eliott on 2025-12-28.
//

import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
  let onCapture: (Data?) -> Void

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(onCapture: onCapture)
  }

  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let onCapture: (Data?) -> Void

    init(onCapture: @escaping (Data?) -> Void) {
      self.onCapture = onCapture
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      let image = info[.originalImage] as? UIImage
      let data = image?.jpegData(compressionQuality: 0.8)
      onCapture(data)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      onCapture(nil)
    }
  }
}
