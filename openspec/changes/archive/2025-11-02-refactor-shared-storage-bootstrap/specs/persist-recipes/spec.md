## MODIFIED Requirements
### Requirement: Prepare Local Recipe Database
The storage layer MUST expose a single bootstrap API that provisions and migrates the shared SQLiteData database so every Recipes target configures storage through the same code path.

#### Scenario: App launch prepares database file
- **GIVEN** the app launches with a writable application support directory
- **WHEN** the storage layer initializes via the shared bootstrap API
- **THEN** it MUST invoke SQLiteData's `defaultDatabase(path:configuration:)` (or equivalent helper) to create or migrate the SQLite file named `Recipes.sqlite`
- **AND** the configuration MUST use `prepareDatabase` to run migrations that ensure a `recipes` table exists with columns for id, title, summary, ingredients, instructions, prepTimeMinutes, cookTimeMinutes, servings, createdAt, and updatedAt

#### Scenario: Extension reuses bootstrap
- **GIVEN** a Recipes extension or widget target needs database access
- **WHEN** it initializes storage
- **THEN** it MUST call the same shared bootstrap API used by the main app instead of defining its own SQLite configuration or migrations
- **AND** the bootstrap MUST return a database writer pointed at the app group container so extensions persist data into the same file

## ADDED Requirements
### Requirement: Provide Shared Storage Metadata
The storage layer MUST own the app group identifier and database filename constants so all targets import them from a single storage-focused source-of-truth.

#### Scenario: Resolve shared container identifier
- **GIVEN** any Recipes target needs the shared container URL
- **WHEN** it requests the app group identifier or database filename
- **THEN** it MUST retrieve those values from the storage layer's shared metadata API
- **AND** no other module MUST define duplicate identifiers or filenames for the shared database
