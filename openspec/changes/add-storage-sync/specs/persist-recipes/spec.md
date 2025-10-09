## ADDED Requirements
### Requirement: Prepare Local Recipe Database
The app MUST provision and migrate a SQLite file that stores recipe records before any recipe data is accessed.
#### Scenario: App launch prepares database file
- **GIVEN** the app launches with a writable application support directory
- **WHEN** the storage layer initializes
- **THEN** it MUST invoke SQLiteData's `defaultDatabase(path:configuration:)` (or equivalent helper) to create or migrate the SQLite file named `Recipes.sqlite`
- **AND** the configuration MUST use `prepareDatabase` to run migrations that ensure a `recipes` table exists with columns for id, title, summary, ingredients, instructions, prepTimeMinutes, cookTimeMinutes, servings, createdAt, and updatedAt

### Requirement: Configure CloudKit Sync Engine
The storage layer MUST keep local recipe changes synchronized with CloudKit using SQLiteData's synchronization primitives.
#### Scenario: Sync engine starts on launch
- **GIVEN** iCloud is available for the signed-in user
- **WHEN** the storage layer finishes preparing the database
- **THEN** it MUST initialize a SQLiteData `SyncEngine` using the shared CloudKit container identifier defined in `Recipes.entitlements`
- **AND** the engine MUST start syncing the `recipes` table with a matching CloudKit custom zone

### Requirement: Provide Recipe Domain Model
The persistence layer MUST expose a strongly typed `Recipe` value with durable identifiers and timestamps for use across the app.
#### Scenario: Storage exposes Recipe model
- **GIVEN** views or services need recipe data
- **WHEN** they fetch from the storage layer
- **THEN** they MUST receive a `Recipe` value struct with properties matching the `recipes` table columns, including stable UUID identifiers and ISO-8601 timestamps
- **AND** the model MUST conform to `Sendable` so it is safe to use across Swift concurrency boundaries
