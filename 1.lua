-- ==============================================================================
-- SodaLite GLOBAL (BRPlayerCharacterBase) - OPTIMIZED & SMOOTH
-- ==============================================================================
-- 1. Исправлено периодическое отключение каждые 8 секунд:
--    - Таймер переведён на рекурсивный AddTimerOnce(0.2, FastTick) без сброса watchdog.
--    - Console-команды и применение Wallhack закешированы (вызываются только при смене
--      состояния, а не спамятся 7 раз в секунду).
--    - Устранено мерцание рендера и перезагрузка буферов движка.
-- 2. Полный ребрендинг: везде прописано SodaLite (в шапке, плавающей кнопке, тостах).
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
local MENU_H = 420
local ROW_H  = 38
local menuPos = { X = 300, Y = 120 }

local FLOAT_W = 110
local FLOAT_H = 38
local floatPos = { X = 750, Y = 15 }

-- Настройки функций
local Config = {
    BlackSky     = false,
    Wallhack     = false,
    WallhackGlow = 3,
    IpadView     = false,
    IpadViewFOV  = 120,
    
    AimTouchSpeed = 40,
    AimTouchFOV   = 30,
}

local currentTab = "VISUALS"
local bgPanel = nil
local floatItem = nil
local contentContainer = nil
local parentCanvas = nil
local isMenuOpen = false

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
-- 4. UMG ВИДЖЕТЫ: ЧЕКБОКС И СЛАЙДЕР
-- ==============================================================================
local function DrawCheckbox(parent, x, y, w, label, configKey)
    local h = ROW_H
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y + h - 1, w, 1, FLinearColor(0.2, 0.25, 0.35, 0.4), 11)

    Text(parent, label, x + 16, y + h * 0.5, 12, Colors.text_white, 15, 0.0, 0.5)

    local toggleW, toggleH = 46, 22
    local toggleX = x + w - toggleW - 14
    local toggleY = y + (h - toggleH) * 0.5

    local track = Layer(parent, toggleX, toggleY, toggleW, toggleH, 
        Config[configKey] and Colors.toggle_on or Colors.toggle_off, 12)

    local knobSize = 18
    local knobOffset = Config[configKey] and (toggleW - knobSize - 2) or 2
    local knob = Layer(parent, toggleX + knobOffset, toggleY + 2, knobSize, knobSize, Colors.toggle_knob, 14)

    MakeBtn(parent, x, y, w, h, 20, function()
        Config[configKey] = not Config[configKey]
        local isEnabled = Config[configKey]

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

local function DrawSlider(parent, x, y, w, label, configKey, minVal, maxVal)
    local h = ROW_H
    Layer(parent, x, y, w, h, Colors.bg_row, 10)
    Layer(parent, x, y + h - 1, w, 1, FLinearColor(0.2, 0.25, 0.35, 0.4), 11)

    Text(parent, label, x + 16, y + h * 0.5, 12, Colors.text_white, 15, 0.0, 0.5)

    local valText = Text(parent, tostring(Config[configKey]), x + w - 120, y + h * 0.5, 12, Colors.accent_blue, 15, 1.0, 0.5)

    local btnW = 28
    local btnMinusX = x + w - 85
    local btnPlusX  = x + w - 40
    local btnY      = y + (h - 26) * 0.5

    Layer(parent, btnMinusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "-", btnMinusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnMinusX, btnY, btnW, 26, 20, function()
        if Config[configKey] > minVal then
            Config[configKey] = Config[configKey] - 1
            if IsValid(valText) then valText:SetText(tostring(Config[configKey])) end
        end
    end)

    Layer(parent, btnPlusX, btnY, btnW, 26, Colors.slider_bg, 12)
    Text(parent, "+", btnPlusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    MakeBtn(parent, btnPlusX, btnY, btnW, 26, 20, function()
        if Config[configKey] < maxVal then
            Config[configKey] = Config[configKey] + 1
            if IsValid(valText) then valText:SetText(tostring(Config[configKey])) end
        end
    end)
end

-- ==============================================================================
-- 5. ОТРИСОВКА МЕНЮ SODALITE
-- ==============================================================================
local function RenderContent()
    if not IsValid(contentContainer) then return end
    contentContainer:ClearChildren()

    local startY = 10
    local colW = MENU_W - 32

    if currentTab == "VISUALS" then
        -- 1. BlackSky
        DrawCheckbox(contentContainer, 16, startY, colW, "Black Sky (Чёрное небо)", "BlackSky")
        
        -- 2. Wallhack + Настройка Glow
        DrawCheckbox(contentContainer, 16, startY + 44, colW, "Wallhack (Chams / Сквозь стены)", "Wallhack")
        DrawSlider(contentContainer, 16, startY + 88, colW, "   > Яркость Wallhack Glow (1-10)", "WallhackGlow", 1, 10)
        
        -- 3. IPad View + Настройка FOV
        DrawCheckbox(contentContainer, 16, startY + 132, colW, "IPad View (Отдаление камеры)", "IpadView")
        DrawSlider(contentContainer, 16, startY + 176, colW, "   > Угол обзора FOV (90-140)", "IpadViewFOV", 90, 140)
    elseif currentTab == "AIMBOT" then
        DrawSlider(contentContainer, 16, startY, colW, "Aim Touch Speed", "AimTouchSpeed", 10, 100)
        DrawSlider(contentContainer, 16, startY + 44, colW, "Aim Touch FOV", "AimTouchFOV", 10, 100)
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
    local tabW = 120
    local tabH = 32

    Layer(bgPanel, 16, tabY, tabW, tabH, Colors.bg_row, 5)
    Text(bgPanel, "VISUALS", 16 + tabW * 0.5, tabY + tabH * 0.5, 11, Colors.text_white, 6, 0.5, 0.5)
    MakeBtn(bgPanel, 16, tabY, tabW, tabH, 20, function()
        currentTab = "VISUALS"
        RenderContent()
    end)

    Layer(bgPanel, 16 + tabW + 8, tabY, tabW, tabH, Colors.bg_row, 5)
    Text(bgPanel, "AIMBOT", 16 + tabW + 8 + tabW * 0.5, tabY + tabH * 0.5, 11, Colors.text_white, 6, 0.5, 0.5)
    MakeBtn(bgPanel, 16 + tabW + 8, tabY, tabW, tabH, 20, function()
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
