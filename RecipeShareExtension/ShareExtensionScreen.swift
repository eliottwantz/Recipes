//
//  ShareReviewView.swift
//  RecipeShareExtension
//
//  Created by Eliott on 2025-10-25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ShareExtensionScreen: View {
  let context: NSExtensionContext

  enum Phase: Equatable {
    case importing
    case imported(RecipeDetails)
    case error(String)
  }
  @State private var phase: Phase = .importing

  private var importManager = RecipeImportManager()

  init(context: NSExtensionContext) {
    self.context = context
  }

  var body: some View {
    switch phase {
    case .importing:
      VStack {
        Text("Importing...")
        ProgressView()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onAppear {
        loadInitialShare(from: context)
      }
    case .imported(let extractedRecipeDetail):
      RecipeImportScreen(recipeDetails: extractedRecipeDetail) {
        context.completeRequest(returningItems: nil)
      }
    case .error(let message):
      NavigationStack {
        ContentUnavailableView(
          "Import Failed",
          systemImage: "exclamationmark.circle.fill",
          description: Text(message)
        )
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", systemImage: "xmark") {
              cancel()
            }
          }
        }
      }
    }
  }

  private func loadInitialShare(from context: NSExtensionContext) {
    guard phase == .importing else { return }
    Task { await loadSharedContent(from: context) }
  }

  private func loadSharedContent(from context: NSExtensionContext) async {
    do {
      let payload = try await resolveHTMLPayload(from: context)
      let imported = try await importManager.extractRecipe(
        from: payload.html,
        sourceURL: payload.sourceURL
      )
      phase = .imported(imported)
    } catch {
      phase = .error(error.localizedDescription)
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

  private func cancel() {
    let error = NSError(
      domain: NSCocoaErrorDomain,
      code: CocoaError.userCancelled.rawValue,
      userInfo: nil
    )
    context.cancelRequest(withError: error)
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
