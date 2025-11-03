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
The import service MUST normalize the JSON-LD fields into the app's `Recipe` model and persist it using the default database connection.

#### Scenario: Persist mapped recipe into structured storage
- **GIVEN** the JSON-LD recipe provides `name`, `description`, `recipeIngredient`, optional `recipeInstructions`, `prepTime`, `cookTime`, and `recipeYield`
- **WHEN** the service maps the data
- **THEN** it MUST create a new `Recipe` with a generated UUID, title from `name`, summary from `description`, ordered ingredient lines from `recipeIngredient`, and ordered instruction steps from `recipeInstructions`
- **AND** each ingredient line and instruction step MUST be trimmed, inserted into `recipe_ingredients` or `recipe_instructions` with zero-based sequential `position` values and linked to the recipe id
- **AND** it MUST convert ISO8601 duration strings (`prepTime`, `cookTime`) into minute counts when present
- **AND** it MUST store the recipe via the shared SQLiteData writer, returning the saved `Recipe` with its structured collections so callers can present it

