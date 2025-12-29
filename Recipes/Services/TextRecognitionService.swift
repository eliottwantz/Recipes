//
//  TextRecognitionService.swift
//  Recipes
//
//  Created by Eliott on 2025-12-28.
//

import UIKit
import Vision

struct TextRecognitionService {
  enum RecognitionError: LocalizedError {
    case imageCreationFailed
    case noTextFound
    case recognitionFailed(Error)

    var errorDescription: String? {
      switch self {
      case .imageCreationFailed:
        return "Failed to process the image."
      case .noTextFound:
        return "No text found in the image."
      case .recognitionFailed(let error):
        return "Text recognition failed: \(error.localizedDescription)"
      }
    }
  }

 nonisolated func recognizeText(from imageData: Data) async throws -> String {
    guard let image = UIImage(data: imageData),
      let cgImage = image.cgImage
    else {
      throw RecognitionError.imageCreationFailed
    }

    return try await withCheckedThrowingContinuation { continuation in
      let request = VNRecognizeTextRequest { request, error in
        if let error {
          continuation.resume(throwing: RecognitionError.recognitionFailed(error))
          return
        }

        guard let observations = request.results as? [VNRecognizedTextObservation] else {
          continuation.resume(throwing: RecognitionError.noTextFound)
          return
        }

        let text =
          observations
          .compactMap { $0.topCandidates(1).first?.string }
          .joined(separator: "\n")

        if text.isEmpty {
          continuation.resume(throwing: RecognitionError.noTextFound)
        } else {
          continuation.resume(returning: text)
        }
      }

      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true

      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      do {
        try handler.perform([request])
      } catch {
        continuation.resume(throwing: RecognitionError.recognitionFailed(error))
      }
    }
  }
}
