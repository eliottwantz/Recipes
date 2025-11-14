# import-recipes Specification

## Purpose
TBD - created by archiving change add-recipe-import-manager. Update Purpose after archive.
## Requirements
### Requirement: Fetch Recipe Source HTML
The app MUST provide a service that downloads the raw HTML for a user-supplied recipe URL.

#### Scenario: Successful download
- **GIVEN** a valid HTTPS recipe URL that responds with status 200 and `text/html` content
- **WHEN** the `RecipeImportManager` (or equivalent dedicated service) imports that URL
- **THEN** it MUST issue a single HTTP GET request to fetch the HTML bytes
- **AND** it MUST surface a recoverable error if the download fails (network error or non-2xx status)

### Requirement: Parse Recipe JSON-LD
The import service MUST scan downloaded HTML for JSON-LD script tags and keep only objects whose `@type` includes `Recipe`.

#### Scenario: Extract recipe nodes
- **GIVEN** the downloaded HTML contains one or more `<script type="application/ld+json">` nodes with arrays of objects
- **WHEN** the service parses those nodes
- **THEN** it MUST decode JSON objects and filter to the first object whose `@type` (string or array) includes `Recipe`
- **AND** it MUST ignore malformed JSON-LD blobs without failing the entire import unless all blobs are invalid

### Requirement: Store Imported Recipe
The import service MUST normalize the JSON-LD fields into the app's `Recipe` model and return the extracted details to the caller for review before persistence.

#### Scenario: Return extracted recipe for user review
- **GIVEN** the JSON-LD recipe provides `name`, `description`, `recipeIngredient`, optional `recipeInstructions`, `prepTime`, `cookTime`, and `recipeYield`
- **WHEN** the service maps the data
- **THEN** it MUST create a new `Recipe` with a generated UUID, title from `name`, summary from `description`, ordered ingredient lines from `recipeIngredient`, and ordered instruction steps from `recipeInstructions`
- **AND** each ingredient line and instruction step MUST be trimmed, prepared as `RecipeIngredient` or `RecipeInstruction` with zero-based sequential `position` values linked to the recipe id
- **AND** it MUST convert ISO8601 duration strings (`prepTime`, `cookTime`) into minute counts when present
- **AND** it MUST capture the source URL as the `website` field for attribution
- **AND** it MUST extract nutrition information from the JSON-LD `nutrition` field when present and store as free-form text
- **AND** it MUST initialize `notes` as nil (empty) for new imports
- **AND** it MUST return the `ExtractedRecipeDetail` containing the recipe and its structured collections without persisting, allowing the caller to present the data for review

#### Scenario: Persist confirmed recipe after user edits
- **GIVEN** the user has reviewed and optionally edited an `ExtractedRecipeDetail`
- **WHEN** the user confirms the save action
- **THEN** the import screen MUST call the `RecipeImportManager.persist` method with the edited details
- **AND** the manager MUST store the recipe via the shared SQLiteData writer, inserting the `Recipe` and its associated `RecipeIngredient`, `RecipeInstruction`, and any `RecipePhoto` records in a single transaction

### Requirement: Review and Edit Extracted Recipe
The import screen MUST allow users to review and edit extracted recipe details before persisting them to storage.

#### Scenario: Display extracted recipe for editing
- **GIVEN** the `RecipeImportManager` has successfully extracted a recipe from a URL
- **WHEN** extraction completes
- **THEN** the import screen MUST transition to an edit phase showing the extracted recipe details
- **AND** it MUST display editable fields for title, summary, prep time (minutes), cook time (minutes), servings, notes, nutrition, and website
- **AND** it MUST display the list of ingredients with their text and position
- **AND** it MUST display the list of instructions with their text and position
- **AND** it MUST display the photo gallery when photos are present

#### Scenario: Edit recipe metadata
- **GIVEN** the user is viewing the recipe edit screen
- **WHEN** the user modifies the title, summary, prep time, cook time, servings, notes, nutrition, or website fields
- **THEN** the screen MUST update the corresponding field in the `ExtractedRecipeDetail`
- **AND** changes MUST be reflected immediately in the edit view

#### Scenario: Edit photo collection
- **GIVEN** the user is viewing the recipe edit screen
- **WHEN** the user adds a photo via the photo picker
- **THEN** the screen MUST append a new `RecipePhoto` with the next sequential position
- **AND WHEN** the user removes a photo
- **THEN** the screen MUST remove it and reindex remaining photos' positions sequentially
- **AND WHEN** the user reorders photos via drag-and-drop
- **THEN** the screen MUST update each photo's `position` to reflect the new order

