<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# Repository Guidelines

## Project Structure & Module Organization
The SwiftUI target resides under `Recipes`, with `RecipesApp.swift` declaring the `RecipesApp` entry point and global environment. `ContentView.swift` currently hosts the starter UI; spin off new views into feature folders (e.g., `Recipes/MealList/MealListView.swift`) to keep the root uncluttered. Store any reusable modifiers or models in peer directories under `Recipes`, and keep assets in `Assets.xcassets` so Xcode bundles them automatically.

## Build, Test, and Development Commands
Open the project in Xcode with `open Recipes.xcodeproj` for day-to-day development. Use `xcodebuild -scheme Recipes -destination 'platform=iOS Simulator,name=iPhone 16' build | xcbeautify` to validate builds headlessly, e.g., in CI. When tests are added, run them with `xcodebuild test -scheme Recipes -destination 'platform=iOS Simulator,name=iPhone 16' | xcbeautify`.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines: camelCase for functions and variables, UpperCamelCase for types, and keep filenames aligned with the primary type they expose. Use four-space indentation and let Xcode handle automatic whitespace; avoid trailing spaces in SwiftUI builders to minimize diff noise. Prefer SwiftUI previews for layout checks, but gate expensive sample data behind `#if DEBUG` so release builds stay lean.

## Testing Guidelines
No tests needed.

## Commit & Pull Request Guidelines
Match the existing history by keeping commit subjects short, imperative, and under ~72 characters (e.g., `Add meal list view`). Group related changes per commit and explain rationale in the body if needed. Pull requests should summarize feature intent, call out UI changes with simulator screenshots, and link issues or task IDs so reviewers can trace requirements.
