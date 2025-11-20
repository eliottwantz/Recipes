//
//  Button+Style.swift
//  Recipes
//
//  Created by Eliott on 2025-11-14.
//

import SwiftUI

struct ToolbarButtonStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(width: 48, height: 48)
      .font(.system(size: 22))
      .tint(.primary)
      .labelStyle(.iconOnly)
      .glassEffect(.regular.interactive(), in: .circle)
      .onTapGesture {
        configuration.trigger()
      }
      .contentShape(.circle)
  }
}

#Preview {
  VStack {
    Button {
      print("Tapped")
    } label: {
      Label("Add", systemImage: "plus")
    }
    .buttonStyle(.bordered)

    Button {
      print("Tapped")
    } label: {
      Label("Add", systemImage: "plus")
    }
    .buttonStyle(.toolbar)
  }
}

extension PrimitiveButtonStyle where Self == ToolbarButtonStyle {
  static var toolbar: ToolbarButtonStyle { ToolbarButtonStyle() }
}
