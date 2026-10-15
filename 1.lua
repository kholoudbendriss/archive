-- ==============================================================================
-- SodaLite GLOBAL + ESP + AIMBOT
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
-- 1. БАЗОВЫЕ ХЕЛПЕРЫ
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
local function IsValid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, obj); return ok and v
    end
    if Game and Game.IsValid then
        local ok, v = pcall(Game.IsValid, Game, obj); return ok and v
    end
    return true
end
local function Notify(msg)
    pcall(function()
        local sh = import("ScriptHelperClient")
        if sh and sh.AddOnScreenDebugMessage then
            sh.AddOnScreenDebugMessage("[SodaLite] " .. tostring(msg), -1, 2.0, {R=0.2, G=0.6, B=1.0, A=1}, {X=1.2, Y=1.2})
        end
    end)
    print("[SodaLite] " .. tostring(msg))
end

-- ==============================================================================
-- 2. ЦВЕТА И РАЗМЕРЫ
-- ==============================================================================
local Colors = {
    bg_main     = FLinearColor(0.07, 0.09, 0.14, 0.96),
    bg_header   = FLinearColor(0.04, 0.05, 0.08, 1.00),
    bg_row      = FLinearColor(0.11, 0.13, 0.18, 0.90),
    bg_header_row = FLinearColor(0.15, 0.20, 0.30, 0.95),
    border      = FLinearColor(0.18, 0.45, 0.95, 0.90),
    accent_blue = FLinearColor(0.20, 0.50, 1.00, 1.00),
    accent_red  = FLinearColor(0.92, 0.22, 0.25, 1.00),
    accent_gold = FLinearColor(1.00, 0.80, 0.20, 1.00),
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

local MENU_W, MENU_H = 620, 620
local ROW_H, HEADER_ROW_H = 34, 26
local menuPos  = { X = 280, Y = 80 }
local FLOAT_W, FLOAT_H = 110, 38
local floatPos = { X = 750, Y = 15 }

-- ==============================================================================
-- 3. КОНФИГ + СЛАЙДЕРЫ (все значения из pasta.lua)
-- ==============================================================================
local Config = {
    -- VISUALS (из оригинала)
    BlackSky = false, Wallhack = false, WallhackGlow = 3,
    IpadView = false, IpadViewFOV = 120,

    -- AIMBOT main
    AimTouchEnable = false, EspFovCircle = false,
    AimTouchHipfire = false, AimTouchHipIgKnock = false, AimTouchHipIgBot = false, AimTouchHipVisCheck = false,
    AimTouchSG = false, AimTouchSGAutoFire = false, AimTouchSGIgKnock = false, AimTouchSGIgBot = false, AimTouchSGVisCheck = false,
    AimTouchScopeAll = false, AimTouchScopeIgKnock = false, AimTouchScopeIgBot = false, AimTouchScopeVisCheck = false,
    AimTouchScopeSniper = false, AimTouchSniperIgKnock = false, AimTouchSniperIgBot = false, AimTouchSniperVisCheck = false,
    AimTouchMortar = false,
    Crosshair = false, LessShake = false,

    -- ESP enemy
    EspVip = false, EspDistance = false, EspVipPro = false,
    EspRadar = false, Esp5 = false, Esp6 = false, Esp8 = false,
    EspAntenna = false, EspName = false,

    -- ESP vehicle
    VehicleEnabled = false,
    VehicleShowDacia = false, VehicleShowUAZ = false, VehicleShowBuggy = false,
    VehicleShowCoupe = false, VehicleShowMirado = false, VehicleShowMotor = false, VehicleShowOther = false,
    VehicleColor_Dacia = 4, VehicleColor_UAZ = 4, VehicleColor_Buggy = 4,
    VehicleColor_Coupe = 4, VehicleColor_Mirado = 4, VehicleColor_Motor = 4, VehicleColor_Other = 4,

    -- ESP throwable
    ThrowableEnabled = false, ThrowableGrenade = false, ThrowableSmoke = false, ThrowableMolotov = false,
    ThrowableColor_Grenade = 4, ThrowableColor_Smoke = 4, ThrowableColor_Molotov = 4,
    ThrowableScanMode = 0,

    -- ESP loot
    EspLoot = false,
    LootShowM416 = false, LootShowAUG = false, LootShowAKM = false, LootShowM24 = false,
    LootShowUMP = false, LootShowDBS = false, LootShowS12K = false,
    LootShowVest3 = false, LootShowHelmet3 = false, LootShowBag3 = false,
    LootColor_M416 = 4, LootColor_AUG = 4, LootColor_AKM = 4, LootColor_M24 = 4,
    LootColor_UMP = 4, LootColor_DBS = 4, LootColor_S12K = 4,
    LootColor_Vest3 = 4, LootColor_Helmet3 = 4, LootColor_Bag3 = 4,
    LootScanMode = 0,

    -- ESP static
    EspStatic = false, EspEnemyCount = true, EspWeaponStatus = true,
}

local Sliders = {
    -- aimbot hipfire
    AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250,
    AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1, AimTouchHipFOVColor = 7,
    -- aimbot shotgun
    AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30,
    AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1, AimTouchSGFOVColor = 1,
    -- aimbot scope-all
    AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300,
    AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1,
    AimTouchScopePred = 0, AimTouchScopeRecoil = 0, AimTouchScopeFOVColor = 6,
    -- aimbot sniper
    AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400,
    AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2,
    AimTouchSniperPred = 0, AimTouchSniperFOVColor = 4,
    -- aimbot mortar
    AimTouchMortarPred = 0, AimTouchMortarFOV = 360, AimTouchMortarFOVColor = 5,
    -- ESP colors
    ColorVisible = 4, ColorInvisible = 1, ColorBrightness = 25, ColorGlow = 3.0,
}

-- Совместимость с портированным кодом из pasta.lua
_G.FufuModState = _G.FufuModState or {
    TrackedMarks = {}, EnemyMarks = {},
    LastMagicConfigHash = "OFF", MagicUpdateVersion = 1,
}
_G.FufuModState.CustomTextData = Sliders

-- ==============================================================================
-- 4. ESP / AIMBOT МОДУЛЬ ЛОГИКИ (порт из pasta.lua)
-- ==============================================================================
local _slua = rawget(_G, "slua")
local function Valid(obj)
    if not obj then return false end
    if _slua and _slua.isValid then
        local ok, v = pcall(_slua.isValid, obj); if not ok or not v then return false end
    end
    return true
end

-- палитра 7 цветов
local COLOR_MAP = {
    [1] = {R=255, G=0,   B=0},   [2] = {R=255, G=255, B=255},
    [3] = {R=255, G=255, B=0},   [4] = {R=0,   G=255, B=0},
    [5] = {R=0,   G=255, B=255}, [6] = {R=0,   G=0,   B=255},
    [7] = {R=255, G=0,   B=255}
}
local function GetColorBy7(idx)
    if not idx or idx < 1 or idx > 7 then idx = 4 end
    return COLOR_MAP[idx] or {R=0, G=255, B=0, A=255}
end
local function GetAppliedColor(colorIdx, brightness)
    local base = COLOR_MAP[colorIdx] or COLOR_MAP[4]
    local b = brightness or 25
    return {
        R = math.min(255, (base.R or 0) * b / 25),
        G = math.min(255, (base.G or 0) * b / 25),
        B = math.min(255, (base.B or 0) * b / 25),
        A = 255
    }
end

local C_GREEN  = {R=0, G=255, B=0, A=255}
local C_YELLOW = {R=255, G=255, B=0, A=255}

-- ============= Mark helpers =============
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

-- ============= Meshes =============
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

-- ============= Chams (V3 Engine из pasta.lua) =============
local function ApplyColorBodyNew(enemy, markData)
    pcall(function()
        if not _G.FufuModState.ConsoleNewWallReady then
            local KSL = import("KismetSystemLibrary")
            local world = slua and slua.getWorld and slua.getWorld()
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
        if Valid(weapon) and Valid(weapon.Mesh) then table.insert(meshes, weapon.Mesh) end

        local LinearColorClass = import("LinearColor") or FLinearColor
        local visibleRGB   = GetAppliedColor(Sliders.ColorVisible   or 4, Sliders.ColorBrightness or 25)
        local invisibleRGB = GetAppliedColor(Sliders.ColorInvisible or 1, Sliders.ColorBrightness or 25)
        local glow = Sliders.ColorGlow or 3.0

        local visColor = LinearColorClass and LinearColorClass(
            (visibleRGB.R/255) * glow, (visibleRGB.G/255) * glow, (visibleRGB.B/255) * glow, 1.0
        ) or visibleRGB
        local occColor = LinearColorClass and LinearColorClass(
            invisibleRGB.R/255, invisibleRGB.G/255, invisibleRGB.B/255, 1.0
        ) or invisibleRGB

        for _, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    if type(mesh.SetDrawDyeing) == "function" then
                        mesh:SetDrawDyeing(true); mesh:SetDrawDyeingMode(1)
                        mesh:SetVisibleDyeingColor(visColor); mesh:SetOccludedDyeingColor(occColor)
                        mesh:SetDyeingColorFadeDistance(99999.0); mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
                        mesh:SetDrawHighlight(true); mesh:OverrideHighlightColor(visColor); mesh:SetHighlightCanBeOccluded(false)
                        mesh:SetDrawIdeaOutline(true); mesh:SetIdeaOutlineNew(true); mesh:SetIdeaOutlineOcclusionHighlight(true)
                        mesh:OverrideIdeaOutlineColor(visColor); mesh:SetIdeaOutlineOcclusionColor(occColor)
                        mesh:OverrideIdeaOutlineThickness(20); mesh:SetIdeaOverrideOutlineAndOcclusion(true)
                        mesh:SetRenderCustomDepth(true); mesh:SetCustomDepthStencilValue(255)
                    end
                end)
            end
        end
        markData.ColorNewApplied = true
    end)
end
local function UndoColorBodyNew(enemy, markData)
    pcall(function()
        if markData.ColorNewApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            local weapon = nil
            pcall(function() weapon = enemy:GetCurrentWeapon() end)
            if Valid(weapon) and Valid(weapon.Mesh) then table.insert(meshes, weapon.Mesh) end
            for _, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function()
                        if type(mesh.SetDrawDyeing) == "function" then
                            mesh:SetDrawDyeing(false); mesh:SetDrawHighlight(false)
                            mesh:SetDrawIdeaOutline(false); mesh:SetRenderCustomDepth(false)
                        end
                    end)
                end
            end
            markData.ColorNewApplied = false
        end
    end)
end

-- ============= Native ESP Init =============
local function InitializeNativeESP()
    if _G.FufuModState.NativeESPReady then return end
    pcall(function()
        local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local currentMarkCfg = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
        local function ApplyCfg(cfg)
            if not cfg then return end
            if cfg[1006] then
                cfg[1006].bBindBlocked = true; cfg[1006].bBindOutScreen = true
                cfg[1006].MaxWidgetNum = 99; cfg[1006].MaxShowDistance = 6000000
                cfg[1006].bScaleByDistance = false; cfg[1006].BindSocketName = "root"
                cfg[1006].bUseLuaWorldSocketName = true; cfg[1006].WorldPositionOffset = FVector(0,0,-30)
            end
            cfg[8888] = { UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, MaxShowDistance = 6000000, bBindOutScreen = true, bBindBlocked = true,
                bIsBindingActor = true, BindSocketName = "head", bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0,0,30), bNeedPreLoad = true, Priority = 2 }
            cfg[9999] = { UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, MaxShowDistance = 6000000, bBindOutScreen = true, bBindBlocked = true,
                bIsBindingActor = true, BindSocketName = "head", bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0,0,50), bNeedPreLoad = true, Priority = 2 }
        end
        ApplyCfg(currentMarkCfg)
        for k, cfg in pairs(package.loaded) do
            if type(k) == "string" and string.find(k, "ScreenMarkConfig") and type(cfg) == "table" then ApplyCfg(cfg) end
        end
    end)
    _G.FufuModState.NativeESPReady = true
end

-- ==============================================================================
-- 5. FOV CIRCLE OVERLAY (порт из pasta.lua)
-- ==============================================================================
local SlateBlueprintLibrary = import("SlateBlueprintLibrary")

_G.FovCircleOverlay = {
    Container = nil, WidgetSlot = nil, ParentCanvas = nil, Lines = {},
    NumSegments = 45, Thickness = 1.5,
    LastRadius = -1, LastColor = -1, LastCX = -1, LastCY = -1, PrecalcMath = nil
}

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
    local FVector2D_local = import("Vector2D") or FVector2D
    for i = 1, _G.FovCircleOverlay.NumSegments do
        local border = nil
        pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", Container) end)
        if border and slua.isValid(border) then
            pcall(function()
                border.RenderTransformPivot = FVector2D_local(0, 0.5)
                border:SetRenderTransformPivot(FVector2D_local(0, 0.5))
                border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local slot = Container:AddChildToCanvas(border)
            if slot then pcall(function() slot:SetAlignment(FVector2D_local(0, 0.5)) end) end
            _G.FovCircleOverlay.Lines[i] = { widget = border, slot = slot }
        end
    end
    local MainSlot = nil
    pcall(function() MainSlot = ParentCanvas:AddChildToCanvas(Container) end)
    if MainSlot then
        pcall(function()
            MainSlot:SetAutoSize(false)
            MainSlot:SetSize(FVector2D_local(0, 0))
            MainSlot:SetZOrder(995)
            MainSlot:SetAlignment(FVector2D_local(0, 0))
            MainSlot:SetPosition(FVector2D_local(0, 0))
        end)
    end
    _G.FovCircleOverlay.Container = Container
    _G.FovCircleOverlay.WidgetSlot = MainSlot
    _G.FovCircleOverlay.ParentCanvas = ParentCanvas
    return true
end

function _G.FovCircleOverlay.Update(pc, player)
    if not Config.EspFovCircle then
        if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then
            pcall(function() _G.FovCircleOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            _G.FovCircleOverlay.LastRadius = -1
        end
        return
    end
    local fovVal, colIdx = 30, 7
    local WEAPON_TYPE = _G.__AimTouch_WeaponType or "NORMAL"
    local isADS = player.bIsGunADS or false
    if WEAPON_TYPE == "MORTAR" then
        fovVal = Sliders.AimTouchMortarFOV or 360; colIdx = Sliders.AimTouchMortarFOVColor or 5
    elseif WEAPON_TYPE == "SHOTGUN" then
        fovVal = Sliders.AimTouchSGFOV or 40; colIdx = Sliders.AimTouchSGFOVColor or 1
    elseif isADS then
        if WEAPON_TYPE == "SNIPER" then
            fovVal = Sliders.AimTouchSniperFOV or 20; colIdx = Sliders.AimTouchSniperFOVColor or 4
        else
            fovVal = Sliders.AimTouchScopeFOV or 30; colIdx = Sliders.AimTouchScopeFOVColor or 6
        end
    else
        fovVal = Sliders.AimTouchHipFOV or 30; colIdx = Sliders.AimTouchHipFOVColor or 7
    end
    local rawCX = _G.__AimTouch_CenterX or 960
    local rawCY = _G.__AimTouch_CenterY or 540
    local vpX   = _G.__AimTouch_ViewportX or 1920
    if not _G.FovCircleOverlay.Create() then return end
    local ParentCanvas = _G.FovCircleOverlay.ParentCanvas
    if not ParentCanvas or not slua.isValid(ParentCanvas) then return end

    local scaleX, scaleY, offsetX, offsetY = 1.0, 1.0, 0.0, 0.0
    pcall(function()
        local cg = ParentCanvas:GetCachedGeometry()
        if cg and SlateBlueprintLibrary then
            local FVector2D_local = import("Vector2D") or FVector2D
            local pt0 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D_local(0, 0))
            local pt1 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D_local(100, 100))
            if pt0 and pt1 then
                scaleX = (pt1.X - pt0.X) / 100
                scaleY = (pt1.Y - pt0.Y) / 100
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

    local LinearColorClass = import("LinearColor") or FLinearColor
    local r, g, b = GetFOVColor(colIdx)
    local dim = 0.55
    local color = LinearColorClass and LinearColorClass(r*dim, g*dim, b*dim, 1.0)
        or {R = r*dim*255, G = g*dim*255, B = b*dim*255, A = 255}

    local numSegments = _G.FovCircleOverlay.NumSegments
    if not _G.FovCircleOverlay.PrecalcMath then
        _G.FovCircleOverlay.PrecalcMath = {}
        local angleStep = 360.0 / numSegments
        local math_cos, math_sin, math_rad = math.cos, math.sin, math.rad
        local math_atan2 = math.atan2 or math.atan
        for i = 1, numSegments do
            local a1 = math_rad((i-1) * angleStep)
            local a2 = math_rad(i * angleStep)
            local c1, s1 = math_cos(a1), math_sin(a1)
            local c2, s2 = math_cos(a2), math_sin(a2)
            local dx, dy = c2 - c1, s2 - s1
            local dist = math.sqrt(dx*dx + dy*dy)
            local ang  = math.deg(math_atan2(dy, dx))
            _G.FovCircleOverlay.PrecalcMath[i] = { c1=c1, s1=s1, dist_unit=dist, angleDeg=ang }
        end
    end
    pcall(function()
        local FVector2D_local = import("Vector2D") or FVector2D
        for i = 1, numSegments do
            local md = _G.FovCircleOverlay.PrecalcMath[i]
            local x1 = targetRadius * md.c1
            local y1 = targetRadius * md.s1
            local dist = targetRadius * md.dist_unit
            local line = _G.FovCircleOverlay.Lines[i]
            if line and line.slot and slua.isValid(line.slot) then
                line.slot:SetPosition(FVector2D_local(centerX + x1, centerY + y1))
                line.slot:SetSize(FVector2D_local(dist + 0.8, _G.FovCircleOverlay.Thickness))
                line.widget:SetRenderAngle(md.angleDeg)
                line.widget:SetBrushColor(color)
            end
        end
    end)
end

-- ==============================================================================
-- 6. AIMBOT CORE (порт из pasta.lua)
-- ==============================================================================
_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
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

_G.AimTouch = function()
    pcall(function()
        if not Config.AimTouchEnable then return end
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
        local cond, prioMode, boneIdx, speedVal, fovVal, maxDistMeters, useVisCheck, igKnock, igBot = 2, 1, 1, 50, 30, 50, false, false, false
        local predVal, recoilCompVal = 0, 0
        if isMortar and Config.AimTouchMortar then
            local isPlaced = false
            pcall(function() if weapon and weapon.MortarState == 2 then isPlaced = true end end)
            if not isPlaced then return end
            cond, prioMode, boneIdx, speedVal = 2, 1, 4, 100
            fovVal = Sliders.AimTouchMortarFOV or 360
            maxDistMeters = 2000
            predVal = Sliders.AimTouchMortarPred or 0
        elseif isShotgun and Config.AimTouchSG then
            cond = Sliders.AimTouchSGCond or 1
            if Config.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = Sliders.AimTouchSGPrio or 1
            boneIdx = Sliders.AimTouchSGBone or 2
            speedVal = Sliders.AimTouchSGSpeed or 80
            fovVal = Sliders.AimTouchSGFOV or 40
            maxDistMeters = Sliders.AimTouchSGDist or 30
            useVisCheck = Config.AimTouchSGVisCheck
            igKnock = Config.AimTouchSGIgKnock; igBot = Config.AimTouchSGIgBot
        elseif isADS then
            if isSniper and Config.AimTouchScopeSniper then
                cond = Sliders.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode = Sliders.AimTouchSniperPrio or 1
                boneIdx = Sliders.AimTouchSniperBone or 1
                speedVal = Sliders.AimTouchSniperSpeed or 30
                fovVal = Sliders.AimTouchSniperFOV or 20
                maxDistMeters = Sliders.AimTouchSniperDist or 400
                useVisCheck = Config.AimTouchSniperVisCheck
                igKnock = Config.AimTouchSniperIgKnock; igBot = Config.AimTouchSniperIgBot
                predVal = Sliders.AimTouchSniperPred or 0
            elseif Config.AimTouchScopeAll then
                cond = Sliders.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = Sliders.AimTouchScopePrio or 1
                boneIdx = Sliders.AimTouchScopeBone or 2
                speedVal = Sliders.AimTouchScopeSpeed or 40
                fovVal = Sliders.AimTouchScopeFOV or 20
                maxDistMeters = Sliders.AimTouchScopeDist or 300
                useVisCheck = Config.AimTouchScopeVisCheck
                igKnock = Config.AimTouchScopeIgKnock; igBot = Config.AimTouchScopeIgBot
                predVal = Sliders.AimTouchScopePred or 0
                recoilCompVal = Sliders.AimTouchScopeRecoil or 0
            else return end
        else
            if not Config.AimTouchHipfire then return end
            cond = Sliders.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end
            prioMode = Sliders.AimTouchHipPrio or 1
            boneIdx = Sliders.AimTouchHipBone or 1
            speedVal = Sliders.AimTouchHipSpeed or 50
            fovVal = Sliders.AimTouchHipFOV or 30
            maxDistMeters = Sliders.AimTouchHipDist or 250
            useVisCheck = Config.AimTouchHipVisCheck
            igKnock = Config.AimTouchHipIgKnock; igBot = Config.AimTouchHipIgBot
        end
        local currentMaxDist = maxDistMeters * 100
        local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
        if not enemies or #enemies == 0 then return end
        local FVector2D_local = import("Vector2D")
        local UGameplayStatics = import("GameplayStatics")
        local KismetMathLibrary = import("KismetMathLibrary")
        local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
        if not slua.isValid(camManager) then return end
        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end
        local ui_util = require("client.common.ui_util")
        local viewportSize = ui_util and ui_util.GetViewportSize()
        if not viewportSize then return end
        local centerX, centerY = viewportSize.X * 0.5, viewportSize.Y * 0.5
        local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)
        local bestTarget, bestScore = nil, 99999999
        local selBoneName = "head"
        if boneIdx == 2 then selBoneName = "spine_03"
        elseif boneIdx == 3 then selBoneName = "spine_01"
        elseif boneIdx == 4 then selBoneName = "pelvis" end
        for _, target in ipairs(enemies) do
            if slua.isValid(target) then
                if igKnock and target.HealthStatus == 1 then goto continue end
                if igBot then
                    local tIsBot = false
                    if target.bIsAI == true or target.IsAI == true then tIsBot = true end
                    local pState = target.PlayerState
                    if slua.isValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
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
                if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then goto continue end
                local screen = FVector2D_local()
                local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
                if not success or screen.X <= 0 or screen.Y <= 0 then goto continue end
                local dx, dy = screen.X - centerX, screen.Y - centerY
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
                if currentScore < bestScore then bestScore = currentScore; bestTarget = target end
            end
            ::continue::
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
        local smoothFactor = speedVal >= 100 and 1.0 or ((speedVal / 100.0) * 0.3)
        if smoothFactor < 0.01 then smoothFactor = 0.01 end
        local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
        local finalYaw = currentRot.Yaw + (deltaYaw * smoothFactor)
        if recoilCompVal > 0 and isFiring then
            finalPitch = finalPitch - (recoilCompVal / 50.0) * 1.5
        end
        local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }
        pc:SetControlRotation(finalRot, "AimTouch")
        if isShotgun and Config.AimTouchSGAutoFire then
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
-- 7. UMG ХЕЛПЕРЫ
-- ==============================================================================
local function NewObject(path, parent)
    local obj = nil
    pcall(function()
        if CGame and CGame.NewObjectFromPath then obj = CGame:NewObjectFromPath(path, parent) end
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
            slot:SetPosition(FVector2D(x, y)); slot:SetSize(FVector2D(w, h)); slot:SetZOrder(zOrder or 0)
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
            slot:SetPosition(FVector2D(x, y)); slot:SetSize(FVector2D(w, h)); slot:SetZOrder(zOrder or 100)
        end
        if onClick then
            pcall(function()
                if btn.OnClicked then btn.OnClicked:Add(function() pcall(onClick) end) end
            end)
        end
    end
    return btn
end

-- ==============================================================================
-- 8. UI ПРИМИТИВЫ (header, checkbox, slider, color switcher)
-- ==============================================================================
local COLOR_NAMES = {"Red","White","Yellow","Green","Cyan","Blue","Purple"}

local function DrawSectionHeader(parent, x, y, w, label)
    Layer(parent, x, y, w, HEADER_ROW_H, Colors.bg_header_row, 10)
    Text(parent, "◆ " .. label, x + 12, y + HEADER_ROW_H * 0.5, 12, Colors.accent_gold, 15, 0.0, 0.5)
end

local function DrawCheckbox(parent, x, y, w, label, configTbl, key)
    local h = ROW_H
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y + h - 1, w, 1, FLinearColor(0.2, 0.25, 0.35, 0.4), 11)
    Text(parent, label, x + 16, y + h * 0.5, 12, Colors.text_white, 15, 0.0, 0.5)
    local toggleW, toggleH = 46, 22
    local toggleX = x + w - toggleW - 14
    local toggleY = y + (h - toggleH) * 0.5
    local track = Layer(parent, toggleX, toggleY, toggleW, toggleH,
        configTbl[key] and Colors.toggle_on or Colors.toggle_off, 12)
    local knobSize = 18
    local knobOffset = configTbl[key] and (toggleW - knobSize - 2) or 2
    local knob = Layer(parent, toggleX + knobOffset, toggleY + 2, knobSize, knobSize, Colors.toggle_knob, 14)
    MakeBtn(parent, x, y, w, h, 20, function()
        configTbl[key] = not configTbl[key]
        local isEnabled = configTbl[key]
        if IsValid(track) then track:SetBrushColor(isEnabled and Colors.toggle_on or Colors.toggle_off) end
        if IsValid(knob) then
            local newKnobX = toggleX + (isEnabled and (toggleW - knobSize - 2) or 2)
            if knob.Slot then knob.Slot:SetPosition(FVector2D(newKnobX, toggleY + 2)) end
        end
    end)
end

local function DrawSlider(parent, x, y, w, label, sliderTbl, key, minVal, maxVal, step)
    step = step or 1
    local h = ROW_H
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y + h - 1, w, 1, FLinearColor(0.2, 0.25, 0.35, 0.4), 11)
    Text(parent, label, x + 16, y + h * 0.5, 12, Colors.text_white, 15, 0.0, 0.5)
    local valText = Text(parent, tostring(sliderTbl[key]), x + w - 120, y + h * 0.5, 12, Colors.accent_blue, 15, 1.0, 0.5)
    local btnW = 28
    local btnMinusX = x + w - 85
    local btnPlusX  = x + w - 40
    local btnY      = y + (h - 26) * 0.5
    Layer(parent, btnMinusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "-", btnMinusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnMinusX, btnY, btnW, 26, 20, function()
        if sliderTbl[key] > minVal then
            sliderTbl[key] = sliderTbl[key] - step
            if IsValid(valText) then valText:SetText(tostring(sliderTbl[key])) end
        end
    end)
    Layer(parent, btnPlusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "+", btnPlusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnPlusX, btnY, btnW, 26, 20, function()
        if sliderTbl[key] < maxVal then
            sliderTbl[key] = sliderTbl[key] + step
            if IsValid(valText) then valText:SetText(tostring(sliderTbl[key])) end
        end
    end)
end

local function DrawColorSwitcher(parent, x, y, w, label, tbl, key)
    local h = ROW_H
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y + h - 1, w, 1, FLinearColor(0.2, 0.25, 0.35, 0.4), 11)
    Text(parent, label, x + 16, y + h * 0.5, 12, Colors.text_white, 15, 0.0, 0.5)
    local btnW = 26
    local btnMinusX = x + w - 130
    local btnPlusX  = x + w - 40
    local btnY      = y + (h - 26) * 0.5
    local valText = Text(parent, COLOR_NAMES[tbl[key]] or "?", x + w - 85, y + h * 0.5, 12, Colors.accent_gold, 15, 0.5, 0.5)
    Layer(parent, btnMinusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "<", btnMinusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnMinusX, btnY, btnW, 26, 20, function()
        tbl[key] = tbl[key] - 1; if tbl[key] < 1 then tbl[key] = 7 end
        if IsValid(valText) then valText:SetText(COLOR_NAMES[tbl[key]] or "?") end
    end)
    Layer(parent, btnPlusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, ">", btnPlusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnPlusX, btnY, btnW, 26, 20, function()
        tbl[key] = tbl[key] + 1; if tbl[key] > 7 then tbl[key] = 1 end
        if IsValid(valText) then valText:SetText(COLOR_NAMES[tbl[key]] or "?") end
    end)
end

-- ==============================================================================
-- 9. РЕНДЕР ВКЛАДОК
-- ==============================================================================
local function RenderVisuals(c, startY)
    local colW = MENU_W - 32
    local y = startY
    DrawSectionHeader(c, 16, y, colW, "VISUALS"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "Black Sky (Чёрное небо)", Config, "BlackSky"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "Wallhack (Chams)", Config, "Wallhack"); y = y + 38
    DrawSlider(c, 16, y, colW, "   Wallhack Glow (1-10)", Config, "WallhackGlow", 1, 10); y = y + 42
    DrawCheckbox(c, 16, y, colW, "IPad View (Отдаление камеры)", Config, "IpadView"); y = y + 38
    DrawSlider(c, 16, y, colW, "   iPad FOV (90-140)", Config, "IpadViewFOV", 90, 140); y = y + 46
    return y
end

local function RenderESP(c, startY)
    local colW = MENU_W - 32
    local y = startY
    DrawSectionHeader(c, 16, y, colW, "ENEMY ESP"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "ESP AUTO", Config, "EspVip"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "ESP METER (Distance)", Config, "EspDistance"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "HEALTH V1", Config, "EspVipPro"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "ESP MARK (Radar)", Config, "EspRadar"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "ESP BOX FRAME", Config, "Esp5"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "ESP HEAD", Config, "Esp6"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "ESP HEALTH V2", Config, "Esp8"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "ESP LINE ANTENNA", Config, "EspAntenna"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "ESP NAME", Config, "EspName"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "Visible Color", Sliders, "ColorVisible"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "Invisible Color", Sliders, "ColorInvisible"); y = y + 38
    DrawSlider(c, 16, y, colW, "Color Brightness (1-50)", Sliders, "ColorBrightness", 1, 50); y = y + 42
    DrawSlider(c, 16, y, colW, "Color Glow (0-10)", Sliders, "ColorGlow", 0, 10); y = y + 46

    DrawSectionHeader(c, 16, y, colW, "THROWABLE ESP"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "Enable Throwable", Config, "ThrowableEnabled"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Grenade", Config, "ThrowableGrenade"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Grenade Color", Config, "ThrowableColor_Grenade"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Smoke", Config, "ThrowableSmoke"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Smoke Color", Config, "ThrowableColor_Smoke"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Molotov", Config, "ThrowableMolotov"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Molotov Color", Config, "ThrowableColor_Molotov"); y = y + 46

    DrawSectionHeader(c, 16, y, colW, "VEHICLE ESP"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "Enable Vehicle", Config, "VehicleEnabled"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Dacia", Config, "VehicleShowDacia"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Dacia Color", Config, "VehicleColor_Dacia"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   UAZ", Config, "VehicleShowUAZ"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   UAZ Color", Config, "VehicleColor_UAZ"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Buggy", Config, "VehicleShowBuggy"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Buggy Color", Config, "VehicleColor_Buggy"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Coupe RB", Config, "VehicleShowCoupe"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Coupe Color", Config, "VehicleColor_Coupe"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Mirado", Config, "VehicleShowMirado"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Mirado Color", Config, "VehicleColor_Mirado"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Motor", Config, "VehicleShowMotor"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Motor Color", Config, "VehicleColor_Motor"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Other", Config, "VehicleShowOther"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Other Color", Config, "VehicleColor_Other"); y = y + 46

    DrawSectionHeader(c, 16, y, colW, "LOOT ESP"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "Enable Loot", Config, "EspLoot"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   M416", Config, "LootShowM416"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   M416 Color", Config, "LootColor_M416"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   AUG", Config, "LootShowAUG"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   AUG Color", Config, "LootColor_AUG"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   AKM", Config, "LootShowAKM"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   AKM Color", Config, "LootColor_AKM"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   M24 / M249", Config, "LootShowM24"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   M24 Color", Config, "LootColor_M24"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   UMP45", Config, "LootShowUMP"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   UMP Color", Config, "LootColor_UMP"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   DBS", Config, "LootShowDBS"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   DBS Color", Config, "LootColor_DBS"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   S12K", Config, "LootShowS12K"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   S12K Color", Config, "LootColor_S12K"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Vest Lv3", Config, "LootShowVest3"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Vest Lv3 Color", Config, "LootColor_Vest3"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Helm Lv3", Config, "LootShowHelmet3"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Helm Lv3 Color", Config, "LootColor_Helmet3"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Bag Lv3", Config, "LootShowBag3"); y = y + 38
    DrawColorSwitcher(c, 16, y, colW, "   Bag Lv3 Color", Config, "LootColor_Bag3"); y = y + 46

    DrawSectionHeader(c, 16, y, colW, "STATIC ESP"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "Enable Static", Config, "EspStatic"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Enemy Count", Config, "EspEnemyCount"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Weapon & Status", Config, "EspWeaponStatus"); y = y + 46
    return y
end

local function RenderAimbot(c, startY)
    local colW = MENU_W - 32
    local y = startY
    DrawSectionHeader(c, 16, y, colW, "AIMBOT MAIN"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "Enable Custom Aimbot", Config, "AimTouchEnable"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "Show FOV Circle", Config, "EspFovCircle"); y = y + 46

    DrawSectionHeader(c, 16, y, colW, "HIPFIRE AIMBOT"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "Enable Hipfire", Config, "AimTouchHipfire"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Ignore Knocked", Config, "AimTouchHipIgKnock"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Ignore Bots", Config, "AimTouchHipIgBot"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Visibility Check", Config, "AimTouchHipVisCheck"); y = y + 38
    DrawSlider(c, 16, y, colW, "   Priority (1-4)", Sliders, "AimTouchHipPrio", 1, 4); y = y + 38
    DrawSlider(c, 16, y, colW, "   Bone (1-4)", Sliders, "AimTouchHipBone", 1, 4); y = y + 38
    DrawSlider(c, 16, y, colW, "   Condition (1-2)", Sliders, "AimTouchHipCond", 1, 2); y = y + 38
    DrawSlider(c, 16, y, colW, "   Speed (1-100)", Sliders, "AimTouchHipSpeed", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   FOV (1-100)", Sliders, "AimTouchHipFOV", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   Distance (x5 m)", Sliders, "AimTouchHipDist", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   FOV Color (1-7)", Sliders, "AimTouchHipFOVColor", 1, 7); y = y + 46

    DrawSectionHeader(c, 16, y, colW, "SHOTGUN AIMBOT"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "Enable Shotgun", Config, "AimTouchSG"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Auto Fire", Config, "AimTouchSGAutoFire"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Ignore Knocked", Config, "AimTouchSGIgKnock"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Ignore Bots", Config, "AimTouchSGIgBot"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Visibility Check", Config, "AimTouchSGVisCheck"); y = y + 38
    DrawSlider(c, 16, y, colW, "   Priority (1-4)", Sliders, "AimTouchSGPrio", 1, 4); y = y + 38
    DrawSlider(c, 16, y, colW, "   Bone (1-4)", Sliders, "AimTouchSGBone", 1, 4); y = y + 38
    DrawSlider(c, 16, y, colW, "   Condition (1-2)", Sliders, "AimTouchSGCond", 1, 2); y = y + 38
    DrawSlider(c, 16, y, colW, "   Speed (1-100)", Sliders, "AimTouchSGSpeed", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   FOV (1-100)", Sliders, "AimTouchSGFOV", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   Distance (m)", Sliders, "AimTouchSGDist", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   FOV Color (1-7)", Sliders, "AimTouchSGFOVColor", 1, 7); y = y + 46

    DrawSectionHeader(c, 16, y, colW, "SCOPED AIMBOT (ALL)"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "Enable Scoped All", Config, "AimTouchScopeAll"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Ignore Knocked", Config, "AimTouchScopeIgKnock"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Ignore Bots", Config, "AimTouchScopeIgBot"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Visibility Check", Config, "AimTouchScopeVisCheck"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Anti OverHead", Config, "LessShake"); y = y + 38
    DrawSlider(c, 16, y, colW, "   Priority (1-4)", Sliders, "AimTouchScopePrio", 1, 4); y = y + 38
    DrawSlider(c, 16, y, colW, "   Bone (1-4)", Sliders, "AimTouchScopeBone", 1, 4); y = y + 38
    DrawSlider(c, 16, y, colW, "   Condition (1-2)", Sliders, "AimTouchScopeCond", 1, 2); y = y + 38
    DrawSlider(c, 16, y, colW, "   Speed (1-100)", Sliders, "AimTouchScopeSpeed", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   FOV (1-100)", Sliders, "AimTouchScopeFOV", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   Distance (x5 m)", Sliders, "AimTouchScopeDist", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   Prediction (0-100)", Sliders, "AimTouchScopePred", 0, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   Recoil Comp (0-50)", Sliders, "AimTouchScopeRecoil", 0, 50); y = y + 38
    DrawSlider(c, 16, y, colW, "   FOV Color (1-7)", Sliders, "AimTouchScopeFOVColor", 1, 7); y = y + 46

    DrawSectionHeader(c, 16, y, colW, "SNIPER AIMBOT"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "Enable Sniper", Config, "AimTouchScopeSniper"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Ignore Knocked", Config, "AimTouchSniperIgKnock"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Ignore Bots", Config, "AimTouchSniperIgBot"); y = y + 38
    DrawCheckbox(c, 16, y, colW, "   Visibility Check", Config, "AimTouchSniperVisCheck"); y = y + 38
    DrawSlider(c, 16, y, colW, "   Priority (1-4)", Sliders, "AimTouchSniperPrio", 1, 4); y = y + 38
    DrawSlider(c, 16, y, colW, "   Bone (1-4)", Sliders, "AimTouchSniperBone", 1, 4); y = y + 38
    DrawSlider(c, 16, y, colW, "   Condition (1-2)", Sliders, "AimTouchSniperCond", 1, 2); y = y + 38
    DrawSlider(c, 16, y, colW, "   Speed (1-100)", Sliders, "AimTouchSniperSpeed", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   FOV (1-100)", Sliders, "AimTouchSniperFOV", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   Distance (x5 m)", Sliders, "AimTouchSniperDist", 1, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   Prediction (0-100)", Sliders, "AimTouchSniperPred", 0, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   FOV Color (1-7)", Sliders, "AimTouchSniperFOVColor", 1, 7); y = y + 46

    DrawSectionHeader(c, 16, y, colW, "MORTAR AIMBOT"); y = y + 32
    DrawCheckbox(c, 16, y, colW, "Enable Mortar", Config, "AimTouchMortar"); y = y + 38
    DrawSlider(c, 16, y, colW, "   Prediction (0-100)", Sliders, "AimTouchMortarPred", 0, 100); y = y + 38
    DrawSlider(c, 16, y, colW, "   FOV (1-360)", Sliders, "AimTouchMortarFOV", 1, 360); y = y + 38
    DrawSlider(c, 16, y, colW, "   FOV Color (1-7)", Sliders, "AimTouchMortarFOVColor", 1, 7); y = y + 46
    return y
end

-- ==============================================================================
-- 10. СКРОЛЛ-СИСТЕМА И СБОРКА МЕНЮ
-- ==============================================================================
local currentTab = "VISUALS"
local bgPanel, floatItem, contentCanvas, parentCanvas = nil, nil, nil, nil
local isMenuOpen = false
local currentPage, totalPages = 1, 1
local ITEMS_PER_PAGE = 13
local pageItems = {}

-- Разбиваем вкладку на страницы (по 13 строк с учётом headers)
local function BuildPageItems(tabName)
    local items = {}
    local function hdr(label)      table.insert(items, {kind="header", label=label}) end
    local function chk(label, key) table.insert(items, {kind="check",  label=label, key=key}) end
    local function sl(label, key, mn, mx) table.insert(items, {kind="slider", label=label, key=key, mn=mn, mx=mx}) end
    local function cs(label, key)  table.insert(items, {kind="color",  label=label, key=key}) end

    if tabName == "VISUALS" then
        hdr("VISUALS")
        chk("Black Sky (Чёрное небо)", "BlackSky")
        chk("Wallhack (Chams)", "Wallhack")
        sl("   Wallhack Glow (1-10)", "WallhackGlow", 1, 10)
        chk("IPad View (Отдаление камеры)", "IpadView")
        sl("   iPad FOV (90-140)", "IpadViewFOV", 90, 140)
    elseif tabName == "ESP" then
        hdr("ENEMY ESP")
        chk("ESP AUTO", "EspVip")
        chk("ESP METER (Distance)", "EspDistance")
        chk("HEALTH V1", "EspVipPro")
        chk("ESP MARK (Radar)", "EspRadar")
        chk("ESP BOX FRAME", "Esp5")
        chk("ESP HEAD", "Esp6")
        chk("ESP HEALTH V2", "Esp8")
        chk("ESP LINE ANTENNA", "EspAntenna")
        chk("ESP NAME", "EspName")
        cs("Visible Color", "ColorVisible")
        cs("Invisible Color", "ColorInvisible")
        sl("Color Brightness (1-50)", "ColorBrightness", 1, 50)
        sl("Color Glow (0-10)", "ColorGlow", 0, 10)

        hdr("THROWABLE ESP")
        chk("Enable Throwable", "ThrowableEnabled")
        chk("   Grenade", "ThrowableGrenade")
        cs("   Grenade Color", "ThrowableColor_Grenade")
        chk("   Smoke", "ThrowableSmoke")
        cs("   Smoke Color", "ThrowableColor_Smoke")
        chk("   Molotov", "ThrowableMolotov")
        cs("   Molotov Color", "ThrowableColor_Molotov")

        hdr("VEHICLE ESP")
        chk("Enable Vehicle", "VehicleEnabled")
        chk("   Dacia", "VehicleShowDacia")
        cs("   Dacia Color", "VehicleColor_Dacia")
        chk("   UAZ", "VehicleShowUAZ")
        cs("   UAZ Color", "VehicleColor_UAZ")
        chk("   Buggy", "VehicleShowBuggy")
        cs("   Buggy Color", "VehicleColor_Buggy")
        chk("   Coupe RB", "VehicleShowCoupe")
        cs("   Coupe Color", "VehicleColor_Coupe")
        chk("   Mirado", "VehicleShowMirado")
        cs("   Mirado Color", "VehicleColor_Mirado")
        chk("   Motor", "VehicleShowMotor")
        cs("   Motor Color", "VehicleColor_Motor")
        chk("   Other", "VehicleShowOther")
        cs("   Other Color", "VehicleColor_Other")

        hdr("LOOT ESP")
        chk("Enable Loot", "EspLoot")
        chk("   M416", "LootShowM416")
        cs("   M416 Color", "LootColor_M416")
        chk("   AUG", "LootShowAUG")
        cs("   AUG Color", "LootColor_AUG")
        chk("   AKM", "LootShowAKM")
        cs("   AKM Color", "LootColor_AKM")
        chk("   M24 / M249", "LootShowM24")
        cs("   M24 Color", "LootColor_M24")
        chk("   UMP45", "LootShowUMP")
        cs("   UMP Color", "LootColor_UMP")
        chk("   DBS", "LootShowDBS")
        cs("   DBS Color", "LootColor_DBS")
        chk("   S12K", "LootShowS12K")
        cs("   S12K Color", "LootColor_S12K")
        chk("   Vest Lv3", "LootShowVest3")
        cs("   Vest Lv3 Color", "LootColor_Vest3")
        chk("   Helm Lv3", "LootShowHelmet3")
        cs("   Helm Lv3 Color", "LootColor_Helmet3")
        chk("   Bag Lv3", "LootShowBag3")
        cs("   Bag Lv3 Color", "LootColor_Bag3")

        hdr("STATIC ESP")
        chk("Enable Static", "EspStatic")
        chk("   Enemy Count", "EspEnemyCount")
        chk("   Weapon & Status", "EspWeaponStatus")
    elseif tabName == "AIMBOT" then
        hdr("AIMBOT MAIN")
        chk("Enable Custom Aimbot", "AimTouchEnable")
        chk("Show FOV Circle", "EspFovCircle")

        hdr("HIPFIRE AIMBOT")
        chk("Enable Hipfire", "AimTouchHipfire")
        chk("   Ignore Knocked", "AimTouchHipIgKnock")
        chk("   Ignore Bots", "AimTouchHipIgBot")
        chk("   Visibility Check", "AimTouchHipVisCheck")
        sl("   Priority (1-4)", "AimTouchHipPrio", 1, 4)
        sl("   Bone (1-4)", "AimTouchHipBone", 1, 4)
        sl("   Condition (1-2)", "AimTouchHipCond", 1, 2)
        sl("   Speed (1-100)", "AimTouchHipSpeed", 1, 100)
        sl("   FOV (1-100)", "AimTouchHipFOV", 1, 100)
        sl("   Distance (x5 m)", "AimTouchHipDist", 1, 100)
        sl("   FOV Color (1-7)", "AimTouchHipFOVColor", 1, 7)

        hdr("SHOTGUN AIMBOT")
        chk("Enable Shotgun", "AimTouchSG")
        chk("   Auto Fire", "AimTouchSGAutoFire")
        chk("   Ignore Knocked", "AimTouchSGIgKnock")
        chk("   Ignore Bots", "AimTouchSGIgBot")
        chk("   Visibility Check", "AimTouchSGVisCheck")
        sl("   Priority (1-4)", "AimTouchSGPrio", 1, 4)
        sl("   Bone (1-4)", "AimTouchSGBone", 1, 4)
        sl("   Condition (1-2)", "AimTouchSGCond", 1, 2)
        sl("   Speed (1-100)", "AimTouchSGSpeed", 1, 100)
        sl("   FOV (1-100)", "AimTouchSGFOV", 1, 100)
        sl("   Distance (m)", "AimTouchSGDist", 1, 100)
        sl("   FOV Color (1-7)", "AimTouchSGFOVColor", 1, 7)

        hdr("SCOPED AIMBOT (ALL)")
        chk("Enable Scoped All", "AimTouchScopeAll")
        chk("   Ignore Knocked", "AimTouchScopeIgKnock")
        chk("   Ignore Bots", "AimTouchScopeIgBot")
        chk("   Visibility Check", "AimTouchScopeVisCheck")
        chk("   Anti OverHead", "LessShake")
        sl("   Priority (1-4)", "AimTouchScopePrio", 1, 4)
        sl("   Bone (1-4)", "AimTouchScopeBone", 1, 4)
        sl("   Condition (1-2)", "AimTouchScopeCond", 1, 2)
        sl("   Speed (1-100)", "AimTouchScopeSpeed", 1, 100)
        sl("   FOV (1-100)", "AimTouchScopeFOV", 1, 100)
        sl("   Distance (x5 m)", "AimTouchScopeDist", 1, 100)
        sl("   Prediction (0-100)", "AimTouchScopePred", 0, 100)
        sl("   Recoil Comp (0-50)", "AimTouchScopeRecoil", 0, 50)
        sl("   FOV Color (1-7)", "AimTouchScopeFOVColor", 1, 7)

        hdr("SNIPER AIMBOT")
        chk("Enable Sniper", "AimTouchScopeSniper")
        chk("   Ignore Knocked", "AimTouchSniperIgKnock")
        chk("   Ignore Bots", "AimTouchSniperIgBot")
        chk("   Visibility Check", "AimTouchSniperVisCheck")
        sl("   Priority (1-4)", "AimTouchSniperPrio", 1, 4)
        sl("   Bone (1-4)", "AimTouchSniperBone", 1, 4)
        sl("   Condition (1-2)", "AimTouchSniperCond", 1, 2)
        sl("   Speed (1-100)", "AimTouchSniperSpeed", 1, 100)
        sl("   FOV (1-100)", "AimTouchSniperFOV", 1, 100)
        sl("   Distance (x5 m)", "AimTouchSniperDist", 1, 100)
        sl("   Prediction (0-100)", "AimTouchSniperPred", 0, 100)
        sl("   FOV Color (1-7)", "AimTouchSniperFOVColor", 1, 7)

        hdr("MORTAR AIMBOT")
        chk("Enable Mortar", "AimTouchMortar")
        sl("   Prediction (0-100)", "AimTouchMortarPred", 0, 100)
        sl("   FOV (1-360)", "AimTouchMortarFOV", 1, 360)
        sl("   FOV Color (1-7)", "AimTouchMortarFOVColor", 1, 7)

        hdr("MISC")
        chk("Small Crosshair", "Crosshair")
    end
    return items
end

local function RenderPage()
    if not IsValid(contentCanvas) then return end
    contentCanvas:ClearChildren()

    local items = BuildPageItems(currentTab)
    -- считаем "слоты" — заголовок = 1 слот, чекбокс = 1 слот, слайдер = 1 слот, color = 1 слот
    local totalSlots = #items
    totalPages = math.max(1, math.ceil(totalSlots / ITEMS_PER_PAGE))
    if currentPage > totalPages then currentPage = totalPages end

    local startIdx = (currentPage - 1) * ITEMS_PER_PAGE + 1
    local endIdx = math.min(currentPage * ITEMS_PER_PAGE, totalSlots)
    local colW = MENU_W - 32
    local y = 6
    for i = startIdx, endIdx do
        local it = items[i]
        if it.kind == "header" then
            DrawSectionHeader(contentCanvas, 16, y, colW, it.label)
            y = y + HEADER_ROW_H + 6
        elseif it.kind == "check" then
            DrawCheckbox(contentCanvas, 16, y, colW, it.label, Config, it.key)
            y = y + ROW_H + 4
        elseif it.kind == "slider" then
            DrawSlider(contentCanvas, 16, y, colW, it.label, Sliders, it.key, it.mn, it.mx)
            y = y + ROW_H + 4
        elseif it.kind == "color" then
            DrawColorSwitcher(contentCanvas, 16, y, colW, it.label, Sliders, it.key)
            y = y + ROW_H + 4
        end
    end
end

-- ==============================================================================
-- 11. СБОРКА ОКНА
-- ==============================================================================
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

    -- Header
    local HEADER_H = 44
    Layer(bgPanel, 0, 0, MENU_W, HEADER_H, Colors.bg_header, 3)
    Layer(bgPanel, 0, HEADER_H - 1, MENU_W, 1, Colors.border, 4)
    Text(bgPanel, "SodaLite GLOBAL", 16, HEADER_H * 0.5, 14, Colors.text_white, 5, 0.0, 0.5)

    local closeX = MENU_W - 36
    Layer(bgPanel, closeX, 8, 28, 28, Colors.accent_red, 5)
    Text(bgPanel, "X", closeX + 14, 22, 12, Colors.text_white, 6, 0.5, 0.5)
    MakeBtn(bgPanel, closeX, 8, 28, 28, 50, function()
        bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        isMenuOpen = false
    end)

    -- Tabs
    local tabY = HEADER_H + 8
    local tabW, tabH = 130, 32
    local tabs = {
        {name="VISUALS", x=16},
        {name="ESP",     x=16 + tabW + 6},
        {name="AIMBOT",  x=16 + (tabW + 6) * 2},
    }
    for _, t in ipairs(tabs) do
        Layer(bgPanel, t.x, tabY, tabW, tabH, Colors.bg_row, 5)
        Text(bgPanel, t.name, t.x + tabW * 0.5, tabY + tabH * 0.5, 11, Colors.text_white, 6, 0.5, 0.5)
        MakeBtn(bgPanel, t.x, tabY, tabW, tabH, 20, function()
            currentTab = t.name
            currentPage = 1
            RenderPage()
        end)
    end

    -- Content area
    local contentY = tabY + tabH + 6
    local contentH = MENU_H - contentY - 46
    contentCanvas = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local cSlot = bgPanel:AddChildToCanvas(contentCanvas)
    cSlot:SetPosition(FVector2D(8, contentY))
    cSlot:SetSize(FVector2D(MENU_W - 16, contentH))
    cSlot:SetZOrder(10)

    -- Footer с pagination
    local footY = MENU_H - 40
    Layer(bgPanel, 0, footY - 1, MENU_W, 1, Colors.border, 40)

    local prevBtnW = 100
    local nextBtnW = 100
    local midX = MENU_W - (prevBtnW + nextBtnW + 40)
    Layer(bgPanel, 16, footY + 6, prevBtnW, 26, Colors.slider_bg, 41)
    Text(bgPanel, "< PREV", 16 + prevBtnW * 0.5, footY + 19, 12, Colors.text_white, 42, 0.5, 0.5)
    MakeBtn(bgPanel, 16, footY + 6, prevBtnW, 26, 50, function()
        if currentPage > 1 then currentPage = currentPage - 1; RenderPage() end
    end)

    Layer(bgPanel, midX, footY + 6, 100, 26, Colors.slider_bg, 41)
    local pageText = Text(bgPanel, "PAGE 1/1", midX + 50, footY + 19, 11, Colors.accent_gold, 42, 0.5, 0.5)
    -- закинем ссылку в глобал, чтобы обновлять счётчик после RenderPage
    _G._SodaPageText = pageText

    Layer(bgPanel, midX + 100 + 6, footY + 6, nextBtnW, 26, Colors.slider_bg, 41)
    Text(bgPanel, "NEXT >", midX + 106 + nextBtnW * 0.5, footY + 19, 12, Colors.text_white, 42, 0.5, 0.5)
    MakeBtn(bgPanel, midX + 100 + 6, footY + 6, nextBtnW, 26, 50, function()
        if currentPage < totalPages then currentPage = currentPage + 1; RenderPage() end
    end)

    RenderPage()
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
-- 12. ПЛАВАЮЩАЯ КНОПКА
-- ==============================================================================
local function CreateFloatButton(canvas)
    if floatItem and IsValid(floatItem.btn) then return end
    floatItem = {}
    local fX, fY, fW, fH = floatPos.X, floatPos.Y, FLOAT_W, FLOAT_H
    floatItem.shadow = Layer(canvas, fX + 2, fY + 3, fW, fH, Colors.shadow, 11898)
    floatItem.border = Layer(canvas, fX - 1, fY - 1, fW + 2, fH + 2, Colors.border, 11900)
    floatItem.bg     = Layer(canvas, fX, fY, fW, fH, Colors.bg_header, 11901)
    floatItem.text   = Text(canvas, "SodaLite", fX + fW * 0.5, fY + fH * 0.5, 11, Colors.accent_blue, 12001, 0.5, 0.5)
    floatItem.btn = MakeBtn(canvas, fX, fY, fW, fH, 12002, function() ToggleMenu(canvas) end)
end

-- ==============================================================================
-- 13. ОСНОВНОЙ ЦИКЛ: ESP + VEHICLE + THROWABLE + LOOT + STATIC + AIMBOT
-- ==============================================================================
local cached_GameplayStatics, cached_ActorClass_ForVehicle = nil, nil
local cached_ActorClass_ForBomb, cached_ActorClass_ForLoot = nil, nil
local cached_VehicleArray, cached_ProjArray, cached_LootArray = nil, nil, nil
local Cached_SecurityCommonUtils = nil

local function ESPMainLoop()
    if _G._SodaPageText and IsValid(_G._SodaPageText) then
        _G._SodaPageText:SetText(string.format("PAGE %d/%d", currentPage, totalPages))
    end

    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local pc = GameplayData.GetPlayerController()
        local localPlayer = slua.isValid(pc) and pc:GetPlayerCharacterSafety() or nil
        if not slua.isValid(localPlayer) then
            for markId, _ in pairs(_G.FufuModState.TrackedMarks) do SafeRemoveMark(markId) end
            _G.FufuModState.TrackedMarks = {}
            _G.FufuModState.EnemyMarks = {}
            return
        end

        InitializeNativeESP()

        -- Viewport center
        local ui_util = require("client.common.ui_util")
        local vp = ui_util and ui_util.GetViewportSize()
        if vp then
            _G.__AimTouch_ViewportX = vp.X
            _G.__AimTouch_CenterX = vp.X * 0.5
            _G.__AimTouch_CenterY = vp.Y * 0.5
        end

        -- Weapon type detection (для FOV circle)
        local wName = ""
        local weapon = localPlayer.WeaponManagerComponent and localPlayer.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(localPlayer.GetCurrentShootWeapon) == "function" then weapon = localPlayer:GetCurrentShootWeapon() end
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

        -- ================ ENEMY ESP ================
        local MyHUD = pc and pc.MyHUD or nil
        if not Cached_SecurityCommonUtils then
            pcall(function() Cached_SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils") end)
        end

        local allChars = {}
        if GameplayData.GetAllPlayerCharacters then allChars = GameplayData.GetAllPlayerCharacters()
        elseif GameplayData.GameCharacters then for _, ch in pairs(GameplayData.GameCharacters) do table.insert(allChars, ch) end end

        local mLoc = nil
        pcall(function() if type(localPlayer.K2_GetActorLocation) == "function" then mLoc = localPlayer:K2_GetActorLocation() end end)

        for _, enemy in pairs(allChars) do
            if slua.isValid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                local key = GetSafeEnemyKey(enemy)
                _G.FufuModState.EnemyMarks[key] = _G.FufuModState.EnemyMarks[key] or { enemy = enemy }
                local markData = _G.FufuModState.EnemyMarks[key]
                markData.enemy = enemy

                -- Chams если Wallhack
                if Config.Wallhack then
                    ApplyColorBodyNew(enemy, markData)
                else
                    if markData.ColorNewApplied then UndoColorBodyNew(enemy, markData) end
                end

                if slua.isValid(MyHUD) and MyHUD.AddDebugText then
                    local distM = 0
                    pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)
                    if distM > 0 and distM <= 400 then
                        -- HP + Name (VipPro)
                        if Config.EspVipPro then
                            local hp = enemy.Health or 100
                            local maxHp = enemy.HealthMax or 100
                            local hpPercent = maxHp > 0 and math.floor((hp/maxHp)*100) or 0
                            local pName = Config.EspName and (enemy.PlayerName or "Enemy") or ""
                            local label = (pName ~= "" and (pName .. " ") or "") .. hpPercent .. "%"
                            local bIsVis = true
                            pcall(function() if pc and type(pc.LineOfSightTo) == "function" then bIsVis = pc:LineOfSightTo(enemy) end end)
                            local visRGB = GetAppliedColor(Sliders.ColorVisible or 4, Sliders.ColorBrightness or 25)
                            local invRGB = GetAppliedColor(Sliders.ColorInvisible or 1, Sliders.ColorBrightness or 25)
                            local col = bIsVis and visRGB or invRGB
                            pcall(function()
                                MyHUD:AddDebugText(label, enemy, 0.2,
                                    {X=0,Y=0,Z=120}, {X=0,Y=0,Z=120},
                                    col, true, false, true, nil, 1.0, true)
                            end)
                        end

                        -- Distance
                        if Config.EspDistance then
                            pcall(function()
                                MyHUD:AddDebugText(string.format("%.0fm", distM), enemy, 0.3,
                                    {X=15,Y=15,Z=-15}, {X=15,Y=15,Z=-15},
                                    {R=255,G=255,B=255,A=255}, true, false, true, nil, 0.9, true)
                            end)
                        end

                        -- Name (если не VipPro)
                        if Config.EspName and not Config.EspVipPro then
                            pcall(function()
                                local pName = enemy.PlayerName or enemy.PlayerNamePublic or "Enemy"
                                MyHUD:AddDebugText(pName, enemy, 0.2,
                                    {X=0,Y=0,Z=150}, {X=0,Y=0,Z=150},
                                    {R=255,G=255,B=255,A=255}, true, false, true, nil, 1.0, true)
                            end)
                        end

                        -- Head dot
                        if Config.Esp6 then
                            local eMesh = enemy.Mesh
                            if Valid(eMesh) and distM <= 250 then
                                local bIsVis = true
                                pcall(function() if pc and type(pc.LineOfSightTo) == "function" then bIsVis = pc:LineOfSightTo(enemy) end end)
                                local visRGB = GetAppliedColor(Sliders.ColorVisible or 4, Sliders.ColorBrightness or 25)
                                local invRGB = GetAppliedColor(Sliders.ColorInvisible or 1, Sliders.ColorBrightness or 25)
                                local col = bIsVis and visRGB or invRGB
                                pcall(function()
                                    MyHUD:AddDebugText("●", enemy, 0.2,
                                        {X=0,Y=0,Z=90}, {X=0,Y=0,Z=90},
                                        col, true, false, true, nil, 0.9, true)
                                end)
                            end
                        end

                        -- Antenna
                        if Config.EspAntenna and distM <= 400 then
                            pcall(function()
                                local loopCount, zStep, baseZ = 8, 1000, 105
                                local topZ = baseZ + (loopCount * zStep)
                                for i = 1, loopCount do
                                    local zOff = baseZ + (i * zStep)
                                    MyHUD:AddDebugText("|", enemy, 0.06,
                                        {X=0,Y=0,Z=zOff}, {X=0,Y=0,Z=zOff},
                                        C_GREEN, true, false, true, nil, 1.2, true)
                                end
                                MyHUD:AddDebugText("I", enemy, 0.06,
                                    {X=0,Y=0,Z=topZ+60}, {X=0,Y=0,Z=topZ+60},
                                    C_GREEN, true, false, true, nil, 1.5, true)
                            end)
                        end
                    end
                end

                -- Radar mark
                if Config.EspRadar then
                    if not markData.radarMark or markData.radarMark == 0 then
                        markData.radarMark = SafeAddMark(8888, FVector(0,0,0), 0, "", 4, enemy)
                    end
                else
                    if markData.radarMark and markData.radarMark ~= 0 then
                        SafeRemoveMark(markData.radarMark); markData.radarMark = nil
                    end
                end

                -- HP mark (EspVip / Esp8)
                if Config.EspVip then
                    if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                else
                    if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                end
                if Config.Esp8 then
                    if markData.hpMark8 == nil then markData.hpMark8 = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                else
                    if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                end
            end
        end

        -- ================ VEHICLE ESP ================
        if Config.VehicleEnabled and slua.isValid(MyHUD) then
            pcall(function()
                if not cached_GameplayStatics then cached_GameplayStatics = import("GameplayStatics") end
                if not cached_ActorClass_ForVehicle then cached_ActorClass_ForVehicle = import("STExtraVehicleBase") end
                if not cached_VehicleArray then cached_VehicleArray = slua.Array(UEnums.EPropertyClass.Object, cached_ActorClass_ForVehicle) end
                local gameInstance = ui_util and ui_util.GetGameInstance()
                if gameInstance and cached_GameplayStatics then
                    local allVehicles = cached_GameplayStatics.GetAllActorsOfClass(gameInstance, cached_ActorClass_ForVehicle, cached_VehicleArray)
                    if allVehicles then
                        for _, veh in pairs(allVehicles) do
                            if slua.isValid(veh) and not veh.bHidden and not veh.bTearOff then
                                local vehName = "Kendaraan"
                                pcall(function()
                                    if type(veh.GetVehicleName) == "function" then vehName = veh:GetVehicleName()
                                    elseif veh.VehicleName then vehName = veh.VehicleName end
                                end)
                                local nameLower = string.lower(tostring(vehName) .. tostring(veh))
                                local displayName, colorKey, isShow = "Other", "VehicleColor_Other", Config.VehicleShowOther
                                if string.find(nameLower, "uaz") then displayName, colorKey, isShow = "UAZ", "VehicleColor_UAZ", Config.VehicleShowUAZ
                                elseif string.find(nameLower, "dacia") then displayName, colorKey, isShow = "Dacia", "VehicleColor_Dacia", Config.VehicleShowDacia
                                elseif string.find(nameLower, "buggy") then displayName, colorKey, isShow = "Buggy", "VehicleColor_Buggy", Config.VehicleShowBuggy
                                elseif string.find(nameLower, "mirado") then displayName, colorKey, isShow = "Mirado", "VehicleColor_Mirado", Config.VehicleShowMirado
                                elseif string.find(nameLower, "bike") or string.find(nameLower, "motor") or string.find(nameLower, "scooter") then displayName, colorKey, isShow = "Motor", "VehicleColor_Motor", Config.VehicleShowMotor
                                elseif string.find(nameLower, "coupe") then displayName, colorKey, isShow = "Coupe", "VehicleColor_Coupe", Config.VehicleShowCoupe end
                                if isShow then
                                    local distM = 0
                                    pcall(function() distM = localPlayer:GetDistanceTo(veh) / 100 end)
                                    if distM > 0 and distM <= 300 then
                                        local vehColor = GetColorBy7(Config[colorKey] or 4)
                                        local text = string.format("%s [%dm]", displayName, math.floor(distM))
                                        pcall(function()
                                            MyHUD:AddDebugText(text, veh, 0.3,
                                                {X=0,Y=0,Z=50}, {X=0,Y=0,Z=50},
                                                vehColor, true, false, true, nil, 1.0, true)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- ================ THROWABLE ESP ================
        if Config.ThrowableEnabled and slua.isValid(MyHUD) then
            pcall(function()
                if not cached_GameplayStatics then cached_GameplayStatics = import("GameplayStatics") end
                if not cached_ActorClass_ForBomb then cached_ActorClass_ForBomb = import("Actor") end
                if not cached_ProjArray then cached_ProjArray = slua.Array(UEnums.EPropertyClass.Object, cached_ActorClass_ForBomb) end
                local gameInstance = ui_util and ui_util.GetGameInstance()
                if gameInstance and cached_GameplayStatics then
                    local allActors = cached_GameplayStatics.GetAllActorsOfClass(gameInstance, cached_ActorClass_ForBomb, cached_ProjArray)
                    if allActors then
                        for _, actor in pairs(allActors) do
                            if slua.isValid(actor) and not actor.bHidden and not actor.bTearOff then
                                local nameLower = string.lower(tostring(actor))
                                local bType, displayName, colorKey, toggle = 0, nil, nil, nil
                                if string.find(nameLower, "smoke") then bType, displayName, colorKey, toggle = 2, "SMOKE", "ThrowableColor_Smoke", "ThrowableSmoke"
                                elseif string.find(nameLower, "burn") or string.find(nameLower, "molotov") then bType, displayName, colorKey, toggle = 3, "MOLOTOV", "ThrowableColor_Molotov", "ThrowableMolotov"
                                elseif string.find(nameLower, "grenade") then bType, displayName, colorKey, toggle = 1, "GRENADE", "ThrowableColor_Grenade", "ThrowableGrenade" end
                                if bType > 0 and Config[toggle] then
                                    local distM = 0
                                    pcall(function() distM = localPlayer:GetDistanceTo(actor) / 100 end)
                                    if distM > 0 and distM <= 150 then
                                        local col = GetColorBy7(Config[colorKey] or 4)
                                        local text = string.format("%s [%dm]", displayName, math.floor(distM))
                                        pcall(function()
                                            MyHUD:AddDebugText(text, actor, 0.3,
                                                {X=0,Y=0,Z=25}, {X=0,Y=0,Z=25},
                                                col, true, false, true, nil, 1.0, true)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- ================ LOOT ESP ================
        if Config.EspLoot and slua.isValid(MyHUD) then
            pcall(function()
                if not cached_GameplayStatics then cached_GameplayStatics = import("GameplayStatics") end
                if not cached_ActorClass_ForLoot then cached_ActorClass_ForLoot = import("Actor") end
                if not cached_LootArray then cached_LootArray = slua.Array(UEnums.EPropertyClass.Object, cached_ActorClass_ForLoot) end
                local gameInstance = ui_util and ui_util.GetGameInstance()
                if gameInstance and cached_GameplayStatics then
                    local allActors = cached_GameplayStatics.GetAllActorsOfClass(gameInstance, cached_ActorClass_ForLoot, cached_LootArray)
                    if allActors then
                        local lootKeywords = {
                            ["m416"] = {name="M416", toggle="LootShowM416", colorKey="LootColor_M416"},
                            ["aug"]  = {name="AUG",  toggle="LootShowAUG",  colorKey="LootColor_AUG"},
                            ["akm"]  = {name="AKM",  toggle="LootShowAKM",  colorKey="LootColor_AKM"},
                            ["m24"]  = {name="M24",  toggle="LootShowM24",  colorKey="LootColor_M24"},
                            ["m249"] = {name="M249", toggle="LootShowM24",  colorKey="LootColor_M24"},
                            ["ump"]  = {name="UMP45",toggle="LootShowUMP",  colorKey="LootColor_UMP"},
                            ["dbs"]  = {name="DBS",  toggle="LootShowDBS",  colorKey="LootColor_DBS"},
                            ["s12"]  = {name="S12K", toggle="LootShowS12K", colorKey="LootColor_S12K"},
                        }
                        for _, actor in pairs(allActors) do
                            if slua.isValid(actor) and not actor.bHidden and not actor.bTearOff then
                                local lowerName = string.lower(tostring(actor))
                                for keyword, info in pairs(lootKeywords) do
                                    if string.find(lowerName, keyword, 1, true) and Config[info.toggle] then
                                        local distM = 0
                                        pcall(function() distM = localPlayer:GetDistanceTo(actor) / 100 end)
                                        if distM > 0 and distM <= 100 then
                                            local col = GetColorBy7(Config[info.colorKey] or 4)
                                            local text = string.format("%s [%dm]", info.name, math.floor(distM))
                                            pcall(function()
                                                MyHUD:AddDebugText(text, actor, 0.3,
                                                    {X=0,Y=0,Z=30}, {X=0,Y=0,Z=30},
                                                    col, true, false, true, nil, 1.0, true)
                                            end)
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- ================ STATIC ESP ================
        if Config.EspStatic and slua.isValid(MyHUD) then
            pcall(function()
                if Config.EspEnemyCount then
                    local function Rainbow()
                        local t = os.clock()
                        local r = math.sin(t * 0.8) * 0.5 + 0.5
                        local g = math.sin(t * 0.8 + 2.094) * 0.5 + 0.5
                        local b = math.sin(t * 0.8 + 4.188) * 0.5 + 0.5
                        return { R = math.floor(r*255), G = math.floor(g*255), B = math.floor(b*255), A = 255 }
                    end
                    local myTeamId = localPlayer.TeamID or 0
                    local myPos = localPlayer:K2_GetActorLocation()
                    local maxDist, realCount, aiCount = 35000, 0, 0
                    for _, tPawn in pairs(allChars) do
                        if slua.isValid(tPawn) and tPawn ~= localPlayer then
                            local tTeamId = tPawn.TeamID or 0
                            if tTeamId ~= myTeamId then
                                local ePos = tPawn:K2_GetActorLocation()
                                if ePos then
                                    local dx, dy, dz = ePos.X - myPos.X, ePos.Y - myPos.Y, ePos.Z - myPos.Z
                                    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                                    if dist <= maxDist then
                                        local isAI = (tPawn.bIsAI == true or tPawn.IsAI == true)
                                        if not isAI then
                                            local pState = tPawn.PlayerState
                                            if slua.isValid(pState) and (pState.bIsABot == true or pState.bIsBot == true) then isAI = true end
                                        end
                                        if isAI then aiCount = aiCount + 1 else realCount = realCount + 1 end
                                    end
                                end
                            end
                        end
                    end
                    local total = realCount + aiCount
                    local text = total > 0 and string.format("❮ ENEMY : %d ❯", total) or "❮ AREA CLEAR ❯"
                    pcall(function()
                        MyHUD:AddDebugText(text, localPlayer, 1.05,
                            {X=0,Y=0,Z=150}, {X=0,Y=0,Z=150},
                            Rainbow(), true, false, true, nil, 1.2, true)
                    end)
                end
            end)
        end

        -- ================ AIMBOT ================
        if Config.AimTouchEnable then _G.AimTouch() end

        -- FOV Circle overlay
        if _G.FovCircleOverlay then
            pcall(function() _G.FovCircleOverlay.Update(pc, localPlayer) end)
        end
    end)
end

-- ==============================================================================
-- 14. ИНИЦИАЛИЗАЦИЯ
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
        Notify("SodaLite Loaded Successfully!")
    end
end

local function TickLoop()
    pcall(function()
        TryInit()
        if _initDone then ESPMainLoop() end
    end)
    local okT, ticker = pcall(require, "common.time_ticker")
    if okT and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.1, TickLoop)
    end
end
TickLoop()

-- ==============================================================================
-- 15. LIFECYCLE
-- ==============================================================================
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