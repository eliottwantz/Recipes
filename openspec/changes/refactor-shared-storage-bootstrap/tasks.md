## Tasks

- [x] Inventory current storage bootstrap responsibilities across the app and share extension to define the reusable surface (configuration, migrations, logging, sync hooks).
- [x] Extract the shared bootstrap implementation and app group metadata into a storage-scoped module/source group compiled into both targets.
- [x] Update the main app bootstrap call sites (including previews/tests) to use the shared helper while continuing to initialize CloudKit sync.
- [x] Replace the share extension bootstrap with the shared helper and remove redundant migration or file-url code.
- [x] Run `openspec validate refactor-shared-storage-bootstrap --strict` and `xcodebuild -scheme Recipes -destination 'platform=iOS Simulator,name=iPhone 16' build | xcbeautify` to confirm specs and builds succeed.
