//
//  PhotoRecipeImportScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-12-28.
//

import PhotosUI
import SwiftUI

struct PhotoRecipeImportScreen: View {
  enum Source {
    case photoLibrary
    case camera
  }

  let source: Source
  var onDismiss: (() -> Void)?

  @Environment(\.dismiss) private var dismiss
  @State private var phase: Phase = .selectingImage
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var showCamera = false
  @State private var importedRecipeDetails: RecipeDetails?
  @State private var showRecipeImportScreen = false

  private let importManager = PhotoRecipeImportManager()

  enum Phase: Equatable {
    case selectingImage
    case processing
  }

  var body: some View {
    NavigationStack {
      Group {
        switch phase {
        case .selectingImage:
          selectingImageView
        case .processing:
          processingView
        }
      }
      .navigationTitle("Import from Photo")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .cancel) {
            dismiss()
            onDismiss?()
          }
        }
      }
    }
    .onChange(of: selectedPhotoItem) { _, newItem in
      guard let newItem else { return }
      Task {
        await processPhotoItem(newItem)
      }
    }
    .fullScreenCover(isPresented: $showCamera) {
      CameraView { imageData in
        showCamera = false
        if let imageData {
          Task {
            await processImageData(imageData)
          }
        } else {
          // User cancelled camera
          dismiss()
          onDismiss?()
        }
      }
      .ignoresSafeArea()
    }
    .sheet(isPresented: $showRecipeImportScreen) {
      if let details = importedRecipeDetails {
        RecipeImportScreen(recipeDetails: details) {
          dismiss()
          onDismiss?()
        }
      }
    }
    .onAppear {
      if source == .camera {
        showCamera = true
      }
    }
  }

  @ViewBuilder
  private var selectingImageView: some View {
    if source == .photoLibrary {
      VStack(spacing: 24) {
        ContentUnavailableView(
          "Select a Recipe Photo",
          systemImage: "photo.on.rectangle",
          description: Text("Choose a photo of a recipe to import")
        )

        PhotosPicker(
          selection: $selectedPhotoItem,
          matching: .images
        ) {
          Label("Choose Photo", systemImage: "photo")
        }
        .buttonStyle(.borderedProminent)
      }
    } else {
      // Camera source - will show fullScreenCover
      Color.clear
    }
  }

  private var processingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .scaleEffect(1.5)
      Text("Reading recipe...")
        .font(.headline)
      Text("Extracting text and parsing ingredients")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  private func processPhotoItem(_ item: PhotosPickerItem) async {
    phase = .processing

    guard let data = try? await item.loadTransferable(type: Data.self) else {
      ToastManager.shared.show(
        icon: "xmark.circle.fill",
        title: "Failed to load image",
        tint: .red,
        duration: 3.0
      )
      dismiss()
      onDismiss?()
      return
    }

    await processImageData(data)
  }

  private func processImageData(_ data: Data) async {
    phase = .processing

    do {
      let result = try await importManager.importRecipe(from: data)

      switch result {
      case .success(let details):
        importedRecipeDetails = details
        showRecipeImportScreen = true

      case .partialSuccess(let details, _, _):
        // Show toast with warning, but still show form
        ToastManager.shared.show(
          icon: "exclamationmark.triangle.fill",
          title: "Parsing incomplete",
          subtitle: "Extracted text added to notes",
          tint: .orange,
          duration: 3.0
        )
        importedRecipeDetails = details
        showRecipeImportScreen = true
      }
    } catch let error as PhotoRecipeImportManager.ImportError {
      switch error {
      case .ocrFailed:
        // OCR failed - show toast and dismiss
        ToastManager.shared.show(
          icon: "xmark.circle.fill",
          title: "Could not read image",
          subtitle: "No text found in the photo",
          tint: .red,
          duration: 3.0
        )
        dismiss()
        onDismiss?()

      case .parsingFailed:
        // Should not reach here due to partialSuccess handling in importManager
        dismiss()
        onDismiss?()
      }
    } catch {
      ToastManager.shared.show(
        icon: "xmark.circle.fill",
        title: "Import failed",
        subtitle: error.localizedDescription,
        tint: .red,
        duration: 3.0
      )
      dismiss()
      onDismiss?()
    }
  }
}
