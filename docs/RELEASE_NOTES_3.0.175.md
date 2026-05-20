# Release Notes - 3.0.175

## Gear Advisor

- Fixed armor-family detection so numeric item class/subclass data is preferred before localized text heuristics.
- Routed localized subtype matching through the canonical localized lookup instead of the older English-only alias table.
- Prevents leather and mail armor from being recommended to cloth-only classes through armor-only fallback scoring.

## Reported Examples

- `item:2373` - Worn Leather Boots
- `item:2371` - Worn Leather Belt
- `item:2401` - Light Chain Boots

## Metadata

- Bumped addon metadata to `3.0.175`.
- Set addon date to `2026-05-20 10:12:57 -05:00`.
