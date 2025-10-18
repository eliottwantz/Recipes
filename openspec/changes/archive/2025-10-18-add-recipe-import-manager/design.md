## Overview

Introduce a `RecipeImportManager` service that owns end-to-end recipe ingestion from arbitrary web URLs. The manager will:
- perform an async HTTP GET using the shared `URLSession` dependency
- scan HTML for JSON-LD script tags without pulling in third-party HTML parsers
- decode JSON objects into a lightweight `ImportedRecipe` struct that mirrors the schema required for a `Recipe`
- normalize ingredient and instruction arrays into newline-delimited strings
- persist the mapped `Recipe` through the shared SQLiteData `DatabaseWriter`

This isolates scraping logic from UI code while giving us one asynchronous entry point for future import flows.

## Decisions

- Parse JSON-LD with Foundation `JSONSerialization` / `JSONDecoder` after extracting script contents via a simple string-based search keyed on `<script type="application/ld+json">` to avoid new dependencies.
- Treat the first JSON-LD object whose `@type` contains `"Recipe"` (string or array) as authoritative; fall back with a clear error when no such node exists.
- Support `recipeInstructions` expressed as a single string, an array of strings, or an array of objects containing `text`, collapsing them into newline-separated steps.
- Convert ISO-8601 duration strings (`PT1H20M`) into minute counts using `ISO8601DateComponentsFormatter`, defaulting to `nil` when parsing fails instead of throwing.
- Inject the `DatabaseWriter` and `URLSession` via Dependencies so previews and tests can override them; default insert uses `Recipe(id: UUID(), ...)` and sets `createdAt` / `updatedAt` to now.
