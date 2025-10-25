## Why

- The main app (`Recipes/Storage/StorageBootstrap.swift`) and the share extension (`RecipeShareExtension/ShareExtensionBootstrap.swift`) each recreate the same SQLite configuration, migration list, and error handling, which risks schema drift and increases maintenance cost whenever we touch persistence.
- Core storage metadata such as the app group identifier and database filename currently live inside `RecipeImportFeature/AppGroup.swift`, forcing unrelated modules to depend on the import feature just to locate the shared container.
- Consolidating bootstrap logic and metadata into a storage-focused surface keeps responsibilities clearer and reduces boilerplate for future targets that need database access.

## What Changes

- Extract a storage bootstrap utility (likely a lightweight Swift module or shared source folder) that owns the SQLiteData configuration, migration registration, and logging so both the app target and share extension can call the same API.
- Relocate the app group identifier and database filename constants into the storage layer alongside the bootstrap helper, removing the dependency on `RecipeImportFeature` for unrelated features.
- Update the host app, previews, and share extension to invoke the shared bootstrap entry points instead of maintaining duplicate code paths.
- Clean up any now-redundant files and ensure dependency declarations reflect the new shared storage surface.

## Impact

- Requires touching Xcode target membership so the shared bootstrap source is compiled into both the app target and the share extension.
- CloudKit sync set-up must continue to function after the refactor; we need to confirm the new shared bootstrap exposes hooks for the main app to start the sync engine while remaining lightweight for the share extension.
- We must validate that moving the app group metadata does not break entitlements or existing file paths during upgrades for existing users.
