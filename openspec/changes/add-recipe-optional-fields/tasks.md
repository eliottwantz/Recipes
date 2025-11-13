# Implementation Tasks

## 1. Schema & Model Updates
- [x] 1.1 Add optional `notes`, `nutrition`, and `website` columns to `Recipe` table in `Storage/Schema.swift`
- [x] 1.2 Add photos table schema (separate table for one-to-many relationship)
- [x] 1.3 Update database migration to add new columns to existing installations
- [x] 1.4 Verify CloudKit sync includes new fields in schema

## 2. Import Flow Updates
- [x] 2.1 Update `RecipeImportManager` to capture source URL as `website` field
- [x] 2.2 Extract nutrition information from JSON-LD when present (e.g., `nutrition` object)
- [x] 2.3 Initialize `notes` as empty string and `photos` as empty array for new imports

## 3. Edit Screen Updates
- [x] 3.1 Add `notes` text editor field to `RecipeEditFormView`
- [x] 3.2 Add `nutrition` text field to `RecipeEditFormView`
- [x] 3.3 Add `website` URL field to `RecipeEditFormView`
- [x] 3.4 Add photo picker/manager UI for adding/removing photos
- [x] 3.5 Update save logic to persist all optional fields

## 4. Detail View Updates
- [x] 4.1 Display `website` as a tappable link in `RecipeDetailView` when present
- [x] 4.2 Display `nutrition` information section when present
- [x] 4.3 Display `notes` section when present
- [x] 4.4 Display photo gallery when photos are present
- [x] 4.5 Ensure layout gracefully handles missing optional fields

## 5. Validation
- [x] 5.1 Test import flow with and without optional fields populated
- [x] 5.2 Test editing recipes to add/remove optional fields
- [x] 5.3 Test CloudKit sync with new fields
- [x] 5.4 Verify existing recipes display correctly with nil optional fields
- [x] 5.5 Build and validate with `xcodebuild` to ensure no regressions
