-- ==============================================================================
-- PUBG MOBILE IMGUI MENU TEMPLATE (BRPlayerCharacterBase) WITH DRAG & DROP
-- ==============================================================================
-- Этот скрипт является полноценной основой для создания UMG-меню в PUBG Mobile.
-- Возможности:
-- 1. Поддержка перетаскивания (DRAG & DROP):
--    - Плавающую кнопку [OPEN MENU] можно свободно таскать пальцем по всему экрану.
--    - Окно меню можно перетаскивать за шапку (Header).
-- 2. Умное распознавание клика:
--    - Если пальцем просто тапнули — меню открывается/закрывается.
--    - Если палец сдвинулся — кнопка плавно следует за пальцем.
-- 3. Чекбоксы (Toggles) и Слайдеры с живой сменой состояний.
-- 4. Переключение вкладок (VISUALS / AIMBOT).
-- ==============================================================================

local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {},
  LuaEventContainer = {}
}

-- RPC сигнатуры для защиты от рассинхрона
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }

-- ==============================================================================
-- 1. СИСТЕМА ЦВЕТОВ (FLinearColor: R, G, B, A от 0.0 до 1.0)
-- ==============================================================================
local function Color(r, g, b, a)
    local col = { R = r or 1, G = g or 1, B = b or 1, A = a or 1 }
    local ok, LC = pcall(import, "LinearColor")
    if ok and LC then return LC(r, g, b, a) end
    return col
end

local Colors = {
    -- Тёмно-синяя тема (Royal Cyber)
    bg_main     = Color(0.07, 0.09, 0.14, 0.96), -- Фон главного окна
    bg_header   = Color(0.04, 0.05, 0.08, 1.00), -- Шапка меню
    bg_row      = Color(0.11, 0.13, 0.18, 0.90), -- Фон строки
    border      = Color(0.15, 0.45, 1.00, 0.85), -- Неоновый синий бордер
    accent_blue = Color(0.18, 0.50, 1.00, 1.00), -- Акцентный синий
    accent_red  = Color(0.92, 0.22, 0.25, 1.00), -- Кнопка [X]
    text_white  = Color(0.96, 0.98, 1.00, 1.00), -- Белый текст
    text_dim    = Color(0.60, 0.65, 0.75, 1.00), -- Серый текст
    
    -- Переключатели
    toggle_on   = Color(0.18, 0.55, 1.00, 1.00),
    toggle_off  = Color(0.20, 0.22, 0.28, 1.00),
    toggle_knob = Color(1.00, 1.00, 1.00, 1.00),
    
    -- Слайдеры
    slider_bg   = Color(0.16, 0.18, 0.25, 1.00),
    slider_fill = Color(0.18, 0.55, 1.00, 1.00),
}

-- Размеры и стартовые координаты окна меню
local MENU_W = 560
local MENU_H = 400
local ROW_H  = 40
local menuPos = { X = 300, Y = 120 }

-- Размеры и стартовые координаты плавающей кнопки
local FLOAT_W = 120
local FLOAT_H = 38
local floatPos = { X = 750, Y = 15 }

-- Таблица настроек
local Config = {
    EspBox      = false,
    EspLine     = true,
    EspSkeleton = false,
    AimFov      = 60,
    AimSmooth   = 15,
}

local currentTab = "VISUALS"
local bgPanel = nil
local floatContainer = nil
local contentContainer = nil
local parentCanvas = nil
local isMenuOpen = false

-- ==============================================================================
-- 2. СИСТЕМА DRAG & DROP (ПЕРЕМЕЩЕНИЕ ПАЛЬЦЕМ)
-- ==============================================================================
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

-- Получаем контроллер игрока для чтения координат тача
local function GetPlayerController()
    local pc = nil
    pcall(function()
        if slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController then
            pc = slua_GameFrontendHUD:GetPlayerController()
        end
    end)
    if not pc or not IsValid(pc) then
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

-- Получает текущие координаты пальца на сенсорном экране (или курсора мыши на ПК)
local function GetTouchPosition()
    local pc = GetPlayerController()
    if not pc or not IsValid(pc) then return nil, nil end

    -- 1. Мобильный тач (индекс 0 = Touch1)
    local okT, tx, ty, pressed = pcall(function()
        local x, y, p = 0, 0, false
        return pc:GetInputTouchState(0, x, y, p)
    end)
    if okT and tx and ty and (tx ~= 0 or ty ~= 0) then
        return tx, ty
    end

    -- 2. Мышь (для эмуляторов Gameloop / LDPlayer)
    local okM, mx, my = pcall(function()
        return pc:GetMousePosition(0, 0)
    end)
    if okM and mx and my and (mx ~= 0 or my ~= 0) then
        return mx, my
    end

    return nil, nil
end

-- ==============================================================================
-- 3. БАЗОВЫЕ ХЕЛПЕРЫ UMG
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

local function CreateLayer(parent, x, y, w, h, color, zOrder)
    local b = NewObject("/Script/UMG.Border", parent)
    if IsValid(b) then
        pcall(function() b:SetBrushColor(color) end)
        pcall(function() b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        local slot = parent:AddChildToCanvas(b)
        if slot then
            slot:SetAutoSize(false)
            slot:SetPosition({ X = x, Y = y })
            slot:SetSize({ X = w, Y = h })
            slot:SetZOrder(zOrder or 0)
        end
    end
    return b
end

local function CreateText(parent, text, x, y, fontSize, color, zOrder, alignX, alignY)
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
            slot:SetPosition({ X = x, Y = y })
            slot:SetAlignment({ X = alignX or 0, Y = alignY or 0 })
            slot:SetZOrder(zOrder or 1)
        end
    end
    return tb
end

local function CreateButton(parent, x, y, w, h, zOrder, onClick)
    local btn = NewObject("/Script/UMG.Button", parent)
    if IsValid(btn) then
        pcall(function()
            local col0 = Color(0, 0, 0, 0)
            local normalStyle = { TintColor = { SpecifiedColor = col0 } }
            btn:SetWidgetStyle({
                Normal  = normalStyle,
                Hovered = normalStyle,
                Pressed = normalStyle,
            })
            btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
            if onClick then
                btn.OnClicked:Add(onClick)
            end
        end)
        local slot = parent:AddChildToCanvas(btn)
        if slot then
            slot:SetAutoSize(false)
            slot:SetPosition({ X = x, Y = y })
            slot:SetSize({ X = w, Y = h })
            slot:SetZOrder(zOrder or 100)
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
-- 4. UMG ВИДЖЕТЫ: ЧЕКБОКС И СЛАЙДЕР
-- ==============================================================================
local function DrawCheckbox(parent, x, y, w, label, configKey)
    local h = ROW_H
    CreateLayer(parent, x, y, w, h, Colors.bg_row, 10)
    CreateLayer(parent, x, y + h - 1, w, 1, Color(0.2, 0.25, 0.35, 0.4), 11)

    CreateText(parent, label, x + 16, y + h * 0.5, 12, Colors.text_white, 15, 0.0, 0.5)

    local toggleW, toggleH = 46, 22
    local toggleX = x + w - toggleW - 14
    local toggleY = y + (h - toggleH) * 0.5

    local track = CreateLayer(parent, toggleX, toggleY, toggleW, toggleH, 
        Config[configKey] and Colors.toggle_on or Colors.toggle_off, 12)

    local knobSize = 18
    local knobOffset = Config[configKey] and (toggleW - knobSize - 2) or 2
    local knob = CreateLayer(parent, toggleX + knobOffset, toggleY + 2, knobSize, knobSize, Colors.toggle_knob, 14)

    CreateButton(parent, x, y, w, h, 20, function()
        Config[configKey] = not Config[configKey]
        local isEnabled = Config[configKey]

        if IsValid(track) then
            track:SetBrushColor(isEnabled and Colors.toggle_on or Colors.toggle_off)
        end
        if IsValid(knob) then
            local newKnobX = toggleX + (isEnabled and (toggleW - knobSize - 2) or 2)
            local slot = knob.Slot
            if slot then slot:SetPosition({ X = newKnobX, Y = toggleY + 2 }) end
        end

        Notify(label .. ": " .. (isEnabled and "ON" or "OFF"))
    end)
end

local function DrawSlider(parent, x, y, w, label, configKey, minVal, maxVal)
    local h = ROW_H
    CreateLayer(parent, x, y, w, h, Colors.bg_row, 10)
    CreateLayer(parent, x, y + h - 1, w, 1, Color(0.2, 0.25, 0.35, 0.4), 11)

    CreateText(parent, label, x + 16, y + h * 0.5, 12, Colors.text_white, 15, 0.0, 0.5)

    local valText = CreateText(parent, tostring(Config[configKey]), x + w - 120, y + h * 0.5, 12, Colors.accent_blue, 15, 1.0, 0.5)

    local btnW = 28
    local btnMinusX = x + w - 85
    local btnPlusX  = x + w - 40
    local btnY      = y + (h - 26) * 0.5

    CreateLayer(parent, btnMinusX, btnY, btnW, 26, Colors.slider_bg, 12)
    CreateText(parent, "-", btnMinusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    CreateButton(parent, btnMinusX, btnY, btnW, 26, 20, function()
        if Config[configKey] > minVal then
            Config[configKey] = Config[configKey] - 1
            if IsValid(valText) then valText:SetText(tostring(Config[configKey])) end
        end
    end)

    CreateLayer(parent, btnPlusX, btnY, btnW, 26, Colors.slider_bg, 12)
    CreateText(parent, "+", btnPlusX + btnW * 0.5, btnY + 13, 14, Colors.text_white, 13, 0.5, 0.5)
    CreateButton(parent, btnPlusX, btnY, btnW, 26, 20, function()
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
    end
end

local function BuildMenu(canvas)
    if IsValid(bgPanel) then
        bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        isMenuOpen = true
        return
    end

    -- Главный контейнер окна
    bgPanel = NewObject("/Script/UMG.CanvasPanel", canvas)
    local bgSlot = canvas:AddChildToCanvas(bgPanel)
    bgSlot:SetPosition(menuPos)
    bgSlot:SetSize({ X = MENU_W, Y = MENU_H })
    bgSlot:SetZOrder(10000)

    -- Фон и обводка
    CreateLayer(bgPanel, -2, -2, MENU_W + 4, MENU_H + 4, Colors.border, 1)
    CreateLayer(bgPanel, 0, 0, MENU_W, MENU_H, Colors.bg_main, 2)

    -- Шапка окна (Header)
    local HEADER_H = 44
    CreateLayer(bgPanel, 0, 0, MENU_W, HEADER_H, Colors.bg_header, 3)
    CreateLayer(bgPanel, 0, HEADER_H - 1, MENU_W, 1, Colors.border, 4)
    CreateText(bgPanel, "CUSTOM IMGUI MENU - PUBG MOBILE", 16, HEADER_H * 0.5, 13, Colors.text_white, 5, 0.0, 0.5)

    -- ЗОНА ПЕРЕТАСКИВАНИЯ ОКНА ЗА ШАПКУ:
    local dragBtn = NewObject("/Script/UMG.Button", bgPanel)
    if IsValid(dragBtn) then
        local col0 = Color(0, 0, 0, 0)
        local normalStyle = { TintColor = { SpecifiedColor = col0 } }
        dragBtn:SetWidgetStyle({ Normal = normalStyle, Hovered = normalStyle, Pressed = normalStyle })
        dragBtn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)

        dragBtn.OnPressed:Add(function()
            local tx, ty = GetTouchPosition()
            if tx and ty then
                isDraggingMenu = true
                dragStartTouchX = tx
                dragStartTouchY = ty
                dragStartElemX  = menuPos.X
                dragStartElemY  = menuPos.Y
            end
        end)

        dragBtn.OnReleased:Add(function()
            isDraggingMenu = false
        end)

        local dSlot = bgPanel:AddChildToCanvas(dragBtn)
        dSlot:SetPosition({ X = 0, Y = 0 })
        dSlot:SetSize({ X = MENU_W - 40, Y = HEADER_H })
        dSlot:SetZOrder(30)
    end

    -- Кнопка закрытия [X]
    local closeX = MENU_W - 36
    CreateLayer(bgPanel, closeX, 8, 28, 28, Colors.accent_red, 5)
    CreateText(bgPanel, "X", closeX + 14, 22, 12, Colors.text_white, 6, 0.5, 0.5)
    CreateButton(bgPanel, closeX, 8, 28, 28, 50, function()
        bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        isMenuOpen = false
    end)

    -- Вкладки
    local tabY = HEADER_H + 8
    local tabW = 120
    local tabH = 32

    CreateLayer(bgPanel, 16, tabY, tabW, tabH, Colors.bg_row, 5)
    CreateText(bgPanel, "VISUALS", 16 + tabW * 0.5, tabY + tabH * 0.5, 11, Colors.text_white, 6, 0.5, 0.5)
    CreateButton(bgPanel, 16, tabY, tabW, tabH, 20, function()
        currentTab = "VISUALS"
        RenderContent()
    end)

    CreateLayer(bgPanel, 16 + tabW + 8, tabY, tabW, tabH, Colors.bg_row, 5)
    CreateText(bgPanel, "AIMBOT", 16 + tabW + 8 + tabW * 0.5, tabY + tabH * 0.5, 11, Colors.text_white, 6, 0.5, 0.5)
    CreateButton(bgPanel, 16 + tabW + 8, tabY, tabW, tabH, 20, function()
        currentTab = "AIMBOT"
        RenderContent()
    end)

    contentContainer = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local cSlot = bgPanel:AddChildToCanvas(contentContainer)
    cSlot:SetPosition({ X = 0, Y = tabY + tabH + 6 })
    cSlot:SetSize({ X = MENU_W, Y = MENU_H - (tabY + tabH + 6) })
    cSlot:SetZOrder(10)

    RenderContent()
    isMenuOpen = true
end

local function ToggleMenu(canvas)
    if isMenuOpen then
        if IsValid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
        isMenuOpen = false
    else
        BuildMenu(canvas)
    end
end

-- ==============================================================================
-- 6. ПЛАВАЮЩАЯ КНОПКА С ПЕРЕТАСКИВАНИЕМ (DRAGGABLE FLOAT BUTTON)
-- ==============================================================================
local function CreateFloatButton(canvas)
    if IsValid(floatContainer) then return end

    -- Создаём контейнер для кнопки (CanvasPanel позволяет легко перемещать всю кнопку разом)
    floatContainer = NewObject("/Script/UMG.CanvasPanel", canvas)
    local slot = canvas:AddChildToCanvas(floatContainer)
    slot:SetPosition(floatPos)
    slot:SetSize({ X = FLOAT_W, Y = FLOAT_H })
    slot:SetZOrder(12000)

    -- Фон и текст внутри контейнера
    CreateLayer(floatContainer, 0, 0, FLOAT_W, FLOAT_H, Colors.border, 1)
    CreateLayer(floatContainer, 1, 1, FLOAT_W - 2, FLOAT_H - 2, Colors.bg_header, 2)
    CreateText(floatContainer, "OPEN MENU", FLOAT_W * 0.5, FLOAT_H * 0.5, 11, Colors.accent_blue, 3, 0.5, 0.5)

    -- Кнопка, отслеживающая нажатие, перемещение и отпускание
    local btn = NewObject("/Script/UMG.Button", floatContainer)
    if IsValid(btn) then
        local col0 = Color(0, 0, 0, 0)
        local normalStyle = { TintColor = { SpecifiedColor = col0 } }
        btn:SetWidgetStyle({ Normal = normalStyle, Hovered = normalStyle, Pressed = normalStyle })
        btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)

        -- 1. Палец опустился на экран
        btn.OnPressed:Add(function()
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

        -- 2. Палец поднялся
        btn.OnReleased:Add(function()
            isDraggingFloat = false
            -- Если палец не сдвигался (был просто короткий тап) — открываем меню!
            if not floatMoved then
                ToggleMenu(canvas)
            end
        end)

        local bSlot = floatContainer:AddChildToCanvas(btn)
        bSlot:SetPosition({ X = 0, Y = 0 })
        bSlot:SetSize({ X = FLOAT_W, Y = FLOAT_H })
        bSlot:SetZOrder(10)
    end
end

-- ==============================================================================
-- 7. ТИКЕР ПЕРЕМЕЩЕНИЯ (50 FPS UPDATE LOOP)
-- ==============================================================================
-- Этот тикер проверяет позицию пальца при зажатой кнопке и плавно двигает виджет
local function StartDragTicker()
    local okT, ticker = pcall(require, "common.time_ticker")
    if okT and ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0.02, function()
            -- Перемещение плавающей кнопки
            if isDraggingFloat and IsValid(floatContainer) then
                local tx, ty = GetTouchPosition()
                if tx and ty then
                    local dx = tx - dragStartTouchX
                    local dy = ty - dragStartTouchY
                    -- Если сдвинулся более чем на 4 пикселя — считаем это перетаскиванием
                    if math.abs(dx) > 4 or math.abs(dy) > 4 then
                        floatMoved = true
                        floatPos.X = dragStartElemX + dx
                        floatPos.Y = dragStartElemY + dy
                        if floatContainer.Slot then
                            floatContainer.Slot:SetPosition(floatPos)
                        end
                    end
                end
            end

            -- Перемещение окна меню за шапку
            if isDraggingMenu and IsValid(bgPanel) then
                local tx, ty = GetTouchPosition()
                if tx and ty then
                    local dx = tx - dragStartTouchX
                    local dy = ty - dragStartTouchY
                    menuPos.X = dragStartElemX + dx
                    menuPos.Y = dragStartElemY + dy
                    if bgPanel.Slot then
                        bgPanel.Slot:SetPosition(menuPos)
                    end
                end
            end
        end, 0, 0.02)
    end
end

-- ==============================================================================
-- 8. ПОЛУЧЕНИЕ ИГРОВОГО CANVAS И ИНИЦИАЛИЗАЦИЯ
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
    if IsValid(floatContainer) then
        _initDone = true
        StartDragTicker()
        Notify("Menu Initialized with Drag & Drop!")
    end
end

-- Таймер ожидания загрузки холста
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
    pcall(TryInit)
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    pcall(TryInit)
end

return BRPlayerCharacterBase
