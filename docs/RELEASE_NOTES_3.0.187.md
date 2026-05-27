# Release Notes - 3.0.187

## Gear Finder

- Fixed paired-slot duplicate handling so the same trinket or ring is not recommended in both slots when item IDs are represented differently internally.
- Improved tier-progression filtering so early results are pruned before display while still allowing the next regular T7/Naxx progression step when a current pre-raid or heroic slot has no upgrade.
- Added a startup item-cache guard. Opening Gear Finder immediately after login now shows a loading state and auto-scans after item data has had time to load.
- Reduced transient cache noise by only queuing approximate fallback candidates after unresolved item retries are exhausted.

## Compatibility

- Fixed AtlasLoot and other addon compatibility with `GetItemQualityColor()` by returning a display-ready quality color code from the global wrapper.
- Updated ZGV GoldUI callers to use the ZGV-owned quality-color helper.

## Diagnostics

- Continue using `/zgvgeartrace <itemid>` for suspicious recommendations.
- Send the copied trace popup text plus a screenshot of the Gear Finder result so source, phase, BiS rank, and queue state can be verified.

## Validation

- Lua syntax/load checks passed for touched files.
- In-game fast-open Gear Finder testing showed reliable results after loading.

## Metadata

- Updated addon version metadata to `3.0.187`.
- Release timestamp: `2026-05-26 21:04:30 -05:00`.
