# Changelog

## Unreleased

- Fix: menu save (`7`) wrote `config_saved.lua` to a hard-coded `F:\Steam\...` path, so it failed on every other install. The path now comes from the script's own folder.

## 0.5 - 2026-09-02

First public release.

- Campaign never ends: forces `BrunoCampaign:ShouldCampaignComplete` to `false`, so the game never rolls credits after the final arc. On by default.
- Optional: freeze the day counter (sandbox), disable permadeath / ironman, disable tutorials.
- In-game keyboard menu (`End` to open, number keys `1`-`7`); settings persist to `config_saved.lua`.
- Experimental holotable top-up from the `SK_Table_*` weighted pools, present but off by default.
- Requires [UE4SS for STAR WARS Zero Company](https://www.nexusmods.com/starwarszerocompany/mods/9) by Vercadi.
