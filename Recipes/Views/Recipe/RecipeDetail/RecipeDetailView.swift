import Dependencies
import SQLiteData
import SwiftUI

struct RecipeDetailView: View {
  @State private var viewModel: RecipeDetailViewModel
  
  init(recipe: Recipe) {
    _viewModel = State(initialValue: RecipeDetailViewModel(recipe: recipe))
  }

  var body: some View {
    Group {
      if viewModel.isLoading {
        ProgressView("Loading recipe details...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let error = viewModel.error {
        ContentUnavailableView(
          "Failed to Load Recipe",
          systemImage: "exclamationmark.triangle",
          description: Text(error)
        )
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Retry") {
              viewModel.retry()
            }
          }
        }
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            header

            if !viewModel.ingredients.isEmpty {
              ingredientsSection
            }

            if !viewModel.instructions.isEmpty {
              instructionsSection
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 22)
        }
      }
    }
    .darkPrimaryLightSecondaryBackgroundColor()
    .navigationTitle(viewModel.recipe.name)
    .navigationBarTitleDisplayMode(.inline)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(viewModel.recipe.name)
        .font(.largeTitle.weight(.bold))
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)

      HStack(alignment: .center) {
        HStack(spacing: 8) {
          Image(systemName: "person.2")
            .foregroundStyle(.tint)
          VStack(alignment: .leading, spacing: 4) {
            Text("\(viewModel.recipe.servings, default: "N/A")")
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
            Text(minutesString(viewModel.recipe.prepTimeMinutes))
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
            Text(minutesString(viewModel.recipe.cookTimeMinutes))
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
        ForEach(Array(viewModel.ingredients.enumerated()), id: \.element.id) { index, line in
          Text(line.text)
            .font(.body)
            .foregroundStyle(.primary)

          if index != viewModel.ingredients.count - 1 {
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
        ForEach(Array(viewModel.instructions.enumerated()), id: \.element.id) { index, step in
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
      RecipeDetailView(recipe: sample)
    } else {
      Text("No sample recipe")
    }
  }
}
