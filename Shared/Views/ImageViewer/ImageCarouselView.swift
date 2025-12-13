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
  }
}
