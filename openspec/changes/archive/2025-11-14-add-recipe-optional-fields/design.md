# Design: Optional Recipe Fields

## Context
The current `Recipe` model captures core metadata (name, times, servings) and structured content (ingredients, instructions). Users need additional optional context: personal notes, nutrition facts, source attribution, and visual imagery. These fields should be optional to keep the model lightweight for simple recipes while supporting richer detail when needed.

## Goals / Non-Goals

### Goals
- Add four optional fields without breaking existing recipes
- Support CloudKit sync for new fields
- Allow users to edit optional fields in the edit screen
- Display optional fields in detail view when present
- Preserve source URL during import for attribution

### Non-Goals
- Structured nutrition parsing (keep as free-form text for now)
- Image hosting/CDN integration (photos stored locally, synced via CloudKit)
- Recipe tagging or categorization (separate feature)
- Multi-URL support (single website field sufficient)

## Decisions

### Schema Design
- **Notes**: `String?` column on `Recipe` table - simple nullable text for user annotations
- **Nutrition**: `String?` column on `Recipe` table - free-form text for dietary information
- **Website**: `String?` column on `Recipe` table - source URL for attribution
- **Photos**: Separate `recipe_photos` table with `(id, recipeId, position, photoData)` to support ordered collection of images without bloating main recipe row

**Alternatives considered:**
- Storing photos as JSON blob in Recipe table → rejected for CloudKit sync complexity and query inflexibility
- Structured nutrition schema (calories, protein, etc.) → rejected for simplicity; free-form text sufficient initially

### Import Behavior
- Capture source URL as `website` during import
- Extract nutrition from JSON-LD `nutrition` field when present (map to string)
- Leave `notes` empty initially (user-only field)
- Photos not imported initially (future enhancement)

### UI Layout
- Optional fields displayed in detail view only when non-empty to avoid clutter
- Edit screen shows all optional fields with clear labels
- Website displayed as tappable link with Safari icon
- Photos displayed as horizontal scrolling gallery

### Migration Strategy
- Add columns with `ALTER TABLE ADD COLUMN` in migration
- New columns default to NULL for existing recipes
- No data backfill required
- CloudKit schema updated via SQLiteData automatic detection

## Risks / Trade-offs

### Risk: CloudKit schema evolution
- **Mitigation**: Test schema migration on development CloudKit container first, verify backward compatibility

### Risk: Free-form nutrition text may be inconsistent
- **Mitigation**: Acceptable for MVP; structured schema can be added later with migration

### Trade-off: Photos stored locally vs cloud hosting
- **Decision**: Local storage with CloudKit sync keeps implementation simple and respects user privacy
- **Downside**: Large photo libraries may slow sync; consider size limits if needed

## Migration Plan

1. Add columns to `Recipe` table via SQLiteData migration
2. Create `recipe_photos` table with foreign key to recipes
3. Deploy app update with schema changes
4. CloudKit schema updates automatically on first sync
5. Rollback: columns are optional; app can ignore new fields if rollback needed

## Open Questions

- Should photos have a size limit? (Suggest 2MB per photo, 10 photos per recipe)
- Should nutrition field support markdown formatting? (Defer to user feedback)
- Should website field validate URL format? (Client-side validation sufficient)
