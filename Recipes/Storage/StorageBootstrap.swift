import CloudKit
import Dependencies
import Foundation
import OSLog
import SQLiteData

enum StorageBootstrap {
    static func configure() {
        do {
            try prepareDependencies { values in
                try values.bootstrapStorage()
            }
        } catch {
            assertionFailure("Failed to configure storage: \(error)")
        }
    }
}

private enum CloudKitConfiguration {
    static let containerIdentifier = "iCloud.com.develiott.Recipes"
}

extension DependencyValues {
    fileprivate mutating func bootstrapStorage() throws {
        defaultDatabase = try RecipesDatabase.makeDatabase(
            containerIdentifier: CloudKitConfiguration.containerIdentifier
        )
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            defaultSyncEngine = try SyncEngine(
                for: defaultDatabase,
                tables: Recipe.self,
                containerIdentifier: CloudKitConfiguration.containerIdentifier
            )
        }
    }
}

private enum RecipesDatabase {
    static func makeDatabase(containerIdentifier: String) throws -> any DatabaseWriter {
        @Dependency(\.context) var context
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        configuration.prepareDatabase { db in
            try db.attachMetadatabase(containerIdentifier: containerIdentifier)
        }

        #if DEBUG
            configuration.prepareDatabase { db in
                db.trace(options: .profile) {
                    if context == .preview {
                        print("\($0.expandedDescription)")
                    } else {
                        logger.debug("\($0.expandedDescription)")
                    }
                }
            }
        #endif

        let databasePath: String?
        if context == .live {
            databasePath =
                URL.applicationSupportDirectory.appendingPathComponent("Recipes.sqlite").path
        } else {
            databasePath = nil
        }

        let database = try SQLiteData.defaultDatabase(
            path: databasePath,
            configuration: configuration
        )
        logger.info("DB path:\n\(database.path)")

        var migrator = DatabaseMigrator()
        #if DEBUG
            migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("Create recipes table") { db in
            try #sql(
                """
                CREATE TABLE "recipes" (
                    "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
                    "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                    "summary" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                    "ingredients" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                    "instructions" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                    "prepTimeMinutes" INTEGER,
                    "cookTimeMinutes" INTEGER,
                    "servings" INTEGER,
                    "createdAt" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
                    "updatedAt" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
                ) STRICT
                """
            ).execute(db)
        }
        try migrator.migrate(database)
        return database
    }
}

nonisolated private let logger = Logger(subsystem: "Recepies", category: "Database")
