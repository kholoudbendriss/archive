-- ==============================================================================
-- SODALITE UI CORE (SVG EXACT MATCH)
-- Воссоздание интерфейса строго по Frame 12(1).svg
-- ==============================================================================

local BRPlayerCharacterBase = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {} }

-- 1. ТОЧНЫЕ ЦВЕТА ИЗ SVG
local function FLinearColor(r, g, b, a)
    local col = { R=r or 1, G=g or 1, B=b or 1, A=a or 1 }
    local ok, LC = pcall(import, "LinearColor")
    if ok and LC then return LC(r, g, b, a) end
    return col
end

local function FVector2D(x, y)
    local vec = { X=x or 0, Y=y or 0 }
    local ok, V = pcall(import, "Vector2D")
    if ok and V then return V(x or 0, y or 0) end
    return vec
end

-- Палитра из SVG
local C = {
    -- Окна и фоны
    MenuBg        = FLinearColor(0.906, 0.906, 0.906, 1.0),   -- #E7E7E7
    SidebarBg     = FLinearColor(0.71,  0.71,  0.71,  0.5),   -- #B5B5B5 @ 50%
    RowBg         = FLinearColor(1.0,   1.0,   1.0,   0.25),  -- White @ 25%
    
    -- Акценты
    ActiveIcon    = FLinearColor(0.29,  0.565, 0.851, 1.0),   -- #4A90D9 (Синий)
    ToggleOn      = FLinearColor(0.224, 0.875, 0.482, 1.0),   -- #39DF7B (Зеленый)
    ToggleOff     = FLinearColor(0.608, 0.608, 0.608, 1.0),   -- #9B9B9B (Серый)
    KnobWhite     = FLinearColor(1.0,   1.0,   1.0,   1.0),
    
    -- Текст
    TextDark      = FLinearColor(0.2,   0.2,   0.2,   1.0),   -- #333333
    TextDim       = FLinearColor(0.33,  0.33,  0.33,  1.0),   -- #555555
    
    -- Home Indicator
    Indicator     = FLinearColor(1.0,   1.0,   1.0,   0.9),
}

-- Размеры из SVG
local MENU_W, MENU_H = 640, 411
local SIDEBAR_W      = 83
local ROW_H          = 60
local ICON_SIZE      = 36
local INDICATOR_W    = 226
local INDICATOR_H    = 5

-- Состояние
local Config = _G.SodaConfig or {
    BlackSky = false, Wallhack = false, IpadView = false, Aimbot = false
}
local currentTab = "VISUALS"
local bgPanel, floatItem, contentContainer, parentCanvas, isMenuOpen = nil, nil, nil, nil, false

-- Проверка валидности
local function IsValid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, obj); return ok and v
    end
    return true
end

-- 2. БАЗОВЫЕ ФУНКЦИИ СОЗДАНИЯ ВИДЖЕТОВ (UMG WRAPPERS)
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
            if radius and radius > 0 then b:SetCornerRadius(radius) end
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
            tb:SetFont({ Size = fontSize or 12, Typeface = "Bold" }) -- Bold как в SVG
            tb:SetColorAndOpacity(color or C.TextDark)
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
        pcall(function() btn:SetBackgroundColor(FLinearColor(0,0,0,0)) end)
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

-- 3. ЭЛЕМЕНТЫ МЕНЮ ПО SVG ДИЗАЙНУ

-- Переключатель (Toggle) точно как на картинке
local function DrawCheckbox(parent, x, y, w, label, configKey)
    local h = ROW_H
    -- Фон строки (белый полупрозрачный)
    Layer(parent, x, y, w, h, C.RowBg, 10, 8)
    
    -- Текст слева
    Text(parent, label, x + 16, y + h * 0.5, 12, C.TextDark, 15, 0.0, 0.5)

    -- Плашка переключателя (скругленный прямоугольник)
    local toggleW, toggleH = 42, 24
    local toggleX = x + w - toggleW - 16
    local toggleY = y + (h - toggleH) * 0.5
    
    local track = Layer(parent, toggleX, toggleY, toggleW, toggleH, 
        Config[configKey] and C.ToggleOn or C.ToggleOff, 12, 12)
    
    -- Белый кружок (Knob)
    local knobSize = 18
    local knobOffset = Config[configKey] and (toggleW - knobSize - 3) or 3
    local knob = Layer(parent, toggleX + knobOffset, toggleY + 3, knobSize, knobSize, C.KnobWhite, 14, 9)

    MakeBtn(parent, x, y, w, h, 20, function()
        Config[configKey] = not Config[configKey]
        local isEnabled = Config[configKey]
        
        -- Анимация цвета и позиции
        if IsValid(track) then track:SetBrushColor(isEnabled and C.ToggleOn or C.ToggleOff) end
        if IsValid(knob) then
            local newKnobX = toggleX + (isEnabled and (toggleW - knobSize - 3) or 3)
            if knob.Slot then knob.Slot:SetPosition(FVector2D(newKnobX, toggleY + 3)) end
        end
    end)
end

-- Иконка категории в сайдбаре
local function DrawSidebarIcon(parent, x, y, isActive, onClick)
    local size = ICON_SIZE
    local bgRadius = 18
    local iconColor = isActive and C.ActiveIcon or C.ToggleOff
    
    -- Круглый фон
    Layer(parent, x, y, size, size, iconColor, 10, bgRadius)
    
    -- Условная иконка (текст или символ для примера)
    -- В реальном коде здесь можно использовать Image или TextBlock с символом
    local symbol = isActive and "V" or "-" 
    Text(parent, symbol, x + size*0.5, y + size*0.5, 16, C.KnobWhite, 11, 0.5, 0.5)
    
    -- Невидимая кнопка поверх
    MakeBtn(parent, x, y, size, size, 20, onClick)
end

-- 4. ОТРИСОВКА КОНТЕНТА ПО ВКЛАДКАМ
local function RenderContent()
    if not IsValid(contentContainer) then return end
    contentContainer:ClearChildren()
    local startY = 12
    local colW = MENU_W - SIDEBAR_W - 20

    if currentTab == "VISUALS" then
        Text(contentContainer, "VISUAL SETTINGS", 16, startY, 14, C.TextDim, 15, 0.0, 0.0)
        DrawCheckbox(contentContainer, 16, startY + 30, colW, "Black Sky (Чёрное небо)", "BlackSky")
        DrawCheckbox(contentContainer, 16, startY + 90, colW, "Wallhack (Chams)", "Wallhack")
        DrawCheckbox(contentContainer, 16, startY + 150, colW, "IPad View (Отдаление камеры)", "IpadView")
    elseif currentTab == "AIMBOT" then
        Text(contentContainer, "AIM ASSISTANCE", 16, startY, 14, C.TextDim, 15, 0.0, 0.0)
        DrawCheckbox(contentContainer, 16, startY + 30, colW, "Enable Aimbot", "Aimbot")
    end
end

-- 5. СБОРКА ГЛАВНОГО ОКНА (ТОЧНАЯ КОПИЯ SVG СТРУКТУРЫ)
local function BuildMenu(canvas)
    if IsValid(bgPanel) then
        bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        isMenuOpen = true; return
    end

    bgPanel = NewObject("/Script/UMG.CanvasPanel", canvas)
    local bgSlot = canvas:AddChildToCanvas(bgPanel)
    -- Центрируем меню по вертикали и горизонтали, чуть выше центра как в дизайне
    local vpW, vpH = 1920, 1080 -- Дефолт, будет пересчитано при инициализации
    pcall(function()
        local ui_util = require("client.common.ui_util")
        if ui_util and ui_util.GetViewportSize then
            local sz = ui_util.GetViewportSize()
            if sz then vpW = sz.X; vpH = sz.Y end
        end
    end)
    
    local posX = (vpW - MENU_W) * 0.5
    local posY = (vpH - MENU_H) * 0.5 - 50 
    
    bgSlot:SetPosition(FVector2D(posX, posY))
    bgSlot:SetSize(FVector2D(MENU_W, MENU_H))
    bgSlot:SetZOrder(10000)

    -- Основное окно с тенью (эмуляция через Border)
    Layer(bgPanel, 0, 0, MENU_W, MENU_H, C.MenuBg, 1, 25)
    
    -- Сайдбар слева
    Layer(bgPanel, 10, 8, SIDEBAR_W, MENU_H - 16, C.SidebarBg, 2, 20)

    -- Иконки в сайдбаре (вертикальный список)
    DrawSidebarIcon(bgPanel, 23.5, 21, currentTab == "VISUALS", function()
        currentTab = "VISUALS"; RenderContent()
    end)
    DrawSidebarIcon(bgPanel, 23.5, 81, currentTab == "AIMBOT", function()
        currentTab = "AIMBOT"; RenderContent()
    end)
    DrawSidebarIcon(bgPanel, 23.5, 141, currentTab == "EXPLOIT", function()
        currentTab = "EXPLOIT"; RenderContent()
    end)
    DrawSidebarIcon(bgPanel, 23.5, 201, currentTab == "SKINS", function()
        currentTab = "SKINS"; RenderContent()
    end)
    DrawSidebarIcon(bgPanel, 23.5, 261, currentTab == "SETTINGS", function()
        currentTab = "SETTINGS"; RenderContent()
    end)

    -- Контейнер для контента справа от сайдбара
    contentContainer = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local cSlot = bgPanel:AddChildToCanvas(contentContainer)
    cSlot:SetPosition(FVector2D(SIDEBAR_W + 10, 8))
    cSlot:SetSize(FVector2D(MENU_W - SIDEBAR_W - 20, MENU_H - 16))
    cSlot:SetZOrder(10)

    RenderContent()
    isMenuOpen = true
end

-- 6. HOME INDICATOR (КАК НА IPHONE)
local function CreateFloatButton(canvas)
    if floatItem and IsValid(floatItem.btn) then return end
    floatItem = {}
    
    local vpW, vpH = 1920, 1080
    pcall(function()
        local ui_util = require("client.common.ui_util")
        if ui_util and ui_util.GetViewportSize then
            local sz = ui_util.GetViewportSize()
            if sz then vpW = sz.X; vpH = sz.Y end
        end
    end)

    local fX = (vpW - INDICATOR_W) * 0.5
    local fY = vpH - 20 -- Отступ снизу как в iOS
    
    -- Тень индикатора (легкое размытие через Border с прозрачностью)
    Layer(canvas, fX, fY + 2, INDICATOR_W, INDICATOR_H, FLinearColor(0,0,0,0.3), 11898, 2.5)
    
    -- Сам индикатор
    floatItem.bg = Layer(canvas, fX, fY, INDICATOR_W, INDICATOR_H, C.Indicator, 11901, 2.5)
    
    -- Кнопка клика
    floatItem.btn = MakeBtn(canvas, fX - 20, fY - 20, INDICATOR_W + 40, INDICATOR_H + 40, 12002, function() 
        ToggleMenu(canvas) 
    end)
end

local function ToggleMenu(canvas)
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        if IsValid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        else BuildMenu(canvas) end
    else
        if IsValid(bgPanel) then bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
    end
end

-- 7. ИНИЦИАЛИЗАЦИЯ
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
        print("[SodaLite] UI Loaded with SVG Exact Design")
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

function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    pcall(TryInit)
end
function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    pcall(TryInit)
end

return BRPlayerCharacterBase