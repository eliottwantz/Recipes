//
//  URL+Extension.swift
//  Recipes
//
//  Created by Eliott on 21-11-2025.
//

import Foundation

extension URL: @retroactive Identifiable {
    public var id: URL { self }
}
