# browse-recipes Specification

## Purpose
TBD - created by archiving change add-recipe-list-view. Update Purpose after archive.
## Requirements
### Requirement: List All Recipes
The app MUST provide a SwiftUI view that lists every stored recipe using the shared SQLiteData database connection.
#### Scenario: Handle empty recipe set
- **GIVEN** no recipes exist in the `recipes` table
- **WHEN** the recipe list view appears
- **THEN** the recipe list view MUST render a SwiftUI `ContentUnavailableView` with copy that explains no recipes are available
- **AND** the `ContentUnavailableView` MUST remain visible until at least one recipe exists

### Requirement: Display Recipe Details
The app MUST present a dedicated view for an individual recipe that surfaces its core metadata, ingredient list, and cooking instructions.

#### Scenario: Show full recipe information
- **GIVEN** a recipe exists with title, servings count, prep time, cook time, ordered ingredients, and step-by-step instructions
- **WHEN** the user navigates to the recipe detail view for that recipe
- **THEN** the view MUST display the recipe title prominently at the top
- **AND** the view MUST show servings, prep time, and cook time in a concise metadata section
- **AND** the view MUST render the ingredient list as readable bullet points or similar structured layout
- **AND** the view MUST present the instructions in order, ensuring multi-step text remains legible
- **AND** the view MUST display the website as a tappable link when present
- **AND** the view MUST display the nutrition information section when present
- **AND** the view MUST display the notes section when present
- **AND** the view MUST display a photo gallery when photos are present
- **AND** optional fields MUST be hidden when empty to avoid clutter

