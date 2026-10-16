-- ==============================================================================
-- SodaLite GLOBAL + FULL ESP + FULL AIMBOT (fixed, no cuts)
-- ==============================================================================

local BRPlayerCharacterBase = {
  ServerRPC = {}, ClientRPC = {}, MulticastRPC = {}, LuaEventContainer = {}
}

BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }

-- ==============================================================================
-- TYPES
-- ==============================================================================
local function FLinearColor(r, g, b, a)
    local col = { R=r or 1, G=g or 1, B=b or 1, A=a or 1, r=r or 1, g=g or 1, b=b or 1, a=a or 1 }
    local ok, LC = pcall(import, "LinearColor")
    if ok and LC then return LC(r, g, b, a) end
    return col
end
local function FVector2D(x, y)
    local vec = { X=x or 0, Y=y or 0, x=x or 0, y=y or 0 }
    local ok, V = pcall(import, "Vector2D")
    if ok and V then return V(x or 0, y or 0) end
    return vec
end

local Colors = {
    bg_main     = FLinearColor(0.07, 0.09, 0.14, 0.96),
    bg_header   = FLinearColor(0.04, 0.05, 0.08, 1.00),
    bg_row      = FLinearColor(0.11, 0.13, 0.18, 0.90),
    border      = FLinearColor(0.18, 0.45, 0.95, 0.90),
    accent_blue = FLinearColor(0.20, 0.50, 1.00, 1.00),
    accent_red  = FLinearColor(0.92, 0.22, 0.25, 1.00),
    text_white  = FLinearColor(0.96, 0.98, 1.00, 1.00),
    text_dim    = FLinearColor(0.60, 0.65, 0.75, 1.00),
    toggle_on   = FLinearColor(0.18, 0.55, 1.00, 1.00),
    toggle_off  = FLinearColor(0.20, 0.22, 0.28, 1.00),
    toggle_knob = FLinearColor(1.00, 1.00, 1.00, 1.00),
    slider_bg   = FLinearColor(0.16, 0.18, 0.25, 1.00),
    transparent = FLinearColor(0.00, 0.00, 0.00, 0.00),
    shadow      = FLinearColor(0.00, 0.00, 0.00, 0.45),
}

local MENU_W = 800
local MENU_H = 720
local ROW_H  = 38
local PAIR_H = 28
local menuPos = { X = 260, Y = 90 }
local FLOAT_W, FLOAT_H = 110, 38
local floatPos = { X = 750, Y = 15 }

-- ==============================================================================
-- CONFIG (persistent)
-- ==============================================================================
_G.SodaConfig = _G.SodaConfig or {
    -- SodaLite
    BlackSky=false, Wallhack=false, WallhackGlow=3, IpadView=false, IpadViewFOV=120,
    -- ESP
    EspVip=false, EspDistance=false, EspVipPro=false, EspRadar=false,
    Esp5=false, Esp6=false, Esp8=false, EspAntenna=false,
    EspName=false, EspStatic=false, EspEnemyCount=true, EspWeaponStatus=true,
    ColorBodyNew=false,
    -- Throwable
    ThrowableEnabled=false, ThrowableGrenade=false, ThrowableSmoke=false, ThrowableMolotov=false,
    ThrowableColor_Grenade=4, ThrowableColor_Smoke=4, ThrowableColor_Molotov=4, ThrowableScanMode=0,
    -- Vehicle
    VehicleEnabled=false, VehicleShowDacia=false, VehicleShowUAZ=false, VehicleShowBuggy=false,
    VehicleShowCoupe=false, VehicleShowMirado=false, VehicleShowMotor=false, VehicleShowOther=false,
    VehicleColor_Dacia=4, VehicleColor_UAZ=4, VehicleColor_Buggy=4, VehicleColor_Coupe=4,
    VehicleColor_Mirado=4, VehicleColor_Motor=4, VehicleColor_Other=4,
    -- Loot
    EspLoot=false, LootShowM416=false, LootShowAUG=false, LootShowAKM=false,
    LootShowM24=false, LootShowUMP=false, LootShowDBS=false, LootShowS12K=false,
    LootShowVest3=false, LootShowHelmet3=false, LootShowBag3=false,
    LootColor_M416=4, LootColor_AUG=4, LootColor_AKM=4, LootColor_M24=4,
    LootColor_UMP=4, LootColor_DBS=4, LootColor_S12K=4, LootColor_Vest3=4,
    LootColor_Helmet3=4, LootColor_Bag3=4, LootScanMode=0,
    -- Aimbot
    AimTouchEnable=false,
    AimTouchHipfire=false, AimTouchHipIgKnock=false, AimTouchHipIgBot=false, AimTouchHipVisCheck=false,
    AimTouchSG=false, AimTouchSGAutoFire=false, AimTouchSGIgKnock=false, AimTouchSGIgBot=false, AimTouchSGVisCheck=false,
    AimTouchScopeAll=false, AimTouchScopeIgKnock=false, AimTouchScopeIgBot=false, AimTouchScopeVisCheck=false,
    AimTouchScopeSniper=false, AimTouchSniperIgKnock=false, AimTouchSniperIgBot=false, AimTouchSniperVisCheck=false,
    AimTouchMortar=false,
    EspFovCircle=false,
    -- Exploit: FastMove
    FastMove_Enabled   = false,
    FastMove_Multiplier = 10,
    FastMove_MaxSafe   = 25,
    FastMove_RampTime  = 0.5,
}
local Config = _G.SodaConfig
_G.FufuModConfig = _G.SodaConfig

-- ==============================================================================
-- STATE
-- ==============================================================================
_G.FufuModState = _G.FufuModState or {
    LoopToken=0, AimbotLoopToken=0, TrackedMarks={}, EnemyMarks={}, IsAutoFiring=false, CustomTextData=nil,
    NativeESPReady=false, ConsoleNewWallReady=false, MagicUpdateVersion=1, LastMagicConfigHash="",
    PrevGraphicsState = {},
}
_G.FufuModState.CustomTextData = _G.FufuModState.CustomTextData or {
    AimTouchHipPrio=1, AimTouchHipBone=1, AimTouchHipCond=1, AimTouchHipSpeed=50, AimTouchHipFOV=30, AimTouchHipDist=250,
    AimTouchSGPrio=1, AimTouchSGBone=2, AimTouchSGCond=1, AimTouchSGSpeed=80, AimTouchSGFOV=40, AimTouchSGDist=30,
    AimTouchScopePrio=1, AimTouchScopeBone=2, AimTouchScopeCond=1, AimTouchScopeSpeed=40, AimTouchScopeFOV=20,
    AimTouchScopeDist=300, AimTouchScopePred=0, AimTouchScopeRecoil=0,
    AimTouchSniperPrio=1, AimTouchSniperBone=1, AimTouchSniperCond=2, AimTouchSniperSpeed=30, AimTouchSniperFOV=20,
    AimTouchSniperDist=400, AimTouchSniperPred=0,
    AimTouchMortarPred=0, AimTouchMortarFOV=360,
    AimTouchHipFOVColor=7, AimTouchSGFOVColor=1, AimTouchScopeFOVColor=6,
    AimTouchSniperFOVColor=4, AimTouchMortarFOVColor=5,
    IpadViewFOV=120, HRecoil=0.3, VRecoil=0.3,
}

_G.ColorConfig = _G.ColorConfig or { VisibleColor=4, InvisibleColor=1, Brightness=25, Glow=3.0 }

-- ==============================================================================
-- PERSISTENCE
-- ==============================================================================
local CONFIG_FILE = "SodaLite_FULL.txt"

local function GetConfigPaths(fileName)
    local paths = {}
    local pkgs = {"com.tencent.ig","com.pubg.krmobile","com.vng.pubgmobile","com.rekoo.pubgm","com.pubg.imobile"}
    for _, pkg in ipairs(pkgs) do
        table.insert(paths, "//storage/emulated/0/Android/data/"..pkg.."/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/"..fileName)
        table.insert(paths, "//storage/emulated/0/Android/data/"..pkg.."/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/"..fileName)
    end
    if os and os.getenv then
        local home = os.getenv("HOME")
        if home and home ~= "" then table.insert(paths, home.."/Documents/ShadowTrackerExtra/Saved/SaveGames/"..fileName) end
    end
    return paths
end

local function serializeTable(tbl, indent)
    indent = indent or ""
    local items = {}
    for k, v in pairs(tbl) do
        local keyStr = type(k) == "string" and string.format("[%q]", k) or "["..tostring(k).."]"
        if type(v) == "table" then
            table.insert(items, indent..keyStr.." = "..serializeTable(v, indent.."  "))
        elseif type(v) == "string" then
            table.insert(items, indent..keyStr.." = "..string.format("%q", v))
        elseif type(v) == "number" or type(v) == "boolean" then
            table.insert(items, indent..keyStr.." = "..tostring(v))
        end
    end
    return "{\n"..table.concat(items, ",\n").."\n"..indent:sub(1, math.max(#indent-2,0)).."}"
end

_G.SodaSave = function()
    pcall(function()
        local data = "return {\nConfig = "..serializeTable(_G.SodaConfig or {}, "  ")..",\n"
        data = data.."CustomTextData = "..serializeTable(_G.FufuModState.CustomTextData or {}, "  ")..",\n"
        data = data.."ColorConfig = "..serializeTable(_G.ColorConfig or {}, "  ").."\n}"
        for _, path in ipairs(GetConfigPaths(CONFIG_FILE)) do
            local f = io.open(path, "w")
            if f then f:write(data); f:close(); break end
        end
    end)
end

_G.SodaLoad = function()
    pcall(function()
        for _, path in ipairs(GetConfigPaths(CONFIG_FILE)) do
            local f = io.open(path, "r")
            if f then
                local content = f:read("*a"); f:close()
                local func = load(content)
                if func then
                    local saved = func()
                    if saved and type(saved) == "table" then
                        if saved.Config then for k, v in pairs(saved.Config) do _G.SodaConfig[k] = v end end
                        if saved.CustomTextData then for k, v in pairs(saved.CustomTextData) do _G.FufuModState.CustomTextData[k] = v end end
                        if saved.ColorConfig then for k, v in pairs(saved.ColorConfig) do _G.ColorConfig[k] = v end end
                    end
                end
                break
            end
        end
    end)
end
_G.SodaLoad()

local _lastSaveTime = 0
local function AutoSaveLoop()
    local now = os.clock()
    if now - _lastSaveTime > 5 then _lastSaveTime = now; _G.SodaSave() end
    local okT, ticker = pcall(require, "common.time_ticker")
    if okT and ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(5.0, AutoSaveLoop) end
end
AutoSaveLoop()

-- ==============================================================================
-- COLOR HELPERS
-- ==============================================================================
local COLOR_MAP = {
    [1]={R=255,G=0,B=0}, [2]={R=255,G=255,B=255}, [3]={R=255,G=255,B=0},
    [4]={R=0,G=255,B=0}, [5]={R=0,G=255,B=255}, [6]={R=0,G=0,B=255}, [7]={R=255,G=0,B=255},
}
local COLOR_PALETTE_7 = {
    [1]={R=255,G=0,B=0,A=255}, [2]={R=255,G=255,B=255,A=255}, [3]={R=255,G=255,B=0,A=255},
    [4]={R=0,G=255,B=0,A=255}, [5]={R=0,G=255,B=255,A=255}, [6]={R=0,G=0,B=255,A=255}, [7]={R=255,G=0,B=255,A=255},
}
local function GetColorBy7(idx)
    if not idx or idx < 1 or idx > 7 then idx = 4 end
    return COLOR_PALETTE_7[idx] or {R=0,G=255,B=0,A=255}
end
local function GetAppliedColor(colorIdx, brightness)
    local base = COLOR_MAP[colorIdx] or COLOR_MAP[4]
    local b = brightness or _G.ColorConfig.Brightness or 25
    return { R=math.min(255,(base.R or 0)*b/25), G=math.min(255,(base.G or 0)*b/25), B=math.min(255,(base.B or 0)*b/25), A=255 }
end
local function GetFOVColor(idx)
    if idx == 1 then return 1.0, 0.0, 0.0 end
    if idx == 2 then return 0.0, 1.0, 0.0 end
    if idx == 3 then return 0.0, 0.0, 1.0 end
    if idx == 4 then return 1.0, 1.0, 0.0 end
    if idx == 5 then return 0.65, 0.15, 1.0 end
    if idx == 6 then return 0.0, 1.0, 1.0 end
    if idx == 7 then return 1.0, 1.0, 1.0 end
    return 1.0, 1.0, 1.0
end

local C_GREEN = {R=0,G=255,B=0,A=255}
local C_YELLOW = {R=255,G=255,B=0,A=255}

-- ==============================================================================
-- CORE HELPERS
-- ==============================================================================
local function Valid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, obj); return ok and v
    end
    if Game and Game.IsValid then
        local ok, v = pcall(Game.IsValid, Game, obj); return ok and v
    end
    return true
end
local IsValid = Valid

local function SafeAddMark(id, pos, z, str, size, actor)
    local mark = nil
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            mark = InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
            if mark then _G.FufuModState.TrackedMarks[mark] = true end
        end
    end)
    return mark
end

local function SafeRemoveMark(mark)
    if not mark then return end
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.HideMapMark then InGameMarkTools.HideMapMark(mark) end
        if InGameMarkTools and InGameMarkTools.RemoveMapMark then InGameMarkTools.RemoveMapMark(mark) end
    end)
    _G.FufuModState.TrackedMarks[mark] = nil
end

local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

local function CheckIsAI(pawn, markData)
    if markData.AK_IS_BOT ~= nil then return markData.AK_IS_BOT, true end
    local isAI, hasChecked = false, false
    pcall(function()
        if pawn.bIsAI == true or pawn.IsAI == true then isAI = true; hasChecked = true end
        if type(pawn.IsBot) == "function" and pawn:IsBot() then isAI = true; hasChecked = true end
        local pState = pawn.PlayerState or (type(pawn.GetPlayerState) == "function" and pawn:GetPlayerState())
        if Valid(pState) then
            hasChecked = true
            if pState.bIsABot == true or pState.bIsBot == true then isAI = true end
            if type(pState.IsBot) == "function" and pState:IsBot() then isAI = true end
        end
        if not isAI then
            local name = pawn.PlayerName or (type(pawn.GetPlayerName) == "function" and pawn:GetPlayerName()) or ""
            if name ~= "" and (name:find("Cobra") or name:find("Target") or name:find("bot_") or name:find("b_")) then
                isAI = true; hasChecked = true
            end
        end
    end)
    if hasChecked then markData.AK_IS_BOT = isAI end
    return isAI, hasChecked
end

local function GetFirstElemSafe(elemArray)
    if elemArray and type(elemArray.Num) == "function" and elemArray:Num() > 0 then
        if type(elemArray.Get) == "function" then return elemArray:Get(0) end
    elseif elemArray and type(elemArray) == "table" and #elemArray > 0 then
        return elemArray[1]
    end
    return nil
end

local function GetAllSkeletalMeshes(enemy, markData)
    local curTime = os.clock()
    if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime) < 3.0 then
        local validMeshes = {}
        for _, m in ipairs(markData.CachedMeshes) do if Valid(m) then table.insert(validMeshes, m) end end
        markData.CachedMeshes = validMeshes
        return validMeshes
    end
    local meshes = {}
    if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
    pcall(function()
        local SkeletalMeshClass = import("SkeletalMeshComponent")
        if SkeletalMeshClass and type(enemy.GetComponentsByClass) == "function" then
            local childs = enemy:GetComponentsByClass(SkeletalMeshClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for i = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(i-1) or childs[i]
                    if Valid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)
    if markData then markData.CachedMeshes = meshes; markData.CachedMeshTime = curTime end
    return meshes
end

-- ==============================================================================
-- AIMBOT: GetEnemyTargetsFromActors + UpdateAimMeta + AimTouch (FULL)
-- ==============================================================================
_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not okData or not GameplayData then return result end
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return result end
    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
    end
    local myTeam = player:GetTeamID()
    for _, actor in pairs(allCharacters) do
        if slua.isValid(actor) and actor ~= player and actor.GetTeamID and actor:IsAlive() then
            if actor:GetTeamID() ~= myTeam then
                local dist = player:GetDistanceTo(actor)
                if dist <= radius then table.insert(result, actor) end
            end
        end
    end
    return result
end

_G.UpdateAimMeta = function(pc, player)
    pcall(function()
        local ui_util = require("client.common.ui_util")
        if ui_util then
            local vp = ui_util.GetViewportSize()
            if vp then
                _G.__AimTouch_ViewportX = vp.X
                _G.__AimTouch_CenterX = vp.X * 0.5
                _G.__AimTouch_CenterY = vp.Y * 0.5
            end
        end
        local wName = ""
        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then weapon = player:GetCurrentShootWeapon() end
        if slua.isValid(weapon) then
            wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then
                _G.__AimTouch_WeaponType = "SHOTGUN"
            elseif wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                _G.__AimTouch_WeaponType = "SNIPER"
            elseif wName:lower():find("mortar") or wName:lower():find("cối") then
                _G.__AimTouch_WeaponType = "MORTAR"
            else
                _G.__AimTouch_WeaponType = "NORMAL"
            end
        end
    end)
end

_G.AimTouch = function()
    pcall(function()
        if not _G.FufuModConfig.AimTouchEnable then return end
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end

        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS

        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then weapon = player:GetCurrentShootWeapon() end

        local isShotgun, isSniper, isMortar, currentAmmo = false, false, false, 1
        if slua.isValid(weapon) then
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then isShotgun = true end
            if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then isSniper = true end
            if wName:lower():find("mortar") or wName:lower():find("cối") then isMortar = true end
            if type(weapon.GetCurrentAmmo) == "function" then currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then currentAmmo = weapon.CurrentAmmo end
        end

        if _G.FufuModState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.FufuModState.IsAutoFiring = false
        end

        if isShotgun and currentAmmo <= 0 then return end

        local cond, prioMode, boneIdx, speedVal, fovVal, maxDistMeters = 2, 1, 1, 50, 30, 50
        local useVisCheck, igKnock, igBot = false, false, false
        local predVal, recoilCompVal = 0, 0

        if isMortar and _G.FufuModConfig.AimTouchMortar then
            local isPlaced = false
            pcall(function() if weapon and weapon.MortarState == 2 then isPlaced = true end end)
            if not isPlaced then return end
            cond=2; prioMode=1; boneIdx=4; speedVal=100
            fovVal = _G.FufuModState.CustomTextData.AimTouchMortarFOV or 360
            maxDistMeters = 2000
            predVal = _G.FufuModState.CustomTextData.AimTouchMortarPred or 0

        elseif isShotgun and _G.FufuModConfig.AimTouchSG then
            cond = _G.FufuModState.CustomTextData.AimTouchSGCond or 1
            if _G.FufuModConfig.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = _G.FufuModState.CustomTextData.AimTouchSGPrio or 1
            boneIdx = _G.FufuModState.CustomTextData.AimTouchSGBone or 2
            speedVal = _G.FufuModState.CustomTextData.AimTouchSGSpeed or 80
            fovVal = _G.FufuModState.CustomTextData.AimTouchSGFOV or 40
            maxDistMeters = _G.FufuModState.CustomTextData.AimTouchSGDist or 30
            useVisCheck = _G.FufuModConfig.AimTouchSGVisCheck
            igKnock = _G.FufuModConfig.AimTouchSGIgKnock
            igBot = _G.FufuModConfig.AimTouchSGIgBot

        elseif isADS then
            if isSniper and _G.FufuModConfig.AimTouchScopeSniper then
                cond = _G.FufuModState.CustomTextData.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode = _G.FufuModState.CustomTextData.AimTouchSniperPrio or 1
                boneIdx = _G.FufuModState.CustomTextData.AimTouchSniperBone or 1
                speedVal = _G.FufuModState.CustomTextData.AimTouchSniperSpeed or 30
                fovVal = _G.FufuModState.CustomTextData.AimTouchSniperFOV or 20
                maxDistMeters = _G.FufuModState.CustomTextData.AimTouchSniperDist or 400
                useVisCheck = _G.FufuModConfig.AimTouchSniperVisCheck
                igKnock = _G.FufuModConfig.AimTouchSniperIgKnock
                igBot = _G.FufuModConfig.AimTouchSniperIgBot
                predVal = _G.FufuModState.CustomTextData.AimTouchSniperPred or 0
            elseif _G.FufuModConfig.AimTouchScopeAll then
                cond = _G.FufuModState.CustomTextData.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = _G.FufuModState.CustomTextData.AimTouchScopePrio or 1
                boneIdx = _G.FufuModState.CustomTextData.AimTouchScopeBone or 2
                speedVal = _G.FufuModState.CustomTextData.AimTouchScopeSpeed or 40
                fovVal = _G.FufuModState.CustomTextData.AimTouchScopeFOV or 20
                maxDistMeters = _G.FufuModState.CustomTextData.AimTouchScopeDist or 300
                useVisCheck = _G.FufuModConfig.AimTouchScopeVisCheck
                igKnock = _G.FufuModConfig.AimTouchScopeIgKnock
                igBot = _G.FufuModConfig.AimTouchScopeIgBot
                predVal = _G.FufuModState.CustomTextData.AimTouchScopePred or 0
                recoilCompVal = _G.FufuModState.CustomTextData.AimTouchScopeRecoil or 0
            else
                return
            end
        else
            if not _G.FufuModConfig.AimTouchHipfire then return end
            cond = _G.FufuModState.CustomTextData.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end
            prioMode = _G.FufuModState.CustomTextData.AimTouchHipPrio or 1
            boneIdx = _G.FufuModState.CustomTextData.AimTouchHipBone or 1
            speedVal = _G.FufuModState.CustomTextData.AimTouchHipSpeed or 50
            fovVal = _G.FufuModState.CustomTextData.AimTouchHipFOV or 30
            maxDistMeters = _G.FufuModState.CustomTextData.AimTouchHipDist or 250
            useVisCheck = _G.FufuModConfig.AimTouchHipVisCheck
            igKnock = _G.FufuModConfig.AimTouchHipIgKnock
            igBot = _G.FufuModConfig.AimTouchHipIgBot
        end

        local currentMaxDist = maxDistMeters * 100
        local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
        if not enemies or #enemies == 0 then return end

        local FVector2DClass = import("Vector2D")
        local UGameplayStatics = import("GameplayStatics")
        local KismetMathLibrary = import("KismetMathLibrary")

        local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
        if not slua.isValid(camManager) then return end
        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end

        local ui_util = require("client.common.ui_util")
        if not ui_util then return end
        local viewportSize = ui_util.GetViewportSize()
        if not viewportSize then return end

        local centerX = viewportSize.X * 0.5
        local centerY = viewportSize.Y * 0.5
        local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)

        local bestTarget, bestScore = nil, 99999999
        local selBoneName = "head"
        if boneIdx == 1 then selBoneName = "head"
        elseif boneIdx == 2 then selBoneName = "spine_03"
        elseif boneIdx == 3 then selBoneName = "spine_01"
        elseif boneIdx == 4 then selBoneName = "pelvis" end

        for i, target in ipairs(enemies) do
            if not slua.isValid(target) then goto continue_at end
            pcall(function() if slua.isValid(target.Mesh) then target.Mesh.MeshComponentUpdateFlag = 0 end end)
            if igKnock and target.HealthStatus == 1 then goto continue_at end
            if igBot then
                local tIsBot = false
                if target.bIsAI == true or target.IsAI == true then tIsBot = true end
                local pState = target.PlayerState
                if slua.isValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
                if tIsBot then goto continue_at end
            end
            if useVisCheck then
                local curTime = os.clock()
                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                _G.AimTouchVisCache = _G.AimTouchVisCache or {}
                if not _G.AimTouchVisCache[tId] or (curTime - _G.AimTouchVisCache[tId].time) > 0.2 then
                    local isHidden = true
                    pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                    _G.AimTouchVisCache[tId] = { hidden = isHidden, time = curTime }
                end
                if _G.AimTouchVisCache[tId].hidden then goto continue_at end
            end

            local tPos = target:GetBonePos(selBoneName, {X=0,Y=0,Z=0})
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.GetSocketLocation) == "function" then tPos = target:GetSocketLocation(selBoneName) end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.K2_GetActorLocation) == "function" then
                    tPos = target:K2_GetActorLocation()
                    if tPos then
                        if boneIdx == 1 then tPos.Z = tPos.Z + 70
                        elseif boneIdx == 2 then tPos.Z = tPos.Z + 40
                        elseif boneIdx == 3 then tPos.Z = tPos.Z + 20 end
                    end
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then goto continue_at end

            local screen = FVector2DClass()
            local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
            if not success or screen.X <= 0 or screen.Y <= 0 then goto continue_at end

            local dx, dy = screen.X - centerX, screen.Y - centerY
            local distScreen = math.sqrt(dx*dx + dy*dy)
            if distScreen > FOV_RADIUS then goto continue_at end

            local currentScore = distScreen
            if prioMode == 2 then currentScore = player:GetDistanceTo(target)
            elseif prioMode == 3 then currentScore = target.Health or 100
            elseif prioMode == 4 then
                local hp = target.Health or 100
                local maxhp = target.HealthMax or 100
                if maxhp <= 0 then maxhp = 100 end
                currentScore = hp / maxhp
            end
            if currentScore < bestScore then bestScore = currentScore; bestTarget = target end

            ::continue_at::
        end

        if not slua.isValid(bestTarget) then return end

        local finalBonePos = bestTarget:GetBonePos(selBoneName, {X=0,Y=0,Z=0})
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.GetSocketLocation) == "function" then finalBonePos = bestTarget:GetSocketLocation(selBoneName) end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.K2_GetActorLocation) == "function" then
                finalBonePos = bestTarget:K2_GetActorLocation()
                if finalBonePos then
                    if boneIdx == 1 then finalBonePos.Z = finalBonePos.Z + 70
                    elseif boneIdx == 2 then finalBonePos.Z = finalBonePos.Z + 40
                    elseif boneIdx == 3 then finalBonePos.Z = finalBonePos.Z + 20 end
                end
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then return end

        if predVal > 0 then
            pcall(function()
                local tVelocity = nil
                if type(bestTarget.GetVelocity) == "function" then tVelocity = bestTarget:GetVelocity() end
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local distToEnemy = player:GetDistanceTo(bestTarget) / 100.0
                    local ToF = (distToEnemy / 800.0) * (predVal / 50.0)
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * ToF)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * ToF)
                end
            end)
        end

        -- === MORTAR TRAJECTORY (полная логика из pasta.lua) ===
        if isMortar and _G.FufuModConfig.AimTouchMortar then
            local targetPos = { X=finalBonePos.X, Y=finalBonePos.Y, Z=finalBonePos.Z }
            local launchPos = camLoc
            pcall(function()
                if player.K2_GetActorLocation then
                    local pLoc = player:K2_GetActorLocation()
                    if pLoc then launchPos = { X=pLoc.X, Y=pLoc.Y, Z=pLoc.Z + 50 } end
                end
            end)

            local function CalcMortarTrajectory(V, G, tX, tY, tZ)
                local mDx = math.sqrt((tX - launchPos.X)^2 + (tY - launchPos.Y)^2) - 80
                if mDx < 500 then mDx = 500 end
                local mDy = tZ - launchPos.Z
                local minVSq = G * (mDy + math.sqrt(mDx*mDx + mDy*mDy))
                if (V * V) < minVSq then V = math.sqrt(minVSq) + 100 end
                local v2 = V * V
                local root = v2*v2 - G*(G*mDx*mDx + 2*mDy*v2)
                if root >= 0 then
                    local angleRad = math.atan((v2 + math.sqrt(root)) / (G * mDx))
                    local deg = math.deg(angleRad)
                    if deg >= 35 and deg <= 89.5 then
                        return true, deg, mDx / (V * math.cos(angleRad)), mDx
                    end
                end
                return false, 45, 0, mDx
            end

            local vNear, gNear = 9070, 980 * 2.8
            local vFar, gFar = 12520, 980 * 4.0
            local vUltra, gUltra = 16800, 980 * 4.5

            local okNear, angNear, tofNear, dxN = CalcMortarTrajectory(vNear, gNear, targetPos.X, targetPos.Y, targetPos.Z)
            local okFar, angFar, tofFar, dxF = CalcMortarTrajectory(vFar, gFar, targetPos.X, targetPos.Y, targetPos.Z)
            local okUltra, angUltra, tofUltra, dxU = CalcMortarTrajectory(vUltra, gUltra, targetPos.X, targetPos.Y, targetPos.Z)

            local physAngle, validMortar = 45, false
            if okNear and dxN <= 25000 then validMortar, physAngle = true, angNear
            elseif okFar and dxF <= 40000 then validMortar, physAngle = true, angFar
            elseif okUltra then validMortar, physAngle = true, angUltra
            elseif okNear then validMortar, physAngle = true, angNear end

            local currentRotMortar = pc:GetControlRotation()
            local rotYaw = currentRotMortar.Yaw
            pcall(function()
                local lookRot = KismetMathLibrary.FindLookAtRotation(camLoc, { X=targetPos.X, Y=targetPos.Y, Z=targetPos.Z })
                if lookRot then rotYaw = lookRot.Yaw end
            end)

            local targetCameraPitch = ((physAngle - 45) / 43.0) * 90.0 - 60.0
            local smoothFactorMortar = (speedVal >= 100) and 1.0 or math.max(0.01, (speedVal / 100.0) * 0.3)
            local finalPitchMortar = currentRotMortar.Pitch + (targetCameraPitch - currentRotMortar.Pitch) * smoothFactorMortar
            local deltaYawMortar = rotYaw - currentRotMortar.Yaw
            if deltaYawMortar > 180 then deltaYawMortar = deltaYawMortar - 360 end
            if deltaYawMortar < -180 then deltaYawMortar = deltaYawMortar + 360 end
            local finalYawMortar = currentRotMortar.Yaw + deltaYawMortar * smoothFactorMortar

            pc:SetControlRotation({ Pitch = finalPitchMortar, Yaw = finalYawMortar, Roll = 0 }, "AimTouchMortar")
            return
        end

        local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
        if not rot then return end
        local currentRot = pc:GetControlRotation()
        if not currentRot then return end

        local deltaYaw = rot.Yaw - currentRot.Yaw
        local deltaPitch = rot.Pitch - currentRot.Pitch

        if isADS then
            local camRot = nil
            if type(camManager.GetCameraRotation) == "function" then camRot = camManager:GetCameraRotation() end
            if camRot then
                deltaYaw = deltaYaw - (camRot.Yaw - currentRot.Yaw)
                deltaPitch = deltaPitch - (camRot.Pitch - currentRot.Pitch)
            end
        end

        if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
        if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
        if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
        if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end

        local smoothFactor = (speedVal >= 100) and 1.0 or math.max(0.01, (speedVal / 100.0) * 0.3)
        local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
        local finalYaw = currentRot.Yaw + (deltaYaw * smoothFactor)

        if recoilCompVal > 0 and isFiring then
            finalPitch = finalPitch - ((recoilCompVal / 50.0) * 1.5)
        end

        pc:SetControlRotation({ Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }, "AimTouch")

        if isShotgun and _G.FufuModConfig.AimTouchSGAutoFire then
            pcall(function()
                local distToTarget = player:GetDistanceTo(bestTarget) / 100
                if distToTarget <= maxDistMeters then
                    player.bIsWeaponFiring = true
                    if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(true) end
                    if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(true) end
                    local wepMgr = player.WeaponManagerComponent
                    if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = true end
                    local currentWep = player:GetCurrentWeapon()
                    if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then currentWep:StartFire() end
                    _G.FufuModState.IsAutoFiring = true
                end
            end)
        end
    end)
end

-- ==============================================================================
-- FOV CIRCLE OVERLAY (полный блок из pasta.lua)
-- ==============================================================================
local SlateBlueprintLibrary = import("SlateBlueprintLibrary")

_G.FovCircleOverlay = {
    Container = nil, WidgetSlot = nil, ParentCanvas = nil, Lines = {},
    NumSegments = 45, Thickness = 1.5,
    LastRadius = -1, LastColor = -1, LastCX = -1, LastCY = -1, PrecalcMath = nil
}

function _G.FovCircleOverlay.Create()
    if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then return true end
    local ParentCanvas = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local MainUI = InGameUITools.GetMainControlBaseUI()
        if slua.isValid(MainUI) then
            if slua.isValid(MainUI.CanvasPanel_0) then ParentCanvas = MainUI.CanvasPanel_0
            elseif slua.isValid(MainUI.CanvasPanel_42) then ParentCanvas = MainUI.CanvasPanel_42 end
        end
    end)
    if not ParentCanvas or not slua.isValid(ParentCanvas) then return false end

    local Container = nil
    pcall(function() Container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", ParentCanvas) end)
    if not Container or not slua.isValid(Container) then return false end

    local FVector2DClass = import("Vector2D") or _G.FVector2D
    for i = 1, _G.FovCircleOverlay.NumSegments do
        local border = nil
        pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", Container) end)
        if border and slua.isValid(border) then
            pcall(function()
                border.RenderTransformPivot = FVector2DClass(0, 0.5)
                border:SetRenderTransformPivot(FVector2DClass(0, 0.5))
                border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local slot = Container:AddChildToCanvas(border)
            if slot then pcall(function() slot:SetAlignment(FVector2DClass(0, 0.5)) end) end
            _G.FovCircleOverlay.Lines[i] = { widget = border, slot = slot }
        end
    end

    local MainSlot = nil
    pcall(function() MainSlot = ParentCanvas:AddChildToCanvas(Container) end)
    if MainSlot then
        pcall(function()
            MainSlot:SetAutoSize(false); MainSlot:SetSize(FVector2DClass(0, 0))
            MainSlot:SetZOrder(995); MainSlot:SetAlignment(FVector2DClass(0, 0))
            MainSlot:SetPosition(FVector2DClass(0, 0))
        end)
    end

    _G.FovCircleOverlay.Container = Container
    _G.FovCircleOverlay.WidgetSlot = MainSlot
    _G.FovCircleOverlay.ParentCanvas = ParentCanvas
    return true
end

function _G.FovCircleOverlay.Update(pc, player)
    if not _G.FufuModConfig.EspFovCircle then
        if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then
            pcall(function() _G.FovCircleOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            _G.FovCircleOverlay.LastRadius = -1
        end
        return
    end

    local fovVal, colIdx = 30, 7
    local cData = _G.FufuModState.CustomTextData
    local WEAPON_TYPE = _G.__AimTouch_WeaponType or "NORMAL"
    local isADS = player.bIsGunADS or false

    if WEAPON_TYPE == "MORTAR" then
        fovVal = cData.AimTouchMortarFOV or 360
        colIdx = tonumber(cData.AimTouchMortarFOVColor) or 5
    elseif WEAPON_TYPE == "SHOTGUN" then
        fovVal = cData.AimTouchSGFOV or 40
        colIdx = tonumber(cData.AimTouchSGFOVColor) or 1
    elseif isADS then
        if WEAPON_TYPE == "SNIPER" then
            fovVal = cData.AimTouchSniperFOV or 20
            colIdx = tonumber(cData.AimTouchSniperFOVColor) or 4
        else
            fovVal = cData.AimTouchScopeFOV or 30
            colIdx = tonumber(cData.AimTouchScopeFOVColor) or 6
        end
    else
        fovVal = cData.AimTouchHipFOV or 30
        colIdx = tonumber(cData.AimTouchHipFOVColor) or 7
    end

    local rawCX = _G.__AimTouch_CenterX or 960
    local rawCY = _G.__AimTouch_CenterY or 540
    local vpX = _G.__AimTouch_ViewportX or 1920

    if not _G.FovCircleOverlay.Create() then return end
    local ParentCanvas = _G.FovCircleOverlay.ParentCanvas
    if not ParentCanvas or not slua.isValid(ParentCanvas) then return end

    local scaleX, scaleY, offsetX, offsetY = 1.0, 1.0, 0.0, 0.0
    pcall(function()
        local cg = ParentCanvas:GetCachedGeometry()
        if cg and SlateBlueprintLibrary then
            local FVector2DClass = import("Vector2D") or _G.FVector2D
            local pt0 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2DClass(0, 0))
            local pt1 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2DClass(100, 100))
            if pt0 and pt1 then
                scaleX = (pt1.X - pt0.X) / 100; scaleY = (pt1.Y - pt0.Y) / 100
                offsetX = pt0.X; offsetY = pt0.Y
            end
        end
    end)

    local centerX = rawCX * scaleX + offsetX
    local centerY = rawCY * scaleY + offsetY
    local avgScale = (scaleX + scaleY) / 2
    local rawRadius = (fovVal / 100.0) * (vpX / 2.0)
    local targetRadius = rawRadius * avgScale

    if math.abs(_G.FovCircleOverlay.LastRadius - targetRadius) < 0.5
       and _G.FovCircleOverlay.LastColor == colIdx
       and math.abs(_G.FovCircleOverlay.LastCX - centerX) < 0.5
       and math.abs(_G.FovCircleOverlay.LastCY - centerY) < 0.5 then return end

    _G.FovCircleOverlay.LastRadius = targetRadius
    _G.FovCircleOverlay.LastColor = colIdx
    _G.FovCircleOverlay.LastCX = centerX
    _G.FovCircleOverlay.LastCY = centerY

    pcall(function() _G.FovCircleOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)

    local LinearColorClass = import("LinearColor") or _G.FLinearColor
    local r, g, b = GetFOVColor(colIdx)
    local dim = 0.55
    local color = LinearColorClass and LinearColorClass(r*dim, g*dim, b*dim, 1.0)
        or {R=r*dim*255, G=g*dim*255, B=b*dim*255, A=255}

    local numSegments = _G.FovCircleOverlay.NumSegments
    if not _G.FovCircleOverlay.PrecalcMath then
        _G.FovCircleOverlay.PrecalcMath = {}
        local angleStep = 360.0 / numSegments
        for i = 1, numSegments do
            local a1 = math.rad((i-1) * angleStep)
            local a2 = math.rad(i * angleStep)
            local c1, s1 = math.cos(a1), math.sin(a1)
            local c2, s2 = math.cos(a2), math.sin(a2)
            local dxu, dyu = c2 - c1, s2 - s1
            local atan2 = math.atan2 or math.atan
            _G.FovCircleOverlay.PrecalcMath[i] = {
                c1 = c1, s1 = s1,
                dist_unit = math.sqrt(dxu*dxu + dyu*dyu),
                angleDeg = math.deg(atan2(dyu, dxu)),
            }
        end
    end

    pcall(function()
        local FVector2DClass = import("Vector2D") or _G.FVector2D
        for i = 1, numSegments do
            local mData = _G.FovCircleOverlay.PrecalcMath[i]
            local x1 = targetRadius * mData.c1
            local y1 = targetRadius * mData.s1
            local dist = targetRadius * mData.dist_unit
            local line = _G.FovCircleOverlay.Lines[i]
            if line and line.slot and slua.isValid(line.slot) then
                line.slot:SetPosition(FVector2DClass(centerX + x1, centerY + y1))
                line.slot:SetSize(FVector2DClass(dist + 0.8, _G.FovCircleOverlay.Thickness))
                line.widget:SetRenderAngle(mData.angleDeg)
                line.widget:SetBrushColor(color)
            end
        end
    end)
end

function _G.CleanUpFovCircleOverlay()
    if _G.FovCircleOverlay and _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then
        pcall(function() _G.FovCircleOverlay.Container:RemoveFromParent() end)
        pcall(function() _G.FovCircleOverlay.Container:ConditionalBeginDestroy() end)
    end
    _G.FovCircleOverlay.Container = nil
    _G.FovCircleOverlay.WidgetSlot = nil
    _G.FovCircleOverlay.ParentCanvas = nil
    _G.FovCircleOverlay.LastRadius = -1
end

-- ==============================================================================
-- ENGINE CHAMS (ApplyColorBodyNew / UndoColorBodyNew)
-- ==============================================================================
local function ApplyColorBodyNew(enemy, markData)
    pcall(function()
        if not _G.FufuModState.ConsoleNewWallReady then
            local KSL = import("KismetSystemLibrary")
            local world = slua.getWorld()
            if KSL and world then
                KSL.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
                KSL.ExecuteConsoleCommand(world, "r.CustomDepth 3")
                KSL.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
                KSL.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
                _G.FufuModState.ConsoleNewWallReady = true
            end
        end

        local meshes = GetAllSkeletalMeshes(enemy, markData)
        local weapon = nil
        pcall(function() weapon = enemy:GetCurrentWeapon() end)
        if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then table.insert(meshes, weapon.Mesh) end

        local isBot = markData.AK_IS_BOT or false
        local stateHash = (isBot and "BOT" or "PLAYER").."_"..#meshes
        if markData.LastColorNewHash == stateHash and markData.ColorNewApplied then return end
        markData.LastColorNewHash = stateHash
        markData.ColorNewApplied = true

        local LinearColorClass = import("LinearColor") or _G.FLinearColor
        local visRGB = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness or 25)
        local occRGB = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness or 25)
        local glow = _G.ColorConfig.Glow or 3.0
        local visColor = LinearColorClass and LinearColorClass(
            (visRGB.R/255)*glow, (visRGB.G/255)*glow, (visRGB.B/255)*glow, 1.0) or visRGB
        local occColor = LinearColorClass and LinearColorClass(
            occRGB.R/255, occRGB.G/255, occRGB.B/255, 1.0) or occRGB

        for _, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    if type(mesh.SetDrawDyeing) == "function" then
                        mesh:SetDrawDyeing(true)
                        mesh:SetDrawDyeingMode(1)
                        mesh:SetVisibleDyeingColor(visColor)
                        mesh:SetOccludedDyeingColor(occColor)
                        mesh:SetDyeingColorFadeDistance(99999.0)
                        mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
                        mesh:SetDrawHighlight(true)
                        mesh:OverrideHighlightColor(visColor)
                        mesh:SetHighlightCanBeOccluded(false)
                        mesh:SetDrawIdeaOutline(true)
                        mesh:SetIdeaOutlineNew(true)
                        mesh:SetIdeaOutlineOcclusionHighlight(true)
                        mesh:OverrideIdeaOutlineColor(visColor)
                        mesh:SetIdeaOutlineOcclusionColor(occColor)
                        mesh:OverrideIdeaOutlineThickness(20)
                        mesh:SetIdeaOverrideOutlineAndOcclusion(true)
                        mesh:SetRenderCustomDepth(true)
                        mesh:SetCustomDepthStencilValue(255)
                    end
                end)
            end
        end
    end)
end

local function UndoColorBodyNew(enemy, markData)
    pcall(function()
        if markData.ColorNewApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            local weapon = nil
            pcall(function() weapon = enemy:GetCurrentWeapon() end)
            if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then table.insert(meshes, weapon.Mesh) end
            for _, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function()
                        if type(mesh.SetDrawDyeing) == "function" then
                            mesh:SetDrawDyeing(false)
                            mesh:SetDrawHighlight(false)
                            mesh:SetDrawIdeaOutline(false)
                            mesh:SetRenderCustomDepth(false)
                        end
                    end)
                end
            end
            markData.ColorNewApplied = false
            markData.LastColorNewHash = ""
        end
    end)
end

-- ==============================================================================
-- ESP LOOP (FULL)
-- ==============================================================================
local function RunESPLoop(localPlayer, pc)
    pcall(function()
        local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if not okData or not GameplayData then return end

        local Cached_PPM = nil
        pcall(function() Cached_PPM = import("PostProcessManager").GetInstance() end)
        local Cached_SecurityCommonUtils = nil
        pcall(function() Cached_SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils") end)
        local Cached_MyHUD = pc and pc.MyHUD or nil

        local allCharacters = {}
        if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters()
        elseif GameplayData.GameCharacters then
            for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
        end

        local currentValidKeys = {}
        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer then currentValidKeys[GetSafeEnemyKey(enemy)] = true end
        end

        for key, data in pairs(_G.FufuModState.EnemyMarks) do
            if not currentValidKeys[key] then
                SafeRemoveMark(data.radarMark); SafeRemoveMark(data.hpMark)
                SafeRemoveMark(data.hpMark8); SafeRemoveMark(data.distMark)
                if _G.AimTouchVisCache and _G.AimTouchVisCache[key] then _G.AimTouchVisCache[key] = nil end
                data.enemy = nil; data.CachedMeshes = nil
                _G.FufuModState.EnemyMarks[key] = nil
            end
        end

        local mHead_Global, mBody_Global, mLegs_Global = 1.0, 1.0, 1.0
        local runInject_Global = false
        if _G.FufuModConfig.CustomMagicBullet then
            runInject_Global = true
            mHead_Global = 1.0; mBody_Global = 1.0; mLegs_Global = 1.0
            local cData = _G.FufuModState.CustomTextData
            if cData.MagicHead then mHead_Global = tonumber(cData.MagicHead) or 1.0 end
            if cData.MagicBody then mBody_Global = tonumber(cData.MagicBody) or 1.0 end
            if cData.MagicLegs then mLegs_Global = tonumber(cData.MagicLegs) or 1.0 end
        end

        local BoneScaleMap = {
            ["head"]=mHead_Global, ["neck_01"]=mHead_Global,
            ["pelvis"]=mBody_Global, ["spine_01"]=mBody_Global, ["spine_02"]=mBody_Global, ["spine_03"]=mBody_Global,
            ["thigh_l"]=mLegs_Global, ["thigh_r"]=mLegs_Global,
            ["calf_l"]=mLegs_Global, ["calf_r"]=mLegs_Global,
            ["foot_l"]=mLegs_Global, ["foot_r"]=mLegs_Global,
        }

        local mLoc = nil
        pcall(function() if type(localPlayer.K2_GetActorLocation) == "function" then mLoc = localPlayer:K2_GetActorLocation() end end)

        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                local bIsReallyDead = false
                pcall(function()
                    if type(enemy.IsDead) == "function" then bIsReallyDead = enemy:IsDead()
                    elseif enemy.bIsDead ~= nil then bIsReallyDead = enemy.bIsDead
                    elseif enemy.bIsDeadFlag ~= nil then bIsReallyDead = enemy.bIsDeadFlag end
                    if enemy.HealthStatus ~= nil and enemy.HealthStatus == 2 then bIsReallyDead = true end
                end)

                local eKey = GetSafeEnemyKey(enemy)
                _G.FufuModState.EnemyMarks[eKey] = _G.FufuModState.EnemyMarks[eKey] or { enemy = enemy }
                local markData = _G.FufuModState.EnemyMarks[eKey]
                markData.enemy = enemy

                if not bIsReallyDead then
                    if markData.lastEnemyActor ~= enemy then
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                        if markData.radarMark then SafeRemoveMark(markData.radarMark); markData.radarMark = nil end
                        markData.lastEnemyActor = enemy
                        markData.LastUIComp = nil
                        markData.LastFrameUIState = nil
                    end

                    local eMesh = nil
                    pcall(function() eMesh = enemy.Mesh or (type(enemy.getAvatarComponent2) == "function" and enemy:getAvatarComponent2() or nil) end)
                    local aLoc = nil
                    pcall(function() if type(enemy.K2_GetActorLocation) == "function" then aLoc = enemy:K2_GetActorLocation() end end)

                    CheckIsAI(enemy, markData)

                    local currentMeshCount = 0
                    if Valid(eMesh) then currentMeshCount = #GetAllSkeletalMeshes(enemy, markData) end
                    local isMeshChanged = (markData.LastMeshCountWall ~= currentMeshCount)

                    -- Engine Chams (ColorBodyNew)
                    if _G.FufuModConfig.ColorBodyNew then
                        if isMeshChanged or not markData.WallhackApplied then
                            ApplyColorBodyNew(enemy, markData)
                            markData.WallhackApplied = true
                            markData.LastMeshCountWall = currentMeshCount
                        end
                    else
                        UndoColorBodyNew(enemy, markData)
                        markData.WallhackApplied = false
                    end

                    -- Hitbox scaling (MagicBullet)
                    pcall(function()
                        local EnemyMesh = eMesh
                        if slua.isValid(EnemyMesh) then
                            local uniqueID = type(enemy.GetUniqueID) == "function" and enemy:GetUniqueID() or tostring(enemy.PlayerKey or enemy)
                            if markData.MagicBulletHash == _G.FufuModState.LastMagicConfigHash and markData.MagicTargetID == uniqueID then return end
                            local PhysicsAsset = EnemyMesh.PhysicsAssetOverride
                            if not slua.isValid(PhysicsAsset) and EnemyMesh.SkeletalMesh then PhysicsAsset = EnemyMesh.SkeletalMesh.PhysicsAsset end
                            if slua.isValid(PhysicsAsset) and PhysicsAsset.SkeletalBodySetups then
                                if not _G.AK_ModdedPhysAssets then _G.AK_ModdedPhysAssets = {} end
                                local PhysAssetName = "DefaultPhys"
                                pcall(function() PhysAssetName = PhysicsAsset:GetName() end)
                                if _G.AK_ModdedPhysAssets[PhysAssetName] ~= _G.FufuModState.LastMagicConfigHash then
                                    if not _G.AK_OrigHitboxes then _G.AK_OrigHitboxes = {} end
                                    if not _G.AK_OrigHitboxes[PhysAssetName] then _G.AK_OrigHitboxes[PhysAssetName] = {} end
                                    local OrigHitboxData = _G.AK_OrigHitboxes[PhysAssetName]
                                    local SkeletalBodySetups = PhysicsAsset.SkeletalBodySetups
                                    local numSetups = type(SkeletalBodySetups.Num) == "function" and SkeletalBodySetups:Num() or #SkeletalBodySetups
                                    local limit = numSetups > 50 and 50 or numSetups
                                    for i = 1, limit do
                                        local BodySetup = type(SkeletalBodySetups.Get) == "function" and SkeletalBodySetups:Get(i-1) or SkeletalBodySetups[i]
                                        if slua.isValid(BodySetup) then
                                            local LowerBoneName = string.lower(tostring(BodySetup.BoneName))
                                            local MatchedBoneKey = nil
                                            for k, _ in pairs(BoneScaleMap) do
                                                if string.find(LowerBoneName, k, 1, true) then MatchedBoneKey = k break end
                                            end
                                            if MatchedBoneKey then
                                                local TargetScale = 1.0
                                                if runInject_Global then TargetScale = BoneScaleMap[MatchedBoneKey] end
                                                local AggGeom = BodySetup.AggGeom
                                                local BoxElems = AggGeom and AggGeom.BoxElems or BodySetup.BoxElems
                                                local SphereElems = AggGeom and AggGeom.SphereElems or BodySetup.SphereElems
                                                local SphylElems = AggGeom and AggGeom.SphylElems or BodySetup.SphylElems
                                                local BoxElem = GetFirstElemSafe(BoxElems)
                                                local SphereElem = GetFirstElemSafe(SphereElems)
                                                local SphylElem = GetFirstElemSafe(SphylElems)
                                                if not OrigHitboxData[MatchedBoneKey] then
                                                    OrigHitboxData[MatchedBoneKey] = { Box=nil, Sphere=nil, Sphyl=nil }
                                                    if BoxElem then OrigHitboxData[MatchedBoneKey].Box = { X=BoxElem.X, Y=BoxElem.Y, Z=BoxElem.Z } end
                                                    if SphereElem then OrigHitboxData[MatchedBoneKey].Sphere = { Radius=SphereElem.Radius } end
                                                    if SphylElem then OrigHitboxData[MatchedBoneKey].Sphyl = { Radius=SphylElem.Radius, Length=SphylElem.Length } end
                                                end
                                                local OrigElemData = OrigHitboxData[MatchedBoneKey]
                                                if OrigElemData.Box and BoxElem then
                                                    BoxElem.X = OrigElemData.Box.X * TargetScale
                                                    BoxElem.Y = OrigElemData.Box.Y * TargetScale
                                                    BoxElem.Z = OrigElemData.Box.Z * TargetScale
                                                    if type(BoxElems.Set) == "function" then BoxElems:Set(0, BoxElem) else BoxElems[1] = BoxElem end
                                                    if AggGeom then AggGeom.BoxElems = BoxElems; BodySetup.AggGeom = AggGeom else BodySetup.BoxElems = BoxElems end
                                                end
                                                if OrigElemData.Sphere and SphereElem then
                                                    SphereElem.Radius = OrigElemData.Sphere.Radius * TargetScale
                                                    if type(SphereElems.Set) == "function" then SphereElems:Set(0, SphereElem) else SphereElems[1] = SphereElem end
                                                    if AggGeom then AggGeom.SphereElems = SphereElems; BodySetup.AggGeom = AggGeom else BodySetup.SphereElems = SphereElems end
                                                end
                                                if OrigElemData.Sphyl and SphylElem then
                                                    SphylElem.Radius = OrigElemData.Sphyl.Radius * TargetScale
                                                    SphylElem.Length = OrigElemData.Sphyl.Length * TargetScale
                                                    if type(SphylElems.Set) == "function" then SphylElems:Set(0, SphylElem) else SphylElems[1] = SphylElem end
                                                    if AggGeom then AggGeom.SphylElems = SphylElems; BodySetup.AggGeom = AggGeom else BodySetup.SphylElems = SphylElems end
                                                end
                                            end
                                        end
                                    end
                                    _G.AK_ModdedPhysAssets[PhysAssetName] = _G.FufuModState.LastMagicConfigHash
                                end
                                if EnemyMesh.SetPhysicsAsset then EnemyMesh:SetPhysicsAsset(PhysicsAsset) end
                                EnemyMesh.PhysicsAssetOverride = PhysicsAsset
                                markData.MagicBulletHash = _G.FufuModState.LastMagicConfigHash
                                markData.MagicTargetID = uniqueID
                            end
                        end
                    end)

                    local distM = 0
                    pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)

                    local currentHp, maxHp = 100, 100
                    local showFrameUI = _G.FufuModConfig.Esp5 or _G.FufuModConfig.EspVipPro or _G.FufuModConfig.EspVip
                    if showFrameUI then
                        pcall(function()
                            if enemy.Health then currentHp = enemy.Health elseif type(enemy.GetHealth) == "function" then currentHp = enemy:GetHealth() end
                            if enemy.HealthMax then maxHp = enemy.HealthMax elseif type(enemy.GetHealthMax) == "function" then maxHp = enemy:GetHealthMax() end
                        end)
                        if maxHp <= 0 then maxHp = 100 end
                    end
                    local hpRatio = currentHp / maxHp

                    if _G.FufuModConfig.EspAntenna then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) and distM <= 400 then
                                local loopCount, zStep, baseZ = 8, 1000, 105
                                local topZ = baseZ + (loopCount * zStep)
                                for i = 1, loopCount do
                                    local zOffset = baseZ + (i * zStep)
                                    MyHUD:AddDebugText("|", enemy, 0.06, {X=0,Y=0,Z=zOffset}, {X=0,Y=0,Z=zOffset}, C_GREEN, true, false, true, nil, 1.2, true)
                                end
                                MyHUD:AddDebugText("I", enemy, 0.06, {X=0,Y=0,Z=topZ+60}, {X=0,Y=0,Z=topZ+60}, C_GREEN, true, false, true, nil, 1.5, true)
                            end
                        end)
                    end

                    if _G.FufuModConfig.Esp6 then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if not (Valid(MyHUD) and MyHUD.AddDebugText) then return end
                            if not Valid(enemy) or not Valid(eMesh) then return end
                            if distM > 250 then return end
                            local headPos = eMesh:GetSocketLocation("head")
                            if not headPos then return end
                            local bIsVisible = true
                            if pc and type(pc.LineOfSightTo) == "function" then bIsVisible = pc:LineOfSightTo(enemy) end
                            local visibleCol = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness or 25)
                            local invisibleCol = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness or 25)
                            local headColor = bIsVisible and visibleCol or invisibleCol
                            MyHUD:AddDebugText("●", enemy, 0.2, {X=0,Y=0,Z=90}, {X=0,Y=0,Z=90}, headColor, true, false, true, nil, 0.9, true)
                        end)
                    end

                    if showFrameUI then
                        pcall(function()
                            local SecurityCommonUtils = Cached_SecurityCommonUtils
                            local show = true
                            if enemy.HealthStatus and SecurityCommonUtils and SecurityCommonUtils.IsHealthStatusAlive then
                                if not SecurityCommonUtils.IsHealthStatusAlive(enemy.HealthStatus) then show = false end
                            end
                            if show and mLoc then
                                if aLoc and SecurityCommonUtils and SecurityCommonUtils.IsVector then
                                    if SecurityCommonUtils.IsVector(aLoc) and SecurityCommonUtils.IsVector(mLoc) then
                                        if aLoc.Z >= 150000 or FVector.Dist2D(mLoc, aLoc) > 50000 then show = false end
                                    end
                                end
                            end
                            if show then
                                if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then enemy:Replay_CreateEnemyFrameUI(true, true) end
                                if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                                if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio) end
                                local uiComp = enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI) == "function" and enemy:GetEnemyFrameUI())
                                if Valid(uiComp) and markData.LastFrameUIState ~= "VISIBLE" then
                                    if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(0) end
                                    if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(false) end
                                    markData.LastFrameUIState = "VISIBLE"
                                end
                            end
                        end)
                    else
                        pcall(function()
                            if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end
                            local uiComp = enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI) == "function" and enemy:GetEnemyFrameUI())
                            if Valid(uiComp) and markData.LastFrameUIState ~= "HIDDEN" then
                                if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(2) end
                                if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(true) end
                                markData.LastFrameUIState = "HIDDEN"
                            end
                        end)
                    end

                    if _G.FufuModConfig.EspVipPro then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if not (Valid(hud) and hud.AddDebugText) then return end
                            if distM > 400 then return end
                            local hp = enemy.Health or 100
                            local maxHp2 = enemy.HealthMax or 100
                            local isKnock = (hp <= 0 or enemy.HealthStatus == 1)
                            local hpPercent = isKnock and 0 or (hp / maxHp2)
                            local pctValue = math.floor(hpPercent * 100 + 0.5)
                            local pName = ""
                            if _G.FufuModConfig.EspName then pName = enemy.PlayerName or enemy.PlayerNamePublic or "Enemy" end
                            local bIsVisible = false
                            if pc and type(pc.LineOfSightTo) == "function" then bIsVisible = pc:LineOfSightTo(enemy) end
                            local visibleCol = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness)
                            local invisibleCol = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness)
                            local textColor = {R=255,G=255,B=255,A=255}
                            if isKnock then textColor = {R=0,G=0,B=255,A=255}
                            else textColor = bIsVisible and visibleCol or invisibleCol end
                            local label = ""
                            if isKnock then label = (pName ~= "" and string.format("%s [♿]", pName) or "♿")
                            else
                                if pName ~= "" then label = string.format("%s ▶ %.0f%%", pName, pctValue)
                                else label = string.format("▶ %.0f%%", pctValue) end
                            end
                            hud:AddDebugText(label, enemy, 0.2, {X=0,Y=0,Z=120}, {X=0,Y=0,Z=120}, textColor, true, false, true, nil, 1.0, true)
                        end)
                    end

                    if _G.FufuModConfig.EspDistance then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if not (Valid(hud) and hud.AddDebugText) then return end
                            if distM > 400 then return end
                            hud:AddDebugText(string.format("%.0fm", math.floor(distM+0.5)), enemy, 0.3, {X=15,Y=15,Z=-15}, {X=15,Y=15,Z=-15}, {R=255,G=255,B=255,A=255}, true, false, true, nil, 0.9, true)
                        end)
                    end

                    if _G.FufuModConfig.EspName and not _G.FufuModConfig.EspVipPro then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if not (Valid(hud) and hud.AddDebugText) then return end
                            if distM > 400 then return end
                            local pName = enemy.PlayerName or enemy.PlayerNamePublic or "Enemy"
                            if pName == "" then return end
                            local isKnock = (enemy.Health or 100) <= 0 or enemy.HealthStatus == 1
                            local bIsVisible = true
                            pcall(function() if pc and type(pc.LineOfSightTo) == "function" then bIsVisible = pc:LineOfSightTo(enemy) end end)
                            local visibleCol = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness)
                            local invisibleCol = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness)
                            local nameColor = {R=255,G=255,B=255,A=255}
                            if isKnock then nameColor = {R=0,G=0,B=255,A=255}
                            else nameColor = bIsVisible and visibleCol or invisibleCol end
                            hud:AddDebugText(pName, enemy, 0.2, {X=0,Y=0,Z=120}, {X=0,Y=0,Z=120}, nameColor, true, false, true, nil, 1.0, true)
                        end)
                    end

                    if _G.FufuModConfig.EspVip then
                        if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                        if markData.distMark == nil then markData.distMark = SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                    end

                    if _G.FufuModConfig.Esp8 then
                        if markData.hpMark8 == nil then markData.hpMark8 = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                    end

                    if _G.FufuModConfig.EspRadar then
                        if not markData.radarMark or markData.radarMark == 0 then
                            markData.radarMark = SafeAddMark(8888, FVector(0,0,0), 0, "", 4, enemy)
                        end
                    else
                        if markData.radarMark and markData.radarMark ~= 0 then
                            SafeRemoveMark(markData.radarMark); markData.radarMark = nil
                        end
                    end
                else
                    if not markData.IsCleanedUp then
                        SafeRemoveMark(markData.radarMark); markData.radarMark = nil
                        SafeRemoveMark(markData.hpMark); markData.hpMark = nil
                        SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil
                        SafeRemoveMark(markData.distMark); markData.distMark = nil
                        pcall(function()
                            local eObj = markData.enemy
                            if Valid(eObj) then
                                if eObj.Replay_SetVisiableOfFrameUI then eObj:Replay_SetVisiableOfFrameUI(false) end
                                local uiComp = eObj.EnemyFrameUI or (type(eObj.GetEnemyFrameUI) == "function" and eObj:GetEnemyFrameUI())
                                if Valid(uiComp) then
                                    if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(2) end
                                    if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(true) end
                                end
                            end
                        end)
                        markData.IsCleanedUp = true
                    end
                end
            end
        end

        -- THROWABLE
        if _G.FufuModConfig.ThrowableEnabled then
            pcall(function()
                local MyHUD = Cached_MyHUD
                if not Valid(MyHUD) then return end
                if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                if not _G.CachedActorClass_ForBomb then _G.CachedActorClass_ForBomb = import("Actor") end
                if not _G.CachedProjArray then _G.CachedProjArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForBomb) end
                local ui_util = require("client.common.ui_util")
                local gameInstance = ui_util and ui_util.GetGameInstance()
                if not (gameInstance and _G.CachedGameplayStatics) then return end
                local curTime = os.clock()
                local scanInterval = 0.5
                local mode = _G.FufuModConfig.ThrowableScanMode or 0
                if mode == 10 then scanInterval = 10.0 elseif mode == 20 then scanInterval = 20.0 end
                if not _G.LastThrowableScanTime or (curTime - _G.LastThrowableScanTime) >= scanInterval then
                    _G.LastThrowableScanTime = curTime
                    local allActors = _G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance, _G.CachedActorClass_ForBomb, _G.CachedProjArray)
                    local activeThrowables, itemThrowables = {}, {}
                    if allActors then
                        for _, actor in pairs(allActors) do
                            if slua.isValid(actor) and not actor.bHidden and not actor.bTearOff then
                                local isPendingKill = false
                                pcall(function() if type(actor.IsPendingKill) == "function" then isPendingKill = actor:IsPendingKill() end end)
                                if not isPendingKill then
                                    local nameLower = string.lower(tostring(actor))
                                    local bType = 0
                                    if string.find(nameLower, "smoke") then bType = 2
                                    elseif string.find(nameLower, "burn") or string.find(nameLower, "molotov") then bType = 3
                                    elseif string.find(nameLower, "grenade") then bType = 1 end
                                    if bType > 0 then
                                        if string.find(nameLower, "projectile") or string.find(nameLower, "thrown") then
                                            table.insert(activeThrowables, {act=actor, type=bType})
                                        else
                                            table.insert(itemThrowables, {act=actor, type=bType})
                                        end
                                    end
                                end
                            end
                        end
                    end
                    _G.CachedActiveThrowables = activeThrowables
                    _G.CachedItemThrowables = itemThrowables
                end
                local function DrawThrowables(list, isItem, maxDist)
                    if not list then return end
                    for _, item in ipairs(list) do
                        local throwable = item.act
                        local bType = item.type
                        if slua.isValid(throwable) and not throwable.bHidden then
                            local distM = 0
                            pcall(function() distM = localPlayer:GetDistanceTo(throwable) / 100 end)
                            if distM > 0 and distM <= maxDist then
                                local displayName, colorIdx = "", 4
                                if bType == 1 then
                                    if not _G.FufuModConfig.ThrowableGrenade then goto cont end
                                    displayName = isItem and "Grenade" or "GRENADE"
                                    colorIdx = _G.FufuModConfig.ThrowableColor_Grenade or 4
                                elseif bType == 2 then
                                    if not _G.FufuModConfig.ThrowableSmoke then goto cont end
                                    displayName = isItem and "Smoke" or "SMOKE"
                                    colorIdx = _G.FufuModConfig.ThrowableColor_Smoke or 4
                                elseif bType == 3 then
                                    if not _G.FufuModConfig.ThrowableMolotov then goto cont end
                                    displayName = isItem and "Molotov" or "MOLOTOV"
                                    colorIdx = _G.FufuModConfig.ThrowableColor_Molotov or 4
                                else goto cont end
                                local color = GetColorBy7(colorIdx)
                                local text = string.format("%s [%dm]", displayName, math.floor(distM))
                                MyHUD:AddDebugText(text, throwable, 0.3, {X=0,Y=0,Z=25}, {X=0,Y=0,Z=25}, color, true, false, true, nil, 1.0, true)
                            end
                            ::cont::
                        end
                    end
                end
                DrawThrowables(_G.CachedItemThrowables, true, 50)
                DrawThrowables(_G.CachedActiveThrowables, false, 150)
            end)
        end

        -- VEHICLE
        if _G.FufuModConfig.VehicleEnabled then
            pcall(function()
                local MyHUD = Cached_MyHUD
                if not Valid(MyHUD) then return end
                if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                if not _G.CachedActorClass_ForVehicle then _G.CachedActorClass_ForVehicle = import("STExtraVehicleBase") end
                if not _G.CachedVehicleArray then _G.CachedVehicleArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForVehicle) end
                local ui_util = require("client.common.ui_util")
                local gameInstance = ui_util and ui_util.GetGameInstance()
                if not (gameInstance and _G.CachedGameplayStatics) then return end
                local curTime = os.clock()
                if not _G.LastVehicleScanTime or (curTime - _G.LastVehicleScanTime) > 1.0 then
                    _G.LastVehicleScanTime = curTime
                    local allVehicles = _G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance, _G.CachedActorClass_ForVehicle, _G.CachedVehicleArray)
                    local activeVehicles = {}
                    if allVehicles then
                        for _, veh in pairs(allVehicles) do
                            if slua.isValid(veh) and not veh.bHidden and not veh.bTearOff then
                                local isPendingKill = false
                                pcall(function() if type(veh.IsPendingKill) == "function" then isPendingKill = veh:IsPendingKill() end end)
                                if not isPendingKill then
                                    local vehName = "Kendaraan"
                                    pcall(function()
                                        if type(veh.GetVehicleName) == "function" then vehName = veh:GetVehicleName()
                                        elseif veh.VehicleName then vehName = veh.VehicleName end
                                    end)
                                    local nameLower = string.lower(tostring(vehName)..tostring(veh))
                                    local displayName = "Kendaraan"
                                    if string.find(nameLower, "uaz") then displayName = "UAZ"
                                    elseif string.find(nameLower, "dacia") then displayName = "Dacia"
                                    elseif string.find(nameLower, "buggy") then displayName = "Buggy"
                                    elseif string.find(nameLower, "mirado") then displayName = "Mirado"
                                    elseif string.find(nameLower, "bike") or string.find(nameLower, "motor") then displayName = "Motor"
                                    elseif string.find(nameLower, "scooter") then displayName = "Scooter"
                                    elseif string.find(nameLower, "coupe") then displayName = "Coupe RB"
                                    elseif string.find(nameLower, "brdm") then displayName = "BRDM"
                                    else displayName = "Kendaraan" end
                                    table.insert(activeVehicles, {act=veh, name=displayName})
                                end
                            end
                        end
                    end
                    _G.CachedVehicles = activeVehicles
                end
                if _G.CachedVehicles then
                    for _, item in ipairs(_G.CachedVehicles) do
                        local veh = item.act
                        if slua.isValid(veh) and not veh.bHidden then
                            local isShow = false
                            local colorKey = "VehicleColor_Other"
                            if item.name == "Dacia" then isShow = _G.FufuModConfig.VehicleShowDacia; colorKey = "VehicleColor_Dacia"
                            elseif item.name == "UAZ" then isShow = _G.FufuModConfig.VehicleShowUAZ; colorKey = "VehicleColor_UAZ"
                            elseif item.name == "Buggy" then isShow = _G.FufuModConfig.VehicleShowBuggy; colorKey = "VehicleColor_Buggy"
                            elseif item.name == "Coupe RB" then isShow = _G.FufuModConfig.VehicleShowCoupe; colorKey = "VehicleColor_Coupe"
                            elseif item.name == "Mirado" then isShow = _G.FufuModConfig.VehicleShowMirado; colorKey = "VehicleColor_Mirado"
                            elseif item.name == "Motor" or item.name == "Scooter" then isShow = _G.FufuModConfig.VehicleShowMotor; colorKey = "VehicleColor_Motor"
                            else isShow = _G.FufuModConfig.VehicleShowOther; colorKey = "VehicleColor_Other" end
                            if isShow then
                                local distM = 0
                                pcall(function() distM = localPlayer:GetDistanceTo(veh) / 100 end)
                                if distM > 0 and distM <= 300 then
                                    local text = string.format("%s [%dm]", item.name, math.floor(distM))
                                    local vehColor = GetColorBy7(_G.FufuModConfig[colorKey] or 4)
                                    MyHUD:AddDebugText(text, veh, 0.3, {X=0,Y=0,Z=50}, {X=0,Y=0,Z=50}, vehColor, true, false, true, nil, 1.0, true)
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- LOOT
        if _G.FufuModConfig.EspLoot then
            pcall(function()
                local MyHUD = Cached_MyHUD
                if not Valid(MyHUD) then return end
                if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                if not _G.CachedActorClass_ForLoot then _G.CachedActorClass_ForLoot = import("Actor") end
                if not _G.CachedLootArray then _G.CachedLootArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForLoot) end
                local ui_util = require("client.common.ui_util")
                local gameInstance = ui_util and ui_util.GetGameInstance()
                if not (gameInstance and _G.CachedGameplayStatics) then return end
                local curTime = os.clock()
                local scanInterval = 0.5
                local mode = _G.FufuModConfig.LootScanMode or 0
                if mode == 10 then scanInterval = 10.0 elseif mode == 20 then scanInterval = 20.0 end
                if not _G.LastLootScanTime or (curTime - _G.LastLootScanTime) >= scanInterval then
                    _G.LastLootScanTime = curTime
                    local allActors = _G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance, _G.CachedActorClass_ForLoot, _G.CachedLootArray)
                    local lootItems = {}
                    local lootKeywords = {
                        ["m416"]={name="M416",toggle="LootShowM416",colorKey="LootColor_M416"},
                        ["aug"]={name="AUG",toggle="LootShowAUG",colorKey="LootColor_AUG"},
                        ["akm"]={name="AKM",toggle="LootShowAKM",colorKey="LootColor_AKM"},
                        ["m24"]={name="M24",toggle="LootShowM24",colorKey="LootColor_M24"},
                        ["ump45"]={name="UMP45",toggle="LootShowUMP",colorKey="LootColor_UMP"},
                        ["ump"]={name="UMP45",toggle="LootShowUMP",colorKey="LootColor_UMP"},
                        ["dbs"]={name="DBS",toggle="LootShowDBS",colorKey="LootColor_DBS"},
                        ["s12k"]={name="S12K",toggle="LootShowS12K",colorKey="LootColor_S12K"},
                        ["s12"]={name="S12K",toggle="LootShowS12K",colorKey="LootColor_S12K"},
                    }
                    local level3Items = {
                        ["armor"]={name="Vest Lv3",toggle="LootShowVest3",colorKey="LootColor_Vest3"},
                        ["helmet"]={name="Helm Lv3",toggle="LootShowHelmet3",colorKey="LootColor_Helmet3"},
                        ["helm"]={name="Helm Lv3",toggle="LootShowHelmet3",colorKey="LootColor_Helmet3"},
                        ["bag 3"]={name="Bag Lv3",toggle="LootShowBag3",colorKey="LootColor_Bag3"},
                        ["backpack 3"]={name="Bag Lv3",toggle="LootShowBag3",colorKey="LootColor_Bag3"},
                    }
                    if allActors then
                        for _, actor in pairs(allActors) do
                            if slua.isValid(actor) and not actor.bHidden and not actor.bTearOff then
                                local isPendingKill = false
                                pcall(function() if type(actor.IsPendingKill) == "function" then isPendingKill = actor:IsPendingKill() end end)
                                if not isPendingKill then
                                    local actorName = ""
                                    pcall(function()
                                        if type(actor.GetName) == "function" then actorName = actor:GetName()
                                        elseif actor.Name then actorName = actor.Name
                                        else actorName = tostring(actor) end
                                    end)
                                    local lowerName = string.lower(actorName)
                                    if lowerName == "" then lowerName = string.lower(tostring(actor)) end
                                    local displayInfo, matched = nil, false
                                    for keyword, info in pairs(lootKeywords) do
                                        if string.find(lowerName, keyword, 1, true) then displayInfo = info; matched = true; break end
                                    end
                                    if not matched then
                                        for keyword, info in pairs(level3Items) do
                                            if string.find(lowerName, keyword, 1, true) and string.find(lowerName, "3", 1, true) then
                                                displayInfo = info; matched = true; break
                                            end
                                        end
                                    end
                                    if matched and displayInfo then table.insert(lootItems, {act=actor, info=displayInfo}) end
                                end
                            end
                        end
                    end
                    _G.CachedLootItems = lootItems
                end
                if _G.CachedLootItems then
                    for _, item in ipairs(_G.CachedLootItems) do
                        local loot = item.act
                        if slua.isValid(loot) and not loot.bHidden then
                            local distM = 0
                            pcall(function() distM = localPlayer:GetDistanceTo(loot) / 100 end)
                            if distM > 0 and distM <= 100 then
                                local toggle = item.info.toggle
                                if toggle and not _G.FufuModConfig[toggle] then goto cont2 end
                                local colorIdx = _G.FufuModConfig[item.info.colorKey] or 4
                                local color = GetColorBy7(colorIdx)
                                MyHUD:AddDebugText(string.format("%s [%dm]", item.info.name, math.floor(distM)),
                                    loot, 0.3, {X=0,Y=0,Z=30}, {X=0,Y=0,Z=30}, color, true, false, true, nil, 0.9, true)
                            end
                            ::cont2::
                        end
                    end
                end
            end)
        end

        -- STATIC
        if _G.FufuModConfig.EspStatic then
            pcall(function()
                local MyHUD = Cached_MyHUD
                if not Valid(MyHUD) then return end
                if _G.FufuModConfig.EspEnemyCount then
                    local function GetRainbowColor()
                        local time = os.clock()
                        local r = math.sin(time*0.8)*0.5+0.5
                        local g = math.sin(time*0.8+2.094)*0.5+0.5
                        local b = math.sin(time*0.8+4.188)*0.5+0.5
                        return {R=math.floor(r*255),G=math.floor(g*255),B=math.floor(b*255),A=255}
                    end
                    local myTeamId = localPlayer.TeamID or localPlayer:GetTeamID() or 0
                    local myPos = localPlayer:K2_GetActorLocation()
                    local maxDist = 35000
                    local realCount, aiCount = 0, 0
                    for _, tPawn in pairs(allCharacters) do
                        if slua.isValid(tPawn) and tPawn ~= localPlayer then
                            local targetTeamId = tPawn.TeamID or tPawn:GetTeamID() or 0
                            if targetTeamId ~= myTeamId then
                                local enemyPos = tPawn:K2_GetActorLocation()
                                if enemyPos then
                                    local dx, dy, dz = enemyPos.X-myPos.X, enemyPos.Y-myPos.Y, enemyPos.Z-myPos.Z
                                    if math.sqrt(dx*dx+dy*dy+dz*dz) <= maxDist then
                                        local isAI = false
                                        if tPawn.bIsAI == true or tPawn.IsAI == true then isAI = true end
                                        if not isAI then
                                            local pState = tPawn.PlayerState
                                            if slua.isValid(pState) then
                                                if pState.bIsABot == true or pState.bIsBot == true then isAI = true end
                                                local playerID = pState.PlayerId or pState.PlayerID
                                                if playerID and (playerID == 0 or playerID < 10000) then isAI = true end
                                                local exactPing = pState.ExactPing or pState.Ping
                                                if exactPing and exactPing == 0 then isAI = true end
                                            else isAI = true end
                                        end
                                        if isAI then aiCount = aiCount + 1 else realCount = realCount + 1 end
                                    end
                                end
                            end
                        end
                    end
                    local color = GetRainbowColor()
                    local totalEnemy = realCount + aiCount
                    local text = totalEnemy > 0 and string.format("❮ ENEMY : %d ❯", totalEnemy) or " ❮ AREA 350M CLEAR ❯"
                    MyHUD:AddDebugText(text, localPlayer, 1.05, {X=0,Y=0,Z=150}, {X=0,Y=0,Z=150}, color, true, false, true, nil, 1.2, true)
                end
                if _G.FufuModConfig.EspWeaponStatus then
                    local ui_util = require("client.common.ui_util")
                    local viewportSize = ui_util and ui_util.GetViewportSize()
                    if viewportSize then
                        local centerX = viewportSize.X * 0.5
                        local centerY = viewportSize.Y * 0.5
                        local FOV_RADIUS = (10 / 100.0) * (viewportSize.X / 2.0)
                        local FVector2DClass = import("Vector2D")
                        local bestTarget, bestDist = nil, 999999
                        for _, enemy in pairs(allCharacters) do
                            if Valid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                                local ePos = enemy:K2_GetActorLocation()
                                if ePos then
                                    local screen = FVector2DClass()
                                    if pc:ProjectWorldLocationToScreen(ePos, screen, false) and screen.X > 0 and screen.Y > 0 then
                                        local dx, dy = screen.X-centerX, screen.Y-centerY
                                        if math.sqrt(dx*dx+dy*dy) <= FOV_RADIUS then
                                            local dist3D = localPlayer:GetDistanceTo(enemy)
                                            if dist3D < bestDist then bestDist = dist3D; bestTarget = enemy end
                                        end
                                    end
                                end
                            end
                        end
                        if Valid(bestTarget) then
                            local distM = math.floor(bestDist / 100)
                            local hp = bestTarget.Health or 100
                            local maxHp = bestTarget.HealthMax or 100
                            local hpPercent = maxHp > 0 and math.floor((hp/maxHp)*100) or 0
                            local isKnock = (hp <= 0 or bestTarget.HealthStatus == 1)
                            local weaponName = "Tangan Kosong"
                            local eWeapon = bestTarget.CurrentWeapon or bestTarget:GetCurrentWeapon()
                            if Valid(eWeapon) and type(eWeapon.GetWeaponName) == "function" then weaponName = eWeapon:GetWeaponName() end
                            local statusText = isKnock and " [K]" or ""
                            local text = string.format("%s | %dm | %d%% HP%s", weaponName, distM, hpPercent, statusText)
                            MyHUD:AddDebugText(text, bestTarget, 0.15, {X=0,Y=0,Z=-50}, {X=0,Y=0,Z=-50}, C_YELLOW, true, false, true, nil, 0.8, true)
                        end
                    end
                end
            end)
        end
    end)
end

-- ==============================================================================
-- UMG HELPERS
-- ==============================================================================
local currentTab = "VISUALS"
local bgPanel, floatItem, contentContainer, parentCanvas, isMenuOpen = nil, nil, nil, nil, false

local function NewObject(path, parent)
    local obj = nil
    pcall(function()
        if CGame and CGame.NewObjectFromPath then obj = CGame:NewObjectFromPath(path, parent) end
    end)
    return obj
end

local function Layer(parent, x, y, w, h, color, zOrder)
    local b = NewObject("/Script/UMG.Border", parent)
    if Valid(b) then
        pcall(function() b:SetBrushColor(color) end)
        pcall(function() b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        local slot = parent:AddChildToCanvas(b)
        if slot then
            slot:SetAutoSize(false); slot:SetPosition(FVector2D(x, y))
            slot:SetSize(FVector2D(w, h)); slot:SetZOrder(zOrder or 0)
        end
    end
    return b
end

local function Text(parent, text, x, y, fontSize, color, zOrder, alignX, alignY)
    local tb = NewObject("/Script/UMG.TextBlock", parent)
    if Valid(tb) then
        pcall(function()
            tb:SetText(tostring(text or ""))
            tb:SetFont({ Size = fontSize or 12 })
            tb:SetColorAndOpacity(color or Colors.text_white)
            tb:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local slot = parent:AddChildToCanvas(tb)
        if slot then
            slot:SetAutoSize(true); slot:SetPosition(FVector2D(x, y))
            slot:SetAlignment(FVector2D(alignX or 0, alignY or 0)); slot:SetZOrder(zOrder or 1)
        end
    end
    return tb
end

local function MakeBtn(parent, x, y, w, h, zOrder, onClick)
    local btn = NewObject("/Script/UMG.Button", parent)
    if Valid(btn) then
        pcall(function() btn:SetColorAndOpacity(Colors.transparent) end)
        pcall(function() btn:SetBackgroundColor(Colors.transparent) end)
        pcall(function() btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible) end)
        local slot = parent:AddChildToCanvas(btn)
        if slot then
            slot:SetAutoSize(false); slot:SetPosition(FVector2D(x, y))
            slot:SetSize(FVector2D(w, h)); slot:SetZOrder(zOrder or 100)
        end
        if onClick then
            pcall(function()
                if btn.OnClicked then btn.OnClicked:Add(function() pcall(onClick) end) end
            end)
        end
    end
    return btn
end

local function Notify(msg)
    pcall(function()
        local sh = import("ScriptHelperClient")
        if sh and sh.AddOnScreenDebugMessage then
            sh.AddOnScreenDebugMessage("[SodaLite] "..tostring(msg), -1, 2.5, {R=0.2,G=0.6,B=1.0,A=1}, {X=1.2,Y=1.2})
        end
    end)
    print("[SodaLite] "..tostring(msg))
end

-- ==============================================================================
-- DRAW: single / pair
-- ==============================================================================
local function DrawCheckbox(parent, x, y, w, label, configKey)
    local h = ROW_H
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y+h-1, w, 1, FLinearColor(0.2,0.25,0.35,0.4), 11)
    Text(parent, label, x+16, y+h*0.5, 12, Colors.text_white, 15, 0.0, 0.5)
    local toggleW, toggleH = 46, 22
    local toggleX = x + w - toggleW - 14
    local toggleY = y + (h - toggleH) * 0.5
    local track = Layer(parent, toggleX, toggleY, toggleW, toggleH, Config[configKey] and Colors.toggle_on or Colors.toggle_off, 12)
    local knobSize = 18
    local knobOffset = Config[configKey] and (toggleW - knobSize - 2) or 2
    local knob = Layer(parent, toggleX+knobOffset, toggleY+2, knobSize, knobSize, Colors.toggle_knob, 14)
    MakeBtn(parent, x, y, w, h, 20, function()
        Config[configKey] = not Config[configKey]
        local isEnabled = Config[configKey]
        if Valid(track) then track:SetBrushColor(isEnabled and Colors.toggle_on or Colors.toggle_off) end
        if Valid(knob) then
            local newKnobX = toggleX + (isEnabled and (toggleW - knobSize - 2) or 2)
            if knob.Slot then knob.Slot:SetPosition(FVector2D(newKnobX, toggleY+2)) end
        end
        _G.SodaSave()
        Notify(label..": "..(isEnabled and "ON" or "OFF"))
    end)
end

local function DrawSlider(parent, x, y, w, label, configKey, minVal, maxVal)
    local h = ROW_H
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y+h-1, w, 1, FLinearColor(0.2,0.25,0.35,0.4), 11)
    Text(parent, label, x+16, y+h*0.5, 12, Colors.text_white, 15, 0.0, 0.5)
    local valText = Text(parent, tostring(Config[configKey]), x+w-120, y+h*0.5, 12, Colors.accent_blue, 15, 1.0, 0.5)
    local btnW, btnMinusX, btnPlusX = 28, x+w-85, x+w-40
    local btnY = y + (h-26)*0.5
    Layer(parent, btnMinusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "-", btnMinusX+btnW*0.5, btnY+13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnMinusX, btnY, btnW, 26, 20, function()
        if Config[configKey] > minVal then
            Config[configKey] = Config[configKey] - 1
            if Valid(valText) then valText:SetText(tostring(Config[configKey])) end
            _G.SodaSave()
        end
    end)
    Layer(parent, btnPlusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "+", btnPlusX+btnW*0.5, btnY+13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnPlusX, btnY, btnW, 26, 20, function()
        if Config[configKey] < maxVal then
            Config[configKey] = Config[configKey] + 1
            if Valid(valText) then valText:SetText(tostring(Config[configKey])) end
            _G.SodaSave()
        end
    end)
end

local function DrawCheckboxSmall(parent, x, y, w, h, label, configKey)
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y+h-1, w, 1, FLinearColor(0.2,0.25,0.35,0.4), 11)
    Text(parent, label, x+10, y+h*0.5, 10, Colors.text_white, 15, 0.0, 0.5)
    local toggleW, toggleH = 36, 18
    local toggleX = x + w - toggleW - 8
    local toggleY = y + (h - toggleH) * 0.5
    local track = Layer(parent, toggleX, toggleY, toggleW, toggleH, Config[configKey] and Colors.toggle_on or Colors.toggle_off, 12)
    local knobSize = 14
    local knobOffset = Config[configKey] and (toggleW - knobSize - 2) or 2
    local knob = Layer(parent, toggleX+knobOffset, toggleY+2, knobSize, knobSize, Colors.toggle_knob, 14)
    MakeBtn(parent, x, y, w, h, 20, function()
        Config[configKey] = not Config[configKey]
        local isEnabled = Config[configKey]
        if Valid(track) then track:SetBrushColor(isEnabled and Colors.toggle_on or Colors.toggle_off) end
        if Valid(knob) then
            local newKnobX = toggleX + (isEnabled and (toggleW - knobSize - 2) or 2)
            if knob.Slot then knob.Slot:SetPosition(FVector2D(newKnobX, toggleY+2)) end
        end
        _G.SodaSave()
        Notify(label..": "..(isEnabled and "ON" or "OFF"))
    end)
end

local function DrawCheckboxPair(parent, x, y, w, label1, key1, label2, key2)
    local h = PAIR_H
    local halfW = (w - 6) / 2
    DrawCheckboxSmall(parent, x, y, halfW, h, label1, key1)
    if label2 and key2 then DrawCheckboxSmall(parent, x+halfW+6, y, halfW, h, label2, key2) end
end

local function DrawSwitcherSmall(parent, x, y, w, h, label, stateKey, texts, values)
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y+h-1, w, 1, FLinearColor(0.2,0.25,0.35,0.4), 11)
    Text(parent, label, x+10, y+h*0.5, 10, Colors.text_white, 15, 0.0, 0.5)
    local cData = _G.FufuModState.CustomTextData
    local curVal = cData[stateKey] or values[1]
    local curIdx = 1
    for i, v in ipairs(values) do if v == curVal then curIdx = i; break end end
    local btnW = 70
    local btnX = x + w - btnW - 6
    local btnY = y + (h - 18) * 0.5
    Layer(parent, btnX, btnY, btnW, 18, Colors.slider_bg, 12)
    local valText = Text(parent, texts[curIdx] or "?", btnX+btnW*0.5, btnY+9, 10, Colors.accent_blue, 13, 0.5, 0.5)
    MakeBtn(parent, btnX, btnY, btnW, 18, 20, function()
        curIdx = curIdx + 1
        if curIdx > #values then curIdx = 1 end
        cData[stateKey] = values[curIdx]
        if Valid(valText) then valText:SetText(texts[curIdx]) end
        _G.SodaSave()
    end)
end

local function DrawSwitcherPair(parent, x, y, w, label1, key1, texts1, vals1, label2, key2, texts2, vals2)
    local h = PAIR_H
    local halfW = (w - 6) / 2
    DrawSwitcherSmall(parent, x, y, halfW, h, label1, key1, texts1, vals1)
    if label2 and key2 then DrawSwitcherSmall(parent, x+halfW+6, y, halfW, h, label2, key2, texts2, vals2) end
end

local function DrawSliderSmall(parent, x, y, w, h, label, stateKey, minVal, maxVal)
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y+h-1, w, 1, FLinearColor(0.2,0.25,0.35,0.4), 11)
    Text(parent, label, x+10, y+h*0.5, 10, Colors.text_white, 15, 0.0, 0.5)
    local cData = _G.FufuModState.CustomTextData
    local curVal = cData[stateKey] or minVal
    local valText = Text(parent, tostring(curVal), x+w-90, y+h*0.5, 10, Colors.accent_blue, 15, 1.0, 0.5)
    local btnW = 22
    local btnY = y + (h - 18) * 0.5
    local btnMinusX = x + w - 60
    local btnPlusX = x + w - 28
    Layer(parent, btnMinusX, btnY, btnW, 18, Colors.slider_bg, 12)
    Text(parent, "-", btnMinusX+btnW*0.5, btnY+9, 12, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnMinusX, btnY, btnW, 18, 20, function()
        local v = cData[stateKey] or minVal
        if v > minVal then cData[stateKey] = v - 1; if Valid(valText) then valText:SetText(tostring(cData[stateKey])) end; _G.SodaSave() end
    end)
    Layer(parent, btnPlusX, btnY, btnW, 18, Colors.slider_bg, 12)
    Text(parent, "+", btnPlusX+btnW*0.5, btnY+9, 12, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnPlusX, btnY, btnW, 18, 20, function()
        local v = cData[stateKey] or minVal
        if v < maxVal then cData[stateKey] = v + 1; if Valid(valText) then valText:SetText(tostring(cData[stateKey])) end; _G.SodaSave() end
    end)
end

local function DrawSliderPair(parent, x, y, w, label1, key1, min1, max1, label2, key2, min2, max2)
    local h = PAIR_H
    local halfW = (w - 6) / 2
    DrawSliderSmall(parent, x, y, halfW, h, label1, key1, min1, max1)
    if label2 and key2 then DrawSliderSmall(parent, x+halfW+6, y, halfW, h, label2, key2, min2, max2) end
end

-- ==============================================================================
-- RENDER CONTENT
-- ==============================================================================
local function RenderContent()
    if not Valid(contentContainer) then return end
    contentContainer:ClearChildren()
    local startY = 8
    local colW = MENU_W - 32
    local y

    if currentTab == "VISUALS" then
        DrawCheckbox(contentContainer, 16, startY, colW, "Black Sky (Чёрное небо)", "BlackSky")
        DrawCheckbox(contentContainer, 16, startY+44, colW, "Wallhack (Chams / Сквозь стены)", "Wallhack")
        DrawSlider(contentContainer, 16, startY+88, colW, "   > Яркость Wallhack Glow (1-10)", "WallhackGlow", 1, 10)
        DrawCheckbox(contentContainer, 16, startY+132, colW, "IPad View (Отдаление камеры)", "IpadView")
        DrawSlider(contentContainer, 16, startY+176, colW, "   > Угол обзора FOV (90-140)", "IpadViewFOV", 90, 140)

    elseif currentTab == "ESP" then
        y = startY
        Text(contentContainer, "▼ CORE ESP", 16, y+6, 11, Colors.accent_blue, 15, 0.0, 0.0); y = y + 22
        DrawCheckboxPair(contentContainer, 16, y, colW, "ESP AUTO", "EspVip", "ESP METER", "EspDistance"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "HEALTH V1", "EspVipPro", "ESP MARK", "EspRadar"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "BOX FRAME", "Esp5", "ESP HEAD", "Esp6"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "HEALTH V2", "Esp8", "LINE ANTENNA", "EspAntenna"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "ESP NAME", "EspName", "ENEMY COUNT", "EspEnemyCount"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "WEAPON STATUS", "EspWeaponStatus", "ESP STATIC", "EspStatic"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "ENGINE CHAMS", "ColorBodyNew", nil, nil); y = y + PAIR_H + 6

        Text(contentContainer, "▼ THROWABLE", 16, y+6, 11, Colors.accent_blue, 15, 0.0, 0.0); y = y + 22
        DrawCheckboxPair(contentContainer, 16, y, colW, "THROWABLE", "ThrowableEnabled", "GRENADE", "ThrowableGrenade"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "SMOKE", "ThrowableSmoke", "MOLOTOV", "ThrowableMolotov"); y = y + PAIR_H + 6

        Text(contentContainer, "▼ VEHICLE", 16, y+6, 11, Colors.accent_blue, 15, 0.0, 0.0); y = y + 22
        DrawCheckboxPair(contentContainer, 16, y, colW, "VEHICLE", "VehicleEnabled", "DACIA", "VehicleShowDacia"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "UAZ", "VehicleShowUAZ", "BUGGY", "VehicleShowBuggy"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "COUPE", "VehicleShowCoupe", "MIRADO", "VehicleShowMirado"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "MOTOR", "VehicleShowMotor", "OTHER", "VehicleShowOther"); y = y + PAIR_H + 6

        Text(contentContainer, "▼ LOOT", 16, y+6, 11, Colors.accent_blue, 15, 0.0, 0.0); y = y + 22
        DrawCheckboxPair(contentContainer, 16, y, colW, "LOOT", "EspLoot", "M416", "LootShowM416"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "AUG", "LootShowAUG", "AKM", "LootShowAKM"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "M24", "LootShowM24", "UMP", "LootShowUMP"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "DBS", "LootShowDBS", "S12K", "LootShowS12K"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "VEST3", "LootShowVest3", "HELMET3", "LootShowHelmet3"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "BAG3", "LootShowBag3", nil, nil); y = y + PAIR_H + 2

    elseif currentTab == "AIMBOT" then
        y = startY
        DrawCheckbox(contentContainer, 16, y, colW, "Enable Aimbot (Master)", "AimTouchEnable"); y = y + ROW_H + 6
        DrawCheckbox(contentContainer, 16, y, colW, "Show FOV Circle (показывать круг FOV)", "EspFovCircle"); y = y + ROW_H + 6

        Text(contentContainer, "▼ SCOPED AIMBOT (works in ADS only)", 16, y+4, 11, Colors.accent_blue, 15, 0.0, 0.0); y = y + 20
        DrawCheckboxPair(contentContainer, 16, y, colW, "SCOPE ALL WEAPONS", "AimTouchScopeAll", "SCOPE SNIPER ONLY", "AimTouchScopeSniper"); y = y + PAIR_H + 4

        Text(contentContainer, "— Scope All options —", 16, y+4, 10, Colors.text_dim, 15, 0.0, 0.0); y = y + 18
        DrawCheckboxPair(contentContainer, 16, y, colW, "IgKnock", "AimTouchScopeIgKnock", "IgBot", "AimTouchScopeIgBot"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "VisCheck", "AimTouchScopeVisCheck", nil, nil); y = y + PAIR_H + 2
        DrawSwitcherPair(contentContainer, 16, y, colW,
            "Priority", "AimTouchScopePrio", {"Center","Dist","HP","HP%"}, {1,2,3,4},
            "Bone", "AimTouchScopeBone", {"Head","Chest","Stomach","Pelvis"}, {1,2,3,4}); y = y + PAIR_H + 2
        DrawSwitcherPair(contentContainer, 16, y, colW,
            "Condition", "AimTouchScopeCond", {"Aim when firing","Always aim"}, {1,2},
            nil, nil, nil, nil); y = y + PAIR_H + 2
        DrawSliderPair(contentContainer, 16, y, colW,
            "Speed", "AimTouchScopeSpeed", 1, 100,
            "FOV", "AimTouchScopeFOV", 1, 100); y = y + PAIR_H + 2
        DrawSliderPair(contentContainer, 16, y, colW,
            "Distance (x5 m)", "AimTouchScopeDist", 1, 100,
            "Prediction", "AimTouchScopePred", 0, 100); y = y + PAIR_H + 2
        DrawSliderPair(contentContainer, 16, y, colW,
            "Recoil Comp", "AimTouchScopeRecoil", 0, 50,
            "FOV Color", "AimTouchScopeFOVColor", 1, 7); y = y + PAIR_H + 6

        Text(contentContainer, "— Scope Sniper options —", 16, y+4, 10, Colors.text_dim, 15, 0.0, 0.0); y = y + 18
        DrawCheckboxPair(contentContainer, 16, y, colW, "Sniper IgKnock", "AimTouchSniperIgKnock", "Sniper IgBot", "AimTouchSniperIgBot"); y = y + PAIR_H + 2
        DrawCheckboxPair(contentContainer, 16, y, colW, "Sniper VisCheck", "AimTouchSniperVisCheck", nil, nil); y = y + PAIR_H + 2
        DrawSwitcherPair(contentContainer, 16, y, colW,
            "Sniper Priority", "AimTouchSniperPrio", {"Center","Dist","HP","HP%"}, {1,2,3,4},
            "Sniper Bone", "AimTouchSniperBone", {"Head","Chest","Stomach","Pelvis"}, {1,2,3,4}); y = y + PAIR_H + 2
        DrawSwitcherPair(contentContainer, 16, y, colW,
            "Sniper Cond", "AimTouchSniperCond", {"Aim when firing","Open Scope Aim"}, {1,2},
            nil, nil, nil, nil); y = y + PAIR_H + 2
        DrawSliderPair(contentContainer, 16, y, colW,
            "Sniper Speed", "AimTouchSniperSpeed", 1, 100,
            "Sniper FOV", "AimTouchSniperFOV", 1, 100); y = y + PAIR_H + 2
        DrawSliderPair(contentContainer, 16, y, colW,
            "Sniper Distance (x5 m)", "AimTouchSniperDist", 1, 100,
            "Sniper Prediction", "AimTouchSniperPred", 0, 100); y = y + PAIR_H + 2
        DrawSliderPair(contentContainer, 16, y, colW,
            "Sniper FOV Color", "AimTouchSniperFOVColor", 1, 7,
            nil, nil, 0, 0); y = y + PAIR_H + 2
    
        elseif currentTab == "EXPLOIT" then
        y = startY
        Text(contentContainer, "▼ MOVEMENT EXPLOITS", 16, y+6, 11, Colors.accent_blue, 15, 0.0, 0.0); y = y + 22

        -- FastMove toggle (полная ширина)
        DrawCheckbox(contentContainer, 16, y, colW, "FAST MOVE (спринт ускорение)", "FastMove_Enabled"); y = y + ROW_H + 6

        -- Speed multiplier
        DrawSlider(contentContainer, 16, y, colW, "   > Speed Multiplier (1-25x)", "FastMove_Multiplier", 1, 25); y = y + ROW_H + 6

        Text(contentContainer, "   Работает только пешком (в машине авто-отключается).", 16, y+4, 10, Colors.text_dim, 15, 0.0, 0.0); y = y + 22
        Text(contentContainer, "   Multiplier >15 может быть заметно для античита.", 16, y+4, 10, Colors.text_dim, 15, 0.0, 0.0); y = y + 22
    end
end

-- ==============================================================================
-- BUILD MENU
-- ==============================================================================
local function BuildMenu(canvas)
    if Valid(bgPanel) then
        bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        isMenuOpen = true
        return
    end
    bgPanel = NewObject("/Script/UMG.CanvasPanel", canvas)
    local bgSlot = canvas:AddChildToCanvas(bgPanel)
    bgSlot:SetPosition(FVector2D(menuPos.X, menuPos.Y))
    bgSlot:SetSize(FVector2D(MENU_W, MENU_H))
    bgSlot:SetZOrder(10000)
    Layer(bgPanel, -2, -2, MENU_W+4, MENU_H+4, Colors.border, 1)
    Layer(bgPanel, 0, 0, MENU_W, MENU_H, Colors.bg_main, 2)

    local HEADER_H = 44
    Layer(bgPanel, 0, 0, MENU_W, HEADER_H, Colors.bg_header, 3)
    Layer(bgPanel, 0, HEADER_H-1, MENU_W, 1, Colors.border, 4)
    Text(bgPanel, "SodaLite GLOBAL + FULL ESP/AIM", 16, HEADER_H*0.5, 14, Colors.text_white, 5, 0.0, 0.5)

    local closeX = MENU_W - 36
    Layer(bgPanel, closeX, 8, 28, 28, Colors.accent_red, 5)
    Text(bgPanel, "X", closeX+14, 22, 12, Colors.text_white, 6, 0.5, 0.5)
    MakeBtn(bgPanel, closeX, 8, 28, 28, 50, function()
        bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed); isMenuOpen = false
    end)

    local tabY = HEADER_H + 8
    local tabW, tabH = 150, 32
    local function MakeTab(label, key, xOff)
        Layer(bgPanel, 16+xOff, tabY, tabW, tabH, Colors.bg_row, 5)
        Text(bgPanel, label, 16+xOff+tabW*0.5, tabY+tabH*0.5, 11, Colors.text_white, 6, 0.5, 0.5)
        MakeBtn(bgPanel, 16+xOff, tabY, tabW, tabH, 20, function() currentTab = key; RenderContent() end)
    end
    MakeTab("VISUALS", "VISUALS", 0)
    MakeTab("ESP", "ESP", tabW+8)
    MakeTab("AIMBOT", "AIMBOT", (tabW+8)*2)
    MakeTab("EXPLOIT", "EXPLOIT", (tabW+8)*3)

    contentContainer = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local cSlot = bgPanel:AddChildToCanvas(contentContainer)
    cSlot:SetPosition(FVector2D(0, tabY + tabH + 6))
    cSlot:SetSize(FVector2D(MENU_W, MENU_H - (tabY + tabH + 6)))
    cSlot:SetZOrder(10)
    RenderContent()
    isMenuOpen = true
end

local function ToggleMenu(canvas)
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        if Valid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        else BuildMenu(canvas) end
    else
        if Valid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
    end
end

local function CreateFloatButton(canvas)
    if floatItem and Valid(floatItem.btn) then return end
    floatItem = {}
    local fX, fY, fW, fH = floatPos.X, floatPos.Y, FLOAT_W, FLOAT_H
    floatItem.shadow = Layer(canvas, fX+2, fY+3, fW, fH, Colors.shadow, 11898)
    floatItem.border = Layer(canvas, fX-1, fY-1, fW+2, fH+2, Colors.border, 11900)
    floatItem.bg     = Layer(canvas, fX, fY, fW, fH, Colors.bg_header, 11901)
    floatItem.text   = Text(canvas, "SodaLite", fX+fW*0.5, fY+fH*0.5, 11, Colors.accent_blue, 12001, 0.5, 0.5)
    floatItem.btn    = MakeBtn(canvas, fX, fY, fW, fH, 12002, function() ToggleMenu(canvas) end)
end

-- ==============================================================================
-- SODALITE ORIGINAL FEATURES
-- ==============================================================================
local _prevBlackSky = nil
local function UpdateBlackSky()
    if Config.BlackSky == _prevBlackSky then return end
    _prevBlackSky = Config.BlackSky
    pcall(function()
        local KSL = import("KismetSystemLibrary")
        local world = slua and slua.getWorld and slua.getWorld()
        if not KSL or not world then return end
        if Config.BlackSky then KSL.ExecuteConsoleCommand(world, "r.CylinderMaxDrawHeight 9999")
        else KSL.ExecuteConsoleCommand(world, "r.CylinderMaxDrawHeight 0000") end
    end)
end

local _prevIpadView, _prevIpadFOV = nil, nil
local function UpdateIpadView(localPlayer, pc)
    pcall(function()
        if not IsValid(localPlayer) or not IsValid(pc) then return end
        local uTPPCam = localPlayer.ThirdPersonCameraComponent
        local camMgr = pc.PlayerCameraManager
        if Config.IpadView then
            local targetFOV = Config.IpadViewFOV or 120
            if _prevIpadView ~= true or _prevIpadFOV ~= targetFOV then
                _prevIpadView, _prevIpadFOV = true, targetFOV
                if IsValid(uTPPCam) then uTPPCam.FieldOfView = targetFOV end
                if IsValid(camMgr) then camMgr.DefaultFOV = targetFOV; if type(camMgr.SetFOV) == "function" then camMgr:SetFOV(targetFOV) end end
            end
        else
            if _prevIpadView ~= false then
                _prevIpadView, _prevIpadFOV = false, 90
                if IsValid(uTPPCam) then uTPPCam.FieldOfView = 90 end
                if IsValid(camMgr) then camMgr.DefaultFOV = 90; if type(camMgr.UnlockFOV) == "function" then camMgr:UnlockFOV() end end
            end
        end
    end)
end

local _wallhackConsoleReady = false
local function InitWallhackConsole()
    if _wallhackConsoleReady then return end
    pcall(function()
        local KSL = import("KismetSystemLibrary")
        local world = slua and slua.getWorld and slua.getWorld()
        if KSL and world then
            KSL.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
            KSL.ExecuteConsoleCommand(world, "r.CustomDepth 3")
            KSL.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
            KSL.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
            _wallhackConsoleReady = true
        end
    end)
end

local function ApplyWallhack(enemy, glow)
    local LinearColorClass = import("LinearColor") or FLinearColor
    local glowVal = glow or 3.0
    local visColor = LinearColorClass(0.0*glowVal, 1.0*glowVal, 0.2*glowVal, 1.0)
    local occColor = LinearColorClass(1.0*glowVal, 0.1*glowVal, 0.2*glowVal, 1.0)
    for _, mesh in ipairs(GetAllSkeletalMeshes(enemy)) do
        if IsValid(mesh) then
            pcall(function()
                if type(mesh.SetDrawDyeing) == "function" then
                    mesh:SetDrawDyeing(true); mesh:SetDrawDyeingMode(1)
                    mesh:SetVisibleDyeingColor(visColor); mesh:SetOccludedDyeingColor(occColor)
                    mesh:SetDyeingColorFadeDistance(99999.0); mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
                    mesh:SetDrawHighlight(true); mesh:OverrideHighlightColor(visColor); mesh:SetHighlightCanBeOccluded(false)
                    mesh:SetDrawIdeaOutline(true); mesh:SetIdeaOutlineNew(true); mesh:SetIdeaOutlineOcclusionHighlight(true)
                    mesh:OverrideIdeaOutlineColor(visColor); mesh:SetIdeaOutlineOcclusionColor(occColor)
                    mesh:OverrideIdeaOutlineThickness(15); mesh:SetIdeaOverrideOutlineAndOcclusion(true)
                end
            end)
        end
    end
end

local function UndoWallhack(enemy)
    for _, mesh in ipairs(GetAllSkeletalMeshes(enemy)) do
        if IsValid(mesh) then
            pcall(function()
                if type(mesh.SetDrawDyeing) == "function" then
                    mesh:SetDrawDyeing(false); mesh:SetDrawHighlight(false); mesh:SetDrawIdeaOutline(false)
                end
            end)
        end
    end
end

local _wallhackApplied = {}
local _prevWallhackState, _prevWallhackGlow = nil, nil

local function UpdateWallhack(localPlayer)
    pcall(function()
        if not IsValid(localPlayer) then return end
        local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if not okData or not GameplayData then return end
        local allCharacters = {}
        if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters()
        elseif GameplayData.GameCharacters then
            for _, c in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, c) end
        end
        local glowChanged = (_prevWallhackGlow ~= Config.WallhackGlow)
        _prevWallhackGlow = Config.WallhackGlow
        if Config.Wallhack then
            if not _prevWallhackState then InitWallhackConsole(); _prevWallhackState = true end
            for _, enemy in pairs(allCharacters) do
                if IsValid(enemy) and enemy ~= localPlayer then
                    if glowChanged or not _wallhackApplied[enemy] then
                        ApplyWallhack(enemy, Config.WallhackGlow)
                        _wallhackApplied[enemy] = true
                    end
                end
            end
        else
            if _prevWallhackState then
                _prevWallhackState = false
                for _, enemy in pairs(allCharacters) do
                    if IsValid(enemy) and enemy ~= localPlayer then UndoWallhack(enemy) end
                end
                _wallhackApplied = {}
            end
        end
    end)
end

-- ==============================================================================
-- EXPLOIT: FASTMOVE (persistent state, ramp-based, safe-context aware)
-- ==============================================================================
_G.FastMove_State = _G.FastMove_State or {
    char = nil, saved = false, o = {}, curMult = 1.0, active = false
}
local FM = _G.FastMove_State

local function FM_GetMyChar()
    local ch = nil
    pcall(function()
        local pc = _G.LocalPlayerController
        if not (pc and slua.isValid(pc)) then
            local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
            if okData and GameplayData then
                pc = GameplayData.GetPlayerController()
                if pc and slua.isValid(pc) then
                    _G.LocalPlayerController = pc
                end
            end
        end
        if pc and slua.isValid(pc) then
            ch = pc:GetPlayerCharacterSafety()
            if ch and slua.isValid(ch) then _G.LocalPlayerCharacter = ch end
        end
    end)
    return ch
end

local function FM_IsSafeContext(ch)
    local safe = true
    pcall(function()
        local veh = ch.CurrentVehicle
        if veh and slua.isValid(veh) then safe = false end
    end)
    return safe
end

local function FM_SaveOriginals(ch, cm)
    if FM.saved then return end
    FM.saved = true
    local o = FM.o
    pcall(function() o.SpeedRate  = tonumber(cm.SpeedRate) or 1 end)
    pcall(function() o.Scale      = tonumber(ch.SpeedScale) or 1 end)
    pcall(function() o.Value      = tonumber(ch.SpeedValue) or 0 end)
    pcall(function() o.Def        = tonumber(cm.DefaultMaxWalkSpeed) or 600 end)
    pcall(function() o.Max        = tonumber(cm.MaxWalkSpeed) or 600 end)
    pcall(function() o.Sprint     = tonumber(ch.MaxSprintSpeed) or 600 end)
    pcall(function() o.High       = tonumber(ch.HighWalkSpeed) or o.Sprint end)
    pcall(function() o.Crouch     = tonumber(ch.MaxCrouchSpeed) or 300 end)
    pcall(function() o.Prone      = tonumber(ch.MaxProneSpeed) or 100 end)
    pcall(function() o.SprintCr   = tonumber(ch.MaxSprintCrouchSpeed) or 400 end)
end

local function FM_Enforce(ch, cm, m)
    pcall(function() cm.SpeedRate           = FM.o.SpeedRate * m end)
    pcall(function() ch.SpeedScale          = FM.o.Scale * m end)
    pcall(function() ch.SpeedValue          = FM.o.Value * m end)
    pcall(function() cm.MaxWalkSpeed        = FM.o.Max * m end)
    pcall(function() cm.DefaultMaxWalkSpeed = FM.o.Def * m end)
    pcall(function() ch.MaxSprintSpeed      = FM.o.Sprint * m end)
    pcall(function() ch.HighWalkSpeed       = FM.o.High * m end)
    pcall(function() ch.MaxCrouchSpeed      = FM.o.Crouch * m end)
    pcall(function() ch.MaxProneSpeed       = FM.o.Prone * m end)
    pcall(function() ch.MaxSprintCrouchSpeed= FM.o.SprintCr * m end)
end

local function FM_Restore(ch)
    if not ch or not slua.isValid(ch) then return end
    pcall(function()
        local cm = ch.STCharacterMovement or ch.CharacterMovement
        if cm and slua.isValid(cm) then
            cm.SpeedRate           = FM.o.SpeedRate or 1
            cm.MaxWalkSpeed        = FM.o.Max or 600
            cm.DefaultMaxWalkSpeed = FM.o.Def or 600
        end
        ch.SpeedScale       = FM.o.Scale or 1
        ch.MaxSprintSpeed   = FM.o.Sprint or 600
    end)
end

_G.SodaFastMoveSet = function(mult)
    mult = tonumber(mult) or 1.0
    if mult > _G.SodaConfig.FastMove_MaxSafe then mult = _G.SodaConfig.FastMove_MaxSafe end
    _G.SodaConfig.FastMove_Multiplier = mult
end

local function FM_Tick()
    pcall(function()
        local cfg = _G.SodaConfig

        -- если выключен — восстановить оригиналы и выйти
        if not cfg.FastMove_Enabled then
            if FM.active then
                FM_Restore(FM.char)
                FM.active = false
                FM.saved = false
            end
            return
        end

        local ch = FM_GetMyChar()
        if ch ~= FM.char then
            FM_Restore(FM.char)
            FM.char = ch
            FM.saved = false
            FM.curMult = 1.0
        end
        if not ch then return end

        local cm = nil
        pcall(function() cm = ch.STCharacterMovement or ch.CharacterMovement end)
        if not cm or not slua.isValid(cm) then return end

        FM_SaveOriginals(ch, cm)

        local targetMult = FM_IsSafeContext(ch) and (tonumber(cfg.FastMove_Multiplier) or 10) or 1.0
        if targetMult > cfg.FastMove_MaxSafe then targetMult = cfg.FastMove_MaxSafe end

        local rampTime = tonumber(cfg.FastMove_RampTime) or 0.5
        if rampTime < 0.05 then rampTime = 0.05 end
        local dt = 0.016

        if FM.curMult < targetMult then
            FM.curMult = math.min(FM.curMult + dt / rampTime, targetMult)
        elseif FM.curMult > targetMult then
            FM.curMult = math.max(FM.curMult - dt / rampTime, targetMult)
        end

        FM_Enforce(ch, cm, FM.curMult)
        FM.active = true
    end)
end

-- ==============================================================================
-- WORKERS
-- ==============================================================================
if not _G.__SodaWorkersRunning then
    _G.__SodaWorkersRunning = true

    local function CheatWorker()
        pcall(function()
            local pc = _G.LocalPlayerController
            local localPlayer = _G.LocalPlayerCharacter
            if not IsValid(pc) or not IsValid(localPlayer) then
                local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
                if okData and GameplayData then
                    pc = GameplayData.GetPlayerController()
                    if IsValid(pc) then
                        _G.LocalPlayerController = pc
                        localPlayer = pc:GetPlayerCharacterSafety()
                        _G.LocalPlayerCharacter = localPlayer
                    end
                end
            end
            UpdateBlackSky()
            if IsValid(localPlayer) and IsValid(pc) then
                UpdateIpadView(localPlayer, pc)
                UpdateWallhack(localPlayer)
                RunESPLoop(localPlayer, pc)
            end
        end)
        local okT, ticker = pcall(require, "common.time_ticker")
        if okT and ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.15, CheatWorker) end
    end

    local function AimbotWorker()
        pcall(function()
            if _G.FufuModConfig.AimTouchEnable then
                local pc = _G.LocalPlayerController
                local player = _G.LocalPlayerCharacter
                if IsValid(pc) and IsValid(player) then
                    _G.UpdateAimMeta(pc, player)
                end
                _G.AimTouch()
            end

            -- FOV circle update (даже если aim выключен, но включен круг)
            if _G.FufuModConfig.EspFovCircle then
                local pc = _G.LocalPlayerController
                local player = _G.LocalPlayerCharacter
                if IsValid(pc) and IsValid(player) then
                    _G.FovCircleOverlay.Update(pc, player)
                end
            end

            -- FastMove (Exploit)
            FM_Tick()
        end)
        local okT, ticker = pcall(require, "common.time_ticker")
        if okT and ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.016, AimbotWorker) end
    end

    CheatWorker()
    AimbotWorker()
end

-- ==============================================================================
-- INIT
-- ==============================================================================
local function GetCanvas()
    if IsValid(parentCanvas) then return parentCanvas end
    parentCanvas = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local MainUI = InGameUITools and InGameUITools.GetMainControlBaseUI and InGameUITools.GetMainControlBaseUI()
        if MainUI and IsValid(MainUI) then
            if MainUI.CanvasPanel_0 and IsValid(MainUI.CanvasPanel_0) then parentCanvas = MainUI.CanvasPanel_0
            elseif MainUI.CanvasPanel_42 and IsValid(MainUI.CanvasPanel_42) then parentCanvas = MainUI.CanvasPanel_42 end
        end
    end)
    return parentCanvas
end

local _initDone = false
local function TryInit()
    if _initDone then return end
    local canvas = GetCanvas()
    if not canvas then return end
    CreateFloatButton(canvas)
    if floatItem and IsValid(floatItem.btn) then
        _initDone = true
        Notify("SodaLite FULL loaded")
    end
end

local function InitWatcher()
    if _initDone then return end
    pcall(TryInit)
    if not _initDone then
        local okT, ticker = pcall(require, "common.time_ticker")
        if okT and ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.5, InitWatcher) end
    end
end
InitWatcher()

function BRPlayerCharacterBase:ctor() end
function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    pcall(function()
        _G.LocalPlayerCharacter = self
        _G.LocalPlayerController = self:GetPlayerControllerSafety()
    end)
    pcall(TryInit)
end
function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    pcall(function()
        _G.LocalPlayerCharacter = self
        _G.LocalPlayerController = self:GetPlayerControllerSafety()
    end)
    pcall(TryInit)
end

return BRPlayerCharacterBase