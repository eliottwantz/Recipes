import Dependencies
import SQLiteData
import SwiftUI

struct RecipeListView: View {
  @FetchAll(Recipe.order { $0.updatedAt.desc() })
  private var recipes

  @Environment(\.scenePhase) private var scenePhase
  @State private var importModel = RecipeImportModel()

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
          NavigationLink(value: recipe) {
            RecipeRow(recipe: recipe)
          }
        }
        .listStyle(.plain)
      }
    }
    .navigationTitle("Recipes")
    .navigationDestination(
      for: Recipe.self,
      destination: { recipe in
        RecipeDetailView(recipe: recipe)
      }
    )
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          importModel.showAddForm = true
        } label: {
          Label("Add", systemImage: "plus")
        }
      }
    }
    .sheet(isPresented: $importModel.showAddForm) {
      Form {
        Text("Recipe URL")
          .font(.caption)
          .foregroundColor(.secondary)
        TextField("URL", text: $importModel.recipeUrl)
          .keyboardType(.URL)
          .textInputAutocapitalization(.never)
          .disableAutocorrection(true)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .disabled(importModel.isImporting)
        if importModel.isImporting {
          HStack {
            ProgressView()
            Text("Importing…")
              .foregroundStyle(.secondary)
          }
        }
        Button {
          importModel.handleImport()
        } label: {
          Text(importModel.isImporting ? "Importing…" : "Import Recipe")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(
          importModel.isImporting
            || importModel.recipeUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .submitLabel(.send)
      .onSubmit {
        importModel.handleImport()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            importModel.showAddForm = false
            importModel.recipeUrl = ""
            importModel.importError = nil
          }
          .disabled(importModel.isImporting)
        }
      }
    }
    .alert(
      "Import Failed",
      isPresented: Binding(
        get: { importModel.importError != nil },
        set: { isPresented in
          if !isPresented {
            importModel.importError = nil
          }
        }
      )
    ) {
      Button("OK", role: .cancel) {
        importModel.importError = nil
      }
    } message: {
      Text(importModel.importError ?? "")
    }
    .onChange(of: importModel.showAddForm) { _, newValue in
      if !newValue {
        importModel.recipeUrl = ""
        importModel.isImporting = false
        importModel.importError = nil
      }
    }
    .onChange(of: scenePhase) { oldValue, newValue in
      if oldValue == .inactive && newValue == .active {
        Task {
          try await $recipes.load()
        }
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
      if let summary = recipe.summary, !summary.isEmpty {
        Text(summary)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(3)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
  }
}

#Preview {
  Storage.configure()
  return NavigationStack {
    RecipeListView()
  }
}
