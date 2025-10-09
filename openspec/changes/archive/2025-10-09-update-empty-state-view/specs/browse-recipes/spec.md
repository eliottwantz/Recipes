## MODIFIED Requirements
### Requirement: List All Recipes
The app MUST provide a SwiftUI view that lists every stored recipe using the shared SQLiteData database connection.
#### Scenario: Handle empty recipe set
- **GIVEN** no recipes exist in the `recipes` table
- **WHEN** the recipe list view appears
- **THEN** the recipe list view MUST render a SwiftUI `ContentUnavailableView` with copy that explains no recipes are available
- **AND** the `ContentUnavailableView` MUST remain visible until at least one recipe exists
