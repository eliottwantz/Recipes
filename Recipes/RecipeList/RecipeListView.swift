import Dependencies
import SQLiteData
import SwiftUI

struct RecipeListView: View {
  @FetchAll(
    Recipe
      .order { $0.updatedAt.desc() },
    animation: .default
  )
  private var recipes
  
  @Dependency(RecipeImportManager.self) private var recipeImportManager
  
  @State private var showAddForm = false
  @State private var recipeUrl = ""
  @State private var isImporting = false
  @State private var importError: String?

  var body: some View {
    Group {
      if recipes.isEmpty {
        ContentUnavailableView(
          "No Recipes Yet",
          systemImage: "text.book.closed",
          description: Text("Add a new recipe to start building your collection.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(recipes) { recipe in
          NavigationLink {
            RecipeDetailView(recipe: recipe)
          } label: {
            RecipeRow(recipe: recipe)
          }
        }
        .listStyle(.plain)
      }
    }
    .navigationTitle("Recipes")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          showAddForm = true
        } label: {
          Label("Add", systemImage: "plus")
        }
      }
    }
    .sheet(isPresented: $showAddForm) {
      Form {
        Text("Recipe URL")
          .font(.caption)
          .foregroundColor(.secondary)
        TextField("URL", text: $recipeUrl)
          .keyboardType(.URL)
          .textInputAutocapitalization(.never)
          .disableAutocorrection(true)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .disabled(isImporting)
        if isImporting {
          HStack {
            ProgressView()
            Text("Importing…")
              .foregroundStyle(.secondary)
          }
        }
        Button {
          handleImport()
        } label: {
          Text(isImporting ? "Importing…" : "Import Recipe")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isImporting || recipeUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .submitLabel(.send)
      .onSubmit {
        handleImport()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            showAddForm = false
            recipeUrl = ""
            importError = nil
          }
          .disabled(isImporting)
        }
      }
    }
    .alert("Import Failed", isPresented: Binding(
      get: { importError != nil },
      set: { isPresented in
        if !isPresented {
          importError = nil
        }
      }
    )) {
      Button("OK", role: .cancel) {
        importError = nil
      }
    } message: {
      Text(importError ?? "")
    }
    .onChange(of: showAddForm) { _, newValue in
      if !newValue {
        recipeUrl = ""
        isImporting = false
        importError = nil
      }
    }
  }
}

private struct RecipeRow: View {
  let recipe: Recipe

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(recipe.title)
        .font(.headline)
        .foregroundStyle(.primary)
      if !recipe.summary.isEmpty {
        Text(recipe.summary)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(3)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
  }
}

private extension RecipeListView {
  @MainActor
  func handleImport() {
    let trimmed = recipeUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    guard let url = URL(string: trimmed) else {
      importError = "Please enter a valid recipe URL."
      return
    }

    if isImporting {
      return
    }

    let manager = recipeImportManager
    isImporting = true

    Task {
      do {
        _ = try await manager.importRecipe(from: url)
        await MainActor.run {
          isImporting = false
          recipeUrl = ""
          showAddForm = false
        }
      } catch {
        await MainActor.run {
          isImporting = false
          importError = error.localizedDescription
        }
      }
    }
  }
}

#Preview {
  StorageBootstrap.configurePreview()
  return NavigationStack {
    RecipeListView()
  }
}
