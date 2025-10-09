## Why
- Persisting recipes locally and syncing with CloudKit is a core pillar of the app; we currently have no persistence layer.
- SQLiteData offers built-in CloudKit replication, so wiring it up early sets the foundation for future recipe features.
- Establishing the `Recipe` model now unblocks UI work that depends on structured data.

## What Changes
- Provision the app's SQLite database with SQLiteData's `defaultDatabase(...)` helper, optionally configuring the connection via `Configuration.prepareDatabase`, and run migrations to ensure the schema exists.
- Configure a `SyncEngine` backed by CloudKit to keep local and remote records in sync.
- Define a `Recipe` model and schema that the storage layer can use for CRUD and syncing.

## Impact
- Introduces SQLiteData and CloudKit runtime dependencies; minimal risk beyond initial setup.
- Requires iCloud entitlements to be active in development builds to exercise sync flows.
- Downstream views gain a concrete data model and persistence hooks for future work.
