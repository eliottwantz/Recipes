## ADDED Requirements
### Requirement: List All Recipes
The app MUST provide a SwiftUI view that lists every stored recipe using the shared SQLiteData database connection.

#### Scenario: Display persisted recipes
- **GIVEN** one or more recipes exist in the `recipes` table
- **WHEN** the recipe list view appears
- **THEN** it MUST fetch all `Recipe` records from the default database writer configured by storage bootstrap
- **AND** display them in a scrollable list showing each recipe's title and summary
- **AND** order the rows by most recently updated first so newer content surfaces at the top

#### Scenario: Handle empty recipe set
- **GIVEN** no recipes exist in the `recipes` table
- **WHEN** the recipe list view appears
- **THEN** it MUST render a friendly empty state message instead of an empty list
