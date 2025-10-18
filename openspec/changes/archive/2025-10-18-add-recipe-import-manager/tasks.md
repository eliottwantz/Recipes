## Tasks

- [x] Add `RecipeImportManager` protocol and concrete implementation registered through Dependencies.
- [x] Implement HTML download routine using `URLSession` with error propagation for non-2xx responses.
- [x] Parse extracted JSON-LD into an intermediate `ImportedRecipe` model and map supported fields to `Recipe`.
- [x] Persist imported recipes via the shared `DatabaseWriter`, ensuring timestamps update and the saved value returns to callers.
- [x] Wire a manual validation harness (e.g., preview or debug command) and run `xcodebuild -scheme Recipes -destination 'platform=iOS Simulator,name=iPhone 16' build | xcbeautify`.
