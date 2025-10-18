## Why
- Users need a focused screen to read an individual recipe without scanning the full list.
- The list view alone does not surface servings, prep time, cook time, or step-by-step instructions.

## What Changes
- Introduce a SwiftUI recipe detail view that renders a selected recipe with its metadata, ingredients, and instructions.
- Update the browse-recipes capability to cover presenting individual recipe details.

## Impact
- Adds a new view and navigation entry point in the SwiftUI app.
- Does not add new dependencies or persistency requirements.
