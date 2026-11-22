-- ============================================================================
-- ZC_Endless - configuration
-- Edit values, then hot-reload (Ctrl+R) or relaunch.
-- The in-game menu (see below) can also change these live and save them to
-- config_saved.lua, which is loaded on top of this file. Delete config_saved.lua
-- to go back to the values here.
-- ============================================================================
return {
    -- ---- Campaign (safe, on by default) --------------------------------
    -- Force BrunoCampaign:ShouldCampaignComplete -> false so the story never
    -- rolls credits after the final arc. This alone = "campaign never ends";
    -- you keep whatever missions the game itself still generates.
    NeverEndCampaign = true,

    -- Career vs sandbox clock:
    --   false = days keep advancing (they only advance when a mission finishes anyway)
    --   true  = hold a turn-blocking key so the day counter never moves
    FreezeClock = false,
    ToggleFreezeKey = "F9",

    -- ---- Holotable top-up (EXPERIMENTAL - off by default) --------------
    -- Injecting missions via the weighted-table API is still being worked out
    -- (the RNG-generator arg is an in/out struct that UE4SS marshals awkwardly).
    -- Leave this false until it is proven; a bad call can crash the game.
    EnableBoardTopUp = false,
    MinBoardMissions = 3,
    TargetBoardMissions = 7,
    AllowDuplicates = false,
    Tables = {
        "/Game/Game/GameData/MissionData/MissionTables/SK_Table_Imperial.SK_Table_Imperial",
        "/Game/Game/GameData/MissionData/MissionTables/SK_Table_Outlaws.SK_Table_Outlaws",
        "/Game/Game/GameData/MissionData/MissionTables/SK_Table_Coil.SK_Table_Coil",
        "/Game/Game/GameData/MissionData/MissionTables/SK_Table_Sepratists.SK_Table_Sepratists",
    },
    IncludeCrisis = false,
    CrisisTable = "/Game/Game/GameData/MissionData/MissionTables/SK_Table_CrisisTable.SK_Table_CrisisTable",

    -- ---- Permadeath (technique from Nexus mod 88 by Caites) ----------
    DisablePermadeath = false,
    DisableIronman = false,

    -- ---- Tutorials (technique from Nexus mod 88 by Caites) ----------
    -- true  = suppress the tutorial system, tutorial mission, and popups
    -- false = stop suppressing (does NOT force-replay the intro)
    DisableTutorials = false,

    -- ---- On-screen menu -------------------------------------------
    -- Opens top-left. While open, number keys 1-7 toggle rows / run actions:
    --   1 campaign-never-ends  2 freeze clock      3 board top-up
    --   4 disable permadeath   5 disable tutorials 6 top up now
    --   7 save settings (-> config_saved.lua)
    ShowPanel = true,
    TogglePanelKey = "END", -- F11 is the game's fullscreen toggle. alts: HOME, INS, F1..F4
    PanelAutoShowSeconds = 5,

    -- ---- Misc --------------------------------------------------------
    ForceTopUpKey = "F8",
    DebugLog = true,
}
