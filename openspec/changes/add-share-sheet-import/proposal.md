## Why

- Users frequently discover new dishes while browsing Safari and expect to send them straight into Recipes without copy/pasting URLs manually.
- The current import flow only exists inside the main app, forcing context switching and extra taps whenever inspiration strikes on the web.
- Delivering a share-sheet capture experience aligns with the app goal of streamlining web recipe imports and showcases the JSON-LD pipeline across surfaces.
- Leveraging the page contents already loaded in Safari avoids redundant network requests and respects user expectations around privacy and speed.

## What Changes

- Add an iOS share extension target that appears from the system share sheet and boots into a SwiftUI review flow whenever Safari shares a recipe webpage, consuming the HTML payload provided by the host.
- Extract the existing JSON-LD import pipeline into a reusable module so both the main app and the extension can process shared HTML payloads and build `Recipe` values consistently without refetching the page.
- Present a review UI that displays the parsed recipe, lets users adjust fields that map to the `Recipe` model, and provides Save and Cancel actions.
- Update persistence to expose the SQLiteData database from an app group container so the extension can write new recipes through the same insertion path as the main app.
- Wire basic error handling so unsupported inputs or parsing failures surface actionable messaging inside the share sheet.

## Impact

- Requires introducing an app group entitlement and migrating the on-device database into the shared container, which may warrant a lightweight migration step.
- Extending the import pipeline to a new target increases surface area for dependency injection and testing; we must keep the module boundary lean to avoid code duplication.
- Share extensions have tight memory and execution limits, so the implementation must keep parsing efficient and avoid long-running background work, while handling potentially large HTML documents passed in from the host app.
- Additional build settings and CI updates are needed to ensure the new extension target compiles during headless builds.
