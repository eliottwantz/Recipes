## Why

Users need to review and correct extracted recipe details before saving, as automated parsing from web HTML can produce incomplete or incorrect metadata (missing servings, wrong times, malformed ingredient lists). Currently the `RecipeImportScreen` immediately persists imported recipes without giving users a chance to verify or edit them.

## What Changes

- Add an intermediate edit phase to `RecipeImportScreen` after extraction completes, allowing users to review and modify the extracted recipe details before persisting.
- Provide UI controls for editing title, summary, prep time, cook time, and servings fields.
- Enable full editing of ingredient and instruction lists: modify text, add new items, delete items, and reorder via drag-and-drop.
- Transition from `.success` phase to the edit view, then persist only after user confirms the edits.

## Impact

- Affected specs: `import-recipes` (adds review and editing requirement)
- Affected code: `Shared/RecipeImport/RecipeImportScreen.swift` (new edit view and phase), `Shared/RecipeImport/RecipeImportManager.swift` (return extraction result without immediate persistence)
- **BREAKING**: `RecipeImportManager.importRecipe` currently persists immediately; we will refactor to return `ExtractedRecipeDetail` without saving, deferring persistence until user confirms edits
