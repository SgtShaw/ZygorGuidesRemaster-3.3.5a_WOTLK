# Zygor Guides Viewer Remastered (3.3.5a)

## Version

- Revision: `92`
- Version: `3.0.92`

## Talent Advisor Status

- The embedded `ZygorTalentAdvisor` module has been removed from this repo/addon package.
- It is no longer loaded by `files.xml`.
- Any Talent Advisor features/build files now live outside this addon folder.

## Installation / Update Notes

1. Install/update only this `ZygorGuidesViewerRM` folder.
2. If you still use Talent Advisor separately, install/manage it as a standalone addon/module.
3. `/reload` is enough for Lua-only changes.
4. Full relaunch is required when files/assets are added/removed.

## Guide Profiles

- Current default guide content is the remastered/TrinityCore-oriented profile for WotLK 3.3.5a private servers.
- Optional fallback profile is available for Alliance leveling: `Guides\Leveling_Original\ZygorGuidesAlliance.lua`.
- That fallback is original, unmodified content from classic Zygor guide sources and is intended only if the recommended profile is problematic for your route/session.
- Keep fallback profile optional; do not use it as the primary default.

## Backups

- The local `BACKUP` folder contains edit snapshots created during changes.

