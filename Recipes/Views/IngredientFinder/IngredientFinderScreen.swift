//
//  IngredientFinderScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-12-31.
//

import Dependencies
import SQLiteData
import SwiftUI

struct IngredientFinderScreen: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL
  @Dependency(\.defaultDatabase) private var database

  @State private var ingredientsText: String = ""
  @State private var myRecipesOnly: Bool = true
  @State private var searchResults: [RecipeMatch] = []
  @State private var isSearching: Bool = false
  @State private var searchError: String?

  @FocusState private var keyboardFocused: Bool

  @FetchAll(RecipePhoto.order(by: \.position))
  private var recipePhotos: [RecipePhoto]

  private var recipePhotosPerRecipe: [Recipe.ID: [RecipePhoto]] {
    Dictionary(grouping: recipePhotos, by: \.recipeId)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Input Section
        VStack(alignment: .leading, spacing: 12) {
          Text("Available Ingredients")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)

          TextEditor(text: $ingredientsText)
            .frame(minHeight: 120, maxHeight: 200)
            .padding(8)
            .background(Color(uiColor: .systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
              RoundedRectangle(cornerRadius: 10)
                .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
            )
            .focused($keyboardFocused)

          if ingredientsText.isEmpty {
            Text(
              "Enter ingredients separated by commas or new lines\nExample: tomatoes, pasta, garlic, olive oil"
            )
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 4)
          }

          // Toggle
          Toggle("My recipes only", isOn: $myRecipesOnly)
            .tint(.accent)

          // Action Buttons
          if myRecipesOnly {
            Button {
              searchLocalRecipes()
            } label: {
              HStack {
                Image(systemName: "magnifyingglass")
                Text("Search my recipes")
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
            }
            .buttonStyle(.glassProminent)
            .disabled(
              ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching
            )
          } else {
            HStack(spacing: 12) {
              Button {
                openChatGPT()
              } label: {
                HStack {
                  Image(systemName: "bubble.left.and.bubble.right")
                  Text("Ask ChatGPT")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
              }
              .buttonStyle(.glassProminent)
              .disabled(ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

              Button {
                copyPrompt()
              } label: {
                Image(systemName: "doc.on.doc")
                  .frame(width: 44, height: 44)
              }
              .buttonStyle(.glass)
              .buttonBorderShape(.circle)
              .tint(.accent)
              .disabled(ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
          }

          if let error = searchError {
            Text(error)
              .font(.caption)
              .foregroundStyle(.red)
              .padding(.horizontal, 4)
          }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))

        Divider()

        // Results Section
        if myRecipesOnly {
          if isSearching {
            VStack {
              Spacer()
              ProgressView()
              Text("Searching recipes...")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
              Spacer()
            }
          } else if searchResults.isEmpty && !ingredientsText.isEmpty {
            VStack(spacing: 12) {
              Spacer()
              Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
              Text("No matching recipes found")
                .font(.headline)
              Text("Try different ingredients or turn off 'My recipes only'")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
              Spacer()
            }
          } else if !searchResults.isEmpty {
            ScrollView {
              LazyVStack(spacing: 12) {
                ForEach(searchResults) { match in
                  RecipeMatchRow(match: match, photos: recipePhotosPerRecipe[match.id] ?? [])
                }
              }
              .padding()
            }
          } else {
            VStack {
              Spacer()
              Image(systemName: "frying.pan")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
              Text("Enter your ingredients to find recipes")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
              Spacer()
            }
          }
        } else {
          VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
              .font(.system(size: 48))
              .foregroundStyle(.accent)
            Text("Use ChatGPT to find recipes")
              .font(.headline)
            Text("ChatGPT will search online recipes using your ingredients")
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
            Spacer()
          }
        }
      }
      .navigationTitle("Find Recipes")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(for: Recipe.ID.self) { recipeId in
        RecipeDetailScreen(recipeId: recipeId)
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .close) {
            dismiss()
          }
        }

        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button {
            keyboardFocused = false
          } label: {
            Label("Dismiss keyboard", systemImage: "keyboard.chevron.compact.down")
              .labelStyle(.iconOnly)
          }
        }
      }
    }
    .toastPresenter()
  }

  // MARK: - Actions

  private func searchLocalRecipes() {
    searchError = nil
    isSearching = true
    searchResults = []

    Task {
      do {
        let results = try IngredientMatchingService.findMatches(
          userIngredients: ingredientsText,
          database: database
        )

        await MainActor.run {
          searchResults = results
          isSearching = false

          if results.isEmpty {
            searchError = "No recipes found matching your ingredients"
          }
        }
      } catch {
        await MainActor.run {
          searchError = "Search failed: \(error.localizedDescription)"
          isSearching = false
        }
      }
    }
  }

  private func openChatGPT() {
    guard let url = ChatGPTPromptService.createChatGPTDeeplink(ingredients: ingredientsText) else {
      searchError = "Failed to create ChatGPT link"
      return
    }

    openURL(url) { success in
      if !success {
        searchError = "Could not open ChatGPT app"
      }
    }
  }

  private func copyPrompt() {
    let prompt = ChatGPTPromptService.generateRecipePrompt(ingredients: ingredientsText)
    UIPasteboard.general.string = prompt

    ToastManager.shared.show(
      icon: "doc.on.doc.fill",
      title: "Prompt copied",
      subtitle: "Paste in ChatGPT app",
      tint: .accent,
      duration: 2.5
    )
  }
}

// MARK: - Recipe Match Row

struct RecipeMatchRow: View {
  let match: RecipeMatch
  let photos: [RecipePhoto]

  private var matchPercentageText: String {
    let percentage = Int(match.matchPercentage * 100)
    return "\(percentage)%"
  }

  private var matchDetailsText: String {
    let total = match.matchedIngredients.count + match.missingIngredients.count
    return "\(match.matchedIngredients.count)/\(total) ingredients"
  }

  var body: some View {
    NavigationLink(value: match.recipeDetails.recipe.id) {
      HStack(spacing: 12) {
        // Recipe Photo
        Group {
          if let photo = photos.first, let image = photo.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            Image(systemName: "frying.pan.fill")
              .font(.system(size: 24))
              .foregroundStyle(.secondary)
          }
        }
        .frame(width: 64, height: 64)
        .background(Color(uiColor: .systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))

        // Recipe Details
        VStack(alignment: .leading, spacing: 4) {
          Text(match.recipeDetails.recipe.name)
            .font(.headline)
            .lineLimit(2)

          HStack(spacing: 8) {
            Label(matchDetailsText, systemImage: "checkmark.circle.fill")
              .font(.caption)
              .foregroundStyle(
                match.matchPercentage >= 0.8
                  ? .green : match.matchPercentage >= 0.5 ? .orange : .secondary)

            if !match.missingIngredients.isEmpty {
              Text("• Missing: \(match.missingIngredients.prefix(2).joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
          }
        }

        Spacer()

        // Match Badge
        Text(matchPercentageText)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(
            match.matchPercentage >= 0.8
              ? Color.green : match.matchPercentage >= 0.5 ? Color.orange : Color.gray
          )
          .clipShape(Capsule())
      }
      .padding(12)
      .background(Color(uiColor: .systemGray6))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  Storage.configure()
  return IngredientFinderScreen()
}
