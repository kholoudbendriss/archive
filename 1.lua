-- ==============================================================================
-- SODALITE UI - 1:1 PIXEL-PERFECT REPLICA (Smooth Capsule & Responsive Layout)
-- Top Floating Pill: [ 17:31:25 | Mango Cheats | Expend 999 day ] (Slate Grey Glass)
-- Main Window: Matching Slate Grey Glass (640x411, rx=25) with dynamic viewport centering
-- Menu starts CLOSED by default (Clean screen at startup, opens on Home bar tap)
-- Working Close Button (✕) with direct CloseMenu handler & dual touch/click binding
-- Dynamic Home Indicator anchored to bottom-center with instant OpenMenu handler
-- High-Resolution 1px-Raster Merged Rounded Geometry (Eliminates stair-step pixelation)
-- Procedural Vector Icons for 100% font compatibility (User, MAIN, ESP, AIM, MEM, SET)
-- ==============================================================================

local BRPlayerCharacterBase = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {} }

-- 1. БЕЗОПАСНЫЕ ТИПЫ И ЦВЕТОВАЯ ПАЛИТРА
local function FLinearColor(r, g, b, a)
    local col = { R = r or 1, G = g or 1, B = b or 1, A = a or 1 }
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
    local vec = { X = x or 0, Y = y or 0 }
    local ok, V = pcall(import, "Vector2D")
    if ok and V then return V(x or 0, y or 0) end
    return vec
end

local function GetSlateVis(visName)
    if UEnums and UEnums.ESlateVisibility and UEnums.ESlateVisibility[visName] ~= nil then
        return UEnums.ESlateVisibility[visName]
    end
    local ok, ue = pcall(import, "UEnums")
    if ok and ue and ue.ESlateVisibility and ue.ESlateVisibility[visName] ~= nil then
        return ue.ESlateVisibility[visName]
    end
    local map = {
        Visible = 0,
        Collapsed = 1,
        Hidden = 2,
        HitTestInvisible = 3,
        SelfHitTestInvisible = 4,
    }
    return map[visName] or 0
end

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

local function SetVis(widget, visName)
    if not IsValid(widget) then return end
    pcall(function()
        widget:SetWidgetVisibility(GetSlateVis(visName))
    end)
end

-- Цветовая палитра: единый темно-серый стиль Slate Grey (RGB 118, 124, 134)
local C = {
    -- Главный корпус окна (Slate Grey матовое стекло)
    WindowBg        = FLinearColor(0.463, 0.486, 0.525, 0.92), -- #767C86 92%
    Outline         = FLinearColor(1.0, 1.0, 1.0, 0.35),
    Shadow          = FLinearColor(0.0, 0.0, 0.0, 0.30),

    -- Сайдбар слева
    SidebarBg       = FLinearColor(0.380, 0.405, 0.445, 0.85),
    SidebarActiveBg = FLinearColor(0.537, 0.843, 0.710, 0.25), -- мятный акцент

    -- Иконки сайдбара
    IconUser        = FLinearColor(0.29, 0.56, 0.85, 1.0), -- #4A90D9
    IconMain        = FLinearColor(0.36, 0.55, 0.94, 1.0), -- #5B8DEF
    IconESP         = FLinearColor(0.537, 0.843, 0.710, 1.0), -- мятный #89D7B5
    IconAim         = FLinearColor(0.96, 0.65, 0.14, 1.0), -- #F5A623
    IconMem         = FLinearColor(0.48, 0.41, 0.93, 1.0), -- #7B68EE
    IconSet         = FLinearColor(0.65, 0.68, 0.72, 1.0),

    -- Текстовые метки
    TextDark        = FLinearColor(0.96, 0.97, 0.98, 0.98), -- четкий светлый текст
    TextActiveESP   = FLinearColor(0.537, 0.843, 0.710, 1.0),
    TextUser        = FLinearColor(0.85, 0.88, 0.92, 0.90),

    TextTitle       = FLinearColor(1.0, 1.0, 1.0, 0.98),
    TextCategory    = FLinearColor(0.96, 0.97, 0.98, 0.98),
    CategorySquare  = FLinearColor(0.537, 0.843, 0.710, 1.0),

    -- Разделители таблицы
    DividerTop      = FLinearColor(1.0, 1.0, 1.0, 0.25),
    DividerRow      = FLinearColor(1.0, 1.0, 1.0, 0.15),

    -- Переключатели
    ToggleOn        = FLinearColor(0.537, 0.843, 0.710, 1.0), -- мятный #89D7B5
    ToggleOff       = FLinearColor(0.36, 0.38, 0.42, 1.0),
    KnobWhite       = FLinearColor(1.0, 1.0, 1.0, 1.0),

    -- Кнопка закрытия окна
    CloseBtnBg      = FLinearColor(0.380, 0.405, 0.445, 0.80),
    CloseCross      = FLinearColor(0.95, 0.35, 0.35, 1.0),

    -- Верхний плавающий бар (Top Pill: 1 в 1 как на скриншоте)
    TopPillBg       = FLinearColor(0.463, 0.486, 0.525, 0.85), -- #767C86 85%
    TopPillOutline  = FLinearColor(1.0, 1.0, 1.0, 0.30),
    TopPillShadow   = FLinearColor(0.0, 0.0, 0.0, 0.25),
    TopPillClock    = FLinearColor(1.0, 1.0, 1.0, 0.98), -- 17:31:25
    TopPillTitle    = FLinearColor(0.537, 0.843, 0.710, 1.0), -- мятный Mango Cheats
    TopPillStatus   = FLinearColor(1.0, 1.0, 1.0, 0.98), -- Expend 999 day
    TopPillDiv      = FLinearColor(1.0, 1.0, 1.0, 0.85),

    -- Нижний индикатор
    IndicatorWhite  = FLinearColor(1.0, 1.0, 1.0, 0.95),

    Transparent     = FLinearColor(0.0, 0.0, 0.0, 0.0),
}

-- Размеры по menu.svg
local MENU_W, MENU_H        = 640, 411
local SIDEBAR_X, SIDEBAR_Y  = 10, 8
local SIDEBAR_W, SIDEBAR_H  = 83, 396
local INDICATOR_W           = 226
local INDICATOR_H           = 5

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
local bgSlot = nil
local floatContainer = nil
local floatSlot = nil
local topPillContainer = nil
local topPillSlot = nil
local contentContainer = nil
local parentCanvas = nil
local isMenuOpen = false
local clockTextBlock = nil

local function GetViewport()
    local vpW, vpH = 1280, 720
    pcall(function()
        local ui_util = require("client.common.ui_util")
        if ui_util and ui_util.GetViewportSize then
            local sz = ui_util.GetViewportSize()
            if sz and sz.X and sz.X > 50 and sz.Y and sz.Y > 50 then
                vpW = sz.X
                vpH = sz.Y
            end
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

local function Layer(parent, x, y, w, h, color, zOrder)
    local b = NewObject("/Script/UMG.Border", parent)
    if IsValid(b) then
        pcall(function()
            b:SetBrushColor(color)
        end)
        SetVis(b, "SelfHitTestInvisible")
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

-- ==============================================================================
-- 2. ВЫСОКОТОЧНЫЙ 1px RASTER ЗАКРУГЛИТЕЛЬ ПАНЕЛЕЙ (БЕЗ ПИКСЕЛЬНЫХ СТУПЕНЕК)
-- Точное вычисление окружности с шагом в 1 пиксель и объединением смежных линий
-- ==============================================================================
local function RoundedPanel(parent, x, y, w, h, r, color, zOrder)
    local container = NewObject("/Script/UMG.CanvasPanel", parent)
    if not IsValid(container) then return nil end
    local cSlot = parent:AddChildToCanvas(container)
    if cSlot then
        cSlot:SetAutoSize(false)
        cSlot:SetPosition(FVector2D(x, y))
        cSlot:SetSize(FVector2D(w, h))
        cSlot:SetZOrder(zOrder or 0)
    end
    SetVis(container, "SelfHitTestInvisible")

    r = math.min(math.floor(r or 12), math.floor(h * 0.5), math.floor(w * 0.5))
    if r < 1 then
        Layer(container, 0, 0, w, h, color, 0)
        return container
    end

    -- 1-пиксельный точный расчет смещения dx по формуле окружности
    local top_dx = {}
    for i = 0, r - 1 do
        local dy = r - (i + 0.5)
        local dx = math.floor(r - math.sqrt(math.max(0, r * r - dy * dy)) + 0.5)
        top_dx[#top_dx + 1] = dx
    end

    -- Слияние смежных одинаковых строк в один непрерывный прямоугольник
    local merged = {}
    local curDx = top_dx[1]
    local curY = 0
    local curH = 1
    for i = 2, #top_dx do
        if top_dx[i] == curDx then
            curH = curH + 1
        else
            merged[#merged + 1] = { dx = curDx, y = curY, h = curH }
            curDx = top_dx[i]
            curY = i - 1
            curH = 1
        end
    end
    merged[#merged + 1] = { dx = curDx, y = curY, h = curH }

    -- Верхний свод капсулы
    for _, s in ipairs(merged) do
        Layer(container, s.dx, s.y, w - 2 * s.dx, s.h, color, 0)
    end

    -- Центральный блок
    local midH = h - 2 * r
    if midH > 0 then
        Layer(container, 0, r, w, midH, color, 0)
    end

    -- Нижний свод капсулы (симметричный реверс)
    for _, s in ipairs(merged) do
        local by = h - s.y - s.h
        Layer(container, s.dx, by, w - 2 * s.dx, s.h, color, 0)
    end

    return container
end

local function Text(parent, text, x, y, fontSize, color, zOrder, alignX, alignY)
    local tb = NewObject("/Script/UMG.TextBlock", parent)
    if IsValid(tb) then
        pcall(function()
            tb:SetText(tostring(text or ""))
            tb:SetFont({ Size = fontSize or 12, Typeface = "Regular" })
            tb:SetColorAndOpacity(FSlateColor(color or C.TextDark))
        end)
        SetVis(tb, "SelfHitTestInvisible")
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
            btn:SetColorAndOpacity(C.Transparent)
            btn:SetBackgroundColor(C.Transparent)
        end)
        SetVis(btn, "Visible")
        local slot = parent:AddChildToCanvas(btn)
        if slot then
            slot:SetAutoSize(false)
            slot:SetPosition(FVector2D(x, y))
            slot:SetSize(FVector2D(w, h))
            slot:SetZOrder(zOrder or 1000)
        end
        if onClick then
            local lastTrigger = 0
            local function handleTrigger()
                local now = os.clock()
                if (now - lastTrigger) < 0.25 then return end
                lastTrigger = now
                pcall(onClick)
            end
            pcall(function()
                if btn.OnClicked then btn.OnClicked:Add(handleTrigger) end
                if btn.OnPressed then btn.OnPressed:Add(handleTrigger) end
            end)
        end
    end
    return btn
end

-- ==============================================================================
-- 3. ВЕРХНИЙ ПЛАВАЮЩИЙ БАР (TOP FLOATING PILL) - SLATE GREY (КАК НА СКРИНШОТЕ)
-- [ 17:31:25 | Mango Cheats | Expend 999 day ]
-- ==============================================================================
local function CreateTopPill(canvas)
    if IsValid(topPillContainer) then return end
    local vpW, _ = GetViewport()
    local pillW, pillH = 363, 38
    local pr = 19
    local pillX = math.floor((vpW - pillW) * 0.5)

    topPillContainer = NewObject("/Script/UMG.CanvasPanel", canvas)
    topPillSlot = canvas:AddChildToCanvas(topPillContainer)
    if topPillSlot then
        topPillSlot:SetAutoSize(false)
        topPillSlot:SetPosition(FVector2D(pillX, 12))
        topPillSlot:SetSize(FVector2D(pillW, pillH))
        topPillSlot:SetZOrder(10000)
    end
    SetVis(topPillContainer, "SelfHitTestInvisible")

    -- 1. Тень капсулы (dy=3)
    RoundedPanel(topPillContainer, 0, 3, pillW, pillH, pr, C.TopPillShadow, 1)

    -- 2. Тонкая светлая окантовка
    RoundedPanel(topPillContainer, -1, -1, pillW + 2, pillH + 2, pr + 1, C.TopPillOutline, 2)

    -- 3. Основной корпус капсулы: цвет Slate Grey (118, 124, 134, 85%)
    RoundedPanel(topPillContainer, 0, 0, pillW, pillH, pr, C.TopPillBg, 3)

    -- Секция 1: Часы (реальное системное время с секундами 17:31:25)
    clockTextBlock = Text(topPillContainer, os.date("%H:%M:%S"), 55, 19, 13, C.TopPillClock, 10, 0.5, 0.5)

    -- Разделитель 1: |
    Text(topPillContainer, "|", 104, 19, 12, C.TopPillDiv, 10, 0.5, 0.5)

    -- Секция 2: Название чита (Mango Cheats) - сочный мятно-зеленый (137, 215, 181)
    Text(topPillContainer, "Mango Cheats", 168, 19, 13, C.TopPillTitle, 10, 0.5, 0.5)

    -- Разделитель 2: |
    Text(topPillContainer, "|", 232, 19, 12, C.TopPillDiv, 10, 0.5, 0.5)

    -- Секция 3: Статус лицензии (Expend 999 day)
    Text(topPillContainer, "Expend 999 day", 296, 19, 12, C.TopPillStatus, 10, 0.5, 0.5)
end

-- ==============================================================================
-- 4. ПЕРЕКЛЮЧАТЕЛЬ И СТРОКА ТАБЛИЦЫ
-- ==============================================================================
local function DrawToggle(parent, x, y, configKey)
    local tw, th = 42, 24
    local tr = 12
    local on = Config[configKey]
    local trackColor = on and C.ToggleOn or C.ToggleOff

    RoundedPanel(parent, x, y, tw, th, tr, trackColor, 12)

    local kw, kh = 18, 18
    local kr = 9
    local knobX = on and (x + 21) or (x + 3)
    local knobY = y + 3
    RoundedPanel(parent, knobX, knobY, kw, kh, kr, C.KnobWhite, 14)

    MakeBtn(parent, x - 5, y - 5, tw + 10, th + 10, 16, function()
        Config[configKey] = not Config[configKey]
        RenderContent()
    end)
end

local function DrawRow(parent, labelText, yPos, configKey)
    Text(parent, labelText, 119, yPos + 12, 13, C.TextDark, 12, 0.0, 0.5)
    DrawToggle(parent, 570, yPos, configKey)
end

-- ==============================================================================
-- 5. ПРОЦЕДУРНЫЕ ВЕКТОРНЫЕ ИКОНКИ САЙДБАРА
-- ==============================================================================
local function DrawHouseIcon(parent, ox, oy)
    Layer(parent, ox + 12, oy + 6,  4, 2, C.KnobWhite, 15)
    Layer(parent, ox + 10, oy + 8,  8, 2, C.KnobWhite, 15)
    Layer(parent, ox + 7,  oy + 10, 14, 2, C.KnobWhite, 15)
    Layer(parent, ox + 9,  oy + 12, 10, 9, C.KnobWhite, 15)
    Layer(parent, ox + 12, oy + 15, 4, 6, C.IconMain, 16)
end

local function DrawEyeIcon(parent, ox, oy)
    Layer(parent, ox + 8,  oy + 9,  12, 2, C.KnobWhite, 15)
    Layer(parent, ox + 5,  oy + 11, 18, 6, C.KnobWhite, 15)
    Layer(parent, ox + 8,  oy + 17, 12, 2, C.KnobWhite, 15)
    Layer(parent, ox + 11, oy + 11, 6, 6, C.IconESP, 16)
    Layer(parent, ox + 13, oy + 13, 2, 2, C.KnobWhite, 17)
end

local function DrawAimIcon(parent, ox, oy)
    Layer(parent, ox + 9,  oy + 6,  10, 2, C.KnobWhite, 15)
    Layer(parent, ox + 9,  oy + 20, 10, 2, C.KnobWhite, 15)
    Layer(parent, ox + 6,  oy + 9,  2, 10, C.KnobWhite, 15)
    Layer(parent, ox + 20, oy + 9,  2, 10, C.KnobWhite, 15)
    Layer(parent, ox + 13, oy + 4,  2, 5, C.KnobWhite, 15)
    Layer(parent, ox + 13, oy + 19, 2, 5, C.KnobWhite, 15)
    Layer(parent, ox + 4,  oy + 13, 5, 2, C.KnobWhite, 15)
    Layer(parent, ox + 19, oy + 13, 5, 2, C.KnobWhite, 15)
    Layer(parent, ox + 12, oy + 12, 4, 4, C.KnobWhite, 15)
end

local function DrawMemIcon(parent, ox, oy)
    Layer(parent, ox + 8,  oy + 8,  12, 12, C.KnobWhite, 15)
    Layer(parent, ox + 10, oy + 10, 8, 8,   C.IconMem, 16)
    Layer(parent, ox + 12, oy + 12, 4, 4,   C.KnobWhite, 17)
    for _, p in ipairs({10, 16}) do
        Layer(parent, ox + p,  oy + 5,  2, 3, C.KnobWhite, 15)
        Layer(parent, ox + p,  oy + 20, 2, 3, C.KnobWhite, 15)
        Layer(parent, ox + 5,  oy + p,  3, 2, C.KnobWhite, 15)
        Layer(parent, ox + 20, oy + p,  3, 2, C.KnobWhite, 15)
    end
end

local function DrawSetIcon(parent, ox, oy)
    Layer(parent, ox + 8,  oy + 8,  12, 12, C.KnobWhite, 15)
    Layer(parent, ox + 11, oy + 11, 6, 6,   C.IconSet, 16)
    Layer(parent, ox + 12, oy + 5,  4, 3, C.KnobWhite, 15)
    Layer(parent, ox + 12, oy + 20, 4, 3, C.KnobWhite, 15)
    Layer(parent, ox + 5,  oy + 12, 3, 4, C.KnobWhite, 15)
    Layer(parent, ox + 20, oy + 12, 3, 4, C.KnobWhite, 15)
end

-- ==============================================================================
-- 6. САЙДБАР С 6 ВКЛАДКАМИ
-- ==============================================================================
local function DrawSidebar(parent)
    local sr = 20
    RoundedPanel(parent, SIDEBAR_X, SIDEBAR_Y, SIDEBAR_W, SIDEBAR_H, sr, C.SidebarBg, 5)

    -- 1. User
    RoundedPanel(parent, SIDEBAR_X + 23.5, SIDEBAR_Y + 13, 36, 36, 18, C.IconUser, 10)
    Text(parent, "A", SIDEBAR_X + 41.5, SIDEBAR_Y + 31, 15, C.KnobWhite, 12, 0.5, 0.5)
    Text(parent, "User", SIDEBAR_X + 41.5, SIDEBAR_Y + 58, 10, C.TextUser, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 5, SIDEBAR_W, 60, 20, function()
        currentTab = "User"
        RenderContent()
    end)

    -- 2. MAIN
    RoundedPanel(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 81, 28, 28, 8, C.IconMain, 10)
    DrawHouseIcon(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 81)
    Text(parent, "MAIN", SIDEBAR_X + 41.5, SIDEBAR_Y + 118, 9, C.TextDark, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 72, SIDEBAR_W, 60, 20, function()
        currentTab = "MAIN"
        RenderContent()
    end)

    -- 3. ESP (Активная вкладка)
    RoundedPanel(parent, SIDEBAR_X, SIDEBAR_Y + 132, SIDEBAR_W, 60, 12, C.SidebarActiveBg, 7)
    RoundedPanel(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 141, 28, 28, 8, C.IconESP, 10)
    DrawEyeIcon(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 141)
    Text(parent, "ESP", SIDEBAR_X + 41.5, SIDEBAR_Y + 178, 10, C.TextActiveESP, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 132, SIDEBAR_W, 60, 20, function()
        currentTab = "ESP"
        RenderContent()
    end)

    -- 4. AIM
    RoundedPanel(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 201, 28, 28, 8, C.IconAim, 10)
    DrawAimIcon(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 201)
    Text(parent, "AIM", SIDEBAR_X + 41.5, SIDEBAR_Y + 238, 10, C.TextDark, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 192, SIDEBAR_W, 60, 20, function()
        currentTab = "AIM"
        RenderContent()
    end)

    -- 5. MEM
    RoundedPanel(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 261, 28, 28, 8, C.IconMem, 10)
    DrawMemIcon(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 261)
    Text(parent, "MEM", SIDEBAR_X + 41.5, SIDEBAR_Y + 298, 10, C.TextDark, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 252, SIDEBAR_W, 60, 20, function()
        currentTab = "MEM"
        RenderContent()
    end)

    -- 6. SET
    RoundedPanel(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 321, 28, 28, 8, C.IconSet, 10)
    DrawSetIcon(parent, SIDEBAR_X + 27.5, SIDEBAR_Y + 321)
    Text(parent, "SET", SIDEBAR_X + 41.5, SIDEBAR_Y + 358, 10, C.TextDark, 12, 0.5, 0.5)
    MakeBtn(parent, SIDEBAR_X, SIDEBAR_Y + 312, SIDEBAR_W, 60, 20, function()
        currentTab = "SET"
        RenderContent()
    end)
end

-- ==============================================================================
-- 7. СОДЕРЖИМОЕ ОКНА
-- ==============================================================================
function RenderContent()
    if not IsValid(contentContainer) then return end
    contentContainer:ClearChildren()

    if currentTab == "ESP" then
        Text(contentContainer, "ESP", 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)

        Layer(contentContainer, 119, 62, 12, 12, C.CategorySquare, 10)
        Text(contentContainer, "Character", 138, 68, 12, C.TextCategory, 12, 0.0, 0.5)

        Layer(contentContainer, 119, 84, 493, 1, C.DividerTop, 10)

        DrawRow(contentContainer, "Box", 95, "Box")
        Layer(contentContainer, 119, 129, 493, 1, C.DividerRow, 10)

        DrawRow(contentContainer, "Line", 140, "Line")
        Layer(contentContainer, 119, 174, 493, 1, C.DividerRow, 10)

        DrawRow(contentContainer, "Skeleton", 185, "Skeleton")
        Layer(contentContainer, 119, 219, 493, 1, C.DividerRow, 10)

        DrawRow(contentContainer, "Name and dist", 230, "NameDist")
        Layer(contentContainer, 119, 264, 493, 1, C.DividerRow, 10)

        DrawRow(contentContainer, "Health", 275, "Health")
    else
        Text(contentContainer, currentTab, 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)
        Text(contentContainer, "Раздел " .. currentTab .. " в разработке", 119, 95, 13, C.TextUser, 12, 0.0, 0.0)
    end
end

-- ==============================================================================
-- 8. АДАПТИВНОЕ ЦЕНТРИРОВАНИЕ ВИДЖЕТОВ ПО РАЗМЕРУ ВЬЮПОРТА
-- ==============================================================================
local function UpdateLayoutPositions(vpW, vpH)
    -- 1. Центрирование плавающего бара вверху
    if topPillSlot then
        local pillW = 363
        local pillX = math.floor((vpW - pillW) * 0.5)
        pcall(function()
            topPillSlot:SetPosition(FVector2D(pillX, 12))
        end)
    end

    -- 2. Перемещение Home-индикатора точно к текущему низу экрана
    if floatSlot then
        local hitW, hitH = 280, 50
        local fX = math.floor((vpW - hitW) * 0.5)
        local fY = vpH - hitH - 8
        pcall(function()
            floatSlot:SetPosition(FVector2D(fX, fY))
        end)
    end

    -- 3. Центрирование главного меню
    if IsValid(bgPanel) and bgSlot then
        local posX = math.max(0, math.floor((vpW - MENU_W) * 0.5))
        local posY = math.max(0, math.floor((vpH - MENU_H) * 0.5))
        pcall(function()
            bgSlot:SetPosition(FVector2D(posX, posY))
        end)
    end
end

-- ==============================================================================
-- 9. УПРАВЛЕНИЕ ОТКРЫТИЕМ И ЗАКРЫТИЕМ МЕНЮ
-- ==============================================================================
local function CloseMenu()
    isMenuOpen = false
    if IsValid(bgPanel) then
        SetVis(bgPanel, "Collapsed")
    end
    if IsValid(floatContainer) then
        SetVis(floatContainer, "SelfHitTestInvisible")
    end
end

local function OpenMenu(canvas)
    isMenuOpen = true
    local c = canvas or parentCanvas or GetCanvas()
    if IsValid(bgPanel) then
        local vpW, vpH = GetViewport()
        UpdateLayoutPositions(vpW, vpH)
        SetVis(bgPanel, "SelfHitTestInvisible")
    else
        if c then BuildMenu(c) end
    end
    if IsValid(floatContainer) then
        SetVis(floatContainer, "Collapsed")
    end
end

function ToggleMenu(canvas)
    if isMenuOpen then
        CloseMenu()
    else
        OpenMenu(canvas)
    end
end

-- ==============================================================================
-- 10. СБОРКА ОСНОВНОГО ОКНА МЕНЮ (rx=25, Slate Grey)
-- ==============================================================================
function BuildMenu(canvas)
    if IsValid(bgPanel) then
        local vpW, vpH = GetViewport()
        UpdateLayoutPositions(vpW, vpH)
        SetVis(bgPanel, "SelfHitTestInvisible")
        if IsValid(floatContainer) then
            SetVis(floatContainer, "Collapsed")
        end
        isMenuOpen = true
        return
    end

    local vpW, vpH = GetViewport()
    bgPanel = NewObject("/Script/UMG.CanvasPanel", canvas)
    bgSlot = canvas:AddChildToCanvas(bgPanel)

    local posX = math.max(0, math.floor((vpW - MENU_W) * 0.5))
    local posY = math.max(0, math.floor((vpH - MENU_H) * 0.5))

    if bgSlot then
        bgSlot:SetAutoSize(false)
        bgSlot:SetPosition(FVector2D(posX, posY))
        bgSlot:SetSize(FVector2D(MENU_W, MENU_H))
        bgSlot:SetZOrder(10000)
    end
    SetVis(bgPanel, "SelfHitTestInvisible")

    local menuRadius = 25

    -- 1. Мягкая тень окна
    RoundedPanel(bgPanel, 4, 4, MENU_W, MENU_H, menuRadius, C.Shadow, 1)
    -- 2. Внешняя светлая окантовка стекла
    RoundedPanel(bgPanel, -1, -1, MENU_W + 2, MENU_H + 2, menuRadius + 1, C.Outline, 2)
    -- 3. Основной корпус окна: цвет Slate Grey (118, 124, 134, 92%)
    RoundedPanel(bgPanel, 0, 0, MENU_W, MENU_H, menuRadius, C.WindowBg, 3)

    -- Сайдбар
    DrawSidebar(bgPanel)

    -- Контейнер контента
    contentContainer = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local cSlot = bgPanel:AddChildToCanvas(contentContainer)
    if cSlot then
        cSlot:SetAutoSize(false)
        cSlot:SetPosition(FVector2D(0, 0))
        cSlot:SetSize(FVector2D(MENU_W, MENU_H))
        cSlot:SetZOrder(10)
    end
    SetVis(contentContainer, "SelfHitTestInvisible")

    RenderContent()

    -- 4. Кнопка закрытия окна (справа сверху: скругленная капсула с крестиком)
    -- Кликабельная область 70x50 с наивысшим Z-Order = 10000
    RoundedPanel(bgPanel, 601, 9, 27, 23, 11, C.CloseBtnBg, 9990)
    Text(bgPanel, "✕", 614.5, 20.5, 14, C.CloseCross, 9991, 0.5, 0.5)
    MakeBtn(bgPanel, 570, 0, 70, 50, 10000, function()
        CloseMenu()
    end)

    if IsValid(floatContainer) then
        SetVis(floatContainer, "Collapsed")
    end
    isMenuOpen = true
end

-- ==============================================================================
-- 11. НИЖНИЙ ИНДИКАТОР HOME (IOS HOME BAR) С ДИНАМИЧЕСКИМ ПРИВЯЗЫВАНИЕМ
-- ==============================================================================
local function CreateFloatButton(canvas)
    if IsValid(floatContainer) then return end
    local vpW, vpH = GetViewport()
    local hitW, hitH = 280, 50
    local fW, fH = INDICATOR_W, INDICATOR_H

    local fX = math.floor((vpW - hitW) * 0.5)
    local fY = vpH - hitH - 8

    floatContainer = NewObject("/Script/UMG.CanvasPanel", canvas)
    floatSlot = canvas:AddChildToCanvas(floatContainer)
    if floatSlot then
        floatSlot:SetAutoSize(false)
        floatSlot:SetPosition(FVector2D(fX, fY))
        floatSlot:SetSize(FVector2D(hitW, hitH))
        floatSlot:SetZOrder(11900)
    end
    SetVis(floatContainer, "SelfHitTestInvisible")

    -- Белая скругленная капсула 226x5 rx=2.5 внутри контейнера
    local barX = math.floor((hitW - fW) * 0.5)
    local barY = hitH - fH - 8
    RoundedPanel(floatContainer, barX, barY + 1, fW, fH, 2.5, C.Shadow, 1)
    RoundedPanel(floatContainer, barX, barY, fW, fH, 2.5, C.IndicatorWhite, 2)

    -- Невидимая кнопка поверх всего индикатора для быстрого клика/тапа
    MakeBtn(floatContainer, 0, 0, hitW, hitH, 100, function()
        ToggleMenu(canvas)
    end)
end

-- ==============================================================================
-- 12. ДИНАМИЧЕСКИЙ НАБЛЮДАТЕЛЬ ЗА РАЗРЕШЕНИЕМ (FULLSCREEN / RESIZE WATCHER)
-- ==============================================================================
local lastVpW, lastVpH = -1, -1
local function CheckViewportChange()
    local vpW, vpH = GetViewport()
    if vpW ~= lastVpW or vpH ~= lastVpH then
        lastVpW = vpW
        lastVpH = vpH
        UpdateLayoutPositions(vpW, vpH)
    end
end

-- ==============================================================================
-- 13. ИНИЦИАЛИЗАЦИЯ И ХУКИ В ИГРЕ
-- ==============================================================================
function GetCanvas()
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

    local vpW, vpH = GetViewport()
    if vpW < 50 or vpH < 50 then return end

    CreateTopPill(canvas)
    CreateFloatButton(canvas)

    -- Меню изначально НЕ открыто (чистый экран при старте)
    isMenuOpen = false
    if IsValid(floatContainer) then
        SetVis(floatContainer, "SelfHitTestInvisible")
        _initDone = true
        print("[SodaLite] Responsive Menu Ready (Starts Closed, Tap Home Bar To Open)")
    end
end

local function InitWatcher()
    if _initDone then
        -- Автообновление системных часов (HH:MM:SS) и проверка изменения экрана
        pcall(function()
            if IsValid(clockTextBlock) then
                clockTextBlock:SetText(os.date("%H:%M:%S"))
            end
            CheckViewportChange()
        end)
    else
        pcall(TryInit)
    end

    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.5, InitWatcher)
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
