# STAR WARS Zero Company: strategy-layer API reference

Signatures taken from the UE4SS CXX header dump (`Bruno.hpp`, `BitReactorGame.hpp`) of the Steam build tested Sept 2026. `WorldCtx` = any `UObject` world context (PlayerController / GameInstance work).

## Accessors

```text
StaticFindObject("/Script/Bruno.Default__BrunoStrategyGameState")
    :GetBrunoStrategyGameState(WorldCtx)          -> ABrunoStrategyGameState*   (holds all mgr ptrs)

Default__BrunoMissionCentral            :GetMissionCentral(WorldCtx)
Default__BrunoCampaignManager           :GetCampaignManager(WorldCtx)
Default__BrunoStrategyTurnManager       :GetStrategyTurnManager(WorldCtx)
Default__BrunoStrategyRandomizationManager :GetRandomizationManager(WorldCtx)
Default__BrunoStrategyObjectiveManager  :GetStrategyObjectiveManager(WorldCtx)
Default__BrunoFocusCentral              :GetFocusCentral(WorldCtx)
Default__BrunoRosterManager             :GetRosterManager(WorldCtx)
Default__BrunoRosterLevelManager        :GetRosterLevelManager(WorldCtx)
```

Or just `FindFirstOf("BrunoMissionCentral")` etc.; they are single live actors in the hub.

## Campaign

```text
class UBrunoCampaign : UBitReactorAssetDefinitionBase
    bool  ShouldCampaignComplete(int32 Turn)          -- hook -> force false for endless
    int32 GetTotalTurns()
    UBrunoCampaignArc* GetCampaignArcForTurn(int32 Turn, int32& ArcIndex, int32& ArcSubTurn)
    -- fields: Arcs[], DefaultObjectives[], StartingRoster[], StartingThreatLevel,
    --         OpeningMissionSettings

class ABrunoCampaignManager : AInfo
    void CompleteCampaign(const FCampaignID& CampaignID)
    void DEBUG_CancelCampaign(const FCampaignID&, bool bCancelCampaignActivities)
    TArray<FCampaignID> GetActiveCampaigns() / GetCompletedCampaigns() / GetCanceledCampaigns()
    -- delegate OnCampaignCompleted

Campaign asset: /Game/Game/GameData/CampaignData/MainStory/Campaign_MainStory
End state:      GMState_PostCampaign_Credits_C
```

## Strategy turn

```text
class ABrunoStrategyTurnManager : AInfo
    void  AddTurnBlockingKey(FString)
    void  RemoveTurnBlockingKey(FString)
    bool  HasTurnBlockingKey(FString)
    void  DebugClearTurnBlockingKeys()
    bool  CanAdvanceStrategyTurn()
    int32 GetStrategyTurn()
    int32 StrategyTurn                       -- field
    TSet<FString> TurnAdvancementBlockingKeys
    -- delegates OnStrategyTurnBegin / ...BeginPost / ...End / ...StateReady / ...BlockingUpdated
```

## Missions

```text
class ABrunoMissionCentral : AInfo
    void       OnStrategyTurnBegin(int32 Turn)                  -- per-turn entry point
    TMap<FMissionID,FBrunoMissionRuntimeData> GetAvailableMissions()
    TMap<...>  GetAvailableMissionsOfType(const UBrunoMissionData* MissionData)
    bool       CanAddMission(const UBrunoMissionData* Mission)
    FMissionID AddMission(const UBrunoMissionData* Mission,
                          TSoftObjectPtr<UObject> Origin,
                          bool bIgnoreFactRequirements,
                          FBrunoMissionRuntimeData QueuedMissionDataToCopy)
    void       CompleteMission(FMissionID) / FailMission(FMissionID) / TryExpireMission(FMissionID,bool)
    void       RefreshMissionSpawnSet(FMissionID)
    ...        GenerateSpawnSet(FGameplayTag IdentifyingFactionTag, int32 ThreatLevel, bool bIsCrisisEliteSpawnSet)
    void       SimulateMission(FMissionID, bool bSimulateSuccess, bool bNaturalSimulation)
    -- fields AvailableMissions, QueuedMissions, StartingMissions, EndedMissions, CurrentMissionID
    -- delegates OnMissionAdded / OnMissionCompleted / OnMissionExpired / OnMissionFailed / OnMissionStarted
    -- BP event: /Game/Game/Core/Blueprints/BP_BrunoMissionCentral.BP_BrunoMissionCentral_C:NotifyMusicSubSystemOnMissionCompleted

class UMissionWeightedTable : UBitReactorAssetDefinitionBase
    TArray<UBrunoMissionData*> SelectMissions       (UObject* WorldCtx, FSimpleRandomGenerator& Gen, int32 NumToSelect, bool bAllowDuplicates)
    TArray<UBrunoMissionData*> SelectAndAddMissions (UObject* WorldCtx, FSimpleRandomGenerator& Gen, int32 NumToSelect, bool bAllowDuplicates)
    void                       AddSelectedMissions  (UObject* WorldCtx, const TArray<UBrunoMissionData*>& Selected)
    TArray<FWeightedMission>    WeightedMissions
    bool                       bBlockLevelDuplicates, bAllowLevelDuplicatesIfEmptyBucket

struct FWeightedMission { float Weight; bool bEmptyOption;
                          FGameplayTagRequirements FactTagRequirements;
                          TArray<FFactValueRequirement> FactValueRequirements;
                          UBrunoMissionData* Mission; }

class UBrunoMissionData : UBitReactorMissionData
    FText GetLocationName() / GetLocationTag() / GetRegionTag()

class ABrunoStrategyRandomizationManager : AInfo
    FSimpleRandomGenerator GenericMissionTableGenerator, CampaignMissionTableGenerator,
                           CampaignCrisisMissionTableGenerator, CampaignCrisisOperationGenerator,
                           MissionUnqueueGenerator, ShopItemGenerator, CrossTrainingGenerator,
                           GenericRewardTableGenerator, GenericRecipeTableGenerator, ...
    void  SetSeed(int32) / int32 GetSeed()
    int32 InitialSeed;  bool bSeeded

Weighted-table assets: /Game/Game/GameData/MissionData/MissionTables/
    SK_Table_Imperial  SK_Table_Outlaws  SK_Table_Coil  SK_Table_Sepratists  SK_Table_CrisisTable
Mission data assets:   /Game/Game/GameData/MissionData/{Story_Main,AuthoredHero,Optional,Optional/CrisisMissions}/
```

## Strategy objectives (the holotable "objectives" system)

```text
class ABrunoStrategyObjectiveManager : AInfo
    FObjectiveID AddObjective(UBrunoStrategyObjective* NewObjective)
    TArray<...>  GetCurrentObjectives() / GetCompletedObjectives() / GetExpiredObjectives() / GetHiddenObjectives()
    bool  TryCompleteObjective(FObjectiveID) / TryExpireObjective(FObjectiveID) / TryDisplayObjective(FObjectiveID)
    bool  ForceCompleteObjective(FObjectiveID) / ForceExpireObjective(FObjectiveID)
    void  SetObjectiveProgress / ModifyObjectiveProgress / SetObjectiveMaxProgress
    -- delegates OnObjectiveAdded / OnObjectiveCompleted / OnObjectiveExpired / OnObjectiveDisplayed / OnObjectiveProgressChanged
```

## Roster / economy / facilities

```text
class ABrunoRosterManager : AInfo
    TArray<AActor*> GetRosterActors()
    void  DismissCharacterFromRoster(AActor*)
    -- field RosterActors

class ABrunoHQInventory : AInfo
    int32 GetTotalAmountOwned(UBrunoInventoryItem*)
    void  AddItem(UBrunoInventoryItem*, int32 Amount)          -- negative to spend
    void  SetBonusEquipmentSlots(FGameplayTag, int32)
    void  RefreshEquipmentSlots(AActor*, FGameplayTag)

class ABrunoFacilityManager : AInfo
    bool  IsFacilityBlocked(FGameplayTag)
    void  RemoveFacilityBlockingKey(FGameplayTag, FString)
    -- field FacilityBlockingMap
    void  RestockShop(FGameplayTag)                            -- hookable
    void  AddItemToShop(FGameplayTag, <NewShopItem struct>)

class ABrunoRosterLevelManager : AInfo
    int32 GetRosterLevel() / GetMaxRosterLevel()
    void  GainRosterLevel() / CheckForNewUpgradeRecipeAvailable()
    int32 RosterLevel                                          -- Den level, 1..10

class ABrunoFocusCentral : AInfo
    void  GainBaseFocusPoints(int32)

Statics CDOs (/Script/Bruno.Default__X, most take a WorldCtx):
  BrunoStrategyStatics : GetItemAmount(w,item), AddItem(w,item,n),
                         GetAvailableCrossTrainings(a,b), ModifyAvailableCrossTrainings(a,b,delta),
                         GainBondPointsForCharacters(AActor* a, AActor* b)
  BrunoGameStatics     : GrantItem(w,item,n)
  BrunoRosterStatics   : GetAllRosterActors(w), GetAvailableRosterActors(w)

Credits item: /Game/Game/GameData/ItemData/Resources/Resource_Credits
Intel  item : /Game/Game/GameData/ItemData/Resources/Resource_Intelligence
```

## Permadeath / ironman / tutorials (framework layer)

```text
StaticFindObject("/Script/BitReactorGame.Default__BitReactorGameStatics")
    bool GetPermaDeathWC(gi) / void SetPermaDeath(gi, bool)
    bool GetIronmanMode(gi)  / void SetIronmanMode(gi, bool)

GameInstance.StrategyData.bPermaDeath / .bIronman / .bEnableTutorials    -- direct fields
GameInstance.bFirstTimeUserExperience / :SetFirstTimeUserExperience(bool)

FindFirstOf("BrunoSaveGameSubsystem")
    bool AreSaveGamesBlocked()
    FString GetSaveGameBlockerReason()
    void RemoveUnconditionalSaveBlocker(gi)

FindFirstOf("BitReactorTutorialManagerSubsystem")
    bool bEnableTutorialSystem, bAllowNewTutorials
    void PauseNewTutorials()
FindFirstOf("BitReactorUserSettingsLocal")
    void SetPlayTutorialMission(bool), SetShowTutorials(bool)
FindFirstOf("BitReactorCoreUserProfile")
    bool bTutorialMission, bTutorialPopups

FindFirstOf("BrunoDatabankNewCharacterViewModel")           -- hook :ConfirmNewCharacter / :ConfirmNewDatabankCharacter
```

## CheatManager

```text
PlayerController.CheatManager  (also FindFirstOf("BP_BrunoCheatManager_C"))
    CompleteMission()  CompleteEncounter()  GrantFocusPoints(FString name)
    GainRosterLevel()  ResetActionPoints(bool)
```
