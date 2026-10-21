-- ==============================================================================
-- MENU23.LUA — SVG UI + AUTO-DOWNLOAD & EXECUTE ENGINE (afw.lua)
-- ==============================================================================

local BRPlayerCharacterBase = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {} }

-- 1. АКТИВАЦИЯ И ЛИЦЕНЗИРОВАНИЕ ДВИЖКА (Обход проверки лицензии)
_G._LICENSE_OK = true
_G._MOD_EXPIRED = false

-- URL твоего движка на GitHub
local ENGINE_URL = "https://raw.githubusercontent.com/kholoudbendriss/archive/refs/heads/main/afw.lua"
_G._ENGINE_LOADED = false

-- 2. ЗАГРУЗКА И АКТИВАЦИЯ ДВИЖКА
local _engineLoadAttempts = 0
local function LoadEngine()
    if _G._ENGINE_LOADED then return end
    _engineLoadAttempts = _engineLoadAttempts + 1

    -- А. Проверка, не загружен ли уже модуль в память
    if _G._MAGOO_FILEUTIL_MOD_LOADED then
        _G._LICENSE_OK = true
        _G._MOD_EXPIRED = false
        _G._ENGINE_LOADED = true
        if _G.StartAuthenticatedRuntime then pcall(_G.StartAuthenticatedRuntime) end
        if _G.EnsureModFeaturesRunning then pcall(_G.EnsureModFeaturesRunning) end
        print("[Menu23] Engine already present in memory — activated!")
        return
    end

    -- Б. Проверка локального файла на устройстве (быстрый старт без сети)
    local localFiles = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/afw.lua",
        "//storage/emulated/0/afw.lua",
    }
    for _, path in ipairs(localFiles) do
        local f = io.open(path, "r")
        if f then
            local data = f:read("*a")
            f:close()
            if data and #data > 100 then
                _G._LICENSE_OK = true
                _G._MOD_EXPIRED = false
                local chunk, err = load(data, "afw.lua")
                if chunk then
                    local ok, execErr = pcall(chunk)
                    if ok then
                        _G._ENGINE_LOADED = true
                        print("[Menu23] Engine loaded from local file: " .. path)
                        if _G.StartAuthenticatedRuntime then pcall(_G.StartAuthenticatedRuntime) end
                        if _G.EnsureModFeaturesRunning then pcall(_G.EnsureModFeaturesRunning) end
                        return
                    end
                end
            end
        end
    end

    -- В. Загрузка с GitHub через http manager
    local http = nil
    pcall(function()
        http = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.http_manager)
    end)
    if not http then
        print("[Menu23] HTTP manager not ready yet, will retry...")
        return
    end

    print("[Menu23] Downloading engine from: " .. ENGINE_URL .. " (attempt " .. tostring(_engineLoadAttempts) .. ")")

    local function handleResponse(success, response)
        if success and response and #response > 100 then
            _G._LICENSE_OK = true
            _G._MOD_EXPIRED = false
            local chunk, err = load(response, "afw.lua")
            if chunk then
                local ok, execErr = pcall(chunk)
                if ok then
                    _G._ENGINE_LOADED = true
                    print("[Menu23] Engine (afw.lua) downloaded and executed successfully!")
                    if _G.StartAuthenticatedRuntime then pcall(_G.StartAuthenticatedRuntime) end
                    if _G.EnsureModFeaturesRunning then pcall(_G.EnsureModFeaturesRunning) end
                else
                    print("[Menu23] Engine execution error: " .. tostring(execErr))
                end
            else
                print("[Menu23] Engine compilation error: " .. tostring(err))
            end
        else
            print("[Menu23] Download attempt failed (empty or network issue).")
        end
    end

    local headers = {
        ["Accept"] = "*/*",
        ["User-Agent"] = "Mozilla/5.0"
    }

    -- GitHub Raw принимает ТОЛЬКО GET-запросы!
    local getSent = false
    if type(http.Get) == "function" then
        getSent = pcall(function()
            http:Get(ENGINE_URL, headers, function(ok, resp)
                if ok and resp and #resp > 100 then
                    handleResponse(true, resp)
                else
                    -- Fallback на Post с пустым телом
                    pcall(function()
                        http:Post(ENGINE_URL, headers, "", nil, handleResponse, 20)
                    end)
                end
            end, 20)
        end)
    end

    if not getSent then
        pcall(function()
            http:Post(ENGINE_URL, headers, "", nil, handleResponse, 20)
        end)
    end
end

-- Планировщик автозагрузки движка (с повторными попытками при задержке сети)
local function ScheduleEngineLoader()
    LoadEngine()
    if not _G._ENGINE_LOADED and _engineLoadAttempts < 5 then
        local tk = require("common.time_ticker")
        if tk and tk.AddTimerOnce then
            tk.AddTimerOnce(3.0, ScheduleEngineLoader)
        end
    end
end

pcall(function()
    local tk = require("common.time_ticker")
    if tk and tk.AddTimerOnce then
        tk.AddTimerOnce(2.0, ScheduleEngineLoader)
    else
        LoadEngine()
    end
end)

-- ==============================================================================
-- 3. ГЛОБАЛЬНАЯ ОЧИСТКА СТАРЫХ ВИДЖЕТОВ ПРИ ПЕРЕЗАГРУЗКЕ
-- ==============================================================================
pcall(function()
    if _G.SodaLite_TopPillContainer and IsValid(_G.SodaLite_TopPillContainer) then
        _G.SodaLite_TopPillContainer:RemoveFromParent()
        _G.SodaLite_TopPillContainer = nil
    end
    if _G.SodaLite_FloatContainer and IsValid(_G.SodaLite_FloatContainer) then
        _G.SodaLite_FloatContainer:RemoveFromParent()
        _G.SodaLite_FloatContainer = nil
    end
    if _G.SodaLite_BgPanel and IsValid(_G.SodaLite_BgPanel) then
        _G.SodaLite_BgPanel:RemoveFromParent()
        _G.SodaLite_BgPanel = nil
    end
end)

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
    local map = { Visible = 0, Collapsed = 1, Hidden = 2, HitTestInvisible = 3, SelfHitTestInvisible = 4 }
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
    pcall(function() widget:SetWidgetVisibility(GetSlateVis(visName)) end)
end

local C = {
    WindowBg        = FLinearColor(0.463, 0.486, 0.525, 0.92),
    Outline         = FLinearColor(1.0, 1.0, 1.0, 0.35),
    Shadow          = FLinearColor(0.0, 0.0, 0.0, 0.30),
    SidebarBg       = FLinearColor(0.380, 0.405, 0.445, 0.85),
    SidebarActiveBg = FLinearColor(0.537, 0.843, 0.710, 0.25),
    IconUser        = FLinearColor(0.29, 0.56, 0.85, 1.0),
    IconMain        = FLinearColor(0.36, 0.55, 0.94, 1.0),
    IconESP         = FLinearColor(0.537, 0.843, 0.710, 1.0),
    IconAim         = FLinearColor(0.96, 0.65, 0.14, 1.0),
    IconMem         = FLinearColor(0.48, 0.41, 0.93, 1.0),
    IconSet         = FLinearColor(0.65, 0.68, 0.72, 1.0),
    TextDark        = FLinearColor(0.96, 0.97, 0.98, 0.98),
    TextActiveESP   = FLinearColor(0.537, 0.843, 0.710, 1.0),
    TextUser        = FLinearColor(0.85, 0.88, 0.92, 0.90),
    TextTitle       = FLinearColor(1.0, 1.0, 1.0, 0.98),
    TextCategory    = FLinearColor(0.96, 0.97, 0.98, 0.98),
    CategorySquare  = FLinearColor(0.537, 0.843, 0.710, 1.0),
    DividerTop      = FLinearColor(1.0, 1.0, 1.0, 0.25),
    DividerRow      = FLinearColor(1.0, 1.0, 1.0, 0.15),
    ToggleOn        = FLinearColor(0.537, 0.843, 0.710, 1.0),
    ToggleOff       = FLinearColor(0.36, 0.38, 0.42, 1.0),
    KnobWhite       = FLinearColor(1.0, 1.0, 1.0, 1.0),
    CloseBtnBg      = FLinearColor(0.380, 0.405, 0.445, 0.80),
    CloseCross      = FLinearColor(0.95, 0.35, 0.35, 1.0),
    TopPillBg       = FLinearColor(0.463, 0.486, 0.525, 0.85),
    TopPillOutline  = FLinearColor(1.0, 1.0, 1.0, 0.30),
    TopPillShadow   = FLinearColor(0.0, 0.0, 0.0, 0.25),
    TopPillClock    = FLinearColor(1.0, 1.0, 1.0, 0.98),
    TopPillTitle    = FLinearColor(0.537, 0.843, 0.710, 1.0),
    TopPillStatus   = FLinearColor(1.0, 1.0, 1.0, 0.98),
    TopPillDiv      = FLinearColor(1.0, 1.0, 1.0, 0.85),
    IndicatorWhite  = FLinearColor(1.0, 1.0, 1.0, 0.95),
    Transparent     = FLinearColor(0.0, 0.0, 0.0, 0.0),
}

-- ==============================================================================
-- 4. СИНХРОНИЗАЦИЯ НАСТРОЕК С ДВИЖКОМ (afw.lua)
-- ==============================================================================
_G.GTLMODConfig = _G.GTLMODConfig or {}
local defaultConfig = {
    -- ESP
    EspVip = false, EspVipPro = false, EspDistance = false, EspName = false, EspRadar = false,
    Esp5 = false, Esp6 = false, Esp7 = false, Esp8 = false, EspAntenna = false,
    EspItem_Master = false, EspItem_AR = true, EspItem_Sniper = true, EspItem_SMG = true,
    EspItem_Shotgun = true, EspItem_LMG = true, EspItem_Pistol = true, EspItem_Scope = true,
    EspItem_Med = true, EspItem_Grenade = true, EspItem_Special = false,
    EspModelName = false, EspShowDistance = false, EspShowHealthBar = false, EspTeamColorBox = false,
    EspWeaponIcon = false, EspActiveBom = false, EspLine = false, CounterEnabled = false,
    -- AIM
    AimTouchEnable = false, ForceAimbot = false, AimTouchIgKnock = true, AimTouchIgBot = true, AimTouchVisCheck = true,
    PrivSmallCrosshair = false,
    -- EXPLOIT
    WallhackSmart = false, IpadView = false, CustomHRecoil = false, CustomVRecoil = false,
    CustomAimbot = false, CustomAimbotClose = false, LessShake = false, Accuracy = false, GodMode = false,
    BlackSky = false, RemoveGrass = false, RemoveFog = false,
    -- SKINS
    ModSkin = false, SkinSuit = 1, SkinBag = 1, SkinHelmet = 1, SkinGloves = 1,
    SkinGlider = 1, SkinParachute = 1, SkinM416 = 1, SkinAKM = 1, SkinSCAR = 1,
}
for k, v in pairs(defaultConfig) do
    if _G.GTLMODConfig[k] == nil then _G.GTLMODConfig[k] = v end
end

_G.GTLMODState = _G.GTLMODState or { CustomTextData = {} }
if not _G.GTLMODState.CustomTextData then _G.GTLMODState.CustomTextData = {} end
_G.GTLMODState.CustomTextData.IpadViewFOV = _G.GTLMODState.CustomTextData.IpadViewFOV or 120

-- Функция синхронизации переключателей с движком afw.lua
local function UpdateFeature(configKey, isEnabled)
    _G.GTLMODConfig[configKey] = isEnabled

    if configKey == "Esp5" then
        _G.GTLMODConfig.EspBox = isEnabled
        _G.GTLMODConfig.Box = isEnabled
    elseif configKey == "EspLine" then
        _G.GTLMODConfig.Line = isEnabled
    elseif configKey == "EspModelName" then
        _G.GTLMODConfig.EspName = isEnabled
        _G.GTLMODConfig.EspDistance = isEnabled
        _G.GTLMODConfig.EspShowDistance = isEnabled
    elseif configKey == "EspVipPro" then
        _G.GTLMODConfig.EspShowHealthBar = isEnabled
        _G.GTLMODConfig.EspHealth = isEnabled
    elseif configKey == "AimTouchEnable" then
        _G.GTLMODConfig.ForceAimbot = isEnabled
        _G._ForceAimbotWanted = isEnabled
    elseif configKey == "ForceAimbot" then
        _G.GTLMODConfig.AimTouchEnable = isEnabled
        _G._ForceAimbotWanted = isEnabled
    elseif configKey == "WallhackSmart" then
        if isEnabled then
            if _G.StartNewWallhack then pcall(_G.StartNewWallhack) end
        else
            if _G.StopNewWallhack then pcall(_G.StopNewWallhack) end
        end
    elseif configKey == "BlackSky" then
        if _G.ApplyBlackSky then pcall(_G.ApplyBlackSky, isEnabled) end
    elseif configKey == "IpadView" then
        if _G.GTLMODState and _G.GTLMODState.CustomTextData then
            _G.GTLMODState.CustomTextData.IpadViewFOV = isEnabled and 120 or 90
        end
    end

    -- Немедленный вызов синхронизации движка
    if _G.EnsureModFeaturesRunning then
        pcall(_G.EnsureModFeaturesRunning)
    end
end

-- Размеры
local MENU_W, MENU_H        = 640, 411
local SIDEBAR_X, SIDEBAR_Y  = 10, 8
local SIDEBAR_W, SIDEBAR_H  = 83, 396
local INDICATOR_W           = 226
local INDICATOR_H           = 5

local currentTab = "ESP"
local bgPanel, bgSlot, floatContainer, floatSlot, topPillContainer, topPillSlot = nil, nil, nil, nil, nil, nil
local sidebarContainer, contentContainer, parentCanvas, isMenuOpen, clockTextBlock = nil, nil, nil, false, nil

local function GetViewport()
    local vpW, vpH = 1280, 720
    pcall(function()
        local ui_util = require("client.common.ui_util")
        if ui_util and ui_util.GetViewportSize then
            local sz = ui_util.GetViewportSize()
            if sz and sz.X and sz.X > 50 and sz.Y and sz.Y > 50 then
                vpW = sz.X; vpH = sz.Y
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
        pcall(function() b:SetBrushColor(color) end)
        SetVis(b, "SelfHitTestInvisible")
        local slot = parent:AddChildToCanvas(b)
        if slot then
            slot:SetAutoSize(false); slot:SetPosition(FVector2D(x, y))
            slot:SetSize(FVector2D(w, h)); slot:SetZOrder(zOrder or 0)
        end
    end
    return b
end

local function RoundedPanel(parent, x, y, w, h, r, color, zOrder)
    local container = NewObject("/Script/UMG.CanvasPanel", parent)
    if not IsValid(container) then return nil end
    local cSlot = parent:AddChildToCanvas(container)
    if cSlot then
        cSlot:SetAutoSize(false); cSlot:SetPosition(FVector2D(x, y))
        cSlot:SetSize(FVector2D(w, h)); cSlot:SetZOrder(zOrder or 0)
    end
    SetVis(container, "SelfHitTestInvisible")

    r = math.min(math.floor(r or 12), math.floor(h * 0.5), math.floor(w * 0.5))
    if r < 1 then
        Layer(container, 0, 0, w, h, color, 0)
        return container
    end

    local top_dx = {}
    for i = 0, r - 1 do
        local dy = r - (i + 0.5)
        local dx = math.floor(r - math.sqrt(math.max(0, r * r - dy * dy)) + 0.5)
        top_dx[#top_dx + 1] = dx
    end
    local merged, curDx, curY, curH = {}, top_dx[1], 0, 1
    for i = 2, #top_dx do
        if top_dx[i] == curDx then curH = curH + 1
        else
            merged[#merged + 1] = { dx = curDx, y = curY, h = curH }
            curDx, curY, curH = top_dx[i], i - 1, 1
        end
    end
    merged[#merged + 1] = { dx = curDx, y = curY, h = curH }

    for _, s in ipairs(merged) do Layer(container, s.dx, s.y, w - 2 * s.dx, s.h, color, 0) end
    local midH = h - 2 * r
    if midH > 0 then Layer(container, 0, r, w, midH, color, 0) end
    for _, s in ipairs(merged) do Layer(container, s.dx, h - s.y - s.h, w - 2 * s.dx, s.h, color, 0) end

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
            slot:SetAutoSize(true); slot:SetPosition(FVector2D(x, y))
            slot:SetAlignment(FVector2D(alignX or 0.0, alignY or 0.0)); slot:SetZOrder(zOrder or 1)
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
            slot:SetAutoSize(false); slot:SetPosition(FVector2D(x, y))
            slot:SetSize(FVector2D(w, h)); slot:SetZOrder(zOrder or 1000)
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
-- 5. СТРОКА ТАБЛИЦЫ И ТУМБЛЕР
-- ==============================================================================
local function DrawToggle(parent, x, y, configKey)
    local tw, th, tr = 42, 24, 12
    local on = _G.GTLMODConfig[configKey]
    local trackColor = on and C.ToggleOn or C.ToggleOff
    RoundedPanel(parent, x, y, tw, th, tr, trackColor, 12)
    local kw, kh, kr = 18, 18, 9
    local knobX = on and (x + 21) or (x + 3)
    RoundedPanel(parent, knobX, y + 3, kw, kh, kr, C.KnobWhite, 14)
    MakeBtn(parent, x - 5, y - 5, tw + 10, th + 10, 16, function()
        local newState = not _G.GTLMODConfig[configKey]
        UpdateFeature(configKey, newState)
        RenderContent()
    end)
end

local function DrawRow(parent, labelText, yPos, configKey)
    Text(parent, labelText, 119, yPos + 12, 13, C.TextDark, 12, 0.0, 0.5)
    DrawToggle(parent, 570, yPos, configKey)
end

-- ==============================================================================
-- 6. ПРОЦЕДУРНЫЕ ИКОНКИ САЙДБАРА
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
-- 7. ДИНАМИЧЕСКИЙ САЙДБАР (ПОДСВЕТКА ВЫБРАННОЙ ВКЛАДКИ ЗЕЛЕНЫМ)
-- ==============================================================================
local function RenderSidebar()
    if not IsValid(sidebarContainer) then return end
    sidebarContainer:ClearChildren()
    RoundedPanel(sidebarContainer, 0, 0, SIDEBAR_W, SIDEBAR_H, 20, C.SidebarBg, 1)

    local tabs = {
        { id = "ESP",     name = "ESP",  y = 5,   h = 60 },
        { id = "AIM",     name = "AIM",  y = 72,  h = 60 },
        { id = "SKINS",   name = "SKIN", y = 132, h = 60 },
        { id = "EXPLOIT", name = "MEM",  y = 192, h = 60 },
        { id = "SET",     name = "SET",  y = 252, h = 60 },
    }

    for _, tab in ipairs(tabs) do
        local isActive = (currentTab == tab.id)
        local tabY = tab.y

        -- Зеленая подсветка только для выбранной вкладки
        if isActive then
            RoundedPanel(sidebarContainer, 0, tabY, SIDEBAR_W, tab.h, 12, C.SidebarActiveBg, 3)
        end

        local textCol = isActive and C.TextActiveESP or C.TextDark

        if tab.id == "ESP" then
            RoundedPanel(sidebarContainer, 27.5, tabY + 9, 28, 28, 8, C.IconESP, 10)
            DrawEyeIcon(sidebarContainer, 27.5, tabY + 9)
        elseif tab.id == "AIM" then
            RoundedPanel(sidebarContainer, 27.5, tabY + 9, 28, 28, 8, C.IconAim, 10)
            DrawAimIcon(sidebarContainer, 27.5, tabY + 9)
        elseif tab.id == "SKINS" then
            RoundedPanel(sidebarContainer, 27.5, tabY + 9, 28, 28, 8, C.IconMain, 10)
            DrawHouseIcon(sidebarContainer, 27.5, tabY + 9)
        elseif tab.id == "EXPLOIT" then
            RoundedPanel(sidebarContainer, 27.5, tabY + 9, 28, 28, 8, C.IconMem, 10)
            DrawMemIcon(sidebarContainer, 27.5, tabY + 9)
        elseif tab.id == "SET" then
            RoundedPanel(sidebarContainer, 27.5, tabY + 9, 28, 28, 8, C.IconSet, 10)
            DrawSetIcon(sidebarContainer, 27.5, tabY + 9)
        end

        Text(sidebarContainer, tab.name, 41.5, tabY + 46, 9, textCol, 12, 0.5, 0.5)

        -- Кнопка переключения вкладки (высокий Z-Order = 100)
        local targetId = tab.id
        MakeBtn(sidebarContainer, 0, tabY, SIDEBAR_W, tab.h, 100, function()
            if currentTab ~= targetId then
                currentTab = targetId
                RenderSidebar()
                RenderContent()
            end
        end)
    end
end

-- ==============================================================================
-- 8. КОНТЕНТ МЕНЮ
-- ==============================================================================
function RenderContent()
    if not IsValid(contentContainer) then return end
    contentContainer:ClearChildren()

    if currentTab == "ESP" then
        Text(contentContainer, "ESP", 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)
        Layer(contentContainer, 119, 62, 12, 12, C.CategorySquare, 10)
        Text(contentContainer, "Character", 138, 68, 12, C.TextCategory, 12, 0.0, 0.5)
        Layer(contentContainer, 119, 84, 493, 1, C.DividerTop, 10)

        DrawRow(contentContainer, "ESP Box / Frame", 95, "Esp5")
        Layer(contentContainer, 119, 129, 493, 1, C.DividerRow, 10)

        DrawRow(contentContainer, "ESP Skeleton (Line)", 140, "EspLine")
        Layer(contentContainer, 119, 174, 493, 1, C.DividerRow, 10)

        DrawRow(contentContainer, "ESP Name & Dist", 185, "EspModelName")
        Layer(contentContainer, 119, 219, 493, 1, C.DividerRow, 10)

        DrawRow(contentContainer, "ESP Health", 230, "EspVipPro")

    elseif currentTab == "AIM" then
        Text(contentContainer, "AIM", 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)
        Layer(contentContainer, 119, 62, 12, 12, C.CategorySquare, 10)
        Text(contentContainer, "Aimbot", 138, 68, 12, C.TextCategory, 12, 0.0, 0.5)
        Layer(contentContainer, 119, 84, 493, 1, C.DividerTop, 10)

        DrawRow(contentContainer, "Enable Aim Assist", 95, "AimTouchEnable")
        Layer(contentContainer, 119, 129, 493, 1, C.DividerRow, 10)

        DrawRow(contentContainer, "Ignore Knocked", 140, "AimTouchIgKnock")
        Layer(contentContainer, 119, 174, 493, 1, C.DividerRow, 10)

        DrawRow(contentContainer, "Force Aimbot", 185, "ForceAimbot")

    elseif currentTab == "SKINS" then
        Text(contentContainer, "SKIN HACKS", 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)
        Layer(contentContainer, 119, 62, 12, 12, C.CategorySquare, 10)
        Text(contentContainer, "Mod Skin", 138, 68, 12, C.TextCategory, 12, 0.0, 0.5)
        Layer(contentContainer, 119, 84, 493, 1, C.DividerTop, 10)

        DrawRow(contentContainer, "Enable Skin Hack", 95, "ModSkin")
        Layer(contentContainer, 119, 129, 493, 1, C.DividerRow, 10)

        Text(contentContainer, "Skin settings integrated with engine", 119, 135, 11, C.TextDark, 12, 0.0, 0.5)

    elseif currentTab == "EXPLOIT" then
        Text(contentContainer, "EXPLOITS", 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)
        Layer(contentContainer, 119, 62, 12, 12, C.CategorySquare, 10)
        Text(contentContainer, "Memory / Exploits", 138, 68, 12, C.TextCategory, 12, 0.0, 0.5)
        Layer(contentContainer, 119, 84, 493, 1, C.DividerTop, 10)

        DrawRow(contentContainer, "Wallhack Chams", 95, "WallhackSmart")
        Layer(contentContainer, 119, 129, 493, 1, C.DividerRow, 10)

        DrawRow(contentContainer, "IPad View", 140, "IpadView")
        Layer(contentContainer, 119, 174, 493, 1, C.DividerRow, 10)

        DrawRow(contentContainer, "Black Sky", 185, "BlackSky")

    elseif currentTab == "SET" then
        Text(contentContainer, "SETTINGS", 365, 38, 16, C.TextTitle, 12, 0.5, 0.5)
        Layer(contentContainer, 119, 62, 12, 12, C.CategorySquare, 10)
        Text(contentContainer, "Configs", 138, 68, 12, C.TextCategory, 12, 0.0, 0.5)
        Layer(contentContainer, 119, 84, 493, 1, C.DividerTop, 10)

        Text(contentContainer, "Sodalite UI v2.3 Replica", 119, 105, 13, C.TextDark, 12, 0.0, 0.5)

        local engineStatus = _G._ENGINE_LOADED and "afw.lua [ACTIVE / OK]" or "afw.lua [CONNECTING...]"
        local statusColor = _G._ENGINE_LOADED and C.TextActiveESP or C.KnobWhite
        Text(contentContainer, "Engine: " .. engineStatus, 119, 135, 12, statusColor, 12, 0.0, 0.5)
    end
end

-- ==============================================================================
-- 9. ВЕРХНИЙ ПЛАВАЮЩИЙ БАР (TOP PILL: 11:58)
-- ==============================================================================
local function CreateTopPill(canvas)
    if IsValid(topPillContainer) then return end
    local vpW, _ = GetViewport()
    local pillW, pillH, pr = 363, 38, 19
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
    _G.SodaLite_TopPillContainer = topPillContainer

    RoundedPanel(topPillContainer, 0, 3, pillW, pillH, pr, C.TopPillShadow, 1)
    RoundedPanel(topPillContainer, -1, -1, pillW + 2, pillH + 2, pr + 1, C.TopPillOutline, 2)
    RoundedPanel(topPillContainer, 0, 0, pillW, pillH, pr, C.TopPillBg, 3)

    -- Только часы и минуты (например 11:58)
    clockTextBlock = Text(topPillContainer, os.date("%H:%M"), 45, 19, 13, C.TopPillClock, 10, 0.5, 0.5)
    Text(topPillContainer, "|", 88, 19, 12, C.TopPillDiv, 10, 0.5, 0.5)
    Text(topPillContainer, "Mango Cheats", 160, 19, 13, C.TopPillTitle, 10, 0.5, 0.5)
    Text(topPillContainer, "|", 232, 19, 12, C.TopPillDiv, 10, 0.5, 0.5)
    Text(topPillContainer, "Expend 999 day", 296, 19, 12, C.TopPillStatus, 10, 0.5, 0.5)
end

-- ==============================================================================
-- 10. АДАПТИВНОЕ ЦЕНТРИРОВАНИЕ
-- ==============================================================================
local function UpdateLayoutPositions(vpW, vpH)
    if topPillSlot then
        local pillW = 363
        local pillX = math.floor((vpW - pillW) * 0.5)
        pcall(function() topPillSlot:SetPosition(FVector2D(pillX, 12)) end)
    end
    if floatSlot then
        local hitW, hitH = 280, 50
        local fX = math.floor((vpW - hitW) * 0.5)
        local fY = vpH - hitH - 8
        pcall(function() floatSlot:SetPosition(FVector2D(fX, fY)) end)
    end
    if IsValid(bgPanel) and bgSlot then
        local posX = math.max(0, math.floor((vpW - MENU_W) * 0.5))
        local posY = math.max(0, math.floor((vpH - MENU_H) * 0.5))
        pcall(function() bgSlot:SetPosition(FVector2D(posX, posY)) end)
    end
end

-- ==============================================================================
-- 11. УПРАВЛЕНИЕ МЕНЮ (ОТКРЫТЬ / ЗАКРЫТЬ)
-- ==============================================================================
local function CloseMenu()
    isMenuOpen = false
    if IsValid(bgPanel) then SetVis(bgPanel, "Collapsed") end
    if IsValid(floatContainer) then SetVis(floatContainer, "SelfHitTestInvisible") end
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
    if IsValid(floatContainer) then SetVis(floatContainer, "Collapsed") end
end

function ToggleMenu(canvas)
    if isMenuOpen then CloseMenu() else OpenMenu(canvas) end
end

-- ==============================================================================
-- 12. СБОРКА ОСНОВНОГО ОКНА МЕНЮ
-- ==============================================================================
function BuildMenu(canvas)
    if IsValid(bgPanel) then
        local vpW, vpH = GetViewport()
        UpdateLayoutPositions(vpW, vpH)
        SetVis(bgPanel, "SelfHitTestInvisible")
        if IsValid(floatContainer) then SetVis(floatContainer, "Collapsed") end
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
    _G.SodaLite_BgPanel = bgPanel

    local menuRadius = 25
    RoundedPanel(bgPanel, 4, 4, MENU_W, MENU_H, menuRadius, C.Shadow, 1)
    RoundedPanel(bgPanel, -1, -1, MENU_W + 2, MENU_H + 2, menuRadius + 1, C.Outline, 2)
    RoundedPanel(bgPanel, 0, 0, MENU_W, MENU_H, menuRadius, C.WindowBg, 3)

    -- Контейнер сайдбара с Z-Order = 50 (всегда выше контента!)
    sidebarContainer = NewObject("/Script/UMG.CanvasPanel", bgPanel)
    local sSlot = bgPanel:AddChildToCanvas(sidebarContainer)
    if sSlot then
        sSlot:SetAutoSize(false)
        sSlot:SetPosition(FVector2D(SIDEBAR_X, SIDEBAR_Y))
        sSlot:SetSize(FVector2D(SIDEBAR_W, SIDEBAR_H))
        sSlot:SetZOrder(50)
    end
    SetVis(sidebarContainer, "SelfHitTestInvisible")
    RenderSidebar()

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

    -- Кнопка закрытия [✕]
    RoundedPanel(bgPanel, 601, 9, 27, 23, 11, C.CloseBtnBg, 9990)
    Text(bgPanel, "✕", 614.5, 20.5, 14, C.CloseCross, 9991, 0.5, 0.5)
    MakeBtn(bgPanel, 570, 0, 70, 50, 10000, function() CloseMenu() end)

    if IsValid(floatContainer) then SetVis(floatContainer, "Collapsed") end
    isMenuOpen = true
end

-- ==============================================================================
-- 13. НИЖНИЙ ИНДИКАТОР HOME BAR
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
    _G.SodaLite_FloatContainer = floatContainer

    local barX = math.floor((hitW - fW) * 0.5)
    local barY = hitH - fH - 8
    RoundedPanel(floatContainer, barX, barY + 1, fW, fH, 2.5, C.Shadow, 1)
    RoundedPanel(floatContainer, barX, barY, fW, fH, 2.5, C.IndicatorWhite, 2)
    MakeBtn(floatContainer, 0, 0, hitW, hitH, 100, function() ToggleMenu(canvas) end)
end

-- ==============================================================================
-- 14. НАБЛЮДАТЕЛЬ ЗА ЭКРАНОМ
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
-- 15. ПОИСК CANVAS И ИНИЦИАЛИЗАЦИЯ
-- ==============================================================================
function GetCanvas()
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
    local vpW, vpH = GetViewport()
    if vpW < 50 or vpH < 50 then return end

    CreateTopPill(canvas)
    CreateFloatButton(canvas)

    -- Меню изначально закрыто
    isMenuOpen = false
    _initDone = true
    if IsValid(floatContainer) then SetVis(floatContainer, "SelfHitTestInvisible") end
end

local function InitWatcher()
    if _initDone then
        pcall(function()
            if IsValid(clockTextBlock) then clockTextBlock:SetText(os.date("%H:%M")) end
            CheckViewportChange()
        end)
    else
        pcall(TryInit)
    end
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.5, InitWatcher) end
end
InitWatcher()

function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    pcall(TryInit)
    pcall(function()
        if _G.EnsureModFeaturesRunning then _G.EnsureModFeaturesRunning() end
    end)
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    pcall(TryInit)
    pcall(function()
        if _G.EnsureModFeaturesRunning then _G.EnsureModFeaturesRunning() end
    end)
end

return BRPlayerCharacterBase
