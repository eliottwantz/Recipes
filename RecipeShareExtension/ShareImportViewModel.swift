//
//  ShareImportViewModel.swift
//  RecipeShareExtension
//
//  Created by Eliott on 2025-10-25.
//

import Foundation
import SQLiteData
import UniformTypeIdentifiers

@MainActor
@Observable
final class ShareImportViewModel {
  enum Phase {
    case idle
    case loading
    case loaded
    case failed(ShareError)
  }

  struct ShareError: Identifiable, Equatable {
    let id = UUID()
    let message: String
  }

  private(set) var phase: Phase = .idle
  var draft: RecipeImportManager.ExtractedRecipeDetail? = nil
  var isSaving = false
  var saveError: ShareError?

  @ObservationIgnored @Dependency(\.defaultDatabase) private var database
  @ObservationIgnored @Dependency(\.date.now) private var now

  private var hasAttemptedInitialLoad = false

  func loadInitialShare(from context: NSExtensionContext) {
    guard hasAttemptedInitialLoad == false else { return }
    hasAttemptedInitialLoad = true
    Task { await loadSharedContent(from: context) }
  }

  func cancel(context: NSExtensionContext) {
    let error = NSError(
      domain: NSCocoaErrorDomain,
      code: CocoaError.userCancelled.rawValue,
      userInfo: nil
    )
    context.cancelRequest(withError: error)
  }

  func saveCurrentDraft(in context: NSExtensionContext) {
    guard case .loaded = phase, isSaving == false else { return }
    isSaving = true
    saveError = nil

    guard let draft else { return }
    let currentDraft = draft.normalized()
    let timestamp = now

    do {
      try persistDraft(currentDraft, timestamp: timestamp)
      isSaving = false
      context.completeRequest(returningItems: [], completionHandler: nil)
    } catch {
      let shareError = shareError(for: error)
      isSaving = false
      saveError = shareError
    }
  }

  private func loadSharedContent(from context: NSExtensionContext) async {
    phase = .loading
    saveError = nil

    do {
      let payload = try await resolveHTMLPayload(from: context)
      let imported = try await RecipeImportManager.extractRecipe(from: payload.html)
      draft = imported
      phase = .loaded
    } catch {
      draft = nil
      let shareError = shareError(for: error)
      phase = .failed(shareError)
    }
  }

  private func resolveHTMLPayload(from context: NSExtensionContext) async throws -> HTMLPayload {
    let items = context.inputItems.compactMap { $0 as? NSExtensionItem }

    for item in items {
      guard let attachments = item.attachments else { continue }
      for provider in attachments {
        if let payload = try await htmlFromItemProvider(provider) {
          return payload
        }
      }
    }

    throw ShareImportFailure.missingHTML
  }

  private func htmlFromItemProvider(_ provider: NSItemProvider) async throws -> HTMLPayload? {
    if provider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
      let item = try await loadItem(
        forTypeIdentifier: UTType.propertyList.identifier, from: provider)
      if let payload = HTMLPayload(item: item) {
        return payload
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

  private func persistDraft(_ draft: RecipeImportManager.ExtractedRecipeDetail, timestamp: Date)
    throws
  {
    guard draft.recipe.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
      throw ShareImportFailure.missingTitle
    }

    try RecipeImportManager.persist(draft, in: database)
  }

  private func shareError(for error: Error) -> ShareError {
    if let failure = error as? ShareImportFailure {
      return ShareError(message: failure.errorDescription)
    }

    if let localized = error as? LocalizedError, let description = localized.errorDescription {
      return ShareError(message: description)
    }

    return ShareError(
      message: "Something went wrong while importing the recipe.",
    )
  }
}

private struct HTMLPayload: Equatable {
  let html: String
  let sourceURL: URL?

  private init(html: String, sourceURL: URL?) {
    self.html = html
    self.sourceURL = sourceURL
  }

  init?(item: Any) {
    if let results = item as? NSDictionary,
      let jsResults = results[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any]
    {

      guard let html = jsResults["html"] as? String

      else {
        print("❌ No 'html' key found in JS results")
        return nil
      }
      print("✅ Extracted HTML (first 200 chars):")
      print(html.prefix(200))

      guard let url = jsResults["url"] as? String else {
        print("No 'url' key found in JS results")
        self.init(html: html, sourceURL: nil)
        return

      }
      print("Page URL:", url)

      self.init(html: html, sourceURL: URL(string: url))
    } else {
      print("Unexpected dictionary format:", item)
      return nil
    }
  }
}

private enum ShareImportFailure: LocalizedError {
  case missingHTML
  case emptyPayload
  case itemProvider(Error)
  case missingTitle

  var errorDescription: String {
    switch self {
    case .missingHTML:
      return
        "Please share again after the page finishes loading."
    case .emptyPayload:
      return "The shared item did not include any content."
    case .itemProvider(let error):
      if let localized = error as? LocalizedError,
        let description = localized.errorDescription
      {
        return description
      }
      return "Failed to read the shared content."
    case .missingTitle:
      return "Title is required before saving this recipe."
    }
  }

  var isRetryable: Bool {
    switch self {
    case .missingHTML:
      return false
    case .emptyPayload, .itemProvider:
      return true
    case .missingTitle:
      return false
    }
  }
}
