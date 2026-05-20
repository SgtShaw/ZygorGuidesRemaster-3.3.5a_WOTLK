# Release Notes - 3.0.183

## Gear Advisor

- Added a tooltip value display dropdown:
  - `Upgrade Comparison` keeps the existing `+/- score` and percent display.
  - `Item Score` shows the static weighted score assigned to the item.
  - `Both` shows the static score and the upgrade comparison together.
- Added an optional normalized item score display mode that scales static tooltip scores by the total positive stat weights, similar to Pawn's normalized value display.
- Recommendation logic and score calculations are unchanged; the new setting only changes tooltip presentation.

## Localization

- Added localized labels and descriptions for the new tooltip value display and normalized item score options across the supported addon locale files.

## Metadata

- Updated `Ver.lua` and `ZygorGuidesViewerRM.toc` to 3.0.183.
