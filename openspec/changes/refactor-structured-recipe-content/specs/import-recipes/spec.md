## MODIFIED Requirements
### Requirement: Store Imported Recipe
The import service MUST normalize the JSON-LD fields into the app's `Recipe` model and persist it using the default database connection.

#### Scenario: Persist mapped recipe into structured storage
- **GIVEN** the JSON-LD recipe provides `name`, `description`, `recipeIngredient`, optional `recipeInstructions`, `prepTime`, `cookTime`, and `recipeYield`
- **WHEN** the service maps the data
- **THEN** it MUST create a new `Recipe` with a generated UUID, title from `name`, summary from `description`, ordered ingredient lines from `recipeIngredient`, and ordered instruction steps from `recipeInstructions`
- **AND** each ingredient line and instruction step MUST be trimmed, inserted into `recipe_ingredients` or `recipe_instructions` with zero-based sequential `position` values and linked to the recipe id
- **AND** it MUST convert ISO8601 duration strings (`prepTime`, `cookTime`) into minute counts when present
- **AND** it MUST store the recipe via the shared SQLiteData writer, returning the saved `Recipe` with its structured collections so callers can present it
