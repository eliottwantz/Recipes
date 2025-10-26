## Tasks

- [ ] Implement a destructive SQLite migration that recreates the `recipes` table without the legacy newline columns and adds fresh `recipe_ingredients` and `recipe_instructions` tables keyed by recipe id.
- [ ] Update the persistence layer to map `Recipe` with `[IngredientLine]` and `[InstructionStep]`, ensuring fetches and writes keep items ordered by `position`.
- [ ] Adjust the app and share extension flows (detail view, editors, import manager) to work exclusively with the structured collections.
- [ ] Remove any joins/splits on newline text and purge the legacy `ingredients`/`instructions` string columns from models, persistence helpers, and fixtures.
- [ ] Validate with `openspec validate refactor-structured-recipe-content --strict` and `xcodebuild -scheme Recipes -destination 'platform=iOS Simulator,name=iPhone 16' build | xcbeautify`.
