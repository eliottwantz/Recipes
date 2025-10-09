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

        let database: any DatabaseWriter
        if context == .live {
            database = try SQLiteData.defaultDatabase(
                path: URL.applicationSupportDirectory.appendingPathComponent("Recipes.sqlite").path,
                configuration: configuration
            )
        } else {
            database = try SQLiteData.defaultDatabase(
                configuration: configuration
            )
        }
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
        #if DEBUG
            migrator.registerMigration("Seed recipes") { db in
                try db.seed {
                    Recipe(
                        id: UUID(uuidString: "EB91BFAA-83E3-4E0C-B6DD-7F2C940FF23A")!,
                        title: "Heirloom Tomato Bruschetta",
                        summary: "Toasted baguette topped with juicy tomatoes, basil, and garlic.",
                        ingredients: """
                            1 baguette
                            2 cups diced heirloom tomatoes
                            2 cloves garlic, minced
                            6 fresh basil leaves, chopped
                            2 tbsp extra-virgin olive oil
                            Salt and pepper to taste
                            """,
                        instructions: """
                            Slice baguette and toast until golden.
                            Toss tomatoes, garlic, basil, and olive oil with salt and pepper.
                            Spoon tomato mixture over warm baguette slices and serve immediately.
                            """,
                        prepTimeMinutes: 15,
                        cookTimeMinutes: 5,
                        servings: 6
                    )
                    Recipe(
                        id: UUID(uuidString: "67B4819F-4B5A-46EA-AC6B-4A3AB473E2B6")!,
                        title: "Creamy Mushroom Risotto",
                        summary: "Classic risotto with sautéed cremini mushrooms and parmesan.",
                        ingredients: """
                            4 cups vegetable broth
                            1 cup arborio rice
                            8 oz cremini mushrooms, sliced
                            1 shallot, minced
                            2 cloves garlic, minced
                            1/2 cup dry white wine
                            1/2 cup grated parmesan
                            2 tbsp butter
                            2 tbsp olive oil
                            Salt and pepper to taste
                            """,
                        instructions: """
                            Warm broth in a saucepan over low heat.
                            Sauté mushrooms in olive oil until browned, remove and reserve.
                            Cook shallot and garlic in butter until fragrant, then stir in rice.
                            Deglaze with wine, stir until absorbed, then add broth one ladle at a time.
                            Fold in mushrooms and parmesan once rice is creamy and al dente.
                            Season to taste and serve hot.
                            """,
                        prepTimeMinutes: 10,
                        cookTimeMinutes: 30,
                        servings: 4
                    )
                    Recipe(
                        id: UUID(uuidString: "ACECF31E-986F-4B24-9F1E-E7C382773F19")!,
                        title: "Citrus Herb Roast Chicken",
                        summary: "Roasted chicken infused with lemon, orange, and fresh herbs.",
                        ingredients: """
                            1 whole chicken (4 lbs)
                            1 lemon, halved
                            1 orange, halved
                            4 sprigs fresh thyme
                            4 sprigs fresh rosemary
                            4 cloves garlic, smashed
                            2 tbsp olive oil
                            Salt and pepper to taste
                            """,
                        instructions: """
                            Preheat oven to 400°F (204°C).
                            Pat chicken dry, season cavity with salt and pepper, and stuff with citrus, herbs, and garlic.
                            Rub skin with olive oil, salt, and pepper.
                            Roast until internal temperature reaches 165°F, about 1 hour 10 minutes.
                            Rest chicken for 10 minutes before carving.
                            """,
                        prepTimeMinutes: 15,
                        cookTimeMinutes: 70,
                        servings: 6
                    )
                }
            }
        #endif
        try migrator.migrate(database)
        return database
    }
}

nonisolated private let logger = Logger(subsystem: "Recepies", category: "Database")
