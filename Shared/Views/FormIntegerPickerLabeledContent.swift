//
//  FormIntegerPickerLabeledContent.swift
//  Recipes
//
//  Created by Eliott on 2025-11-09.
//

import SwiftUI

struct FormIntegerPickerLabeledContent: View {
  let labelText: String
  @Binding var amount: Int

  @State private var isPresented = false

  init(_ labelText: String, amount: Binding<Int>) {
    self.labelText = labelText
    self._amount = amount

  }

  var body: some View {
    LabeledContent(labelText) {
      Button {
        isPresented.toggle()
      } label: {
        Text("\(amount)")
      }
    }
    .popover(isPresented: $isPresented, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
      AmountPicker(labelText, amount: $amount)
        .presentationCompactAdaptation(.none)
    }
  }
}

private struct AmountPicker: View {
  let titleKey: String
  @Binding var amount: Int

  init(_ titleKey: String, amount: Binding<Int>) {
    self.titleKey = titleKey
    self._amount = amount
  }

  var body: some View {
    Picker(titleKey, selection: $amount) {
      ForEach((0...500), id: \.self) { value in
        Text("\(value)")
          .tag(value)
      }
    }
    #if os(iOS)
      .pickerStyle(.wheel)
    #endif
    .clipped()
  }
}

#Preview {
  @Previewable @State var servings = 2
  AmountPicker(
    "Servings",
    amount: $servings
  )
}

#Preview {
  @Previewable @State var servings = 2
  Form {
    FormIntegerPickerLabeledContent(
      "Servings", amount: $servings
    )
  }
}
