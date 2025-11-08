//
//  ShareReviewView.swift
//  RecipeShareExtension
//
//  Created by Codex on 2025-10-25.
//

import SwiftUI

struct ShareReviewView: View {
  @Bindable var viewModel: ShareImportViewModel
  let context: NSExtensionContext

  var body: some View {
    NavigationStack {
//      content
//        .navigationTitle("Review Recipe")
//        .toolbar {
//          ToolbarItem(placement: .cancellationAction) {
//            Button("Cancel", action: cancel)
//          }
//          ToolbarItem(placement: .confirmationAction) {
//            Button {
//              viewModel.saveCurrentDraft(in: context)
//            } label: {
//              if viewModel.isSaving {
//                ProgressView()
//              } else {
//                Text("Save")
//              }
//            }
//            .disabled(isSaveDisabled)
//          }
//        }
    }
//    .alert(item: $viewModel.saveError) { error in
//      Alert(
//        title: Text("Unable to Save"),
//        message: Text(error.message),
//        dismissButton: .default(Text("OK"))
//      )
//    }
  }
//
//  @ViewBuilder
//  private var content: some View {
//    switch viewModel.phase {
//    case .idle, .loading:
//      VStack(spacing: 16) {
//        ProgressView()
//        Text("Importing recipe…")
//          .font(.callout)
//          .foregroundStyle(.secondary)
//      }
//      .frame(maxWidth: .infinity, maxHeight: .infinity)
//      .background(Color(.systemGroupedBackground))
//    case .failed(let error):
//      ShareErrorView(
//        error: error,
//        cancel: cancel
//      )
//    case .loaded:
//      if let draft = viewModel.draft {
//        RecipeFormView(draft: draft)
//      } else {
//        Text("No recipe data available")
//          .foregroundStyle(.secondary)
//          .frame(maxWidth: .infinity, maxHeight: .infinity)
//          .background(Color(.systemGroupedBackground))
//      }
//    }
//  }
//
//  private var isSaveDisabled: Bool {
//    guard let draft = viewModel.draft else { return true }
//    return viewModel.isSaving
//      || draft.recipe.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//  }
//
//  private func cancel() {
//    viewModel.cancel(context: context)
//  }
}

//private struct RecipeFormView: View {
//  @Bindable var draft: ShareImportViewModel.Draft
//
//  var body: some View {
//    Form {
//      Section("Details") {
//        TextField("Title", text: $draft.recipe.title)
//          .textContentType(.name)
//          .submitLabel(.done)
//
//        TextEditor(
//          text: Binding(
//            get: { draft.recipe.summary ?? "" },
//            set: { draft.recipe.summary = $0.isEmpty ? nil : $0 }
//          )
//        )
//        .frame(minHeight: 80)
//        .overlay(alignment: .topLeading) {
//          if draft.recipe.summary?.isEmpty ?? true {
//            Text("Summary")
//              .foregroundStyle(.secondary)
//              .padding(.top, 8)
//              .padding(.leading, 5)
//          }
//        }
//      }
//
//      Section("Ingredients") {
//        TextEditor(
//          text: Binding(
//            get: { draft.ingredientsText },
//            set: { newValue in
//              draft.ingredients = newValue.components(separatedBy: .newlines).enumerated().map { index, text in
//                RecipeIngredient(id: UUID(), recipeId: draft.recipe.id, position: index, text: text)
//              }
//            }
//          )
//        )
//        .frame(minHeight: 160)
//        .font(.system(.body, design: .monospaced))
//      }
//
//      Section("Instructions") {
//        TextEditor(
//          text: Binding(
//            get: { draft.instructionsText },
//            set: { newValue in
//              draft.instructions = newValue.components(separatedBy: .newlines).enumerated().map { index, text in
//                RecipeInstruction(id: UUID(), recipeId: draft.recipe.id, position: index, text: text)
//              }
//            }
//          )
//        )
//        .frame(minHeight: 200)
//      }
//
//      Section("Servings & Timing") {
//        StepperField(
//          title: "Servings",
//          value: Binding(
//            get: { draft.recipe.servings ?? 0 },
//            set: { draft.recipe.servings = $0 == 0 ? nil : $0 }
//          )
//        )
//
//        StepperField(
//          title: "Prep Minutes",
//          value: Binding(
//            get: { draft.recipe.prepTimeMinutes ?? 0 },
//            set: { draft.recipe.prepTimeMinutes = $0 == 0 ? nil : $0 }
//          )
//        )
//
//        StepperField(
//          title: "Cook Minutes",
//          value: Binding(
//            get: { draft.recipe.cookTimeMinutes ?? 0 },
//            set: { draft.recipe.cookTimeMinutes = $0 == 0 ? nil : $0 }
//          )
//        )
//      }
//    }
//  }
//}
//
//private struct ShareErrorView: View {
//  let error: ShareImportViewModel.ShareError
//  let cancel: () -> Void
//
//  var body: some View {
//    VStack(spacing: 20) {
//      Image(systemName: "exclamationmark.triangle.fill")
//        .font(.system(size: 40))
//        .foregroundStyle(.yellow)
//
//      Text(error.message)
//        .multilineTextAlignment(.center)
//        .font(.body)
//        .padding(.horizontal)
//
//      Button("Cancel", role: .cancel, action: cancel)
//    }
//    .frame(maxWidth: .infinity, maxHeight: .infinity)
//    .padding()
//    .background(Color(.systemGroupedBackground))
//  }
//}
//
//private struct StepperField: View {
//  let title: String
//  @Binding var value: Int
//
//  var body: some View {
//    Stepper(value: $value, in: 0...600, step: 1) {
//      HStack {
//        Text(title)
//        Spacer()
//        if value > 0 {
//          Text("\(value)")
//            .foregroundStyle(.secondary)
//        } else {
//          Text("Optional")
//            .foregroundStyle(.tertiary)
//        }
//      }
//    }
//  }
//}
