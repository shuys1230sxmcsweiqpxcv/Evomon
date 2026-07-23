
local G = (type(getgenv) == "function" and getgenv()) or _G

if G.MM2Hop and type(G.MM2Hop) == "table" and type(G.MM2Hop.Destroy) == "function" then
    pcall(function()
        G.MM2Hop:Destroy("reload")
    end)
    G.MM2Hop = nil
end

--══════════════════════════════════ CONFIG ═════════════════════════════════

local DEFAULT_CONFIG = {
    CheckIntervalSec = 120,
    LowPlayerMax = 2, 
    BagFailHopThreshold = 5,
    ServerHopUrl = "https://raw.githubusercontent.com/shuys1230sxmcsweiqpxcv/Evomon/refs/heads/main/serverhop.lua",
}

local Config = {}
do
    local userCfg = type(G.MM2HopConfig) == "table" and G.MM2HopConfig or {}
    for k, v in DEFAULT_CONFIG do
        Config[k] = userCfg[k] ~= nil and userCfg[k] or v
    end
end

--══════════════════════════════════ SERVICES ════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TAG = "[MM2Hop]"

local function log(msg)
    print(TAG .. " " .. tostring(msg))
end

local function safe(fn, ...)
    return pcall(fn, ...)
end

--══════════════════════════════════ STATE ════════════════════════════════════

local HopState = {
    hopping = false,
}

local BagState = {
    roundActive = false,
    bagCurrent = 0,
    bagMax = 0,
    bagWasFull = false,
    consecutiveFails = 0,
}

local connections = {}
local threads = {}
local destroyed = false

local function trackConn(name, conn)
    if conn then
        connections[name] = conn
    end
    return conn
end

local function trackThread(name, thread)
    if thread then
        threads[name] = thread
    end
    return thread
end

--══════════════════════════════════ HOP ════════════════════════════════════

local function runServerHop(reason)
    if destroyed or HopState.hopping then
        return
    end

    local url = Config.ServerHopUrl
    if type(url) ~= "string" or url == "" then
        log("ServerHopUrl trống — bỏ qua hop")
        return
    end

    HopState.hopping = true
    log(string.format("Đang hop server (%s)...", tostring(reason)))

    local ok, err = safe(function()
        loadstring(game:HttpGet(url))()
    end)

    if not ok then
        log("Hop thất bại / Hop failed: " .. tostring(err))
        HopState.hopping = false
    end
end

--══════════════════════════════════ BAG TRACKING ════════════════════════════

local function resetRoundBag()
    BagState.roundActive = false
    BagState.bagCurrent = 0
    BagState.bagMax = 0
    BagState.bagWasFull = false
end

local function onBagFull()
    BagState.bagWasFull = true
    if BagState.consecutiveFails > 0 then
        log(string.format("Bag đầy (%d/%d) — reset fail counter", BagState.bagCurrent, BagState.bagMax))
    end
    BagState.consecutiveFails = 0
end

local function onBagNotFull(reason)
    BagState.consecutiveFails += 1
    local threshold = tonumber(Config.BagFailHopThreshold) or 6
    log(string.format(
        "Bag chưa đầy / bag not full (%s) — %d/%d | collected=%d max=%d",
        tostring(reason),
        BagState.consecutiveFails,
        threshold,
        BagState.bagCurrent,
        BagState.bagMax
    ))

    if BagState.consecutiveFails >= threshold then
        runServerHop(string.format("bag fail x%d", BagState.consecutiveFails))
    end
end

local function evaluateRoundBag(why)
    if not BagState.roundActive then
        return
    end

    local current = BagState.bagCurrent
    local max = BagState.bagMax

    if BagState.bagWasFull or (max > 0 and current >= max) then
        onBagFull()
    else
        onBagNotFull(why)
    end

    resetRoundBag()
end

local function onCoinsStarted()
    BagState.roundActive = true
    BagState.bagCurrent = 0
    BagState.bagMax = 0
    BagState.bagWasFull = false
    log("CoinsStarted — theo dõi bag round mới")
end

local function onCoinCollected(_coinType, current, max)
    current, max = tonumber(current), tonumber(max)
    if current then
        BagState.bagCurrent = current
    end
    if max and max > 0 then
        BagState.bagMax = max
    end

    if current and max and max > 0 and current >= max then
        onBagFull()
    end
end

local function onRoundEnded(why)
    evaluateRoundBag("round end / " .. tostring(why))
end

--══════════════════════════════════ LOW PLAYER ═════════════════════════════

local function checkLowPlayers()
    if destroyed or HopState.hopping then
        return
    end

    local playerCount = #Players:GetPlayers()
    local maxPlayers = tonumber(Config.LowPlayerMax) or 2

    if playerCount <= maxPlayers then
        log(string.format("Ít người chơi / low players (%d <= %d) — hop", playerCount, maxPlayers))
        runServerHop(string.format("low players (%d)", playerCount))
    else
        log(string.format(
            "Kiểm tra player: %d người (>%d — OK, không hop; chỉ hop khi <= %d)",
            playerCount, maxPlayers, maxPlayers
        ))
    end
end

local function startPlayerMonitor()
    local interval = math.max(tonumber(Config.CheckIntervalSec) or 180, 10)
    trackThread("playerMonitor", task.spawn(function()
        task.wait(3) -- chờ game load
        while not destroyed do
            safe(checkLowPlayers)
            task.wait(interval)
        end
    end))
end

--══════════════════════════════════ REMOTES ═════════════════════════════════

local Remotes = {}

local function resolveRemotes()
    if Remotes.CoinsStarted then
        return true
    end

    local ok = safe(function()
        local root = ReplicatedStorage:WaitForChild("Remotes", 30)
        local gp = root:WaitForChild("Gameplay", 30)
        Remotes.Gameplay = gp
        Remotes.CoinsStarted = gp:WaitForChild("CoinsStarted", 10)
        Remotes.CoinCollected = gp:WaitForChild("CoinCollected", 10)
        Remotes.VictoryScreen = gp:WaitForChild("VictoryScreen", 10)
        Remotes.RoundEndFade = gp:WaitForChild("RoundEndFade", 10)
    end)

    return ok and Remotes.CoinsStarted ~= nil
end

local function connectRemotes()
    if destroyed then
        return false
    end

    if not resolveRemotes() then
        log("Không tìm thấy remotes — thử lại sau 5s / remotes missing, retrying")
        trackThread("remoteRetry", task.delay(5, function()
            if not destroyed then
                connectRemotes()
            end
        end))
        return false
    end

    trackConn("CoinsStarted", Remotes.CoinsStarted.OnClientEvent:Connect(function()
        safe(onCoinsStarted)
    end))

    trackConn("CoinCollected", Remotes.CoinCollected.OnClientEvent:Connect(function(coinType, current, max)
        safe(onCoinCollected, coinType, current, max)
    end))

    trackConn("VictoryScreen", Remotes.VictoryScreen.OnClientEvent:Connect(function()
        safe(onRoundEnded, "VictoryScreen")
    end))

    trackConn("RoundEndFade", Remotes.RoundEndFade.OnClientEvent:Connect(function()
        safe(onRoundEnded, "RoundEndFade")
    end))

    log("Đã kết nối remotes / remotes connected")
    return true
end

--══════════════════════════════════ PUBLIC API ══════════════════════════════

local MM2Hop = {}

function MM2Hop.Destroy(why)
    if destroyed then
        return
    end
    destroyed = true

    for name, conn in connections do
        safe(function()
            conn:Disconnect()
        end)
        connections[name] = nil
    end

    log("Đã dừng / stopped" .. (why and (" (" .. tostring(why) .. ")") or ""))
end

function MM2Hop.GetState()
    return {
        hopping = HopState.hopping,
        bagFails = BagState.consecutiveFails,
        roundActive = BagState.roundActive,
        bagCurrent = BagState.bagCurrent,
        bagMax = BagState.bagMax,
        bagWasFull = BagState.bagWasFull,
    }
end

G.MM2Hop = MM2Hop

--══════════════════════════════════ BOOT ════════════════════════════════════

log(string.format(
    "Khởi động — check=%ds, hop khi <= %d player, bagFail=%d (server đông hơn %d thì KHÔNG hop)",
    tonumber(Config.CheckIntervalSec) or 180,
    tonumber(Config.LowPlayerMax) or 2,
    tonumber(Config.BagFailHopThreshold) or 6,
    tonumber(Config.LowPlayerMax) or 2
))

connectRemotes()
startPlayerMonitor()
