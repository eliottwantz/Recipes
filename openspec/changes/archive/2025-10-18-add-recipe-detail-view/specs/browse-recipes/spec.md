## ADDED Requirements
### Requirement: Display Recipe Details
The app MUST present a dedicated view for an individual recipe that surfaces its core metadata, ingredient list, and cooking instructions.

#### Scenario: Show full recipe information
- **GIVEN** a recipe exists with title, servings count, prep time, cook time, ordered ingredients, and step-by-step instructions
- **WHEN** the user navigates to the recipe detail view for that recipe
- **THEN** the view MUST display the recipe title prominently at the top
- **AND** the view MUST show servings, prep time, and cook time in a concise metadata section
- **AND** the view MUST render the ingredient list as readable bullet points or similar structured layout
- **AND** the view MUST present the instructions in order, ensuring multi-step text remains legible
