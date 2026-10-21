-- ============================================================
-- MANGO UI — UE4 / UMG
-- Только интерфейс, без игровых функций.
--
-- Используется API из вашего примера:
-- CGame:NewObjectFromPath, UEnums, import, slua,
-- common.time_ticker, InGameUITools.
-- ============================================================

local BRPlayerCharacterBase = {
    ServerRPC = {},
    ClientRPC = {},
    MulticastRPC = {}
}

-- Необязательные настройки можно задать до загрузки:
--
-- _G.MangoUIOptions = {
--     StartOpen = true,
--     BottomInset = 4,
--     MenuScale = 1,
--     ClockText = "21:37",
--     ExpiryText = "Expend 999 day",
--     FontObject = nil,      -- объект шрифта Inter
--     FontPointScale = 0.75  -- коэффициент px -> Slate points
-- }

local O = _G.MangoUIOptions or {}

-- Удаление предыдущего экземпляра при повторной загрузке.
local previous = _G.MangoDesignUI

if previous and type(previous.Destroy) == "function" then
    pcall(previous.Destroy)
end

-- ============================================================
-- 1. ТИПЫ
-- ============================================================

local function Struct(name, fallback, ...)
    if type(import) == "function" then
        local ok, constructor = pcall(import, name)

        if ok and constructor then
            local made, value = pcall(constructor, ...)

            if made and value then
                return value
            end
        end
    end

    return fallback
end

local function V2(x, y)
    return Struct(
        "Vector2D",
        { X = x, Y = y },
        x, y
    )
end

local function Color(r, g, b, a)
    a = a == nil and 1 or a

    return Struct(
        "LinearColor",
        { R = r, G = g, B = b, A = a },
        r, g, b, a
    )
end

local function RGB(r, g, b, a)
    return Color(r / 255, g / 255, b / 255, a)
end

-- ============================================================
-- 2. ЦВЕТА И СОСТОЯНИЕ
-- ============================================================

local C = {
    background = Color(0.9070514, 0.9070514, 0.9070514, 1),
    sidebar    = RGB(181, 181, 181, 0.5019608),

    green      = RGB(57, 223, 123),
    greenLight = RGB(57, 223, 123, 0.2509804),
    greenText  = RGB(26, 122, 69),
    off        = RGB(208, 208, 208),

    white      = RGB(255, 255, 255),
    text       = RGB(51, 51, 51),
    secondary  = RGB(68, 68, 68),
    muted      = RGB(85, 85, 85),

    rule       = RGB(204, 204, 204),
    divider    = RGB(224, 224, 224),

    blue       = RGB(91, 141, 239),
    avatar     = RGB(74, 144, 217),
    orange     = RGB(245, 166, 35),
    purple     = RGB(123, 104, 238),
    gray       = RGB(155, 155, 155),

    red        = Color(0.8291667, 0.2142014, 0.2142014, 1),
    close      = Color(0.7083336, 0.7083336, 0.7083336, 0.5),

    pill       = RGB(255, 255, 255, 0.5),
    pillText   = RGB(255, 255, 255, 0.9),
    mainWash   = RGB(255, 255, 255, 0.2509804),
    clear      = Color(0, 0, 0, 0)
}

_G.MangoUIConfig = _G.MangoUIConfig or {}

local Config = _G.MangoUIConfig

local defaults = {
    Box         = true,
    Line        = true,
    Skeleton    = false,
    NameAndDist = true,
    Health      = true
}

for key, value in pairs(defaults) do
    if Config[key] == nil then
        Config[key] = value
    end
end

local UI = {
    Tab       = "ESP",
    Open      = O.StartOpen ~= false,
    Callbacks = {},
    Dead      = false
}

_G.MangoDesignUI = UI

local function Log(message)
    print("[Mango UI] " .. tostring(message))
end

local function Valid(object)
    if not object then
        return false
    end

    if slua and slua.isValid then
        local ok, result = pcall(slua.isValid, object)
        return ok and result
    end

    return true
end

-- ============================================================
-- 3. БАЗОВЫЕ UMG-ЭЛЕМЕНТЫ
-- ============================================================

local function Visibility(widget, name)
    local enum = assert(
        UEnums and UEnums.ESlateVisibility,
        "ESlateVisibility недоступен"
    )

    local value = enum[name]

    assert(value ~= nil, "Нет ESlateVisibility." .. name)

    local ok = pcall(function()
        widget:SetWidgetVisibility(value)
    end)

    if not ok then
        widget:SetVisibility(value)
    end
end

local function New(path, parent)
    assert(
        CGame and CGame.NewObjectFromPath,
        "CGame.NewObjectFromPath недоступен"
    )

    local widget = CGame:NewObjectFromPath(path, parent)

    assert(Valid(widget), "Не удалось создать " .. path)

    return widget
end

local function Place(
    parent, widget,
    x, y, w, h, z,
    anchorX, anchorY,
    alignX, alignY
)
    local slot = assert(
        parent:AddChildToCanvas(widget),
        "Не удалось создать CanvasPanelSlot"
    )

    slot:SetAutoSize(false)

    if anchorX ~= nil then
        slot:SetAnchors({
            Minimum = V2(anchorX, anchorY),
            Maximum = V2(anchorX, anchorY)
        })
    end

    slot:SetAlignment(V2(alignX or 0, alignY or 0))
    slot:SetPosition(V2(x, y))
    slot:SetSize(V2(w, h))
    slot:SetZOrder(z or 0)

    return slot
end

local function Canvas(
    parent, x, y, w, h, z,
    anchorX, anchorY,
    alignX, alignY
)
    local widget = New("/Script/UMG.CanvasPanel", parent)

    Visibility(widget, "SelfHitTestInvisible")

    local slot = Place(
        parent, widget,
        x, y, w, h, z,
        anchorX, anchorY,
        alignX, alignY
    )

    return widget, slot
end

local function Rect(parent, x, y, w, h, color, z)
    local widget = New("/Script/UMG.Border", parent)

    widget:SetBrushColor(color)
    Visibility(widget, "HitTestInvisible")

    Place(parent, widget, x, y, w, h, z)

    return widget
end

-- UE4 не имеет универсального UMG SetCornerRadius.
-- Поэтому скругления собраны из неперекрывающихся полос.
-- Дополнительные текстуры и материалы не требуются.
-- Контур приближённый, без векторного сглаживания.

local function Round(parent, x, y, w, h, radius, color, z)
    local panel = Canvas(parent, x, y, w, h, z)

    local shape = {
        Widget = panel,
        Parts = {}
    }

    local function Part(px, py, pw, ph)
        if pw > 0 and ph > 0 then
            shape.Parts[#shape.Parts + 1] = Rect(
                panel, px, py, pw, ph, color, 0
            )
        end
    end

    local r = math.max(0, math.min(radius, w / 2, h / 2))

    if r == 0 then
        Part(0, 0, w, h)
    else
        Part(0, r, w, h - 2 * r)

        for row = 0, math.ceil(r) - 1 do
            local height = math.min(1, r - row)
            local dy = r - row - height / 2

            local inset = r - math.sqrt(
                math.max(0, r * r - dy * dy)
            )

            Part(inset, row, w - 2 * inset, height)

            Part(
                inset,
                h - row - height,
                w - 2 * inset,
                height
            )
        end
    end

    return shape
end

local function Tint(shape, color)
    for _, part in ipairs(shape.Parts) do
        if Valid(part) then
            part:SetBrushColor(color)
        end
    end
end

local function TextColor(widget, color)
    -- Нативный TextBlock принимает FSlateColor.
    -- Некоторые Lua-мосты принимают LinearColor напрямую.

    local ok = pcall(function()
        widget:SetColorAndOpacity({
            SpecifiedColor = color,
            ColorUseRule = 0
        })
    end)

    if not ok then
        widget:SetColorAndOpacity(color)
    end
end

local function Text(
    parent, value, x, y,
    px, color, z,
    alignX, alignY, bold
)
    local widget = New("/Script/UMG.TextBlock", parent)

    widget:SetText(tostring(value))

    local font = {
        Size = math.max(
            1,
            math.floor(px * (O.FontPointScale or 0.75) + 0.5)
        ),

        TypefaceFontName = bold and "Bold" or "Regular"
    }

    if O.FontObject then
        font.FontObject = O.FontObject
    end

    widget:SetFont(font)
    TextColor(widget, color)

    Visibility(widget, "HitTestInvisible")

    local slot = Place(
        parent, widget,
        x, y, 0, 0, z,
        nil, nil,
        alignX, alignY
    )

    slot:SetAutoSize(true)

    return widget
end

local function Button(parent, x, y, w, h, z, onClick)
    local widget = New("/Script/UMG.Button", parent)

    widget:SetBackgroundColor(C.clear)
    Visibility(widget, "Visible")

    Place(parent, widget, x, y, w, h, z)

    local callback = function()
        if UI.Dead then
            return
        end

        local ok, err = pcall(onClick)

        if not ok then
            Log(err)
        end
    end

    UI.Callbacks[#UI.Callbacks + 1] = callback

    assert(
        widget.OnClicked,
        "В этой сборке нет Button.OnClicked"
    ):Add(callback)

    return widget
end

-- ============================================================
-- 4. ЛИНИИ И ИКОНКИ
-- ============================================================

local function Segment(
    parent,
    x1, y1, x2, y2,
    thickness, color, z
)
    local dx = x2 - x1
    local dy = y2 - y1

    local length = math.sqrt(dx * dx + dy * dy)

    if length == 0 then
        return
    end

    local angle

    if dx == 0 then
        angle = dy >= 0 and 90 or -90
    else
        angle = math.deg(math.atan(dy / dx))

        if dx < 0 then
            angle = angle + 180
        end
    end

    local widget = Rect(
        parent,
        (x1 + x2 - length) / 2,
        (y1 + y2 - thickness) / 2,
        length,
        thickness,
        color,
        z
    )

    widget:SetRenderTransformPivot(V2(0.5, 0.5))
    widget:SetRenderTransformAngle(angle)
end

local function Ring(parent, cx, cy, radius, z)
    for i = 0, 15 do
        local a = i * 2 * math.pi / 16
        local b = (i + 1) * 2 * math.pi / 16

        Segment(
            parent,
            cx + math.cos(a) * radius,
            cy + math.sin(a) * radius,
            cx + math.cos(b) * radius,
            cy + math.sin(b) * radius,
            1.15,
            C.white,
            z
        )
    end
end

local function Icon(parent, key, x, y)
    local function Line(x1, y1, x2, y2)
        Segment(
            parent,
            x + x1, y + y1,
            x + x2, y + y2,
            1.3, C.white, 3
        )
    end

    if key == "MAIN" then
        Line(2, 7, 8, 2)
        Line(8, 2, 14, 7)

        Line(2, 7, 2, 14)
        Line(14, 7, 14, 14)

        Line(2, 14, 6, 14)
        Line(10, 14, 14, 14)

        Line(6, 14, 6, 9)
        Line(6, 9, 10, 9)
        Line(10, 9, 10, 14)

    elseif key == "ESP" then
        local points = {
            {1, 8}, {3, 5}, {6, 3.5},
            {10, 3.5}, {13, 5}, {15, 8},
            {13, 11}, {10, 12.5}, {6, 12.5},
            {3, 11}, {1, 8}
        }

        for i = 1, #points - 1 do
            Line(
                points[i][1],
                points[i][2],
                points[i + 1][1],
                points[i + 1][2]
            )
        end

        Ring(parent, x + 8, y + 8, 2.5, 3)

    elseif key == "AIM" then
        Ring(parent, x + 8, y + 8, 6.7, 3)
        Ring(parent, x + 8, y + 8, 4, 3)

        Round(
            parent,
            x + 6.7, y + 6.7,
            2.6, 2.6, 1.3,
            C.white, 3
        )

    elseif key == "MEM" then
        Line(3, 3, 13, 3)
        Line(13, 3, 13, 13)
        Line(13, 13, 3, 13)
        Line(3, 13, 3, 3)

        Line(6, 6, 10, 6)
        Line(10, 6, 10, 10)
        Line(10, 10, 6, 10)
        Line(6, 10, 6, 6)

        for _, p in ipairs({5, 8, 11}) do
            Line(p, 1, p, 3)
            Line(p, 13, p, 15)
            Line(1, p, 3, p)
            Line(13, p, 15, p)
        end

    elseif key == "SET" then
        local points = {}

        for i = 0, 23 do
            local a = i * 2 * math.pi / 24
            local outer = i % 4 == 0 or i % 4 == 3
            local r = outer and 7 or 5.5

            points[#points + 1] = {
                8 + math.cos(a) * r,
                8 + math.sin(a) * r
            }
        end

        for i = 1, #points do
            local a = points[i]
            local b = points[i % #points + 1]

            Line(a[1], a[2], b[1], b[2])
        end

        Ring(parent, x + 8, y + 8, 2.4, 3)
    end
end

-- ============================================================
-- 5. ПЕРЕКЛЮЧАТЕЛИ
-- ============================================================

function UI.SetOpen(open)
    UI.Open = not not open

    if Valid(UI.Menu) then
        Visibility(
            UI.Menu,
            UI.Open and "SelfHitTestInvisible" or "Collapsed"
        )
    end
end

local function ToggleRow(parent, y, label, key)
    Text(
        parent,
        label,
        0, y + 22,
        13, C.text, 2,
        0, 0.5
    )

    local track = Round(
        parent,
        451, y + 10,
        42, 24, 12,
        Config[key] and C.green or C.off,
        2
    )

    local knob = Round(
        parent,
        451 + (Config[key] and 21 or 3),
        y + 13,
        18, 18, 9,
        C.white,
        3
    )

    Button(parent, 0, y, 493, 44, 10, function()
        Config[key] = not Config[key]

        Tint(
            track,
            Config[key] and C.green or C.off
        )

        knob.Widget.Slot:SetPosition(V2(
            451 + (Config[key] and 21 or 3),
            y + 13
        ))

        -- Только изменение состояния интерфейса.
    end)
end

-- ============================================================
-- 6. ОСНОВНОЕ МЕНЮ
-- ============================================================

local function BuildMenu(root)
    local menu = Canvas(
        root,
        0, 20.5,
        640, 411,
        100,
        0.5, 0.5,
        0.5, 0.5
    )

    UI.Menu = menu

    if O.MenuScale and O.MenuScale ~= 1 then
        menu:SetRenderTransformPivot(V2(0.5, 0.5))
        menu:SetRenderScale(V2(O.MenuScale, O.MenuScale))
    end

    Round(
        menu,
        0, 0,
        640, 411,
        25,
        C.background,
        0
    )

    local sidebar = Round(
        menu,
        10, 8,
        83, 396,
        20,
        C.sidebar,
        1
    ).Widget

    -- Аватар.
    Round(
        sidebar,
        23.5, 13,
        36, 36,
        18,
        C.avatar,
        1
    )

    Text(
        sidebar, "A",
        41.5, 31,
        14, C.white, 3,
        0.5, 0.5, true
    )

    Text(
        sidebar, "User",
        41.5, 58,
        8, C.muted, 3,
        0.5, 0.5
    )

    -- Область содержимого.
    local content = Canvas(
        menu,
        119, 8,
        493, 396,
        20
    )

    local title = Text(
        content, "ESP",
        246.5, 30,
        18, C.text, 2,
        0.5, 0.5, true
    )

    local esp = Canvas(
        content,
        0, 0,
        493, 396,
        1
    )

    Round(
        esp,
        0, 54,
        12, 12,
        2,
        C.green,
        2
    )

    Text(
        esp, "Character",
        18, 60,
        11, C.secondary, 2,
        0, 0.5, true
    )

    Rect(
        esp,
        0, 76,
        493, 1,
        C.rule,
        1
    )

    local rows = {
        { "Box",           "Box" },
        { "Line",          "Line" },
        { "Skeleton",      "Skeleton" },
        { "Name and dist", "NameAndDist" },
        { "Health",        "Health" }
    }

    for i, row in ipairs(rows) do
        local y = 77 + (i - 1) * 45

        ToggleRow(esp, y, row[1], row[2])

        if i < #rows then
            Rect(
                esp,
                0, y + 44,
                493, 1,
                C.divider,
                1
            )
        end
    end

    -- Боковая навигация.
    local nav = {}

    local tabs = {
        { "MAIN", C.blue },
        { "ESP",  C.green },
        { "AIM",  C.orange },
        { "MEM",  C.purple },
        { "SET",  C.gray }
    }

    local function SelectTab(key)
        UI.Tab = key
        title:SetText(key)

        Visibility(
            esp,
            key == "ESP"
                and "SelfHitTestInvisible"
                or "Collapsed"
        )

        for tab, entry in pairs(nav) do
            Visibility(
                entry.Highlight,
                tab == key
                    and "HitTestInvisible"
                    or "Collapsed"
            )

            TextColor(
                entry.Label,
                tab == key and C.greenText or C.text
            )
        end
    end

    for i, tab in ipairs(tabs) do
        local key = tab[1]
        local color = tab[2]
        local y = 72 + (i - 1) * 60

        local cell = Canvas(
            sidebar,
            0, y,
            83, 60,
            2
        )

        if key == "MAIN" then
            Rect(
                cell,
                0, 0,
                83, 60,
                C.mainWash,
                0
            )
        end

        local highlight = Rect(
            cell,
            0, 0,
            83, 60,
            C.greenLight,
            1
        )

        Round(
            cell,
            27.5, 9,
            28, 28,
            8,
            color,
            2
        )

        Icon(cell, key, 33.5, 15)

        local label = Text(
            cell, key,
            41.5, 46,
            8, C.text, 4,
            0.5, 0.5, true
        )

        nav[key] = {
            Highlight = highlight,
            Label = label
        }

        Button(cell, 0, 0, 83, 60, 10, function()
            SelectTab(key)
        end)
    end

    UI.SelectTab = SelectTab
    SelectTab(UI.Tab)

    -- Кнопка закрытия.
    Round(
        menu,
        601, 9,
        27, 23,
        11.5,
        C.close,
        90
    )

    Segment(
        menu,
        610, 16,
        619, 25,
        1.3, C.red, 91
    )

    Segment(
        menu,
        619, 16,
        610, 25,
        1.3, C.red, 91
    )

    Button(menu, 601, 9, 27, 23, 100, function()
        UI.SetOpen(false)
    end)

    UI.SetOpen(UI.Open)
end

-- ============================================================
-- 7. ВЕРХНЯЯ ПЛАШКА
-- ============================================================

local function BuildHeader(root)
    local header = Canvas(
        root,
        0, 12,
        363, 38,
        200,
        0.5, 0,
        0.5, 0
    )

    Round(
        header,
        0, 0,
        363, 38,
        19,
        C.pill,
        0
    )

    UI.Clock = Text(
        header,
        O.ClockText or "21:37",
        23, 19,
        16, C.pillText, 2,
        0, 0.5, true
    )

    Text(
        header, "|",
        72, 19,
        14, C.pillText, 2,
        0, 0.5, true
    )

    Text(
        header, "Mango Cheats",
        84, 19,
        16, C.pillText, 2,
        0, 0.5, true
    )

    Text(
        header, "|",
        204, 19,
        14, C.pillText, 2,
        0, 0.5, true
    )

    UI.Expiry = Text(
        header,
        O.ExpiryText or "Expend 999 day",
        216, 19,
        16, C.pillText, 2,
        0, 0.5, true
    )

    Button(header, 0, 0, 363, 38, 10, function()
        UI.SetOpen(not UI.Open)
    end)

    UI.Header = header
end

-- ============================================================
-- 8. HOME INDICATOR
-- ============================================================

local function BuildHomeIndicator(root)
    -- Белая капсула 226 x 5.
    -- Радиус 100 из макета фактически ограничивается
    -- половиной высоты: 2.5.
    --
    -- Anchor    = (0.5, 1)
    -- Alignment = (0.5, 1)
    -- Position  = (0, -4)
    --
    -- Это даёт расположение снизу по центру
    -- без жёсткой привязки к разрешению экрана.

    local indicator = Round(
        root,
        0, 0,
        226, 5,
        2.5,
        C.white,
        300
    ).Widget

    local slot = indicator.Slot

    slot:SetAnchors({
        Minimum = V2(0.5, 1),
        Maximum = V2(0.5, 1)
    })

    slot:SetAlignment(V2(0.5, 1))

    slot:SetPosition(V2(
        0,
        -(O.BottomInset or 4)
    ))

    slot:SetSize(V2(226, 5))

    -- Декоративный элемент не перехватывает касания.
    Visibility(indicator, "HitTestInvisible")

    UI.HomeIndicator = indicator
end

-- ============================================================
-- 9. ОБНОВЛЕНИЕ НАДПИСЕЙ И ОЧИСТКА
-- ============================================================

function UI.SetClockText(value)
    O.ClockText = tostring(value)

    if Valid(UI.Clock) then
        UI.Clock:SetText(O.ClockText)
    end
end

function UI.SetExpiryText(value)
    O.ExpiryText = tostring(value)

    if Valid(UI.Expiry) then
        UI.Expiry:SetText(O.ExpiryText)
    end
end

local function ClearRoot()
    if Valid(UI.Root) then
        pcall(function()
            UI.Root:RemoveFromParent()
        end)
    end

    UI.Root = nil
    UI.Parent = nil
    UI.Menu = nil
    UI.Header = nil
    UI.HomeIndicator = nil
    UI.Clock = nil
    UI.Expiry = nil
    UI.SelectTab = nil
    UI.Callbacks = {}
end

function UI.Destroy()
    UI.Dead = true
    ClearRoot()
end

-- ============================================================
-- 10. ПОИСК ОСНОВНОГО CANVAS
-- ============================================================

local function GetCanvas()
    local ok, tools = pcall(
        require,
        "GameLua.Mod.BaseMod.Common.UI.InGameUITools"
    )

    if not ok or not tools or not tools.GetMainControlBaseUI then
        return nil
    end

    local main = tools.GetMainControlBaseUI()

    if not Valid(main) then
        return nil
    end

    if Valid(main.CanvasPanel_0) then
        return main.CanvasPanel_0
    end

    if Valid(main.CanvasPanel_42) then
        return main.CanvasPanel_42
    end
end

local lastError

local function TryInit()
    if UI.Dead then
        return
    end

    local canvas = GetCanvas()

    if not Valid(canvas) then
        return
    end

    if UI.Parent == canvas
        and Valid(UI.Root)
        and UI.Root:GetParent() == canvas
    then
        return
    end

    ClearRoot()

    local root = New("/Script/UMG.CanvasPanel", canvas)

    UI.Root = root
    UI.Parent = canvas

    Visibility(root, "SelfHitTestInvisible")

    local slot = Place(
        canvas, root,
        0, 0,
        0, 0,
        11000
    )

    -- Растягиваем Root на весь родительский Canvas.
    -- Основной Canvas должен занимать весь viewport.
    slot:SetAnchors({
        Minimum = V2(0, 0),
        Maximum = V2(1, 1)
    })

    slot:SetPosition(V2(0, 0))
    slot:SetSize(V2(0, 0))

    BuildMenu(root)
    BuildHeader(root)
    BuildHomeIndicator(root)

    lastError = nil
    Log("UMG UI loaded")
end

local function SafeInit()
    local ok, err = pcall(TryInit)

    if not ok then
        ClearRoot()

        if lastError ~= tostring(err) then
            Log(err)
            lastError = tostring(err)
        end
    end
end

-- ============================================================
-- 11. ОЖИДАНИЕ CANVAS И СОБЫТИЯ
-- ============================================================

local function Watch()
    if UI.Dead then
        return
    end

    SafeInit()

    local ok, ticker = pcall(
        require,
        "common.time_ticker"
    )

    if ok and ticker and ticker.AddTimerOnce then
        local delay = Valid(UI.Root) and 1 or 0.5

        local scheduled, err = pcall(
            ticker.AddTimerOnce,
            delay,
            Watch
        )

        if not scheduled then
            Log("Timer: " .. tostring(err))
        end
    end
end

function BRPlayerCharacterBase:_PostConstruct()
    local super = BRPlayerCharacterBase.__super

    if super and super._PostConstruct then
        super._PostConstruct(self)
    end

    SafeInit()
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    local super = BRPlayerCharacterBase.__super

    if super and super.ReceiveBeginPlay then
        super.ReceiveBeginPlay(self)
    end

    SafeInit()
end

Watch()

return BRPlayerCharacterBase
