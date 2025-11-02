import Dependencies
import SQLiteData
import SwiftUI

struct RecipeDetailView: View {
  let recipeId: RecipeRecord.ID
  @State private var recipeDetails: RecipeDetail.Value?
  
  init(recipeId: RecipeRecord.ID) {
    self.recipeId = recipeId
  }

  @Dependency(\.defaultDatabase) private var database
  @State private var loadError: String?

  var body: some View {
    Group {
      if let recipeDetails, let recipe = recipeDetails.recipe {
        RecipeDetailContent(
          recipe: recipe,
          ingredients: recipeDetails.ingredients,
          instructions: recipeDetails.instructions
        )
      } else if let loadError {
        ContentUnavailableView(
          "Recipe Unavailable",
          systemImage: "exclamationmark.triangle",
          description: Text(loadError)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        VStack(spacing: 12) {
          ProgressView()
          Text("Loading…")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    //    .task(id: recipeId, loadRecipe)
    .task(id: recipeId) {
      await withErrorReporting {
        let details = try await database.read {
          return try RecipeDetail(recipeId: recipeId).fetch($0)
        }
        await MainActor.run {
          recipeDetails = details
          if details.recipe == nil {
            loadError = "This recipe could not be found."
          } else {
            loadError = nil
          }
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
  }

  //  private func loadRecipe() async {
  //    await MainActor.run {
  //      loadError = nil
  //    }
  //
  //    do {
  //      let response = try await database.read { db in
  //        return try RecipeDetailRequest(recipeId: recipeId).fetch(db)
  //      }
  //      await MainActor.run {
  //        recipeDetails = response
  //        if response.recipe == nil {
  //          loadError = "This recipe could not be found."
  //        } else {
  //          loadError = nil
  //        }
  //      }
  //    } catch {
  //      await MainActor.run {
  //        loadError = error.localizedDescription
  //        recipeDetails = nil
  //      }
  //    }
  //  }
}

private struct RecipeDetail: FetchKeyRequest {
  let recipeId: RecipeRecord.ID

  struct Value {
    let recipe: RecipeRecord?
    let ingredients: [RecipeIngredientRecord]
    let instructions: [RecipeInstructionRecord]
  }

  func fetch(_ db: Database) throws -> Value {
    try Value(
      recipe: RecipeRecord.where {$0.id == recipeId}.fetchOne(db),
      ingredients:
        RecipeIngredientRecord
        .where { $0.recipeId == recipeId }
        .order(by: \.position)
        .fetchAll(db),
      instructions:
        RecipeInstructionRecord
        .where { $0.recipeId == recipeId }
        .order(by: \.position)
        .fetchAll(db)
    )
  }
}

private struct RecipeDetailContent: View {
  let recipe: RecipeRecord
  let ingredients: [RecipeIngredientRecord]
  let instructions: [RecipeInstructionRecord]

  //  private var ingredients: [RecipeIngredientRecord] {
  //    recipe.ingredients.sorted { $0.position < $1.position }
  //  }
  //
  //  private var instructions: [RecipeInstructionRecord] {
  //    recipe.instructions.sorted { $0.position < $1.position }
  //  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        if ingredients.isEmpty == false {
          ingredientsSection
        }

        if instructions.isEmpty == false {
          instructionsSection
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 22)
    }
    .darkPrimaryLightSecondaryBackgroundColor()
    .navigationTitle(recipe.title)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(recipe.title)
        .font(.largeTitle.weight(.bold))
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)

      HStack(alignment: .center) {
        HStack(spacing: 8) {
          Image(systemName: "person.2")
            .foregroundStyle(.tint)
          VStack(alignment: .leading, spacing: 4) {
            Text("\(recipe.servings, default: "N/A")")
              .font(.body.weight(.semibold))
              .foregroundStyle(.primary)
          }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .card(cornerRadius: 40)

        HStack(alignment: .center, spacing: 40) {
          VStack(spacing: 2) {
            HStack(spacing: 6) {
              Text("Prep")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
              Image(systemName: "clock")
                .foregroundStyle(.tint)
            }
            Text(minutesString(recipe.prepTimeMinutes))
              .font(.body.weight(.semibold))
              .foregroundStyle(.primary)
          }
          .multilineTextAlignment(.center)

          VStack(alignment: .center, spacing: 2) {
            HStack(spacing: 6) {
              Text("Cook")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
              Image(systemName: "clock")
                .foregroundStyle(.tint)
            }
            Text(minutesString(recipe.cookTimeMinutes))
              .font(.body.weight(.semibold))
              .foregroundStyle(.primary)
          }
          .multilineTextAlignment(.center)

        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .card(cornerRadius: 40)
      }
    }
  }

  private var ingredientsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Ingredients")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)

      VStack(alignment: .leading, spacing: 12) {
        ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, line in
          Text(line.text)
            .font(.body)
            .foregroundStyle(.primary)

          if index != ingredients.count - 1 {
            Divider()
          }
        }
      }
      .padding()
      .card()
    }
  }

  private var instructionsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Instructions")
        .font(.title3.weight(.semibold))
      VStack(alignment: .leading, spacing: 20) {
        ForEach(Array(instructions.enumerated()), id: \.element.id) { index, step in
          HStack(alignment: .top) {
            Text("\(index + 1)")
              .font(.body.weight(.semibold))
              .foregroundStyle(Color(uiColor: .tintColor).contrastingForegroundColor())
              .frame(width: 22, height: 22)
              .background(
                Circle()
                  .fill(.tint)
              )

            Text(step.text)
              .font(.body)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding()
          .card()
        }
      }
    }
  }

  private func minutesString(_ minutes: Int?) -> String {
    minutes == 1 ? "1 min" : "\(minutes, default: "N/A") mins"
  }
}

private struct CardModifier: ViewModifier {
  let cornerRadius: CGFloat

  init(cornerRadius: CGFloat? = nil) {
    self.cornerRadius = cornerRadius ?? 20
  }

  func body(content: Content) -> some View {
    content
      .darkSecondaryLightPrimaryBackgroundColor()
      .clipShape(.rect(cornerRadius: cornerRadius))
      .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
  }
}

extension View {
  fileprivate func card(cornerRadius: CGFloat? = nil) -> some View {
    modifier(
      CardModifier(cornerRadius: cornerRadius)
    )
  }
}

#Preview {
  let sample = StorageBootstrap.configurePreviewWithInitialFetcher { database in
    try database.read { db in
      try RecipeRecord.limit(1).fetchOne(db)
    }
  }

  NavigationStack {
    if let sample {
      RecipeDetailView(recipeId: sample.id)
    } else {
      Text("No sample recipe")
    }
  }
}
