## ADDED Requirements

### Requirement: Share Extension Imports Recipes
The app MUST ship a share extension that accepts recipe webpage shares from the system share sheet and builds a recipe draft using the shared JSON-LD pipeline without re-fetching the page.

#### Scenario: Import from Safari share
- **GIVEN** the user shares an HTTPS recipe URL from Safari whose HTML contains an `application/ld+json` node with `@type` including `Recipe`
- **WHEN** the share extension loads the selected item
- **THEN** it MUST extract the provided HTML payload from the Safari share (including results returned by the JavaScript preprocessing script) and invoke the same JSON-LD parser used by the `RecipeImportManager`
- **AND** it MUST display the resulting recipe draft in a SwiftUI view showing title, summary, ingredients, instructions, prep time, cook time, and servings within the share sheet context

#### Scenario: Report unsupported input
- **GIVEN** the share extension receives a shared item without usable HTML content or the JSON-LD parser throws an error
- **WHEN** the processing completes
- **THEN** the extension MUST present an inline error message with Retry and Cancel controls instead of failing silently
- **AND** it MUST dismiss itself when the user cancels from that state

### Requirement: Review and Persist Shared Recipes
The share extension MUST allow the user to adjust the extracted recipe and either save it to the shared database or cancel without side effects.

#### Scenario: Save edited recipe
- **GIVEN** the extension has rendered a recipe draft
- **WHEN** the user edits any fields and taps Save
- **THEN** the extension MUST persist the edited fields into the shared SQLiteData database writer located in the app group container using the same schema as the main app
- **AND** it MUST close the share sheet after persistence succeeds so the recipe appears in the main app list the next time it foregrounds

#### Scenario: Cancel import
- **GIVEN** the extension has rendered a recipe draft
- **WHEN** the user taps Cancel
- **THEN** the extension MUST exit without writing to the database or leaving partial data behind
