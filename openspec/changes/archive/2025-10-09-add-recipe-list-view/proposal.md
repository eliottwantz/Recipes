## Why
The app currently shows placeholder content and does not surface any recipes stored in the database, limiting its usefulness.

## What Changes
- Introduce a SwiftUI view that fetches all recipes from the SQLiteData database and presents them in a scrollable list with their titles and summaries.
- Wire the new view into the app shell so users see their recipes on launch.

## Impact
- Users can browse stored recipes immediately after opening the app.
- Provides a foundation for future navigation to recipe details or filtering.
