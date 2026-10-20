-- ==============================================================================
-- SODALITE UI (EXACT SVG MATCH + REAL TIME CLOCK)
-- ==============================================================================

local BRPlayerCharacterBase = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {} }

-- 1. ТОЧНЫЕ ЦВЕТА ИЗ SVG
local function FLinearColor(r, g, b, a)
    local col = { R=r, G=g, B=b, A=a }
    local ok, LC = pcall(import, "LinearColor")
    if ok and LC then return LC(r, g, b, a) end
    return col
end

local function FSlateColor(color)
    local ok, SC = pcall(import, "SlateColor")
    if ok and SC then return SC(color) end
    return color
end

local function FVector2D(x, y)
    local vec = { X=x, Y=y }
    local ok, V = pcall(import, "Vector2D")
    if ok and V then return V(x, y) end
    return vec
end

local C = {
    -- Фоны
    BgMain        = FLinearColor(0.91, 0.91, 0.91, 1.0), -- #E8E8E8
    BgSidebar     = FLinearColor(0.84, 0.84, 0.84, 1.0), -- #D6D6D6
    BgActiveTab   = FLinearColor(0.65, 0.85, 0.71, 0.8), -- #A6D9B5 с прозрачностью
    
    -- Акценты иконок
    IconUser      = FLinearColor(0.20, 0.51, 0.96, 1.0), -- Синий
    IconMain      = FLinearColor(0.15, 0.39, 0.92, 1.0), -- Темно-синий
    IconESP       = FLinearColor(0.06, 0.73, 0.51, 1.0), -- Зеленый
    IconAim       = FLinearColor(0.96, 0.62, 0.04, 1.0), -- Оранжевый
    IconMem       = FLinearColor(0.55, 0.36, 0.96, 1.0), -- Фиолетовый
    IconSet       = FLinearColor(0.42, 0.45, 0.50, 1.0), -- Серый
    
    ToggleOn      = FLinearColor(0.20, 0.83, 0.60, 1.0), -- #34D399
    ToggleOff     = FLinearColor(0.82, 0.84, 0.86, 1.0), -- #D1D5DB
    KnobWhite     = FLinearColor(1.0,  1.0,  1.0,  1.0),
    
    -- Текст (ТЕМНЫЙ, чтобы не было белого на белом)
    TextTitle     = FLinearColor(0.10, 0.10, 0.10, 1.0), -- Почти черный
    TextRow       = FLinearColor(0.22, 0.22, 0.22, 1.0), -- Темно-серый
    TextSub       = FLinearColor(0.50, 0.50, 0.50, 1.0), -- Серый для подписей
    
    Divider       = FLinearColor(0.80, 0.80, 0.80, 1.0), -- Линия разделителя
    Indicator     = FLinearColor(1.0,  1.0,  1.0,  0.9),
    HitArea       = FLinearColor(0.0,  0.0,  0.0,  0.01),
    Transparent   = FLinearColor(0.0,  0.0,  0.0,  0.01),
    Shadow        = FLinearColor(0.0,  0.0,  0.0,  0.15),
}

-- Размеры под SVG
local MENU_W, MENU_H = 640, 411
local SIDEBAR_W      = 76
local ROW_H          = 40
local INDICATOR_W    = 226
local INDICATOR_H    = 5

local Config = _G.SodaConfig or { Box=false, Line=true, Skeleton=false, NameDist=true, Health=true }
local currentTab = "ESP"
local bgPanel, floatItem, contentContainer, parentCanvas, isMenuOpen = nil, nil, nil, nil, false
local clockTextBlock, clockTimer = nil, nil

local function IsValid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, obj); return ok and v
    end
    return true
end

local function GetViewport()
    local vpW, vpH = 1920, 1080
    pcall(function()
        local ui_util = require("client.common.ui_util")
        if ui_util and ui_util.GetViewportSize then
            local sz = ui_util.GetViewportSize()
            if sz and sz.X and sz.X > 800 then vpW = sz.X; vpH = sz.Y end
        end
    end)
    return vpW, vpH
end

-- 2. БАЗОВЫЕ ВИДЖЕТЫ
local function NewObject(path, parent)
    local obj = nil
    pcall(function()
        if CGame and CGame.NewObjectFromPath then obj = CGame:NewObjectFromPath(path, parent) end
    end)
    return obj
end

local function Layer(parent, x, y, w, h, color, zOrder, radius)
    local b = NewObject("/Script/UMG.Border", parent)
    if IsValid(b) then
        pcall(function()
            b:SetBrushColor(color)
            if radius and radius > 0 and b.SetCornerRadius then
                -- Пытаемся задать скругление (в некоторых версиях UMG требует FVector4)
                local r = radius
                pcall(function() b:SetCornerRadius(r) end)
            end
        end)
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
    if IsValid(tb) then
        pcall(function()
            tb:SetText(tostring(text or ""))
            tb:SetFont({ Size = fontSize or 12, Typeface = "Regular" })
            -- Жесткая установка цвета через FSlateColor, чтобы не было белого текста
            tb:SetColorAndOpacity(FSlateColor(color or C.TextRow))
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
    if IsValid(btn) then
        pcall(function() btn:SetBackgroundColor(C.Transparent) end)
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

-- 3. ЭЛЕМЕНТЫ UI
local function DrawToggle(parent, x, y, configKey)
    local toggleW, toggleH = 40, 22
    local track = Layer(parent, x, y, toggleW, toggleH, Config[configKey] and C.ToggleOn or C.ToggleOff, 12, 11)
    local knobSize = 18
    local knobOffset = Config[configKey] and (toggleW - knobSize - 2) or 2
    local knob = Layer(parent, x + knobOffset, y + 2, knobSize, knobSize, C.KnobWhite, 14, 9)

    MakeBtn(parent, x - 10, y - 10, toggleW + 20, toggleH + 20, 15, function()
        Config[configKey] = not Config[configKey]
        local on = Config[configKey]
        if IsValid(track) then track:SetBrushColor(on and C.ToggleOn or C.ToggleOff) end
        if IsValid(knob) then
            local newX = x + (on and (toggleW - knobSize - 2) or 2)
            if knob.Slot then knob.Slot:SetPosition(FVector2D(newX, y + 2)) end
        end
    end)
end

local function DrawRow(parent, x, y, w, label, configKey)
    Layer(parent, x, y + ROW_H - 1, w, 1, C.Divider, 5)
    Text(parent, label, x + 20, y + ROW_H * 0.5, 12, C.TextRow, 15, 0.0, 0.5)
    DrawToggle(parent, x + w - 45, y + (ROW_H - 22) * 0.5, configKey)
end

local function DrawSidebarIcon(parent, x, y, label, iconColor, isActive, onClick)
    local size = 32
    local bgColor = isActive and C.BgActiveTab or C.BgSidebar
    local fullH = 58
    
    -- Фон вкладки (если активна)
    if isActive then
        Layer(parent, 0, y - 10, SIDEBAR_W, fullH, bgColor, 5)
    end
    
    -- Круглая иконка
    Layer(parent, x, y, size, size, iconColor, 10, 16)
    
    -- Текст иконки (U, M, E, A, M, S)
    local letter = string.sub(label, 1, 1)
    Text(parent, letter, x + size * 0.5, y + size * 0.5, 14, C.KnobWhite, 11, 0.5, 0.5)
    
    -- Подпись снизу (User, MAIN, ESP...)
    local txtColor = isActive and C.IconESP or C.TextSub
    Text(parent, label, x + size * 0.5, y + size + 4, 9, txtColor, 11, 0.5, 0.5)

    MakeBtn(parent, 0, y - 10, SIDEBAR_W, fullH, 20, onClick)
end

-- 4. ВРЕМЯ СВЕРХУ ЭКРАНА
local function UpdateClock()
    if not IsValid(clockTextBlock) then return end
    pcall(function()
        -- Настоящее локальное время
        clockTextBlock:SetText(os.date("%H:%M:%S"))
    end)
end

local function CreateTopClock(canvas)
    local vpW, vpH = GetViewport()
    local clockW, clockH = 150, 30
    local x = (vpW - clockW) * 0.5
    local y = 40 -- Отступ сверху

    -- Фон под время (полупрозрачный черный)
    Layer(canvas, x, y, clockW, clockH, FLinearColor(0,0,0,0.5), 9000, 8)
    
    -- Текст времени
    clockTextBlock = Text(canvas, "00:00:00", x + clockW * 0.5, y + clockH * 0.5, 16, C.KnobWhite, 9001, 0.5, 0.5)
    
    -- Таймер обновления (раз в секунду)
    local ticker = require("common.time_ticker")
    local function tick()
        UpdateClock()
        if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(1.0, tick) end
    end
    tick()
end

-- 5. КОНТЕНТ
local function RenderContent()
    if not IsValid(contentContainer) then return end
    contentContainer:ClearChildren()

    -- Заголовок вкладки
    Text(contentContainer, currentTab, (MENU_W - SIDEBAR_W) * 0.5, 20, 16, C.TextTitle, 20, 0.5, 0.5)
    
    local startY = 60
    local rowW = MENU_W - SIDEBAR_W - 40
    
    if currentTab == "ESP" then
        -- Квадратик группы "Character"
        Layer(contentContainer, 20, startY, 8, 8, C.ToggleOn, 10, 2)
        Text(contentContainer, "Character", 35, startY + 4, 13, C.TextTitle, 15, 0.0, 0.5)
        
        local rowsY = startY + 20
        DrawRow(contentContainer, 20, rowsY, rowW, "Box", "Box")
        DrawRow(contentContainer, 20, rowsY + ROW_H, rowW, "Line", "Line")
        DrawRow(contentContainer, 20, rowsY + ROW_H * 2, rowW, "Skeleton", "Skeleton")
        DrawRow(contentContainer, 20, rowsY + ROW_H * 3, rowW, "Name and dist", "NameDist")
        DrawRow(contentContainer, 20, rowsY + ROW_H * 4, rowW, "Health", "Health")
    else
        Text(contentContainer, "Section under development", 20, startY, 12, C.TextSub, 15, 0.0, 0.0)
    end
end

-- 6. СБОРКА ОКНА
local function BuildMenu(canvas)
    if IsValid(bgPanel) then
        bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        isMenuOpen = true
        return
    end

    local vpW, vpH = GetViewport()
    bgPanel = NewObject("/Script/UMG.CanvasPanel", canvas)
    local bgSlot = canvas:AddChildToCanvas(bgPanel)

    local posX = math.floor((vpW - MENU_W) * 0.5)
    local posY = math.floor((vpH - MENU_H) * 0.5)
    
    bgSlot:SetPosition(FVector2D(posX, posY))
    bgSlot:SetSize(FVector2D(MENU_W, MENU_H))
    bgSlot:SetZOrder(10000)

    -- Тень окна
    Layer(bgPanel, 4, 4, MENU_W, MENU_H, C.Shadow, 1, 16)
    
    -- Основной фон
    Layer(bgPanel, 0, 0, MENU_W, MENU_H, C.BgMain, 2, 16)
    
    -- Сайдбар (слева)
    Layer(bgPanel, 0, 0, SIDEBAR_W, MENU_H, C.BgSidebar, 3, 16) 
    -- Перекрываем правую часть сайдбара, чтобы скругление было только слева
    Layer(bgPanel, SIDEBAR_W - 16, 0, 16, MENU_H, C.BgSidebar, 3) 

    -- Красный крестик закрытия в правом верхнем углу
    Text(bgPanel, "✖", MENU_W - 25, 15, 14, FLinearColor(0.8, 0.2, 0.2, 1.0), 20, 0.5, 0.5)
    MakeBtn(bgPanel, MENU_W - 40, 0, 40, 40, 21, function() ToggleMenu(canvas) end)

    -- Иконки в сайдбаре (6 штук)
    local tabs = {
        {key="User", icon=C.IconUser},
        {key="MAIN", icon=C.IconMain},
        {key="ESP",  icon=C.IconESP},
        {key="AIM",  icon=C.IconAim},
        {key="MEM",  icon=C.IconMem},
        {key="SET",  icon=C.IconSet},
    }
    
    local iconY = 20
    for _, tab in ipairs(tabs) do
        local isActive = (currentTab == tab.key)
        DrawSidebarIcon(bgPanel, (SIDEBAR_W - 32)*0.5, iconY, tab.key, tab.icon, isActive, function()
            if tab.key == "ESP" then
                currentTab = "ESP"
                RenderContent()
                -- Пересобираем меню для обновления активной вкладки (визуал)
                bgPanel:RemoveFromParent()
                bgPanel = nil
                BuildMenu(canvas)
            end
        end)
        iconY = iconY + 60
    end

    -- Контейнер для контента
    contentContainer = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local cSlot = bgPanel:AddChildToCanvas(contentContainer)
    cSlot:SetPosition(FVector2D(SIDEBAR_W + 10, 0))
    cSlot:SetSize(FVector2D(MENU_W - SIDEBAR_W - 10, MENU_H))
    cSlot:SetZOrder(10)

    RenderContent()
    isMenuOpen = true
end

-- 7. HOME INDICATOR
local function CreateFloatButton(canvas)
    if floatItem and IsValid(floatItem.bg) then return end
    floatItem = { touchStartY = 0, touchStartTime = 0, swiping = false }

    local vpW, vpH = GetViewport()
    local fX = math.floor((vpW - INDICATOR_W) * 0.5)
    local fY = vpH - 20

    Layer(canvas, fX, fY + 2, INDICATOR_W, INDICATOR_H, C.Shadow, 11898, 2.5)
    floatItem.bg = Layer(canvas, fX, fY, INDICATOR_W, INDICATOR_H, C.Indicator, 11901, 2.5)

    local hitW, hitH = 300, 80
    local hitArea = Layer(canvas, fX + (INDICATOR_W - hitW)*0.5, vpH - hitH + 10, hitW, hitH, C.HitArea, 12000)

    local function onTouchStart(_, _, loc) floatItem.touchStartY = loc.Y; floatItem.touchStartTime = os.clock(); floatItem.swiping = false end
    local function onTouchMove(_, _, loc)
        if not floatItem.touchStartY then return end
        if loc.Y - floatItem.touchStartY < -40 and not floatItem.swiping then
            floatItem.swiping = true
            if not isMenuOpen then ToggleMenu(canvas) end
        end
    end
    local function onTouchEnd(_, _, loc)
        local dt = os.clock() - floatItem.touchStartTime
        local dy = loc.Y - floatItem.touchStartY
        if dt < 0.4 and math.abs(dy) < 30 and not floatItem.swiping then ToggleMenu(canvas) end
        floatItem.touchStartY = 0; floatItem.swiping = false
    end

    pcall(function()
        if hitArea.OnTouchStarted then hitArea.OnTouchStarted:Add(onTouchStart) end
        if hitArea.OnTouchMoved then hitArea.OnTouchMoved:Add(onTouchMove) end
        if hitArea.OnTouchEnded then hitArea.OnTouchEnded:Add(onTouchEnd) end
    end)

    floatItem.btn = MakeBtn(canvas, fX + (INDICATOR_W - hitW)*0.5, vpH - hitH + 10, hitW, hitH, 12001, function() ToggleMenu(canvas) end)
end

function ToggleMenu(canvas)
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        if IsValid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        else BuildMenu(canvas) end
        if floatItem and floatItem.bg then floatItem.bg:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
    else
        if IsValid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
        if floatItem and floatItem.bg then floatItem.bg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
    end
end

-- 8. INIT
local function GetCanvas()
    if IsValid(parentCanvas) then return parentCanvas end
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
    if GetViewport() < 800 then return end

    CreateFloatButton(canvas)
    CreateTopClock(canvas) -- Запускаем часы
    
    if floatItem and IsValid(floatItem.bg) then
        _initDone = true
        print("[SodaLite] EXACT SVG UI Loaded")
    end
end

local function InitWatcher()
    if _initDone then return end
    pcall(TryInit)
    if not _initDone then
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.5, InitWatcher) end
    end
end
InitWatcher()

function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    pcall(TryInit)
end
function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    pcall(TryInit)
end

return BRPlayerCharacterBase