import SQLiteData
import SwiftUI
import UIKit

struct RecipeDetailView: View {
  let recipe: Recipe

  private var ingredientLines: [String] {
    splitLines(recipe.ingredients)
  }

  private var instructionLines: [String] {
    splitLines(recipe.instructions)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
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

        if !ingredientLines.isEmpty {
          VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
              .font(.title3.weight(.semibold))
              .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 12) {
              ForEach(Array(ingredientLines.enumerated()), id: \.offset) { index, line in
                Text(line)
                  .font(.body)
                  .foregroundStyle(.primary)

                if index != ingredientLines.count - 1 {
                  Divider()
                }
              }
            }
            .padding()
            .card()
          }
        }

        if !instructionLines.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
              .font(.title3.weight(.semibold))
            VStack(alignment: .leading, spacing: 20) {
              ForEach(Array(instructionLines.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .top) {
                  Text("\(index + 1)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .tintColor).contrastingForegroundColor())
                    .frame(width: 22, height: 22)
                    .background(
                      Circle()
                        .fill(.tint)
                    )

                  Text(line)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .card()
              }
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 22)
    }
    .darkPrimaryLightSecondaryBackgroundColor()
  }

  private func splitLines(_ text: String) -> [String] {
    text
      .split(whereSeparator: \.isNewline)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
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
    return try database.read { db in
      return try! Recipe.limit(1).fetchAll(db).first!
    }
  }

  NavigationStack {
    RecipeDetailView(recipe: sample)
  }
}
