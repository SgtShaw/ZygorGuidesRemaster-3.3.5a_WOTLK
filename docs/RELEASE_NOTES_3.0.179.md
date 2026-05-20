# Release Notes - 3.0.179

## Gear Advisor

- Added compact `ic` and `is` metadata to armor and weapon records in `ZygorItemDB.lua` using AzerothCore WotLK `item_template` class/subclass data.
- `GetItemDetailsFromDB()` now resolves item class, subclass, and armor/weapon family from DB metadata before slot/name heuristics.
- DB fallback records with reliable class/subclass can be validated and rejected correctly even when live tooltip scanning is unavailable.
- Reported Laplace examples now resolve as leather/mail/gun from DB metadata instead of relying on localized tooltip text.

## Metadata

- Updated `Ver.lua` and `ZygorGuidesViewerRM.toc` to 3.0.179.