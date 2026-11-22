# ZC_Endless

> Developed with AI assistance, then hand-edited, reviewed and tested.

An endless / career mode for [STAR WARS Zero Company](https://www.bitreactor.gg/): a UE4SS Lua mod that stops the campaign from ending after the final story arc, so your company, roster, gear and progress carry on.

## What it does

| Feature | Default | How |
|---|---|---|
| Campaign never ends | on | Forces `BrunoCampaign:ShouldCampaignComplete` to return `false`, so the game never enters `GMState_PostCampaign_Credits_C` after the final arc (`Arc_MainStory_A7`). |
| Freeze the day counter (sandbox) | off | Holds a permanent turn-blocking key on `BrunoStrategyTurnManager` so the cycle never advances. Toggle in game with `F9` or the menu. |
| Disable permadeath / ironman | off | `BitReactorGameStatics:SetPermaDeath` / `SetIronmanMode`, the `StrategyData` flags, and clears the save blocker. Technique from Caites' mod #88. |
| Disable tutorials | off | Suppresses the tutorial system, tutorial mission and popups. Technique from Caites' mod #88. |
| Holotable top-up | off (experimental) | On each strategy turn and Den entry, if the board has fewer than `MinBoardMissions`, draws skirmishes from the `SK_Table_*` weighted pools up to `TargetBoardMissions`. Not reliable yet: the RNG generator argument is an in/out struct that UE4SS marshals awkwardly. |

Nothing is written to your save directly. A campaign kept alive past its normal end just keeps going; remove the mod and that save continues as a normal (already past the end) campaign.

Whether the game keeps generating skirmishes on its own after the final arc is untested. If it does, "campaign never ends" alone is enough and the top-up is not needed.

## Requirements

- STAR WARS Zero Company (Steam).
- UE4SS for STAR WARS Zero Company by Vercadi, Nexus mod [#9](https://www.nexusmods.com/starwarszerocompany/mods/9). Install it first, press its console key and confirm it loads.

## Install

Copy the `Mods/ZC_Endless` folder from this repo into:

```text
...\STAR WARS Zero Company\SWZeroCompany\Binaries\Win64\ue4ss\Mods\
```

so you have `...\ue4ss\Mods\ZC_Endless\Scripts\main.lua`. The folder contains an `enabled.txt`, which is enough for UE4SS to load it. To also list it explicitly, add `ZC_Endless : 1` to `ue4ss\Mods\mods.txt` (above the `Keybinds` line) and a matching entry to `mods.json`.

Full details: [docs/INSTALL.md](docs/INSTALL.md).

## Usage

Load a campaign. The UE4SS console shows:

```text
[ZC_Endless] hook armed: ShouldCampaignComplete -> false
[ZC_Endless] all hooks armed.
```

### In-game menu

Press `End` to open the menu (`F11` is the game's fullscreen toggle, so it is not used). With `ShowPanel` on, the panel also appears for a few seconds after the mod loads. While it is open, number keys `1`-`7` toggle rows and run actions:

```text
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

`7` writes your choices to `config_saved.lua`, which is loaded on top of `config.lua` on the next launch; delete that file to reset. The save path is hard-coded to `F:\Steam\steamapps\common\STAR WARS Zero Company\...\ZC_Endless\Scripts\config_saved.lua` (`main.lua:88`), so saving only works for a game installed there.

There is no ImGui in this UE4SS build, so the menu is keyboard-driven, not clickable.

Outside the menu, `F8` tops the board up now (only while `EnableBoardTopUp` is on) and `F9` toggles the clock freeze.

## Configuration

`Mods/ZC_Endless/Scripts/config.lua` holds every option, commented. Hot-reload (`Ctrl+R`) or relaunch to apply edits.

| Option | Default | Meaning |
|---|---|---|
| `NeverEndCampaign` | `true` | Force `ShouldCampaignComplete` to `false`. |
| `FreezeClock` | `false` | Hold a turn-blocking key so the day counter never moves. |
| `ToggleFreezeKey` | `"F9"` | Key that toggles the clock freeze. |
| `EnableBoardTopUp` | `false` | Experimental holotable top-up; a bad call can crash the game. |
| `MinBoardMissions` | `3` | Top up when the board has fewer missions than this. |
| `TargetBoardMissions` | `7` | Fill the board up to this many missions. |
| `AllowDuplicates` | `false` | Let a weighted table pick the same mission more than once. |
| `Tables` | 4 pools | `SK_Table_Imperial`, `_Outlaws`, `_Coil`, `_Sepratists`. |
| `IncludeCrisis` | `false` | Also draw from `CrisisTable`. |
| `CrisisTable` | `SK_Table_CrisisTable` | The crisis pool. |
| `DisablePermadeath` | `false` | Turn permadeath off. |
| `DisableIronman` | `false` | Turn ironman off. |
| `DisableTutorials` | `false` | Suppress tutorials; `false` stops suppressing but does not replay the intro. |
| `ShowPanel` | `true` | Show the menu panel briefly after the mod loads. |
| `TogglePanelKey` | `"END"` | Menu key; alternatives `HOME`, `INS`, `F1`-`F4`. |
| `PanelAutoShowSeconds` | `5` | How long the panel stays up when shown automatically. |
| `ForceTopUpKey` | `"F8"` | Key for a manual top-up. |
| `DebugLog` | `true` | Write `[ZC_Endless]` lines to the UE4SS log. |

## Uninstall

Delete the `ue4ss\Mods\ZC_Endless\` folder (and its lines in `mods.txt` / `mods.json` if you added them). Your save is untouched.

## Layout

```text
Mods/ZC_Endless/enabled.txt          force-enables the mod in UE4SS
Mods/ZC_Endless/Scripts/main.lua     hooks, top-up, menu and keybinds
Mods/ZC_Endless/Scripts/config.lua   options
tools/luacheck.py                    Lua parse check
docs/                                install guide, research notes, API reference
dist/NEXUS_PAGE.md                   Nexus Mods upload sheet
```

## Tests

`tools/luacheck.py` parse-checks the Lua with the Lua runtime bundled in `lupa` (`pip install lupa`, then `python tools/luacheck.py Mods/ZC_Endless/Scripts/*.lua`).

## Docs

- [docs/INSTALL.md](docs/INSTALL.md): install, verify, hot reload, troubleshooting.
- [docs/RESEARCH.md](docs/RESEARCH.md): how the campaign works and where the mod hooks it.
- [docs/API.md](docs/API.md): strategy-layer API reference for other modders.
- [CHANGELOG.md](CHANGELOG.md): release notes.
- [dist/NEXUS_PAGE.md](dist/NEXUS_PAGE.md): Nexus Mods upload sheet.

## Credits and licence

Built on the reverse-engineering and techniques of the STAR WARS Zero Company modding community; nothing here is original invention. Every author is named in [CREDITS.md](CREDITS.md).

[MIT](LICENSE). The techniques it builds on belong to their original authors.
