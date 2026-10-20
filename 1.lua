-- ==============================================================================
-- SODALITE UI CORE (SVG EXACT MATCH) + HOME INDICATOR SWIPE/TAP
-- ==============================================================================

local BRPlayerCharacterBase = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {} }

-- 1. ЦВЕТА ИЗ SVG
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

local C = {
    MenuBg        = FLinearColor(0.906, 0.906, 0.906, 1.0),
    SidebarBg     = FLinearColor(0.71,  0.71,  0.71,  0.5),
    RowBg         = FLinearColor(1.0,   1.0,   1.0,   0.25),
    ActiveIcon    = FLinearColor(0.29,  0.565, 0.851, 1.0),
    ToggleOn      = FLinearColor(0.224, 0.875, 0.482, 1.0),
    ToggleOff     = FLinearColor(0.608, 0.608, 0.608, 1.0),
    KnobWhite     = FLinearColor(1.0,   1.0,   1.0,   1.0),
    TextDark      = FLinearColor(0.2,   0.2,   0.2,   1.0),
    TextDim       = FLinearColor(0.33,  0.33,  0.33,  1.0),
    Indicator     = FLinearColor(1.0,   1.0,   1.0,   0.9),
    HitArea       = FLinearColor(0.0,   0.0,   0.0,   0.01),
    Transparent   = FLinearColor(0.0,   0.0,   0.0,   0.01),
}

-- Размеры
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
            if radius and radius > 0 and b.SetCornerRadius then b:SetCornerRadius(radius) end
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
            tb:SetFont({ Size = fontSize or 12, Typeface = "Bold" })
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

-- ⚠️ ФИКС: alpha 0.01 чтобы Slate считал кнопку hit-testable
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

-- 3. ЭЛЕМЕНТЫ МЕНЮ
local function DrawCheckbox(parent, x, y, w, label, configKey)
    local h = ROW_H
    Layer(parent, x, y, w, h, C.RowBg, 10, 8)
    Text(parent, label, x + 16, y + h * 0.5, 12, C.TextDark, 15, 0.0, 0.5)

    local toggleW, toggleH = 42, 24
    local toggleX = x + w - toggleW - 16
    local toggleY = y + (h - toggleH) * 0.5
    local track = Layer(parent, toggleX, toggleY, toggleW, toggleH,
        Config[configKey] and C.ToggleOn or C.ToggleOff, 12, 12)
    local knobSize = 18
    local knobOffset = Config[configKey] and (toggleW - knobSize - 3) or 3
    local knob = Layer(parent, toggleX + knobOffset, toggleY + 3, knobSize, knobSize, C.KnobWhite, 14, 9)

    MakeBtn(parent, x, y, w, h, 20, function()
        Config[configKey] = not Config[configKey]
        local on = Config[configKey]
        if IsValid(track) then track:SetBrushColor(on and C.ToggleOn or C.ToggleOff) end
        if IsValid(knob) then
            local newX = toggleX + (on and (toggleW - knobSize - 3) or 3)
            if knob.Slot then knob.Slot:SetPosition(FVector2D(newX, toggleY + 3)) end
        end
    end)
end

local function DrawSidebarIcon(parent, x, y, isActive, onClick)
    local size = ICON_SIZE
    local iconColor = isActive and C.ActiveIcon or C.ToggleOff
    Layer(parent, x, y, size, size, iconColor, 10, 18)
    local symbol = isActive and "V" or "-"
    Text(parent, symbol, x + size * 0.5, y + size * 0.5, 16, C.KnobWhite, 11, 0.5, 0.5)
    MakeBtn(parent, x, y, size, size, 20, onClick)
end

-- 4. КОНТЕНТ
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
    elseif currentTab == "EXPLOIT" then
        Text(contentContainer, "EXPLOITS", 16, startY, 14, C.TextDim, 15, 0.0, 0.0)
        Text(contentContainer, "No exploits configured yet.", 16, startY + 30, 12, C.TextDim, 15, 0.0, 0.0)
    elseif currentTab == "SKINS" then
        Text(contentContainer, "SKINS", 16, startY, 14, C.TextDim, 15, 0.0, 0.0)
        Text(contentContainer, "No skins loaded.", 16, startY + 30, 12, C.TextDim, 15, 0.0, 0.0)
    elseif currentTab == "SETTINGS" then
        Text(contentContainer, "SETTINGS", 16, startY, 14, C.TextDim, 15, 0.0, 0.0)
        Text(contentContainer, "Config save/load here.", 16, startY + 30, 12, C.TextDim, 15, 0.0, 0.0)
    end
end

-- 5. СБОРКА ОКНА
local function BuildMenu(canvas)
    if IsValid(bgPanel) then
        bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        isMenuOpen = true
        print("[SodaLite] BuildMenu: reused existing panel")
        return
    end

    local vpW, vpH = GetViewport()
    print(string.format("[SodaLite] BuildMenu: viewport %dx%d", vpW, vpH))

    bgPanel = NewObject("/Script/UMG.CanvasPanel", canvas)
    local bgSlot = canvas:AddChildToCanvas(bgPanel)

    local posX = math.floor((vpW - MENU_W) * 0.5)
    local posY = math.floor((vpH - MENU_H) * 0.5) - 40

    bgSlot:SetPosition(FVector2D(posX, posY))
    bgSlot:SetSize(FVector2D(MENU_W, MENU_H))
    bgSlot:SetZOrder(10000)

    -- Фон окна
    Layer(bgPanel, 0, 0, MENU_W, MENU_H, C.MenuBg, 1, 25)
    -- Сайдбар
    Layer(bgPanel, 10, 8, SIDEBAR_W, MENU_H - 16, C.SidebarBg, 2, 20)

    -- Иконки сайдбара
    local tabs = {
        {key="VISUALS",  y=21},
        {key="AIMBOT",   y=81},
        {key="EXPLOIT",  y=141},
        {key="SKINS",    y=201},
        {key="SETTINGS", y=261},
    }
    for _, t in ipairs(tabs) do
        DrawSidebarIcon(bgPanel, 23.5, t.y, currentTab == t.key, function()
            currentTab = t.key
            RenderContent()
        end)
    end

    -- Контейнер контента
    contentContainer = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local cSlot = bgPanel:AddChildToCanvas(contentContainer)
    cSlot:SetPosition(FVector2D(SIDEBAR_W + 10, 8))
    cSlot:SetSize(FVector2D(MENU_W - SIDEBAR_W - 20, MENU_H - 16))
    cSlot:SetZOrder(10)

    RenderContent()
    isMenuOpen = true
    print("[SodaLite] BuildMenu: created at " .. posX .. "," .. posY)
end

-- 6. HOME INDICATOR (тап + свайп вверх)
local function CreateFloatButton(canvas)
    if floatItem and IsValid(floatItem.bg) then return end
    floatItem = {
        touchStartY = 0,
        touchStartTime = 0,
        swiping = false,
    }

    local vpW, vpH = GetViewport()
    local fX = math.floor((vpW - INDICATOR_W) * 0.5)
    local fY = vpH - 20

    -- Тень
    Layer(canvas, fX, fY + 2, INDICATOR_W, INDICATOR_H, FLinearColor(0, 0, 0, 0.3), 11898, 2.5)
    -- Индикатор
    floatItem.bg = Layer(canvas, fX, fY, INDICATOR_W, INDICATOR_H, C.Indicator, 11901, 2.5)

    -- Зона захвата (300×80, чуть выше края)
    local hitW, hitH = 300, 80
    local hitX = fX + (INDICATOR_W - hitW) * 0.5
    local hitY = vpH - hitH + 10

    local hitArea = Layer(canvas, hitX, hitY, hitW, hitH, C.HitArea, 12000)

    local function onTouchStart(myGeom, idx, loc)
        floatItem.touchStartY = loc.Y
        floatItem.touchStartTime = os.clock()
        floatItem.swiping = false
        print("[SodaLite] Home: touch start Y=" .. tostring(loc.Y))
    end

    local function onTouchMove(myGeom, idx, loc)
        if not floatItem.touchStartY or floatItem.touchStartY == 0 then return end
        local dy = loc.Y - floatItem.touchStartY
        if dy < -40 and not floatItem.swiping then
            floatItem.swiping = true
            print("[SodaLite] Home: swipe up -> toggle")
            if not isMenuOpen then ToggleMenu(canvas) end
        end
    end

    local function onTouchEnd(myGeom, idx, loc)
        local dt = os.clock() - (floatItem.touchStartTime or 0)
        local dy = loc.Y - (floatItem.touchStartY or 0)
        print(string.format("[SodaLite] Home: touch end dt=%.2f dy=%.1f swiping=%s", dt, dy, tostring(floatItem.swiping)))
        if dt < 0.4 and math.abs(dy) < 30 and not floatItem.swiping then
            print("[SodaLite] Home: tap -> toggle")
            ToggleMenu(canvas)
        end
        floatItem.touchStartY = 0
        floatItem.swiping = false
    end

    -- Пытаемся навесить touch-делегаты через Border
    local hooked = false
    pcall(function()
        if hitArea.OnTouchStarted then
            hitArea.OnTouchStarted:Add(onTouchStart)
            hooked = true
        end
        if hitArea.OnTouchMoved then
            hitArea.OnTouchMoved:Add(onTouchMove)
        end
        if hitArea.OnTouchEnded then
            hitArea.OnTouchEnded:Add(onTouchEnd)
        end
    end)
    print("[SodaLite] Home: touch delegates hooked = " .. tostring(hooked))

    -- Fallback: обычный клик на Button поверх зоны захвата
    floatItem.btn = MakeBtn(canvas, hitX, hitY, hitW, hitH, 12001, function()
        print("[SodaLite] Home: button click fallback")
        ToggleMenu(canvas)
    end)
end

-- 7. TOGGLE
function ToggleMenu(canvas)
    isMenuOpen = not isMenuOpen
    print("[SodaLite] ToggleMenu -> isMenuOpen=" .. tostring(isMenuOpen))

    if isMenuOpen then
        if IsValid(bgPanel) then
            bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        else
            BuildMenu(canvas)
        end
        -- скрыть индикатор пока меню открыто
        if floatItem and floatItem.bg and IsValid(floatItem.bg) then
            floatItem.bg:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
    else
        if IsValid(bgPanel) then
            bgPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
        if floatItem and floatItem.bg and IsValid(floatItem.bg) then
            floatItem.bg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end
    end
end

-- 8. INIT
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

    -- Ждём пока viewport реально готов
    local vpW = GetViewport()
    if vpW < 800 then return end

    CreateFloatButton(canvas)
    if floatItem and IsValid(floatItem.bg) then
        _initDone = true
        print("[SodaLite] UI Loaded (SVG + Home Indicator)")
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