## MODIFIED Requirements
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

### Requirement: Provide Recipe Domain Model
The persistence layer MUST expose a strongly typed `Recipe` value with durable identifiers and timestamps for use across the app.
#### Scenario: Storage exposes structured recipe model
- **GIVEN** views or services need recipe data
- **WHEN** they fetch from the storage layer
- **THEN** they MUST receive a `Recipe` value struct that includes ordered `ingredients` and `instructions` collections, each providing trimmed line text and stable ordering metadata
- **AND** the model MUST conform to `Sendable` so it is safe to use across Swift concurrency boundaries
- **AND** the collections MUST be hydrated from the structured tables and never rely on newline splitting at the call site
