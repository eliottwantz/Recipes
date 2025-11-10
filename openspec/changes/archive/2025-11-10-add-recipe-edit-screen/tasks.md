## Tasks

- [x] 1.1 Refactor `RecipeImportManager.importRecipe` to return `ExtractedRecipeDetail` without persisting (breaking change from current auto-persist behavior)
- [x] 1.2 Add `.editing(ExtractedRecipeDetail)` phase to `RecipeImportScreen.Phase` enum
- [x] 1.3 Transition from `.importing` to `.editing` after successful extraction instead of auto-persisting
- [x] 1.4 Create `RecipeEditView` component to display and edit extracted recipe fields
- [x] 1.5 Implement editable text fields for title, summary, prep time, cook time, and servings
- [x] 1.6 Implement ingredient list editor with add, delete, edit, and reorder (drag-and-drop) capabilities
- [x] 1.7 Implement instruction list editor with add, delete, edit, and reorder (drag-and-drop) capabilities
- [x] 1.8 Add "Save" toolbar button in edit phase that persists the edited `ExtractedRecipeDetail` and dismisses
- [x] 1.9 Add "Cancel" button that discards edits and returns to initial import form
- [x] 1.10 Validate build with `xcodebuild -scheme Recipes -destination 'platform=iOS Simulator,name=iPhone 16' build | xcbeautify`
