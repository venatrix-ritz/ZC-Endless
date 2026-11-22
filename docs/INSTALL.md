# Installing ZC_Endless

## 1. Prerequisite: UE4SS

ZC_Endless is a UE4SS Lua mod. You need the **game-specific UE4SS build** for STAR WARS Zero Company by **Vercadi**, Nexus mod [#9](https://www.nexusmods.com/starwarszerocompany/mods/9) (the generic UE4SS release will not initialise on this game).

After installing it, `...\SWZeroCompany\Binaries\Win64\` should contain:

```text
dwmapi.dll
ue4ss\
  UE4SS.dll
  UE4SS-settings.ini
  Mods\
    mods.txt
    mods.json
    ...
```

Launch the game once and confirm UE4SS loads (its console key, F10 by default, opens the console; or check `ue4ss\UE4SS.log`).

## 2. Drop in the mod

Copy the `Mods/ZC_Endless` folder from this repo to:

```text
...\STAR WARS Zero Company\SWZeroCompany\Binaries\Win64\ue4ss\Mods\ZC_Endless\
```

Result:

```text
ue4ss\Mods\ZC_Endless\
  enabled.txt
  Scripts\
    main.lua
    config.lua
```

The `enabled.txt` file is enough for UE4SS to load the mod: a present `enabled.txt` force-enables a mod regardless of `mods.txt`.

## 3. (Optional) list it explicitly

If you prefer to control it from the mod list:

**`ue4ss\Mods\mods.txt`**: add above the `Keybinds` line:

```text
ZC_Endless : 1
```

**`ue4ss\Mods\mods.json`**: add before the `Keybinds` entry:

```json
    {
        "mod_name": "ZC_Endless",
        "mod_enabled": true
    },
```

## 4. Verify

Load a campaign. In the UE4SS console or `UE4SS.log`:

```text
Starting Lua mod 'ZC_Endless'
[RegisterHook] Registered native hook (..) for Function /Script/Bruno.BrunoCampaign:ShouldCampaignComplete
[ZC_Endless] hook armed: ShouldCampaignComplete -> false
[ZC_Endless] hook armed: OnStrategyTurnBegin -> board top-up
[ZC_Endless] hook armed: Den entry -> board top-up
[ZC_Endless] all hooks armed.
```

Press **End** in the Den to open the menu.

## Hot reload

If `EnableHotReloadSystem = 1` in `UE4SS-settings.ini`, `Ctrl+R` reloads mods without restarting, which is handy when editing `config.lua`. A brand-new mod folder still needs a relaunch the first time.

## Uninstall

Delete `ue4ss\Mods\ZC_Endless\` and remove its `mods.txt` / `mods.json` entries if you added them. Saves are not modified by this mod.

## Troubleshooting

| Symptom | Check |
|---|---|
| No `[ZC_Endless]` lines in the log | Folder in the right place? `Scripts\main.lua` present? UE4SS itself loading? `DebugLog = true` in `config.lua`? |
| `[ZC_Endless] ... syntax error` | You edited `main.lua` / `config.lua`: run `tools/luacheck.py` on it. |
| Menu key does nothing | `End` may be rebound; set `TogglePanelKey` in `config.lua` to `HOME`, `INS`, `F1`... |
| Settings do not stick after `7` | The save path is hard-coded to the `F:\Steam\...` install (`main.lua:88`); on any other install path the save fails and the log shows `menu: settings SAVE FAILED`. |
| Game crashes on Den load | Set `EnableBoardTopUp = false` in `config.lua` (it is the default). Report the last `[ZC_Endless]` lines from `UE4SS.log`. |
