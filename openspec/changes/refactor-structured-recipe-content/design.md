## Overview
We will retire the newline-delimited `ingredients` and `instructions` text fields in `Recipe` in favor of normalized child tables so every ingredient line and instruction step is persisted separately with ordering metadata. The app and share extension will consume strongly typed arrays, avoiding the current round-tripping between `[String]` and joined text blobs.

## Data Model
- Keep the `recipes` table focused on recipe metadata: id, title, summary, prep/cook durations, servings, timestamps.
- Introduce `recipe_ingredients` with columns: `id` (UUID, PK), `recipeId` (FK to recipes.id), `position` (INTEGER), `text` (TEXT). Unique index on `(recipeId, position)` enforces ordering without duplicates.
- Introduce `recipe_instructions` with the same shape for instruction steps. Future optional columns (e.g., `headline`, `timerSeconds`) can be added without touching the parent row.
- Update `Recipe` to expose `ingredients: [IngredientLine]` and `instructions: [InstructionStep]` where each type is a lightweight struct wrapping the string plus the position. Accessors will guarantee stable ordering based on `position`.

## Schema Rollout
- Because we are still in development with disposable data, we can ship a destructive migration that recreates the relevant tables with their new shapes.
- The `recipes` table will drop the legacy newline fields entirely in favor of the normalized child tables.

## Parsing & APIs
- `RecipeImportPipeline` already returns `[String]`, so persistence can insert lines directly into the new tables without joining.
- Shared `RecipeDraft` will load from the structured arrays and only expose `ingredientsText`/`instructionsText` as computed helpers for text area bindings.
- Data fetchers will perform joined queries (e.g., `Recipe` + `recipe_ingredients` ordered by `position`) and assemble the domain model before handing it to SwiftUI views.

## Risks & Mitigations
- **Schema reset safety**: Gate the destructive migration behind a feature flag or development-only build step to avoid wiping data once we approach a production launch.
- **Performance**: Batched fetches (single query per recipe with `GROUP_CONCAT` or manual joins) keep the detail view responsive; caching can evolve later if profiling shows issues.
- **Backward compatibility**: Since both app and extension ship together, we can migrate eagerly at launch and avoid format drift.
