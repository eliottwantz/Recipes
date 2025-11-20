//
//  RecipeDetailScreen.swift
//  Recipes
//
//  Created by Eliott on 2025-11-09.
//

import Dependencies
import SQLiteData
import SwiftUI

struct RecipeDetailView: View {
  let recipeDetails: RecipeDetails
  @State private var selectedRecipePhoto: RecipePhoto?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        if let notes = recipeDetails.recipe.notes, !notes.isEmpty {
          notesSection
        }

        if !recipeDetails.ingredients.isEmpty {
          ingredientsSection
        }

        if !recipeDetails.instructions.isEmpty {
          instructionsSection
        }

        if !recipeDetails.photos.isEmpty {
          photosSection
        }

        if let nutrition = recipeDetails.recipe.nutrition, !nutrition.isEmpty {
          nutritionSection
        }

      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 10)
      .padding(.bottom, 10)
    }
    .darkPrimaryLightSecondaryBackgroundColor()
    .fullScreenCover(item: $selectedRecipePhoto) { photo in
      NavigationStack {
        ZoomableImageView(imageData: photo.photoData)
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Button {
                selectedRecipePhoto = nil
              } label: {
                Label("Close", systemImage: "xmark")
              }
            }
          }
      }
      .presentationBackground(.black)
      #if os(iOS)
        .statusBarHidden()
      #endif
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      titleCover

      HStack(alignment: .center) {
        HStack(spacing: 8) {
          Image(systemName: "person.2")
            .foregroundStyle(.tint)
          VStack(alignment: .leading, spacing: 4) {
            Text("\(recipeDetails.recipe.servings)")
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
            TimeView(totalMinutes: recipeDetails.recipe.prepTimeMinutes)
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
            TimeView(totalMinutes: recipeDetails.recipe.cookTimeMinutes)
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

  private var titleCover: some View {
    Group {
      if let firstPhoto = recipeDetails.photos.first,
        let uiImage = UIImage(data: firstPhoto.photoData)
      {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFill()
          .frame(height: 220)
          .frame(maxWidth: .infinity)
          .clipped()
          .clipShape(RoundedRectangle(cornerRadius: 20))
          .overlay {
            RoundedRectangle(cornerRadius: 20)
              .fill(Color.black.opacity(0.25))
          }
          .overlay(alignment: .topLeading) {
            Text(recipeDetails.recipe.name)
              .font(.title.weight(.bold))
              .foregroundStyle(.white)
              .shadow(radius: 2)
              .padding(16)
          }
          .overlay(alignment: .bottomLeading) {
            if let website = recipeDetails.recipe.website,
              let url = URL(string: website),
              let host = url.host
            {
              Link(destination: url) {
                HStack(spacing: 8) {
                  Image(systemName: "safari")
                    .foregroundStyle(.white)
                  Text(host)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
              }
              .padding(16)
            }
          }
          .onTapGesture {
            // TODO: Open WebView with the selected URL if exists, otherwise open ImageCarousel viewer
          }
      } else {
        Text(recipeDetails.recipe.name)
          .font(.largeTitle.weight(.bold))
          .foregroundStyle(.primary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private var ingredientsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Ingredients")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)

      VStack(alignment: .leading, spacing: 12) {
        ForEach(Array(recipeDetails.ingredients.enumerated()), id: \.element.id) { index, line in
          Text(line.text)
            .font(.body)
            .foregroundStyle(.primary)

          if index != recipeDetails.ingredients.count - 1 {
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
        ForEach(Array(recipeDetails.instructions.enumerated()), id: \.element.id) { index, step in
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

  private var websiteSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Source")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)

      if let website = recipeDetails.recipe.website, let url = URL(string: website) {
        Link(destination: url) {
          HStack {
            Image(systemName: "safari")
              .foregroundStyle(.tint)
            Text(website)
              .font(.body)
              .foregroundStyle(.tint)
              .lineLimit(2)
            Spacer()
            Image(systemName: "arrow.up.right")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding()
          .card()
        }
      }
    }
  }

  private var nutritionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Nutrition")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)

      Text(recipeDetails.recipe.nutrition ?? "")
        .font(.body)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .card()
    }
  }

  private var notesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Notes")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)

      Text(recipeDetails.recipe.notes ?? "")
        .font(.body)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .card()
    }
  }

  private var photosSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Photos")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(Array(recipeDetails.photos.enumerated()), id: \.offset) { index, photo in
            if let uiImage = UIImage(data: photo.photoData) {
              Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onTapGesture {
                  selectedRecipePhoto = photo
                }
            }
          }
        }
      }
    }
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
  let recipeDetails = Storage.configure { database in
    return try database.read { db in
      print("FETCHING RECIPE FOR PREVIEW")
      let recipe = try Recipe.all.fetchOne(db)
      guard let recipe else { fatalError("No recipe found. Seed the database first.") }
      let results = try RecipeDetails.FetchKeyRequest(recipeId: recipe.id).fetch(db)
      return RecipeDetails(
        recipe: recipe, ingredients: results.ingredients, instructions: results.instructions,
        photos: results.photos)
    }
  }

  NavigationStack {
    RecipeDetailView(recipeDetails: recipeDetails)
  }
}
