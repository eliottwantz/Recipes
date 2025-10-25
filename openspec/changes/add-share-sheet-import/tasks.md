## Tasks

- [X] Create the `RecipeShareExtension` target with the required entitlements, app group, and Info.plist configuration so it appears in the iOS share sheet.
- [X] Extract the JSON-LD import pipeline (network fetch, parser, mapping) into a module that both the app target and extension can import without duplicating code.
- [X] Implement an extension view model that resolves shared URL attachments, runs the importer with async/await, and produces a mutable `RecipeDraft`.
- [ ] Build the SwiftUI review UI that binds to the draft, surfaces parsed fields, and offers Save and Cancel actions.
- [ ] Wire Save to persist through the shared SQLiteData database writer (now located in the app group container) and ensure Cancel dismisses without side effects.
- [ ] Add user-facing error handling for missing URLs, network failures, and parsing errors, including Retry affordances within the extension limits.
- [ ] Validate with `openspec validate add-share-sheet-import --strict` and `xcodebuild -scheme Recipes -destination 'platform=iOS Simulator,name=iPhone 16' build | xcbeautify` (ensuring the extension target is part of the scheme).
