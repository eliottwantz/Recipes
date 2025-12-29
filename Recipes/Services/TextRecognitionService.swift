//
//  TextRecognitionService.swift
//  Recipes
//
//  Created by Eliott on 2025-12-28.
//

import UIKit
import Vision

struct TextRecognitionService {
  nonisolated static let recognitionLanguages = [
    Locale.Language(languageCode: .english),
    Locale.Language(languageCode: .french),
  ]

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
    var request = RecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = Self.recognitionLanguages
    #if DEBUG
      print("Recognizing text with languages: \(request.recognitionLanguages)")
    #endif

    do {
      let results = try await request.perform(on: imageData)
      let text =
        results
        .compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n")
      if text.isEmpty {
        throw RecognitionError.noTextFound
      }
      return text
    } catch {
      throw RecognitionError.recognitionFailed(error)
    }
  }
}
