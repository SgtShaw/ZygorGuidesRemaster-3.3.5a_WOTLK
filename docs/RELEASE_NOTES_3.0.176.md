# Release Notes - 3.0.176

## Gear Advisor

- Added a runtime usability guard so items Blizzard reports as unusable for the current character are rejected before scoring.
- Applies in both immediate item validity paths before armor/DPS fallback comparisons.
- Prevents unusable armor or weapon recommendations when localized subtype metadata is incomplete or unreliable.

## Reported Example

- `item:2399` - Light Chain Belt still being recommended to a priest on `3.0.175`.

## Metadata

- Bumped addon metadata to `3.0.176`.
- Set addon date to `2026-05-20 10:22:10 -05:00`.
