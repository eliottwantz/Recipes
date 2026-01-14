//
//  SecureStorage.swift
//  Recipes
//
//  Created by Eliott on 2025-01-14.
//

import Foundation
import Security

enum SecureStorage {
  private static let service = Constants.bundleID

  enum Key: String {
    case videoRecipeAPIKey = "video_recipe_api_key"
  }

  enum SecureStorageError: Error {
    case encodingFailed
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
  }

  static func save(_ value: String, for key: Key) throws {
    guard let data = value.data(using: .utf8) else {
      throw SecureStorageError.encodingFailed
    }

    // First, try to delete any existing item
    try? delete(key)

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw SecureStorageError.saveFailed(status)
    }
  }

  static func get(_ key: Key) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess,
      let data = result as? Data,
      let string = String(data: data, encoding: .utf8)
    else {
      return nil
    }

    return string
  }

  static func delete(_ key: Key) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key.rawValue,
    ]

    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw SecureStorageError.deleteFailed(status)
    }
  }

  static func hasValue(for key: Key) -> Bool {
    get(key) != nil
  }
}
