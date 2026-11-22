-- ============================================================================
-- ZC_Endless  -  endless / career mode for STAR WARS Zero Company
--
--  1. BrunoCampaign:ShouldCampaignComplete is forced to false -> the story
--     never rolls credits after the final arc.
--  2. (experimental) On each strategy turn / Den entry, if the holotable has
--     fewer than MinBoardMissions, skirmishes are drawn from the SK_Table_*
--     weighted pools until it has TargetBoardMissions.
--  3. Optional: freeze the day counter (sandbox), disable permadeath / ironman,
--     suppress the tutorial system.
--
--  In-game menu: press End (configurable). Number keys 1-7 toggle rows.
--
--  Install: this folder in ue4ss/Mods/, listed in mods.txt / mods.json.
--  Uninstall / vanilla: remove the folder. No save data is altered directly.
--
--  CREDITS - techniques and API knowledge reused from these Nexus Mods authors:
--    Caites    - mods 88 (Skip Tutorial + Permadeath) & 103 (Mission and
--                Campaign Time Control): turn-blocking keys, CanAdvanceStrategyTurn,
--                permadeath / ironman / tutorial-suppression, Den auto-unlock hook
--    malekk14  - mod 107 (Zero Company Long Play / ZC_CycleFreeze): the
--                turn-blocking-key clock freeze, mission-complete hook, TurnManager
--                NotifyOnNewObject re-arm pattern
--    matutela22- mods 90 (Operator Maintenance) & 106 (Custom Company Start):
--                UMG panel construction, post-turn hook pattern, RosterManager /
--                HQInventory / FacilityManager access, StrategyData.StrategyTurn
--    HazeMP    - mod 40 (BlackMarket Stock Injector): list-injection pattern,
--                Restock hook, struct-shape trial, LoadAsset + StaticFindObject
--    DevToolsMaster - mod 47 (UE4SS Cheat Menu): the FGuid marshalling constraint,
--                clickable-UMG approach, BrunoStrategyStatics / RosterStatics API
--    arctco    - mod 44 (Squad Six): the "125 mission definitions" insight,
--                squad model, mission-squad-select UI
--    Vercadi   - mod 9: the game-specific UE4SS build this runs on
--    UE4SS-RE team (https://github.com/UE4SS-RE/RE-UE4SS) - UE4SS itself
--  Full list with links: CREDITS.md
-- ============================================================================

local UEHelpers = require("UEHelpers")

-- ---- config ---------------------------------------------------------------
local DEFAULTS = {
    EnableBoardTopUp = false,
    MinBoardMissions = 3,
    TargetBoardMissions = 7,
    AllowDuplicates = false,
    ShowPanel = false,
    TogglePanelKey = "END",
    PanelAutoShowSeconds = 5,
    Tables = {
        "/Game/Game/GameData/MissionData/MissionTables/SK_Table_Imperial.SK_Table_Imperial",
        "/Game/Game/GameData/MissionData/MissionTables/SK_Table_Outlaws.SK_Table_Outlaws",
        "/Game/Game/GameData/MissionData/MissionTables/SK_Table_Coil.SK_Table_Coil",
        "/Game/Game/GameData/MissionData/MissionTables/SK_Table_Sepratists.SK_Table_Sepratists",
    },
    IncludeCrisis = false,
    CrisisTable = "/Game/Game/GameData/MissionData/MissionTables/SK_Table_CrisisTable.SK_Table_CrisisTable",
    NeverEndCampaign = true,
    FreezeClock = false,
    ToggleFreezeKey = "F9",
    DisablePermadeath = false,
    DisableIronman = false,
    DisableTutorials = false,
    ForceTopUpKey = "F8",
    DebugLog = true,
}
local cfg = DEFAULTS
do
    local ok, loaded = pcall(require, "config")
    if ok and type(loaded) == "table" then
        cfg = loaded
        for k, v in pairs(DEFAULTS) do
            if cfg[k] == nil then
                cfg[k] = v
            end
        end
    end
    -- runtime overrides saved from the in-game menu (numpad 6)
    local ok2, saved = pcall(require, "config_saved")
    if ok2 and type(saved) == "table" then
        for k, v in pairs(saved) do
            cfg[k] = v
        end
    end
end

local FREEZE_KEY = "ZC_Endless_Freeze"
-- UE4SS loads this file with luaL_loadfile, so the chunk source is "@<full path>\main.lua";
-- config_saved.lua sits next to it, in the folder require() reads it from.
local function ScriptDirectory()
    local info = debug and debug.getinfo and debug.getinfo(1, "S")
    local source = info and info.source
    if type(source) ~= "string" then
        return nil
    end
    return source:match("^@(.*[/\\])")
end

local SCRIPT_DIR = ScriptDirectory()
local SAVED_PATH = SCRIPT_DIR and (SCRIPT_DIR .. "config_saved.lua")
if not SAVED_PATH then
    print("[ZC_Endless] WARNING: could not find the Scripts folder; menu save (7) is disabled.\n")
end

local function PersistSettings()
    if not SAVED_PATH then
        return false
    end
    local f, err = io.open(SAVED_PATH, "w")
    if not f then
        print("[ZC_Endless] could not write " .. SAVED_PATH .. ": " .. tostring(err) .. "\n")
        return false
    end
    f:write("-- written by ZC_Endless in-game menu (numpad 6). delete to reset to config.lua.\n")
    f:write("return {\n")
    for _, k in ipairs({
        "NeverEndCampaign",
        "FreezeClock",
        "EnableBoardTopUp",
        "DisablePermadeath",
        "DisableIronman",
        "DisableTutorials",
        "ShowPanel",
    }) do
        f:write(string.format("    %s = %s,\n", k, tostring(cfg[k] and true or false)))
    end
    f:write("}\n")
    f:close()
    return true
end

-- ---- helpers ------------------------------------------------------------
local function log(fmt, ...)
    if not cfg.DebugLog then
        return
    end
    local msg = fmt
    if select("#", ...) > 0 then
        local ok, s = pcall(string.format, fmt, ...)
        if ok then
            msg = s
        end
    end
    print("[ZC_Endless] " .. tostring(msg) .. "\n")
end

local function safe(fn)
    local ok, r = pcall(fn)
    if ok then
        return r
    end
end

local function valid(o)
    return o ~= nil and (safe(function()
        return o:IsValid()
    end) == true)
end

local function WorldCtx()
    local o = safe(function()
        return UEHelpers.GetWorldContextObject()
    end)
    if valid(o) then
        return o
    end
    o = safe(function()
        return UEHelpers.GetPlayerController()
    end)
    if valid(o) then
        return o
    end
    return safe(function()
        return UEHelpers.GetGameInstance()
    end)
end

local function find(cls)
    local o = safe(function()
        return FindFirstOf(cls)
    end)
    if valid(o) then
        return o
    end
end

-- ABrunoStrategyGameState holds direct pointers to every strategy manager.
local function GameState()
    return find("BrunoStrategyGameState") or find("BP_BrunoStrategyGameState_C")
end

local function MissionCentral()
    local gs = GameState()
    local mc = gs and safe(function()
        return gs.MissionCentral
    end)
    if valid(mc) then
        return mc
    end
    return find("BrunoMissionCentral") or find("BP_BrunoMissionCentral_C")
end

local function RandomizationManager()
    local gs = GameState()
    local rm = gs and safe(function()
        return gs.RandomizationManager
    end)
    if valid(rm) then
        return rm
    end
    return find("BrunoStrategyRandomizationManager") or find("BP_BrunoRandomizationManager_C")
end

local function TurnManager()
    local gs = GameState()
    local tm = gs and safe(function()
        return gs.StrategyTurnManager
    end)
    if valid(tm) then
        return tm
    end
    return find("BrunoStrategyTurnManager")
end

local function GameInstance()
    return find("BrunoGameInstance")
        or find("BP_BrunoGameInstance_C")
        or safe(function()
            return UEHelpers.GetGameInstance()
        end)
end

local function LoadObj(path)
    local o = safe(function()
        return StaticFindObject(path)
    end)
    if valid(o) then
        return o
    end
    safe(function()
        LoadAsset(path)
    end)
    return safe(function()
        return StaticFindObject(path)
    end)
end

-- ---- available-mission count -----------------------------------------
-- Prefer the view-model's int accessor; fall back to counting the TMap.
local function AvailableMissionCount()
    local vm = find("BrunoStrategyTurnViewModel")
    if vm then
        local n = safe(function()
            return vm:GetTotalAvailableMissions()
        end)
        if type(n) == "number" then
            return n
        end
    end
    local mc = MissionCentral()
    if not mc then
        return nil
    end
    local m = safe(function()
        return mc:GetAvailableMissions()
    end)
    if m == nil then
        return nil
    end
    local n = safe(function()
        return #m
    end)
    if type(n) == "number" and n > 0 then
        return n
    end
    local count = 0
    local okForEach = pcall(function()
        m:ForEach(function()
            count = count + 1
        end)
    end)
    if okForEach then
        return count
    end
    return nil
end

-- ---- board top-up ---------------------------------------------------
-- NOTE: in Zero Company the strategy turn only advances when the player
-- LAUNCHES a mission - there is no idle "end turn". So an empty board = a
-- soft-lock. The top-up therefore runs on Den entry as well as turn-begin.
local topping = false
local lastTopUpAt = 0
local TOPUP_COOLDOWN = 6.0 -- seconds; ignored for manual/console triggers
local PanelShow -- forward decl (assigned in the panel section below)

local function TopUp(reason)
    if topping then
        return
    end
    if not cfg.EnableBoardTopUp then
        if reason == "manual" or reason == "console" then
            log(
                "top-up: disabled (config.EnableBoardTopUp = false). board count now = %s",
                tostring(AvailableMissionCount())
            )
        end
        return
    end
    local forced = (reason == "manual" or reason == "console")
    if not forced and (os.clock() - lastTopUpAt) < TOPUP_COOLDOWN then
        return
    end
    lastTopUpAt = os.clock()
    topping = true
    local done = function()
        topping = false
    end

    local mc = MissionCentral()
    local rm = RandomizationManager()
    local wc = WorldCtx()
    if not (mc and rm and wc) then
        log(
            "top-up (%s): strategy layer not ready (mc=%s rm=%s wc=%s)",
            tostring(reason),
            tostring(mc ~= nil),
            tostring(rm ~= nil),
            tostring(wc ~= nil)
        )
        return done()
    end

    local have = AvailableMissionCount()
    if have == nil then
        log("top-up (%s): could not read board count; injecting a default batch", tostring(reason))
        have = 0
    end
    if have >= cfg.MinBoardMissions then
        log("top-up (%s): board has %d (>= %d) - nothing to do", tostring(reason), have, cfg.MinBoardMissions)
        return done()
    end

    local need = math.max(0, cfg.TargetBoardMissions - have)
    log("top-up (%s): board has %d, want %d, drawing %d", tostring(reason), have, cfg.TargetBoardMissions, need)

    local tables = {}
    for _, p in ipairs(cfg.Tables or {}) do
        tables[#tables + 1] = p
    end
    if cfg.IncludeCrisis and cfg.CrisisTable then
        tables[#tables + 1] = cfg.CrisisTable
    end
    if #tables == 0 then
        log("top-up: no tables configured")
        return done()
    end

    local added, i, guard = 0, 1, 0
    while added < need and guard < need * 4 + #tables do
        guard = guard + 1
        local path = tables[((i - 1) % #tables) + 1]
        i = i + 1
        local tbl = LoadObj(path)
        if valid(tbl) then
            local batch = math.min(2, need - added)
            -- SelectAndAddMissions(WorldCtx, FSimpleRandomGenerator& Generator,
            --                      int32 NumToSelect, bool bAllowDuplicates)
            -- Generator is an in/out struct param -> pass an empty Lua table so UE4SS
            -- can marshal it. Passing the raw struct userdata errors ("no table on the stack").
            local ok, res = pcall(function()
                return tbl:SelectAndAddMissions(wc, {}, batch, cfg.AllowDuplicates and true or false)
            end)
            if ok then
                local n = safe(function()
                    return #res
                end) or batch
                added = added + n
                log("  + %d from %s", n, path:match("([^/.]+)%.[^.]+$") or path)
            else
                -- do NOT attempt any other UFunction call here; a bad struct arg
                -- crashes the whole process, not just Lua.
                log(
                    "  ! SelectAndAddMissions failed on %s: %s (skipping - no risky fallback)",
                    path:match("([^/.]+)%.[^.]+$") or path,
                    tostring(res)
                )
                break
            end
        else
            log("  ! table not found: %s", path)
        end
    end
    log("top-up (%s): added ~%d mission(s)", tostring(reason), added)
    if PanelShow then
        pcall(PanelShow)
    end
    done()
end

-- ---- permadeath off (mod 88 approach) ------------------------------
local function ApplyPermadeath()
    if not (cfg.DisablePermadeath or cfg.DisableIronman) then
        return
    end
    local gi = GameInstance()
    local statics = safe(function()
        return StaticFindObject("/Script/BitReactorGame.Default__BitReactorGameStatics")
    end)
    if not (valid(gi) and statics) then
        return
    end
    if cfg.DisablePermadeath then
        pcall(function()
            statics:SetPermaDeath(gi, false)
        end)
        pcall(function()
            gi.StrategyData.bPermaDeath = false
        end)
    end
    if cfg.DisableIronman then
        pcall(function()
            statics:SetIronmanMode(gi, false)
        end)
        pcall(function()
            gi.StrategyData.bIronman = false
        end)
        local ss = find("BrunoSaveGameSubsystem")
        if ss then
            local blocked = safe(function()
                return ss:AreSaveGamesBlocked()
            end)
            if blocked then
                pcall(function()
                    ss:RemoveUnconditionalSaveBlocker(gi)
                end)
            end
        end
    end
end

-- ---- tutorial suppression (technique from Nexus mod 88 by Caites) --------
local function ApplyTutorials()
    if cfg.DisableTutorials == nil then
        return
    end
    local off = cfg.DisableTutorials and true or false
    local want = not off -- value to write when we're NOT suppressing

    local tm = find("BitReactorTutorialManagerSubsystem")
    if tm then
        pcall(function()
            tm.bEnableTutorialSystem = want
        end)
        pcall(function()
            tm.bAllowNewTutorials = want
        end)
        if off then
            pcall(function()
                tm:PauseNewTutorials()
            end)
        end
    end
    local s = find("BitReactorUserSettingsLocal")
    if s then
        pcall(function()
            s:SetPlayTutorialMission(want)
        end)
        pcall(function()
            s:SetShowTutorials(want)
        end)
    end
    local p = find("BitReactorCoreUserProfile")
    if p then
        pcall(function()
            p.bTutorialMission = want
        end)
        pcall(function()
            p.bTutorialPopups = want
        end)
    end
    local gi = GameInstance()
    if gi and off then
        -- only ever CLEAR the first-time-user flag; never re-arm it (would replay the intro)
        pcall(function()
            gi:SetFirstTimeUserExperience(false)
        end)
        pcall(function()
            gi.bFirstTimeUserExperience = false
        end)
    end
    if gi then
        pcall(function()
            gi.StrategyData.bEnableTutorials = want
        end)
    end
end

-- ---- clock freeze (sandbox) --------------------------------------
local freezeOn = cfg.FreezeClock and true or false

local function ApplyFreeze()
    if not freezeOn then
        return
    end
    local tm = TurnManager()
    if not tm then
        return
    end
    local held = safe(function()
        return tm:HasTurnBlockingKey(FREEZE_KEY)
    end)
    if not held then
        pcall(function()
            tm:AddTurnBlockingKey(FREEZE_KEY)
        end)
        log("clock frozen (blocking key held)")
    end
end

local function ClearFreeze()
    local tm = TurnManager()
    if not tm then
        return
    end
    pcall(function()
        tm:RemoveTurnBlockingKey(FREEZE_KEY)
    end)
    log("clock unfrozen")
end

-- ---- hooks -------------------------------------------------------
local armed = { campaign = false, turn = false, den = false }

local DEN_ONSTATEBEGIN = "/Game/Game/GameData/Logic/GameplayMaster/GameplayMasterStates/"
    .. "GMState_Headquarters_ExplorePhase.GMState_Headquarters_ExplorePhase_C:OnStateBegin"

local function ArmCampaignHook()
    if armed.campaign or not cfg.NeverEndCampaign then
        return armed.campaign
    end
    local ok = pcall(function()
        RegisterHook(
            "/Script/Bruno.BrunoCampaign:ShouldCampaignComplete",
            function() end,
            function(self, Turn, ReturnValue)
                if not cfg.NeverEndCampaign then
                    return
                end
                pcall(function()
                    ReturnValue:set(false)
                end)
            end
        )
    end)
    if ok then
        armed.campaign = true
        log("hook armed: ShouldCampaignComplete -> false")
    end
    return armed.campaign
end

local function ArmTurnHook()
    if armed.turn then
        return true
    end
    local ok = pcall(function()
        RegisterHook("/Script/Bruno.BrunoMissionCentral:OnStrategyTurnBegin", function() end, function(self, Turn)
            local t = safe(function()
                return Turn:get()
            end)
            -- let the game finish its own turn-begin mission churn first
            ExecuteWithDelay(2000, function()
                ExecuteInGameThread(function()
                    ApplyFreeze()
                    ApplyPermadeath()
                    ApplyTutorials()
                    TopUp("turn " .. tostring(t))
                end)
            end)
        end)
    end)
    if ok then
        armed.turn = true
        log("hook armed: OnStrategyTurnBegin -> board top-up")
    end
    return armed.turn
end

-- Den entry: the reliable refill point, since time only advances via missions
-- and an empty board would otherwise soft-lock the player.
local function ArmDenHook()
    if armed.den then
        return true
    end
    local ok = pcall(function()
        RegisterHook(DEN_ONSTATEBEGIN, function() end, function()
            ExecuteWithDelay(2500, function()
                ExecuteInGameThread(function()
                    ApplyFreeze()
                    ApplyPermadeath()
                    ApplyTutorials()
                    TopUp("den")
                end)
            end)
        end)
    end)
    if ok then
        armed.den = true
        log("hook armed: Den entry -> board top-up")
    end
    return armed.den
end

local function TryArm()
    ArmCampaignHook()
    ArmTurnHook()
    ArmDenHook()
    local campaignOK = armed.campaign or not cfg.NeverEndCampaign
    if not (campaignOK and armed.turn and armed.den) then
        ExecuteWithDelay(5000, function()
            ExecuteInGameThread(TryArm)
        end)
    else
        log("all hooks armed.")
    end
end

-- re-apply state whenever a new strategy map finishes loading
if type(RegisterLoadMapPostHook) == "function" then
    RegisterLoadMapPostHook(function()
        ExecuteWithDelay(4000, function()
            ExecuteInGameThread(function()
                ApplyPermadeath()
                ApplyTutorials()
                ApplyFreeze()
            end)
        end)
    end)
end

-- ---- on-screen panel (UMG, mirrors the pattern in Nexus mods 90/107) ----
local Panel = { widget = nil, text = nil, seq = 0, pinned = false, hideTok = 0 }

local function DestroyPanel()
    if valid(Panel.widget) then
        pcall(function()
            Panel.widget:RemoveFromParent()
        end)
    end
    Panel.widget, Panel.text = nil, nil
end

local function BuildPanel()
    if valid(Panel.widget) and valid(Panel.text) then
        return true
    end
    DestroyPanel()
    local outer = safe(function()
        return UEHelpers.GetPlayerController()
    end)
    if not valid(outer) then
        outer = safe(function()
            return UEHelpers.GetGameInstance()
        end)
    end
    if not valid(outer) then
        return false
    end
    local UW = safe(function()
        return StaticFindObject("/Script/UMG.UserWidget")
    end)
    local WT = safe(function()
        return StaticFindObject("/Script/UMG.WidgetTree")
    end)
    local CP = safe(function()
        return StaticFindObject("/Script/UMG.CanvasPanel")
    end)
    local BR = safe(function()
        return StaticFindObject("/Script/UMG.Border")
    end)
    local TB = safe(function()
        return StaticFindObject("/Script/UMG.TextBlock")
    end)
    if not (UW and WT and CP and BR and TB) then
        return false
    end

    Panel.seq = Panel.seq + 1
    local sfx = tostring(Panel.seq)
    local w = safe(function()
        return StaticConstructObject(UW, outer, FName("ZCEndless_W_" .. sfx))
    end)
    if not valid(w) then
        return false
    end
    local tree = safe(function()
        return StaticConstructObject(WT, w, FName("ZCEndless_T_" .. sfx))
    end)
    pcall(function()
        w.WidgetTree = tree
    end)
    local canvas = safe(function()
        return StaticConstructObject(CP, tree, FName("ZCEndless_C_" .. sfx))
    end)
    pcall(function()
        tree.RootWidget = canvas
    end)
    local border = safe(function()
        return StaticConstructObject(BR, canvas, FName("ZCEndless_B_" .. sfx))
    end)
    if not valid(border) then
        return false
    end
    pcall(function()
        border:SetBrushColor({ R = 0.02, G = 0.03, B = 0.05, A = 0.86 })
    end)
    pcall(function()
        border:SetPadding({ Left = 14.0, Top = 8.0, Right = 14.0, Bottom = 8.0 })
    end)
    pcall(function()
        canvas:AddChild(border)
    end)
    local txt = safe(function()
        return StaticConstructObject(TB, border, FName("ZCEndless_X_" .. sfx))
    end)
    if not valid(txt) then
        return false
    end
    pcall(function()
        txt:SetColorAndOpacity({ SpecifiedColor = { R = 0.75, G = 0.92, B = 1.0, A = 1.0 } })
    end)
    pcall(function()
        txt:SetShadowColorAndOpacity({ R = 0, G = 0, B = 0, A = 0.9 })
        txt:SetShadowOffset({ X = 1.0, Y = 1.0 })
    end)
    pcall(function()
        txt.Font.Size = 18
    end)
    pcall(function()
        border:SetContent(txt)
    end)
    local slot = safe(function()
        return border.Slot
    end)
    if valid(slot) then
        pcall(function()
            slot:SetAnchors({ Minimum = { X = 0, Y = 0 }, Maximum = { X = 0, Y = 0 } })
        end)
        pcall(function()
            slot:SetAlignment({ X = 0, Y = 0 })
        end)
        pcall(function()
            slot:SetPosition({ X = 24.0, Y = 120.0 })
        end)
        pcall(function()
            slot:SetAutoSize(true)
        end)
    end
    pcall(function()
        w:AddToViewport(500)
    end)
    Panel.widget, Panel.text = w, txt
    return valid(Panel.text)
end

local function onoff(b)
    return b and "ON " or "off"
end

local function PanelString()
    local n = AvailableMissionCount()
    return table.concat({
        "== ZC ENDLESS ==   board: " .. (n == nil and "?" or tostring(n)),
        "",
        " [1] campaign never ends : " .. onoff(cfg.NeverEndCampaign),
        " [2] freeze clock        : " .. onoff(freezeOn),
        " [3] board top-up (exp)  : " .. onoff(cfg.EnableBoardTopUp),
        " [4] disable permadeath  : " .. onoff(cfg.DisablePermadeath),
        " [5] disable tutorials   : " .. onoff(cfg.DisableTutorials),
        " [6] top up board now",
        " [7] save settings",
        "",
        " [End] close",
    }, "\n")
end

-- ESlateVisibility: 0 = Visible, 1 = Collapsed
PanelShow = function(seconds)
    if not cfg.ShowPanel then
        return
    end
    if not BuildPanel() then
        return
    end
    pcall(function()
        Panel.text:SetText(FText(PanelString()))
    end)
    pcall(function()
        Panel.widget:SetVisibility(0)
    end)
    Panel.hideTok = Panel.hideTok + 1
    local mine = Panel.hideTok
    local s = seconds or cfg.PanelAutoShowSeconds or 5
    if not Panel.pinned and s > 0 then
        ExecuteWithDelay(s * 1000, function()
            ExecuteInGameThread(function()
                if mine == Panel.hideTok and not Panel.pinned and valid(Panel.widget) then
                    pcall(function()
                        Panel.widget:SetVisibility(1)
                    end)
                end
            end)
        end)
    end
end

local function PanelToggle()
    Panel.pinned = not Panel.pinned
    if Panel.pinned then
        PanelShow(0)
    elseif valid(Panel.widget) then
        pcall(function()
            Panel.widget:SetVisibility(1)
        end)
    end
end

-- number keys 1-7 while the panel is pinned
local function MenuAction(n)
    if not Panel.pinned then
        return
    end
    if n == 1 then
        cfg.NeverEndCampaign = not cfg.NeverEndCampaign
        log("menu: campaign never ends -> %s", onoff(cfg.NeverEndCampaign))
    elseif n == 2 then
        freezeOn = not freezeOn
        if freezeOn then
            ApplyFreeze()
        else
            ClearFreeze()
        end
    elseif n == 3 then
        cfg.EnableBoardTopUp = not cfg.EnableBoardTopUp
        log("menu: board top-up -> %s (experimental)", onoff(cfg.EnableBoardTopUp))
    elseif n == 4 then
        cfg.DisablePermadeath = not cfg.DisablePermadeath
        log("menu: disable permadeath -> %s", onoff(cfg.DisablePermadeath))
        if cfg.DisablePermadeath then
            ApplyPermadeath()
        end
    elseif n == 5 then
        cfg.DisableTutorials = not cfg.DisableTutorials
        log("menu: disable tutorials -> %s", onoff(cfg.DisableTutorials))
        ApplyTutorials()
    elseif n == 6 then
        TopUp("manual")
    elseif n == 7 then
        log("menu: settings %s", PersistSettings() and "saved" or "SAVE FAILED")
    end
    PanelShow(0) -- refresh + keep pinned
end

-- ---- keybinds --------------------------------------------------
local function key(name)
    return name and Key[name]
end

local kTop = key(cfg.ForceTopUpKey)
if kTop then
    pcall(function()
        RegisterKeyBind(kTop, function()
            ExecuteInGameThread(function()
                TopUp("manual")
            end)
        end)
    end)
end

local kFreeze = key(cfg.ToggleFreezeKey)
if kFreeze then
    pcall(function()
        RegisterKeyBind(kFreeze, function()
            ExecuteInGameThread(function()
                freezeOn = not freezeOn
                if freezeOn then
                    ApplyFreeze()
                else
                    ClearFreeze()
                end
                if PanelShow then
                    pcall(PanelShow)
                end
            end)
        end)
    end)
end

local kPanel = key(cfg.TogglePanelKey)
if kPanel then
    pcall(function()
        RegisterKeyBind(kPanel, function()
            ExecuteInGameThread(function()
                PanelToggle()
            end)
        end)
    end)
end

-- number keys 1-6 drive the menu (only act while the panel is pinned).
-- top-row digits (NumLock-independent); they only do anything with the menu open.
do
    local words = { "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN" }
    for n = 1, 7 do
        local k = key(words[n]) or key("NUM_" .. words[n])
        if k then
            pcall(function()
                RegisterKeyBind(k, function()
                    ExecuteInGameThread(function()
                        MenuAction(n)
                    end)
                end)
            end)
        end
    end
end

-- console: zcendless_topup
pcall(function()
    RegisterConsoleCommandGlobalHandler("zcendless_topup", function()
        ExecuteInGameThread(function()
            TopUp("console")
        end)
        return true
    end)
end)

-- ---- go ------------------------------------------------------
TryArm()
if cfg.ShowPanel then
    ExecuteWithDelay(6000, function()
        ExecuteInGameThread(function()
            PanelShow(cfg.PanelAutoShowSeconds)
        end)
    end)
end
log(
    "loaded. career=%s freeze=%s topup=%s permadeath_off=%s  |  %s opens the menu, numpad 1-6 = actions",
    tostring(cfg.NeverEndCampaign),
    tostring(cfg.FreezeClock),
    tostring(cfg.EnableBoardTopUp),
    tostring(cfg.DisablePermadeath),
    tostring(cfg.TogglePanelKey)
)
