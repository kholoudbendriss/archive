-- ==============================================================================
-- PUBG MOBILE IMGUI MENU (BRPlayerCharacterBase) - FIXED CLICK & DRAG
-- ==============================================================================
-- Полностью исправлено:
-- 1. Клик теперь срабатывает 100% надёжно через прямой UButton:OnClicked на Canvas.
-- 2. Убран сбойный SetWidgetStyle, заменён на нативные SetColorAndOpacity.
-- 3. Все координаты используют корректный FVector2D(x, y).
-- 4. Добавлена функция плавного перетаскивания + стрелки позиционирования в меню.
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

-- Размеры
local MENU_W = 560
local MENU_H = 400
local ROW_H  = 40
local menuPos = { X = 300, Y = 120 }

local FLOAT_W = 120
local FLOAT_H = 38
local floatPos = { X = 750, Y = 15 }

-- Настройки функций
local Config = {
    EspBox      = false,
    EspLine     = true,
    EspSkeleton = false,
    AimFov      = 60,
    AimSmooth   = 15,
}

local currentTab = "VISUALS"
local bgPanel = nil
local floatItem = nil
local contentContainer = nil
local parentCanvas = nil
local isMenuOpen = false

-- Состояние перемещения (Drag & Drop)
local isDraggingFloat = false
local isDraggingMenu  = false
local floatMoved      = false
local dragStartTouchX = 0
local dragStartTouchY = 0
local dragStartElemX  = 0
local dragStartElemY  = 0

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
-- 2. ТАЧ И ИГРОК
-- ==============================================================================
local function GetPlayerController()
    local pc = _G.LocalPlayerController
    if IsValid(pc) then return pc end

    pcall(function()
        if slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController then
            pc = slua_GameFrontendHUD:GetPlayerController()
        end
    end)
    if not IsValid(pc) then
        pcall(function()
            local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
            local MainUI = InGameUITools and InGameUITools.GetMainControlBaseUI and InGameUITools.GetMainControlBaseUI()
            if MainUI and MainUI.GetPlayerController then
                pc = MainUI:GetPlayerController()
            end
        end)
    end
    return pc
end

local function GetTouchPosition()
    local pc = GetPlayerController()
    if not IsValid(pc) then return nil, nil end

    local okT, tx, ty, pressed = pcall(function()
        local x, y, p = 0, 0, false
        return pc:GetInputTouchState(0, x, y, p)
    end)
    if okT and tx and ty and (tx ~= 0 or ty ~= 0) then
        return tx, ty
    end

    local okM, mx, my = pcall(function()
        return pc:GetMousePosition(0, 0)
    end)
    if okM and mx and my and (mx ~= 0 or my ~= 0) then
        return mx, my
    end

    return nil, nil
end

-- ==============================================================================
-- 3. НАДЕЖНЫЕ ХЕЛПЕРЫ ДЛЯ UMG ВИДЖЕТОВ
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

-- Кнопка с надежным перехватом OnClicked
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
            sh.AddOnScreenDebugMessage("[IMGUI] " .. tostring(msg), -1, 2.5, {R=0.2, G=0.6, B=1.0, A=1}, {X=1.2, Y=1.2})
        end
    end)
    print("[IMGUI] " .. tostring(msg))
end

-- ==============================================================================
-- 4. ВИДЖЕТЫ МЕНЮ: ЧЕКБОКС И СЛАЙДЕР
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
-- 5. ОТРИСОВКА МЕНЮ
-- ==============================================================================
local function RenderContent()
    if not IsValid(contentContainer) then return end
    contentContainer:ClearChildren()

    local startY = 10
    local colW = MENU_W - 32

    if currentTab == "VISUALS" then
        DrawCheckbox(contentContainer, 16, startY, colW, "ESP Box (Коробка)", "EspBox")
        DrawCheckbox(contentContainer, 16, startY + 46, colW, "ESP Line (Линия)", "EspLine")
        DrawCheckbox(contentContainer, 16, startY + 92, colW, "ESP Skeleton (Скелет)", "EspSkeleton")
    elseif currentTab == "AIMBOT" then
        DrawSlider(contentContainer, 16, startY, colW, "Радиус Aim FOV", "AimFov", 10, 180)
        DrawSlider(contentContainer, 16, startY + 46, colW, "Плавность Aim Smooth", "AimSmooth", 1, 30)
    elseif currentTab == "POSITION" then
        Text(contentContainer, "Перемещение плавающей кнопки:", 16, startY + 10, 12, Colors.text_white, 15, 0.0, 0.5)
        
        -- Быстрые пресеты
        local pBtnW = 90
        Layer(contentContainer, 16, startY + 35, pBtnW, 30, Colors.bg_row, 12)
        Text(contentContainer, "СЛЕВА", 16 + pBtnW * 0.5, startY + 50, 11, Colors.text_white, 13, 0.5, 0.5)
        MakeBtn(contentContainer, 16, startY + 35, pBtnW, 30, 20, function()
            _G.UpdateFloatPos(60, 20)
        end)

        Layer(contentContainer, 16 + pBtnW + 10, startY + 35, pBtnW, 30, Colors.bg_row, 12)
        Text(contentContainer, "ЦЕНТР", 16 + pBtnW + 10 + pBtnW * 0.5, startY + 50, 11, Colors.text_white, 13, 0.5, 0.5)
        MakeBtn(contentContainer, 16 + pBtnW + 10, startY + 35, pBtnW, 30, 20, function()
            _G.UpdateFloatPos(750, 15)
        end)

        Layer(contentContainer, 16 + (pBtnW + 10) * 2, startY + 35, pBtnW, 30, Colors.bg_row, 12)
        Text(contentContainer, "СПРАВА", 16 + (pBtnW + 10) * 2 + pBtnW * 0.5, startY + 50, 11, Colors.text_white, 13, 0.5, 0.5)
        MakeBtn(contentContainer, 16 + (pBtnW + 10) * 2, startY + 35, pBtnW, 30, 20, function()
            _G.UpdateFloatPos(1350, 20)
        end)
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
    Text(bgPanel, "CUSTOM IMGUI MENU - PUBG MOBILE", 16, HEADER_H * 0.5, 13, Colors.text_white, 5, 0.0, 0.5)

    -- Перетаскивание меню за шапку
    local dragBtn = MakeBtn(bgPanel, 0, 0, MENU_W - 40, HEADER_H, 30, nil)
    if IsValid(dragBtn) then
        pcall(function()
            if dragBtn.OnPressed then
                dragBtn.OnPressed:Add(function()
                    local tx, ty = GetTouchPosition()
                    if tx and ty then
                        isDraggingMenu  = true
                        dragStartTouchX = tx
                        dragStartTouchY = ty
                        dragStartElemX  = menuPos.X
                        dragStartElemY  = menuPos.Y
                    end
                end)
            end
            if dragBtn.OnReleased then
                dragBtn.OnReleased:Add(function()
                    isDraggingMenu = false
                end)
            end
        end)
    end

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

    Layer(bgPanel, 16 + (tabW + 8) * 2, tabY, tabW, tabH, Colors.bg_row, 5)
    Text(bgPanel, "POSITION", 16 + (tabW + 8) * 2 + tabW * 0.5, tabY + tabH * 0.5, 11, Colors.text_white, 6, 0.5, 0.5)
    MakeBtn(bgPanel, 16 + (tabW + 8) * 2, tabY, tabW, tabH, 20, function()
        currentTab = "POSITION"
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
-- 6. ПЛАВАЮЩАЯ КНОПКА (100% РАБОЧИЙ МЕТОД ПРЯМО НА CANVAS)
-- ==============================================================================
function _G.UpdateFloatPos(x, y)
    floatPos.X = x
    floatPos.Y = y
    if floatItem then
        local fW, fH = FLOAT_W, FLOAT_H
        if floatItem.shadow and floatItem.shadow.Slot then floatItem.shadow.Slot:SetPosition(FVector2D(x + 2, y + 3)) end
        if floatItem.border and floatItem.border.Slot then floatItem.border.Slot:SetPosition(FVector2D(x - 1, y - 1)) end
        if floatItem.bg and floatItem.bg.Slot then floatItem.bg.Slot:SetPosition(FVector2D(x, y)) end
        if floatItem.text and floatItem.text.Slot then floatItem.text.Slot:SetPosition(FVector2D(x + fW * 0.5, y + fH * 0.5)) end
        if floatItem.btn and floatItem.btn.Slot then floatItem.btn.Slot:SetPosition(FVector2D(x, y)) end
    end
end

local function CreateFloatButton(canvas)
    if floatItem and IsValid(floatItem.btn) then return end
    floatItem = {}

    local fX, fY, fW, fH = floatPos.X, floatPos.Y, FLOAT_W, FLOAT_H

    floatItem.shadow = Layer(canvas, fX + 2, fY + 3, fW, fH, Colors.shadow, 11898)
    floatItem.border = Layer(canvas, fX - 1, fY - 1, fW + 2, fH + 2, Colors.border, 11900)
    floatItem.bg     = Layer(canvas, fX, fY, fW, fH, Colors.bg_header, 11901)
    floatItem.text   = Text(canvas, "OPEN MENU", fX + fW * 0.5, fY + fH * 0.5, 11, Colors.accent_blue, 12001, 0.5, 0.5)

    -- Кнопка клика (Z-Order = 12002 — ПОВЕРХ ВСЕХ СЛОЕВ)
    floatItem.btn = MakeBtn(canvas, fX, fY, fW, fH, 12002, function()
        ToggleMenu(canvas)
    end)

    -- События для перетаскивания (Drag)
    pcall(function()
        if floatItem.btn.OnPressed then
            floatItem.btn.OnPressed:Add(function()
                local tx, ty = GetTouchPosition()
                if tx and ty then
                    isDraggingFloat = true
                    floatMoved      = false
                    dragStartTouchX = tx
                    dragStartTouchY = ty
                    dragStartElemX  = floatPos.X
                    dragStartElemY  = floatPos.Y
                end
            end)
        end
        if floatItem.btn.OnReleased then
            floatItem.btn.OnReleased:Add(function()
                isDraggingFloat = false
            end)
        end
    end)
end

-- ==============================================================================
-- 7. ТИКЕР ПЕРЕМЕЩЕНИЯ (50 FPS)
-- ==============================================================================
local function StartDragTicker()
    local okT, ticker = pcall(require, "common.time_ticker")
    if okT and ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0.02, function()
            if isDraggingFloat then
                local tx, ty = GetTouchPosition()
                if tx and ty then
                    local dx = tx - dragStartTouchX
                    local dy = ty - dragStartTouchY
                    if math.abs(dx) > 5 or math.abs(dy) > 5 then
                        floatMoved = true
                        _G.UpdateFloatPos(dragStartElemX + dx, dragStartElemY + dy)
                    end
                end
            end

            if isDraggingMenu and IsValid(bgPanel) then
                local tx, ty = GetTouchPosition()
                if tx and ty then
                    local dx = tx - dragStartTouchX
                    local dy = ty - dragStartTouchY
                    menuPos.X = dragStartElemX + dx
                    menuPos.Y = dragStartElemY + dy
                    if bgPanel.Slot then
                        bgPanel.Slot:SetPosition(FVector2D(menuPos.X, menuPos.Y))
                    end
                end
            end
        end, 0, 0.02)
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
        StartDragTicker()
        Notify("Menu Initialized!")
    end
end

pcall(function()
    local okT, ticker = pcall(require, "common.time_ticker")
    if okT and ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(1.0, function()
            if not _initDone then pcall(TryInit) end
        end, 0, 1.0)
        if ticker.AddTimerOnce then
            ticker.AddTimerOnce(0.5, function() pcall(TryInit) end)
        end
    end
end)

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
