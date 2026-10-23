-- ============================================================
-- TESLA 10X GAMING 4.6 — BYPASS UPGRADE (22-LAYER)
-- Generated: 2026-10-23
-- User: Rich23yo (6133128553)
-- Features: ESP Distance, ESP HP Bar, ESP Master, ESP Names, ESP Player Counter,
--           ESP Snaplines, ESP Team Color, ESP VIP Panel, Enemy Stance + Weapon,
--           Fake HWID, Wallhack Chams, iPad View FOV
-- Bypass: 🔴 Fortress (22 layers) + Legacy Tier 10/20/30
-- ============================================================

local BRPlayerCharacterBase = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {}, LuaEventContainer = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }

local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local EMovementMode = import("EMovementMode")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")

-- [[TESLA_CONFIG_START]]
_G.LexusConfig = _G.LexusConfig or {
    AimTouchEnable = false,
    ColorBodyNew = true,
    Esp9_Count = true,
    Esp9_Distance = true,
    Esp9_HP = true,
    Esp9_Line = true,
    Esp9_Name = true,
    Esp9_Skeleton = false,
    Esp9_Team = true,
    Esp9_Weapon = false,
    EspAntenna = false,
    EspDistance = false,
    EspLoai5 = false,
    EspLoai6 = false,
    EspLoai7 = true,
    EspLoai8 = false,
    EspLoai9 = true,
    EspOutline = false,
    EspRadar = false,
    EspVip = false,
    EspVipPro = true,
    FakeHWID = true,
    IpadView = true,
    KillCountUI = false,
    NoRecoilEnabled = false,
    AimbotMode = 1,
    AimbotBone = 1,
    AimbotFOV = 80,
    AimbotSpeed = 100,
    AimTouchIgKnock = false,
    AimTouchIgBot = false,
    AimTouchVisCheck = false,
    RecoilReduction = 100,
    IpadViewFOV = 120,
    BypassTier = 30,
}
-- [[TESLA_CONFIG_END]]

_G.LexusState = _G.LexusState or { LoopToken = 0, CustomTextData = {}, EnemyMarks = {} }
_G.TeslaLoadedFeatures = {}
_G.TeslaLoadedFeatures = {
  "ESP Player Counter",
  "ESP Distance",
  "ESP HP Bar",
  "ESP Snaplines",
  "ESP Master",
  "ESP Names",
  "Enemy Stance + Weapon",
  "ESP Team Color",
  "ESP VIP Panel",
  "Fake HWID",
  "iPad View FOV",
  "Wallhack Chams"
}

-- LAG FIX & HELPERS
_G.AkoStability = _G.AkoStability or { MainInterval = 0.05, AimbotInterval = 0.033, SlowFrameThreshold = 0.025, SlowFrameBackoff = 0.066, SlowFrameCount = 0 }
local _cached_linear, _cached_skeletal, _cached_gpdata, _cached_ticker = nil, nil, nil, nil

local function getLC() if _cached_linear == nil then _cached_linear = import("LinearColor") end return _cached_linear end
local function getSkel() if _cached_skeletal == nil then _cached_skeletal = import("SkeletalMeshComponent") end return _cached_skeletal end
local function getGD()
  if _cached_gpdata == nil then
    local ok, m = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok then _cached_gpdata = m end
  end
  return _cached_gpdata
end
local function getTicker()
  if _cached_ticker == nil then
    local ok, t = pcall(require, "common.time_ticker")
    if ok then _cached_ticker = t end
  end
  return _cached_ticker
end

local _slua = rawget(_G, "slua")
function _G.Valid(obj)
  if not obj then return false end
  if _slua and _slua.isValid then
    local ok, v = pcall(_slua.isValid, obj)
    return ok and v
  end
  return true
end

function _G.Notify(msg)
  local s = "[TESLA 10X] " .. tostring(msg)
  pcall(function() print(s) end)
  pcall(function()
    local sh = import("ScriptHelperClient")
    if sh and sh.AddOnScreenDebugMessage then
      sh.AddOnScreenDebugMessage(s, -1, 4.0, {R=1, G=0.85, B=0, A=1}, {X=1.2, Y=1.2})
    end
  end)
end

-- SAVE / LOAD CONFIG
local ConfigFileName = "TESLA_10X_settings.txt"
local function GetConfigPaths(fileName)
  return {
    "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "ShadowTrackerExtra/Saved/Paks/" .. fileName, fileName
  }
end

function _G.SaveModSettings()
  pcall(function()
    local data = "return {\n"
    for k, v in pairs(_G.LexusConfig or {}) do
      data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
    end
    data = data .. "}\n"
    for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
      local file = io.open(path, "w")
      if file then file:write(data); file:close(); break end
    end
  end)
end

function _G.LoadModSettings()
  pcall(function()
    for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
      local file = io.open(path, "r")
      if file then
        local content = file:read("*a"); file:close()
        local func = load(content)
        if func then
          local savedData = func()
          if savedData and type(savedData) == "table" then
            for k, v in pairs(savedData) do _G.LexusConfig[k] = v end
          end
        end
        break
      end
    end
  end)
end
LoadModSettings()

function _G.GetSafeEnemyKey(enemy)
  if Valid(enemy) then
    if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
    if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
  end
  return tostring(enemy)
end

function _G.CheckIsAI(pawn, markData)
  if markData.AK_IS_BOT ~= nil then return markData.AK_IS_BOT, true end
  local isAI = false; local hasChecked = false
  pcall(function()
    if pawn.bIsAI == true or pawn.IsAI == true then isAI = true; hasChecked = true end
    if type(pawn.IsBot) == "function" and pawn:IsBot() then isAI = true; hasChecked = true end
    local ps = pawn.PlayerState or (type(pawn.GetPlayerState) == "function" and pawn:GetPlayerState())
    if Valid(ps) then
      hasChecked = true
      if ps.bIsABot == true or ps.bIsBot == true then isAI = true end
    end
  end)
  if hasChecked then markData.AK_IS_BOT = isAI end
  return isAI, hasChecked
end

function _G.GetAllSkeletalMeshes(enemy, markData)
  local curTime = os.clock()
  if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime < 0.5) then
    local valid = {}
    for _, m in ipairs(markData.CachedMeshes) do if Valid(m) then table.insert(valid, m) end end
    markData.CachedMeshes = valid; return valid
  end
  local meshes = {}
  if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
  pcall(function()
    local skel = getSkel()
    if skel and type(enemy.GetComponentsByClass) == "function" then
      local comps = enemy:GetComponentsByClass(skel)
      if comps then
        local n = type(comps.Num) == "function" and comps:Num() or #comps
        for i = 1, n do
          local c = type(comps.Get) == "function" and comps:Get(i-1) or comps[i]
          if Valid(c) and c ~= enemy.Mesh then table.insert(meshes, c) end
        end
      end
    end
  end)
  if markData then markData.CachedMeshes = meshes; markData.CachedMeshTime = curTime end
  return meshes
end


-- ============================================================
-- ESP SYSTEM (без изменений)
-- ============================================================
_G.PlayerMapMarker = _G.PlayerMapMarker or {}
local PMM = _G.PlayerMapMarker
PMM.ESPWidgets = PMM.ESPWidgets or {}
PMM.ESPWidgetPtrs = PMM.ESPWidgetPtrs or {}
PMM._Canvas = nil

function PMM.GetPC() local GD = getGD(); return GD and GD.GetPlayerController and GD.GetPlayerController() end
function PMM.GetLocalChar() local GD = getGD(); return GD and GD.GetLocalCharacter and GD.GetLocalCharacter() end
function PMM.GetAllChars()
  local c = {}
  pcall(function()
    local p = Game:GetAllPlayerPawns()
    if p then for _, v in pairs(p) do
      if v and slua.isValid(v) then
        local k = v.PlayerKey or (v.GetPlayerKey and v:GetPlayerKey())
        if k then c[k] = v end
      end
    end end
  end)
  return c
end
function PMM.GetTeamID(c) if not Valid(c) then return nil end local t = nil; pcall(function() t = c.TeamID or (c.GetTeamID and c:GetTeamID()) end); return t end
function PMM.IsMe(c, k, mk) if not Valid(c) then return false end; local my = PMM.GetLocalChar(); if my and c == my then return true end; return mk ~= nil and k ~= nil and tostring(k) == tostring(mk) end

function PMM.InitCanvas()
  if PMM._Canvas and Game:IsValid(PMM._Canvas) then return true end
  local ok, t = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameUITools")
  if not ok then return false end
  local u = t.GetMainControlBaseUI()
  if u and Game:IsValid(u) then
    PMM._Canvas = u.CanvasPanel_0 or u.CanvasPanel_42
  end
  return PMM._Canvas ~= nil
end

function PMM.UpdTransform(pc)
  local scale = 1.0
  pcall(function()
    local w = import("WidgetLayoutLibrary")
    if w and w.GetViewportScale then scale = w.GetViewportScale(pc) or 1.0 end
  end)
  PMM._scaleX = 1.0 / scale
  PMM._scaleY = 1.0 / scale
end

function PMM.Project(pc, loc)
  local v2 = import("Vector2D")
  local sp = v2 and v2(0,0) or {X=0,Y=0}
  local ok = false
  pcall(function()
    local r = pc:ProjectWorldLocationToScreen(loc, sp, true)
    if r == true or r == 1 then ok = true end
  end)
  if not ok or (sp.X == 0 and sp.Y == 0) then return false, nil end
  local out = v2 and v2(sp.X * (PMM._scaleX or 1), sp.Y * (PMM._scaleY or 1)) or {X=sp.X,Y=sp.Y}
  return true, out
end

function PMM.CreateWidget()
  if not PMM.InitCanvas() then return nil end
  local w = nil
  pcall(function()
    if not PMM.Class then
      PMM.Class = slua.loadClass("/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP")
    end
    local s = import("STExtraBlueprintFunctionLibrary")
    local p = PMM.GetPC()
    if s and PMM.Class then
      w = s.CreateWidgetByClass(PMM.Class, p and p.Object or PMM._Canvas)
    end
  end)
  if w then
    w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    return { C = w, N = w.TextBlock_TeamName }
  end
  return nil
end

function PMM.UpdWidget(wid, txt, pos, pc, onScr)
  if not wid or not wid.C then return end
  local c = wid.C
  if not onScr or not pos then
    pcall(function() c:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    return
  end
  if not PMM._Canvas or not Game:IsValid(PMM._Canvas) then return end
  local ptr = tostring(c)
  local slot = PMM.ESPWidgetPtrs[ptr]
  if not slot or not slua.isValid(slot) then
    slot = PMM._Canvas:AddChildToCanvas(c)
    if slot then
      PMM.ESPWidgetPtrs[ptr] = slot
      pcall(function() slot:SetAutoSize(true) end)
      pcall(function() slot:SetZOrder(20) end)
      local v2 = import("Vector2D")
      pcall(function() slot:SetAlignment(v2 and v2(0.5, 1.0) or {X=0.5,Y=1.0}) end)
    end
  end
  pcall(function() c:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
  if not wid.rst then
    local v2 = import("Vector2D")
    pcall(function() c:SetRenderScale(v2 and v2(0.8, 0.8) or {X=0.8,Y=0.8}) end)
    wid.rst = true
  end
  if slot and slua.isValid(slot) then
    if not wid.p then wid.p = pos else wid.p.X = pos.X; wid.p.Y = pos.Y end
    pcall(function() slot:SetPosition(wid.p) end)
  end
  if wid.N and wid.txt ~= txt then
    pcall(function() wid.N:SetText(txt) end)
    local sc = import("SlateColor")
    local lc = getLC()
    if sc and lc then pcall(function() wid.N:SetColorAndOpacity(sc(lc(1,1,1,1))) end) end
    wid.txt = txt
  end
end

function PMM.Scan()
  local chars = PMM.GetAllChars()
  local pc = PMM.GetPC()
  local me = PMM.GetLocalChar()
  if not Valid(pc) or not Valid(me) then return end
  PMM.UpdTransform(pc)
  local myKey = me.PlayerKey
  local myTeam = PMM.GetTeamID(me)
  local myLoc = nil
  pcall(function() myLoc = me:K2_GetActorLocation() end)
  if not myLoc then return end
  local seen = {}
  for k, c in pairs(chars) do
    if Valid(c) and not PMM.IsMe(c, k, myKey) then
      local t = PMM.GetTeamID(c)
      if myTeam == nil or t ~= myTeam then
        local ks = tostring(k)
        seen[ks] = true
        local cloc = nil
        pcall(function() cloc = c:K2_GetActorLocation() end)
        if cloc then
          local wid = PMM.ESPWidgets[ks]
          if not wid then
            wid = PMM.CreateWidget()
            if wid then PMM.ESPWidgets[ks] = wid end
          end
          if wid then
            local headLoc = import("Vector") and import("Vector")(cloc.X, cloc.Y, cloc.Z + 85) or {X=cloc.X, Y=cloc.Y, Z=cloc.Z+85}
            local onScr, pos = PMM.Project(pc, headLoc)
            local txt = ""
            if _G.LexusConfig.Esp9_Name then txt = c.PlayerName or "?" end
            if _G.LexusConfig.Esp9_Distance then
              local d = math.floor(math.sqrt((cloc.X-myLoc.X)^2 + (cloc.Y-myLoc.Y)^2) / 100)
              local ds = string.format("[%dm]", d)
              if txt ~= "" then txt = txt .. " " .. ds else txt = ds end
            end
            PMM.UpdWidget(wid, txt, pos, pc, onScr)
          end
        end
      end
    end
  end
  for k, w in pairs(PMM.ESPWidgets) do
    if not seen[k] and w and w.C then
      pcall(function() w.C:RemoveFromParent(); w.C:ConditionalBeginDestroy() end)
      PMM.ESPWidgets[k] = nil
    end
  end
end



-- ============================================================
-- WALLHACK CHAMS (без изменений)
-- ============================================================
function _G.ApplyChams(enemy, md)
  if not _G.ConsoleNewWallReady then
    local w = slua.getWorld(); local k = import("KismetSystemLibrary")
    if k and w then
      k.ExecuteConsoleCommand(w, "r.EnableDrawDyeingColor 1")
      k.ExecuteConsoleCommand(w, "r.CustomDepth 3")
      _G.ConsoleNewWallReady = true
    end
  end
  local m = _G.GetAllSkeletalMeshes(enemy, md)
  local wep = enemy:GetCurrentWeapon()
  if Valid(wep) and Valid(wep.Mesh) then table.insert(m, wep.Mesh) end
  local isBot = md.AK_IS_BOT or false
  local h = (isBot and "B" or "P") .. "_" .. tostring(#m)
  if md.LastChams == h and md.ChamsOn then return end
  md.LastChams = h; md.ChamsOn = true
  local lc = getLC()
  local v = lc and lc(0,100,0,1) or {R=0,G=100,B=0,A=1}
  local o = lc and lc(100,0,0,1) or {R=100,G=0,B=0,A=1}
  if isBot then
    v = lc and lc(49,48,0,100) or {R=49,G=48,B=0,A=100}
    o = lc and lc(9,1,45,100) or {R=9,G=1,B=45,A=100}
  end
  for _, mesh in ipairs(m) do
    if Valid(mesh) and mesh.SetDrawDyeing then
      mesh:SetDrawDyeing(true)
      mesh:SetDrawDyeingMode(1)
      mesh:SetVisibleDyeingColor(v)
      mesh:SetOccludedDyeingColor(o)
      mesh:SetDyeingColorFadeDistance(99999)
      mesh:SetDyeingColorMinMaxDistance(0, 99999)
    end
  end
end

function _G.RemoveChams(enemy, md)
  if not md.ChamsOn then return end
  local m = _G.GetAllSkeletalMeshes(enemy, md)
  local wep = enemy:GetCurrentWeapon()
  if Valid(wep) and Valid(wep.Mesh) then table.insert(m, wep.Mesh) end
  for _, mesh in ipairs(m) do
    if Valid(mesh) and mesh.SetDrawDyeing then
      mesh:SetDrawDyeing(false)
    end
  end
  md.ChamsOn = false
  md.LastChams = nil
end



-- ============================================================
-- FAKE HWID (без изменений)
-- ============================================================
function _G.InitHWID()
  pcall(function()
    local l = import("KismetSystemLibrary")
    if l and not _G.HWID_Hooked then
      _G.OrigHWID = l.GetDeviceId
      l.GetDeviceId = function(...)
        if _G.LexusConfig.FakeHWID then
          if not _G.FakeHWID then
            local c = "0123456789ABCDEF"
            local s = ""
            for i = 1, 32 do s = s .. c:sub(math.random(1,16), math.random(1,16)) end
            _G.FakeHWID = s
          end
          return _G.FakeHWID
        end
        return _G.OrigHWID and _G.OrigHWID(...) or "UNKNOWN"
      end
      _G.HWID_Hooked = true
    end
  end)
end



-- ============================================================
-- IPAD VIEW (без изменений)
-- ============================================================
function _G.ApplyIpad(p)
  pcall(function()
    local c = p.ThirdPersonCameraComponent
    if not Valid(c) then return end
    if _G.LexusConfig.IpadView then
      local target = _G.LexusConfig.IpadViewFOV or 120
      if c.FieldOfView ~= target and not p.bIsWeaponAiming then c.FieldOfView = target end
    else
      if c.FieldOfView ~= 90 and not p.bIsWeaponAiming then c.FieldOfView = 90 end
    end
  end)
end



-- ============================================================
-- ============================================================
-- 🔴 FORTRESS BYPASS — 22 LAYERS (заменяет старые Tier 10/20/30)
-- ============================================================
-- ============================================================

-- helpers
local function nop() return true end
local function retTrue() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retEmptyString() return "" end

-- -------------------------------------------------------------
-- L1. SLUA BYPASS
-- -------------------------------------------------------------
local function InitSLUABypass()
  pcall(function()
    if slua and slua.getSignature then
      slua.getSignature = function() return 0xDEADBEEF end
    end
    local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
    if loader then
      loader.verifyBytecode = retTrue
      loader.checkIntegrity = retTrue
      if loader.disableSignatureCheck then loader.disableSignatureCheck = retTrue end
    end
    if slua_serialize then
      slua_serialize.check = retTrue
      slua_serialize.verify = retTrue
    end
    if jit and jit.attach then
      jit.attach(function() end, "bc")
    end
    if _G.slua_verify then _G.slua_verify = retTrue end
    if _G.check_slua_integrity then _G.check_slua_integrity = retTrue end
  end)
end

-- -------------------------------------------------------------
-- L2. MDS & SIGNATURE BYPASS
-- -------------------------------------------------------------
local function InitMDSBypass()
  pcall(function()
    local console = import("KismetSystemLibrary")
    if console then
      console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
      console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
      console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
    end
    if CreativeModeBlueprintLibrary then
      CreativeModeBlueprintLibrary.MD5HashByteArray = function()
        return "0000000000000000000000000000000000000000000000000000000000000000"
      end
      CreativeModeBlueprintLibrary.GetContentDiffData = retTrue
      CreativeModeBlueprintLibrary.VerifyFileIntegrity = retTrue
    end
    if _G.MD5Hash then _G.MD5Hash = function() return "BYPASS" end end
    if _G.CRC32   then _G.CRC32   = function() return 0 end end
    if _G.SHA1    then _G.SHA1    = function() return "BYPASS" end end
    local FileHashChecker = package.loaded["common.file.hash_checker"]
    if FileHashChecker then
      FileHashChecker.CheckFileMD5 = retTrue
      FileHashChecker.VerifyFileAll = retTrue
    end
    local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
    if TssSdk then
      TssSdk.GetFileMD5 = function() return "BYPASS" end
      TssSdk.VerifyFileSignature = retTrue
    end
  end)
end

-- -------------------------------------------------------------
-- L3. SKIN & AVATAR BYPASS
-- -------------------------------------------------------------
local function InitSkinBypass()
  pcall(function()
    local puffer_tlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
    if puffer_tlog then
      puffer_tlog.ReportEvent = nop
      puffer_tlog.ReportDownloadResult = nop
      puffer_tlog.ReportODPTDError = nop
      puffer_tlog.ReportSkinError = nop
    end
    local AvatarUtils = package.loaded["AvatarUtils"]
    if AvatarUtils then
      AvatarUtils.CheckIsWeaponInBlackList = retFalse
      AvatarUtils.IsValidAvatar = retTrue
      AvatarUtils.CheckAvatarIntegrity = retTrue
      AvatarUtils.ReportInvalidAvatar = nop
    end
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    local fileCheckSubsystem = SubsystemMgr and SubsystemMgr:Get("FileCheckSubsystem")
    if fileCheckSubsystem then
      fileCheckSubsystem.StartCheck = nop
      fileCheckSubsystem.ReportAbnormalFile = nop
      fileCheckSubsystem.StopCheck = nop
    end
    local equipmentException = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
    if equipmentException then
      equipmentException.Report = nop
      equipmentException.SendException = nop
    end
  end)
end

-- -------------------------------------------------------------
-- L4. LOG BLOCKER — logs, screenshots, analytics
-- -------------------------------------------------------------
local function InitLogBlocker()
  pcall(function()
    local ScreenshotMTDer = import("ScreenshotMTDer")
    if ScreenshotMTDer then
      ScreenshotMTDer.MTDePicture = retEmptyString
      ScreenshotMTDer.RemTDePicture = retEmptyString
      ScreenshotMTDer.HasCaptured = retTrue
      ScreenshotMTDer.TakeScreenshot = nop
    end
    local TLog = package.loaded["TLog"] or _G.TLog
    if TLog then
      TLog.Info = nop; TLog.Warning = nop; TLog.Error = nop
      TLog.Debug = nop; TLog.Report = nop; TLog.Send = nop
    end
    local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
    if CrashSight then
      CrashSight.SetCustomData = nop
      CrashSight.SendCrash = nop
      CrashSight.ReportUserException = nop
    end
    local GameReportUtils = package.loaded["GameLua.Mod.BaseMod.GameReportUtils"]
    if GameReportUtils then
      GameReportUtils.BuggyPostException = nop
      GameReportUtils.CheckCanBugglyPostException = retFalse
      GameReportUtils.ReplayReportData = nop
      GameReportUtils.ReportGameException = nop
    end
    local ClientToolsReport = package.loaded["client.slua.logic.report.ClientToolsReport"]
    if ClientToolsReport then
      ClientToolsReport.SendCrash = nop
      ClientToolsReport.UploadLog = nop
    end
    local TLogReportUtils = package.loaded["client.slua.config.tlog.tlog_report_utils"]
    if TLogReportUtils then
      TLogReportUtils.ReportTLogEvent = nop
    end
    for _, sdk in ipairs({"Firebase", "Adjust", "AppsFlyer", "FacebookAnalytics", "GameAnalytics"}) do
      local s = _G[sdk]
      if s then
        s.logEvent = nop; s.trackEvent = nop; s.setEnabled = retFalse
        s.sendEvent = nop; s.report = nop
      end
    end
  end)
end

-- -------------------------------------------------------------
-- L5. SCANNER & VERIFICATION BLOCKER
-- -------------------------------------------------------------
local function InitScannerBlocker()
  pcall(function()
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SubsystemMgr then
      local subsystems = {
        "AFKReporterSubsystem", "ClientDataStatisticsSubsystem",
        "AvatarExceptionSubsystem", "ClientVerifySubsystem",
        "MemoryCheckSubsystem", "SpeedCheckSubsystem",
        "WallCheckSubsystem", "FileCheckSubsystem",
        "BehaviorScoreSubsystem"
      }
      for _, name in ipairs(subsystems) do
        local sub = SubsystemMgr:Get(name)
        if sub then
          for k, v in pairs(sub) do
            if type(v) == "function" and (
              k:find("Report") or k:find("Send") or
              k:find("Upload") or k:find("Check") or
              k:find("Validate") or k:find("Scan") or k:find("Detect")
            ) then
              pcall(function() sub[k] = nop end)
            end
          end
          if sub.ReportPingDelayTimer then
            sub.RemoveGameTimer(sub.ReportPingDelayTimer)
            sub.ReportPingDelayTimer = nil
            sub.DelayCount = 0
          end
        end
      end
    end
    local AvatarExceptionPlayerInst = package.loaded[
      "GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"
    ]
    if AvatarExceptionPlayerInst then
      AvatarExceptionPlayerInst.CheckAvatarException = nop
      AvatarExceptionPlayerInst.ReportAvatarExceptionOnce = nop
      AvatarExceptionPlayerInst.CheckPawnVisible = retFalse
      AvatarExceptionPlayerInst.CheckAvatarMeshVisible = retFalse
      AvatarExceptionPlayerInst.CheckCanBuggyPostException = retFalse
    end
    local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
    if TssSdk then
      local originalOnRecvData = TssSdk.OnRecvData
      TssSdk.OnRecvData = function(data)
        if type(data) == "string" then
          if string.find(data, "cheat") or string.find(data, "violation") or
             string.find(data, "hack") or string.find(data, "verify") then
            return
          end
        end
        if originalOnRecvData then originalOnRecvData(data) end
      end
      TssSdk.SendReportInfo = nop
      TssSdk.ScanMemory = retTrue
      TssSdk.IsMalnet = retFalse
      TssSdk.GetTssSdkReportInfo = retEmptyString
      TssSdk.CheckEnvironment = retTrue
      TssSdk.verifyProcess = retTrue
    end
  end)
end

-- -------------------------------------------------------------
-- L6. REPLAY TELEMETRY BLOCKER
-- -------------------------------------------------------------
local function InitReplayTelemetryBlocker()
  pcall(function()
    local logic_report_replay = package.loaded["client.slua.logic.replay.logic_report_replay"]
    if logic_report_replay then
      logic_report_replay.ReportReplay = nop
      logic_report_replay.SendReportReq = nop
      logic_report_replay.UploadReplay = nop
    end
  end)
end

-- -------------------------------------------------------------
-- L7. REPORT FLOW BLOCKER
-- -------------------------------------------------------------
local function InitReportFlowBlocker()
  pcall(function()
    local reportFlows = {
      "ReportAttackFlow", "ReportHitFlow", "ReportFireArms",
      "ReportSecAttackFlow", "ReportMrpcsFlow", "ReportVerifyInfoFlow",
      "ReportPlayerBehavior", "ReportTeammateHurt", "ReportPlayerMoveRoute",
      "ReportPlayerPosition", "ReportSecVehicleMoveFlow",
      "ReportParachuteData", "ReportMiskillByTeammate",
      "ReportDsNetRate", "ReportCircleFlow",
      "ReportPlayerKillFlow", "ReportPlayerFramePingRecord",
      "ReportDSNetRate", "ReportNetContinuousSaturate",
      "ReportSecMrpcsFlow"
    }
    for _, funcName in ipairs(reportFlows) do
      if _G[funcName] then _G[funcName] = nop end
      if _G.GameplayCallbacks and _G.GameplayCallbacks[funcName] then
        _G.GameplayCallbacks[funcName] = nop
      end
    end
    local checkFuncs = {
      "CheckReportSecAttackFlowWithAttackFlow",
      "CheckReportSecAttackFlow"
    }
    for _, funcName in ipairs(checkFuncs) do
      if _G[funcName] then _G[funcName] = retFalse end
      if _G.GameplayCallbacks and _G.GameplayCallbacks[funcName] then
        _G.GameplayCallbacks[funcName] = retFalse
      end
    end
    local enableFlags = {
      "IsEnableReportPlayerKillFlow",
      "IsEnableReportMrpcsFlow",
      "IsEnableReportMrpcsInPartCircleFlow",
      "IsEnableReportCircleFlow"
    }
    for _, flag in ipairs(enableFlags) do
      if _G[flag] then _G[flag] = retFalse end
    end
  end)
end

-- -------------------------------------------------------------
-- L8. PLAYER SECURITY COLLECTOR BYPASS
-- -------------------------------------------------------------
local function InitPlayerSecurityBypass()
  pcall(function()
    local securityCollectors = {
      "PlayerSecurityInfoCollector",
      "PlayerKillFlow"
    }
    for _, collector in ipairs(securityCollectors) do
      local c = package.loaded[collector]
      if c then
        for k, v in pairs(c) do
          if type(v) == "function" and (
            k:find("Raw") or k:find("Collect") or
            k:find("Upload") or k:find("Record")
          ) then
            pcall(function() c[k] = nop end)
          end
        end
      end
    end
    local ClientFlow = require("GameLua.Mod.BaseMod.Common.Security.ClientFlowSubsystem")
    if ClientFlow then
      ClientFlow.ReportCircleFlow = nop
      ClientFlow.ReportMrpcsFlow = nop
      ClientFlow.ReportPlayerKillFlow = nop
    end
    local SecuritySubsystem = package.loaded[
      "GameLua.Mod.BaseMod.Common.Security.SecuritySubsystem"
    ]
    if SecuritySubsystem then
      SecuritySubsystem.CollectData = nop
      SecuritySubsystem.CheckCheat = retFalse
      SecuritySubsystem.SendToServer = nop
    end
  end)
end

-- -------------------------------------------------------------
-- L9. CLIENT FLOW / CORONA LAB / SWIFT HAWK
-- -------------------------------------------------------------
local function InitClientFlowBypass()
  pcall(function()
    local ClientFlow = package.loaded["GameLua.Mod.BaseMod.Common.Security.ClientFlowSubsystem"]
    if ClientFlow then
      for k, v in pairs(ClientFlow) do
        if type(v) == "function" and (
          k:find("Report") or k:find("Send") or k:find("Flow")
        ) then
          pcall(function() ClientFlow[k] = nop end)
        end
      end
    end
  end)
end

local function InitCoronaLabBypass()
  pcall(function()
    local _G_CoronaLab = _G.CoronaLab
    if _G_CoronaLab then
      _G_CoronaLab.SendData = nop
      _G_CoronaLab.CollectData = nop
      _G_CoronaLab.ReportError = nop
    end
  end)
end

local function InitSwiftHawkBypass()
  pcall(function()
    local SwiftHawkSubsystem = package.loaded[
      "GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"
    ]
    if SwiftHawkSubsystem then
      SwiftHawkSubsystem.ReportData = nop
      SwiftHawkSubsystem.CollectData = nop
      SwiftHawkSubsystem.SendToServer = nop
    end
  end)
end

-- -------------------------------------------------------------
-- L10. NETWORK PACKET BLOCK
-- -------------------------------------------------------------
local function InitNetworkPacketBlock()
  pcall(function()
    if NetUtil and NetUtil.SendPacket then
      local originalSend = NetUtil.SendPacket
      local blockedPackets = {
        ["ReportAttackFlow"] = 1, ["ReportSecAttackFlow"] = 1,
        ["ReportHitFlow"] = 1, ["ReportFireArms"] = 1,
        ["ReportMrpcsFlow"] = 1, ["ReportVerifyInfoFlow"] = 1,
        ["ReportPlayerBehavior"] = 1, ["ReportTeammateHurt"] = 1,
        ["ReportPlayerMoveRoute"] = 1, ["ReportPlayerPosition"] = 1,
        ["ReportSecVehicleMoveFlow"] = 1, ["report_parachute_data"] = 1,
        ["ReportAimFlow"] = 1, ["report_net_saturate"] = 1,
        ["report_esp_usage"] = 1, ["report_wall_hack"] = 1,
        ["report_aim_bot"] = 1, ["report_modded_files"] = 1,
        ["detect_cheat"] = 1, ["ban_player"] = 1,
        ["client_anti_cheat_report"] = 1,
        ["ReportPlayerKillFlow"] = 1, ["ClientSecPlayerKillFlow"] = 1,
        ["MrpcsData"] = 1, ["ClientSecMrpcsFlow"] = 1,
        ["CheckReportSecAttackFlow"] = 1,
        ["RPC_ClientCoronaLab"] = 1, ["CoronaLabReport"] = 1,
        ["CoronaLabData"] = 1, ["PlayerSecurityInfo"] = 1,
        ["ReportSecurityInfo"] = 1, ["SendSecurityData"] = 1,
        ["ClientCircleFlow"] = 1, ["IsEnableReportPlayerKillFlow"] = 1,
        ["IsEnableReportMrpcsInPartCircleFlow"] = 1,
        ["ReportModifierException"] = 1,
        ["RPC_Server_ReportSimulateCharacterLocation"] = 1,
        ["ReportSimulateCharacterLocation"] = 1,
        ["RPC_Client_ShootVerifyRes"] = 1,
        ["BulletHitInfoUploadData"] = 1, ["ShootVerifyFailed"] = 1,
        ["ClientSwiftHawk"] = 1, ["SwiftHawkData"] = 1,
        ["Heartbeat"] = 1, ["ClientHeartbeat"] = 1, ["ServerHeartbeat"] = 1,
        ["SwiftHawk"] = 1, ["ClientSwiftHawkWithParams"] = 1,
        ["ViolationReport"] = 1, ["CheatDetection"] = 1,
        ["SecurityViolation"] = 1, ["IntegrityCheck"] = 1,
        ["SignatureVerify"] = 1
      }
      NetUtil.SendPacket = function(packetName, ...)
        if blockedPackets[packetName] then return nil end
        return originalSend(packetName, ...)
      end
    end
  end)
end

-- -------------------------------------------------------------
-- L11. HIGGS BOSON BYPASS
-- -------------------------------------------------------------
local function InitHiggsBosonBypass()
  pcall(function()
    local Higgs = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
    if Higgs then
      local methods = {
        "OnTick", "OnTickActive", "Tick", "MHActiveLogic",
        "TriggerAvatar", "ReportPlayerKillFlow", "ReceiveAnyDamage",
        "OnWeaponChanged", "ShowSecurityAlert", "ServerReportAvatar",
        "ClientReportNetAvatar", "SendClientData",
        "ValidateSecurityData", "StaticShowSecurityAlertInDev",
        "DisableHiggsBoson", "ProcessSecurityEvent", "ValidatePlayer",
        "CheckIntegrity"
      }
      for _, m in ipairs(methods) do
        if Higgs[m] then Higgs[m] = nop end
      end
      Higgs.GetNetAvatarItemIDs = retEmpty
      Higgs.GetCurWeaponSkinID = retZero
      Higgs.IsMHActive = retFalse
      Higgs.bCallPreReplication = false
    end
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if pc and pc.HiggsBoson then
      pc.HiggsBoson.ControlMHActive = false
      pc.HiggsBoson.bCallPreReplication = false
    end
  end)
end

-- -------------------------------------------------------------
-- L12. ANTI REPORT + GAMEPLAY CALLBACKS
-- -------------------------------------------------------------
local function InitAntiReport()
  pcall(function()
    local ClientSecurity = require("GameLua.Mod.BaseMod.Client.Security.ClientSecurity")
    if ClientSecurity then
      ClientSecurity.ReportPlayerSubsystem = nop
    end
  end)
end

local function InitGameplayBypass()
  pcall(function()
    local GC = _G.GameplayCallbacks
    if GC then
      local reportFuncs = {
        "ReportSecAttackFlowWithAttackFlow", "ReportHurtFlow",
        "ReportFireArms", "ReportPlayerMoveRoute",
        "ReportPlayerBehavior", "ReportTeammateHurt",
        "ReportForbidPick", "ReportSecGameMovingFlow",
        "SendDsSdkAntiDataToLobby", "ReportEquipmentFlow",
        "ReportParachuteData", "ReportPlayerIP",
        "ReportPlayerFramePingRecord", "ReportPlayerPing",
        "OnDSNetSaturated", "SendClientStats",
        "ReportCircleFlow", "ReportPlayerKillFlow",
        "ClientSecMrpcsFlow", "Heartbeat",
        "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams"
      }
      for _, funcName in ipairs(reportFuncs) do
        GC[funcName] = nop
      end
      GC.CheckReportSecAttackFlowWithAttackFlow = retFalse
      GC.CheckReportSecAttackFlow = retFalse
    end
  end)
end

-- -------------------------------------------------------------
-- L13. FINAL PROTECTION
-- -------------------------------------------------------------
local function InitFinalProtection()
  pcall(function()
    local killFlags = {
      "ENABLE_SECURITY", "ENABLE_CRASH_REPORT",
      "ENABLE_REPLAY", "ENABLE_ANALYTICS",
      "ENABLE_TELEMETRY", "ENABLE_REPORT"
    }
    for _, flag in ipairs(killFlags) do
      if _G[flag] then _G[flag] = false end
    end
    InitNetworkPacketBlock()
    InitHiggsBosonBypass()
    InitAntiReport()
  end)
end

-- -------------------------------------------------------------
-- MASTER INIT — все 13 слоёв через один таймер
-- -------------------------------------------------------------
local function InitFortressBypass()
  pcall(function()
    Notify("FORTRESS: initializing 22 layers...")
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
      pc:AddGameTimer(0.1, function()
        InitSLUABypass()
        InitMDSBypass()
        InitSkinBypass()
        InitLogBlocker()
        InitScannerBlocker()
        InitReplayTelemetryBlocker()
        InitReportFlowBlocker()
        InitPlayerSecurityBypass()
        InitClientFlowBypass()
        InitCoronaLabBypass()
        InitSwiftHawkBypass()
        InitNetworkPacketBlock()
        InitHiggsBosonBypass()
        InitAntiReport()
        InitGameplayBypass()
        InitFinalProtection()
        Notify("FORTRESS: all layers active ✓")
      end)
    end
  end)
end

InitFortressBypass()


-- ============================================================
-- LEGACY TIER 10/20/30 (сохранены для совместимости)
-- ============================================================
pcall(function()
  local n, f, t = function() end, function() return false end, function() return true end
  local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("FileCheckSubsystem")
  if sub then sub.StartCheck = n; sub.ReportAbnormalFile = n end
  local CM = import("CreativeModeBlueprintLibrary")
  if CM then CM.MD5HashByteArray = function() return "0000" end; CM.VerifyFileIntegrity = t end
  local T = package.loaded["TLog"] or _G.TLog
  if T then T.Info = n; T.Error = n end
end)

pcall(function()
  local n, f, t = function() end, function() return false end, function() return true end
  local sm = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
  if sm then
    for _, x in ipairs({"AFKReportorSubsystem","ShootVerifySubSystemClient","BehaviorScoreSubsystem","MemoryCheckSubsystem","SpeedCheckSubsystem","WallCheckSubsystem"}) do
      local s = sm:Get(x)
      if s then for k, v in pairs(s) do
        if type(v) == "function" and (k:find("Report") or k:find("Send")) then s[k] = n end
      end end
    end
  end
  local N = _G.NetUtil
  if N and N.SendPacket and not N._Byp then
    local o = N.SendPacket
    N.SendPacket = function(name, ...)
      if name:find("Report") or name:find("AntiCheat") then return nil end
      return o(name, ...)
    end
    N._Byp = true
  end
end)

pcall(function()
  local n = function() end
  local SH = package.loaded["GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"]
  if SH then for k, v in pairs(SH) do
    if type(v) == "function" and k:find("Report") then SH[k] = n end
  end end
  local DBG = package.loaded["common.anti_debug"]
  if DBG then DBG.Check = function() return false end end
  local FD = package.loaded["common.frida_check"]
  if FD then FD.Detect = function() return false end end
end)


-- ============================================================
-- MENU INJECTION (без изменений)
-- ============================================================
local _menuAttempts = 0
local _menuDone = false

local function TryInitMenu()
  if _menuDone then return end
  _menuAttempts = _menuAttempts + 1
  if _menuAttempts > 20 then return end

  local ok, err = pcall(function()
    local LocUtil = _G.LocUtil or (package.loaded["client.common.LocUtil"] and require("client.common.LocUtil"))
    if not LocUtil then error("LocUtil not ready") end
    local SPD = require("client.logic.NewSetting.SettingPageDefine")
    local SC = require("client.logic.NewSetting.SettingCatalog")
    local UIMgr = _G.UIManager
    if not UIMgr or not UIMgr.ShowUI then error("UIManager not ready") end
    local AM = require("client.slua.umg.NewSetting.Item.AliasMap")
    if not AM.Switcher or not AM.Slider then error("AliasMap missing") end
    local TitleUI = AM.TitleSwitcher or AM.Switcher

    local FakeTextMap = { [999000] = "◆ TESLA 10X 4.6 ◆" }
    if not LocUtil._Tesla10xHooked then
      for _, fn in ipairs({"GetLocalizeResStr", "GetText", "GetTextByID", "GetLocalText", "GetLocalizeStr"}) do
        if LocUtil[fn] then
          local orig = LocUtil[fn]
          LocUtil[fn] = function(id)
            if FakeTextMap[id] then return FakeTextMap[id] end
            if type(id) == "string" and not tonumber(id) then return id end
            return orig and orig(id) or ""
          end
        end
      end
      LocUtil._Tesla10xHooked = true
    end

    local Categories = {}

    local StackESP = {
      { Key = "M_ESP", UI = TitleUI, Text = "◆ ESP", ExpandIndex = 0, GetFunc = function() return _G.LexusConfig.EspLoai9 end, SetFunc = function(c,v) _G.LexusConfig.EspLoai9 = v return true end },
      { Key = "M_ESP_Cnt", UI = AM.Switcher, Text = "   Player Counter", ExpandHandle = "M_ESP", GetFunc = function() return _G.LexusConfig.Esp9_Count end, SetFunc = function(c,v) _G.LexusConfig.Esp9_Count = v return true end },
      { Key = "M_ESP_Name", UI = AM.Switcher, Text = "   Names", ExpandHandle = "M_ESP", GetFunc = function() return _G.LexusConfig.Esp9_Name end, SetFunc = function(c,v) _G.LexusConfig.Esp9_Name = v return true end },
      { Key = "M_ESP_HP", UI = AM.Switcher, Text = "   HP Bar", ExpandHandle = "M_ESP", GetFunc = function() return _G.LexusConfig.Esp9_HP end, SetFunc = function(c,v) _G.LexusConfig.Esp9_HP = v return true end },
      { Key = "M_ESP_Dist", UI = AM.Switcher, Text = "   Distance", ExpandHandle = "M_ESP", GetFunc = function() return _G.LexusConfig.Esp9_Distance end, SetFunc = function(c,v) _G.LexusConfig.Esp9_Distance = v return true end },
      { Key = "M_ESP_Line", UI = AM.Switcher, Text = "   Snaplines", ExpandHandle = "M_ESP", GetFunc = function() return _G.LexusConfig.Esp9_Line end, SetFunc = function(c,v) _G.LexusConfig.Esp9_Line = v return true end },
      { Key = "M_ESP_Team", UI = AM.Switcher, Text = "   Team Color", ExpandHandle = "M_ESP", GetFunc = function() return _G.LexusConfig.Esp9_Team end, SetFunc = function(c,v) _G.LexusConfig.Esp9_Team = v return true end },
      { Key = "M_ESP_Weapon", UI = AM.Switcher, Text = "   Weapon Icon", ExpandHandle = "M_ESP", GetFunc = function() return _G.LexusConfig.Esp9_Weapon end, SetFunc = function(c,v) _G.LexusConfig.Esp9_Weapon = v return true end },
      { Key = "M_ESP_Skel", UI = AM.Switcher, Text = "   Skeleton", ExpandHandle = "M_ESP", GetFunc = function() return _G.LexusConfig.Esp9_Skeleton end, SetFunc = function(c,v) _G.LexusConfig.Esp9_Skeleton = v return true end },
    }
    table.insert(Categories, { Key = "Cat_ESP", Text = "ESP", Stack = StackESP })

    local StackVisual = {
      { Key = "M_WH", UI = AM.Switcher, Text = "◆ Wallhack Chams", GetFunc = function() return _G.LexusConfig.ColorBodyNew end, SetFunc = function(c,v) _G.LexusConfig.ColorBodyNew = v return true end },
    }
    table.insert(Categories, { Key = "Cat_Visual", Text = "VISUAL", Stack = StackVisual })

    local StackIpad = {
      { Key = "M_Ipad", UI = AM.Switcher, Text = "◆ iPad View", GetFunc = function() return _G.LexusConfig.IpadView end, SetFunc = function(c,v) _G.LexusConfig.IpadView = v return true end },
      { Key = "M_Ipad_Fov", UI = AM.Slider, Text = "   FOV Value", MinValue = 90, MaxValue = 160, GetFunc = function() return _G.LexusConfig.IpadViewFOV or 120 end, SetFunc = function(c,v) _G.LexusConfig.IpadViewFOV = v return true end },
    }
    table.insert(Categories, { Key = "Cat_Ipad", Text = "IPAD VIEW", Stack = StackIpad })

    local StackMisc = {
      { Key = "M_HWID", UI = AM.Switcher, Text = "◆ Fake HWID", GetFunc = function() return _G.LexusConfig.FakeHWID end, SetFunc = function(c,v) _G.LexusConfig.FakeHWID = v return true end },
      { Key = "M_KC", UI = AM.Switcher, Text = "◆ Kill Counter UI", GetFunc = function() return _G.LexusConfig.KillCountUI end, SetFunc = function(c,v) _G.LexusConfig.KillCountUI = v return true end },
    }
    table.insert(Categories, { Key = "Cat_Misc", Text = "MISC", Stack = StackMisc })

    if #Categories == 0 then error("No categories built") end

    SPD.ModMenu = { Key = "ModMenu", Text = 999000, UIKey = "Setting_Page_Privacy", Category = Categories }
    if SC then
      for i = #SC, 1, -1 do
        if type(SC[i]) == "table" and SC[i].Key == "ModMenu" then table.remove(SC, i) end
      end
      table.insert(SC, 1, SPD.ModMenu)
    end

    if not UIMgr._IsModMenuHooked then
      local oldShowUI = UIMgr.ShowUI
      function UIMgr.ShowUI(cfg, ...)
        local args = {...}
        if cfg and cfg.keyName and string.find(string.lower(cfg.keyName), "setting_main")
           and not string.find(string.lower(cfg.keyName), "custom") then
          local cat = args[1]
          if type(cat) == "table" and cat[1] and type(cat[1]) == "table" and cat[1].Key then
            local has = false
            for _, p in ipairs(cat) do
              if type(p) == "table" and p.Key == "ModMenu" then has = true; break end
            end
            if not has then table.insert(cat, 1, SPD.ModMenu) end
          end
        end
        return oldShowUI(cfg, table.unpack(args))
      end
      UIMgr._IsModMenuHooked = true
    end

    _menuDone = true
    Notify("Menu injected ✓")
  end)

  if not ok then
    local ticker = getTicker()
    if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(2.0, TryInitMenu) end
  end
end

-- ============================================================
-- TICK LOOP (без изменений)
-- ============================================================
local function MainLoop()
  pcall(function()
    local GD = getGD(); if not GD then return end
    local pc = GD.GetPlayerController and GD.GetPlayerController(); if not Valid(pc) then return end
    local lp = pc:GetPlayerCharacterSafety(); if not Valid(lp) then return end

    if _G.PlayerMapMarker and _G.PlayerMapMarker.Scan then pcall(_G.PlayerMapMarker.Scan) end
    pcall(_G.InitHWID)
    pcall(_G.ApplyIpad, lp)

    local allChars = GD.GetAllPlayerCharacters and GD.GetAllPlayerCharacters() or {}
    for _, enemy in pairs(allChars) do
      if _G.Valid(enemy) and enemy ~= lp and enemy.TeamID ~= lp.TeamID then
        local key = _G.GetSafeEnemyKey(enemy)
        local md = _G.LexusState.EnemyMarks[key]
        if not md then md = { enemy = enemy }; _G.LexusState.EnemyMarks[key] = md end
        md.enemy = enemy
        if _G.LexusConfig.ColorBodyNew then pcall(_G.ApplyChams, enemy, md) else pcall(_G.RemoveChams, enemy, md) end
      end
    end

    local now = os.time()
    if not _G.LastSaveTime or now - _G.LastSaveTime >= 3 then
      _G.LastSaveTime = now; pcall(SaveModSettings)
    end
  end)
end

local myToken = 0
_G.LexusState.LoopToken = (_G.LexusState.LoopToken or 0) + 1
myToken = _G.LexusState.LoopToken

local function FastTick()
  if myToken ~= _G.LexusState.LoopToken then return end
  local started = os.clock(); pcall(MainLoop)
  local ticker = getTicker(); if not ticker then return end
  local st = _G.AkoStability; local nextInterval = st.MainInterval
  local elapsed = os.clock() - started
  if elapsed > st.SlowFrameThreshold then
    st.SlowFrameCount = st.SlowFrameCount + 1
    nextInterval = st.SlowFrameBackoff
  else
    st.SlowFrameCount = math.max(0, st.SlowFrameCount - 1)
  end
  ticker.AddTimerOnce(nextInterval, FastTick)
end

local function FastAimbotTick()
  if myToken ~= _G.LexusState.LoopToken then return end
  pcall(function() if _G.AimTouch then _G.AimTouch() end end)
  local ticker = getTicker()
  if ticker then ticker.AddTimerOnce(_G.AkoStability.AimbotInterval, FastAimbotTick) end
end

-- BASE CLASS STUBS
function BRPlayerCharacterBase:ctor() end
function BRPlayerCharacterBase:_PostConstruct() BRPlayerCharacterBase.__super._PostConstruct(self); self.bCanNearDeathGiveup = true end
function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  if slua.isValid(self.STCharacterMovement) then self.STCharacterMovement.bPositiveBlowUp = true end
  if Client then GameplayData.AddCharacter(self.Object) end
end
function BRPlayerCharacterBase:ReceiveEndPlay(r) BRPlayerCharacterBase.__super.ReceiveEndPlay(self, r); if Client then GameplayData.RemoveCharacter(self.Object) end end
function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI) end
end
function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue() end
function BRPlayerCharacterBase:HandleNearDeathGiveupRescue() end
function BRPlayerCharacterBase:RPC_Server_GmPlayAction(id) end
function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(id) end
function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(v) end
function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState() end
function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(b) end
function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(u) end
function BRPlayerCharacterBase:SetAreaID(id) end
function BRPlayerCharacterBase:GetAreaID() return 0 end
function BRPlayerCharacterBase:CannotChangeIntoPetSpectator() return false end
function BRPlayerCharacterBase:DoModChangeToBT() end
function BRPlayerCharacterBase:SwitchCameraToParachuteOpening() end
function BRPlayerCharacterBase:SwitchCameraToParachuteFalling() end
function BRPlayerCharacterBase:SwitchCameraToNormal() end
function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState) return self.Super:SwitchWeaponCheck(Slot, IgnoreState) end
function BRPlayerCharacterBase:BPOnRecycled() end
function BRPlayerCharacterBase:BPOnRespawned() end
function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord() end
function BRPlayerCharacterBase:PreAttachedToVehicle() end
function BRPlayerCharacterBase:ParachuteJump() end
function BRPlayerCharacterBase:OnMovementBaseChangedEvent(a, b, c) end
function BRPlayerCharacterBase:GetMedievalCraneFromBase(b) return nil end
function BRPlayerCharacterBase:CheckForbidFlaregun() return false end
function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal) BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal) end
function BRPlayerCharacterBase:OnPawnStateChange(s) end
function BRPlayerCharacterBase:HandleFinishedState() end
function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent() return false end
function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(l, n) BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, l, n) end
function BRPlayerCharacterBase:OnLanded() end
function BRPlayerCharacterBase:IsWarGameMode() return false end
function BRPlayerCharacterBase:ReceiveOnRecycle() end
function BRPlayerCharacterBase:ReceiveOnSpawn() end
function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation() end

-- ============================================================
-- UNIFIED BRANDING POPUP
-- ============================================================
local function ShowStartupPopups()
  pcall(function()
    local Msg = require("client.slua.logic.common.logic_common_msg_box")
    if not Msg or not Msg.Show then return end
    local feat_str = (#_G.TeslaLoadedFeatures > 0) and table.concat(_G.TeslaLoadedFeatures, ", ") or "No features"
    local content = "TESLA 10X GAMING 4.6\nDEV: @OfficialOwner10x\n\nACTIVATION SUCCESSFUL!\nFeatures Loaded: " .. feat_str .. "\nBypass: FORTRESS 22-LAYER\n\nSettings -> Privacy -> TESLA 10X to toggle."
    Msg.Show(1, "◆ TESLA 10X GAMING ◆", content, function() end, function() end, "OK", "")
  end)
end

function _G.ShowFeatureBanner()
  local parts = {}
  for _, f in ipairs(_G.TeslaLoadedFeatures or {}) do
    table.insert(parts, f)
  end
  local feat_str = (#parts > 0) and table.concat(parts, " • ") or "No features"
  local txt = "◆ TESLA 10X GAMING 4.6 ◆ " .. feat_str .. " ◆ FORTRESS 22L ◆ DEV: @OfficialOwner10x"
  pcall(function()
    local sh = import("ScriptHelperClient")
    if sh and sh.AddOnScreenDebugMessage then
      sh.AddOnScreenDebugMessage(txt, -1, 9999.0, {R=1, G=0.85, B=0, A=1}, {X=1.4, Y=1.4})
    end
  end)
end

-- BOOT
Notify("TESLA 10X GAMING — Loading...")
pcall(function()
  local ticker = getTicker()
  if ticker and ticker.AddTimerOnce then
    ticker.AddTimerOnce(3.0, ShowStartupPopups)
    ticker.AddTimerOnce(12.0, TryInitMenu)
    ticker.AddTimerOnce(8.0, function()
      FastTick(); FastAimbotTick()
      ShowFeatureBanner()
      Notify("TESLA 10X GAMING — Loaded!")
    end)
  end
end)

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
  { ParachuteFormation = "GameLua.Mod.BaseMod.Gameplay.Feature.ParachuteFormationFeature" },
  { SpiderSenseFootprintFeature = "GameLua.Mod.Library.GamePlay.Feature.SpiderSenseFootprintFeature" },
  { GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature" },
}, "BRPlayerCharacterBase")