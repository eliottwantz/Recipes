# Add Optional Recipe Fields

## Why
Users need to capture additional context beyond core recipe details. Supporting optional notes for personal annotations, nutrition information for dietary tracking, source website URLs for attribution, and photos for visual reference will make recipes more useful and complete.

## What Changes
- Add four optional fields to the `Recipe` model:
  - `notes` (String?) - User-editable personal annotations
  - `nutrition` (String?) - Nutrition information (free-form text)
  - `website` (String?) - Source URL for attribution
  - `photos` (Array of photo references) - Visual imagery
- Update database schema to include these new columns
- Extend import flow to optionally populate `website` from source URL and `nutrition` from JSON-LD when available
- Update recipe detail view to display these optional fields when present
- Extend recipe edit screen to allow editing all optional fields

## Impact
- Affected specs: `persist-recipes`, `import-recipes`, `browse-recipes`
- Affected code:
  - `Storage/Schema.swift` - Add new columns to `Recipe` table
  - `Shared/Model/RecipeDetails.swift` - Update model to include optional fields
  - `Shared/Views/RecipeImport/RecipeImportManager.swift` - Populate optional fields during import
  - `Recipes/Views/Recipe/RecipeDetail/RecipeDetailView.swift` - Display optional fields
  - `Shared/Views/RecipeEditFormView.swift` - Add editors for optional fields
