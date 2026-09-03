# How STAR WARS Zero Company's campaign works (and how endless mode hooks it)

Reverse‑engineered from UE4SS runtime reflection (object dump + CXX header dump) and from
reading the community's existing Lua mods. All names below are the game's own.

Two UE modules:

- **`Bruno`** — the game‑specific strategy/campaign layer (`ABruno*`, `UBruno*`, `GMState_*`)
- **`BitReactorGame`** — the studio framework (`BitReactorGameStatics`, tutorial/user‑settings subsystems)

---

## 1. The strategy turn ("cycle")

- The day counter is `BrunoGameInstance.StrategyData.StrategyTurn` (int), mirrored on
  `ABrunoStrategyTurnManager.StrategyTurn`.
- **A turn only advances when a mission finishes** (win *or* lose). There is no idle
  "end turn" button in the Den. Defeat conditions end the campaign outright.
- `ABrunoStrategyTurnManager` gates advancement with a set of named blocking keys:
  `AddTurnBlockingKey(FString)`, `RemoveTurnBlockingKey(FString)`,
  `HasTurnBlockingKey(FString)`, `DebugClearTurnBlockingKeys()`, `CanAdvanceStrategyTurn()`.
  Hold a key permanently ⇒ the clock never moves (that is "freeze clock" / sandbox mode).
- The strategy state machine lives at
  `/Game/Game/GameData/Logic/GameplayMaster/GameplayMasterStates/`. Relevant states:
  - `GMState_Headquarters_ExplorePhase_C` — the Den / HQ. Has `:OnStateBegin` (the reliable
    "player is now in the hub" hook).
  - `GMState_Headquarters_EndTurn_C` — advancing the day.
  - `GMState_TacticalVictory_C` — mission win.
  - `GMState_SetUpNewCampaign_C` — new‑campaign setup.
  - `GMState_PostCampaign_Credits_C` — **the end.** Reached after the final arc.

## 2. The campaign

- Exactly one `UBrunoCampaign` asset:
  `/Game/Game/GameData/CampaignData/MainStory/Campaign_MainStory`.
- `.Arcs` = 10 `UBrunoCampaignArc` assets: `A1, A2Start, A2, A3, A4Start, A4, A5Start, A5,
  A6, A7`. `A7` is the last. (The `*Start` sub‑arcs are transitions; `Arc_MainStory_A4`
  ends with a `CustomReward_TimeSkip_C`.)
- `UBrunoCampaign` methods:
  - `bool ShouldCampaignComplete(int32 Turn)` ← **the decision point**
  - `int32 GetTotalTurns()`
  - `UBrunoCampaignArc* GetCampaignArcForTurn(int32 Turn, int32& ArcIndex, int32& ArcSubTurn)`
  - `GetArcStartingTurn`, `GetSettingsForTurn`
- `ABrunoCampaignManager` (live at `HUB_Root.PersistentLevel`):
  `CompleteCampaign(const FCampaignID&)`, `DEBUG_CancelCampaign`, `GetActiveCampaigns()`,
  `.ActiveCampaigns`, delegate `OnCampaignCompleted`.

**Endless mode = force `ShouldCampaignComplete` to return `false`.** The game then never
asks the campaign manager to complete, never enters `GMState_PostCampaign_Credits_C`, and
the strategy layer just continues.

## 3. Missions

Missions are **data‑driven, not procedural** — the game ships ~90 authored
`UBrunoMissionData` assets under `/Game/Game/GameData/MissionData/`:

| Folder | Prefix | Nature |
|---|---|---|
| `Story_Main/` | `MM_<arc>_<nnn>_<name>` | Main story. Finite, arc‑gated. |
| `AuthoredHero/` | `HM_<hero>_<nnn>` | Hero missions. Finite. |
| `Optional/` | `SK_<Planet>_<nnn>` | **Skirmishes — the repeatable pool.** |
| `Optional/CrisisMissions/` | `SK_<Planet>_<nnn>_Crisis` | Timed "crisis" variants. |

Planets in the skirmish pool: Anaxes, Brentaal IV, Dantooine, Florrum, Kaller, Lothal,
Mapuzo, Ryloth, Serolonis, Sullust, Vandor.

### The holotable board

- `ABrunoMissionCentral` (live at `HUB_Root.PersistentLevel`; also
  `GetMissionCentral(WorldContextObject)`). 64 functions. Key ones:
  - `TMap<FMissionID, FBrunoMissionRuntimeData> GetAvailableMissions()`
  - `GetAvailableMissionsOfType(UBrunoMissionData*)`
  - `bool CanAddMission(UBrunoMissionData*)`
  - `FMissionID AddMission(UBrunoMissionData* Mission, TSoftObjectPtr<UObject> Origin,
     bool bIgnoreFactRequirements, FBrunoMissionRuntimeData QueuedMissionDataToCopy)`
  - `OnStrategyTurnBegin(int32 Turn)` — per‑turn entry point
  - `TryExpireMission`, `RefreshMissionSpawnSet`,
    `GenerateSpawnSet(FGameplayTag FactionTag, int ThreatLevel, bool bCrisisElite)`
  - delegates `OnMissionAdded / OnMissionCompleted / OnMissionExpired`
  - hookable BP event `NotifyMusicSubSystemOnMissionCompleted(MissionID, …)`
- The game itself ships `CustomReward_AddMission_C` and `CustomReward_RevealMission_C` —
  adding a mission mid‑campaign is a first‑class operation, not a hack.
- `MissionUnqueueGenerator` on the randomization manager culls stale queued missions each
  turn — injected missions may be removed if they linger.

### The skirmish pools

Five `UMissionWeightedTable` assets at
`/Game/Game/GameData/MissionData/MissionTables/`:

| Asset | entries | faction |
|---|---|---|
| `SK_Table_Imperial`    | 6  | Empire |
| `SK_Table_Outlaws`     | 11 | Outlaws |
| `SK_Table_Coil`        | 11 | Coil syndicate |
| `SK_Table_Sepratists`  | 11 | Separatists *(sic — the asset name is misspelled)* |
| `SK_Table_CrisisTable` | 26 | crisis events |

`UMissionWeightedTable`:

```
TArray<FWeightedMission> WeightedMissions;
bool bBlockLevelDuplicates, bAllowLevelDuplicatesIfEmptyBucket;

TArray<UBrunoMissionData*> SelectMissions       (UObject* WorldCtx, FSimpleRandomGenerator& Gen, int32 NumToSelect, bool bAllowDuplicates);
TArray<UBrunoMissionData*> SelectAndAddMissions (UObject* WorldCtx, FSimpleRandomGenerator& Gen, int32 NumToSelect, bool bAllowDuplicates);  -- picks AND registers
void                       AddSelectedMissions  (UObject* WorldCtx, const TArray<UBrunoMissionData*>& Selected);

FWeightedMission { float Weight; bool bEmptyOption;
                   FGameplayTagRequirements FactTagRequirements;
                   TArray<FFactValueRequirement> FactValueRequirements;
                   UBrunoMissionData* Mission; }
```

The `Generator` argument is an `FSimpleRandomGenerator` — a by‑reference (in/out) struct.
The generators live on `ABrunoStrategyRandomizationManager` (get via
`GetRandomizationManager(WorldContextObject)`):

```
FSimpleRandomGenerator GenericMissionTableGenerator, CampaignMissionTableGenerator,
                       CampaignCrisisMissionTableGenerator, CampaignCrisisOperationGenerator,
                       MissionUnqueueGenerator, ShopItemGenerator, CrossTrainingGenerator, ...
int32 InitialSeed;  void SetSeed(int32);  int32 GetSeed();
```

## 4. Everything hangs off `ABrunoStrategyGameState`

It holds direct pointers to every manager, so it is the one‑stop accessor:

```
.RandomizationManager  .MissionCentral  .CampaignManager  .StrategyTurnManager
.FacilityManager  .RosterManager  .BondsCentral  .FocusCentral  .HQInventory
.RosterLevelManager  .ObjectiveManager
```

`GetBrunoStrategyGameState(WorldContextObject)` returns it.

## 5. UE4SS gotchas learned the hard way

- **`RegisterHook(path, pre, post)`** — to override a bool return, use the *post* callback
  and `ReturnValue:set(false)` on the trailing param.
- **UE4SS on this game cannot marshal `TArray<FGuid>` / `TMap<FGuid,…>` / `…ByID(FGuid)`.**
  Always use the actor / name variants. (Credit: DevToolsMaster, mod #47.)
- **An in/out struct parameter needs a Lua `{}`**, not the raw struct userdata, or you get
  *"Tried storing reference to a Lua table for an 'Out' parameter … but no table was on
  the stack"*.
- **A malformed struct argument to a UFunction crashes the whole process.** `pcall` does
  not catch it. Do not "try" a call with guessed struct args — know the shape first.
- **No ImGui Lua API in the current game build** (`imgui`, `RegisterCustomGUIWindow` are
  `nil`). GUIs must be UMG, and clickable UMG needs a mouse‑polling workaround because
  `OnClicked` delegates cannot be bound from Lua on this stack.
- `enabled.txt` in a mod folder force‑enables that mod regardless of `mods.txt` /
  `mods.json`.

## 6. Also in the SDK, not yet used

- `ABrunoMissionCentral:SimulateMission(FMissionID, bool bSuccess, bool bNatural)` —
  auto‑resolve a mission without playing it (a "skip" button).
- `GenerateSpawnSet(FactionTag, ThreatLevel, bCrisisElite)` + `Campaign.StartingThreatLevel`
  — enemy difficulty is threat‑level‑scaled; an endless mode could ramp it per cycle.
- `RandomizationManager:SetSeed / GetSeed` — deterministic runs, or re‑roll the board.
- `GE_Reward_NextMission_*` / `GE_Lose_NextMission_*` — missions carry buffs/debuffs into
  the next fight; a rogue‑lite modifier layer could hook these.
- `BrunoStrategySaveGame` (`GatherSaveInfo` / `ApplySaveInfo`, `.CharacterInfos`) —
  snapshot / restore the roster for discrete "runs".
