## Overview

Create a new `RecipeShareExtension` target that boots a SwiftUI scene responsible for receiving shared URLs, invoking the existing import pipeline, and rendering a lightweight review editor. The extension will resolve the first HTTPS URL attachment, download HTML via the shared networking dependency, run the JSON-LD extractor, and materialize a `RecipeDraft` structure that mirrors the `Recipe` model. The draft feeds a SwiftUI form so users can tweak metadata before saving. Persistence happens through the same SQLiteData writer that the main app uses, moved into an app group container and injected into both targets via Dependencies.

## Decisions

- Promote the `RecipeImportManager` parsing and mapping code into a shareable module (`RecipeImportFeature`) so the extension and host app compile against a single source of truth for JSON-LD handling.
- Introduce a `RecipeDraft` value that wraps a `Recipe` while keeping optional fields mutable for the editing UI; dagger reuses the existing `Recipe` struct when persisting to avoid schema drift.
- Use an app group-based SQLite configuration so the extension can call the existing persistence helper without bespoke serialization or IPC.
- Keep the share extension UI purely SwiftUI with a simple state machine (loading → review → error) to respect the extension time limits and keep engineering overhead low.
- Surface recoverable errors (network failure, missing JSON-LD, unsupported item provider types) inside the extension with Retry and Cancel actions, falling back to dismissal when the user opts out.
