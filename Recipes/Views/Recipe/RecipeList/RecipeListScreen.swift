//
//  RecipeListScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-11-08.
//

import Dependencies
import PhotosUI
import SQLiteData
import SwiftUI
import SwiftUINavigation
import os

struct RecipeListScreen: View {
  @Environment(\.scenePhase) private var scenePhase
  @Dependency(\.defaultDatabase) private var database

  @FetchAll(Recipe.order(by: \.name), animation: .default)
  private var recipes

  @FetchAll(RecipePhoto.order(by: \.position))
  private var recipePhotos: [RecipePhoto]

  @State private var searchText: String = ""

  @State private var sortBy: SortBy = .name
  @State private var sortDirection: SortDirection = .asc

  @State private var editMode: EditMode = .inactive
  @State private var selection = Set<Recipe.ID>()
  @State private var showDeleteConfirmation: Bool = false

  // Photo import state
  @State private var showPhotosPicker: Bool = false
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var showCamera: Bool = false
  @State private var showProcessingSheet: Bool = false
  @State private var processingStatus: RecipeProcessingView.Status = .extractingText
  @State private var processingTask: Task<Void, Never>?

  // Video import state
  @State private var showVideoImport: Bool = false

  private var appRouter = AppRouter.shared
  private let importManager = PhotoRecipeImportManager()

  private var searchId: String {
    "\(searchText)_\(sortBy)_\(sortDirection)"
  }

  private var recipePhotosPerRecipe: [Recipe.ID: [RecipePhoto]] {
    Dictionary(grouping: recipePhotos, by: \.recipeId)
  }

  var body: some View {
    @Bindable var appRouter = appRouter

    NavigationStack(path: $appRouter.navigationPath) {
      RecipeListView(recipes: recipes, recipePhotos: recipePhotosPerRecipe, selection: $selection)
        .navigationTitle("All recipes")
        .toolbarTitleDisplayMode(.inlineLarge)
        .searchable(text: $searchText)
        .task(id: searchId) {
          await updateSearchQuery()
        }
        .environment(\.editMode, $editMode)
        .toolbar {
          ToolbarItemGroup(placement: .primaryAction) {
            if editMode == .active {
              Button(role: .destructive) {
                showDeleteConfirmation = true
              }
              .disabled(selection.isEmpty)
              .tint(.red)
              .confirmationDialog(
                "Select Delete to permanently remove \(selection.count) recipes.",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
              ) {
                Button(role: .destructive) {
                  deleteSelectedRecipes()
                  selection.removeAll()
                  Task {
                    try await Task.sleep(for: .milliseconds(10))
                    withAnimation {
                      editMode = .inactive
                    }
                  }
                }
                Button("Cancel") {}
              }

              Button {
                withAnimation {
                  editMode = .inactive
                }
              } label: {
                Label("Done", systemImage: "checkmark")
              }
              .buttonStyle(.glassProminent)
            } else {
              Menu {
                Section("Sorting") {
                  let systemImage: String = sortDirection == .asc ? "chevron.up" : "chevron.down"
                  Button {
                    if sortBy == .name {
                      sortDirection = sortDirection == .asc ? .desc : .asc
                    }
                    sortBy = .name
                  } label: {
                    if sortBy == .name {
                      Label("Name", systemImage: systemImage)
                    } else {
                      Text("Name")
                    }
                  }

                  Button {
                    if sortBy == .createdAt {
                      sortDirection = sortDirection == .asc ? .desc : .asc
                    }
                    sortBy = .createdAt
                  } label: {
                    if sortBy == .createdAt {
                      Label("Date added", systemImage: systemImage)
                    } else {
                      Text("Date added")
                    }
                  }
                }

                Section {
                  Button {
                    appRouter.destination = .ingredientFinder
                  } label: {
                    Label("Find by ingredients", systemImage: "fork.knife")
                  }

                  Button {
                    withAnimation {
                      selection.removeAll()
                      editMode = .active
                    }
                  } label: {
                    Label("Select recipes", systemImage: "checkmark.circle")
                  }
                }
              } label: {
                Label("Options", systemImage: "ellipsis")
              }
            }
          }
        }
        .safeAreaBar(edge: .bottom) {
          HStack {
            Spacer()

            Menu {
              Section {
                Button {
                  let emptyRecipe = RecipeDetails(
                    recipe: Recipe(id: UUID()),
                    ingredients: [],
                    instructions: [],
                    photos: []
                  )
                  appRouter.destination = .addRecipe(emptyRecipe)
                } label: {
                  Label("Add manually", systemImage: "square.and.pencil")
                }

                Button {
                  showVideoImport = true
                } label: {
                  Label("From Social Media...", systemImage: "link")
                }
              }

              if RecipeParsingService.isAvailable {
                Section("Smart Import") {
                  Button {
                    showCamera = true
                  } label: {
                    Label("From Camera...", systemImage: "camera")
                  }
                  Button {
                    showPhotosPicker = true
                  } label: {
                    Label("From Image...", systemImage: "photo")
                  }
                }
              }
            } label: {
              Label("Add a recipe", systemImage: "plus")
                .labelStyle(.iconOnly)
                .font(.system(size: 22))
                .frame(width: 48, height: 48)
                .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
          }
          .padding(.trailing)
          .padding(.bottom, 8)
        }
        .photosPicker(
          isPresented: $showPhotosPicker,
          selection: $selectedPhotoItem,
          matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
          guard let newItem else { return }
          processPhotoItem(newItem)
        }
        .fullScreenCover(isPresented: $showCamera) {
          CameraView { imageData in
            showCamera = false
            if let imageData {
              processImageData(imageData)
            }
          }
          .ignoresSafeArea()
        }
        .sheet(isPresented: $showProcessingSheet) {
          RecipeProcessingView(status: processingStatus) {
            cancelProcessing()
          }
        }
        .sheet(item: $appRouter.destination.addRecipe) { recipeDetails in
          RecipeImportScreen(recipeDetails: recipeDetails)
        }
        .sheet(isPresented: $appRouter.destination.ingredientFinder) {
          IngredientFinderScreen()
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showVideoImport) {
          VideoRecipeImportScreen()
            .interactiveDismissDisabled()
        }
        .onChange(of: scenePhase) { oldValue, newValue in
          if oldValue == .inactive && newValue == .active {
            Task {
              await withThrowingTaskGroup { group in
                group.addTask {
                  try await $recipes.load()
                  Logger.ui.info("✅ Done loading recipes")
                }
                group.addTask {
                  try await $recipePhotos.load()
                  Logger.ui.info("✅ Done loading recipe photos")
                }
                Logger.ui.info("🔄 Waiting for recipe data to load...")
              }
              Logger.ui.info("🎉 All recipe data loaded!")
              Logger.ui.info("Total recipes loaded: \(recipes.count)")
            }
          }
        }
    }
  }

  private func processPhotoItem(_ item: PhotosPickerItem) {
    processingStatus = .extractingText
    showProcessingSheet = true

    processingTask = Task {
      guard let data = try? await item.loadTransferable(type: Data.self) else {
        //        await MainActor.run {
        showProcessingSheet = false
        selectedPhotoItem = nil
        ToastManager.shared.show(
          icon: "xmark.circle.fill",
          title: "Failed to load image",
          tint: .red,
          duration: 3.0
        )
        //        }
        return
      }

      await processImageDataAsync(data)
    }
  }

  private func processImageData(_ data: Data) {
    processingStatus = .extractingText
    showProcessingSheet = true

    processingTask = Task {
      await processImageDataAsync(data)
    }
  }

  nonisolated private func processImageDataAsync(_ data: Data) async {
    do {
      let result = try await importManager.importRecipe(from: data) { status in
        Task { @MainActor in
          processingStatus = status
        }
      }

      await MainActor.run {
        showProcessingSheet = false
        selectedPhotoItem = nil

        switch result {
        case .success(let details):
          appRouter.destination = .addRecipe(details)

        case .partialSuccess(let details, _, _):
          ToastManager.shared.show(
            icon: "exclamationmark.triangle.fill",
            title: "Parsing incomplete",
            subtitle: "Extracted text added to notes",
            tint: .orange,
            duration: 3.0
          )
          appRouter.destination = .addRecipe(details)
        }
      }
    } catch is CancellationError {
      // User cancelled - do nothing
      await MainActor.run {
        selectedPhotoItem = nil
      }
    } catch let error as PhotoRecipeImportManager.ImportError {
      await MainActor.run {
        showProcessingSheet = false
        selectedPhotoItem = nil

        switch error {
        case .ocrFailed:
          ToastManager.shared.show(
            icon: "xmark.circle.fill",
            title: "Could not read image",
            subtitle: "No text found in the photo",
            tint: .red,
            duration: 3.0
          )
        case .parsingFailed:
          ToastManager.shared.show(
            icon: "xmark.circle.fill",
            title: "Import failed",
            tint: .red,
            duration: 3.0
          )
        }
      }
    } catch {
      await MainActor.run {
        showProcessingSheet = false
        selectedPhotoItem = nil
        ToastManager.shared.show(
          icon: "xmark.circle.fill",
          title: "Import failed",
          subtitle: .init(stringLiteral: error.localizedDescription),
          tint: .red,
          duration: 3.0
        )
      }
    }
  }

  private func cancelProcessing() {
    processingTask?.cancel()
    processingTask = nil
    showProcessingSheet = false
    selectedPhotoItem = nil
  }

  private func updateSearchQuery() async {
    _ = await withErrorReporting {
      try await $recipes.load(
        Recipe
          .where { recipe in
            if searchText.isEmpty {
              true
            } else {
              RecipeText
                .where { $0.match(searchText) && $0.rowid.eq(recipe.rowid) }
                .exists()
            }
          }
          .order {
            switch (sortBy, sortDirection) {
            case (.name, .asc):
              $0.name.asc()
            case (.name, .desc):
              $0.name.desc()
            case (.createdAt, .asc):
              $0.createdAt.asc()
            case (.createdAt, .desc):
              $0.createdAt.desc()
            }
          }
      )
    }
  }

  private func deleteSelectedRecipes() {
    withErrorReporting {
      try database.write { db in
        try Recipe
          .where { selection.contains($0.id) }
          .delete()
          .execute(db)
      }
    }
  }
}

#Preview {
  Storage.configure()
  return RecipeListScreen()

}
