-- ==============================================================================
-- SodaLite GLOBAL (BRPlayerCharacterBase) - OPTIMIZED & SMOOTH + ESP/AIMBOT
-- ==============================================================================
-- 1. Исправлено периодическое отключение каждые 8 секунд:
--    - Таймер переведён на рекурсивный AddTimerOnce(0.2, FastTick) без сброса watchdog.
--    - Console-команды и применение Wallhack закешированы (вызываются только при смене
--      состояния, а не спамятся 7 раз в секунду).
--    - Устранено мерцание рендера и перезагрузка буферов движка.
-- 2. Полный ребрендинг: везде прописано SodaLite (в шапке, плавающей кнопке, тостах).
-- 3. Добавлены вкладки ESP и AIMBOT с полным функционалом из pasta.lua
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
local MENU_W = 580
local MENU_H = 620  -- Увеличено для новых вкладок
local ROW_H  = 38
local menuPos = { X = 300, Y = 80 }

local FLOAT_W = 110
local FLOAT_H = 38
local floatPos = { X = 750, Y = 15 }

-- ==============================================================================
-- 2. КОНФИГУРАЦИЯ (SodaLite + pasta.lua)
-- ==============================================================================

-- Основной конфиг SodaLite
local Config = {
    BlackSky     = false,
    Wallhack     = false,
    WallhackGlow = 3,
    IpadView     = false,
    IpadViewFOV  = 120,
    
    AimTouchSpeed = 40,
    AimTouchFOV   = 30,
}

-- Конфиг ESP/Aimbot из pasta.lua
_G.FufuModConfig = _G.FufuModConfig or {
    -- ESP
    EspVip = false,
    EspDistance = false,
    EspVipPro = false,
    EspRadar = false,
    Esp5 = false,
    Esp6 = false,
    Esp8 = false,
    EspAntenna = false,
    EspName = false,
    EspFovCircle = false,
    OutlineThickness = 10,
    
    -- Aimbot
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

    -- ESP Static
    EspStatic = false,
    EspEnemyCount = true,
    EspWeaponStatus = true,
    
    -- Wallhack
    Wallhack = false,
    ColorBodyNew = false,
}

-- Состояние из pasta.lua
_G.FufuModState = _G.FufuModState or {
    LoopToken = 0,
    AimbotLoopToken = 0,
    NativeESPReady = false,
    GraphicsUnlocked = false,
    MenuStep = 0,
    LastCmdTime = 0,
    TrackedMarks = {},
    EnemyMarks = {},
    LastAimbotCheckTime = 0,
    CustomTextData = nil,
    LastAimbotConfigString = "",
    MagicUpdateVersion = 1,
    LastMagicConfigHash = "",
    PrevGraphicsState = {},
    SkinWasApplied = false,
    ConsoleNewWallReady = false,
}

-- Цветовая конфигурация из pasta.lua
if _G.ColorConfig == nil then
    _G.ColorConfig = {
        VisibleColor = 4,
        InvisibleColor = 1,
        Brightness = 25,
        Glow = 3.0,
    }
end

-- Палитра 7 цветов
local COLOR_PALETTE_7 = {
    [1] = {R=255, G=0,   B=0, A=255},   -- Red
    [2] = {R=255, G=255, B=255, A=255}, -- White
    [3] = {R=255, G=255, B=0, A=255},   -- Yellow
    [4] = {R=0,   G=255, B=0, A=255},   -- Green
    [5] = {R=0,   G=255, B=255, A=255}, -- Cyan
    [6] = {R=0,   G=0,   B=255, A=255}, -- Blue
    [7] = {R=255, G=0,   B=255, A=255}, -- Purple
}

local COLOR_MAP = {
    [1] = {R=255, G=0,   B=0},
    [2] = {R=255, G=255, B=255},
    [3] = {R=255, G=255, B=0},
    [4] = {R=0,   G=255, B=0},
    [5] = {R=0,   G=255, B=255},
    [6] = {R=0,   G=0,   B=255},
    [7] = {R=255, G=0,   B=255}
}

local function GetColorBy7(idx)
    if not idx or idx < 1 or idx > 7 then idx = 4 end
    return COLOR_PALETTE_7[idx] or {R=0, G=255, B=0, A=255}
end

local function GetAppliedColor(colorIdx, brightness)
    local base = COLOR_MAP[colorIdx] or COLOR_MAP[4]
    local b = brightness or _G.ColorConfig.Brightness or 25
    return {
        R = math.min(255, (base.R or 0) * b / 25),
        G = math.min(255, (base.G or 0) * b / 25),
        B = math.min(255, (base.B or 0) * b / 25),
        A = 255
    }
end

-- Кэш для ESP
_G.CachedGameplayStatics = nil
_G.CachedActorClass_ForVehicle = nil
_G.CachedVehicleArray = nil
_G.CachedVehicles = nil
_G.LastVehicleScanTime = 0

_G.CachedActorClass_ForBomb = nil
_G.CachedProjArray = nil
_G.CachedActiveThrowables = nil
_G.CachedItemThrowables = nil
_G.LastThrowableScanTime = 0
_G.ActiveThrowableTimers = {}

_G.CachedActorClass_ForLoot = nil
_G.CachedLootArray = nil
_G.CachedLootItems = nil
_G.LastLootScanTime = 0

-- ==============================================================================
-- 3. ХЕЛПЕРЫ
-- ==============================================================================

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
-- 4. ЛОГИКА ИЗ PASTA.LUA (ESP + AIMBOT)
-- ==============================================================================

local _slua = rawget(_G, "slua")
local function Valid(obj)
    if not obj then return false end
    if _slua and _slua.isValid then
        local ok, v = pcall(_slua.isValid, obj)
        if not ok or not v then return false end
    end
    return true
end

-- ===== 7 WARNA UNTUK PILIHAN =====
-- (уже определена выше как COLOR_PALETTE_7)

local C_GREEN = {R=0, G=255, B=0, A=255}
local C_RED = {R=255, G=0, B=0, A=255}
local C_CYAN = {R=0, G=255, B=255, A=255}
local C_YELLOW = {R=255, G=255, B=0, A=255}
local C_WHITE = {R=255, G=255, B=255, A=255}
local C_BLUE_TEXT = {R=0, G=200, B=255, A=255}
local SCALE_COLOR_V2 = {R=3, G=3, B=0, A=0}

-- ==========================================
-- MAP MARK CLEANUP MANAGEMENT FUNCTION
-- ==========================================
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

-- ==========================================
-- UNIQUE ID FOR EACH ENEMY
-- ==========================================
local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

-- ==========================================
-- AI (BOT) / REAL PLAYER
-- ==========================================
local function CheckIsAI(pawn, markData)
    if markData.AK_IS_BOT ~= nil then return markData.AK_IS_BOT, true end
    
    local isAI = false
    local hasChecked = false
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
                isAI = true
                hasChecked = true
            end
        end
    end)
    if hasChecked then markData.AK_IS_BOT = isAI end
    return isAI, hasChecked
end

-- ==========================================
-- WALLHACK / CHAMS ENGINE (V3)
-- ==========================================
local function GetAllSkeletalMeshes(enemy, markData)
    local curTime = os.clock()
    if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime) < 3.0 then
        local validMeshes = {}
        for _, cachedMesh in ipairs(markData.CachedMeshes) do
            if Valid(cachedMesh) then table.insert(validMeshes, cachedMesh) end
        end
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
                    if Valid(comp) and comp ~= enemy.Mesh then
                        table.insert(meshes, comp)
                    end
                end
            end
        end
    end)
    if markData then
        markData.CachedMeshes = meshes
        markData.CachedMeshTime = curTime
    end
    return meshes
end

local function ApplyColorBodyNew(enemy, markData)
    pcall(function()
        if not _G.FufuModState.ConsoleNewWallReady then
            local KismetSystemLibrary = import("KismetSystemLibrary")
            local world = slua.getWorld()
            if KismetSystemLibrary and world then
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.CustomDepth 3")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
                _G.FufuModState.ConsoleNewWallReady = true
            end
        end

        local meshes = GetAllSkeletalMeshes(enemy, markData)
        
        local weapon = nil
        pcall(function() weapon = enemy:GetCurrentWeapon() end)
        if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
            table.insert(meshes, weapon.Mesh)
        end

        local isBot = markData.AK_IS_BOT or false
        local currentMeshCount = #meshes
        local stateHash = (isBot and "BOT" or "PLAYER") .. "_" .. tostring(currentMeshCount)
        
        if markData.LastColorNewHash == stateHash and markData.ColorNewApplied then
            return
        end
        
        markData.LastColorNewHash = stateHash
        markData.ColorNewApplied = true

        local LinearColorClass = import("LinearColor") or _G.FLinearColor
        
        local visibleColorRGB = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness or 25)
        local invisibleColorRGB = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness or 25)
        
        local glowIntensity = _G.ColorConfig.Glow or 3.0
        local visColor = LinearColorClass and LinearColorClass(
            (visibleColorRGB.R/255) * glowIntensity, 
            (visibleColorRGB.G/255) * glowIntensity, 
            (visibleColorRGB.B/255) * glowIntensity, 
            1.0
        ) or {R=visibleColorRGB.R, G=visibleColorRGB.G, B=visibleColorRGB.B, A=255}
        
        local occColor = LinearColorClass and LinearColorClass(
            invisibleColorRGB.R/255, 
            invisibleColorRGB.G/255, 
            invisibleColorRGB.B/255, 
            1.0
        ) or {R=invisibleColorRGB.R, G=invisibleColorRGB.G, B=invisibleColorRGB.B, A=1}
        
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
            if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
                table.insert(meshes, weapon.Mesh)
            end

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

-- ==========================================
-- AIMBOT TARGETING
-- ==========================================
local GameplayData = require("GameLua.GameCore.Data.GameplayData")

_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = GameplayData.GetPlayerCharacter()

    if not slua.isValid(player) then
        return result
    end

    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then
        allCharacters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
    end

    local myTeam = player:GetTeamID()

    for _, actor in pairs(allCharacters) do
        if slua.isValid(actor) and actor ~= player and actor.GetTeamID and actor:IsAlive() then
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

-- ==========================================
-- FOV CIRCLE OVERLAY
-- ==========================================
local SlateBlueprintLibrary = import("SlateBlueprintLibrary")

_G.FovCircleOverlay = {
    Container = nil,
    WidgetSlot = nil,
    ParentCanvas = nil,
    Lines = {},
    NumSegments = 45,
    Thickness = 1.5,
    LastRadius = -1,
    LastColor = -1,
    LastCX = -1,
    LastCY = -1,
    PrecalcMath = nil
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
    if _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then
        return true
    end

    local ParentCanvas = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local MainUI = InGameUITools.GetMainControlBaseUI()
        if slua.isValid(MainUI) then
            if slua.isValid(MainUI.CanvasPanel_0) then
                ParentCanvas = MainUI.CanvasPanel_0
            elseif slua.isValid(MainUI.CanvasPanel_42) then
                ParentCanvas = MainUI.CanvasPanel_42
            end
        end
    end)

    if not ParentCanvas or not slua.isValid(ParentCanvas) then
        return false
    end

    local Container = nil
    pcall(function()
        Container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", ParentCanvas)
    end)
    if not Container or not slua.isValid(Container) then
        return false
    end

    local FVector2D = import("Vector2D") or _G.FVector2D

    for i = 1, _G.FovCircleOverlay.NumSegments do
        local border = nil
        pcall(function()
            border = CGame:NewObjectFromPath("/Script/UMG.Border", Container)
        end)
        if border and slua.isValid(border) then
            pcall(function()
                border.RenderTransformPivot = FVector2D(0, 0.5)
                border:SetRenderTransformPivot(FVector2D(0, 0.5))
                border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local slot = Container:AddChildToCanvas(border)
            if slot then
                pcall(function()
                    slot:SetAlignment(FVector2D(0, 0.5))
                end)
            end
            _G.FovCircleOverlay.Lines[i] = { widget = border, slot = slot }
        end
    end

    local MainSlot = nil
    pcall(function()
        MainSlot = ParentCanvas:AddChildToCanvas(Container)
    end)
    if MainSlot then
        pcall(function()
            MainSlot:SetAutoSize(false)
            MainSlot:SetSize(FVector2D(0, 0))
            MainSlot:SetZOrder(995)
            MainSlot:SetAlignment(FVector2D(0, 0))
            MainSlot:SetPosition(FVector2D(0, 0))
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
            pcall(function()
                _G.FovCircleOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end)
            _G.FovCircleOverlay.LastRadius = -1
        end
        return
    end

    local fovVal = 30
    local colIdx = 7
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

    if not _G.FovCircleOverlay.Create() then
        return
    end

    local ParentCanvas = _G.FovCircleOverlay.ParentCanvas
    if not ParentCanvas or not slua.isValid(ParentCanvas) then
        return
    end

    local scaleX, scaleY, offsetX, offsetY = 1.0, 1.0, 0.0, 0.0
    pcall(function()
        local cg = ParentCanvas:GetCachedGeometry()
        if cg and SlateBlueprintLibrary then
            local FVector2D = import("Vector2D") or _G.FVector2D
            local pt0 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D(0, 0))
            local pt1 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D(100, 100))
            if pt0 and pt1 then
                scaleX = (pt1.X - pt0.X) / 100
                scaleY = (pt1.Y - pt0.Y) / 100
                offsetX = pt0.X
                offsetY = pt0.Y
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
       and math.abs(_G.FovCircleOverlay.LastCY - centerY) < 0.5 then
        return
    end

    _G.FovCircleOverlay.LastRadius = targetRadius
    _G.FovCircleOverlay.LastColor = colIdx
    _G.FovCircleOverlay.LastCX = centerX
    _G.FovCircleOverlay.LastCY = centerY

    pcall(function()
        _G.FovCircleOverlay.Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)

    local FLinearColor = import("LinearColor") or _G.FLinearColor
    local r, g, b = GetFOVColor(colIdx)
    local dim = 0.55
    local color = FLinearColor and FLinearColor(r * dim, g * dim, b * dim, 1.0)
        or {R = r * dim * 255, G = g * dim * 255, B = b * dim * 255, A = 255}

    local numSegments = _G.FovCircleOverlay.NumSegments

    if not _G.FovCircleOverlay.PrecalcMath then
        _G.FovCircleOverlay.PrecalcMath = {}
        local angleStep = 360.0 / numSegments
        local math_cos = math.cos
        local math_sin = math.sin
        local math_rad = math.rad
        local math_atan2 = math.atan2 or math.atan

        for i = 1, numSegments do
            local angle1 = math_rad((i - 1) * angleStep)
            local angle2 = math_rad(i * angleStep)
            local c1, s1 = math_cos(angle1), math_sin(angle1)
            local c2, s2 = math_cos(angle2), math_sin(angle2)
            local dx_unit = c2 - c1
            local dy_unit = s2 - s1
            local dist_unit = math.sqrt(dx_unit * dx_unit + dy_unit * dy_unit)
            local angleDeg = math.deg(math_atan2(dy_unit, dx_unit))
            _G.FovCircleOverlay.PrecalcMath[i] = {
                c1 = c1, s1 = s1,
                dist_unit = dist_unit,
                angleDeg = angleDeg
            }
        end
    end

    pcall(function()
        local FVector2D = import("Vector2D") or _G.FVector2D
        for i = 1, numSegments do
            local mathData = _G.FovCircleOverlay.PrecalcMath[i]
            local x1 = targetRadius * mathData.c1
            local y1 = targetRadius * mathData.s1
            local dist = targetRadius * mathData.dist_unit

            local line = _G.FovCircleOverlay.Lines[i]
            if line and line.slot and slua.isValid(line.slot) then
                line.slot:SetPosition(FVector2D(centerX + x1, centerY + y1))
                line.slot:SetSize(FVector2D(dist + 0.8, _G.FovCircleOverlay.Thickness))
                line.widget:SetRenderAngle(mathData.angleDeg)
                line.widget:SetBrushColor(color)
            end
        end
    end)
end

function _G.CleanUpFovCircleOverlay()
    if _G.FovCircleOverlay and _G.FovCircleOverlay.Container and slua.isValid(_G.FovCircleOverlay.Container) then
        pcall(function()
            _G.FovCircleOverlay.Container:RemoveFromParent()
        end)
        pcall(function()
            _G.FovCircleOverlay.Container:ConditionalBeginDestroy()
        end)
    end
    _G.FovCircleOverlay.Container = nil
    _G.FovCircleOverlay.WidgetSlot = nil
    _G.FovCircleOverlay.ParentCanvas = nil
    _G.FovCircleOverlay.LastRadius = -1
end

-- ==========================================
-- AIMBOT MAIN FUNCTION
-- ==========================================
_G.AimTouch = function()
    pcall(function()
        if not _G.FufuModConfig.AimTouchEnable then return end
        
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end
        
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
        
        if slua.isValid(weapon) then
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
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
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

        if isMortar and _G.FufuModConfig.AimTouchMortar then
            local isPlaced = false
            pcall(function()
                if weapon and weapon.MortarState == 2 then isPlaced = true end
            end)
            if not isPlaced then return end

            cond = 2
            prioMode = 1
            boneIdx = 4
            speedVal = 100
            fovVal = _G.FufuModState.CustomTextData.AimTouchMortarFOV or 360
            maxDistMeters = 2000
            useVisCheck = false
            igKnock = false
            igBot = false
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
        
        local FVector2D = import("Vector2D")
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
        
        local bestTarget = nil
        local bestScore = 99999999 
        
        local selBoneName = "head"
        if boneIdx == 1 then selBoneName = "head"
        elseif boneIdx == 2 then selBoneName = "spine_03"
        elseif boneIdx == 3 then selBoneName = "spine_01"
        elseif boneIdx == 4 then selBoneName = "pelvis" end

        for i, target in ipairs(enemies) do
            if not slua.isValid(target) then goto continue end
            
            pcall(function()
                if slua.isValid(target.Mesh) then
                    target.Mesh.MeshComponentUpdateFlag = 0
                end
            end)
            
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
        
        if not slua.isValid(bestTarget) then return end
        
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
                    if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then 
                        currentWep:StartFire() 
                    end
                    _G.FufuModState.IsAutoFiring = true
                end
            end)
        end

    end)
end

-- ==============================================================================
-- 5. UMG ВИДЖЕТЫ: ЧЕКБОКС И СЛАЙДЕР (SodaLite)
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

local function DrawCheckbox(parent, x, y, w, label, configKey, configTable)
    local h = ROW_H
    local cfg = configTable or Config
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y + h - 1, w, 1, FLinearColor(0.2, 0.25, 0.35, 0.4), 11)

    Text(parent, label, x + 16, y + h * 0.5, 12, Colors.text_white, 15, 0.0, 0.5)

    local toggleW, toggleH = 46, 22
    local toggleX = x + w - toggleW - 14
    local toggleY = y + (h - toggleH) * 0.5

    local track = Layer(parent, toggleX, toggleY, toggleW, toggleH, 
        cfg[configKey] and Colors.toggle_on or Colors.toggle_off, 12)

    local knobSize = 18
    local knobOffset = cfg[configKey] and (toggleW - knobSize - 2) or 2
    local knob = Layer(parent, toggleX + knobOffset, toggleY + 2, knobSize, knobSize, Colors.toggle_knob, 14)

    MakeBtn(parent, x, y, w, h, 20, function()
        cfg[configKey] = not cfg[configKey]
        local isEnabled = cfg[configKey]

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
    local cfg = configTable or Config
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y + h - 1, w, 1, FLinearColor(0.2, 0.25, 0.35, 0.4), 11)

    Text(parent, label, x + 16, y + h * 0.5, 12, Colors.text_white, 15, 0.0, 0.5)

    local valText = Text(parent, tostring(cfg[configKey]), x + w - 120, y + h * 0.5, 12, Colors.accent_blue, 15, 1.0, 0.5)

    local btnW = 28
    local btnMinusX = x + w - 85
    local btnPlusX  = x + w - 40
    local btnY      = y + (h - 26) * 0.5

    Layer(parent, btnMinusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "-", btnMinusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnMinusX, btnY, btnW, 26, 20, function()
        if cfg[configKey] > minVal then
            cfg[configKey] = cfg[configKey] - 1
            if IsValid(valText) then valText:SetText(tostring(cfg[configKey])) end
        end
    end)

    Layer(parent, btnPlusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "+", btnPlusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnPlusX, btnY, btnW, 26, 20, function()
        if cfg[configKey] < maxVal then
            cfg[configKey] = cfg[configKey] + 1
            if IsValid(valText) then valText:SetText(tostring(cfg[configKey])) end
        end
    end)
end

-- ==============================================================================
-- 6. ОТРИСОВКА МЕНЮ SODALITE С ВКЛАДКАМИ ESP И AIMBOT
-- ==============================================================================
local currentTab = "VISUALS"
local bgPanel = nil
local floatItem = nil
local contentContainer = nil
local parentCanvas = nil
local isMenuOpen = false

local function RenderContent()
    if not IsValid(contentContainer) then return end
    contentContainer:ClearChildren()

    local startY = 10
    local colW = MENU_W - 32

    if currentTab == "VISUALS" then
        DrawCheckbox(contentContainer, 16, startY, colW, "Black Sky (Чёрное небо)", "BlackSky")
        DrawCheckbox(contentContainer, 16, startY + 44, colW, "Wallhack (Chams / Сквозь стены)", "Wallhack")
        DrawSlider(contentContainer, 16, startY + 88, colW, "   > Яркость Wallhack Glow (1-10)", "WallhackGlow", 1, 10)
        DrawCheckbox(contentContainer, 16, startY + 132, colW, "IPad View (Отдаление камеры)", "IpadView")
        DrawSlider(contentContainer, 16, startY + 176, colW, "   > Угол обзора FOV (90-140)", "IpadViewFOV", 90, 140)
        
    elseif currentTab == "ESP" then
        -- ESP Visual
        DrawCheckbox(contentContainer, 16, startY, colW, "ESP AUTO (normal esp)", "EspVip", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 44, colW, "ESP METER (dist)", "EspDistance", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 88, colW, "HEALTH V1", "EspVipPro", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 132, colW, "ESP MARK (radar)", "EspRadar", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 176, colW, "ESP BOX FRAME", "Esp5", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 220, colW, "ESP HEAD", "Esp6", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 264, colW, "ESP HEALTH V2", "Esp8", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 308, colW, "ESP LINE ANTENA", "EspAntenna", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 352, colW, "ESP NAME", "EspName", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 396, colW, "ESP FOV CIRCLE", "EspFovCircle", _G.FufuModConfig)
        
        -- ESP Vehicle
        DrawCheckbox(contentContainer, 16, startY + 440, colW, "ESP VEHICLE", "VehicleEnabled", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 484, colW, "   > Dacia", "VehicleShowDacia", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 528, colW, "   > UAZ", "VehicleShowUAZ", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 572, colW, "   > Buggy", "VehicleShowBuggy", _G.FufuModConfig)
        
    elseif currentTab == "AIMBOT" then
        -- Aimbot Main
        DrawCheckbox(contentContainer, 16, startY, colW, "ENABLE AIMBOT (Royal & Custom)", "AimTouchEnable", _G.FufuModConfig)
        
        -- Hipfire
        DrawCheckbox(contentContainer, 16, startY + 44, colW, "Hipfire Aimbot (No Scope)", "AimTouchHipfire", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 88, colW, "   > Ignore Knocked", "AimTouchHipIgKnock", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 132, colW, "   > Ignore Bots", "AimTouchHipIgBot", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 176, colW, "   > Visibility Check", "AimTouchHipVisCheck", _G.FufuModConfig)
        DrawSlider(contentContainer, 16, startY + 220, colW, "   > Speed (1-100)", "AimTouchHipSpeed", 1, 100, _G.FufuModState.CustomTextData)
        DrawSlider(contentContainer, 16, startY + 264, colW, "   > FOV (1-100)", "AimTouchHipFOV", 1, 100, _G.FufuModState.CustomTextData)
        DrawSlider(contentContainer, 16, startY + 308, colW, "   > Distance (1-500m)", "AimTouchHipDist", 1, 500, _G.FufuModState.CustomTextData)
        
        -- Shotgun
        DrawCheckbox(contentContainer, 16, startY + 352, colW, "Shotgun Aimbot", "AimTouchSG", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 396, colW, "   > Auto Fire", "AimTouchSGAutoFire", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 440, colW, "   > Ignore Knocked", "AimTouchSGIgKnock", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 484, colW, "   > Ignore Bots", "AimTouchSGIgBot", _G.FufuModConfig)
        
        -- Scope All
        DrawCheckbox(contentContainer, 16, startY + 528, colW, "Scoped Aimbot (All Weapons)", "AimTouchScopeAll", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 572, colW, "   > Ignore Knocked", "AimTouchScopeIgKnock", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 616, colW, "   > Ignore Bots", "AimTouchScopeIgBot", _G.FufuModConfig)
        
        -- Sniper
        DrawCheckbox(contentContainer, 16, startY + 660, colW, "Scoped Aimbot (Sniper Only)", "AimTouchScopeSniper", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 704, colW, "   > Ignore Knocked", "AimTouchSniperIgKnock", _G.FufuModConfig)
        DrawCheckbox(contentContainer, 16, startY + 748, colW, "   > Ignore Bots", "AimTouchSniperIgBot", _G.FufuModConfig)
        
        -- Mortar
        DrawCheckbox(contentContainer, 16, startY + 792, colW, "Mortar Aimbot", "AimTouchMortar", _G.FufuModConfig)
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

    -- Вкладки (4 штуки)
    local tabY = HEADER_H + 8
    local tabW = 130
    local tabH = 32
    local tabGap = 8

    -- VISUALS
    Layer(bgPanel, 16, tabY, tabW, tabH, Colors.bg_row, 5)
    Text(bgPanel, "VISUALS", 16 + tabW * 0.5, tabY + tabH * 0.5, 11, Colors.text_white, 6, 0.5, 0.5)
    MakeBtn(bgPanel, 16, tabY, tabW, tabH, 20, function()
        currentTab = "VISUALS"
        RenderContent()
    end)

    -- ESP
    Layer(bgPanel, 16 + tabW + tabGap, tabY, tabW, tabH, Colors.bg_row, 5)
    Text(bgPanel, "ESP", 16 + tabW + tabGap + tabW * 0.5, tabY + tabH * 0.5, 11, Colors.text_white, 6, 0.5, 0.5)
    MakeBtn(bgPanel, 16 + tabW + tabGap, tabY, tabW, tabH, 20, function()
        currentTab = "ESP"
        RenderContent()
    end)

    -- AIMBOT
    Layer(bgPanel, 16 + (tabW + tabGap) * 2, tabY, tabW, tabH, Colors.bg_row, 5)
    Text(bgPanel, "AIMBOT", 16 + (tabW + tabGap) * 2 + tabW * 0.5, tabY + tabH * 0.5, 11, Colors.text_white, 6, 0.5, 0.5)
    MakeBtn(bgPanel, 16 + (tabW + tabGap) * 2, tabY, tabW, tabH, 20, function()
        currentTab = "AIMBOT"
        RenderContent()
    end)

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
-- 7. ПЛАВАЮЩАЯ КНОПКА SODALITE
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
-- 8. ОБНОВЛЕНИЕ ЛОГИКИ (из SodaLite + pasta.lua)
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

-- 2. IPAD VIEW
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

-- 3. WALLHACK / CHAMS
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
                        local markData = _G.FufuModState.EnemyMarks[GetSafeEnemyKey(enemy)] or {}
                        ApplyColorBodyNew(enemy, markData)
                        _wallhackApplied[enemy] = true
                    end
                end
            end
        else
            if _prevWallhackState then
                _prevWallhackState = false
                for _, enemy in pairs(allCharacters) do
                    if IsValid(enemy) and enemy ~= localPlayer then
                        local markData = _G.FufuModState.EnemyMarks[GetSafeEnemyKey(enemy)] or {}
                        UndoColorBodyNew(enemy, markData)
                    end
                end
                _wallhackApplied = {}
            end
        end
    end)
end

-- ==============================================================================
-- 9. ГЛАВНЫЙ ЦИКЛ (SodaLite + ESP/Aimbot из pasta.lua)
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

        if not IsValid(localPlayer) then return end

        -- Инициализация CustomTextData если нужно
        if _G.FufuModState.CustomTextData == nil then
            _G.FufuModState.CustomTextData = {
                AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1, AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250,
                AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1, AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30,
                AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1, AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300,
                AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2, AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400,
                AimTouchMortarPred = 0, AimTouchMortarFOV = 360,
                AimTouchHipFOVColor = 7, AimTouchSGFOVColor = 1, AimTouchScopeFOVColor = 6, AimTouchSniperFOVColor = 4, AimTouchMortarFOVColor = 5,
            }
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

        -- 4. ESP System (из pasta.lua)
        pcall(function()
            local GameplayData = require("GameLua.GameCore.Data.GameplayData")
            local allCharacters = {}
            if GameplayData.GetAllPlayerCharacters then
                allCharacters = GameplayData.GetAllPlayerCharacters()
            elseif GameplayData.GameCharacters then
                for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
            end

            local Cached_MyHUD = pc and pc.MyHUD or nil

            -- ESP logic from pasta.lua (simplified for loop)
            for _, enemy in pairs(allCharacters) do
                if Valid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                    local eKey = GetSafeEnemyKey(enemy)
                    _G.FufuModState.EnemyMarks[eKey] = _G.FufuModState.EnemyMarks[eKey] or { enemy = enemy }
                    local markData = _G.FufuModState.EnemyMarks[eKey]
                    markData.enemy = enemy

                    -- Wallhack / Chams
                    if _G.FufuModConfig.ColorBodyNew or _G.FufuModConfig.Wallhack then
                        ApplyColorBodyNew(enemy, markData)
                        markData.WallhackApplied = true
                    else
                        UndoColorBodyNew(enemy, markData)
                        markData.WallhackApplied = false
                    end

                    -- ESP Health / Name / Distance
                    if Cached_MyHUD and Cached_MyHUD.AddDebugText then
                        local distM = 0
                        pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)

                        if _G.FufuModConfig.EspVipPro and distM <= 400 then
                            local hp = enemy.Health or 100
                            local maxHp = enemy.HealthMax or 100
                            local isKnock = (hp <= 0 or enemy.HealthStatus == 1)
                            local hpPercent = isKnock and 0 or (hp / maxHp)
                            local pctValue = math.floor(hpPercent * 100 + 0.5)

                            local pName = ""
                            if _G.FufuModConfig.EspName then
                                pName = enemy.PlayerName or enemy.PlayerNamePublic or "Enemy"
                            end

                            local bIsVisible = false
                            if pc and type(pc.LineOfSightTo) == "function" then
                                bIsVisible = pc:LineOfSightTo(enemy)
                            end

                            local visibleCol = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness)
                            local invisibleCol = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness)
                            
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

                            Cached_MyHUD:AddDebugText(label, enemy, 0.2, {X=0, Y=0, Z=120}, {X=0, Y=0, Z=120},
                                             textColor, true, false, true, nil, 1.0, true)
                        end

                        if _G.FufuModConfig.EspDistance and distM <= 400 then
                            local distMeters = math.floor(distM + 0.5)
                            local rangeColor = {R=255, G=255, B=255, A=255}
                            Cached_MyHUD:AddDebugText(string.format("%.0fm", distMeters), enemy, 0.3,
                                             {X=15, Y=15, Z=-15}, {X=15, Y=15, Z=-15},
                                             rangeColor, true, false, true, nil, 0.9, true)
                        end

                        if _G.FufuModConfig.EspName and not _G.FufuModConfig.EspVipPro and distM <= 400 then
                            local pName = enemy.PlayerName or enemy.PlayerNamePublic or "Enemy"
                            if pName ~= "" then
                                local isKnock = (enemy.Health or 100) <= 0 or enemy.HealthStatus == 1
                                local bIsVisible = true
                                pcall(function()
                                    if pc and type(pc.LineOfSightTo) == "function" then
                                        bIsVisible = pc:LineOfSightTo(enemy)
                                    end
                                end)

                                local visibleCol = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness)
                                local invisibleCol = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness)
                                
                                local nameColor = {R=255, G=255, B=255, A=255}
                                if isKnock then
                                    nameColor = {R=0, G=0, B=255, A=255}
                                else
                                    nameColor = bIsVisible and visibleCol or invisibleCol
                                end

                                Cached_MyHUD:AddDebugText(pName, enemy, 0.2, {X=0, Y=0, Z=120}, {X=0, Y=0, Z=120},
                                                 nameColor, true, false, true, nil, 1.0, true)
                            end
                        end
                    end

                    -- ESP Mark / Radar
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
                            SafeRemoveMark(markData.radarMark)
                            markData.radarMark = nil
                        end
                    end

                    if _G.FufuModConfig.EspAntenna then
                        pcall(function()
                            if Cached_MyHUD and distM <= 400 then
                                local loopCount = 8  
                                local zStep = 1000     
                                local baseZ = 105     
                                local topZ = baseZ + (loopCount * zStep)
                                for i = 1, loopCount do
                                    local zOffset = baseZ + (i * zStep)
                                    Cached_MyHUD:AddDebugText("|", enemy, 0.06,
                                        {X=0, Y=0, Z=zOffset}, {X=0, Y=0, Z=zOffset},
                                        C_GREEN, true, false, true, nil, 1.2, true)
                                end
                                Cached_MyHUD:AddDebugText("I", enemy, 0.06,
                                        {X=0, Y=0, Z=topZ + 60}, {X=0, Y=0, Z=topZ + 60},
                                        C_GREEN, true, false, true, nil, 1.5, true)
                            end
                        end)
                    end

                    if _G.FufuModConfig.Esp6 then
                        pcall(function()
                            if Cached_MyHUD and distM <= 250 then
                                local eMesh = enemy.Mesh
                                if Valid(eMesh) then
                                    local headPos = eMesh:GetSocketLocation("head")
                                    if headPos then
                                        local bIsVisible = true
                                        if pc and type(pc.LineOfSightTo) == "function" then
                                            bIsVisible = pc:LineOfSightTo(enemy)
                                        end
                                        local visibleCol = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness or 25)
                                        local invisibleCol = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness or 25)
                                        local headColor = bIsVisible and visibleCol or invisibleCol
                                        Cached_MyHUD:AddDebugText("●", enemy, 0.2, {X=0, Y=0, Z=90}, {X=0, Y=0, Z=90},
                                                         headColor, true, false, true, nil, 0.9, true)
                                    end
                                end
                            end
                        end)
                    end

                    -- ESP Frame UI
                    local showFrameUI = _G.FufuModConfig.Esp5 or _G.FufuModConfig.EspVipPro or _G.FufuModConfig.EspVip
                    if showFrameUI then
                        pcall(function()
                            if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then enemy:Replay_CreateEnemyFrameUI(true, true) end
                            if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                            if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio) end
                            
                            local uiComp = enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI) == "function" and enemy:GetEnemyFrameUI())
                            if Valid(uiComp) then
                                if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(0) end
                                if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(false) end
                            end
                        end)
                    end
                end
            end
        end)

        -- 5. Aimbot
        if _G.FufuModConfig.AimTouchEnable then
            _G.AimTouch()
        end

        -- 6. FOV Circle
        if _G.FovCircleOverlay then
            pcall(function() _G.FovCircleOverlay.Update(pc, localPlayer) end)
        end

        -- 7. ESP Static (Enemy Count + Weapon Status)
        if _G.FufuModConfig.EspStatic then
            pcall(function()
                local Cached_MyHUD = pc and pc.MyHUD or nil
                if not Valid(Cached_MyHUD) then return end

                if _G.FufuModConfig.EspEnemyCount then
                    local function GetRainbowColor()
                        local time = os.clock()
                        local r = math.sin(time * 0.8) * 0.5 + 0.5
                        local g = math.sin(time * 0.8 + 2.094) * 0.5 + 0.5
                        local b = math.sin(time * 0.8 + 4.188) * 0.5 + 0.5
                        return { R = math.floor(r * 255), G = math.floor(g * 255), B = math.floor(b * 255), A = 255 }
                    end

                    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                    local allCharacters = {}
                    if GameplayData.GetAllPlayerCharacters then
                        allCharacters = GameplayData.GetAllPlayerCharacters()
                    elseif GameplayData.GameCharacters then
                        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
                    end

                    local myTeamId = localPlayer.TeamID or localPlayer:GetTeamID() or 0
                    local myPos = localPlayer:K2_GetActorLocation()
                    local maxDist = 35000
                    local totalEnemy = 0

                    for _, tPawn in pairs(allCharacters) do
                        if slua.isValid(tPawn) and tPawn ~= localPlayer then
                            local targetTeamId = tPawn.TeamID or tPawn:GetTeamID() or 0
                            if targetTeamId ~= myTeamId then
                                local enemyPos = tPawn:K2_GetActorLocation()
                                if enemyPos then
                                    local dx = enemyPos.X - myPos.X
                                    local dy = enemyPos.Y - myPos.Y
                                    local dz = enemyPos.Z - myPos.Z
                                    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                                    if dist <= maxDist then
                                        totalEnemy = totalEnemy + 1
                                    end
                                end
                            end
                        end
                    end

                    local color = GetRainbowColor()
                    local text = totalEnemy > 0 and string.format("❮ ENEMY : %d ❯", totalEnemy) or " ❮ AREA 350M CLEAR ❯"
                    Cached_MyHUD:AddDebugText(text, localPlayer, 1.05, {X=0, Y=0, Z=150}, {X=0, Y=0, Z=150}, color, true, false, true, nil, 1.2, true)
                end
            end)
        end
    end)

    -- Рекурсивный перезапуск через 0.15 сек
    local okT, ticker = pcall(require, "common.time_ticker")
    if okT and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.15, CheatWorker)
    end
end

-- ==============================================================================
-- 10. ИНИЦИАЛИЗАЦИЯ
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