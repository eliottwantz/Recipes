# persist-recipes Specification

## Purpose
TBD - created by archiving change add-storage-sync. Update Purpose after archive.
## Requirements
### Requirement: Prepare Local Recipe Database
The app MUST provision and migrate a SQLite file that stores recipe records before any recipe data is accessed.
#### Scenario: App launch prepares database with structured recipe tables
- **GIVEN** the app launches with a writable application support directory
- **WHEN** the storage layer initializes
- **THEN** it MUST invoke SQLiteData's `defaultDatabase(path:configuration:)` (or equivalent helper) to create or migrate the SQLite file named `Recipes.sqlite`
- **AND** the migration MUST ensure the following tables exist:
  - `recipes` with columns for id, title, summary, prepTimeMinutes, cookTimeMinutes, servings, createdAt, and updatedAt
  - `recipe_ingredients` with columns for id, recipeId, position, and text, with a foreign key to `recipes.id` and uniqueness on `(recipeId, position)`
  - `recipe_instructions` with columns for id, recipeId, position, and text, with a foreign key to `recipes.id` and uniqueness on `(recipeId, position)`

### Requirement: Configure CloudKit Sync Engine
The storage layer MUST keep local recipe changes synchronized with CloudKit using SQLiteData's synchronization primitives.
#### Scenario: Sync engine starts on launch
- **GIVEN** iCloud is available for the signed-in user
- **WHEN** the storage layer finishes preparing the database
- **THEN** it MUST initialize a SQLiteData `SyncEngine` using the shared CloudKit container identifier defined in `Recipes.entitlements`
- **AND** the engine MUST start syncing the `recipes` table with a matching CloudKit custom zone

### Requirement: Provide Recipe Domain Model
The persistence layer MUST expose a strongly typed `Recipe` value with durable identifiers and timestamps for use across the app.
#### Scenario: Storage exposes structured recipe model
- **GIVEN** views or services need recipe data
- **WHEN** they fetch from the storage layer
- **THEN** they MUST receive a `Recipe` value struct that includes ordered `ingredients` and `instructions` collections, each providing trimmed line text and stable ordering metadata
- **AND** the model MUST conform to `Sendable` so it is safe to use across Swift concurrency boundaries
- **AND** the collections MUST be hydrated from the structured tables and never rely on newline splitting at the call site

### Requirement: Provide Shared Storage Metadata
The storage layer MUST own the app group identifier and database filename constants so all targets import them from a single storage-focused source-of-truth.

#### Scenario: Resolve shared container identifier
- **GIVEN** any Recipes target needs the shared container URL
- **WHEN** it requests the app group identifier or database filename
- **THEN** it MUST retrieve those values from the storage layer's shared metadata API
- **AND** no other module MUST define duplicate identifiers or filenames for the shared database

