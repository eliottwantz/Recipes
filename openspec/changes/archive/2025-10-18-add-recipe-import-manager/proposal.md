## Why

- Users expect to import recipes directly from web URLs instead of manually retyping content.
- The app currently lacks any service that fetches external HTML or understands JSON-LD recipe metadata.
- Centralizing import logic paves the way for future automation (browser extension, share sheet) without duplicating parsing code.

## What Changes

- Introduce a `RecipeImportManager` that downloads HTML, extracts JSON-LD recipe payloads, and persists normalized `Recipe` values.
- Add lightweight parsing utilities for locating `<script type="application/ld+json">` blocks and decoding recipe-specific fields.
- Extend the storage layer with an insertion helper tailored for imported recipes so the manager can write to SQLiteData safely.

## Impact

- New asynchronous service increases surface area for networking errors; UI needs to surface failures gracefully.
- Importing remote HTML may require additional entitlement review when we later expose the feature, but no new packages or binaries are added now.
- Persister must handle partial metadata (missing cook time, instructions) without crashing, ensuring resilience against diverse recipe schemas.
