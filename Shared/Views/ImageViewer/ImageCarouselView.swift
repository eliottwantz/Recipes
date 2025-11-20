//
//  ImageCarouselView.swift
//  Recipes
//
//  Created by Eliott on 2025-11-20.
//

import SwiftUI

struct ImageCarouselView: View {
  let photos: [RecipePhoto]
  @Binding var selectedPhotoID: UUID?

  var body: some View {
    #if os(iOS)
      TabView(selection: $selectedPhotoID) {
        ForEach(photos) { photo in
          ZoomableImageView(imageData: photo.photoData)
            .tag(photo.id)
            .ignoresSafeArea()
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .always))
      .ignoresSafeArea()
      .background(.black)
    #elseif os(macOS)
      ZStack {
        if let selectedPhoto = photos.first(where: { $0.id == selectedPhotoID }) {
          ZoomableImageView(imageData: selectedPhoto.photoData)
            .id(selectedPhoto.id)
            .transition(.opacity)
        }
      }
      .background(.black)
      .focusable()
      .focusEffectDisabled()
      .onKeyPress(.leftArrow) {
        navigate(direction: .backward)
        return .handled
      }
      .onKeyPress(.rightArrow) {
        navigate(direction: .forward)
        return .handled
      }
      .onAppear {
        // Ensure the view can receive focus for key presses
        DispatchQueue.main.async {
          NSApp.keyWindow?.makeFirstResponder(nil)
        }
      }
    #endif
  }

  #if os(macOS)
    private enum Direction {
      case forward, backward
    }

    private func navigate(direction: Direction) {
      guard let currentID = selectedPhotoID,
        let currentIndex = photos.firstIndex(where: { $0.id == currentID })
      else { return }

      let newIndex = currentIndex + direction
      if newIndex >= 0 && newIndex < photos.count {
        withAnimation {
          selectedPhotoID = photos[newIndex].id
        }
      }
    }
  #endif
}
