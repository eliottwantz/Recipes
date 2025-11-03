## Why
- Ingredients and instruction steps are persisted as newline-delimited blobs, so we lose ordering metadata and cannot represent grouped or multi-line entries without brittle parsing.
- Import and share flows already operate on arrays, forcing lossy joins and splits that leak whitespace handling details across modules.
- Normalizing these collections unlocks richer editing scenarios (reordering, grouping) and avoids future migrations when we add structured fields like headings or timers.

## What Changes
- Rework the SQLite schema to move ingredient lines and instruction steps into dedicated child tables keyed by recipe id with stable sort positions.
- Update the `Recipe` domain model and data access layer to surface `[IngredientLine]` and `[InstructionStep]` collections that preserve authoring order and trimmed text.
- Adjust import and share pipelines to map JSON-LD and text input directly into the structured storage, including migration of existing newline data on first launch.

## Impact
- Allows us to reset the development database schema without worrying about legacy data, so we can delete the old newline fields outright.
- Touches app, shared import module, and share extension, so coordination across targets is necessary but the UI layout stays largely unchanged.
- Increases work needed for local persistence tests and sample data, but improves future extensibility and reduces parsing bugs.
