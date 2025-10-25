import CloudKit
import Dependencies
import Foundation
import SQLiteData

enum StorageBootstrap {
  static func configure() {
    prepareDependencies {
      do {
        $0.defaultDatabase = try appDatabase()
      } catch {
        assertionFailure("Failed to configure database: \(error)")
      }
      #if !targetEnvironment(simulator)
        $0.defaultSyncEngine = try! SyncEngine(
          for: $0.defaultDatabase,
          tables: Recipe.self,
        )
      #endif
    }
  }

  static func configurePreview() {
    prepareDependencies {
      do {
        $0.defaultDatabase = try appDatabase()
      } catch {
        print("Failed to configure preview database: \(error)")
      }
    }
  }

  static func configurePreviewWithInitialFetcher<T>(
    _ fetcher: (_ database: any DatabaseWriter) throws -> T
  ) -> T {
    let result: T = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
      return try! fetcher($0.defaultDatabase)
    }
    return result
  }

  static private func appDatabase() throws -> any DatabaseWriter {
    try SharedStorageBootstrap.makeDatabase()
  }
}
