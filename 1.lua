-- ==============================================================================
-- SodaLite GLOBAL (BRPlayerCharacterBase) - OPTIMIZED & SMOOTH
-- ==============================================================================
-- 1. Исправлено периодическое отключение каждые 8 секунд
-- 2. Полный ребрендинг: везде прописано SodaLite
-- 3. Добавлены вкладки ESP и AIMBOT (спащено с pasta.lua)
-- 4. Реализован скролл для вкладок с большим количеством функций
-- ==============================================================================

local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {},
  LuaEventContainer = {}
}

-- RPC сигнатуры
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }

-- ==============================================================================
-- 1. СИСТЕМА ТИПОВ: FLinearColor & FVector2D
-- ==============================================================================
local function FLinearColor(r, g, b, a)
    local col = { R = r or 1, G = g or 1, B = b or 1, A = a or 1, r = r or 1, g = g or 1, b = b or 1, a = a or 1 }
    local ok, LC = pcall(import, "LinearColor")
    if ok and LC then return LC(r, g, b, a) end
    return col
end

local function FVector2D(x, y)
    local vec = { X = x or 0, Y = y or 0, x = x or 0, y = y or 0 }
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
    slider_fill = FLinearColor(0.18, 0.55, 1.00, 1.00),
    transparent = FLinearColor(0.00, 0.00, 0.00, 0.00),
    shadow      = FLinearColor(0.00, 0.00, 0.00, 0.45),
}

-- Размеры окна
local MENU_W = 620
local MENU_H = 520
local ROW_H  = 38
local menuPos = { X = 300, Y = 100 }

local FLOAT_W = 110
local FLOAT_H = 38
local floatPos = { X = 750, Y = 15 }

-- Настройки функций (расширенные)
local Config = {
    -- VISUALS (оригинальные)
    BlackSky     = false,
    Wallhack     = false,
    WallhackGlow = 3,
    IpadView     = false,
    IpadViewFOV  = 120,

    -- ESP (спащено с pasta.lua)
    EspVip = false,
    EspDistance = false,
    EspVipPro = false,
    EspRadar = false,
    Esp5 = false,
    Esp6 = false,
    Esp8 = false,
    EspAntenna = false,
    EspName = false,
    EspStatic = false,
    EspEnemyCount = true,
    EspWeaponStatus = true,
    EspFovCircle = false,
    OutlineThickness = 10,

    -- ESP Vehicle
    VehicleEnabled = false,
    VehicleShowDacia = false,
    VehicleShowUAZ = false,
    VehicleShowBuggy = false,
    VehicleShowCoupe = false,
    VehicleShowMirado = false,
    VehicleShowMotor = false,
    VehicleShowOther = false,
    VehicleColor_Dacia = 4,
    VehicleColor_UAZ = 4,
    VehicleColor_Buggy = 4,
    VehicleColor_Coupe = 4,
    VehicleColor_Mirado = 4,
    VehicleColor_Motor = 4,
    VehicleColor_Other = 4,

    -- ESP Throwable
    ThrowableEnabled = false,
    ThrowableGrenade = false,
    ThrowableSmoke = false,
    ThrowableMolotov = false,
    ThrowableColor_Grenade = 4,
    ThrowableColor_Smoke = 4,
    ThrowableColor_Molotov = 4,
    ThrowableScanMode = 0,

    -- ESP Loot
    EspLoot = false,
    LootShowM416 = false,
    LootShowAUG = false,
    LootShowAKM = false,
    LootShowM24 = false,
    LootShowUMP = false,
    LootShowDBS = false,
    LootShowS12K = false,
    LootShowVest3 = false,
    LootShowHelmet3 = false,
    LootShowBag3 = false,
    LootColor_M416 = 4,
    LootColor_AUG = 4,
    LootColor_AKM = 4,
    LootColor_M24 = 4,
    LootColor_UMP = 4,
    LootColor_DBS = 4,
    LootColor_S12K = 4,
    LootColor_Vest3 = 4,
    LootColor_Helmet3 = 4,
    LootColor_Bag3 = 4,
    LootScanMode = 0,

    -- AIMBOT (спащено с pasta.lua)
    AimTouchEnable = false,
    AimTouchHipIgKnock = false,
    AimTouchHipIgBot = false,
    AimTouchSGIgKnock = false,
    AimTouchSGIgBot = false,
    AimTouchHipVisCheck = false,
    AimTouchSGVisCheck = false,
    AimTouchHipfire = false,
    AimTouchSG = false,
    AimTouchSGAutoFire = false,
    AimTouchScopeAll = false,
    AimTouchScopeIgKnock = false,
    AimTouchScopeIgBot = false,
    AimTouchScopeVisCheck = false,
    AimTouchScopeSniper = false,
    AimTouchSniperIgKnock = false,
    AimTouchSniperIgBot = false,
    AimTouchSniperVisCheck = false,
    AimTouchMortar = false,

    -- Color Config (для ESP)
    ColorConfig_VisibleColor = 4,
    ColorConfig_InvisibleColor = 1,
    ColorConfig_Brightness = 25,
    ColorConfig_Glow = 3.0,
}

-- AimBot настройки (спащено с pasta.lua)
local AimConfig = {
    AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1, AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250,
    AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1, AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30,
    AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1, AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300, AimTouchScopePred = 0, AimTouchScopeRecoil = 0,
    AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2, AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400, AimTouchSniperPred = 0,
    AimTouchMortarPred = 0,
    AimTouchMortarFOV = 360,
    AimTouchHipFOVColor = 7,
    AimTouchSGFOVColor = 1,
    AimTouchScopeFOVColor = 6,
    AimTouchSniperFOVColor = 4,
    AimTouchMortarFOVColor = 5,
}

local currentTab = "VISUALS"
local bgPanel = nil
local floatItem = nil
local contentContainer = nil
local parentCanvas = nil
local isMenuOpen = false
local scrollOffset = 0
local maxScrollOffset = 0
local scrollStep = 40

local function IsValid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, obj)
        return ok and v
    end
    if Game and Game.IsValid then
        local ok, v = pcall(Game.IsValid, Game, obj)
        return ok and v
    end
    return true
end

-- ==============================================================================
-- 2. ОПТИМИЗИРОВАННАЯ ЛОГИКА ФУНКЦИЙ (БЕЗ СПАМА И МЕРЦАНИЯ)
-- ==============================================================================

-- 1. BLACK SKY (Вызывается только при смене тумблера)
local _prevBlackSky = nil
local function UpdateBlackSky()
    if Config.BlackSky == _prevBlackSky then return end
    _prevBlackSky = Config.BlackSky

    pcall(function()
        local KSL = import("KismetSystemLibrary")
        local world = slua and slua.getWorld and slua.getWorld()
        if not KSL or not world then return end
        if Config.BlackSky then
            KSL.ExecuteConsoleCommand(world, "r.CylinderMaxDrawHeight 9999")
        else
            KSL.ExecuteConsoleCommand(world, "r.CylinderMaxDrawHeight 0000")
        end
    end)
end

-- 2. IPAD VIEW (Применяется только при изменении FOV или тумблера)
local _prevIpadView = nil
local _prevIpadFOV = nil
local function UpdateIpadView(localPlayer, pc)
    pcall(function()
        if not IsValid(localPlayer) or not IsValid(pc) then return end
        local uTPPCam = localPlayer.ThirdPersonCameraComponent
        local camMgr = pc.PlayerCameraManager

        if Config.IpadView then
            local targetFOV = Config.IpadViewFOV or 120
            if _prevIpadView ~= true or _prevIpadFOV ~= targetFOV then
                _prevIpadView = true
                _prevIpadFOV = targetFOV
                if IsValid(uTPPCam) then uTPPCam.FieldOfView = targetFOV end
                if IsValid(camMgr) then
                    camMgr.DefaultFOV = targetFOV
                    if type(camMgr.SetFOV) == "function" then camMgr:SetFOV(targetFOV) end
                end
            end
        else
            if _prevIpadView ~= false then
                _prevIpadView = false
                _prevIpadFOV = 90
                if IsValid(uTPPCam) then uTPPCam.FieldOfView = 90 end
                if IsValid(camMgr) then
                    camMgr.DefaultFOV = 90
                    if type(camMgr.UnlockFOV) == "function" then camMgr:UnlockFOV() end
                end
            end
        end
    end)
end

-- 3. WALLHACK / CHAMS (Кэширование мешей, консоль включается только один раз)
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

local function GetAllSkeletalMeshes(enemy)
    local meshes = {}
    if IsValid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
    pcall(function()
        local SkeletalMeshClass = import("SkeletalMeshComponent")
        if SkeletalMeshClass and type(enemy.GetComponentsByClass) == "function" then
            local childs = enemy:GetComponentsByClass(SkeletalMeshClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for i = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(i-1) or childs[i]
                    if IsValid(comp) and comp ~= enemy.Mesh then
                        table.insert(meshes, comp)
                    end
                end
            end
        end
    end)
    return meshes
end

local function ApplyWallhack(enemy, glow)
    local LinearColorClass = import("LinearColor") or FLinearColor
    local glowVal = glow or 3.0
    local visColor = LinearColorClass(0.0 * glowVal, 1.0 * glowVal, 0.2 * glowVal, 1.0)
    local occColor = LinearColorClass(1.0 * glowVal, 0.1 * glowVal, 0.2 * glowVal, 1.0)

    local meshes = GetAllSkeletalMeshes(enemy)
    for _, mesh in ipairs(meshes) do
        if IsValid(mesh) then
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
                    mesh:OverrideIdeaOutlineThickness(15)
                    mesh:SetIdeaOverrideOutlineAndOcclusion(true)
                end
            end)
        end
    end
end

local function UndoWallhack(enemy)
    local meshes = GetAllSkeletalMeshes(enemy)
    for _, mesh in ipairs(meshes) do
        if IsValid(mesh) then
            pcall(function()
                if type(mesh.SetDrawDyeing) == "function" then
                    mesh:SetDrawDyeing(false)
                    mesh:SetDrawHighlight(false)
                    mesh:SetDrawIdeaOutline(false)
                end
            end)
        end
    end
end

local _wallhackApplied = {}
local _prevWallhackState = nil
local _prevWallhackGlow = nil

local function UpdateWallhack(localPlayer)
    pcall(function()
        if not IsValid(localPlayer) then return end
        local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if not okData or not GameplayData then return end

        local allCharacters = {}
        if GameplayData.GetAllPlayerCharacters then
            allCharacters = GameplayData.GetAllPlayerCharacters()
        elseif GameplayData.GameCharacters then
            for _, c in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, c) end
        end

        local glowChanged = (_prevWallhackGlow ~= Config.WallhackGlow)
        _prevWallhackGlow = Config.WallhackGlow

        if Config.Wallhack then
            if not _prevWallhackState then
                InitWallhackConsole()
                _prevWallhackState = true
            end

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
                    if IsValid(enemy) and enemy ~= localPlayer then
                        UndoWallhack(enemy)
                    end
                end
                _wallhackApplied = {}
            end
        end
    end)
end

-- ==============================================================================
-- ESP SYSTEM (SPAЩЕНО С pasta.lua)
-- ==============================================================================

-- Native ESP инициализация
_G.FufuModState = _G.FufuModState or {
    NativeESPReady = false,
    TrackedMarks = {},
    EnemyMarks = {},
    CustomTextData = AimConfig,
}

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
        if InGameMarkTools and InGameMarkTools.HideMapMark then
            InGameMarkTools.HideMapMark(mark)
        end
        if InGameMarkTools and InGameMarkTools.RemoveMapMark then
            InGameMarkTools.RemoveMapMark(mark)
        end
    end)
    _G.FufuModState.TrackedMarks[mark] = nil
end

local function GetSafeEnemyKey(enemy)
    if IsValid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

local function CheckIsAI(pawn, markData)
    if markData.AK_IS_BOT ~= nil then return markData.AK_IS_BOT, true end

    local isAI = false
    local hasChecked = false
    pcall(function()
        if pawn.bIsAI == true or pawn.IsAI == true then isAI = true; hasChecked = true end
        if type(pawn.IsBot) == "function" and pawn:IsBot() then isAI = true; hasChecked = true end

        local pState = pawn.PlayerState or (type(pawn.GetPlayerState) == "function" and pawn:GetPlayerState())
        if IsValid(pState) then
            hasChecked = true
            if pState.bIsABot == true or pState.bIsBot == true then isAI = true end
            if type(pState.IsBot) == "function" and pState:IsBot() then isAI = true end
        end

        if not isAI then
            local name = pawn.PlayerName or (type(pawn.GetPlayerName) == "function" and pawn:GetPlayerName()) or ""
            if name ~= "" and (name:find("Cobra") or name:find("Target") or name:find("bot_") or name:find("b_")) then
                isAI = true
                hasChecked = true
            end
        end
    end)
    if hasChecked then markData.AK_IS_BOT = isAI end
    return isAI, hasChecked
end

local COLOR_MAP = {
    [1] = {R=255, G=0,   B=0},
    [2] = {R=255, G=255, B=255},
    [3] = {R=255, G=255, B=0},
    [4] = {R=0,   G=255, B=0},
    [5] = {R=0,   G=255, B=255},
    [6] = {R=0,   G=0,   B=255},
    [7] = {R=255, G=0,   B=255}
}

local function GetAppliedColor(colorIdx, brightness)
    local base = COLOR_MAP[colorIdx] or COLOR_MAP[4]
    local b = brightness or Config.ColorConfig_Brightness or 25
    return {
        R = math.min(255, (base.R or 0) * b / 25),
        G = math.min(255, (base.G or 0) * b / 25),
        B = math.min(255, (base.B or 0) * b / 25),
        A = 255
    }
end

local function GetColorBy7(idx)
    local COLOR_PALETTE_7 = {
        [1] = {R=255, G=0,   B=0, A=255},
        [2] = {R=255, G=255, B=255, A=255},
        [3] = {R=255, G=255, B=0, A=255},
        [4] = {R=0,   G=255, B=0, A=255},
        [5] = {R=0,   G=255, B=255, A=255},
        [6] = {R=0,   G=0,   B=255, A=255},
        [7] = {R=255, G=0,   B=255, A=255},
    }
    if not idx or idx < 1 or idx > 7 then idx = 4 end
    return COLOR_PALETTE_7[idx] or {R=0, G=255, B=0, A=255}
end

local function InitializeNativeESP()
    if _G.FufuModState.NativeESPReady then return end
    pcall(function()
        local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local currentMarkCfg = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
        local function ApplyCfg(cfg)
            if not cfg then return end
            if cfg[1006] then
                cfg[1006].bBindBlocked = true;
                cfg[1006].bBindOutScreen = true;
                cfg[1006].MaxWidgetNum = 99
                cfg[1006].MaxShowDistance = 6000000;
                cfg[1006].bScaleByDistance = false
                cfg[1006].BindSocketName = "root";
                cfg[1006].bUseLuaWorldSocketName = true
                cfg[1006].WorldPositionOffset = FVector(0, 0, -30)
            end
            cfg[8888] = {
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99,
                MaxShowDistance = 6000000,
                bBindOutScreen = true,
                bBindBlocked = true,
                bIsBindingActor = true,
                BindSocketName = "head",
                bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0, 0, 30),
                bNeedPreLoad = true,
                Priority = 2
            }
            cfg[9999] = {
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99,
                MaxShowDistance = 6000000,
                bBindOutScreen = true,
                bBindBlocked = true,
                bIsBindingActor = true,
                BindSocketName = "head",
                bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0, 0, 50),
                bNeedPreLoad = true,
                Priority = 2
            }
        end
        ApplyCfg(currentMarkCfg)
        for k, cfg in pairs(package.loaded) do
            if type(k) == "string" and string.find(k, "ScreenMarkConfig") and type(cfg) == "table" then
                ApplyCfg(cfg)
            end
        end
    end)
    _G.FufuModState.NativeESPReady = true
end

-- ==============================================================================
-- AIMBOT SYSTEM (SPAЩЕНО С pasta.lua)
-- ==============================================================================

_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = require("GameLua.GameCore.Data.GameplayData").GetPlayerCharacter()

    if not IsValid(player) then
        return result
    end

    local allCharacters = {}
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    if GameplayData.GetAllPlayerCharacters then
        allCharacters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
    end

    local myTeam = player:GetTeamID()

    for _, actor in pairs(allCharacters) do
        if IsValid(actor) and actor ~= player and actor.GetTeamID and actor:IsAlive() then
            if actor:GetTeamID() ~= myTeam then
                local dist = player:GetDistanceTo(actor)
                if dist <= radius then
                    table.insert(result, actor)
                end
            end
        end
    end
    return result
end

_G.AimTouch = function()
    pcall(function()
        if not Config.AimTouchEnable then return end

        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local player = GameplayData.GetPlayerCharacter()
        if not IsValid(player) then return end

        local pc = player:GetPlayerControllerSafety()
        if not IsValid(pc) then return end

        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS

        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then
            weapon = player:GetCurrentShootWeapon()
        end

        local isShotgun = false
        local isSniper = false
        local isMortar = false
        local currentAmmo = 1

        if IsValid(weapon) then
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""

            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then
                isShotgun = true
            end

            if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                isSniper = true
            end

            if wName:lower():find("mortar") or wName:lower():find("cối") then
                isMortar = true
            end

            if type(weapon.GetCurrentAmmo) == "function" then
                currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then
                currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then
                currentAmmo = weapon.CurrentAmmo
            end
        end

        if _G.FufuModState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if IsValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if IsValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.FufuModState.IsAutoFiring = false
        end

        if isShotgun and currentAmmo <= 0 then
            return
        end

        local cond = 2
        local prioMode = 1
        local boneIdx = 1
        local speedVal = 50
        local fovVal = 30
        local maxDistMeters = 50
        local useVisCheck = false
        local igKnock = false
        local igBot = false

        local predVal = 0
        local recoilCompVal = 0

        if isMortar and Config.AimTouchMortar then
            local isPlaced = false
            pcall(function()
                if weapon and weapon.MortarState == 2 then isPlaced = true end
            end)
            if not isPlaced then return end

            cond = 2
            prioMode = 1
            boneIdx = 4
            speedVal = 100
            fovVal = AimConfig.AimTouchMortarFOV or 360
            maxDistMeters = 2000
            useVisCheck = false
            igKnock = false
            igBot = false
            predVal = AimConfig.AimTouchMortarPred or 0

        elseif isShotgun and Config.AimTouchSG then
            cond = AimConfig.AimTouchSGCond or 1
            if Config.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = AimConfig.AimTouchSGPrio or 1
            boneIdx = AimConfig.AimTouchSGBone or 2
            speedVal = AimConfig.AimTouchSGSpeed or 80
            fovVal = AimConfig.AimTouchSGFOV or 40
            maxDistMeters = AimConfig.AimTouchSGDist or 30
            useVisCheck = Config.AimTouchSGVisCheck
            igKnock = Config.AimTouchSGIgKnock
            igBot = Config.AimTouchSGIgBot

        elseif isADS then
            if isSniper and Config.AimTouchScopeSniper then
                cond = AimConfig.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode = AimConfig.AimTouchSniperPrio or 1
                boneIdx = AimConfig.AimTouchSniperBone or 1
                speedVal = AimConfig.AimTouchSniperSpeed or 30
                fovVal = AimConfig.AimTouchSniperFOV or 20
                maxDistMeters = AimConfig.AimTouchSniperDist or 400
                useVisCheck = Config.AimTouchSniperVisCheck
                igKnock = Config.AimTouchSniperIgKnock
                igBot = Config.AimTouchSniperIgBot
                predVal = AimConfig.AimTouchSniperPred or 0
            elseif Config.AimTouchScopeAll then
                cond = AimConfig.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = AimConfig.AimTouchScopePrio or 1
                boneIdx = AimConfig.AimTouchScopeBone or 2
                speedVal = AimConfig.AimTouchScopeSpeed or 40
                fovVal = AimConfig.AimTouchScopeFOV or 20
                maxDistMeters = AimConfig.AimTouchScopeDist or 300
                useVisCheck = Config.AimTouchScopeVisCheck
                igKnock = Config.AimTouchScopeIgKnock
                igBot = Config.AimTouchScopeIgBot
                predVal = AimConfig.AimTouchScopePred or 0
                recoilCompVal = AimConfig.AimTouchScopeRecoil or 0
            else
                return
            end
        else
            if not Config.AimTouchHipfire then return end
            cond = AimConfig.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end
            prioMode = AimConfig.AimTouchHipPrio or 1
            boneIdx = AimConfig.AimTouchHipBone or 1
            speedVal = AimConfig.AimTouchHipSpeed or 50
            fovVal = AimConfig.AimTouchHipFOV or 30
            maxDistMeters = AimConfig.AimTouchHipDist or 250
            useVisCheck = Config.AimTouchHipVisCheck
            igKnock = Config.AimTouchHipIgKnock
            igBot = Config.AimTouchHipIgBot
        end

        local currentMaxDist = maxDistMeters * 100

        local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
        if not enemies or #enemies == 0 then return end

        local FVector2D = import("Vector2D")
        local UGameplayStatics = import("GameplayStatics")
        local KismetMathLibrary = import("KismetMathLibrary")

        local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
        if not IsValid(camManager) then return end

        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end

        local ui_util = require("client.common.ui_util")
        if not ui_util then return end

        local viewportSize = ui_util.GetViewportSize()
        if not viewportSize then return end

        local centerX = viewportSize.X * 0.5
        local centerY = viewportSize.Y * 0.5

        local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)

        local bestTarget = nil
        local bestScore = 99999999

        local selBoneName = "head"
        if boneIdx == 1 then selBoneName = "head"
        elseif boneIdx == 2 then selBoneName = "spine_03"
        elseif boneIdx == 3 then selBoneName = "spine_01"
        elseif boneIdx == 4 then selBoneName = "pelvis" end

        for i, target in ipairs(enemies) do
            if not IsValid(target) then goto continue end

            pcall(function()
                if IsValid(target.Mesh) then
                    target.Mesh.MeshComponentUpdateFlag = 0
                end
            end)

            if igKnock and target.HealthStatus == 1 then goto continue end

            if igBot then
                local tIsBot = false
                if target.bIsAI == true or target.IsAI == true then tIsBot = true end
                local pState = target.PlayerState
                if IsValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
                if tIsBot then goto continue end
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
                if _G.AimTouchVisCache[tId].hidden then goto continue end
            end

            local tPos = target:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.GetSocketLocation) == "function" then
                    tPos = target:GetSocketLocation(selBoneName)
                end
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
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then goto continue end

            local screen = FVector2D()
            local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
            if not success or screen.X <= 0 or screen.Y <= 0 then goto continue end

            local dx = screen.X - centerX
            local dy = screen.Y - centerY
            local distScreen = math.sqrt(dx*dx + dy*dy)

            if distScreen > FOV_RADIUS then goto continue end

            local currentScore = distScreen
            if prioMode == 2 then currentScore = player:GetDistanceTo(target)
            elseif prioMode == 3 then currentScore = target.Health or 100
            elseif prioMode == 4 then
                local hp = target.Health or 100
                local maxhp = target.HealthMax or 100
                if maxhp <= 0 then maxhp = 100 end
                currentScore = hp / maxhp
            end

            if currentScore < bestScore then
                bestScore = currentScore
                bestTarget = target
            end

            ::continue::
        end

        if not IsValid(bestTarget) then return end

        local finalBonePos = bestTarget:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.GetSocketLocation) == "function" then
                finalBonePos = bestTarget:GetSocketLocation(selBoneName)
            end
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
                if type(bestTarget.GetVelocity) == "function" then
                    tVelocity = bestTarget:GetVelocity()
                end

                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local distToEnemy = player:GetDistanceTo(bestTarget) / 100.0
                    local ToF = (distToEnemy / 800.0) * (predVal / 50.0)
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * ToF)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * ToF)
                end
            end)
        end

        local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
        if not rot then return end

        local currentRot = pc:GetControlRotation()
        if not currentRot then return end

        local deltaYaw = rot.Yaw - currentRot.Yaw
        local deltaPitch = rot.Pitch - currentRot.Pitch

        if isADS then
            local camRot = nil
            if type(camManager.GetCameraRotation) == "function" then
                camRot = camManager:GetCameraRotation()
            end
            if camRot then
                deltaYaw = deltaYaw - (camRot.Yaw - currentRot.Yaw)
                deltaPitch = deltaPitch - (camRot.Pitch - currentRot.Pitch)
            end
        end

        if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
        if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
        if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
        if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end

        local smoothFactor = 0.0
        if speedVal >= 100 then
            smoothFactor = 1.0
        else
            smoothFactor = (speedVal / 100.0) * 0.3
            if smoothFactor < 0.01 then smoothFactor = 0.01 end
        end

        local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
        local finalYaw = currentRot.Yaw + (deltaYaw * smoothFactor)

        if recoilCompVal > 0 and isFiring then
            local pullDownForce = (recoilCompVal / 50.0) * 1.5
            finalPitch = finalPitch - pullDownForce
        end

        local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }
        pc:SetControlRotation(finalRot, "AimTouch")

        if isShotgun and Config.AimTouchSGAutoFire then
            pcall(function()
                local distToTarget = player:GetDistanceTo(bestTarget) / 100
                if distToTarget <= maxDistMeters then
                    player.bIsWeaponFiring = true
                    if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(true) end
                    if IsValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(true) end
                    local wepMgr = player.WeaponManagerComponent
                    if IsValid(wepMgr) then wepMgr.bIsWeaponFiring = true end

                    local currentWep = player:GetCurrentWeapon()
                    if IsValid(currentWep) and type(currentWep.StartFire) == "function" then
                        currentWep:StartFire()
                    end
                    _G.FufuModState.IsAutoFiring = true
                end
            end)
        end

    end)
end

-- ==============================================================================
-- 3. ХЕЛПЕРЫ ДЛЯ UMG ВИДЖЕТОВ
-- ==============================================================================
local function NewObject(path, parent)
    local obj = nil
    pcall(function()
        if CGame and CGame.NewObjectFromPath then
            obj = CGame:NewObjectFromPath(path, parent)
        end
    end)
    return obj
end

local function Layer(parent, x, y, w, h, color, zOrder)
    local b = NewObject("/Script/UMG.Border", parent)
    if IsValid(b) then
        pcall(function() b:SetBrushColor(color) end)
        pcall(function() b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        local slot = parent:AddChildToCanvas(b)
        if slot then
            slot:SetAutoSize(false)
            slot:SetPosition(FVector2D(x, y))
            slot:SetSize(FVector2D(w, h))
            slot:SetZOrder(zOrder or 0)
        end
    end
    return b
end

local function Text(parent, text, x, y, fontSize, color, zOrder, alignX, alignY)
    local tb = NewObject("/Script/UMG.TextBlock", parent)
    if IsValid(tb) then
        pcall(function()
            tb:SetText(tostring(text or ""))
            tb:SetFont({ Size = fontSize or 12 })
            tb:SetColorAndOpacity(color or Colors.text_white)
            tb:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local slot = parent:AddChildToCanvas(tb)
        if slot then
            slot:SetAutoSize(true)
            slot:SetPosition(FVector2D(x, y))
            slot:SetAlignment(FVector2D(alignX or 0, alignY or 0))
            slot:SetZOrder(zOrder or 1)
        end
    end
    return tb
end

local function MakeBtn(parent, x, y, w, h, zOrder, onClick)
    local btn = NewObject("/Script/UMG.Button", parent)
    if IsValid(btn) then
        pcall(function() btn:SetColorAndOpacity(Colors.transparent) end)
        pcall(function() btn:SetBackgroundColor(Colors.transparent) end)
        pcall(function() btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible) end)
        local slot = parent:AddChildToCanvas(btn)
        if slot then
            slot:SetAutoSize(false)
            slot:SetPosition(FVector2D(x, y))
            slot:SetSize(FVector2D(w, h))
            slot:SetZOrder(zOrder or 100)
        end
        if onClick then
            pcall(function()
                if btn.OnClicked then
                    btn.OnClicked:Add(function() pcall(onClick) end)
                end
            end)
        end
    end
    return btn
end

local function Notify(msg)
    pcall(function()
        local sh = import("ScriptHelperClient")
        if sh and sh.AddOnScreenDebugMessage then
            sh.AddOnScreenDebugMessage("[SodaLite] " .. tostring(msg), -1, 2.5, {R=0.2, G=0.6, B=1.0, A=1}, {X=1.2, Y=1.2})
        end
    end)
    print("[SodaLite] " .. tostring(msg))
end

-- ==============================================================================
-- 4. UMG ВИДЖЕТЫ: ЧЕКБОКС, СЛАЙДЕР, СВИТЧЕР
-- ==============================================================================
local function DrawCheckbox(parent, x, y, w, label, configKey, configTable)
    local h = ROW_H
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y + h - 1, w, 1, FLinearColor(0.2, 0.25, 0.35, 0.4), 11)

    Text(parent, label, x + 16, y + h * 0.5, 12, Colors.text_white, 15, 0.0, 0.5)

    local tbl = configTable or Config
    local toggleW, toggleH = 46, 22
    local toggleX = x + w - toggleW - 14
    local toggleY = y + (h - toggleH) * 0.5

    local track = Layer(parent, toggleX, toggleY, toggleW, toggleH,
        tbl[configKey] and Colors.toggle_on or Colors.toggle_off, 12)

    local knobSize = 18
    local knobOffset = tbl[configKey] and (toggleW - knobSize - 2) or 2
    local knob = Layer(parent, toggleX + knobOffset, toggleY + 2, knobSize, knobSize, Colors.toggle_knob, 14)

    MakeBtn(parent, x, y, w, h, 20, function()
        tbl[configKey] = not tbl[configKey]
        local isEnabled = tbl[configKey]

        if IsValid(track) then
            track:SetBrushColor(isEnabled and Colors.toggle_on or Colors.toggle_off)
        end
        if IsValid(knob) then
            local newKnobX = toggleX + (isEnabled and (toggleW - knobSize - 2) or 2)
            if knob.Slot then knob.Slot:SetPosition(FVector2D(newKnobX, toggleY + 2)) end
        end

        Notify(label .. ": " .. (isEnabled and "ON" or "OFF"))
    end)
end

local function DrawSlider(parent, x, y, w, label, configKey, minVal, maxVal, configTable)
    local h = ROW_H
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y + h - 1, w, 1, FLinearColor(0.2, 0.25, 0.35, 0.4), 11)

    Text(parent, label, x + 16, y + h * 0.5, 12, Colors.text_white, 15, 0.0, 0.5)

    local tbl = configTable or Config
    local valText = Text(parent, tostring(tbl[configKey]), x + w - 120, y + h * 0.5, 12, Colors.accent_blue, 15, 1.0, 0.5)

    local btnW = 28
    local btnMinusX = x + w - 85
    local btnPlusX  = x + w - 40
    local btnY      = y + (h - 26) * 0.5

    Layer(parent, btnMinusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "-", btnMinusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnMinusX, btnY, btnW, 26, 20, function()
        if tbl[configKey] > minVal then
            tbl[configKey] = tbl[configKey] - 1
            if IsValid(valText) then valText:SetText(tostring(tbl[configKey])) end
        end
    end)

    Layer(parent, btnPlusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "+", btnPlusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnPlusX, btnY, btnW, 26, 20, function()
        if tbl[configKey] < maxVal then
            tbl[configKey] = tbl[configKey] + 1
            if IsValid(valText) then valText:SetText(tostring(tbl[configKey])) end
        end
    end)
end

local function DrawSwitcher(parent, x, y, w, label, configKey, options, configTable)
    local h = ROW_H
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y + h - 1, w, 1, FLinearColor(0.2, 0.25, 0.35, 0.4), 11)

    Text(parent, label, x + 16, y + h * 0.5, 11, Colors.text_white, 15, 0.0, 0.5)

    local tbl = configTable or Config
    local currentVal = tbl[configKey] or 1
    local currentText = options[currentVal] or tostring(currentVal)

    local btnW = 50
    local btnPrevX = x + w - btnW * 2 - 10
    local btnNextX = x + w - btnW - 5
    local btnY = y + (h - 26) * 0.5

    local valDisplay = Text(parent, currentText, x + w - btnW * 2 - 10 - 70, y + h * 0.5, 11, Colors.accent_blue, 15, 1.0, 0.5)

    Layer(parent, btnPrevX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "<", btnPrevX + btnW * 0.5, btnY + 13, 12, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnPrevX, btnY, btnW, 26, 20, function()
        local newVal = currentVal - 1
        if newVal < 1 then newVal = #options end
        tbl[configKey] = newVal
        if IsValid(valDisplay) then valDisplay:SetText(options[newVal] or tostring(newVal)) end
        currentVal = newVal
    end)

    Layer(parent, btnNextX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, ">", btnNextX + btnW * 0.5, btnY + 13, 12, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnNextX, btnY, btnW, 26, 20, function()
        local newVal = currentVal + 1
        if newVal > #options then newVal = 1 end
        tbl[configKey] = newVal
        if IsValid(valDisplay) then valDisplay:SetText(options[newVal] or tostring(newVal)) end
        currentVal = newVal
    end)
end

local function DrawColorSwitcher(parent, x, y, w, label, configKey, configTable)
    local colorNames = {"Red","White","Yellow","Green","Cyan","Blue","Purple"}
    DrawSwitcher(parent, x, y, w, label, configKey, colorNames, configTable)
end

local function DrawSectionTitle(parent, x, y, w, title)
    local h = 30
    Layer(parent, x, y, w, h, Colors.bg_header, 10)
    Layer(parent, x, y + h - 1, w, 1, Colors.border, 11)
    Text(parent, title, x + 16, y + h * 0.5, 12, Colors.accent_blue, 15, 0.0, 0.5)
end

-- ==============================================================================
-- 5. ОТРИСОВКА МЕНЮ SODALITE
-- ==============================================================================

local contentY = 0
local maxContentHeight = 0

local function RenderESP()
    local startY = 10
    local colW = MENU_W - 32
    local y = startY

    -- ESP Visual
    DrawSectionTitle(contentContainer, 16, y, colW, "ESP VISUAL")
    y = y + 34

    DrawCheckbox(contentContainer, 16, y, colW, "ESP AUTO (Normal ESP)", "EspVip"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "ESP METER (Jarak)", "EspDistance"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "HEALTH V1", "EspVipPro"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "ESP MARK", "EspRadar"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "ESP BOX FRAME", "Esp5"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "ESP HEAD", "Esp6"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "ESP HEALTH V2", "Esp8"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "ESP LINE ANTENA", "EspAntenna"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "ESP NAME", "EspName"); y = y + 44

    -- ESP Throwable
    DrawSectionTitle(contentContainer, 16, y, colW, "ESP THROWABLE"); y = y + 34
    DrawCheckbox(contentContainer, 16, y, colW, "Enable Throwable ESP", "ThrowableEnabled"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Grenade", "ThrowableGrenade"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Grenade", "ThrowableColor_Grenade"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Smoke", "ThrowableSmoke"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Smoke", "ThrowableColor_Smoke"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Molotov", "ThrowableMolotov"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Molotov", "ThrowableColor_Molotov"); y = y + 44

    -- ESP Vehicle
    DrawSectionTitle(contentContainer, 16, y, colW, "ESP VEHICLE"); y = y + 34
    DrawCheckbox(contentContainer, 16, y, colW, "Enable Vehicle ESP", "VehicleEnabled"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Dacia", "VehicleShowDacia"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Dacia", "VehicleColor_Dacia"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   UAZ", "VehicleShowUAZ"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna UAZ", "VehicleColor_UAZ"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Buggy", "VehicleShowBuggy"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Buggy", "VehicleColor_Buggy"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Coupe", "VehicleShowCoupe"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Coupe", "VehicleColor_Coupe"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Mirado", "VehicleShowMirado"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Mirado", "VehicleColor_Mirado"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Motor", "VehicleShowMotor"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Motor", "VehicleColor_Motor"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Lainnya", "VehicleShowOther"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Lainnya", "VehicleColor_Other"); y = y + 44

    -- ESP Loot
    DrawSectionTitle(contentContainer, 16, y, colW, "ESP LOOT"); y = y + 34
    DrawCheckbox(contentContainer, 16, y, colW, "Enable Loot ESP", "EspLoot"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   M416", "LootShowM416"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna M416", "LootColor_M416"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   AUG", "LootShowAUG"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna AUG", "LootColor_AUG"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   AKM", "LootShowAKM"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna AKM", "LootColor_AKM"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   M24", "LootShowM24"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna M24", "LootColor_M24"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   UMP45", "LootShowUMP"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna UMP", "LootColor_UMP"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   DBS", "LootShowDBS"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna DBS", "LootColor_DBS"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   S12K", "LootShowS12K"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna S12K", "LootColor_S12K"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Vest Lv3", "LootShowVest3"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Vest Lv3", "LootColor_Vest3"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Helm Lv3", "LootShowHelmet3"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Helm Lv3", "LootColor_Helmet3"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Bag Lv3", "LootShowBag3"); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   Warna Bag Lv3", "LootColor_Bag3"); y = y + 44

    -- ESP Static
    DrawSectionTitle(contentContainer, 16, y, colW, "ESP STATIC"); y = y + 34
    DrawCheckbox(contentContainer, 16, y, colW, "Enable ESP Static", "EspStatic"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Enemy Count", "EspEnemyCount"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Weapon & Status", "EspWeaponStatus"); y = y + 44

    maxContentHeight = y + 20
end

local function RenderAimBot()
    local startY = 10
    local colW = MENU_W - 32
    local y = startY

    -- Aimbot Main
    DrawSectionTitle(contentContainer, 16, y, colW, "AIMBOT SETTINGS"); y = y + 34
    DrawCheckbox(contentContainer, 16, y, colW, "Enable Aimbot (Royal & Custom)", "AimTouchEnable"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "Show FOV Circle", "EspFovCircle"); y = y + 44

    -- Hipfire
    DrawSectionTitle(contentContainer, 16, y, colW, "HIPFIRE AIMBOT"); y = y + 34
    DrawCheckbox(contentContainer, 16, y, colW, "Enable Hipfire Aimbot", "AimTouchHipfire"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Ignore Knocked", "AimTouchHipIgKnock"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Ignore Bots", "AimTouchHipIgBot"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Visibility Check", "AimTouchHipVisCheck"); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Priority", "AimTouchHipPrio", {"Center","Distance","HP","HP%"}, AimConfig); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Bone Target", "AimTouchHipBone", {"Head","Chest","Stomach","Pelvis"}, AimConfig); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Condition", "AimTouchHipCond", {"Aim when firing","Always aim"}, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Speed", "AimTouchHipSpeed", 1, 100, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   FOV Range", "AimTouchHipFOV", 1, 100, AimConfig); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   FOV Color", "AimTouchHipFOVColor", AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Distance (x5m)", "AimTouchHipDist", 1, 100, AimConfig); y = y + 44

    -- Shotgun
    DrawSectionTitle(contentContainer, 16, y, colW, "SHOTGUN AIMBOT"); y = y + 34
    DrawCheckbox(contentContainer, 16, y, colW, "Enable Shotgun Aimbot", "AimTouchSG"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Auto Fire", "AimTouchSGAutoFire"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Ignore Knocked", "AimTouchSGIgKnock"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Ignore Bots", "AimTouchSGIgBot"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Visibility Check", "AimTouchSGVisCheck"); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Priority", "AimTouchSGPrio", {"Center","Distance","HP","HP%"}, AimConfig); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Bone Target", "AimTouchSGBone", {"Head","Chest","Stomach","Pelvis"}, AimConfig); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Condition", "AimTouchSGCond", {"Aim when firing","Always aim"}, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Speed", "AimTouchSGSpeed", 1, 100, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   FOV Range", "AimTouchSGFOV", 1, 100, AimConfig); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   FOV Color", "AimTouchSGFOVColor", AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Distance (m)", "AimTouchSGDist", 1, 100, AimConfig); y = y + 44

    -- Scope All
    DrawSectionTitle(contentContainer, 16, y, colW, "SCOPED AIMBOT (ALL)"); y = y + 34
    DrawCheckbox(contentContainer, 16, y, colW, "Enable Scoped Aimbot", "AimTouchScopeAll"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Ignore Knocked", "AimTouchScopeIgKnock"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Ignore Bots", "AimTouchScopeIgBot"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Visibility Check", "AimTouchScopeVisCheck"); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Priority", "AimTouchScopePrio", {"Center","Distance","HP","HP%"}, AimConfig); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Bone Target", "AimTouchScopeBone", {"Head","Chest","Stomach","Pelvis"}, AimConfig); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Condition", "AimTouchScopeCond", {"Aim when firing","Always aim"}, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Speed", "AimTouchScopeSpeed", 1, 100, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   FOV Range", "AimTouchScopeFOV", 1, 100, AimConfig); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   FOV Color", "AimTouchScopeFOVColor", AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Distance (x5m)", "AimTouchScopeDist", 1, 100, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Prediction", "AimTouchScopePred", 0, 100, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Recoil Comp", "AimTouchScopeRecoil", 0, 50, AimConfig); y = y + 44

    -- Sniper
    DrawSectionTitle(contentContainer, 16, y, colW, "SNIPER AIMBOT"); y = y + 34
    DrawCheckbox(contentContainer, 16, y, colW, "Enable Sniper Aimbot", "AimTouchScopeSniper"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Ignore Knocked", "AimTouchSniperIgKnock"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Ignore Bots", "AimTouchSniperIgBot"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "   Visibility Check", "AimTouchSniperVisCheck"); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Priority", "AimTouchSniperPrio", {"Center","Distance","HP","HP%"}, AimConfig); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Bone Target", "AimTouchSniperBone", {"Head","Chest","Stomach","Pelvis"}, AimConfig); y = y + 44
    DrawSwitcher(contentContainer, 16, y, colW, "   Condition", "AimTouchSniperCond", {"Aim when firing","Open Scope Aim"}, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Speed", "AimTouchSniperSpeed", 1, 100, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   FOV Range", "AimTouchSniperFOV", 1, 100, AimConfig); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   FOV Color", "AimTouchSniperFOVColor", AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Distance (x5m)", "AimTouchSniperDist", 1, 100, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Prediction", "AimTouchSniperPred", 0, 100, AimConfig); y = y + 44

    -- Mortar
    DrawSectionTitle(contentContainer, 16, y, colW, "MORTAR AIMBOT"); y = y + 34
    DrawCheckbox(contentContainer, 16, y, colW, "Enable Mortar Aimbot", "AimTouchMortar"); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   Prediction", "AimTouchMortarPred", 0, 100, AimConfig); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   FOV Range", "AimTouchMortarFOV", 1, 360, AimConfig); y = y + 44
    DrawColorSwitcher(contentContainer, 16, y, colW, "   FOV Color", "AimTouchMortarFOVColor", AimConfig); y = y + 44

    maxContentHeight = y + 20
end

local function RenderVisuals()
    local startY = 10
    local colW = MENU_W - 32
    local y = startY

    DrawCheckbox(contentContainer, 16, y, colW, "Black Sky (Чёрное небо)", "BlackSky"); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "Wallhack (Chams / Сквозь стены)", "Wallhack"); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   > Яркость Wallhack Glow (1-10)", "WallhackGlow", 1, 10); y = y + 44
    DrawCheckbox(contentContainer, 16, y, colW, "IPad View (Отдаление камеры)", "IpadView"); y = y + 44
    DrawSlider(contentContainer, 16, y, colW, "   > Угол обзора FOV (90-140)", "IpadViewFOV", 90, 140); y = y + 44

    maxContentHeight = y + 20
end

local function RenderContent()
    if not IsValid(contentContainer) then return end
    contentContainer:ClearChildren()

    if currentTab == "VISUALS" then
        RenderVisuals()
    elseif currentTab == "ESP" then
        RenderESP()
    elseif currentTab == "AIMBOT" then
        RenderAimBot()
    end

    -- Apply scroll offset
    if IsValid(contentContainer) and contentContainer.Slot then
        contentContainer.Slot:SetPosition(FVector2D(0, -scrollOffset))
    end
end

local function BuildMenu(canvas)
    if IsValid(bgPanel) then
        bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        isMenuOpen = true
        return
    end

    bgPanel = NewObject("/Script/UMG.CanvasPanel", canvas)
    local bgSlot = canvas:AddChildToCanvas(bgPanel)
    bgSlot:SetPosition(FVector2D(menuPos.X, menuPos.Y))
    bgSlot:SetSize(FVector2D(MENU_W, MENU_H))
    bgSlot:SetZOrder(10000)

    Layer(bgPanel, -2, -2, MENU_W + 4, MENU_H + 4, Colors.border, 1)
    Layer(bgPanel, 0, 0, MENU_W, MENU_H, Colors.bg_main, 2)

    -- Шапка окна SodaLite
    local HEADER_H = 44
    Layer(bgPanel, 0, 0, MENU_W, HEADER_H, Colors.bg_header, 3)
    Layer(bgPanel, 0, HEADER_H - 1, MENU_W, 1, Colors.border, 4)
    Text(bgPanel, "SodaLite GLOBAL", 16, HEADER_H * 0.5, 14, Colors.text_white, 5, 0.0, 0.5)

    -- Кнопка закрытия [X]
    local closeX = MENU_W - 36
    Layer(bgPanel, closeX, 8, 28, 28, Colors.accent_red, 5)
    Text(bgPanel, "X", closeX + 14, 22, 12, Colors.text_white, 6, 0.5, 0.5)
    MakeBtn(bgPanel, closeX, 8, 28, 28, 50, function()
        bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        isMenuOpen = false
    end)

    -- Вкладки
    local tabY = HEADER_H + 8
    local tabW = 110
    local tabH = 32
    local tabSpacing = 6
    local tabs = {"VISUALS", "ESP", "AIMBOT"}
    local tabColors = {Colors.bg_row, Colors.bg_row, Colors.bg_row}

    for i, tabName in ipairs(tabs) do
        local tx = 16 + (i - 1) * (tabW + tabSpacing)
        Layer(bgPanel, tx, tabY, tabW, tabH, tabColors[i], 5)
        Text(bgPanel, tabName, tx + tabW * 0.5, tabY + tabH * 0.5, 11, Colors.text_white, 6, 0.5, 0.5)
        MakeBtn(bgPanel, tx, tabY, tabW, tabH, 20, function()
            currentTab = tabName
            scrollOffset = 0
            RenderContent()
        end)
    end

    -- Scroll buttons
    local scrollBtnW = 30
    local scrollBtnH = 30
    local scrollUpX = MENU_W - 40
    local scrollUpY = tabY + tabH + 10
    local scrollDownX = MENU_W - 40
    local scrollDownY = MENU_H - 50

    Layer(bgPanel, scrollUpX, scrollUpY, scrollBtnW, scrollBtnH, Colors.bg_row, 15)
    Text(bgPanel, "▲", scrollUpX + scrollBtnW * 0.5, scrollUpY + scrollBtnH * 0.5, 12, Colors.text_white, 16, 0.5, 0.5)
    MakeBtn(bgPanel, scrollUpX, scrollUpY, scrollBtnW, scrollBtnH, 25, function()
        scrollOffset = scrollOffset - scrollStep
        if scrollOffset < 0 then scrollOffset = 0 end
        RenderContent()
    end)

    Layer(bgPanel, scrollDownX, scrollDownY, scrollBtnW, scrollBtnH, Colors.bg_row, 15)
    Text(bgPanel, "▼", scrollDownX + scrollBtnW * 0.5, scrollDownY + scrollBtnH * 0.5, 12, Colors.text_white, 16, 0.5, 0.5)
    MakeBtn(bgPanel, scrollDownX, scrollDownY, scrollBtnW, scrollBtnH, 25, function()
        scrollOffset = scrollOffset + scrollStep
        local maxScroll = math.max(0, maxContentHeight - (MENU_H - (tabY + tabH + 10)))
        if scrollOffset > maxScroll then scrollOffset = maxScroll end
        RenderContent()
    end)

    contentContainer = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local cSlot = bgPanel:AddChildToCanvas(contentContainer)
    cSlot:SetPosition(FVector2D(0, tabY + tabH + 6))
    cSlot:SetSize(FVector2D(MENU_W - 50, MENU_H - (tabY + tabH + 6)))
    cSlot:SetZOrder(10)
    cSlot:SetClipping(1)

    RenderContent()
    isMenuOpen = true
end

local function ToggleMenu(canvas)
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        if IsValid(bgPanel) then
            bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        else
            BuildMenu(canvas)
        end
    else
        if IsValid(bgPanel) then
            bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
    end
end

-- ==============================================================================
-- 6. ПЛАВАЮЩАЯ КНОПКА SODALITE
-- ==============================================================================
local function CreateFloatButton(canvas)
    if floatItem and IsValid(floatItem.btn) then return end
    floatItem = {}

    local fX, fY, fW, fH = floatPos.X, floatPos.Y, FLOAT_W, FLOAT_H

    floatItem.shadow = Layer(canvas, fX + 2, fY + 3, fW, fH, Colors.shadow, 11898)
    floatItem.border = Layer(canvas, fX - 1, fY - 1, fW + 2, fH + 2, Colors.border, 11900)
    floatItem.bg     = Layer(canvas, fX, fY, fW, fH, Colors.bg_header, 11901)
    floatItem.text   = Text(canvas, "SodaLite", fX + fW * 0.5, fY + fH * 0.5, 11, Colors.accent_blue, 12001, 0.5, 0.5)

    floatItem.btn = MakeBtn(canvas, fX, fY, fW, fH, 12002, function()
        ToggleMenu(canvas)
    end)
end

-- ==============================================================================
-- 7. НЕПРЕРЫВНЫЙ ЦИКЛ БЕЗ ЗАВИСАНИЙ И ОТКЛЮЧЕНИЙ (AddTimerOnce RECURSIVE)
-- ==============================================================================
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

        -- 1. BlackSky
        UpdateBlackSky()

        -- 2. IpadView
        if IsValid(localPlayer) and IsValid(pc) then
            UpdateIpadView(localPlayer, pc)
        end

        -- 3. Wallhack
        if IsValid(localPlayer) then
            UpdateWallhack(localPlayer)
        end

        -- 4. ESP Native
        InitializeNativeESP()

        -- 5. AimBot
        if Config.AimTouchEnable then
            _G.AimTouch()
        end

        -- 6. ESP Loop (спащено с pasta.lua)
        pcall(function()
            if not IsValid(localPlayer) or not IsValid(pc) then return end

            local GameplayData = require("GameLua.GameCore.Data.GameplayData")
            local allCharacters = {}
            if GameplayData.GetAllPlayerCharacters then
                allCharacters = GameplayData.GetAllPlayerCharacters()
            elseif GameplayData.GameCharacters then
                for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
            end

            local Cached_MyHUD = pc and pc.MyHUD or nil

            -- ESP Visual loop (упрощенная версия)
            for _, enemy in pairs(allCharacters) do
                if IsValid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                    local eKey = GetSafeEnemyKey(enemy)
                    _G.FufuModState.EnemyMarks[eKey] = _G.FufuModState.EnemyMarks[eKey] or { enemy = enemy }
                    local markData = _G.FufuModState.EnemyMarks[eKey]

                    local bIsReallyDead = false
                    pcall(function()
                        if type(enemy.IsDead) == "function" then bIsReallyDead = enemy:IsDead()
                        elseif enemy.bIsDead ~= nil then bIsReallyDead = enemy.bIsDead
                        elseif enemy.bIsDeadFlag ~= nil then bIsReallyDead = enemy.bIsDeadFlag end
                        if enemy.HealthStatus ~= nil and enemy.HealthStatus == 2 then bIsReallyDead = true end
                    end)

                    if not bIsReallyDead then
                        local distM = 0
                        pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)

                        local currentHp, maxHp = 100, 100
                        pcall(function()
                            if enemy.Health then currentHp = enemy.Health elseif type(enemy.GetHealth) == "function" then currentHp = enemy:GetHealth() end
                            if enemy.HealthMax then maxHp = enemy.HealthMax elseif type(enemy.GetHealthMax) == "function" then maxHp = enemy:GetHealthMax() end
                        end)
                        if maxHp <= 0 then maxHp = 100 end
                        local hpRatio = currentHp / maxHp

                        if Config.EspVipPro and Cached_MyHUD then
                            pcall(function()
                                local hud = Cached_MyHUD
                                if not (IsValid(hud) and hud.AddDebugText) then return end
                                if distM > 400 then return end

                                local hp = enemy.Health or 100
                                local maxHp2 = enemy.HealthMax or 100
                                local isKnock = (hp <= 0 or enemy.HealthStatus == 1)
                                local hpPercent = isKnock and 0 or (hp / maxHp2)
                                local pctValue = math.floor(hpPercent * 100 + 0.5)

                                local pName = ""
                                if Config.EspName then
                                    pName = enemy.PlayerName or enemy.PlayerNamePublic or "Enemy"
                                end

                                local bIsVisible = false
                                if pc and type(pc.LineOfSightTo) == "function" then
                                    bIsVisible = pc:LineOfSightTo(enemy)
                                end

                                local visibleCol = GetAppliedColor(Config.ColorConfig_VisibleColor or 4, Config.ColorConfig_Brightness)
                                local invisibleCol = GetAppliedColor(Config.ColorConfig_InvisibleColor or 1, Config.ColorConfig_Brightness)

                                local textColor = {R=255, G=255, B=255, A=255}
                                if isKnock then
                                    textColor = {R=0, G=0, B=255, A=255}
                                else
                                    textColor = bIsVisible and visibleCol or invisibleCol
                                end

                                local prefix = bIsVisible and "▶" or "▶"
                                local label = ""
                                if isKnock then
                                    label = (pName ~= "" and string.format("%s [♿]", pName) or "♿")
                                else
                                    if pName ~= "" then
                                        label = string.format("%s %s %.0f%%", pName, prefix, pctValue)
                                    else
                                        label = string.format("%s %.0f%%", prefix, pctValue)
                                    end
                                end

                                hud:AddDebugText(label, enemy, 0.2, {X=0, Y=0, Z=120}, {X=0, Y=0, Z=120},
                                                 textColor, true, false, true, nil, 1.0, true)
                            end)
                        end

                        if Config.EspDistance and Cached_MyHUD then
                            pcall(function()
                                local hud = Cached_MyHUD
                                if not (IsValid(hud) and hud.AddDebugText) then return end
                                if distM > 400 then return end

                                local distMeters = math.floor(distM + 0.5)
                                local rangeColor = {R=255, G=255, B=255, A=255}

                                hud:AddDebugText(string.format("%.0fm", distMeters), enemy, 0.3,
                                                 {X=15, Y=15, Z=-15}, {X=15, Y=15, Z=-15},
                                                 rangeColor, true, false, true, nil, 0.9, true)
                            end)
                        end

                        if Config.EspVip then
                            if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                            if markData.distMark == nil then markData.distMark = SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy) end
                        else
                            if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                            if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                        end

                        if Config.Esp8 then
                            if markData.hpMark8 == nil then markData.hpMark8 = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                        else
                            if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                        end

                        if Config.EspRadar then
                            if not markData.radarMark or markData.radarMark == 0 then
                                markData.radarMark = SafeAddMark(8888, FVector(0,0,0), 0, "", 4, enemy)
                            end
                        else
                            if markData.radarMark and markData.radarMark ~= 0 then
                                SafeRemoveMark(markData.radarMark)
                                markData.radarMark = nil
                            end
                        end
                    else
                        if not markData.IsCleanedUp then
                            SafeRemoveMark(markData.radarMark)
                            markData.radarMark = nil
                            SafeRemoveMark(markData.hpMark)
                            markData.hpMark = nil
                            SafeRemoveMark(markData.hpMark8)
                            markData.hpMark8 = nil
                            SafeRemoveMark(markData.distMark)
                            markData.distMark = nil
                            markData.IsCleanedUp = true
                        end
                    end
                end
            end

            -- ESP Vehicle
            if Config.VehicleEnabled then
                pcall(function()
                    local MyHUD = Cached_MyHUD
                    if not IsValid(MyHUD) then return end
                    if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                    if not _G.CachedActorClass_ForVehicle then _G.CachedActorClass_ForVehicle = import("STExtraVehicleBase") end
                    if not _G.CachedVehicleArray then _G.CachedVehicleArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForVehicle) end
                    local ui_util = require("client.common.ui_util")
                    local gameInstance = ui_util and ui_util.GetGameInstance()
                    if gameInstance and _G.CachedGameplayStatics then
                        local curTime = os.clock()
                        if not _G.LastVehicleScanTime or (curTime - _G.LastVehicleScanTime) > 1.0 then
                            _G.LastVehicleScanTime = curTime
                            local allVehicles = _G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance, _G.CachedActorClass_ForVehicle, _G.CachedVehicleArray)
                            local activeVehicles = {}
                            if allVehicles then
                                for _, veh in pairs(allVehicles) do
                                    if IsValid(veh) and not veh.bHidden and not veh.bTearOff then
                                        local isPendingKill = false
                                        pcall(function() if type(veh.IsPendingKill) == "function" then isPendingKill = veh:IsPendingKill() end end)
                                        if not isPendingKill then
                                            local vehName = "Kendaraan"
                                            pcall(function()
                                                if type(veh.GetVehicleName) == "function" then vehName = veh:GetVehicleName()
                                                elseif veh.VehicleName then vehName = veh.VehicleName end
                                            end)
                                            local nameLower = string.lower(tostring(vehName) .. tostring(veh))
                                            local displayName = "Kendaraan"
                                            if string.find(nameLower, "uaz") then displayName = "UAZ"
                                            elseif string.find(nameLower, "dacia") then displayName = "Dacia"
                                            elseif string.find(nameLower, "buggy") then displayName = "Buggy"
                                            elseif string.find(nameLower, "mirado") then displayName = "Mirado"
                                            elseif string.find(nameLower, "bike") or string.find(nameLower, "motor") then displayName = "Motor"
                                            elseif string.find(nameLower, "scooter") then displayName = "Scooter"
                                            elseif string.find(nameLower, "coupe") then displayName = "Coupe RB"
                                            elseif string.find(nameLower, "brdm") then displayName = "BRDM"
                                            elseif string.find(nameLower, "boat") or string.find(nameLower, "aquarail") then displayName = "Perahu"
                                            elseif string.find(nameLower, "glider") then displayName = "Glider"
                                            else displayName = "Kendaraan" end
                                            table.insert(activeVehicles, {act = veh, name = displayName})
                                        end
                                    end
                                end
                            end
                            _G.CachedVehicles = activeVehicles
                        end

                        if _G.CachedVehicles then
                            for _, item in ipairs(_G.CachedVehicles) do
                                local veh = item.act
                                if IsValid(veh) and not veh.bHidden then
                                    local isPendingKill = false
                                    pcall(function() if type(veh.IsPendingKill) == "function" then isPendingKill = veh:IsPendingKill() end end)
                                    if not isPendingKill then
                                        local isShow = false
                                        local colorKey = "VehicleColor_Other"
                                        if item.name == "Dacia" then isShow = Config.VehicleShowDacia; colorKey = "VehicleColor_Dacia"
                                        elseif item.name == "UAZ" then isShow = Config.VehicleShowUAZ; colorKey = "VehicleColor_UAZ"
                                        elseif item.name == "Buggy" then isShow = Config.VehicleShowBuggy; colorKey = "VehicleColor_Buggy"
                                        elseif item.name == "Coupe RB" then isShow = Config.VehicleShowCoupe; colorKey = "VehicleColor_Coupe"
                                        elseif item.name == "Mirado" then isShow = Config.VehicleShowMirado; colorKey = "VehicleColor_Mirado"
                                        elseif item.name == "Motor" or item.name == "Scooter" then isShow = Config.VehicleShowMotor; colorKey = "VehicleColor_Motor"
                                        else isShow = Config.VehicleShowOther; colorKey = "VehicleColor_Other" end
                                        if isShow then
                                            local distM = 0
                                            pcall(function() distM = localPlayer:GetDistanceTo(veh) / 100 end)
                                            if distM > 0 and distM <= 300 then
                                                local hpStr = ""
                                                pcall(function()
                                                    local hp = veh.HP or (type(veh.GetHP) == "function" and veh:GetHP()) or 100
                                                    local maxHp = veh.HPMax or (type(veh.GetHPMax) == "function" and veh:GetHPMax()) or 100
                                                    if maxHp > 0 then hpStr = string.format(" [%d%%]", math.floor((hp/maxHp)*100)) end
                                                end)
                                                local text = string.format("%s%s [%dm]", item.name, hpStr, math.floor(distM))
                                                local vehColor = GetColorBy7(Config[colorKey] or 4)
                                                local dynamicScale = math.max(0.6, 1.1 - (distM / 500))
                                                MyHUD:AddDebugText(text, veh, 0.3, {X=0, Y=0, Z=50}, {X=0, Y=0, Z=50}, vehColor, true, false, true, nil, dynamicScale, true)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end

            -- ESP Throwable
            if Config.ThrowableEnabled then
                pcall(function()
                    local MyHUD = Cached_MyHUD
                    if not IsValid(MyHUD) then return end
                    if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                    if not _G.CachedActorClass_ForBomb then _G.CachedActorClass_ForBomb = import("Actor") end
                    if not _G.CachedProjArray then _G.CachedProjArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForBomb) end
                    local ui_util = require("client.common.ui_util")
                    local gameInstance = ui_util and ui_util.GetGameInstance()
                    if gameInstance and _G.CachedGameplayStatics then
                        local allActors = _G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance, _G.CachedActorClass_ForBomb, _G.CachedProjArray)
                        if allActors then
                            for _, actor in pairs(allActors) do
                                if IsValid(actor) and not actor.bHidden and not actor.bTearOff then
                                    local isPendingKill = false
                                    pcall(function() if type(actor.IsPendingKill) == "function" then isPendingKill = actor:IsPendingKill() end end)
                                    if not isPendingKill then
                                        local nameLower = string.lower(tostring(actor))
                                        local bType = 0
                                        if string.find(nameLower, "smoke") then bType = 2
                                        elseif string.find(nameLower, "burn") or string.find(nameLower, "molotov") then bType = 3
                                        elseif string.find(nameLower, "grenade") then bType = 1 end
                                        if bType > 0 then
                                            local distM = 0
                                            pcall(function() distM = localPlayer:GetDistanceTo(actor) / 100 end)
                                            if distM > 0 and distM <= 150 then
                                                local displayName = ""
                                                local colorIdx = 4
                                                if bType == 1 then
                                                    if not Config.ThrowableGrenade then goto continue end
                                                    displayName = "GRENADE"
                                                    colorIdx = Config.ThrowableColor_Grenade or 4
                                                elseif bType == 2 then
                                                    if not Config.ThrowableSmoke then goto continue end
                                                    displayName = "SMOKE"
                                                    colorIdx = Config.ThrowableColor_Smoke or 4
                                                elseif bType == 3 then
                                                    if not Config.ThrowableMolotov then goto continue end
                                                    displayName = "MOLOTOV"
                                                    colorIdx = Config.ThrowableColor_Molotov or 4
                                                end
                                                local color = GetColorBy7(colorIdx)
                                                local text = string.format("%s [%dm]", displayName, math.floor(distM))
                                                local dynamicScale = math.max(0.6, 1.1 - (distM / 150))
                                                MyHUD:AddDebugText(text, actor, 0.3, {X=0, Y=0, Z=25}, {X=0, Y=0, Z=25}, color, true, false, true, nil, dynamicScale, true)
                                            end
                                        end
                                    end
                                end
                                ::continue::
                            end
                        end
                    end
                end)
            end

            -- ESP Loot
            if Config.EspLoot then
                pcall(function()
                    local MyHUD = Cached_MyHUD
                    if not IsValid(MyHUD) then return end
                    if not _G.CachedGameplayStatics then _G.CachedGameplayStatics = import("GameplayStatics") end
                    if not _G.CachedActorClass_ForLoot then _G.CachedActorClass_ForLoot = import("Actor") end
                    if not _G.CachedLootArray then _G.CachedLootArray = slua.Array(UEnums.EPropertyClass.Object, _G.CachedActorClass_ForLoot) end
                    local ui_util = require("client.common.ui_util")
                    local gameInstance = ui_util and ui_util.GetGameInstance()
                    if gameInstance and _G.CachedGameplayStatics then
                        local allActors = _G.CachedGameplayStatics.GetAllActorsOfClass(gameInstance, _G.CachedActorClass_ForLoot, _G.CachedLootArray)
                        if allActors then
                            for _, actor in pairs(allActors) do
                                if IsValid(actor) and not actor.bHidden and not actor.bTearOff then
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

                                        local displayInfo = nil
                                        local matched = false

                                        local lootKeywords = {
                                            ["m416"] = {name = "M416", toggle = "LootShowM416", colorKey = "LootColor_M416"},
                                            ["aug"] = {name = "AUG", toggle = "LootShowAUG", colorKey = "LootColor_AUG"},
                                            ["akm"] = {name = "AKM", toggle = "LootShowAKM", colorKey = "LootColor_AKM"},
                                            ["m24"] = {name = "M24", toggle = "LootShowM24", colorKey = "LootColor_M24"},
                                            ["ump"] = {name = "UMP45", toggle = "LootShowUMP", colorKey = "LootColor_UMP"},
                                            ["dbs"] = {name = "DBS", toggle = "LootShowDBS", colorKey = "LootColor_DBS"},
                                            ["s12"] = {name = "S12K", toggle = "LootShowS12K", colorKey = "LootColor_S12K"},
                                        }

                                        for keyword, info in pairs(lootKeywords) do
                                            if string.find(lowerName, keyword, 1, true) then
                                                displayInfo = info
                                                matched = true
                                                break
                                            end
                                        end

                                        if matched and displayInfo then
                                            local distM = 0
                                            pcall(function() distM = localPlayer:GetDistanceTo(actor) / 100 end)
                                            if distM > 0 and distM <= 100 then
                                                local toggle = displayInfo.toggle
                                                if toggle and not Config[toggle] then goto continue end
                                                local colorIdx = Config[displayInfo.colorKey] or 4
                                                local color = GetColorBy7(colorIdx)
                                                local dynamicScale = math.max(0.5, 1.0 - (distM / 100))
                                                MyHUD:AddDebugText(
                                                    string.format("%s [%dm]", displayInfo.name, math.floor(distM)),
                                                    actor,
                                                    0.3,
                                                    {X=0, Y=0, Z=30},
                                                    {X=0, Y=0, Z=30},
                                                    color,
                                                    true, false, true, nil, dynamicScale, true
                                                )
                                            end
                                        end
                                    end
                                end
                                ::continue::
                            end
                        end
                    end
                end)
            end
        end)
    end)

    -- Рекурсивный перезапуск через 0.15 сек — никогда не убивается движком
    local okT, ticker = pcall(require, "common.time_ticker")
    if okT and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.15, CheatWorker)
    end
end

-- ==============================================================================
-- 8. ИНИЦИАЛИЗАЦИЯ
-- ==============================================================================
local function GetCanvas()
    if IsValid(parentCanvas) then return parentCanvas end
    parentCanvas = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local MainUI = InGameUITools and InGameUITools.GetMainControlBaseUI and InGameUITools.GetMainControlBaseUI()
        if MainUI and IsValid(MainUI) then
            if MainUI.CanvasPanel_0 and IsValid(MainUI.CanvasPanel_0) then
                parentCanvas = MainUI.CanvasPanel_0
            elseif MainUI.CanvasPanel_42 and IsValid(MainUI.CanvasPanel_42) then
                parentCanvas = MainUI.CanvasPanel_42
            end
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
        CheatWorker()
        Notify("SodaLite Loaded Successfully!")
    end
end

-- Цикл попытки инициализации (тоже через AddTimerOnce)
local function InitWatcher()
    if _initDone then return end
    pcall(TryInit)
    if not _initDone then
        local okT, ticker = pcall(require, "common.time_ticker")
        if okT and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(0.5, InitWatcher)
        end
    end
end
InitWatcher()

-- Жизненный цикл персонажа (BP_PlayerPawn)
function BRPlayerCharacterBase:ctor()
end

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