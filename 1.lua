-- ==============================================================================
-- SODALITE UI - 1:1 PIXEL-PERFECT SVG REPLICA (menu.svg)
-- Top Floating Pill (Clock | Mango Cheats | Expired 999 days)
-- Glass Sidebar + ESP Module (Character, Box, Line, Skeleton, Name and dist, Health)
-- iOS Home Indicator + Slide/Tap Gesture
-- ==============================================================================

local BRPlayerCharacterBase = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {} }

-- 1. ЦВЕТОВАЯ ПАЛИТРА ИЗ SVG (menu.svg) С ПОЛУПРОЗРАЧНОСТЬЮ И ТЕМНОЙ ШАПКОЙ
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
    -- Окно меню: стильное матовое стекло (Glassmorphism)
    WindowBg        = FLinearColor(0.92, 0.92, 0.93, 0.88), -- полупрозрачный мягкий светлый фон
    Shadow          = FLinearColor(0.0, 0.0, 0.0, 0.20),
    BorderOutline   = FLinearColor(1.0, 1.0, 1.0, 0.60),    -- светлая окантовка стекла
    
    -- Сайдбар слева
    SidebarBg       = FLinearColor(0.78, 0.79, 0.82, 0.65), -- полупрозрачный сайдбар
    SidebarTabActive= FLinearColor(0.22, 0.88, 0.48, 0.28), -- #39DF7B активная подсветка
    
    -- Иконки сайдбара
    IconUser        = FLinearColor(0.29, 0.56, 0.85, 1.0), -- #4A90D9
    IconMain        = FLinearColor(0.36, 0.55, 0.94, 1.0), -- #5B8DEF
    IconESP         = FLinearColor(0.22, 0.88, 0.48, 1.0), -- #39DF7B
    IconAim         = FLinearColor(0.96, 0.65, 0.14, 1.0), -- #F5A623
    IconMem         = FLinearColor(0.48, 0.41, 0.93, 1.0), -- #7B68EE
    IconSet         = FLinearColor(0.61, 0.61, 0.61, 1.0), -- #9B9B9B
    
    -- Тексты сайдбара
    TextUser        = FLinearColor(0.33, 0.33, 0.33, 1.0),
    TextDark        = FLinearColor(0.18, 0.18, 0.20, 1.0),
    TextActiveESP   = FLinearColor(0.10, 0.48, 0.27, 1.0),
    
    -- Заголовок модуля ESP и группы
    TextTitle       = FLinearColor(0.15, 0.15, 0.18, 1.0),
    TextCategory    = FLinearColor(0.25, 0.25, 0.28, 1.0),
    CategorySquare  = FLinearColor(0.22, 0.88, 0.48, 1.0),
    
    -- Разделители таблицы
    DividerTop      = FLinearColor(0.75, 0.75, 0.78, 0.9),
    DividerRow      = FLinearColor(0.82, 0.82, 0.85, 0.8),
    
    -- Переключатели (Toggle switches)
    ToggleOn        = FLinearColor(0.22, 0.88, 0.48, 1.0), -- #39DF7B
    ToggleOff       = FLinearColor(0.78, 0.80, 0.83, 1.0), -- #D0D0D0
    KnobWhite       = FLinearColor(1.0, 1.0, 1.0, 1.0),
    
    -- Кнопка закрытия окна (справа сверху)
    ClosePillBg     = FLinearColor(0.75, 0.75, 0.78, 0.65),
    CloseCross      = FLinearColor(0.85, 0.22, 0.22, 1.0),
    
    -- ВЕРХНИЙ ПЛАВАЮЩИЙ БАР (TOP PILL): ТЕМНОЕ ПОЛУПРОЗРАЧНОЕ СТЕКЛО (ЧТОБЫ ВСЕ ЧИТАЛОСЬ)
    TopPillBg       = FLinearColor(0.08, 0.10, 0.14, 0.70), -- красивое темное стекло
    TopPillBorder   = FLinearColor(1.0, 1.0, 1.0, 0.25),   -- тонкий светлый контур
    TopPillText     = FLinearColor(1.0, 1.0, 1.0, 0.98),   -- яркий белый читаемый текст
    TopPillAccent   = FLinearColor(0.25, 0.90, 0.52, 1.0), -- зеленый акцент
    TopPillDiv      = FLinearColor(1.0, 1.0, 1.0, 0.35),   -- аккуратный разделитель
    
    -- Нижний индикатор жестов
    IndicatorWhite  = FLinearColor(1.0, 1.0, 1.0, 0.95),
    
    Transparent     = FLinearColor(0.0, 0.0, 0.0, 0.001),
}

-- Размеры в точности по menu.svg
local MENU_W, MENU_H        = 640, 411
local SIDEBAR_X, SIDEBAR_Y  = 10, 8
local SIDEBAR_W, SIDEBAR_H  = 83, 396
local INDICATOR_W           = 226
local INDICATOR_H           = 5

-- Текущие настройки (по SVG включены Box, Line, NameDist, Health; Skeleton выключен)
local Config = _G.SodaConfig or {
    Box      = true,
    Line     = true,
    Skeleton = false,
    NameDist = true,
    Health   = true,
}
_G.SodaConfig = Config

local currentTab = "ESP"
local bgPanel = nil
local floatItem = nil
local contentContainer = nil
local parentCanvas = nil
local isMenuOpen = false
local clockTextBlock = nil

local function IsValid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, obj)
        return ok and v
    end
    return true
end

local function GetViewport()
    local vpW, vpH = 1280, 580
    pcall(function()
        local ui_util = require("client.common.ui_util")
        if ui_util and ui_util.GetViewportSize then
            local sz = ui_util.GetViewportSize()
            if sz and sz.X and sz.X > 600 then vpW = sz.X; vpH = sz.Y end
        end
    end)
    return vpW, vpH
end

local function NewObject(path, parent)
    local obj = nil
    pcall(function()
        if CGame and CGame.NewObjectFromPath then
            obj = CGame:NewObjectFromPath(path, parent)
        end
    end)
    return obj
end

-- Создание слоев с поддержкой нескольких вариантов скругления
local function Layer(parent, x, y, w, h, color, zOrder, radius)
    local b = NewObject("/Script/UMG.Border", parent)
    if IsValid(b) then
        pcall(function()
            b:SetBrushColor(color)
            if radius and radius > 0 then
                -- 1. Стандартный метод SetCornerRadius
                pcall(function() b:SetCornerRadius(radius) end)
                -- 2. Вариант через FVector4 (Left, Top, Right, Bottom)
                pcall(function()
                    local FVector4 = import("Vector4")
                    if FVector4 then b:SetCornerRadius(FVector4(radius, radius, radius, radius)) end
                end)
                -- 3. Вариант через свойство Brush.OutlineSettings
                pcall(function()
                    if b.Brush then
                        b.Brush.DrawAs = UEnums and UEnums.ESlateBrushDrawType and UEnums.ESlateBrushDrawType.RoundedBox or 3
                    end
                end)
            end
            b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
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
            tb:SetFont({ Size = fontSize or 12, Typeface = "Regular" })
            tb:SetColorAndOpacity(FSlateColor(color or C.TextDark))
            tb:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local slot = parent:AddChildToCanvas(tb)
        if slot then
            slot:SetAutoSize(true)
            slot:SetPosition(FVector2D(x, y))
            slot:SetAlignment(FVector2D(alignX or 0.0, alignY or 0.0))
            slot:SetZOrder(zOrder or 1)
        end
    end
    return tb
end

local function MakeBtn(parent, x, y, w, h, zOrder, onClick)
    local btn = NewObject("/Script/UMG.Button", parent)
    if IsValid(btn) then
        pcall(function()
            btn:SetBackgroundColor(C.Transparent)
            btn:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
        end)
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

-- ==============================================================================
-- 2. ВЕРХНИЙ ПЛАВАЮЩИЙ БАР (TOP FLOATING PILL) - ПОЛУПРОЗРАЧНЫЙ И ЧИТАЕМЫЙ
-- ==============================================================================
local function CreateTopPill(canvas)
    local vpW, _ = GetViewport()
    local pillW, pillH = 370, 38
    local pillX = math.floor((vpW - pillW) * 0.5)
    local pillY = 12

    -- Тень бара
    Layer(canvas, pillX, pillY + 3, pillW, pillH, C.Shadow, 9997, 19)
    -- Внешняя тонкая светлая окантовка стекла
    Layer(canvas, pillX - 1, pillY - 1, pillW + 2, pillH + 2, C.TopPillBorder, 9998, 20)
    -- Темное полупрозрачное стекло (теперь текст никогда не сольется!)
    Layer(canvas, pillX, pillY, pillW, pillH, C.TopPillBg, 9999, 19)

    -- Секция 1: Часы (реальное системное время)
    clockTextBlock = Text(canvas, os.date("%H:%M:%S"), pillX + 42, pillY + 19, 13, C.TopPillText, 10001, 0.5, 0.5)

    -- Разделитель 1
    Layer(canvas, pillX + 85, pillY + 10, 1.5, 18, C.TopPillDiv, 10001, 1)

    -- Секция 2: Название чита с акцентным цветом
    Text(canvas, "Mango Cheats", pillX + 155, pillY + 19, 13, C.TopPillAccent, 10001, 0.5, 0.5)

    -- Разделитель 2
    Layer(canvas, pillX + 225, pillY + 10, 1.5, 18, C.TopPillDiv, 10001, 1)

    -- Секция 3: Статус лицензии
    Text(canvas, "Expired 999 days", pillX + 298, pillY + 19, 12, C.TopPillText, 10001, 0.5, 0.5)

    -- Таймер автообновления часов каждую секунду
    local ticker = require("common.time_ticker")
    local function tickClock()
        if IsValid(clockTextBlock) then
            pcall(function() clockTextBlock:SetText(os.date("%H:%M:%S")) end)
        end
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(1.0, tickClock)
        end
    end
    tickClock()
end

-- ==============================================================================
-- 3. ПЕРЕКЛЮЧАТЕЛЬ И СТРОКА ТАБЛИЦЫ
-- ==============================================================================
local function DrawToggle(parent, x, y, configKey)
    local tw, th = 42, 24
    local on = Config[configKey]
    local track = Layer(parent, x, y, tw, th, on and C.ToggleOn or C.ToggleOff, 12, 12)

    local kw, kh = 18, 18
    local knobX = on and (x + 21) or (x + 3)
    local knobY = y + 3
    local knob = Layer(parent, knobX, knobY, kw, kh, C.KnobWhite, 14, 9)

    MakeBtn(parent, x - 5, y - 5, tw + 10, th + 10, 16, function()
        Config[configKey] = not Config[configKey]
        local isNowOn = Config[configKey]
        if IsValid(track) then
            track:SetBrushColor(isNowOn and C.ToggleOn or C.ToggleOff)
        end
        if IsValid(knob) and knob.Slot then
            local targetX = isNowOn and (x + 21) or (x + 3)
            knob.Slot:SetPosition(FVector2D(targetX, knobY))
        end
    end)
end

local function DrawRow(parent, labelText, yPos, configKey)
    -- Текст названия функции слева
    Text(parent, labelText, 119, yPos + 12, 13, C.TextDark, 12, 0.0, 0.5)
    -- Переключатель справа
    DrawToggle(parent, 570, yPos, configKey)
end

-- ==============================================================================
-- 4. САЙДБАР С 6 ВКЛАДКАМИ
-- ==============================================================================
local function DrawSidebar(parent)
    -- Фон сайдбара
    Layer(parent, SIDEBAR_X, SIDEBAR_Y, SIDEBAR_W, SIDEBAR_H, C.SidebarBg, 5, 20)

    -- 1. User
    Layer(parent, SIDEBAR_X + 23.5, SIDEBAR_Y + 13, 36, 36, C.IconUser, 10, 18)
    Text(parent, "A", SIDEBAR_X + 41.5, SIDEBAR_Y + 31, 14, C.KnobWhite, 12, 0.5, 0.5)
    Text(parent, "User", SIDEBAR_X + 41.5, SIDEBAR_Y + 58, 10, C.TextUser, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 5, SIDEBAR_W, 60, 20, function()
        currentTab = "User"
        RenderContent()
    end)

    -- 2. MAIN
    Layer(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 81, 28, 28, C.IconMain, 10, 8)
    Text(parent, "⌂", SIDEBAR_X + 41.5, SIDEBAR_Y + 95, 14, C.KnobWhite, 12, 0.5, 0.5)
    Text(parent, "MAIN", SIDEBAR_X + 41.5, SIDEBAR_Y + 118, 9, C.TextDark, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 72, SIDEBAR_W, 60, 20, function()
        currentTab = "MAIN"
        RenderContent()
    end)

    -- 3. ESP (Активная вкладка)
    Layer(parent, SIDEBAR_X, SIDEBAR_Y + 132, SIDEBAR_W, 60, C.SidebarTabActive, 8, 0)
    Layer(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 141, 28, 28, C.IconESP, 10, 8)
    Text(parent, "👁", SIDEBAR_X + 41.5, SIDEBAR_Y + 155, 13, C.KnobWhite, 12, 0.5, 0.5)
    Text(parent, "ESP", SIDEBAR_X + 41.5, SIDEBAR_Y + 178, 10, C.TextActiveESP, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 132, SIDEBAR_W, 60, 20, function()
        currentTab = "ESP"
        RenderContent()
    end)

    -- 4. AIM
    Layer(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 201, 28, 28, C.IconAim, 10, 8)
    Text(parent, "🎯", SIDEBAR_X + 41.5, SIDEBAR_Y + 215, 13, C.KnobWhite, 12, 0.5, 0.5)
    Text(parent, "AIM", SIDEBAR_X + 41.5, SIDEBAR_Y + 238, 10, C.TextDark, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 192, SIDEBAR_W, 60, 20, function()
        currentTab = "AIM"
        RenderContent()
    end)

    -- 5. MEM
    Layer(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 261, 28, 28, C.IconMem, 10, 8)
    Text(parent, "⚡", SIDEBAR_X + 41.5, SIDEBAR_Y + 275, 13, C.KnobWhite, 12, 0.5, 0.5)
    Text(parent, "MEM", SIDEBAR_X + 41.5, SIDEBAR_Y + 298, 10, C.TextDark, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 252, SIDEBAR_W, 60, 20, function()
        currentTab = "MEM"
        RenderContent()
    end)

    -- 6. SET
    Layer(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 321, 28, 28, C.IconSet, 10, 8)
    Text(parent, "⚙", SIDEBAR_X + 41.5, SIDEBAR_Y + 335, 14, C.KnobWhite, 12, 0.5, 0.5)
    Text(parent, "SET", SIDEBAR_X + 41.5, SIDEBAR_Y + 358, 10, C.TextDark, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 312, SIDEBAR_W, 60, 20, function()
        currentTab = "SET"
        RenderContent()
    end)
end

-- ==============================================================================
-- 5. СОДЕРЖИМОЕ ОКНА (ESP И ДРУГИЕ РАЗДЕЛЫ)
-- ==============================================================================
function RenderContent()
    if not IsValid(contentContainer) then return end
    contentContainer:ClearChildren()

    if currentTab == "ESP" then
        -- Заголовок по центру: "ESP"
        Text(contentContainer, "ESP", 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)

        -- Зелёный квадратик группы (x=119, y=62, w=12, h=12, rx=2)
        Layer(contentContainer, 119, 62, 12, 12, C.CategorySquare, 10, 2)
        -- Название группы: "Character"
        Text(contentContainer, "Character", 138, 68, 12, C.TextCategory, 12, 0.0, 0.5)

        -- Главный разделитель (x=119, y=84, w=493, h=1)
        Layer(contentContainer, 119, 84, 493, 1, C.DividerTop, 10)

        -- Строка 1: Box (y=95, divider y=129)
        DrawRow(contentContainer, "Box", 95, "Box")
        Layer(contentContainer, 119, 129, 493, 1, C.DividerRow, 10)

        -- Строка 2: Line (y=140, divider y=174)
        DrawRow(contentContainer, "Line", 140, "Line")
        Layer(contentContainer, 119, 174, 493, 1, C.DividerRow, 10)

        -- Строка 3: Skeleton (y=185, divider y=219)
        DrawRow(contentContainer, "Skeleton", 185, "Skeleton")
        Layer(contentContainer, 119, 219, 493, 1, C.DividerRow, 10)

        -- Строка 4: Name and dist (y=230, divider y=264)
        DrawRow(contentContainer, "Name and dist", 230, "NameDist")
        Layer(contentContainer, 119, 264, 493, 1, C.DividerRow, 10)

        -- Строка 5: Health (y=275)
        DrawRow(contentContainer, "Health", 275, "Health")
    else
        Text(contentContainer, currentTab, 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)
        Text(contentContainer, "Раздел " .. currentTab .. " в разработке", 119, 95, 13, C.TextUser, 12, 0.0, 0.0)
    end
end

-- ==============================================================================
-- 6. СБОРКА ОСНОВНОГО ОКНА МЕНЮ
-- ==============================================================================
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
    Layer(bgPanel, 4, 4, MENU_W, MENU_H, C.Shadow, 1, 25)
    -- Внешняя тонкая светлая рамка стекла
    Layer(bgPanel, -1, -1, MENU_W + 2, MENU_H + 2, C.BorderOutline, 2, 26)
    -- Основной корпус окна: матовое полупрозрачное стекло
    Layer(bgPanel, 0, 0, MENU_W, MENU_H, C.WindowBg, 3, 25)

    -- Кнопка закрытия окна (справа сверху: x=601, y=9, w=27, h=23, rx=11.5)
    Layer(bgPanel, 601, 9, 27, 23, C.ClosePillBg, 15, 11.5)
    Text(bgPanel, "✕", 614.5, 20.5, 13, C.CloseCross, 16, 0.5, 0.5)
    MakeBtn(bgPanel, 595, 5, 40, 32, 20, function()
        ToggleMenu(canvas)
    end)

    -- Отрисовка сайдбара
    DrawSidebar(bgPanel)

    -- Контейнер контента
    contentContainer = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local cSlot = bgPanel:AddChildToCanvas(contentContainer)
    cSlot:SetPosition(FVector2D(0, 0))
    cSlot:SetSize(FVector2D(MENU_W, MENU_H))
    cSlot:SetZOrder(10)

    RenderContent()
    isMenuOpen = true
end

-- ==============================================================================
-- 7. НИЖНИЙ ИНДИКАТОР HOME (IOS HOME BAR) + СВАЙП/ТАП
-- ==============================================================================
local function CreateFloatButton(canvas)
    if floatItem and IsValid(floatItem.bg) then return end
    floatItem = { touchStartY = 0, touchStartTime = 0, swiping = false }

    local vpW, vpH = GetViewport()
    local fX = math.floor((vpW - INDICATOR_W) * 0.5)
    local fY = vpH - 16

    -- Тень и белая плашка 226x5 rx=2.5
    Layer(canvas, fX, fY + 1, INDICATOR_W, INDICATOR_H, C.Shadow, 11898, 2.5)
    floatItem.bg = Layer(canvas, fX, fY, INDICATOR_W, INDICATOR_H, C.IndicatorWhite, 11901, 2.5)

    -- Интерактивная зона для свайпа и клика
    local hitW, hitH = 280, 60
    local hitArea = Layer(canvas, fX + (INDICATOR_W - hitW) * 0.5, vpH - hitH, hitW, hitH, C.Transparent, 12000)

    local function onTouchStart(_, _, loc)
        floatItem.touchStartY = loc.Y
        floatItem.touchStartTime = os.clock()
        floatItem.swiping = false
    end

    local function onTouchMove(_, _, loc)
        if not floatItem.touchStartY then return end
        if (loc.Y - floatItem.touchStartY) < -35 and not floatItem.swiping then
            floatItem.swiping = true
            ToggleMenu(canvas)
        end
    end

    local function onTouchEnd(_, _, loc)
        local dt = os.clock() - floatItem.touchStartTime
        local dy = loc.Y - floatItem.touchStartY
        if dt < 0.35 and math.abs(dy) < 25 and not floatItem.swiping then
            ToggleMenu(canvas)
        end
        floatItem.touchStartY = 0
        floatItem.swiping = false
    end

    pcall(function()
        if hitArea.OnTouchStarted then hitArea.OnTouchStarted:Add(onTouchStart) end
        if hitArea.OnTouchMoved then hitArea.OnTouchMoved:Add(onTouchMove) end
        if hitArea.OnTouchEnded then hitArea.OnTouchEnded:Add(onTouchEnd) end
    end)

    floatItem.btn = MakeBtn(canvas, fX + (INDICATOR_W - hitW) * 0.5, vpH - hitH, hitW, hitH, 12001, function()
        ToggleMenu(canvas)
    end)
end

function ToggleMenu(canvas)
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        if IsValid(bgPanel) then
            bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        else
            BuildMenu(canvas)
        end
        if floatItem and floatItem.bg then
            floatItem.bg:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
    else
        if IsValid(bgPanel) then
            bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
        if floatItem and floatItem.bg then
            floatItem.bg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end
    end
end

-- ==============================================================================
-- 8. ИНИЦИАЛИЗАЦИЯ И ХУКИ
-- ==============================================================================
local function GetCanvas()
    if IsValid(parentCanvas) then return parentCanvas end
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
    if GetViewport() < 600 then return end

    CreateTopPill(canvas)
    CreateFloatButton(canvas)

    if floatItem and IsValid(floatItem.bg) then
        _initDone = true
        print("[SodaLite] 1:1 SVG Menu Initialized Successfully")
    end
end

local function InitWatcher()
    if _initDone then return end
    pcall(TryInit)
    if not _initDone then
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(0.5, InitWatcher)
        end
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
