## Why
Current empty states rely on a custom SwiftUI view instead of the platform-provided `ContentUnavailableView`, which means we miss Apple’s standardized empty-state styling and dynamic type behavior.

## What Changes
- Specify that empty recipe lists must leverage `ContentUnavailableView`
- Update the SwiftUI implementation to render `ContentUnavailableView` for empty recipe collections

## Impact
- Aligns the app with modern iOS empty state conventions
- Reduces custom UI code and increases accessibility coverage
