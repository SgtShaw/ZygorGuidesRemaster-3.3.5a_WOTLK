# Zygor Guides Viewer Remaster

Remastered Zygor Guides Viewer for **World of Warcraft: Wrath of the Lich King (WotLK) 3.3.5a (build 12340)**.

A remastered version of the classic Zygor Guides Viewer, updated for WotLK 3.3.5a private servers with a cleaner UI and maintained compatibility.

This project keeps the classic Zygor workflow while delivering a cleaner remastered presentation and active upkeep for the 3.3.5a community.

[![Download](https://img.shields.io/badge/Download-Addon-2ea043?style=for-the-badge&labelColor=555555)](https://github.com/ErebusAres/ZygorGuidesRemaster-3.3.5a_WOTLK/archive/refs/heads/main.zip)
[![Install](https://img.shields.io/badge/Install-Quickly-8250df?style=for-the-badge&labelColor=555555)](#-quick-install)
[![Help](https://img.shields.io/badge/Help-Localize-f0883e?style=for-the-badge&labelColor=555555)](#-support-wanted-localization-qa)
[![Safety](https://img.shields.io/badge/Safety-VirusTotal_Report-1f6feb?style=for-the-badge&labelColor=555555)](https://www.virustotal.com/gui/url/d55dfec1532a98b39fc87a1a4f34c06b644de5988b24288bf207610b0c1b46fa/detection)

![Guides Included](https://img.shields.io/badge/Guides-Included-orange) ![Last Commit](https://img.shields.io/github/last-commit/ErebusAres/ZygorGuidesRemaster-3.3.5a_WOTLK?label=Updated&color=brightgreen) ![WoW Compatible](https://img.shields.io/badge/For-WoW-yellow) ![Era WotLK 3.3.5a](https://img.shields.io/badge/Era-WotLK_3.3.5a-blue)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/T6T01U9GMM)

## Version

- Version: ![Version](https://img.shields.io/github/commit-activity/t/ErebusAres/ZygorGuidesRemaster-3.3.5a_WOTLK?label=Version%203.0.&color=1f6feb)
- Intended client: **WotLK 3.3.5a / 12340**

## Who This Is For

This addon is intended for:

- World of Warcraft **WotLK 3.3.5a (build 12340)** clients
- Private server environments (for example TrinityCore-based servers)
- Players who want the classic Zygor guide experience with a cleaner UI

This project is primarily focused on **WotLK 3.3.5a**. Other clients may work, but support and testing are centered on 3.3.5a.

## What You Get

- Step-by-step leveling and quest progression guidance.
- Arrow and waypoint navigation while you play.
- Structured objective flow (accept, complete, and turn-in).
- A cleaner, more readable viewer UI designed for long play sessions.
- Includes talent guidance via the bundled `ZygorTalentAdvisor` module inside `ZygorGuidesViewerRM`.

## What Stayed the Same

Core 3.3.5a-era behavior is preserved:

- Guide parser and step engine.
- Map and waypoint workflow.
- Legacy guide execution patterns.
- Base `ZygorTalentAdvisor` behavior and structure.

## What's New in the Remaster

- Cleaner, retail-inspired UI shell for both guide browsing and options.
- New standalone Guide Manager (Home / Featured / Current / Recent) with category sidebar, search, favorites, and folder-style tree behavior.
- New in-app Options experience with categorized navigation, searchable pages, and improved layout consistency.
- Remastered waypoint arrow and objective text styling updates, including clearer action/title/distance presentation and distance color gradients.
- Accessibility improvements including colorblind presets and simplified noun-color handling for better readability.
- Ongoing compatibility focus for 3.3.5a environments and expanded guide coverage where applicable.

## Included Components

1. `ZygorGuidesViewerRM` - Remastered viewer and guide runtime.
2. `ZygorTalentAdvisor` - bundled inside `ZygorGuidesViewerRM` and loaded as part of the addon package.

## Key Controls

- Minimap icon:
  - Left-click toggles the guide viewer.
  - Right-click opens the Guide Manager.
  - Shift + Right-click opens options.
- Viewer toolbar:
  - Guides left-click opens the legacy quick guide dropdown.
  - Guides right-click opens the Guide Manager.
  - Settings left-click opens quick settings.
  - Settings right-click opens Guide Manager options.

## Quick Install

### Installation Overview

1. Download the ZIP.
2. Extract to `Interface\AddOns\`.
3. Launch the game.
4. Enable the addon.

### Detailed Steps

1. Close World of Warcraft.
2. Open `%WoWFolder%\Interface\AddOns\`.
3. Remove older folders if present:
   - `ZygorGuidesViewer`
   - `ZygorTalentAdvisor`
   - This avoids mixed files from older releases.
4. Copy this folder into `AddOns`:
   - `ZygorGuidesViewerRM`
5. Confirm the top-level folder exists:
   - `Interface\AddOns\ZygorGuidesViewerRM\ZygorGuidesViewerRM.toc`
6. Launch the game and enable the addon.

## Common Issues

**Addon not showing in-game**

- Make sure the folder structure is:
  - `Interface\AddOns\ZygorGuidesViewerRM\ZygorGuidesViewerRM.toc`
- Do not nest folders (no double folder level).

**Out of date warning**

- Enable **Load out of date AddOns** on the character select screen.

**Guide not progressing**

- Some imported guides may not fully match 3.3.5a data.
- See the Known Issues section below.

## Update Notes

1. Install or update the `ZygorGuidesViewerRM` folder as a single addon package.
2. `/reload` is usually enough for Lua-only changes.
3. A full relaunch is safer when files, XML includes, assets, or bundled modules change.

## Guide Profiles

- Current default guide content is the remastered, TrinityCore-oriented profile for WotLK 3.3.5a private servers.
- An optional Alliance fallback profile exists at `Guides\Leveling_Original\ZygorGuidesAlliance.lua`.
- That fallback is original, unmodified classic Zygor content and should only be used if the remastered default route is problematic for a specific session.

## Localization

Localization key coverage is complete across shipped locales (`Main` + `NPCs`) with placeholder and format-consistency checks.

Current focus is community QA review:

- natural phrasing in live gameplay context,
- terminology consistency,
- official localized NPC proper names,
- encoding and readability verification.

Localization was largely AI-assisted and should be treated as needing community review until native-speaker QA confirms quality.

### Community Credits

- [`mikki33`](https://github.com/mikki33) for providing Russian localization changes and review updates.

## Support Wanted (Localization QA)

If you can validate translations in-game, your help is very welcome.

Please report:

- mistranslations,
- awkward phrasing,
- broken placeholders (`%s`, `%d`, `|n`, color codes),
- incorrect NPC names,
- encoding artifacts.

## Safety and Trust

This addon is fully open source and can be inspected before use.

- [![VirusTotal Report](https://img.shields.io/badge/VirusTotal-View_Report-3bb143?style=flat-square)](https://www.virustotal.com/gui/url/d55dfec1532a98b39fc87a1a4f34c06b644de5988b24288bf207610b0c1b46fa/detection)
- You can review all files and changes directly in this repository.
- A VirusTotal scan of the download link is provided for transparency.

## Changelog

### Revision 158 - 3.0.158

- Adds @hypopheria2k's PR Merge:
  - Adds more Database Items that were originally missed, including roughly 365 Items.
  - Adds Questing: Mute addon chat spam, preventing Zygor Guides from Letting you know every detail that's going on.
  - Adds Questing: Show Gold vendor prices in tooltips, disabling the Auction House GOLD guide integration in the tooltips.
  - Background opacity now hides borders on all panels.
- Updated addon version metadata to 3.0.158.
Thanks Hypo!

### Revision 157 - 3.0.157

- Added a WotLK client guard in Gear Finder so later-client imported dungeon item IDs are skipped instead of being considered for 3.3.5a recommendations.
- Corrected additional WotLK dungeon boss fallback IDs for Nexus, Azjol-Nerub, Halls of Stone, Halls of Reflection, and Trial of the Champion result labels.
- Added a Heroic difficulty suffix to Gear Finder item rows when a recommendation comes from the heroic version of a dungeon.
- Updated addon version metadata to 3.0.157.

### Revision 156 - 3.0.156

- Added profession-crafted Gear Finder sources with separate options for crafted items, leveling crafts, and PvP starter crafted sets.
- Added crafted-source display details, including profession, minimum skill, specialization/profession-only requirements, bind behavior, and source tooltips.
- Expanded crafted item metadata coverage so crafted suggestions continue to resolve slot and armor/weapon-family details during item-cache misses.
- Updated Gear Finder practical ranking so nearby dungeon drops are preferred over raid-crafted BoE fallback suggestions by default.
- Fixed Pit of Saron Gear Finder boss labels for normal and heroic loot, including Garfrost, Krick and Ick, and Scourgelord Tyrannus fallback mappings.
- Updated addon version metadata to 3.0.156.

### Revision 155 - 3.0.155

- Added sourced Emblem of Heroism currency reward suggestions in Gear Finder, including currency cost, faction vendor, and Dalaran location display.
- Added a Gear Finder no-source message with an Open Source Settings button when no dungeon, raid, or currency reward sources are enabled.
- Made Gear Finder refresh immediately when source options are changed while the finder is open.
- Fixed the currency reward source table load path for the 3.3.5a addon runtime and backfilled missing item database records for IDs `1749`, `1761`, `1795`, `1830`, and `3794`.
- Updated addon version metadata to 3.0.155.

### Revision 154 - 3.0.154

- Expanded Gear Finder footer artwork so every suggestable dungeon and raid source resolves to an existing guide image, including Classic, TBC, WotLK raids, and world-boss style sources.
- Reworked the recommended dungeon footer background into a full-width image treatment with a UI-color-to-art gradient while keeping the dungeon title, summary, and recommendation reason readable.
- Added level-appropriate fallback footer artwork for the no-recommendation state and removed the hardcoded Icecrown debug placeholder.
- Updated addon version metadata to 3.0.154.

### Revision 153 - 3.0.153

- Remastered the Gear Finder presentation with a cleaner two-column card layout, centered title treatment, warmer remaster-aligned panel colors, and a more intentional footer hierarchy.
- Refined Gear Finder row geometry and typography for better readability, spacing, and slot-grid fit, including blocked-row styling for no-upgrade states such as two-hand offhand conflicts.
- Updated addon version metadata to 3.0.153.

### Revision 152 - 3.0.152

- Carried the BIS rollout forward into a validation-focused release after the full class/spec phase coverage pass, keeping curated BIS annotations broad while tightening remaining early-tier healer/caster side-slot carry-forward gaps where the tier rows had dropped known Phase 1 weapons or wands.
- Refined curated BIS data for multiple specs with safer early-tier weapon, shield, relic, and wand continuity so Gear Finder stars stay consistent with the intended progression path without changing recommendation ranking.
- Updated the BIS work tracker to pivot from broad data fill toward in-game validation and targeted mismatch fixes, reflecting that the current work is now primarily spot-checking and maintenance.
- Updated addon version metadata to 3.0.152.

### Revision 151 - 3.0.151

- Normalized gear-signal handling so Gear Advisor, tooltip comparisons, master-loot notices, and loot-roll markers defer unresolved DB-backed items until live resolution is ready, improving same-item verdict consistency across the addon.
- Added curated BIS annotations to Gear Finder without changing upgrade ranking, including gold-star BIS markers, Best In Slot Equipped status, and WotLK phase-aware BIS data scaffolding.
- Expanded curated BIS coverage across all class and spec builds through pre-raid, T7, T8, T9, T10, Ruby Sanctum, and final late-phase targets, then refined side-slot and relic progression where it was safe to do so.
- Fixed Gear Finder ranged-slot handling so wands and other ranged upgrades are not incorrectly blocked by the two-hand offhand rule.
- Updated addon version metadata to 3.0.151.

### Revision 149 - 3.0.149

- Continued the item database audit and materialized confirmed dirty imported stat patterns directly into `ZygorItemDB.lua`, including caster `armorPenetration -> spellPower`, physical `mp5 -> armorPenetration`, and tank/physical `spellPenetration -> blockValue` corrections.
- Verified the remaining suspicious hybrid, relic, trinket, and held-offhand buckets against trusted TBC/WotLK references; the current audit now leaves only QA/test rows flagged and no confirmed gameplay-relevant dirty items.
- Refreshed the live `ZygorItemDB.lua` header metadata after the cleanup pass and kept runtime item resolution aligned with the cleaned database.
- Updated addon version metadata to 3.0.149.

### Revision 148 - 3.0.148

- Continued the DB-first gear-system rollout so Gear Finder, Gear Advisor, equip comparisons, tooltip suggestions, loot-roll markers, and bank-open gear checks rely more consistently on shared resolved item data.
- Improved Gear Finder presentation and recommendation quality with fuller footer handling, corrected boss labels, distinct ring and trinket recommendations, and more reasonable dungeon suggestion behavior.
- Hardened Gear Advisor compare popups with better long-stat layout, expanded vertical sizing, per-line stat rendering, and more accurate DB-plus-live stat resolution for equip-effect and suspicious imported item rows.
- Added item DB audit tooling and continued cleanup of dirty imported item-stat patterns, including targeted fixes such as Mercurial Alchemist Stone and caster-item stat remapping.
- Updated addon version metadata to 3.0.148.
### Revision 147 - 3.0.147

- Extended the DB-first gear model across Gear Finder, Gear Advisor, tooltip scoring, loot-roll markers, bank-open upgrade checks, and related gear suggestion surfaces.
- Added local bank upgrade scanning and bank-aware equip handling, including rechecks while the bank stays open during spec changes.
- Improved Gear Finder result quality with distinct ring and trinket recommendations, more reliable boss-name resolution, better reasonable-upgrade selection, and a reworked full-width footer recommendation area.
- Hardened missing-item handling by batching equippable-only database warnings and added the missing Mercurial Alchemist Stone item database entry.
- Fixed multiple gear tooltip and advisor issues, including duplicate stat lines, false equip-failed spam, random-suffix exact-stat waiting, and tooltip/live-scan fallback for equip-effect items.
- Updated addon version metadata to 3.0.147.
### Revision 145 - 3.0.145

- Removed the broken built-in Retail skin option and deleted the unused Retail experiment files from the active addon copy.
- Fixed multiple /zgold initialization and nil-data crashes across Auctions, Crafting, item pricing, item classification, tutorial helpers, and auction house appraiser button-state handling.
- Deduped Gold Guide farming and gathering route rows, improved fallback names and icons for sparse entries such as Core Leather, and corrected missing Gold Guide help/tutorial localization text.
- Improved Gold Guide help, info, and tutorial presentation, including corrected image resolution, popup text handling, and tooltip positioning for bottom-row entries.
- Aligned the Auction House appraiser scan flow more closely with the retail behavior on the WotLK API, including cleaner scan-state messaging, timeout recovery, and scan button feedback.
- Fixed the Auction House appraiser settings gear to open the remaster gold options section.
- Updated addon version metadata to 3.0.145.

### Revision 144 - 3.0.144

- Fixed a guide-boundary step helper crash where adjacent guide objects could exist without parsed steps, causing skip and auxiliary checks to index guide.steps unsafely.
- Fixed a Disable Route/Loop Stacking viewer crash by safely truncating oversized non-stacked |route displays instead of running past the fixed step-line frame pool.
- Added multigoto, a new multi-location waypoint command that accepts route-style coordinate chains but behaves like ordered plain goto points rather than a route/loop ant-trail path.
- Kept multigoto integrated with the existing auto-advance and waypoint retargeting logic while explicitly excluding it from marching-ant routegroup rendering.
- Continued Gold Guide route improvements so cleaned runtime route wrappers, same-step route progression, and route waypoint retargeting behave more reliably in practical use.
- Updated addon version metadata to 3.0.144.

### Revision 143 - 3.0.143

- Integrated the useful 3.3.5a-safe parts of repo PR 27 instead of copying it wholesale.
- Removed `BackdropTemplate` dependence from the forked dropdown menu code and restored explicit backdrop setup so `UIDropDownFork` menus still render on Wrath.
- Added narrow compatibility guards in `LibRover` for retail-only `C_Map`, `Enum.UIMapType`, and `C_Garrison` usage in the touched startup and debug-menu paths.
- Kept the compatibility merge intentionally narrow and did not ship the PR backup file.
- Fixed Gold Guide tab-switch nil crashes and improved `/zgold` initialization so repeated opens and tab changes are stable.
- Restored Gold route registration for parsed raw-text guides so included farming and gathering route guides are actually recognized and loaded by Gold Guide.
- Added Gold route validation and route-inspection tooling, then corrected duplicate/placeholder route selection so the effective Wrath route set validates cleanly.
- Fixed several Gold route metadata issues and updated the `Borean Leather` route to a stronger Wrath-appropriate `Sholazar Basin` loop.
- Reworked Gold route loading so farming and gathering guides open cleaned runtime route wrappers instead of exposing raw control lines such as `goldtracker`.
- Fixed same-step route waypoint progression so generated route/path points now advance the active waypoint target automatically as each point completes.
- Added internal waypoint ant-trail options for minimap display mode and trail density, localized them across the supported main locale files, and improved the trail visuals and sizing.
- Improved Gold Guide crafting support on Wrath with detailed recipe caching, safer dynamic guide generation, and a usable low-data `Expert` browse mode.
- Continued the non-NPC localization pass by adding the new route-trail option translations to all main locale files.
- Updated addon version metadata to `3.0.143`.
### Revision 138 - 3.0.138

- Refreshed the Gear Advisor equip / compare popup to better match the remastered Guide Viewer styling while preserving the original equip recommendation behavior.
- Updated the popup presentation with a cleaner framed header, improved footer and button styling, and safer cosmetic-only layout polish.
- Improved bind-on-equip handling so BOE upgrade prompts use a single compare popup, show the warning above the footer, and avoid immediately reopening over Blizzard''s bind confirmation.
- Fixed bag and mail acquisition refresh handling so newly pulled items can trigger upgrade suggestions when they land in your bags.
- Updated addon version metadata to `3.0.138`.

### Revision 137 - 3.0.137

- Minor bug fixes and stability improvements.

### Revision 136 - 3.0.136

- Added a clearer Stat Weights summary with a green `Active Profile` line so the live build is easier to distinguish from the selected edit target.
- Added a note clarifying that selecting another class/spec changes which weights you edit, not your live active build, unless an override is enabled for your own class.
- Added an `Override Active Build` toggle for your own class so the selected spec can explicitly override the detected active build for tooltips and gear recommendations.
- Made active-build overrides persist per active talent group/spec slot instead of as one global override.
- Updated ItemScore tooltips and summary labels so overridden builds are shown as overridden instead of incorrectly labeled as detected.
- Improved pre-talent Stat Weights behavior so explicit pre-10 / no-points-spent active choices can be saved and kept until talent-based detection becomes meaningful.
- Made applying a live stat-weight set trigger the existing deferred gear rescoring and bag upgrade scan path without adding a second heavy scan loop.
- Restored the embedded Stat Weights scrollbar path and improved the Guide Manager options host layout so long pages such as `Show All Stats` can scroll again.
- Added in-place Stat Weights tab refresh handling so active talent-group swaps rebuild the open ItemScore pane and resync the player-class selected build to the new active profile.
- Updated addon version metadata to `3.0.136`.

### Revision 131 - 135 - 3.0.131 to 3.0.135

- Added the repository changes merged from PR 24 by [`hypopheria2k`](https://github.com/hypopheria2k).
- Consolidated the intermediate `3.0.131` through `3.0.135` repo-side update range into this changelog entry for historical tracking.

### Revision 130 - 3.0.130

- Fixed a first-login Stat Weights / Gear Advisor timing issue where the active build could initially fall back to the class baseline (such as Discipline) until `/reload` was used.
- Added an extra delayed ItemScore refresh after `LOADING_SCREEN_DISABLED` so active talent data has a second chance to settle before the selected build is finalized on login.
- Fixed an issue with `|icon` not being applied since .114 update.
- Fixed an issue with the new `|buttonicon` for replacing the action button icon for kill/talk.
- Verified the "Ant Trail" for multi-`|goto`, `|route`, and `|loop` work as intended. (not active on multi-goto)
- Fixed an issue with `|title` syntax not replacing the Title for the Waypoint.
- Fixed an issue where using `info` as a blank space line causes `|icon` and/or `|buttonicon` to be multiplied incorrectly, stacked, and otherwise misplaced.
- Updated addon version metadata to 3.0.130.

## Notes

- Intended target client is **WotLK 3.3.5a (12340)**.
- It may work on other versions, but compatibility is not guaranteed.
- `ZygorTalentAdvisor` is bundled and loaded from within `ZygorGuidesViewerRM`.

## Known Issues

- Arrow scale/position drift:
  - On some setups, changing Waypoint Arrow Scale can shift the arrow position unexpectedly.
  - Resetting arrow position may not fully normalize the anchor in all UI/minimap addon combinations.
  - Status: deferred for now.

- Some imported guides may be incomplete or not fully aligned to 3.3.5a data.
- If a guide behaves incorrectly, disable it in `ZygorGuidesViewerRM/Guides/Autoload.xml` and report it.

## Q&A

**Is this remaster free?**

Yes. This remastered version is and will remain free.

**Where should I download it from?**

Use the main repository download link in this README.

**Are third-party mirrors or repacks safe?**

Not always. Use other sites/downloads at your own risk.

## Credits

Original Zygor Guides concept and content belong to the original creators.

This remaster focuses on UI/UX modernization, packaging quality, compatibility maintenance, and localization completion for the 3.3.5a player community.

## Example Images

### New Guide + Options Menus

![options menu display](docs/images/options-menu-display.png)
![guide manager selection preview](docs/images/guide-manager-selection-preview.png)
<img width="1248" height="845" alt="image" src="https://github.com/user-attachments/assets/6d66d7d6-67bc-4c52-bbb5-5cea38e5bbde" />

### New Pointer Arrow

![new pointer arrow](docs/images/new-arrow.gif)

### ... With Colorblind Options

![colorblind deuteran](docs/images/new-arrow-deuteran.gif)
![colorblind protan](docs/images/new-arrow-protan.gif)
![colorblind tritan](docs/images/new-arrow-tritan.gif)

### New And Legacy Looks

<img width="436" height="264" alt="Viewer Step Flow" src="https://github.com/user-attachments/assets/f0dddbf0-7bfa-4b95-a250-0692c7690921" />
<img width="586" height="260" alt="Guide Window Layout" src="https://github.com/user-attachments/assets/e6b85c9c-8835-4e49-96b1-608ad9944b0f" />
<img width="637" height="197" alt="Waypoint and Route Display" src="https://github.com/user-attachments/assets/cd258eb1-ebb6-420d-9516-4abe9d75d88c" />
<img width="443" height="687" alt="Talent Advisor Panel" src="https://github.com/user-attachments/assets/b3f2c2ef-2bef-4ca4-b033-37c314b151d5" />

### New Route and Loop guide modes

<img width="433" height="247" alt="image" src="https://github.com/user-attachments/assets/579b6acb-df5e-4f40-8ef3-7d6b33e1015d" />
<img width="436" height="248" alt="image" src="https://github.com/user-attachments/assets/a845b881-2831-43e3-bd26-5287f9783d68" />






























