# Credits

ZC_Endless is built on the reverse-engineering and techniques of the STAR WARS Zero Company modding community. **This mod would not exist without their work.** Everything below is credited with gratitude; nothing here is claimed as original invention.

If your work is used here and you want the wording changed, your name removed, or a different link, open an issue and it will be fixed.

---

## Foundations

| Who | What |
|---|---|
| **UE4SS-RE team**: <https://github.com/UE4SS-RE/RE-UE4SS> | UE4SS itself (v3.0.1). The Lua scripting layer everything here runs on. MIT licensed. |
| **Vercadi**: Nexus mods #7, #9 | The game-specific compatibility build of UE4SS for STAR WARS Zero Company (patched `FName` validation so the constructor initialises on this game). ZC_Endless requires it. |
| **Bit Reactor / EA** | The game. All `Bruno*` / `BitReactorGame*` class, function and asset names referenced here are the game's own, read back at runtime via UE4SS's object dumper. |

## Techniques and API knowledge reused directly

| Author | Mod(s) | What ZC_Endless took from it |
|---|---|---|
| **Caites** | #88 *Skip Tutorial Level and Permadeath and Beskar Switcher*, #103 *Mission and Campaign Time Control* | The whole clock model: `BrunoStrategyTurnManager` blocking keys, `CanAdvanceStrategyTurn`, `DebugClearTurnBlockingKeys`, the `GMState_Headquarters_ExplorePhase_C:OnStateBegin` Den hook. Permadeath/ironman toggles via `BitReactorGameStatics:SetPermaDeath` / `SetIronmanMode` + `StrategyData`. The tutorial-suppression logic (`BitReactorTutorialManagerSubsystem`, `BitReactorUserSettingsLocal`, `BitReactorCoreUserProfile`, FTUE flag) is adapted almost verbatim from #88. |
| **malekk14** | #107 *Zero Company Long Play* (`ZC_CycleFreeze`) | The permanent turn-blocking-key clock freeze; hooking `BP_BrunoMissionCentral_C:NotifyMusicSubSystemOnMissionCompleted`; re-arming on every `NotifyOnNewObject` of the TurnManager / MissionCentral. The "closest existing scaffold" this mod started from. |
| **matutela22** | #90 *Operator Maintenance*, #106 *Custom Company Start* | The UMG panel construction pattern (`UserWidget -> WidgetTree -> CanvasPanel -> Border -> TextBlock -> AddToViewport`, unique per-instance FNames, map-generation invalidation). The post-turn hook + deferred action pattern. `BP_BrunoRosterManager_C`, `BP_BrunoHQInventory_C`, `BP_BrunoFacilityManager_C`, `GameInstance.StrategyData.StrategyTurn`. |
| **HazeMP** | #40 *BlackMarket Stock Injector (UE4SS)* | The list-injection pattern that the (experimental) board top-up is modelled on: post-hook the game's own restock function, defer one tick with a re-entrancy guard, `LoadAsset` + `StaticFindObject` to resolve a data asset, and trial the accepted struct shape. |
| **DevToolsMaster** | #47 *UE4SS Cheat Menu* | The hard-won note that **UE4SS on this game cannot marshal `TArray<FGuid>` / `FGuid` args**: use actor / name variants. Why a clickable UMG panel needs a mouse-polling workaround (no `OnClicked` delegate binding from Lua). `BrunoStrategyStatics`, `BrunoRosterStatics`, `BrunoFocusCentral`, `CheatManager:CompleteMission` / `CompleteEncounter`. |
| **arctco** | #29, #44 *Squad Six*, #77 | The observation that the game serialises ~125 hand-authored mission definitions, each with a `MaxSquadSize` override, so missions are data-driven, not procedural. Squad model (`BitReactorGameSquad.SquadMembers`, `PlayerController -> PlayerSquad`, `WBP_Menu_MissionSquadSelect`). |
| **Beritio** | #38, #63 *UI Fix Respec* | Additional worked examples of constructing / walking the game's UMG widget tree from Lua. |

## The wider community: every Nexus Mods author whose work was read during research

All 86 mods on the STAR WARS Zero Company Nexus page (as of Sept 2026) were downloaded, extracted and studied to reverse-engineer the game. Thank you to every one of these authors:

Apofes92, arctco, Beritio, Cafiso, Caites, Celestion, chadi7bark, cheezravioli, CityscapeBlues, ClankerModder, ColonelCousland, crowche, DarkStyleee, Dekita, DevToolsMaster, dmto, feelSmooth, Gametism, GhoulMonkey, Glacknarf, HazeMP, hellraiserrocky, hoperua, iammrmikeman, Indurin, ItsxMoose, jayman273, jeez894, jlegg05, jsmitch43, KintaroxOe, klukule, love2799, lukluk8, malekk14, matutela22, MiroslavSVK83, monsterfurby, Mophead01, Natalia341, NodNuatTranslator, P40L0X, Przemba, rokenze, scottyus1, SmexyXey, SundownIV, thezephyr, Threelibras444, TKTaKo, TocorKeding, Toeofcharmander, Vercadi, WrLDCrescere, ZverAllison

## Tools

- **UE4SS** object dumper + CXX header generator: produced the typed reference for every `Bruno*` class used here.
- **rokenze**: #99, the community `.usmap` for FModel (an alternate route to the same reflection data).

---

*STAR WARS and all associated names are trademarks of Lucasfilm Ltd. / Disney. STAR WARS Zero Company is developed by Bit Reactor and published by Electronic Arts. This is an unofficial fan modification and is not affiliated with, endorsed by, or supported by any of them.*
