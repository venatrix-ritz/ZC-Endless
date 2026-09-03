# ZC_Endless

An **endless / career mode** for [STAR WARS Zero Company](https://www.bitreactor.gg/).
A UE4SS Lua mod: after the final story arc the campaign never rolls credits, so your
company, roster, gear and progress carry on indefinitely.

> **Status:** the "campaign never ends" core is working and stable. Automatic mission
> top‑up of the holotable is **experimental and off by default** — see
> [Status & roadmap](#status--roadmap).

Built on the work of the whole STAR WARS Zero Company modding community — see
[CREDITS.md](CREDITS.md). Nothing here is original invention; it is a synthesis of
techniques other people worked out first.

---

## What it does

| Feature | Default | How |
|---|---|---|
| **Campaign never ends** | on | Forces `BrunoCampaign:ShouldCampaignComplete` to return `false`, so the game never transitions into `GMState_PostCampaign_Credits_C` after the final arc (`Arc_MainStory_A7`). |
| **Freeze the day counter** (sandbox) | off | Holds a permanent turn‑blocking key on `BrunoStrategyTurnManager` so the cycle never advances. Toggle in‑game (`F9` or the menu). |
| **Disable permadeath / ironman** | off | `BitReactorGameStatics:SetPermaDeath` / `SetIronmanMode` + `StrategyData` flags + clears the save blocker. Technique from Caites' mod #88. |
| **Disable tutorials** | off | Suppresses the tutorial system, tutorial mission and popups. Technique from Caites' mod #88. |
| **Holotable top‑up** | **off (experimental)** | On each strategy turn / Den entry, if the board has fewer than `MinBoardMissions`, draw skirmishes from the `SK_Table_*` weighted pools up to `TargetBoardMissions`. Not yet reliable — the RNG‑generator argument is an in/out struct that UE4SS marshals awkwardly. |

Nothing is written to your save directly. A campaign kept alive past its normal end just
keeps going; remove the mod and that save continues as a normal (already‑past‑the‑end)
campaign.

## Requirements

1. **STAR WARS Zero Company** (Steam).
2. **UE4SS for STAR WARS Zero Company** by Vercadi — Nexus mod
   [#9](https://www.nexusmods.com/starwarszerocompany/mods/9). Install that first; press
   its console key and confirm it loads.

## Install

Copy the `Mods/ZC_Endless` folder from this repo into:

```
...\STAR WARS Zero Company\SWZeroCompany\Binaries\Win64\ue4ss\Mods\
```

so you have `...\ue4ss\Mods\ZC_Endless\Scripts\main.lua`. The folder contains an
`enabled.txt`, which is enough for UE4SS to load it. To also list it explicitly, add
`ZC_Endless : 1` to `ue4ss\Mods\mods.txt` (above the `Keybinds` line) and a matching entry
to `mods.json`.

Full details: [docs/INSTALL.md](docs/INSTALL.md).

## Use

Load a campaign. On the UE4SS console you should see:

```
[ZC_Endless] hook armed: ShouldCampaignComplete -> false
[ZC_Endless] all hooks armed.
```

### In‑game menu

Press **End** (configurable — `F11` is the game's fullscreen toggle, so it is not used).
A panel appears top‑left. While it is open, number keys **1–7**:

```
== ZC ENDLESS ==   board: 5

 [1] campaign never ends : ON
 [2] freeze clock        : off
 [3] board top-up (exp)  : off
 [4] disable permadeath  : off
 [5] disable tutorials   : off
 [6] top up board now
 [7] save settings

 [End] close
```

`7` writes your choices to `Scripts/config_saved.lua`, which is loaded on top of
`config.lua` on the next launch. Delete that file to reset.

> No ImGui in this UE4SS build, so the menu is keyboard‑driven, not clickable.

### Config file

`Mods/ZC_Endless/Scripts/config.lua` — every option, commented. Hot‑reload (`Ctrl+R`) or
relaunch to apply edits.

## Status & roadmap

- ✅ **Campaign never ends** — working, native hook, stable across sessions.
- ✅ **Freeze clock / permadeath‑off / tutorials‑off** — working (proven techniques from
  existing mods).
- ⚠️ **Holotable top‑up** — the mechanism is fully mapped (`MissionWeightedTable:SelectAndAddMissions`,
  the five `SK_Table_*` pools, `BrunoStrategyRandomizationManager` generators) but the call
  is not yet landing from Lua. First attempt crashed the process via a guessed struct arg;
  the fallback that crashes has been removed and the feature is gated off. Next step is a
  keypress‑triggered single‑shot test harness so a bad call is a contained experiment.
- ❓ **Open question:** does the game keep generating skirmishes on its own after the story
  end? If so, "campaign never ends" alone may be enough and the injection is optional.

See [docs/RESEARCH.md](docs/RESEARCH.md) for the full reverse‑engineering write‑up and
[docs/API.md](docs/API.md) for the game‑internal API reference.

## Uninstall

Delete the `ue4ss\Mods\ZC_Endless\` folder (and its lines from `mods.txt` / `mods.json`
if you added them). Your save is untouched.

## Development

`tools/luacheck.py` parse‑checks the Lua with a bundled Lua runtime
(`pip install lupa`, then `python tools/luacheck.py Mods/ZC_Endless/Scripts/*.lua`).

## License

[MIT](LICENSE). The techniques it builds on belong to their original authors — see
[CREDITS.md](CREDITS.md).
