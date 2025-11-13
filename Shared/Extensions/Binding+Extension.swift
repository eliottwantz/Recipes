//
//  Binding+Extension.swift
//  Recipes
//
//  Created by Eliott on 2025-11-13.
//

import SwiftUI

extension Binding {
  init(_ source: Binding<String?>, default defaultValue: String = "") where Value == String {
    self.init(
      get: { source.wrappedValue ?? defaultValue },
      set: { source.wrappedValue = $0.isEmpty ? nil : $0 }
    )
  }
}
