# Release Notes - 3.0.186

## Gear Finder Recommendation Improvements

- Added ranked BiS-Tooltip recommendation coverage for mapped WotLK specs, with Shadow priest now using curated pre-raid/T9/T10/Ruby Sanctum ordering.
- Preserved Retail WotLK gear source rows when legacy faction gear files load, fixing missing source-backed upgrades.
- Improved DB-backed upgrade evaluation for items that are still pending live client item info.
- Tightened `Prefer tier progression` behavior with boss-row phase handling and stricter progression-band pruning.

## Diagnostics

- Use `/zgvgeartrace <itemid>` for any odd Gear Finder recommendation.
- Send the copied trace popup text plus a screenshot of the Gear Finder result so source, phase, BIS rank, and queue state can be verified.

## Metadata

- Updated addon version metadata to `3.0.186`.
- Release timestamp: `2026-05-23 21:12:37 -05:00`.
