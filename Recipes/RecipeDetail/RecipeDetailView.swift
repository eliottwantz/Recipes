import Dependencies
import SQLiteData
import SwiftUI

@MainActor
@Observable
final class RecipeDetailModel {
  let recipeId: Recipe.ID
  @ObservationIgnored @Fetch private var recipeDetail: RecipeDetail.Value

  var recipe: Recipe? { recipeDetail.recipe }
  var ingredients: [RecipeIngredient] { recipeDetail.ingredients }
  var instructions: [RecipeInstruction] { recipeDetail.instructions }

  init(recipeId: Recipe.ID) {
    self.recipeId = recipeId
    self._recipeDetail = .init(
      wrappedValue: .placeholder,
      RecipeDetail(recipeId: recipeId)
    )
  }

  private struct RecipeDetail: FetchKeyRequest {
    let recipeId: Recipe.ID

    struct Value {
      let recipe: Recipe?
      let ingredients: [RecipeIngredient]
      let instructions: [RecipeInstruction]

      static var placeholder: Value { .init(recipe: nil, ingredients: [], instructions: []) }
    }

    func fetch(_ db: Database) throws -> Value {
      try Value(
        recipe: Recipe.where { $0.id == recipeId }.fetchOne(db),
        ingredients:
          RecipeIngredient
          .where { $0.recipeId == recipeId }
          .order(by: \.position)
          .fetchAll(db),
        instructions:
          RecipeInstruction
          .where { $0.recipeId == recipeId }
          .order(by: \.position)
          .fetchAll(db)
      )
    }
  }
}

struct RecipeDetailView: View {
  @Bindable var model: RecipeDetailModel

  var body: some View {
    Group {
      if let recipe = model.recipe {
        RecipeDetailContent(
          recipe: recipe,
          ingredients: model.ingredients,
          instructions: model.instructions
        )
      } else {
        ContentUnavailableView(
          "Recipe Unavailable",
          systemImage: "exclamationmark.triangle",
          description: Text("This recipe could not be found")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct RecipeDetailContent: View {
  let recipe: Recipe
  let ingredients: [RecipeIngredient]
  let instructions: [RecipeInstruction]

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
  let sample = Storage.configure { database in
    try database.read { db in
      print("FETCHING RECIPE FOR PREVIEW")
      return try Recipe.all.fetchOne(db)
    }
  }

  NavigationStack {
    if let sample {
      RecipeDetailView(model: .init(recipeId: sample.id))
    } else {
      Text("No sample recipe")
    }
  }
}
