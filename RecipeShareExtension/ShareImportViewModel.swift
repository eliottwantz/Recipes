//
//  ShareImportViewModel.swift
//  RecipeShareExtension
//
//  Created by Eliott on 2025-10-25.
//

import Combine
import Dependencies
import Foundation
import RecipeImportFeature
import UIKit
import UniformTypeIdentifiers

@MainActor
final class ShareImportViewModel: ObservableObject {
  enum Phase: Equatable {
    case idle
    case loading
    case loaded(RecipeDraft)
    case failed(ShareError)
  }

  struct ShareError: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let isRetryable: Bool
  }

  @Published private(set) var phase: Phase = .idle
  @Published var draft: RecipeDraft?

  @Dependency(\.urlSession) private var urlSession

  private let pipeline: RecipeImportPipeline
  private var hasAttemptedInitialLoad = false

  init(pipeline: RecipeImportPipeline = RecipeImportPipeline()) {
    self.pipeline = pipeline
  }

  func loadInitialShare(from context: NSExtensionContext) {
    guard hasAttemptedInitialLoad == false else { return }
    hasAttemptedInitialLoad = true
    Task { @MainActor in
      await loadSharedURL(from: context)
    }
  }

  func retry(from context: NSExtensionContext) {
    Task { @MainActor in
      await loadSharedURL(from: context)
    }
  }

  private func loadSharedURL(from context: NSExtensionContext) async {
    phase = .loading

    do {
      let url = try await resolveURL(from: context)
      let imported = try await pipeline.importedRecipe(from: url, session: urlSession)
      let draft = RecipeDraft(imported: imported)
      self.draft = draft
      phase = .loaded(draft)
    } catch {
      draft = nil
      let shareError = shareError(for: error)
      phase = .failed(shareError)
    }
  }

  private func resolveURL(from context: NSExtensionContext) async throws -> URL {
    let items = context.inputItems.compactMap { $0 as? NSExtensionItem }

    for item in items {
      guard let providers = item.attachments else { continue }
      for provider in providers {
        if let url = try await extractURL(from: provider),
          url.scheme?.lowercased().hasPrefix("http") == true
        {
          return url
        }
      }
    }

    throw ShareImportFailure.missingURL
  }

  private func extractURL(from provider: NSItemProvider) async throws -> URL? {
    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
      let item = try await loadItem(forTypeIdentifier: UTType.url.identifier, from: provider)
      if let url = item as? URL {
        return url
      }
      if let url = item as? NSURL {
        return url as URL
      }
      if let data = item as? Data, let string = String(data: data, encoding: .utf8),
        let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines))
      {
        return url
      }
      if let string = item as? String,
        let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines))
      {
        return url
      }
    }

    if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
      let item = try await loadItem(forTypeIdentifier: UTType.plainText.identifier, from: provider)
      if let string = item as? String,
        let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines))
      {
        return url
      }
    }

    return nil
  }

  private func loadItem(
    forTypeIdentifier typeIdentifier: String,
    from provider: NSItemProvider
  ) async throws -> Any {
    try await withCheckedThrowingContinuation { continuation in
      provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
        if let error {
          continuation.resume(throwing: ShareImportFailure.itemProvider(error))
        } else if let item {
          continuation.resume(returning: item)
        } else {
          continuation.resume(throwing: ShareImportFailure.emptyPayload)
        }
      }
    }
  }

  private func shareError(for error: Error) -> ShareError {
    if let failure = error as? ShareImportFailure {
      return ShareError(
        message: failure.errorDescription ?? "Failed to load the shared URL.",
        isRetryable: failure.isRetryable
      )
    }

    if let localized = error as? LocalizedError, let description = localized.errorDescription {
      return ShareError(message: description, isRetryable: true)
    }

    return ShareError(
      message: "Something went wrong while importing the recipe.",
      isRetryable: true
    )
  }
}

private enum ShareImportFailure: LocalizedError {
  case missingURL
  case emptyPayload
  case itemProvider(Error)

  var errorDescription: String? {
    switch self {
    case .missingURL:
      return "No shareable URL was found in the selected items."
    case .emptyPayload:
      return "The shared item did not include any data."
    case .itemProvider(let error):
      if let localized = error as? LocalizedError,
        let description = localized.errorDescription
      {
        return description
      }
      return "Failed to load the shared URL."
    }
  }

  var isRetryable: Bool {
    switch self {
    case .missingURL:
      return false
    case .emptyPayload, .itemProvider:
      return true
    }
  }
}
