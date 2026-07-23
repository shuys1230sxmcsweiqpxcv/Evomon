loadstring([[function LPH_NO_VIRTUALIZE(f) return f end;]])();

local function readNiAutoConfig()
  local g = getgenv()
  if g and typeof(g.NiAutoConfig) == "table" then return g.NiAutoConfig end
  if typeof(shared) == "table" and typeof(shared.NiAutoConfig) == "table" then return shared.NiAutoConfig end
  if typeof(_G.NiAutoConfig) == "table" then return _G.NiAutoConfig end
  return {}
end

getgenv().Config = getgenv().Config or {}
local NiAutoConfig = readNiAutoConfig()
local Config = getgenv().Config

for k, v in NiAutoConfig do
  if Config[k] == nil then
    Config[k] = v
  end
end

Config.ITEMS_RARITY_TO_NOTIFY = Config.ITEMS_RARITY_TO_NOTIFY or { "Godly" }
Config.NotifyIntervalSeconds = Config.NotifyIntervalSeconds or 60
Config.NotifyResendSeconds = Config.NotifyResendSeconds or 120
Config.LogLevel = Config.LogLevel or "INFO"
Config.DebugInventory = Config.DebugInventory or false
Config.ProfileReadyTimeoutSeconds = Config.ProfileReadyTimeoutSeconds or 90

local USER_ID = Config.UserId

-- Default production API when ApiUrl is omitted (only UserId required in launcher)
local DEFAULT_API_URL = "https://niauto.org"
local API_URL = (Config.ApiUrl or ""):gsub("/$", "")
if API_URL == "" or string.find(API_URL, "localhost", 1, true) or string.find(API_URL, "127.0.0.1", 1, true) then
  API_URL = DEFAULT_API_URL:gsub("/$", "")
end

if not USER_ID then
  warn("[NiAutoMM2Notify] Missing UserId — set getgenv().NiAutoConfig.UserId before load")
  return
end

if getgenv().NiAutoMM2TradeNotifyRunning then
  warn("[NiAutoMM2Notify] Already running — skip duplicate load")
  return
end
getgenv().NiAutoMM2TradeNotifyRunning = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Modules = ReplicatedStorage:WaitForChild("Modules", 30)
local Sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
local ProfileData = require(Modules:WaitForChild("ProfileData"))
local InventoryModule = require(Modules:WaitForChild("InventoryModule"))

local LOG_RANK = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
local function log(level, msg)
  local want = LOG_RANK[string.upper(Config.LogLevel)] or 2
  local got = LOG_RANK[string.upper(level)] or 2
  if got >= want then
    print("[NiAutoMM2Notify][" .. level .. "] " .. msg)
  end
end

local function buildHeaders()
  return {
    ["Content-Type"] = "application/json",
    ["X-NiAuto-User-Id"] = USER_ID,
    ["User-Agent"] = "NiAutoMM2Notify/1.0",
    ["ngrok-skip-browser-warning"] = "true",
  }
end

local function httpRequest(opts)
  if typeof(syn) == "table" and syn.request then return syn.request(opts) end
  if typeof(http) == "table" and http.request then return http.request(opts) end
  if typeof(request) == "function" then return request(opts) end
  if HttpService.RequestAsync then
    return HttpService:RequestAsync({
      Url = opts.Url,
      Method = opts.Method or "GET",
      Headers = opts.Headers or {},
      Body = opts.Body,
    })
  end
  error("[NiAutoMM2Notify] No HTTP support in executor")
end

local NOTIFY_HTTP_BACKOFFS = { 5, 15, 30 }

local function apiRequestOnce(method, path, body)
  if string.find(API_URL, "localhost", 1, true) or string.find(API_URL, "127.0.0.1", 1, true) then
    return false, "ApiUrl cannot be localhost — use https://niauto.org or your VPS URL"
  end

  local url = API_URL .. path
  local payload = body and HttpService:JSONEncode(body) or nil
  local okReq, res = pcall(httpRequest, {
    Url = url,
    Method = method,
    Headers = buildHeaders(),
    Body = payload,
  })
  if not okReq then
    return false, "HTTP failed: " .. tostring(res)
  end
  local status = res.StatusCode or res.status or 0
  local raw = res.Body or res.body or ""
  if status == 0 or raw == "" then
    return false, "Empty response (status " .. tostring(status) .. ")"
  end
  local okJson, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
  if not okJson then
    return false, "Invalid JSON (" .. tostring(status) .. "): " .. string.sub(raw, 1, 120)
  end
  if status >= 400 or decoded.ok == false then
    return false, decoded.error or ("HTTP " .. tostring(status))
  end
  return true, decoded.data
end

local function isStatusZeroError(err)
  return typeof(err) == "string" and string.find(err, "status 0", 1, true) ~= nil
end

local function apiRequest(method, path, body)
  local lastErr
  local maxAttempts = 1 + #NOTIFY_HTTP_BACKOFFS

  for attempt = 1, maxAttempts do
    local ok, data = apiRequestOnce(method, path, body)
    if ok then
      return true, data
    end

    lastErr = data
    if not isStatusZeroError(data) or attempt >= maxAttempts then
      break
    end

    local waitSec = NOTIFY_HTTP_BACKOFFS[attempt]
    log(
      "WARN",
      "HTTP status 0 — retry in "
        .. tostring(waitSec)
        .. "s (attempt "
        .. tostring(attempt)
        .. "/"
        .. tostring(#NOTIFY_HTTP_BACKOFFS)
        .. ") ApiUrl="
        .. API_URL
    )
    task.wait(waitSec)
  end

  if typeof(lastErr) == "string" and not string.find(lastErr, "ApiUrl=", 1, true) then
    lastErr = lastErr .. " ApiUrl=" .. API_URL
  end
  return false, lastErr
end

local function buildRaritySet(list)
  local set = {}
  for _, name in list do
    if typeof(name) == "string" and name ~= "" then
      set[name] = true
    end
  end
  return set
end

local NOTIFY_RARITIES = buildRaritySet(Config.ITEMS_RARITY_TO_NOTIFY)

local SKIP_DEFAULT = "default_starter"

local function countEquippedCopies(itemType, itemId)
  local copies = 0
  if itemType == "Weapons" and typeof(ProfileData.Weapons) == "table" then
    local eq = ProfileData.Weapons.Equipped
    if typeof(eq) == "table" then
      for _, equippedId in eq do
        if equippedId == itemId then
          copies += 1
        end
      end
    end
  elseif itemType == "Pets" and typeof(ProfileData.Pets) == "table" then
    local eq = ProfileData.Pets.Equipped
    if typeof(eq) == "table" then
      for _, equippedId in eq do
        if equippedId == itemId then
          copies += 1
        end
      end
    end
  end
  return copies
end

local function analyzeInventoryEntry(itemType, itemId, meta)
  local rarity = meta.Rarity or "Common"
  local amount = tonumber(meta.Amount) or 1
  local equippedCopies = countEquippedCopies(itemType, itemId)
  local reserved = math.min(equippedCopies, amount)

  return {
    id = itemId,
    type = itemType,
    name = meta.Name or itemId,
    rarity = rarity,
    amount = amount,
    tradeableAmount = math.max(amount - reserved, 0),
    equipped = equippedCopies > 0,
    equippedCopies = equippedCopies,
    dataType = meta.DataType or itemType,
    skipReason = (itemId == "DefaultKnife" or itemId == "DefaultGun") and SKIP_DEFAULT or nil,
  }
end

local function waitForCharacterReady()
  local char = LocalPlayer.Character
  if not char then
    char = LocalPlayer.CharacterAdded:Wait()
  end
  char:WaitForChild("HumanoidRootPart", 30)
  return char ~= nil
end

local function waitForProfileReady()
  local timeout = tonumber(Config.ProfileReadyTimeoutSeconds) or 90
  local deadline = os.clock() + timeout
  while os.clock() < deadline do
    if typeof(ProfileData) == "table"
      and typeof(ProfileData.Weapons) == "table"
      and typeof(ProfileData.Weapons.Owned) == "table" then
      return true
    end
    task.wait(0.25)
  end
  log("WARN", "ProfileData not ready after " .. tostring(timeout) .. "s — Weapons.Owned missing")
  return false
end

local function iterTradeInventoryEntries(onEntry)
  local inv = InventoryModule.GenerateInventoryTables(ProfileData, "Trading")
  if not inv or typeof(inv.Data) ~= "table" then
    return inv, 0
  end

  local seen = 0
  for itemType, tabs in inv.Data do
    if itemType == "Weapons" or itemType == "Pets" then
      if typeof(tabs) == "table" then
        for tabName, bucket in tabs do
          if typeof(bucket) == "table" then
            for itemId, meta in bucket do
              if typeof(meta) == "table" then
                seen += 1
                onEntry(itemType, tabName, itemId, meta)
              end
            end
          end
        end
      end
    end
  end

  return inv, seen
end

local function buildInventoryAnalysis()
  local entries = {}
  iterTradeInventoryEntries(function(itemType, _tabName, itemId, meta)
    table.insert(entries, analyzeInventoryEntry(itemType, itemId, meta))
  end)
  return entries
end

local function debugLogInventory()
  if not Config.DebugInventory then return end

  local inv, seen = iterTradeInventoryEntries(function(itemType, tabName, itemId, meta)
    local entry = analyzeInventoryEntry(itemType, itemId, meta)
    log(
      "DEBUG",
      string.format(
        "  %s/%s x%d tradeable=%d rarity=%s tab=%s equipped=%s",
        itemType,
        tostring(entry.name),
        entry.amount,
        entry.tradeableAmount,
        entry.rarity,
        tostring(tabName),
        entry.equipped and "yes" or "no"
      )
    )
  end)

  if not inv then
    log("DEBUG", "GenerateInventoryTables returned nil/invalid")
  elseif seen == 0 then
    log("DEBUG", "GenerateInventoryTables saw 0 entries")
  else
    log("DEBUG", "Inventory snapshot — " .. tostring(seen) .. " entry(ies)")
  end
end

local function collectNotifyItems()
  local items = {}

  for _, entry in buildInventoryAnalysis() do
    if NOTIFY_RARITIES[entry.rarity] and entry.amount > 0 and entry.skipReason ~= SKIP_DEFAULT then
      table.insert(items, {
        itemId = entry.id,
        itemType = entry.type,
        displayName = entry.name,
        rarity = entry.rarity,
        amount = entry.amount,
        tradeableAmount = entry.tradeableAmount,
        equipped = entry.equipped,
        dataType = entry.dataType,
      })
    end
  end

  return items
end

local function payloadHash(items)
  local parts = {}
  for _, item in items do
    table.insert(parts, table.concat({
      tostring(item.itemType),
      tostring(item.itemId),
      tostring(item.amount),
      tostring(item.tradeableAmount or item.amount),
      tostring(item.equipped == true),
      tostring(item.rarity),
    }, "|"))
  end
  table.sort(parts)
  return table.concat(parts, ";")
end

local lastHash = nil
local lastSentAt = 0

local function sendNotifyIfChanged()
  local items = collectNotifyItems()
  local hash = payloadHash(items)
  local now = os.time()
  local resendSec = math.max(tonumber(Config.NotifyResendSeconds) or 120, 30)

  local hashChanged = (hash ~= lastHash)
  local hasItems = #items > 0
  local periodicDue = hasItems
    and not hashChanged
    and lastSentAt > 0
    and (now - lastSentAt) >= resendSec

  if not hashChanged and not periodicDue then
    log("DEBUG", "Inventory unchanged — skip notify")
    return
  end

  if not hasItems then
    if hashChanged then
      lastHash = hash
    end
    log("DEBUG", "No notify-rarity items in inventory")
    return
  end

  local reason = hashChanged and "Inventory changed" or "Periodic resend"
  log("INFO", reason .. " — posting " .. tostring(#items) .. " notify-rarity item(s)")

  local payload = {
    userId = USER_ID,
    robloxUserId = LocalPlayer.UserId,
    robloxUsername = LocalPlayer.Name,
    game = "MM2",
    kind = "inventory_rarity",
    rarities = Config.ITEMS_RARITY_TO_NOTIFY,
    items = items,
    total = #items,
    inventoryHash = hash,
    fetchedAt = now,
  }

  local ok, data = apiRequest("POST", "/api/mm2/notify", payload)
  if ok then
    lastHash = hash
    lastSentAt = now
    log("INFO", "NiAuto notify: POST ok — taskId=" .. tostring(data and data.taskId))
  else
    log("WARN", reason .. " — notify failed: " .. tostring(data))
  end
end

task.spawn(LPH_NO_VIRTUALIZE(function()
  log("INFO", "MM2 notify worker started — ApiUrl=" .. API_URL .. " rarities: " .. HttpService:JSONEncode(Config.ITEMS_RARITY_TO_NOTIFY))
  if not waitForCharacterReady() then
    log("WARN", "Character/HRP not ready — continuing anyway")
  end
  if not waitForProfileReady() then
    log("ERROR", "Cannot notify — profile inventory never loaded")
    getgenv().NiAutoMM2TradeNotifyRunning = false
    return
  end
  task.wait(5)
  while getgenv().NiAutoMM2TradeNotifyRunning do
    if Config.DebugInventory then
      debugLogInventory()
    end
    pcall(sendNotifyIfChanged)
    task.wait(math.max(tonumber(Config.NotifyIntervalSeconds) or 60, 15))
  end
end))
