# Release Notes - 3.0.181

## Gear Advisor Diagnostics

- Added `/zgvgearbug` with alias `/zgvitemdebug`.
- The command accepts a plain item ID, `item:####`, or a shift-clicked item link.
- It prints screenshot-friendly `ZGD` chat lines with DB data, live `GetItemInfo()` data, cached item details, validity, score, Blizzard API probes, equipped slot baselines, and tooltip scanner colors.
- This release is diagnostic only and does not change Gear Advisor or Gear Finder recommendation behavior.

## Metadata

- Updated `Ver.lua` and `ZygorGuidesViewerRM.toc` to 3.0.181.