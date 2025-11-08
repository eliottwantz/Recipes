# Project Context

## Purpose
Recipes is a lightweight SwiftUI app for browsing, organizing, creating, and sharing personal meal ideas across Apple platforms. The goal is to grow a polished reference app that demonstrates clean SwiftUI patterns while remaining small enough for rapid iteration, including a streamlined flow for importing web recipes and normalizing their details.

## Tech Stack
- Swift 6
- SwiftUI with the declarative view lifecycle
- Xcode 26 toolchain with iOS 26 and macOS 26 targets
- SF Symbols for system iconography
- CloudKit for iCloud-backed data synchronization
- SQLiteData for local persistence with CloudKit syncing

## Project Conventions

### Code Style
- Follow the Swift API Design Guidelines: UpperCamelCase types, lowerCamelCase properties/functions.
- Use four-space indentation and let Xcode keep whitespace tidy; avoid trailing spaces in SwiftUI builders.
- Co-locate the primary type with its filename (e.g., `MealListView` lives in `MealListView.swift`).
- Gate heavy preview/sample data behind `#if DEBUG` to keep release builds lean.

### Architecture Patterns
- Single-scene SwiftUI app rooted in `RecipesApp` with feature-specific view files under `Recipes/Views/<Domain>/<FeatureName>/`, expanding to platform-specific scene modifiers when the macOS target needs custom chrome.
- Keep `ContentView` focused on shell navigation; spin off feature views (e.g., meal list, detail) into dedicated folders.
- Favor simple, testable view models when state grows; reuse SwiftUI modifiers/utilities via peer directories under `Recipes/`.
- Model persistence through SQLiteData with CloudKit replication; isolate storage coordination in dedicated data services to keep views declarative.

### Testing Strategy
- No automated tests are required today; rely on SwiftUI previews for rapid layout feedback.
- Validate builds headlessly with `xcodebuild -scheme Recipes -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build | xcbeautify` before merging substantive changes.

### Git Workflow
- Work on short-lived feature branches; target `main` for integration.
- Keep commit subjects short, imperative, and under ~72 characters (e.g., `Add meal list view`).
- Group related changes per commit; document UI-impacting changes with simulator screenshots in PRs.

## Domain Context
- Focus on home-cooked meal management: capturing recipes, tagging meals, and surfacing cooking inspiration.
- Anticipated features include browsing curated lists, viewing detailed ingredients, tracking preparation steps, and importing recipes from websites with automatic parsing of ingredients, preparation steps, prep/cook time, and servings.

## Important Constraints
- Stay lightweight—avoid introducing heavy third-party dependencies unless justified.
- Prioritize clarity over abstraction; default to <100 lines of new code per feature and keep designs easily understandable within 10 minutes.
- Maintain offline friendliness for core browsing and viewing flows while ensuring CloudKit sync reliability.
- When modifying storage logic, review the SQLiteData 1.1.1 documentation (`https://swiftpackageindex.com/pointfreeco/sqlite-data/1.1.1/documentation/sqlitedata`) and its key guides on fetching, preparing the database, dynamic queries, comparing with SwiftData, observing, and CloudKit integration (`/fetching`, `/observing`, `/preparingdatabase`, `/dynamicqueries`, `/comparisonwithswiftdata`, `/cloudkit`) to stay aligned with the evolving API surface.

## External Dependencies
- CloudKit for secure, private-cloud synchronization.
- SQLiteData for SQL-powered local persistence with CloudKit integration.
