# Nexus Mods upload — fill-in sheet

Everything below is ready to paste into the Nexus "Add a mod" form. I can't submit it for you (no API for mod creation; the form needs ToS acceptance + Publish, which I can't click), so this is the manual part.

**File to upload:** `dist/ZC_Endless-0.5.zip`

---

## Form fields

| Field | Value |
|---|---|
| **Name** | `ZC Endless - Endless / Career Mode` |
| **Summary** (short) | `The campaign never ends after the final arc. Keep your company, roster and gear going indefinitely. Plus optional sandbox clock-freeze, permadeath-off and tutorial-off toggles.` |
| **Category** | Gameplay |
| **Version** | `0.5` |
| **Adult content** | No |
| **Requirements** | STAR WARS Zero Company; *UE4SS for STAR WARS Zero Company* by Vercadi (mod 9) — add as a required mod dependency |
| **Source / repo (optional field)** | `https://github.com/venatrix-ritz/ZC-Endless` |
| **Tags** | Gameplay, Cheat, Utilities, Quality of Life, UE4SS, Lua, Sandbox, English |

### Permissions (suggested)

- Users can use assets without permission: **Yes**
- Modification / derivative mods without permission: **Yes** (it's MIT, and it builds on everyone else's work — pay it forward)
- Upload to other sites without permission: your call; "ask first" is fine
- Credits note: this mod reuses techniques from other SWZC modders — keep the CREDITS section

---

## Description (paste into the BBCode / description box)

[size=5][b]ZC Endless[/b][/size]
[i]An endless / career mode for STAR WARS Zero Company.[/i]

After the final story arc, the campaign [b]never rolls credits[/b]. Your company, roster, gear and progress carry on for as long as you want to keep playing.

[size=4][b]What it does[/b][/size]
[list]
[*][b]Campaign never ends[/b] (on by default) — the game never transitions to the post-campaign credits after the last arc. Stable, works across sessions.
[*][b]Freeze the day counter[/b] (optional) — a pure sandbox: the strategy cycle never advances. Toggle in-game.
[*][b]Disable permadeath / ironman[/b] (optional) — technique from Caites' "Skip Tutorial Level and Permadeath and Beskar Switcher".
[*][b]Disable tutorials[/b] (optional) — suppresses the tutorial system, tutorial mission and popups. Also from Caites' mod.
[*][b]Holotable top-up[/b] ([color=#e0a030]experimental, OFF by default[/color]) — meant to keep the mission board stocked from the skirmish pools once the story runs dry. The mechanism is mapped but the call isn't landing reliably yet, so it's disabled. If the game keeps generating skirmishes on its own past the story end, you may not need it at all.
[/list]

Nothing is written to your save. A campaign kept alive past its normal end just keeps going; remove the mod and that save continues as a normal (already-finished) campaign.

[size=4][b]Requirements[/b][/size]
[list]
[*]STAR WARS Zero Company (Steam)
[*][url=https://www.nexusmods.com/starwarszerocompany/mods/9][b]UE4SS for STAR WARS Zero Company[/b][/url] by Vercadi — install this first.
[/list]

[size=4][b]Install[/b][/size]
Extract the [b]ZC_Endless[/b] folder into:
[code]...\STAR WARS Zero Company\SWZeroCompany\Binaries\Win64\ue4ss\Mods\[/code]
so you have [font=Courier New]...\ue4ss\Mods\ZC_Endless\Scripts\main.lua[/font].
The folder's [font=Courier New]enabled.txt[/font] is enough for UE4SS to load it. (Optional: add [font=Courier New]ZC_Endless : 1[/font] to [font=Courier New]ue4ss\Mods\mods.txt[/font] above the Keybinds line.)

[size=4][b]Use[/b][/size]
Load a campaign. Press [b]End[/b] in the Den to open the menu — a small panel, top-left. While it's open, number keys [b]1-7[/b] toggle rows / run actions. Key [b]7[/b] saves your choices so they stick.
(No ImGui in this UE4SS build, so the menu is keyboard-driven, not clickable.)

All options are also in [font=Courier New]Scripts\config.lua[/font], commented.

[size=4][b]Uninstall[/b][/size]
Delete the [font=Courier New]ue4ss\Mods\ZC_Endless\[/font] folder. Your save is untouched.

[size=4][b]Source & documentation[/b][/size]
[url=https://github.com/venatrix-ritz/ZC-Endless]github.com/venatrix-ritz/ZC-Endless[/url] — full source, install guide, the reverse-engineering write-up, and a strategy-layer API reference for other modders.

[size=4][b]Credits[/b][/size]
This mod is a synthesis of the STAR WARS Zero Company modding community's work. Nothing here is original invention.
[list]
[*][b]Caites[/b] — Skip Tutorial + Permadeath, and Mission and Campaign Time Control: the clock model (turn-blocking keys), permadeath / ironman / tutorial suppression, the Den state hook.
[*][b]malekk14[/b] — Zero Company Long Play: the turn-blocking-key clock freeze and the mission-complete hook; the scaffold this started from.
[*][b]matutela22[/b] — Operator Maintenance, Custom Company Start: the UMG panel pattern, the post-turn hook pattern, roster / inventory / facility access.
[*][b]HazeMP[/b] — BlackMarket Stock Injector: the list-injection pattern the (experimental) board top-up is modelled on.
[*][b]DevToolsMaster[/b] — UE4SS Cheat Menu: the note that UE4SS on this game can't marshal FGuid args, and how clickable UMG has to work.
[*][b]arctco[/b] — Squad Six: the insight that the game's missions are data-driven (~125 authored definitions), not procedural.
[*][b]Vercadi[/b] — the game-specific UE4SS build this runs on.
[*][b]The UE4SS-RE team[/b] — UE4SS itself.
[/list]
The full list — every one of the 55 SWZC Nexus authors whose mods were studied during research — is in CREDITS.md inside the download and in the GitHub repo.

[i]STAR WARS and related marks are trademarks of Lucasfilm Ltd. / Disney. STAR WARS Zero Company is by Bit Reactor / Electronic Arts. Unofficial fan mod, no affiliation.[/i]

---

## Changelog entry (for the "Changelogs" tab)

**0.5**
- Initial public release.
- Campaign never ends (forces `BrunoCampaign:ShouldCampaignComplete` to false).
- Optional: freeze clock (sandbox), disable permadeath/ironman, disable tutorials.
- Keyboard menu (End; number keys 1-7); settings persist to `config_saved.lua`.
- Experimental holotable top-up from the `SK_Table_*` pools — present but disabled by default.
