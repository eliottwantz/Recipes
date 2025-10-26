## Tasks

- [X] Create the `RecipeShareExtension` target with the required entitlements, app group, and Info.plist configuration so it appears in the iOS share sheet.
- [X] Extract the JSON-LD import pipeline (HTML parser, mapping) into a module that both the app target and extension can import without duplicating code.
- [X] Implement an extension view model that resolves shared HTML attachments, maps them into a mutable `RecipeDraft`, and exposes retryable error states.
- [X] Build the SwiftUI review UI that binds to the draft, surfaces parsed fields, and offers Save and Cancel actions.
- [X] Wire Save to persist through the shared SQLiteData database writer (now located in the app group container) and ensure Cancel dismisses without side effects.
- [X] Add user-facing error handling for missing HTML, unsupported attachments, and parsing errors, including Retry affordances within the extension limits.
- [X] Validate with `openspec validate add-share-sheet-import --strict` and `xcodebuild -scheme Recipes -destination 'platform=iOS Simulator,name=iPhone 16' build | xcbeautify` (ensuring the extension target is part of the scheme).
