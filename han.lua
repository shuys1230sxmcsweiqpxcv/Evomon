
local G = (type(getgenv) == "function" and getgenv()) or _G

    if G.MM2KaitunV2 and type(G.MM2KaitunV2) == "table" and type(G.MM2KaitunV2.Destroy) == "function" then
        pcall(function()
            G.MM2KaitunV2:Destroy("reload")
        end)
        G.MM2KaitunV2 = nil
    end
    
    --══════════════════════════════════ CONFIG ═════════════════════════════════
    
    local DEFAULT_CONFIG = {
        ----------------------------------------------------------------- farm --
        Enabled = true,
        AutoStart = true,           
        CoinType = "Any",         
        TweenSpeed = 26,           
        TweenSpeedMax = 60,         
        TweenMinTime = 0.1,
        TweenMaxTime = 6,
        CoinBelowOffset = 2.5,     
        CollectTouchDelay = 0.05,
        CollectSettleDelay = 0.08,  
        CoinCycleDelay = 0.02,
        ResetWhenFull = true,      
        TouchInterestWait = 8,      
        RoundReadyTimeout = 45,
        RoundMaxDuration = 400,     
    
    
        OptimizationMode = "best",
        StripLobby = true,
        StripMap = true,            
        StripMapDecor = true,
        StripCoinVisuals = true,   
        MuteSounds = true,
        LowRendering = true,        
        Disable3DRender = false,    
                                    
        HideOtherPlayers = true,
        MinimizeLocalCharacter = true,
    
        InstantOpt = true,       
        BlockMapLoad = true,       
                               
                                    
                                    
                                   
        FilterIncomingInstances = true, 
                                  
        FilterRemoteHandlers = true, 
                                   
                                  
        EssentialRemotes = {      
            "GetCoin", "CoinCollected", "CoinsStarted", "RoundStart", "LoadingMap",
            "VictoryScreen", "RoundEndFade", "TeleportToPart", "PlayerDataChanged",
            "GetCurrentPlayerData", "Fade", "GameOver", "SpecialRound",
            "ShowRoleSelect", "ShowRoleSelectNew", "ShowTeammates", "GiveWeapon",
            "ChangeLastDevice", "LoadedCompletely", "GetData2", "GetSyncData",
            "ChangeProfileData", "ChangeInventoryItem",
            "LoadingUpdate", "ClientLoaded",
        },
        DowngradeTechnology = true,
        FreezeCharacter = true,    
        DisableHeavyScripts = true,
        StripPlayerGui = true,
        KeepGameHud = true,
        BatchDestroyPerFrame = 30,  
    
        LockFps = true,
        FpsCap = 30,              
        AntiAfk = true,
        AutoRejoin = true,         
        RejoinScriptUrl = "",      
    
        AutoSelectDevice = true,    
        AutoDevice = "Phone",       
        WaitForGameReady = true,
        GameReadyTimeout = 120,
    
    
        ShowHud = true,
        HudUpdateInterval = 1,
        VoidRescueBelowY = 15,      
        AutoCreatePad = true,      
        PadSize = 128,
        FixFallenPartsHeight = true,

        ---------------------------------------------------------------- summer --
        EnableSummer2026 = true,
        Summer2026Interval = 15,       -- giây giữa mỗi lần check claim/box
        MinShellsForBox = 0,           -- 0 = auto từ NewShop (SummerKey2026 price)
        Summer2026EventTitle = "Summer2026",
        Summer2026KeyCurrency = "SummerKey2026",
        Summer2026BoxId = "Summer2026Box",
        Summer2026ClaimBattlePass = true,
        Summer2026AutoUnbox = true,
                                    
        Debug = false,
    }
    
    local Config = {}
    do
        local userCfg = type(G.MM2KaitunV2Config) == "table" and G.MM2KaitunV2Config or {}
        for k, v in DEFAULT_CONFIG do
            if userCfg[k] ~= nil then
                Config[k] = userCfg[k]
            else
                Config[k] = v
            end
        end
        if Config.OptimizationMode == "off" then
            Config.StripLobby = false
            Config.StripMap = false
            Config.StripMapDecor = false
            Config.StripCoinVisuals = false
            Config.MuteSounds = false
            Config.LowRendering = false
            Config.HideOtherPlayers = false
            Config.DisableHeavyScripts = false
            Config.StripPlayerGui = false
            Config.InstantOpt = false
            Config.BlockMapLoad = false
            Config.FilterIncomingInstances = false
            Config.FilterRemoteHandlers = false
        elseif Config.OptimizationMode == "light" then
            -- light = rendering + sound + inbound/remote filter, KHÔNG strip
            -- geometry (lobby/map giữ nguyên, không block map load)
            Config.StripLobby = false
            Config.StripMap = false
            Config.StripMapDecor = false
            Config.DisableHeavyScripts = false
            Config.StripPlayerGui = false
            Config.BlockMapLoad = false
        end
    end
    
    --══════════════════════════════ SERVICES / EXEC ════════════════════════════
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Lighting = game:GetService("Lighting")
    local SoundService = game:GetService("SoundService")
    local StarterGui = game:GetService("StarterGui")
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")
    local VirtualUser = game:GetService("VirtualUser")
    local TeleportService = game:GetService("TeleportService")
    
    local player = Players.LocalPlayer
    
    -- Feature-detect API executor (mobile executor thiếu nhiều API — luôn pcall)
    local Exec = {
        fireTouch = (type(firetouchinterest) == "function" and firetouchinterest) or nil,
        getHui = (type(gethui) == "function" and gethui) or nil,
        queueTeleport = nil,
        setFps = nil,
        getConnections = nil,
        setHidden = nil,
        identify = "",
    }
    do
        pcall(function()
            Exec.queueTeleport = (type(queue_on_teleport) == "function" and queue_on_teleport)
                or (type(syn) == "table" and type(syn.queue_on_teleport) == "function" and syn.queue_on_teleport)
                or (type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" and fluxus.queue_on_teleport)
                or nil
        end)
        pcall(function()
            Exec.setFps = (type(setfpscap) == "function" and setfpscap)
                or (type(set_fps_cap) == "function" and set_fps_cap)
                or (type(syn) == "table" and type(syn.set_fps_cap) == "function" and syn.set_fps_cap)
                or nil
        end)
        pcall(function()
            Exec.getConnections = (type(getconnections) == "function" and getconnections)
                or (type(get_signal_cons) == "function" and get_signal_cons)
                or nil
        end)
        pcall(function()
            Exec.setHidden = (type(sethiddenproperty) == "function" and sethiddenproperty) or nil
        end)
        pcall(function()
            if type(identifyexecutor) == "function" then
                Exec.identify = string.lower(tostring(identifyexecutor() or ""))
            end
        end)
    end
    
    -- Arceus/Linux: một số call nặng gây crash → nới nhẹ hành vi
    local LinuxSafe = Exec.identify:find("arceus", 1, true) ~= nil
        or Exec.identify:find("linux", 1, true) ~= nil
    
    --════════════════════════════════════ UTIL ═════════════════════════════════
    
    local function log(msg)
        warn("[KaitunV2] " .. tostring(msg))
    end
    
    local function dbg(msg)
        if Config.Debug then
            log("· " .. tostring(msg))
        end
    end
    
    local function safe(fn, ...)
        local ok, err = pcall(fn, ...)
        if not ok then
            dbg("pcall: " .. tostring(err))
        end
        return ok
    end
    
    local function getCharacter()
        local char = player.Character
        if not char then
            return nil
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then
            return nil
        end
        return char, hrp, hum
    end
    
    -- Lobby Y≈504, map Y≈270-310 (log thực tế) — heuristic kết hợp thêm remote flag
    local function isLobbyY(y)
        return y > 400
    end
    
    --═══════════════════════════════════ MAID ══════════════════════════════════
    -- Quản lý connection/thread theo key: gán đè tự disconnect cái cũ,
    -- round end chỉ cần Clean() nhóm liên quan → không rò connection.
    
    local Maid = {}
    Maid.__index = Maid
    
    function Maid.new()
        return setmetatable({ _items = {} }, Maid)
    end
    
    function Maid:Give(key, item)
        self:Clean(key)
        self._items[key] = item
        return item
    end
    
    function Maid:Clean(key)
        local item = self._items[key]
        if not item then
            return
        end
        self._items[key] = nil
        local t = typeof(item)
        if t == "RBXScriptConnection" then
            safe(function() item:Disconnect() end)
        elseif t == "Instance" then
            safe(function() item:Destroy() end)
        elseif t == "thread" then
            -- không cancel chính thread đang chạy (tự nó return/break sau đó)
            if item ~= coroutine.running() then
                safe(function() task.cancel(item) end)
            end
        elseif type(item) == "function" then
            safe(item)
        end
    end
    
    function Maid:CleanPrefix(prefix)
        for key in self._items do
            if string.sub(key, 1, #prefix) == prefix then
                self:Clean(key)
            end
        end
    end
    
    function Maid:DestroyAll()
        for key in self._items do
            self:Clean(key)
        end
    end
    
    --══════════════════════════════════ STATE ══════════════════════════════════
    
    local PHASE = { BOOT = "boot", LOBBY = "lobby", LOADING = "loading", ROUND = "round", DEAD = "dead" }
    
    local K = {
        Version = "2.1.0",
        Config = Config,
        Phase = PHASE.BOOT,
        Destroyed = false,
    
        -- round flags
        CoinsActive = false,
        AwaitNextRound = false,   -- chết / bag reset → chặn farm tới LoadingMap sau
        TeleportSeen = false,     -- đã nhận TeleportToPart round này
        LoadingMapAt = nil,
        RoundStartedAt = nil,
        ExpectedMapName = nil,
    
        -- farm
        Running = false,
        BagFull = false,
        FullBags = {},            -- [coinType] = true khi bag đó đầy
        Visited = nil,            -- weak set coin đã xử lý round này
        LastFarmCF = nil,
        IsTweening = false,
        CharacterFrozen = false,
    
        -- caches
        CoinContainer = nil,
        CoinSet = nil,            -- [Part] = true, nuôi bằng event
        PlayerData = nil,
        ProfileData = nil,        -- Modules.ProfileData → Materials.Owned.Coins
        _profileInitStarted = false,
        _profileSignalsConnected = false,
        CurrentRoundClient = nil,
        LobbySpawnCF = nil,
        PadTopY = nil,            -- map pad (per-round)
        PadStandCF = nil,         -- vị trí đứng an toàn trên map pad
        LobbyPadTopY = nil,       -- lobby pad (persistent cả session)
        LobbyPadCX = nil,
        LobbyPadCZ = nil,
        LobbyStandCF = nil,       -- vị trí đứng trên lobby pad (fallback rescue)
    
        -- stats
        Stats = {
            collected = 0, rounds = 0, bagCurrent = 0, bagMax = 0,
            inventoryCoins = nil, inventoryBase = nil, inventoryBaseAt = nil,
            startedAt = os.clock(),
        },
    
        -- infra
        GameReady = false,
        OptEarlyApplied = false,   -- instant opt (execute-time) đã chạy
        OptApplied = false,        -- opt boot-sensitive (sau GameReady) đã chạy
        DestroyQueue = {},
        DestroyedMark = setmetatable({}, { __mode = "k" }),
    
        _maid = Maid.new(),
        _roundToken = 0,
        _blockedMaps = setmetatable({}, { __mode = "k" }), -- map đã strip (BlockMapLoad)
        _disabledConns = {},       -- remote handler conns đã Disable (re-Enable khi Destroy)
        _essentialRemotes = nil,   -- set tên remote whitelist (build từ config 1 lần)
    }
    K.Visited = setmetatable({}, { __mode = "k" })
    
    --═════════════════════════════════ REMOTES ═════════════════════════════════
    
    local Remotes = {}
    
    local function resolveRemotes()
        if Remotes.GetCoin then
            return true
        end
        local ok = pcall(function()
            local root = ReplicatedStorage:WaitForChild("Remotes", 30)
            local gp = root:WaitForChild("Gameplay", 30)
            Remotes.Gameplay = gp
            Remotes.GetCoin = gp:WaitForChild("GetCoin", 10)
            Remotes.CoinCollected = gp:WaitForChild("CoinCollected", 10)
            Remotes.CoinsStarted = gp:WaitForChild("CoinsStarted", 10)
            Remotes.RoundStart = gp:WaitForChild("RoundStart", 10)
            Remotes.LoadingMap = gp:WaitForChild("LoadingMap", 10)
            Remotes.VictoryScreen = gp:WaitForChild("VictoryScreen", 10)
            Remotes.RoundEndFade = gp:WaitForChild("RoundEndFade", 10)
            Remotes.TeleportToPart = gp:FindFirstChild("TeleportToPart")
            Remotes.PlayerDataChanged = gp:FindFirstChild("PlayerDataChanged")
            Remotes.Extras = root:FindFirstChild("Extras")
        end)
        return ok and Remotes.GetCoin ~= nil
    end
    
    --═════════════════════════════ PLAYER DATA / ROLE ══════════════════════════
    -- Cache qua PlayerDataChanged (event-driven) — không InvokeServer mỗi tick.
    
    function K:InitPlayerData()
        safe(function()
            local mod = ReplicatedStorage:WaitForChild("Modules", 15)
            mod = mod and mod:WaitForChild("CurrentRoundClient", 15)
            if mod then
                self.CurrentRoundClient = require(mod)
            end
        end)
        local crc = self.CurrentRoundClient
        if type(crc) == "table" then
            if type(crc.PlayerData) == "table" then
                self.PlayerData = crc.PlayerData
            end
            -- signal = BindableEvent con của module (verify MCP)
            local sig = crc.PlayerDataChanged
            if typeof(sig) == "Instance" and sig:IsA("BindableEvent") then
                sig = sig.Event
            end
            if typeof(sig) == "RBXScriptSignal" or (type(sig) == "table" and type(sig.Connect) == "function") then
                safe(function()
                    self._maid:Give("playerDataSig", sig:Connect(function()
                        if type(crc.PlayerData) == "table" then
                            K.PlayerData = crc.PlayerData
                        end
                    end))
                end)
            end
        end
        -- fallback: nghe thẳng remote
        if Remotes.PlayerDataChanged and Remotes.PlayerDataChanged:IsA("RemoteEvent") then
            self._maid:Give("playerDataRemote", Remotes.PlayerDataChanged.OnClientEvent:Connect(function(payload)
                if type(payload) == "table" then
                    K.PlayerData = payload
                end
            end))
        end
    end
    
    function K:GetMyRoundData()
        local data = self.PlayerData
        if type(data) ~= "table" then
            return nil
        end
        return data[player.Name]
    end
    
    -- "Murderer" | "Sheriff" | "Innocent" | nil (chưa vào round)
    function K:GetRole()
        local my = self:GetMyRoundData()
        return my and my.Role or nil
    end
    
    function K:IsAliveInRound()
        local _, _, hum = getCharacter()
        if not hum or hum.Health <= 0 then
            return false
        end
        local my = self:GetMyRoundData()
        if my then
            if my.Dead == true then
                return false
            end
            if my.Role ~= nil then
                return true
            end
        end
        -- Không có data → tin CoinsActive (round vẫn chạy)
        return self.CoinsActive
    end
    
    --═════════════════════════════ PROFILE / INVENTORY ════════════════════════
    -- Coin inventory thật = ProfileData.Materials.Owned.Coins (verify ShopPhone).
    -- Module sync qua ChangeInventoryItem → InventoryDataChanged.
    
    local function extractInventoryCoins(pd)
        if type(pd) ~= "table" then
            return nil
        end
        local mats = pd.Materials
        if type(mats) == "table" then
            local owned = mats.Owned
            if type(owned) == "table" then
                local coins = tonumber(owned.Coins)
                if coins then
                    return coins
                end
            end
        end
        return tonumber(pd.Coins)
    end
    
    function K:SnapshotInventoryCoins(coins)
        coins = tonumber(coins)
        if coins == nil then
            return
        end
        local stats = self.Stats
        if stats.inventoryBase == nil then
            stats.inventoryBase = coins
            stats.inventoryBaseAt = os.clock()
        end
        stats.inventoryCoins = coins
    end
    
    function K:TryRequireProfileData()
        local mod = ReplicatedStorage:FindFirstChild("Modules")
        mod = mod and mod:FindFirstChild("ProfileData")
        if not mod then
            return nil
        end
        local ok, pd = pcall(require, mod)
        if ok and type(pd) == "table" then
            return pd
        end
        return nil
    end
    
    function K:RefreshInventoryCoinsFromProfile()
        local pd = self.ProfileData or self:TryRequireProfileData()
        if pd then
            self.ProfileData = pd
        end
        local coins = extractInventoryCoins(pd)
        if coins ~= nil then
            self:SnapshotInventoryCoins(coins)
        end
        return coins
    end
    
    function K:ConnectProfileDataSignals()
        if self._profileSignalsConnected then
            return
        end
        self._profileSignalsConnected = true
    
        local function onCoinsChanged(coins)
            coins = tonumber(coins)
            if coins == nil then
                K:RefreshInventoryCoinsFromProfile()
            else
                K:SnapshotInventoryCoins(coins)
            end
            K:UpdateHud()
        end
    
        safe(function()
            local inv = ReplicatedStorage:WaitForChild("Remotes", 15)
            inv = inv and inv:WaitForChild("Inventory", 15)
            if not inv then
                return
            end
    
            local invChanged = inv:FindFirstChild("InventoryDataChanged")
            if invChanged and invChanged:IsA("BindableEvent") then
                invChanged = invChanged.Event
            end
            if typeof(invChanged) == "RBXScriptSignal"
                or (type(invChanged) == "table" and type(invChanged.Connect) == "function")
            then
                self._maid:Give("inventoryDataChanged", invChanged:Connect(function(itemType, itemId, amount)
                    if itemType == "Materials" and itemId == "Coins" then
                        onCoinsChanged(amount)
                    end
                end))
            end
    
            local profChanged = inv:FindFirstChild("ProfileDataChanged")
            if profChanged and profChanged:IsA("BindableEvent") then
                profChanged = profChanged.Event
            end
            if typeof(profChanged) == "RBXScriptSignal"
                or (type(profChanged) == "table" and type(profChanged.Connect) == "function")
            then
                self._maid:Give("profileDataChanged", profChanged:Connect(function(key, val)
                    if key == "Coins" then
                        onCoinsChanged(val)
                    elseif key == "Materials" then
                        if type(val) == "table" and type(val.Owned) == "table" then
                            onCoinsChanged(val.Owned.Coins)
                        else
                            onCoinsChanged(nil)
                        end
                    end
                end))
            end
        end)
    
        safe(function()
            local ev = ReplicatedStorage:FindFirstChild("UpdateData2")
            if ev and ev:IsA("RemoteEvent") then
                self._maid:Give("updateData2", ev.OnClientEvent:Connect(function()
                    onCoinsChanged(nil)
                end))
            end
        end)
    end
    
    function K:InitProfileData()
        if self._profileInitStarted then
            return
        end
        self._profileInitStarted = true
        self:ConnectProfileDataSignals()
    
        self._maid:Give("profileInit", task.spawn(function()
            local timeout = 90
            local deadline = os.clock() + timeout
            while not K.Destroyed and os.clock() < deadline do
                local coins = K:RefreshInventoryCoinsFromProfile()
                if coins ~= nil then
                    K:UpdateHud()
                    dbg(string.format("ProfileData ready — inventory coins=%d", coins))
                    return
                end
                task.wait(0.5)
            end
            dbg("ProfileData coin read timeout — HUD may show 0 until sync")
        end))
    end
    
    function K:GetInventoryCoins()
        local coins = self:RefreshInventoryCoinsFromProfile()
        if coins ~= nil then
            return coins
        end
        return self.Stats.inventoryCoins or 0
    end
    
    function K:GetInventoryCoinRate()
        local stats = self.Stats
        local base, at = stats.inventoryBase, stats.inventoryBaseAt
        if not base or not at then
            return 0
        end
        local mins = math.max((os.clock() - at) / 60, 1 / 60)
        return math.max(0, (self:GetInventoryCoins() - base) / mins)
    end
    
    --════════════════════════════ BATCH DESTROY PUMP ═══════════════════════════
    -- Destroy dồn cục gây spike ở 10 FPS → xả theo budget mỗi Heartbeat.
    
    local function isCharacterProtected(inst)
        if not inst then
            return false
        end
        local char = player.Character
        if char and (inst == char or inst:IsDescendantOf(char)) then
            return true
        end
        if inst.Name == "Raggy" or inst.Name == "Characters" then
            return true
        end
        local p = inst.Parent
        while p and p ~= workspace do
            if p.Name == "Raggy" or p.Name == "Characters" then
                return true
            end
            p = p.Parent
        end
        return false
    end
    
    local COIN_KEEP = {
        CoinContainer = true, Coin_Server = true, TouchInterest = true,
        MainCoin = true, DecalPart = true,
    }
    
    local function isCoinRelated(inst)
        if not inst then
            return false
        end
        if COIN_KEEP[inst.Name] then
            return true
        end
        local p = inst.Parent
        while p do
            local n = p.Name
            if n == "CoinContainer" or n == "Coin_Server" then
                return true
            end
            p = p.Parent
        end
        return false
    end
    
    -- Case-insensitive "spawn" match: TeleportToPart trỏ tới part trong map model
    -- (CharacterClient đọc p3.Position — verify Studio) → spawn subtree PHẢI sống
    -- kể cả khi BlockMapLoad destroy toàn bộ geometry còn lại.
    local function isSpawnRelated(inst)
        if not inst then
            return false
        end
        if string.find(string.lower(inst.Name), "spawn", 1, true) then
            return true
        end
        local p = inst.Parent
        while p do
            if string.find(string.lower(p.Name), "spawn", 1, true) then
                return true
            end
            p = p.Parent
        end
        return false
    end
    
    local function isKaitunPart(inst)
        local p = inst
        while p do
            if p.Name == "KaitunV2Pads" then
                return true
            end
            p = p.Parent
        end
        return false
    end
    
    function K:QueueDestroy(inst)
        -- Bất biến cứng: KHÔNG BAO GIỜ destroy coin subtree / spawns / character
        if not inst or not inst.Parent or self.DestroyedMark[inst] then
            return
        end
        if isCoinRelated(inst) or isSpawnRelated(inst) or isCharacterProtected(inst) or isKaitunPart(inst) then
            return
        end
        self.DestroyedMark[inst] = true
        table.insert(self.DestroyQueue, inst)
    end
    
    function K:PumpDestroyQueue()
        local limit = Config.BatchDestroyPerFrame or 30
        local q = self.DestroyQueue
        local n = 0
        while n < limit and #q > 0 do
            local inst = table.remove(q)
            if inst and inst.Parent then
                safe(function() inst:Destroy() end)
                n += 1
            end
        end
    end
    
    --═════════════════════════════════ OPTIMIZER ═══════════════════════════════
    
    local WORKSPACE_LOBBY_DESTROY = {
        "RegularLobby", "LoadLobby", "ServerStatus", "EffectLoader", "PetContainer",
        "WeaponDisplays", "GameSettings", "RoundTimerPart", "VotePads", "ServerVersion",
    }
    
    -- Whitelist script PHẢI giữ (Phụ lục A plan). CharacterClient = P0: disable nó
    -- là kẹt lobby vĩnh viễn (TeleportToPart không ai xử lý).
    local SCRIPT_KEEP = {
        "Kaitun", "CharacterClient", "CoinVisualizer", "CoinBag", "Unfade",
        "RoleSelector", "Preloader", "ControlsEnable", "PlayerScriptsLoader",
        "ClientEventManager", "Menu/GUI", "Menu.GUI", "FadeModule", "SpawnFade",
        "CameraFade", "StatUpdater", "Sync.Client", "ProfileLoader",
        "DatabaseUpdater", "EquipWeapons", "CoinBagContainerScript",
        "CurrentRoundClient", "Animate", "Ragdoll", "Health", "Game/Names",
    }
    
    local MAP_DECOR_DESTROY = {
        "Decoration_Regular", "Decorations", "Decoration", "Interactive",
        "VaultSystem", "Props", "Props2", "Details", "Ambient", "Effects",
        "Particles", "Lights", "Lighting", "Furniture",
    }
    
    local GAME_HUD_SCREENGUIS = { MainGUI = true, GameUI = true, MobileUI = true, TabletUI = true }
    
    local function shouldKeepScript(s)
        local path = s:GetFullName()
        for _, kw in SCRIPT_KEEP do
            if path:find(kw, 1, true) then
                return true
            end
        end
        return false
    end
    
    function K:ApplyRenderingSettings()
        if not Config.LowRendering then
            return
        end
        safe(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        safe(function()
            settings().Rendering.MeshQuality = Enum.MeshQuality.Level01
        end)
        safe(function()
            -- full strip (merge từ opt_v2): shadows/fog/env reflections về 0
            Lighting.GlobalShadows = false
            Lighting.Brightness = 1
            Lighting.FogEnd = 9e9
            Lighting.FogStart = 9e9
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            for _, child in Lighting:GetChildren() do
                child:Destroy()
            end
        end)
        if Config.DowngradeTechnology and Exec.setHidden then
            safe(function()
                Exec.setHidden(Lighting, "Technology", Enum.Technology.Compatibility)
            end)
        end
        safe(function()
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.Decoration = false
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 1
            end
        end)
        if Config.Disable3DRender and not LinuxSafe then
            safe(function()
                RunService:Set3dRenderingEnabled(false)
            end)
        end
    end
    
    function K:MuteSounds()
        if not Config.MuteSounds then
            return
        end
        for _, root in { SoundService, workspace } do
            safe(function()
                for _, s in root:GetDescendants() do
                    if s:IsA("Sound") then
                        s.Volume = 0
                        s.Playing = false
                    end
                end
            end)
        end
        safe(function()
            SoundService.AmbientReverb = Enum.ReverbType.NoReverb
        end)
    end
    
    -- Strip lobby NHƯNG giữ Spawns + tạo lobby pad TRƯỚC khi sàn biến mất.
    -- Verify Studio: SpawnLocation lobby transparent/CanCollide=false (không phải
    -- sàn) và FallenPartsDestroyHeight=NaN → mất sàn = rơi vĩnh viễn.
    function K:StripLobbyModels()
        if not Config.StripLobby then
            return
        end
        self:EnsureLobbyPad()
        for _, name in WORKSPACE_LOBBY_DESTROY do
            local inst = workspace:FindFirstChild(name)
            if inst then
                if inst:IsA("Model") and inst:FindFirstChild("Spawns") then
                    -- lobby model: strip từng child, giữ nguyên Spawns
                    for _, child in inst:GetChildren() do
                        if not isSpawnRelated(child) then
                            self:QueueDestroy(child)
                        end
                    end
                else
                    self:QueueDestroy(inst)
                end
            end
        end
    end
    
    function K:HideOtherPlayers()
        if not Config.HideOtherPlayers then
            return
        end
        for _, model in workspace:GetChildren() do
            if model:IsA("Model") and model ~= player.Character
                and model:FindFirstChildOfClass("Humanoid")
                and not isCharacterProtected(model)
            then
                self:QueueDestroy(model)
            end
        end
    end
    
    -- Ẩn cả player respawn/join sau này (event-driven, không quét lại workspace)
    function K:ArmHideOtherPlayers()
        if not Config.HideOtherPlayers then
            return
        end
        local function hook(plr)
            if plr == player then
                return
            end
            self._maid:Give("hide_" .. plr.UserId, plr.CharacterAdded:Connect(function(char)
                task.defer(function()
                    if char.Parent then
                        safe(function() char:Destroy() end)
                    end
                end)
            end))
            if plr.Character then
                safe(function() plr.Character:Destroy() end)
            end
        end
        for _, plr in Players:GetPlayers() do
            hook(plr)
        end
        self._maid:Give("hidePlayerAdded", Players.PlayerAdded:Connect(hook))
        self._maid:Give("hidePlayerRemoving", Players.PlayerRemoving:Connect(function(plr)
            K._maid:Clean("hide_" .. plr.UserId)
        end))
    end
    
    function K:DisableHeavyScripts()
        if not Config.DisableHeavyScripts then
            return
        end
        local roots = { game:GetService("StarterPlayer"), StarterGui, ReplicatedStorage }
        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            table.insert(roots, pg)
        end
        for _, root in roots do
            safe(function()
                for _, s in root:GetDescendants() do
                    if (s:IsA("LocalScript") or s:IsA("Script")) and not s.Disabled then
                        if not isCharacterProtected(s) and not shouldKeepScript(s) then
                            s.Disabled = true
                        end
                    end
                end
            end)
        end
        self:EnsureCharacterClient()
    end
    
    -- P0: bảo đảm CharacterClient luôn enabled (game teleport phụ thuộc nó)
    function K:EnsureCharacterClient()
        safe(function()
            local char = player.Character
            local cc = char and char:FindFirstChild("CharacterClient")
            if cc and (cc:IsA("LocalScript") or cc:IsA("Script")) then
                cc.Disabled = false
            end
            local starter = game:GetService("StarterPlayer"):FindFirstChild("StarterCharacterScripts")
            cc = starter and starter:FindFirstChild("CharacterClient")
            if cc and (cc:IsA("LocalScript") or cc:IsA("Script")) then
                cc.Disabled = false
            end
        end)
    end
    
    function K:StripPlayerGuiScreens()
        if not Config.StripPlayerGui then
            return
        end
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then
            return
        end
        for _, child in pg:GetChildren() do
            if child:IsA("ScreenGui") and child.Name ~= "KaitunV2Hud" then
                if not (Config.KeepGameHud and GAME_HUD_SCREENGUIS[child.Name]) then
                    safe(function() child:Destroy() end)
                end
            end
        end
        -- Stub GUI mà FadeModule/Unfade mong đợi — tránh error spam sau strip
        for _, spec in { { "CameraFade", "ScreenGui" }, { "SpawnFade", "ScreenGui" }, { "InputContext", "Folder" } } do
            if not pg:FindFirstChild(spec[1]) then
                safe(function()
                    local stub = Instance.new(spec[2])
                    stub.Name = spec[1]
                    if stub:IsA("ScreenGui") then
                        stub.ResetOnSpawn = false
                    end
                    stub.Parent = pg
                end)
            end
        end
    end
    
    function K:MinimizeCharacter()
        if not Config.MinimizeLocalCharacter then
            return
        end
        local char = player.Character
        if not char then
            return
        end
        safe(function()
            for _, part in char:GetDescendants() do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.LocalTransparencyModifier = 1
                    part.CastShadow = false
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    part.Transparency = 1
                end
            end
        end)
    end
    
    local function isDecorName(name)
        for _, decor in MAP_DECOR_DESTROY do
            if name:find(decor, 1, true) then
                return true
            end
        end
        return false
    end
    
    -- Strip map model: giữ CoinContainer + Spawns, destroy phần còn lại theo queue.
    -- StripMap = toàn bộ geometry; chỉ StripMapDecor = folder decor thôi.
    function K:StripMapModel(map)
        if not map or not map.Parent then
            return
        end
        if Config.StripMap then
            for _, child in map:GetChildren() do
                if child.Name ~= "CoinContainer" and not isSpawnRelated(child) and not isCharacterProtected(child) then
                    self:QueueDestroy(child)
                end
            end
        elseif Config.StripMapDecor then
            for _, child in map:GetChildren() do
                if isDecorName(child.Name) and not isSpawnRelated(child) and not isCharacterProtected(child) then
                    self:QueueDestroy(child)
                end
            end
        end
        if Config.StripCoinVisuals then
            local cc = map:FindFirstChild("CoinContainer")
            if cc then
                safe(function()
                    for _, coin in cc:GetChildren() do
                        local vis = coin:FindFirstChild("CoinVisual")
                        if vis then
                            vis:Destroy()
                        end
                    end
                end)
            end
        end
    end
    
    -- Nghe map replicate trong LOADING → strip ngay khi xuất hiện.
    -- Chỉ nối khi loading, ngắt khi round end (không watcher thường trực).
    -- BlockMapLoad đã arm watcher thường trực → bỏ qua (không double-strip).
    function K:ArmMapStripper()
        if Config.BlockMapLoad and self._blockMapArmed then
            return
        end
        if not (Config.StripMap or Config.StripMapDecor or Config.StripCoinVisuals) then
            return
        end
        local token = self._roundToken
        self._maid:Give("round_mapChildAdded", workspace.ChildAdded:Connect(function(child)
            if token ~= K._roundToken then
                return
            end
            if child:IsA("Model") and child ~= player.Character then
                task.defer(function()
                    if token ~= K._roundToken or not child.Parent then
                        return
                    end
                    -- map model = có CoinContainer hoặc trùng tên map đã vote
                    if child:FindFirstChild("CoinContainer")
                        or (K.ExpectedMapName and child.Name == K.ExpectedMapName)
                    then
                        K:StripMapModel(child)
                    end
                end)
            end
        end))
        self._maid:Give("round_mapDescAdded", workspace.DescendantAdded:Connect(function(desc)
            if token ~= K._roundToken then
                return
            end
            if desc.Name == "CoinContainer" then
                local map = desc:FindFirstAncestorOfClass("Model")
                if map and map ~= player.Character then
                    task.defer(function()
                        if token == K._roundToken then
                            K:StripMapModel(map)
                        end
                    end)
                end
            elseif Config.StripCoinVisuals and desc.Name == "CoinVisual" and isCoinRelated(desc) then
                task.defer(function()
                    if desc.Parent then
                        safe(function() desc:Destroy() end)
                    end
                end)
            end
        end))
        -- map đã tồn tại sẵn (inject giữa round)
        for _, child in workspace:GetChildren() do
            if child:IsA("Model") and child ~= player.Character and child:FindFirstChild("CoinContainer") then
                self:StripMapModel(child)
            end
        end
    end
    
    --═══════════════════ INSTANT OPT ENGINE (nhúng từ opt_v2) ══════════════════
    -- Chạy NGAY khi execute (InstantOpt) — không chờ boot/round. Mọi destroy đều
    -- qua QueueDestroy → pump theo budget của Heartbeat hub sẵn có (không tạo
    -- thêm Heartbeat connection, không double pump).
    
    -- Inbound instance filter (lớp 1 opt_v2): junk vừa replicate tới là dọn ngay.
    -- Client không firewall được replication — đây là mức gần nhất hợp lệ.
    local JUNK_DESTROY_CLASSES = {
        ParticleEmitter = true, Trail = true, Beam = true, Smoke = true,
        Fire = true, Sparkles = true, Decal = true, Texture = true,
        BillboardGui = true, SurfaceGui = true, Highlight = true,
        ProximityPrompt = true, ClickDetector = true,
        PointLight = true, SpotLight = true, SurfaceLight = true,
    }
    
    function K:ProcessInboundInstance(inst)
        if not inst or not inst.Parent then
            return
        end
        local cls = inst.ClassName
        if cls == "Explosion" then
            safe(function()
                inst.BlastPressure = 0
                inst.BlastRadius = 0
                inst.Visible = false
            end)
            self:QueueDestroy(inst)
            return
        end
        if cls == "Sound" then
            if Config.MuteSounds then
                safe(function()
                    inst.Volume = 0
                    inst.Playing = false
                    inst.Looped = false
                end)
            end
            return
        end
        if JUNK_DESTROY_CLASSES[cls] then
            -- QueueDestroy tự enforce bất biến: coin/spawn/char/pad không bị đụng
            if cls == "ParticleEmitter" or cls == "Trail" or cls == "Beam" then
                safe(function() inst.Enabled = false end)
            end
            self:QueueDestroy(inst)
        end
    end
    
    -- Watcher thường trực (arm 1 lần cả session, không per-round)
    function K:ArmInboundFilter()
        if not Config.FilterIncomingInstances then
            return
        end
        self._maid:Give("inboundFilter", workspace.DescendantAdded:Connect(function(inst)
            task.defer(function()
                if not K.Destroyed then
                    K:ProcessInboundInstance(inst)
                end
            end)
        end))
        self._maid:Give("inboundLighting", Lighting.ChildAdded:Connect(function(child)
            if Config.LowRendering then
                task.defer(function()
                    if child.Parent then
                        safe(function() child:Destroy() end)
                    end
                end)
            end
        end))
        self._maid:Give("inboundSound", SoundService.DescendantAdded:Connect(function(inst)
            if Config.MuteSounds and inst:IsA("Sound") then
                task.defer(function()
                    if inst.Parent then
                        safe(function()
                            inst.Volume = 0
                            inst.Playing = false
                        end)
                    end
                end)
            end
        end))
    end
    
    -- BLOCK MAP LOAD (chế độ siêu mạnh): map mới replicate vào workspace bị strip
    -- NGAY KHI TỚI — chỉ giữ lại tối thiểu cho farm hoạt động:
    --   • CoinContainer + Coin_Server + TouchInterest (farm — verify Studio:
    --     CoinContainer là Model con trực tiếp map, Coin_Server là Part con)
    --   • Spawns / mọi part tên chứa "spawn" (TeleportToPart trỏ tới part TRONG
    --     map model; CharacterClient đọc p3.Position → part phải sống. Map pad
    --     của kaitun đặt dưới spawn trong OnTeleportToPart → không rơi void)
    --   • Raggy / Characters (ragdoll — isCharacterProtected)
    --   • KaitunV2Pads
    -- Verify Studio 22/07: không script client nào đọc geometry map (grep
    -- Raggy/CoinContainer/Spawns = 0 hit trong 314 script; CoinVisualizer chỉ
    -- dùng CollectionService tag "CoinVisual") → destroy geometry an toàn.
    function K:BlockIncomingModel(model)
        if not model or not model.Parent or self._blockedMaps[model] then
            return
        end
        if model == player.Character or isCharacterProtected(model) or isKaitunPart(model) then
            return
        end
        -- character/NPC có Humanoid → để HideOtherPlayers quyết định, không block.
        -- GetPlayerFromCharacter bắt cả case Humanoid CHƯA replicate xong.
        if model:FindFirstChildOfClass("Humanoid") then
            return
        end
        local isPlayerChar = false
        safe(function()
            isPlayerChar = Players:GetPlayerFromCharacter(model) ~= nil
        end)
        if isPlayerChar then
            return
        end
        -- lobby model = Spawns ở Y lobby (>400) mà không có CoinContainer.
        -- (Map cũng có thể có Spawns nhưng ở Y map thấp — vẫn block bình thường.)
        -- StripLobby=false → không đụng lobby; true → tạo lobby pad TRƯỚC khi
        -- sàn biến mất (giữ fix anti-fall LobbyPad)
        do
            local spawns = model:FindFirstChild("Spawns")
            if spawns and not model:FindFirstChild("CoinContainer") then
                local isLobbyModel = false
                safe(function()
                    local sp = spawns:FindFirstChildWhichIsA("BasePart")
                    if sp and isLobbyY(sp.Position.Y) then
                        isLobbyModel = true
                    end
                end)
                if isLobbyModel then
                    if not Config.StripLobby then
                        return
                    end
                    self:EnsureLobbyPad()
                end
            end
        end
        self._blockedMaps[model] = true
    
        local function stripChild(child)
            if child.Name == "CoinContainer" or isSpawnRelated(child)
                or isCharacterProtected(child) or isKaitunPart(child)
            then
                return
            end
            self:QueueDestroy(child)
        end
    
        -- strip mọi child hiện có (giữ model shell — CoinContainer/Spawns về sau
        -- vẫn có chỗ đậu) + strip CoinVisual trong coin đã tới
        for _, child in model:GetChildren() do
            stripChild(child)
        end
        if Config.StripCoinVisuals then
            local cc = model:FindFirstChild("CoinContainer")
            if cc then
                safe(function()
                    for _, coin in cc:GetChildren() do
                        local vis = coin:FindFirstChild("CoinVisual")
                        if vis then
                            vis:Destroy()
                        end
                    end
                end)
            end
        end
    
        -- child replicate muộn (map lớn stream dần) → chặn tiếp khi tới
        self._blockMapN = (self._blockMapN or 0) + 1
        local key = "blockmap_" .. self._blockMapN
        self._maid:Give(key, model.ChildAdded:Connect(function(child)
            task.defer(function()
                if not K.Destroyed and child.Parent then
                    if child.Name == "CoinContainer" then
                        -- coin visuals của container tới muộn
                        if Config.StripCoinVisuals then
                            K:StripMapModel(model)
                        end
                    else
                        stripChild(child)
                    end
                end
            end)
        end))
        -- model rời workspace (round end, server dọn) → nhả connection
        self._maid:Give(key .. "_gone", model.AncestryChanged:Connect(function(_, parent)
            if parent == nil then
                K._maid:Clean(key)
                K._maid:Clean(key .. "_gone")
            end
        end))
        dbg("BlockMapLoad: stripped incoming model " .. model.Name)
    end
    
    function K:ArmBlockMapLoad()
        if not Config.BlockMapLoad or self._blockMapArmed then
            return
        end
        self._blockMapArmed = true
        self._maid:Give("blockMapWatch", workspace.ChildAdded:Connect(function(child)
            if child:IsA("Model") then
                task.defer(function()
                    if not K.Destroyed and child.Parent then
                        K:BlockIncomingModel(child)
                    end
                end)
            end
        end))
        -- map đã tồn tại lúc execute (inject giữa round)
        for _, child in workspace:GetChildren() do
            if child:IsA("Model") and child:FindFirstChild("CoinContainer") then
                self:BlockIncomingModel(child)
            end
        end
        log("BlockMapLoad armed — map geometry sẽ bị chặn, chỉ coins/spawns load")
    end
    
    -- Remote handler filter (lớp 2 opt_v2): Disable mọi connection OnClientEvent
    -- của RemoteEvent NGOÀI whitelist → remote vẫn tới nhưng 0 CPU handler.
    -- Outgoing (FireServer/InvokeServer) KHÔNG BAO GIỜ bị đụng. Connection của
    -- kaitun đều trên remote whitelist → tự an toàn. Chạy tối đa 2 pass
    -- (GameReady + LoadingMap đầu) vì game script connect dần trong lúc boot.
    function K:ApplyRemoteHandlerFilter()
        if not Config.FilterRemoteHandlers or not Exec.getConnections then
            return
        end
        if (self._remoteFilterPasses or 0) >= 2 then
            return
        end
        self._remoteFilterPasses = (self._remoteFilterPasses or 0) + 1
        if not self._essentialRemotes then
            local set = {}
            if type(Config.EssentialRemotes) == "table" then
                for _, name in Config.EssentialRemotes do
                    set[tostring(name)] = true
                end
            end
            self._essentialRemotes = set
        end
        local disabled = 0
        safe(function()
            for _, inst in ReplicatedStorage:GetDescendants() do
                if (inst:IsA("RemoteEvent") or inst:IsA("UnreliableRemoteEvent"))
                    and not self._essentialRemotes[inst.Name]
                then
                    local ok, conns = pcall(Exec.getConnections, inst.OnClientEvent)
                    if ok and type(conns) == "table" then
                        for _, conn in conns do
                            if pcall(function() conn:Disable() end) then
                                table.insert(self._disabledConns, conn)
                                disabled += 1
                            end
                        end
                    end
                end
            end
        end)
        if disabled > 0 then
            log(string.format("Remote handler filter: disabled %d connections (pass %d)",
                disabled, self._remoteFilterPasses))
        end
    end
    
    function K:RestoreRemoteHandlerFilter()
        for _, conn in self._disabledConns do
            pcall(function() conn:Enable() end)
        end
        table.clear(self._disabledConns)
    end
    
    -- Opt an toàn lúc execute (không đụng boot flow / PlayerGui / script game).
    -- InstantOpt=true → chạy ngay ở INIT; nếu không, ApplyOptimizationOnce gọi.
    function K:ApplyEarlyOpt()
        if self.OptEarlyApplied or Config.OptimizationMode == "off" then
            return
        end
        self.OptEarlyApplied = true
        self:ApplyRenderingSettings()
        self:MuteSounds()
        self:StripLobbyModels()
        self:HideOtherPlayers()
        self:ArmHideOtherPlayers()
        self:MinimizeCharacter()
        self:ArmInboundFilter()
        self:ArmBlockMapLoad()
        log("Instant opt applied (mode=" .. tostring(Config.OptimizationMode)
            .. (Config.BlockMapLoad and ", BlockMapLoad" or "")
            .. (LinuxSafe and ", LinuxSafe" or "") .. ")")
    end
    
    -- Phần boot-sensitive (chờ GameReady): disable script game / strip PlayerGui /
    -- remote filter — đụng sớm quá sẽ phá DeviceSelect/Loading flow.
    function K:ApplyOptimizationOnce()
        if self.OptApplied or Config.OptimizationMode == "off" then
            return
        end
        self.OptApplied = true
        self:ApplyEarlyOpt()
        self:DisableHeavyScripts()
        self:StripPlayerGuiScreens()
        self:ApplyRemoteHandlerFilter()
        self:MinimizeCharacter()
        log("Optimization applied (mode=" .. tostring(Config.OptimizationMode)
            .. (LinuxSafe and ", LinuxSafe" or "") .. ")")
    end
    
    --═════════════════════════════════ MOVEMENT ════════════════════════════════
    
    function K:GetUprightCF(pos, hrp)
        if hrp then
            local _, ry = hrp.CFrame:ToOrientation()
            return CFrame.new(pos) * CFrame.Angles(0, ry, 0)
        end
        return CFrame.new(pos)
    end
    
    function K:ZeroVelocity(hrp)
        safe(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    
    function K:ApplyCF(cf)
        local char, hrp = getCharacter()
        if not hrp or not cf then
            return
        end
        safe(function()
            char:PivotTo(cf)
        end)
        self:ZeroVelocity(hrp)
        self.LastFarmCF = cf
    end
    
    function K:FreezeCharacter()
        if not Config.FreezeCharacter or self.CharacterFrozen then
            return
        end
        local char, hrp, hum = getCharacter()
        if not char or not hum then
            return
        end
        -- KHÔNG anchor HRP: anchored không replicate → server không thấy vị trí
        hum.PlatformStand = true
        hum.AutoRotate = false
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        safe(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            if not LinuxSafe then
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end
        end)
        if not LinuxSafe then
            safe(function()
                for _, desc in char:GetDescendants() do
                    if desc:IsA("Animator") then
                        for _, track in desc:GetPlayingAnimationTracks() do
                            track:Stop(0)
                        end
                    end
                end
            end)
        end
        self.CharacterFrozen = true
        if hrp then
            self:ZeroVelocity(hrp)
        end
    end
    
    function K:UnfreezeCharacter()
        self.CharacterFrozen = false
        local _, _, hum = getCharacter()
        if not hum then
            return
        end
        safe(function()
            hum.PlatformStand = false
            hum.AutoRotate = true
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        end)
    end
    
    -- Tween mượt time-based: đúng quãng đường theo thời gian thực nên ổn định
    -- ở FPS thấp (frame ít nhưng mỗi frame lerp xa hơn). KHÔNG teleport.
    -- Trả về false nếu bị ngắt (round end / chết / stop).
    function K:TweenTo(targetPos, token)
        local _, hrp = getCharacter()
        if not hrp then
            return false
        end
        local speed = math.clamp(Config.TweenSpeed or 28, 4, Config.TweenSpeedMax or 60)
        local from = (self.LastFarmCF and self.LastFarmCF.Position) or hrp.Position
        local dist = (targetPos - from).Magnitude
        if dist < 0.1 then
            self:ApplyCF(self:GetUprightCF(targetPos, hrp))
            return true
        end
        local duration = math.clamp(dist / speed, Config.TweenMinTime or 0.1, Config.TweenMaxTime or 6)
        self.IsTweening = true
        local elapsed = 0
        while elapsed < duration do
            if token ~= self._roundToken or not self.Running then
                self.IsTweening = false
                return false
            end
            local dt = task.wait()
            elapsed += dt
            local alpha = math.clamp(elapsed / duration, 0, 1)
            local _, hrp2 = getCharacter()
            if not hrp2 then
                self.IsTweening = false
                return false
            end
            self:ApplyCF(self:GetUprightCF(from:Lerp(targetPos, alpha), hrp2))
        end
        self.IsTweening = false
        return true
    end
    
    -- Pads vô hình (client-only): sàn VẬT LÝ thay cho geometry đã strip.
    -- Nhân vật ĐỨNG YÊN trên pad = physics tự nghỉ, không cần giữ CFrame mỗi
    -- frame, không anchor HRP (replication coin farm vẫn chạy). 2 pad:
    --   "Pad"      — map, reposition mỗi round (spawn part → cụm coin)
    --   "LobbyPad" — lobby, persistent CẢ SESSION (lobby tĩnh, Y≈502)
    
    local function ensurePadPart(name)
        local folder = workspace:FindFirstChild("KaitunV2Pads")
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = "KaitunV2Pads"
            folder.Parent = workspace
        end
        local pad = folder:FindFirstChild(name)
        if not pad then
            pad = Instance.new("Part")
            pad.Name = name
            pad.Anchored = true
            pad.CanCollide = true
            pad.CanQuery = false
            pad.CanTouch = false
            pad.Transparency = 1
            pad.CastShadow = false
            pad.Size = Vector3.new(Config.PadSize or 128, 4, Config.PadSize or 128)
            pad.Parent = folder
        end
        return pad
    end
    
    -- Map pad dưới vùng coin / spawn part — đỡ rơi void giữa các lần tween
    function K:EnsurePad(centerX, centerZ, topY)
        if not Config.AutoCreatePad then
            return
        end
        local pad = ensurePadPart("Pad")
        pad.CFrame = CFrame.new(centerX, topY - 2, centerZ)
        self.PadTopY = topY
        self.PadStandCF = CFrame.new(centerX, topY + 3, centerZ)
    end
    
    -- Reposition map pad theo bbox cụm coin (gọi lúc farm start)
    function K:SyncPadToCoins()
        if not Config.AutoCreatePad or not self.CoinSet then
            return
        end
        local minX, maxX, minZ, maxZ, minY = math.huge, -math.huge, math.huge, -math.huge, math.huge
        local count = 0
        for coin in self.CoinSet do
            if coin.Parent then
                local p = coin.Position
                minX, maxX = math.min(minX, p.X), math.max(maxX, p.X)
                minZ, maxZ = math.min(minZ, p.Z), math.max(maxZ, p.Z)
                minY = math.min(minY, p.Y)
                count += 1
            end
        end
        if count > 0 then
            self:EnsurePad((minX + maxX) * 0.5, (minZ + maxZ) * 0.5, minY - 4)
        end
    end
    
    -- Lobby pad: top đúng mặt SpawnLocation (Y≈502.07). Tính 1 lần từ
    -- RegularLobby.Spawns rồi cache — tái tạo được kể cả khi lobby đã strip.
    function K:EnsureLobbyPad()
        if not Config.AutoCreatePad then
            return
        end
        if not self.LobbyPadTopY then
            local topY, cx, cz
            safe(function()
                for _, model in workspace:GetChildren() do
                    if model:IsA("Model") then
                        local spawns = model:FindFirstChild("Spawns")
                        if spawns then
                            local minX, maxX = math.huge, -math.huge
                            local minZ, maxZ = math.huge, -math.huge
                            local maxY, n = -math.huge, 0
                            for _, s in spawns:GetChildren() do
                                if s:IsA("BasePart") then
                                    local p = s.Position
                                    minX, maxX = math.min(minX, p.X), math.max(maxX, p.X)
                                    minZ, maxZ = math.min(minZ, p.Z), math.max(maxZ, p.Z)
                                    maxY = math.max(maxY, p.Y + s.Size.Y * 0.5)
                                    n += 1
                                end
                            end
                            if n > 0 and isLobbyY(maxY) then
                                topY = maxY
                                cx, cz = (minX + maxX) * 0.5, (minZ + maxZ) * 0.5
                                break
                            end
                        end
                    end
                end
            end)
            if not topY then
                -- fallback: vị trí nhân vật / spawn CF đã capture
                local _, hrp = getCharacter()
                if hrp and isLobbyY(hrp.Position.Y) then
                    local p = hrp.Position
                    topY, cx, cz = p.Y - 3.1, p.X, p.Z
                elseif self.LobbySpawnCF then
                    local p = self.LobbySpawnCF.Position
                    topY, cx, cz = p.Y - 3.1, p.X, p.Z
                end
            end
            if not topY then
                return
            end
            self.LobbyPadTopY = topY
            self.LobbyPadCX, self.LobbyPadCZ = cx, cz
            self.LobbyStandCF = CFrame.new(cx, topY + 3, cz)
        end
        local pad = ensurePadPart("LobbyPad")
        pad.CFrame = CFrame.new(self.LobbyPadCX, self.LobbyPadTopY - 2, self.LobbyPadCZ)
    end
    
    -- Round cleanup: chỉ bỏ map pad — LobbyPad phải sống qua các round
    function K:RemoveMapPad()
        local folder = workspace:FindFirstChild("KaitunV2Pads")
        local pad = folder and folder:FindFirstChild("Pad")
        if pad then
            safe(function() pad:Destroy() end)
        end
        self.PadTopY = nil
        self.PadStandCF = nil
    end
    
    function K:RemoveAllPads()
        local folder = workspace:FindFirstChild("KaitunV2Pads")
        if folder then
            safe(function() folder:Destroy() end)
        end
        self.PadTopY = nil
        self.PadStandCF = nil
        self.LobbyPadTopY = nil
    end
    
    --═══════════════════════════════ COIN MANAGER ══════════════════════════════
    -- Cache container + coin set nuôi bằng event; KHÔNG GetDescendants mỗi tick.
    
    function K:FindCoinContainer()
        local cc = self.CoinContainer
        if cc and cc.Parent then
            return cc
        end
        self.CoinContainer = nil
        -- CoinContainer là con trực tiếp của map model (verify MCP) → quét nông
        for _, child in workspace:GetChildren() do
            if child:IsA("Model") and child ~= player.Character then
                local found = child:FindFirstChild("CoinContainer")
                if found then
                    self:SetCoinContainer(found)
                    return found
                end
            end
        end
        -- fallback: sâu (map cấu trúc lạ)
        local deep = workspace:FindFirstChild("CoinContainer", true)
        if deep and not isCharacterProtected(deep) then
            self:SetCoinContainer(deep)
        end
        return self.CoinContainer
    end
    
    function K:SetCoinContainer(container)
        if self.CoinContainer == container then
            return
        end
        self.CoinContainer = container
        self.CoinSet = {}
        for _, child in container:GetChildren() do
            if child.Name == "Coin_Server" and child:IsA("BasePart") then
                self.CoinSet[child] = true
            end
        end
        self._maid:Give("round_coinAdded", container.ChildAdded:Connect(function(child)
            if child.Name == "Coin_Server" and child:IsA("BasePart") then
                K.CoinSet[child] = true
                if Config.StripCoinVisuals then
                    task.defer(function()
                        local vis = child:FindFirstChild("CoinVisual")
                        if vis then
                            safe(function() vis:Destroy() end)
                        end
                    end)
                end
            end
        end))
        self._maid:Give("round_coinRemoved", container.ChildRemoved:Connect(function(child)
            K.CoinSet[child] = nil
        end))
        dbg("CoinContainer cached: " .. container:GetFullName())
    end
    
    function K:IsCoinCollectable(coin)
        return coin
            and coin.Parent ~= nil
            and coin:FindFirstChild("TouchInterest") ~= nil
            and not self.Visited[coin]
    end
    
    function K:MatchesCoinType(coin)
        if Config.CoinType == "Any" or not Config.CoinType then
            return true
        end
        local id = coin:GetAttribute("CoinID")
        if id == Config.CoinType then
            return true
        end
        return (id == nil or id == "") and Config.CoinType == "Coin"
    end
    
    -- Coin gần nhất chưa thăm (squared distance — không sqrt trong vòng lặp).
    -- Bỏ qua coin thuộc bag đã đầy (FullBags theo CoinCollected).
    function K:NearestCoin(fromPos)
        local best, bestDist = nil, math.huge
        local coinSet = self.CoinSet
        if not coinSet then
            return nil
        end
        for coin in coinSet do
            if self:IsCoinCollectable(coin) and self:MatchesCoinType(coin) then
                local id = coin:GetAttribute("CoinID")
                if not (id and self.FullBags[id]) then
                    local d = coin.Position - fromPos
                    local dist = d.X * d.X + d.Y * d.Y + d.Z * d.Z
                    if dist < bestDist then
                        best, bestDist = coin, dist
                    end
                end
            end
        end
        return best
    end
    
    function K:CountCollectableCoins()
        local n = 0
        if self.CoinSet then
            for coin in self.CoinSet do
                if self:IsCoinCollectable(coin) then
                    n += 1
                end
            end
        end
        return n
    end
    
    -- Chờ TouchInterest xuất hiện (event + poll thưa) — server gắn sau replicate
    function K:WaitForTouchInterest(token)
        local deadline = os.clock() + (Config.TouchInterestWait or 8)
        while os.clock() < deadline and token == self._roundToken and self.CoinsActive do
            if self:FindCoinContainer() and self:CountCollectableCoins() > 0 then
                return true
            end
            task.wait(0.25)
        end
        return self:CountCollectableCoins() > 0
    end
    
    --═════════════════════════════════ COLLECT ═════════════════════════════════
    
    function K:GetCollectPosition(coin, hrp)
        if Exec.fireTouch then
            -- có firetouchinterest → đứng dưới coin (đỡ khuất camera)
            local hrpHalf = ((hrp and hrp.Size.Y) or 2) * 0.5
            local y = coin.Position.Y - coin.Size.Y * 0.5 - hrpHalf - (Config.CoinBelowOffset or 2.5)
            return Vector3.new(coin.Position.X, y, coin.Position.Z)
        end
        -- không có → phải overlap thật để server Touched tự bắn
        return coin.Position
    end
    
    function K:CollectCoin(coin, hrp)
        if not self:IsCoinCollectable(coin) then
            return false
        end
        if Exec.fireTouch then
            safe(function()
                Exec.fireTouch(hrp, coin, 0)
                task.wait(Config.CollectTouchDelay or 0.05)
                Exec.fireTouch(hrp, coin, 1)
            end)
        end
        -- game validate server-side qua GetCoin(coinId)
        local coinId = coin:GetAttribute("CoinID")
        if type(coinId) == "string" and coinId ~= "" and Remotes.GetCoin then
            safe(function()
                Remotes.GetCoin:FireServer(coinId)
            end)
        end
        task.wait(Config.CollectSettleDelay or 0.08)
        -- coin biến mất / mất TouchInterest = server nhận
        if not coin.Parent or not coin:FindFirstChild("TouchInterest") then
            self.Visited[coin] = true
            self.Stats.collected += 1
            return true
        end
        -- chưa ăn được (murderer gần? lag?) — đánh dấu để không kẹt 1 coin
        self.Visited[coin] = true
        return false
    end
    
    --════════════════════════════════ FARM LOOP ════════════════════════════════
    
    function K:StartFarm()
        if self.Running or not Config.Enabled then
            return
        end
        if self.AwaitNextRound or not self.CoinsActive or not self:IsAliveInRound() then
            return
        end
        local container = self:FindCoinContainer()
        if not container then
            return
        end
        self.Running = true
        self.BagFull = false
        local token = self._roundToken
    
        self:FreezeCharacter()
        self:MinimizeCharacter()
    
        -- pad dưới tâm cụm coin (chống rơi void ở 10 FPS)
        self:SyncPadToCoins()
    
        log(string.format("Farm start — role=%s coins=%d", tostring(self:GetRole()), self:CountCollectableCoins()))
    
        self._maid:Give("round_farmLoop", task.spawn(function()
            local idleSince = nil
            while K.Running and token == K._roundToken do
                if not K:IsAliveInRound() then
                    task.wait(0.5)
                    continue
                end
                if K.BagFull then
                    K:OnBagFull()
                    break
                end
                local _, hrp = getCharacter()
                if not hrp then
                    task.wait(0.5)
                    continue
                end
                local coin = K:NearestCoin((K.LastFarmCF and K.LastFarmCF.Position) or hrp.Position)
                if not coin then
                    -- hết coin nhìn thấy: coin respawn theo đợt → đợi ngắn,
                    -- reset visited nếu lâu quá (coin cũ có thể mọc TouchInterest lại)
                    idleSince = idleSince or os.clock()
                    if os.clock() - idleSince > 5 then
                        K.Visited = setmetatable({}, { __mode = "k" })
                        idleSince = os.clock()
                    end
                    task.wait(0.4)
                    continue
                end
                idleSince = nil
                if K:TweenTo(K:GetCollectPosition(coin, hrp), token) then
                    K:CollectCoin(coin, hrp)
                end
                task.wait(Config.CoinCycleDelay or 0.02)
            end
        end))
    end
    
    function K:StopFarm()
        self.Running = false
        self.IsTweening = false
        self.LastFarmCF = nil
        self._maid:Clean("round_farmLoop")
    end
    
    function K:OnBagFull()
        log(string.format("Bag full (%d/%d) — collected %d total",
            self.Stats.bagCurrent, self.Stats.bagMax, self.Stats.collected))
        self:StopFarm()
        if Config.ResetWhenFull then
            -- reset → respawn lobby → AwaitNextRound chặn farm tới round sau
            self.AwaitNextRound = true
            safe(function()
                local _, _, hum = getCharacter()
                if hum then
                    hum.Health = 0
                end
            end)
        end
    end
    
    --═══════════════════════════════ STATE MACHINE ═════════════════════════════
    
    function K:SetPhase(phase, why)
        if self.Phase == phase then
            return
        end
        dbg(string.format("Phase %s -> %s (%s)", self.Phase, phase, why or "?"))
        self.Phase = phase
        self:UpdateHud()
    end
    
    -- Dọn toàn bộ tài nguyên round (connections, farm, pad, coin cache)
    function K:CleanupRound()
        self._roundToken += 1
        self:StopFarm()
        self._maid:CleanPrefix("round_")
        self.CoinContainer = nil
        self.CoinSet = nil
        self.Visited = setmetatable({}, { __mode = "k" })
        self.FullBags = {}
        self.BagFull = false
        self:RemoveMapPad()
    end
    
    -- LoadingMap: map đã vote, còn ~11s Ở LOBBY trước khi TeleportToPart
    function K:OnLoadingMap(mapName)
        self:CleanupRound()
        self.CoinsActive = false
        self.TeleportSeen = false
        self.LoadingMapAt = os.clock()
        self.AwaitNextRound = false -- round MỚI → mở lại farm
        self.ExpectedMapName = (type(mapName) == "string" and mapName ~= "") and mapName or nil
        self:SetPhase(PHASE.LOADING, "LoadingMap")
        self:UnfreezeCharacter()
        self:EnsureCharacterClient()
        self:CaptureLobbySpawn()
        self:ArmMapStripper()
        self:ApplyRemoteHandlerFilter() -- pass 2 (game script đã connect xong)
        if Config.MuteSounds then
            task.defer(function() self:MuteSounds() end)
        end
    end
    
    -- RoundStart: chỉ refresh loading; KHÔNG đè round đang farm (fires sau
    -- CoinsStarted trong một số edge case)
    function K:OnRoundStart()
        if self.CoinsActive or self.Running then
            return
        end
        if self.Phase ~= PHASE.LOADING then
            self:SetPhase(PHASE.LOADING, "RoundStart")
            self:ArmMapStripper()
        end
    end
    
    function K:OnTeleportToPart(spawnPart)
        self.TeleportSeen = true
        -- CharacterClient PivotTo — mình không đụng vào vị trí lúc này.
        -- NHƯNG map đã bị strip → đặt ngay map pad dưới spawn part để nhân vật
        -- có sàn đáp trong lúc chờ CoinsStarted (window rơi void trước đây).
        if typeof(spawnPart) == "Instance" and spawnPart:IsA("BasePart") then
            dbg("TeleportToPart -> " .. spawnPart:GetFullName())
            local p = spawnPart.Position
            self:EnsurePad(p.X, p.Z, p.Y - 3)
        end
    end
    
    -- CoinsStarted: sự thật duy nhất để farm. args = bag visibility table.
    function K:OnCoinsStarted(bags)
        -- round mới mà farm cũ còn chạy (miss round end + LoadingMap) → dọn trước
        if self.Running then
            self:CleanupRound()
        end
        self.CoinsActive = true
        self.RoundStartedAt = os.clock()
        self.Stats.rounds += 1
        self.Stats.bagCurrent = 0
        self.FullBags = {}
        self:SetPhase(PHASE.ROUND, "CoinsStarted")
        if type(bags) == "table" then
            local names = {}
            for name in bags do
                table.insert(names, tostring(name))
            end
            dbg("Bags: " .. table.concat(names, ", "))
        end
        if self.AwaitNextRound then
            -- chết round trước & CoinsStarted bắn khi mình ở lobby → không farm
            dbg("CoinsStarted while AwaitNextRound — skip farm")
            return
        end
        if not Config.Enabled or not Config.AutoStart then
            return
        end
        local token = self._roundToken
        self._maid:Give("round_startFarm", task.spawn(function()
            if not K:WaitForTouchInterest(token) then
                dbg("No TouchInterest coins within timeout")
            end
            local deadline = os.clock() + (Config.RoundReadyTimeout or 45)
            while token == K._roundToken and K.CoinsActive and os.clock() < deadline do
                if K.Running then
                    return
                end
                if K:IsAliveInRound() and K:CountCollectableCoins() > 0 then
                    K:StartFarm()
                    if K.Running then
                        return
                    end
                end
                task.wait(0.35)
            end
        end))
    end
    
    function K:OnCoinCollected(coinType, current, max)
        current, max = tonumber(current), tonumber(max)
        if current then
            self.Stats.bagCurrent = current
        end
        if max then
            self.Stats.bagMax = max
        end
        if current and max and max > 0 and current >= max then
            if type(coinType) == "string" then
                self.FullBags[coinType] = true
            end
            -- Full khi: đang farm loại đó ("Any" = full là full)
            if Config.CoinType == "Any" or Config.CoinType == coinType then
                self.BagFull = true
            end
        end
        self:UpdateHud()
    end
    
    function K:OnRoundEnded(why)
        self:CleanupRound()
        self.CoinsActive = false
        self.TeleportSeen = false
        self.LoadingMapAt = nil
        self.RoundStartedAt = nil
        self.ExpectedMapName = nil
        self.AwaitNextRound = false
        self:SetPhase(PHASE.LOBBY, why)
        self:UnfreezeCharacter()
        self:CaptureLobbySpawn()
        self:EnsureLobbyPad()
        log(string.format("Round end (%s) — total collected: %d", why, self.Stats.collected))
    end
    
    function K:OnDied()
        self:StopFarm()
        self.AwaitNextRound = true
        self.CharacterFrozen = false
        self:SetPhase(PHASE.DEAD, "Humanoid.Died")
    end
    
    function K:CaptureLobbySpawn()
        local _, hrp = getCharacter()
        if hrp and isLobbyY(hrp.Position.Y) then
            self.LobbySpawnCF = hrp.CFrame
        end
    end
    
    -- Inject giữa round: map + coin đã có sẵn → vào ROUND luôn
    function K:SyncMidRound()
        if self.CoinsActive then
            return
        end
        local container = self:FindCoinContainer()
        if not container then
            return
        end
        if self:CountCollectableCoins() > 0 and self:IsAliveInRound() then
            log("Mid-round inject detected — starting farm")
            self:OnCoinsStarted(nil)
        end
    end
    
    --═══════════════════════════════ HEARTBEAT HUB ═════════════════════════════
    -- Đúng 1 Heartbeat connection: destroy pump + farm hold + void rescue.
    -- Việc nhẹ throttle bằng accumulator, không tạo thêm connection.
    
    function K:StartHeartbeat()
        local rescueAccum = 0
        self._maid:Give("heartbeat", RunService.Heartbeat:Connect(function(dt)
            -- 1) xả destroy queue theo budget
            if #K.DestroyQueue > 0 then
                K:PumpDestroyQueue()
            end
    
            -- 2) farm hold: giữ vị trí giữa các tween (chống trôi/rớt)
            if K.Running and not K.IsTweening and K.LastFarmCF then
                local _, hrp = getCharacter()
                if hrp then
                    if (hrp.Position - K.LastFarmCF.Position).Magnitude > 0.5 then
                        safe(function()
                            player.Character:PivotTo(K.LastFarmCF)
                        end)
                    end
                    K:ZeroVelocity(hrp)
                end
            end
    
            -- 3) void rescue (throttle 0.25s) — backstop, pad vật lý mới là sàn chính
            rescueAccum += dt
            if rescueAccum >= 0.25 then
                rescueAccum = 0
                local _, hrp, hum = getCharacter()
                if hrp and hum and hum.Health > 0 then
                    local y = hrp.Position.Y
                    local below = Config.VoidRescueBelowY or 15
                    if K.Running then
                        -- đang farm: tween/hold tự quản, chỉ kéo về khi lọt pad
                        if K.PadTopY and K.LastFarmCF and y < K.PadTopY - below then
                            K:ApplyCF(K.LastFarmCF)
                        end
                    elseif K.PadTopY and K.PadStandCF then
                        -- có map pad (sau TeleportToPart, trước/giữa farm)
                        if y < K.PadTopY - below then
                            K:ZeroVelocity(hrp)
                            safe(function()
                                player.Character:PivotTo(K.PadStandCF)
                            end)
                        end
                    elseif K.Phase ~= PHASE.ROUND and not (K.Phase == PHASE.LOADING and K.TeleportSeen) then
                        -- ở lobby (lobby/dead/boot/loading-chưa-teleport): chỉ
                        -- rescue khi ĐANG RƠI thật (vel.Y âm) — không giật nhân
                        -- vật đang đứng yên nơi khác
                        local standCF = K.LobbySpawnCF or K.LobbyStandCF
                        local topY = K.LobbyPadTopY or (standCF and standCF.Position.Y - 3.1)
                        if standCF and topY and y < topY - below
                            and hrp.AssemblyLinearVelocity.Y < -10
                        then
                            K:EnsureLobbyPad()
                            K:ZeroVelocity(hrp)
                            safe(function()
                                player.Character:PivotTo(standCF)
                            end)
                        end
                    end
                end
            end
        end))
    end
    
    --════════════════════════════════ WATCHDOG ═════════════════════════════════
    -- Poll thưa (5s) bắt các case remote miss: round treo, farm chưa nổ, v.v.
    
    function K:StartWatchdog()
        self._maid:Give("watchdog", task.spawn(function()
            while not K.Destroyed do
                task.wait(5)
                safe(function()
                    -- round quá lâu không có end event → coi như về lobby
                    if K.CoinsActive and K.RoundStartedAt
                        and os.clock() - K.RoundStartedAt > (Config.RoundMaxDuration or 400)
                    then
                        log("Watchdog: round timeout — force lobby state")
                        K:OnRoundEnded("watchdog-timeout")
                        return
                    end
                    -- CoinsActive mà farm chưa chạy (miss event / respawn kỳ lạ)
                    if K.CoinsActive and not K.Running and not K.AwaitNextRound
                        and Config.Enabled and Config.AutoStart and K:IsAliveInRound()
                        and K:CountCollectableCoins() > 0
                    then
                        K:StartFarm()
                    end
                    -- đứng lobby lâu mà thực ra map đang có coin (miss CoinsStarted)
                    if K.Phase == PHASE.LOBBY and not K.CoinsActive then
                        local _, hrp = getCharacter()
                        if hrp and not isLobbyY(hrp.Position.Y) then
                            K:SyncMidRound()
                        end
                    end
                    K:EnsureCharacterClient()
                end)
            end
        end))
    end
    
    --═══════════════════════════════════ BOOT ══════════════════════════════════
    -- Acc mới / mobile: game bắt chọn device rồi mới clone MainGUI + báo server.
    -- Mirror flow của ReplicatedFirst.UISelector.Loading (gọn).
    
    function K:GetDeviceChoice()
        if Config.AutoDevice == "Phone" or Config.AutoDevice == "Tablet" or Config.AutoDevice == "PC" then
            return Config.AutoDevice
        end
        local touch = false
        safe(function()
            touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        end)
        return touch and "Phone" or "PC"
    end
    
    function K:InstallMainGui(device)
        local pg = player:WaitForChild("PlayerGui", 10)
        if not pg or pg:FindFirstChild("MainGUI") then
            return pg ~= nil
        end
        local templateName = "MainPC"
        safe(function()
            if GuiService:IsTenFootInterface() then
                templateName = "MainXbox"
            elseif device == "Phone" or device == "Tablet" then
                templateName = "MainMobile"
            end
        end)
        local ok = false
        safe(function()
            local guiRoot = ReplicatedStorage:FindFirstChild("GUI")
            local template = guiRoot and guiRoot:FindFirstChild(templateName)
            if not template then
                template = ReplicatedStorage:FindFirstChild("MainGUI")
            end
            if template then
                local clone = template:Clone()
                clone.Name = "MainGUI"
                clone.Parent = pg
                ok = true
            end
        end)
        return ok
    end
    
    function K:CompleteBootIfNeeded()
        if not Config.AutoSelectDevice then
            return false
        end
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then
            return false
        end
        local deviceSelect = pg:FindFirstChild("DeviceSelect")
        local hasMain = pg:FindFirstChild("MainGUI") ~= nil
        if not deviceSelect and hasMain then
            return true
        end
        if not deviceSelect then
            return false
        end
        local device = self:GetDeviceChoice()
        if device == "PC" then
            device = "Phone" -- DeviceSelect chỉ hiện trên touch client
        end
        pg:SetAttribute("Device", device)
        _G.MobileDevice = device
        safe(function()
            Remotes.Extras:WaitForChild("ChangeLastDevice", 5):FireServer(device)
        end)
        if not hasMain then
            self:InstallMainGui(device)
        end
        -- dọn màn boot + báo server load xong
        for _, name in { "DeviceSelect", "JoinPhone", "Join", "Join_Old", "Loading" } do
            local inst = pg:FindFirstChild(name)
            if inst then
                safe(function() inst:Destroy() end)
            end
        end
        safe(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)
        safe(function()
            Remotes.Extras:WaitForChild("LoadedCompletely", 5):FireServer()
        end)
        log("Boot completed (device=" .. device .. ")")
        return true
    end
    
    function K:WaitForGameReady()
        if not Config.WaitForGameReady then
            self.GameReady = true
            return true
        end
        local deadline = os.clock() + (Config.GameReadyTimeout or 120)
        -- event: DeviceSelect xuất hiện muộn → xử lý ngay
        safe(function()
            local pg = player:WaitForChild("PlayerGui", 15)
            if pg then
                self._maid:Give("bootWatcher", pg.ChildAdded:Connect(function(child)
                    if K.GameReady then
                        return
                    end
                    if child.Name == "DeviceSelect" then
                        task.defer(function()
                            task.wait(0.5)
                            K:CompleteBootIfNeeded()
                        end)
                    end
                end))
            end
        end)
        while os.clock() < deadline and not self.Destroyed do
            local pg = player:FindFirstChild("PlayerGui")
            if pg then
                self:CompleteBootIfNeeded()
                local main = pg:FindFirstChild("MainGUI")
                local ds = pg:FindFirstChild("DeviceSelect")
                local loading = pg:FindFirstChild("Loading")
                local dsBlocking = ds and ds:IsA("ScreenGui") and ds.Enabled
                local loadBlocking = loading and loading:IsA("ScreenGui") and loading.Enabled
                if main and not dsBlocking and not loadBlocking then
                    if not pg:GetAttribute("Device") then
                        pg:SetAttribute("Device", self:GetDeviceChoice())
                    end
                    self.GameReady = true
                    self._maid:Clean("bootWatcher")
                    return true
                end
            end
            task.wait(0.5)
        end
        self.GameReady = true -- timeout: cứ chạy tiếp, watchdog lo phần còn lại
        self._maid:Clean("bootWatcher")
        return false
    end
    
    --════════════════════════════════════ HUD ══════════════════════════════════
    
    function K:EnsureHud()
        if not Config.ShowHud or self.HudLabel then
            return
        end
        local parent = player:FindFirstChild("PlayerGui")
        if Exec.getHui then
            local ok, hui = pcall(Exec.getHui)
            if ok and hui then
                parent = hui
            end
        end
        if not parent then
            return
        end
        local gui = Instance.new("ScreenGui")
        gui.Name = "KaitunV2Hud"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 10000
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromOffset(220, 58)
        label.Position = UDim2.new(0.5, -110, 0, 8)
        label.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
        label.BackgroundTransparency = 0.3
        label.TextColor3 = Color3.fromRGB(180, 255, 190)
        label.TextSize = 13
        label.Font = Enum.Font.Code
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.Text = "Kaitun V2"
        label.Parent = gui
        safe(function()
            Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)
        end)
        gui.Parent = parent
        self.Hud = gui
        self.HudLabel = label
        self._maid:Give("hudGui", gui)
        self._maid:Give("hudLoop", task.spawn(function()
            while not K.Destroyed do
                K:UpdateHud()
                task.wait(Config.HudUpdateInterval or 1)
            end
        end))
    end
    
    function K:UpdateHud()
        local label = self.HudLabel
        if not label or not label.Parent then
            return
        end
        safe(function()
            label.Text = string.format(
                " [KaitunV2] %s%s | %s\n bag %d/%d | coins %d (%.0f/m)\n rounds %d | %s",
                self.Phase,
                self.Running and ":farm" or "",
                tostring(self:GetRole() or "-"),
                self.Stats.bagCurrent, self.Stats.bagMax,
                self:GetInventoryCoins(), self:GetInventoryCoinRate(),
                self.Stats.rounds,
                self.AwaitNextRound and "wait next" or "ok"
            )
        end)
    end
    
    --═════════════════════════════ SYSTEM / SAFETY ═════════════════════════════
    
    function K:ApplyFpsCap()
        if not Config.LockFps then
            return
        end
        local fps = math.floor(tonumber(Config.FpsCap) or 0)
        if fps < 1 then
            return
        end
        if Exec.setFps then
            if safe(function() Exec.setFps(fps) end) then
                log("FPS capped at " .. fps)
            end
        else
            dbg("No setfpscap API on this executor")
        end
    end
    
    function K:StartAntiAfk()
        if not Config.AntiAfk then
            return
        end
        self._maid:Give("antiAfk", player.Idled:Connect(function()
            safe(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end))
    end
    
    -- Auto-rejoin khi disconnect: queue script (nếu có url) rồi teleport lại place
    function K:ArmAutoRejoin()
        if not Config.AutoRejoin then
            return
        end
        local function queueSelf()
            if Exec.queueTeleport and type(Config.RejoinScriptUrl) == "string" and Config.RejoinScriptUrl ~= "" then
                safe(function()
                    Exec.queueTeleport(string.format(
                        'getgenv().MM2KaitunV2Config = %s loadstring(game:HttpGet(%q))()',
                        "{}", Config.RejoinScriptUrl
                    ))
                end)
            end
        end
        self._maid:Give("rejoin", GuiService.ErrorMessageChanged:Connect(function(msg)
            if K.Destroyed or type(msg) ~= "string" or msg == "" then
                return
            end
            log("Disconnected (" .. msg .. ") — rejoining...")
            queueSelf()
            safe(function()
                TeleportService:Teleport(game.PlaceId, player)
            end)
            task.delay(10, function()
                if not K.Destroyed then
                    safe(function()
                        TeleportService:Teleport(game.PlaceId, player)
                    end)
                end
            end)
        end))
        self._maid:Give("teleportInit", player.OnTeleport:Connect(function(state)
            if state == Enum.TeleportState.Started then
                queueSelf()
            end
        end))
    end
    
    --════════════════════════════ CHARACTER BINDING ════════════════════════════
    
    function K:BindCharacter(char)
        self.CharacterFrozen = false
        local token = self._roundToken
        task.defer(function()
            local hrp = char:WaitForChild("HumanoidRootPart", 15)
            local hum = char:WaitForChild("Humanoid", 10)
            if hum then
                self._maid:Give("charDied", hum.Died:Connect(function()
                    K:OnDied()
                end))
            end
            if not hrp then
                return
            end
            self:EnsureCharacterClient()
            self:MinimizeCharacter()
            task.wait(0.2)
            if isLobbyY(hrp.Position.Y) then
                -- respawn về lobby (sau chết / round end)
                if self.Phase == PHASE.DEAD then
                    self:SetPhase(PHASE.LOBBY, "respawn-lobby")
                end
                self:CaptureLobbySpawn()
                self:EnsureLobbyPad()
            elseif self.CoinsActive and not self.AwaitNextRound and token == self._roundToken then
                -- respawn giữa round còn sống (hiếm) → farm tiếp
                self:StartFarm()
            end
        end)
    end
    
    --═══════════════════════════════ REMOTE WIRING ═════════════════════════════
    
    function K:ConnectRemotes()
        if not resolveRemotes() then
            log("WARNING: remotes not resolved — retrying in background")
            self._maid:Give("remoteRetry", task.spawn(function()
                while not K.Destroyed and not resolveRemotes() do
                    task.wait(2)
                end
                if not K.Destroyed then
                    K:ConnectRemotes()
                end
            end))
            return
        end
        self._maid:Clean("remoteRetry")
    
        self._maid:Give("rLoadingMap", Remotes.LoadingMap.OnClientEvent:Connect(function(mapName)
            safe(function() K:OnLoadingMap(mapName) end)
        end))
        self._maid:Give("rRoundStart", Remotes.RoundStart.OnClientEvent:Connect(function()
            safe(function() K:OnRoundStart() end)
        end))
        self._maid:Give("rCoinsStarted", Remotes.CoinsStarted.OnClientEvent:Connect(function(bags)
            safe(function() K:OnCoinsStarted(bags) end)
        end))
        self._maid:Give("rCoinCollected", Remotes.CoinCollected.OnClientEvent:Connect(function(coinType, current, max)
            safe(function() K:OnCoinCollected(coinType, current, max) end)
        end))
        self._maid:Give("rVictory", Remotes.VictoryScreen.OnClientEvent:Connect(function()
            safe(function() K:OnRoundEnded("VictoryScreen") end)
        end))
        self._maid:Give("rEndFade", Remotes.RoundEndFade.OnClientEvent:Connect(function()
            safe(function() K:OnRoundEnded("RoundEndFade") end)
        end))
        if Remotes.TeleportToPart
            and (Remotes.TeleportToPart:IsA("RemoteEvent") or Remotes.TeleportToPart:IsA("UnreliableRemoteEvent"))
        then
            self._maid:Give("rTeleport", Remotes.TeleportToPart.OnClientEvent:Connect(function(spawnPart)
                safe(function() K:OnTeleportToPart(spawnPart) end)
            end))
        end
        dbg("Remotes connected")
    end
    
    --═════════════════════════════════ DESTROY ═════════════════════════════════
    
    function K:Destroy(why)
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        self:StopFarm()
        self._maid:DestroyAll()
        self:RestoreRemoteHandlerFilter()
        self:RemoveAllPads()
        self:UnfreezeCharacter()
        safe(function()
            if Config.Disable3DRender then
                RunService:Set3dRenderingEnabled(true)
            end
        end)
        if G.MM2KaitunV2 == self then
            G.MM2KaitunV2 = nil
        end
        log("Destroyed (" .. tostring(why or "manual") .. ")")
    end
    
    --══════════════════════════════ SUMMER 2026 EVENT ═══════════════════════════
    -- MCP-verified: currency SummerKey2026 ("Shells"), box Summer2026Box,
    -- remotes ReplicatedStorage.Remotes.Events.Summer2026Remotes.*
    -- Shop unbox: OpenCrate:InvokeServer(boxId, "MysteryBox", currencyId)
    
    local Summer2026 = {
        _ready = false,
        _warnedInactive = false,
        _eventRemotes = nil,
        _shopRemotes = nil,
        _eventInfo = nil,
        _questsConfig = nil,
        _boxPrice = nil,
    }
    
    local SUMMER_QUEST_FALLBACK = {
        Rewards = { 1, 6, 12, 20 },
        Daily = { 60, 120, 240, 480 },
        Weekly = { 6, 18, 26 },
    }
    
    local function summerPrint(msg)
        print("[KaitunV2][Summer2026] " .. tostring(msg))
    end
    
    local function summerGetProfile(self)
        local pd = self.ProfileData or self:TryRequireProfileData()
        if pd then
            self.ProfileData = pd
        end
        return pd
    end
    
    function K:Summer2026Resolve()
        if Summer2026._ready then
            return true
        end
        if not Config.EnableSummer2026 then
            return false
        end
    
        local events = ReplicatedStorage:FindFirstChild("Remotes")
        events = events and events:FindFirstChild("Events")
        local remotes = events and events:FindFirstChild(Config.Summer2026EventTitle .. "Remotes")
        if not remotes then
            if not Summer2026._warnedInactive then
                summerPrint("event remotes missing — skip (event not live?)")
                Summer2026._warnedInactive = true
            end
            return false
        end
    
        local shop = ReplicatedStorage:FindFirstChild("Remotes")
        shop = shop and shop:FindFirstChild("Shop")
        if not shop or not shop:FindFirstChild("OpenCrate") then
            return false
        end
    
        Summer2026._eventRemotes = remotes
        Summer2026._shopRemotes = shop
    
        safe(function()
            local sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
            local entry = sync.NewShop[Config.Summer2026BoxId]
            if entry and entry.Price then
                Summer2026._boxPrice = entry.Price[Config.Summer2026KeyCurrency]
                    or entry.Price.Shells
            end
        end)
        if not Summer2026._boxPrice or Summer2026._boxPrice <= 0 then
            Summer2026._boxPrice = 1
        end
    
        safe(function()
            local eis = require(ReplicatedStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))
            eis:WaitForInitializedAsync()
            local main = eis:GetMainEvent()
            if main and main.Title == Config.Summer2026EventTitle then
                Summer2026._eventInfo = main
                if main.EventStartInfo and main.EventStartInfo.Quests then
                    Summer2026._questsConfig = main.EventStartInfo.Quests
                end
            end
        end)
    
        Summer2026._ready = true
        summerPrint(string.format(
            "ready — box=%s shells>=%s",
            Config.Summer2026BoxId,
            Config.MinShellsForBox > 0 and Config.MinShellsForBox or Summer2026._boxPrice
        ))
        return true
    end
    
    function K:Summer2026GetShells()
        local pd = summerGetProfile(self)
        if not pd or not pd.Materials or not pd.Materials.Owned then
            return 0
        end
        return pd.Materials.Owned[Config.Summer2026KeyCurrency] or 0
    end
    
    function K:Summer2026GetBoxPrice()
        if Config.MinShellsForBox and Config.MinShellsForBox > 0 then
            return Config.MinShellsForBox
        end
        return Summer2026._boxPrice or 1
    end
    
    function K:Summer2026GetQuestTiers(trackId)
        local cfg = Summer2026._questsConfig
        if cfg and cfg[trackId] and cfg[trackId].Quests then
            local tiers = {}
            for i, q in cfg[trackId].Quests do
                tiers[i] = q.ChallengeAmount
            end
            return tiers
        end
        return SUMMER_QUEST_FALLBACK[trackId]
    end
    
    function K:Summer2026IsQuestTierClaimed(eventData, trackId, tierIndex, progress, challengeAmount)
        if type(eventData) ~= "table" then
            return progress < challengeAmount
        end
        local quests = eventData.Quests
        local track = quests and quests[trackId]
        if type(track) ~= "table" then
            return progress < challengeAmount
        end
        local claimed = track.Claimed
        if type(claimed) == "table" then
            return claimed[tierIndex] == true or claimed[tostring(tierIndex)] == true
        end
        if track.ClaimedRewards and type(track.ClaimedRewards) == "table" then
            return track.ClaimedRewards[tierIndex] == true or track.ClaimedRewards[tostring(tierIndex)] == true
        end
        return progress < challengeAmount
    end
    
    function K:Summer2026ClaimQuests()
        if not self:Summer2026Resolve() then
            return 0
        end
        local pd = summerGetProfile(self)
        if not pd then
            return 0
        end
    
        local eventData = pd[Config.Summer2026EventTitle]
        if type(eventData) ~= "table" then
            eventData = { Quests = {} }
        end
        eventData.Quests = eventData.Quests or {}
    
        local remotes = Summer2026._eventRemotes
        local claimRemote = remotes:FindFirstChild("ClaimEventQuestReward")
            or remotes:FindFirstChild("ClaimQuestReward")
            or remotes:FindFirstChild("ClaimEventQuest")
        local claimed = 0
    
        for _, trackId in { "Rewards", "Daily", "Weekly" } do
            local tiers = self:Summer2026GetQuestTiers(trackId)
            if not tiers then
                continue
            end
            local trackData = eventData.Quests[trackId]
            local progress = type(trackData) == "table" and (trackData.Progress or 0) or 0
    
            for tierIndex, challengeAmount in tiers do
                if progress >= challengeAmount
                    and not self:Summer2026IsQuestTierClaimed(eventData, trackId, tierIndex, progress, challengeAmount)
                then
                    if claimRemote and claimRemote:IsA("RemoteEvent") then
                        local ok = pcall(function()
                            claimRemote:FireServer(trackId, tierIndex)
                        end)
                        if ok then
                            claimed += 1
                            summerPrint(string.format("claim quest %s tier %s (progress %d/%d)", trackId, tierIndex, progress, challengeAmount))
                        end
                    else
                        dbg(string.format(
                            "quest %s tier %s ready (%d/%d) — no claim remote (server may auto-grant)",
                            trackId, tierIndex, progress, challengeAmount
                        ))
                    end
                end
            end
        end
    
        return claimed
    end
    
    function K:Summer2026ClaimBattlePass()
        if not Config.Summer2026ClaimBattlePass or not self:Summer2026Resolve() then
            return 0
        end
        local pd = summerGetProfile(self)
        if not pd then
            return 0
        end
    
        local eventData = pd[Config.Summer2026EventTitle]
        if type(eventData) ~= "table" then
            return 0
        end
    
        local remotes = Summer2026._eventRemotes
        local claimRemote = remotes:FindFirstChild("ClaimBattlePassReward")
        if not claimRemote or not claimRemote:IsA("RemoteEvent") then
            return 0
        end
    
        local currentTier = tonumber(eventData.CurrentTier) or 0
        eventData.ClaimedRewards = eventData.ClaimedRewards or {}
        local claimed = 0
    
        local total = 25
        if Summer2026._eventInfo
            and Summer2026._eventInfo.EventStartInfo
            and Summer2026._eventInfo.EventStartInfo.BattlePass
        then
            total = Summer2026._eventInfo.EventStartInfo.BattlePass.TotalTiers or total
        end
    
        for i = 1, total do
            local key = tostring(i)
            if i <= currentTier
                and eventData.ClaimedRewards[key] ~= true
                and eventData.ClaimedRewards[i] ~= true
            then
                local ok = pcall(function()
                    claimRemote:FireServer(key)
                end)
                if ok then
                    claimed += 1
                    summerPrint("claim battle pass tier " .. key)
                end
            end
        end
    
        return claimed
    end
    
    function K:Summer2026BuyAndOpenBox()
        if not Config.Summer2026AutoUnbox or not self:Summer2026Resolve() then
            return false
        end
    
        local price = self:Summer2026GetBoxPrice()
        local shells = self:Summer2026GetShells()
        if shells < price then
            return false
        end
    
        local shop = Summer2026._shopRemotes
        local openCrate = shop:FindFirstChild("OpenCrate")
        local crateComplete = shop:FindFirstChild("CrateComplete")
        if not openCrate or not openCrate:IsA("RemoteFunction") then
            return false
        end
    
        local rewardId
        local okOpen = pcall(function()
            rewardId = openCrate:InvokeServer(
                Config.Summer2026BoxId,
                "MysteryBox",
                Config.Summer2026KeyCurrency
            )
        end)
        if not okOpen or not rewardId then
            summerPrint("OpenCrate failed for " .. Config.Summer2026BoxId)
            return false
        end
    
        summerPrint(string.format(
            "opened %s (-%d shells, reward=%s)",
            Config.Summer2026BoxId,
            price,
            tostring(rewardId)
        ))
    
        if crateComplete and crateComplete:IsA("RemoteEvent") then
            pcall(function()
                crateComplete:FireServer(rewardId)
            end)
        end
        return true
    end
    
    function K:Summer2026Tick()
        if not Config.EnableSummer2026 or self.Destroyed then
            return
        end
        if not self:Summer2026Resolve() then
            return
        end
    
        local questClaims = self:Summer2026ClaimQuests()
        local bpClaims = self:Summer2026ClaimBattlePass()
        if questClaims > 0 or bpClaims > 0 then
            summerPrint(string.format("claimed quest=%d battlepass=%d", questClaims, bpClaims))
        end
    
        self:Summer2026BuyAndOpenBox()
    end
    
    function K:StartSummer2026()
        if not Config.EnableSummer2026 then
            return
        end
        self._maid:Give("summer2026Loop", task.spawn(function()
            task.wait(5)
            while not self.Destroyed do
                safe(function()
                    self:Summer2026Tick()
                end)
                task.wait(math.max(5, Config.Summer2026Interval or 15))
            end
        end))
    end
    
    --═══════════════════════════════════ INIT ══════════════════════════════════
    
    do
        log(string.format("Kaitun V2 %s loading (exec=%s, fireTouch=%s)",
            K.Version,
            Exec.identify ~= "" and Exec.identify or "unknown",
            Exec.fireTouch and "yes" or "NO — dùng overlap thật"))
    
        -- FallenPartsDestroyHeight = NaN (verify Studio) → rơi void không bao giờ
        -- chết. Set giá trị hữu hạn = lưới cuối: lọt hết mọi pad thì chết +
        -- respawn lobby thay vì rơi vĩnh viễn. (client-set, chỉ ảnh hưởng local)
        if Config.FixFallenPartsHeight then
            safe(function()
                local h = workspace.FallenPartsDestroyHeight
                if h ~= h or h < -100000 then -- NaN hoặc giá trị vô lý
                    workspace.FallenPartsDestroyHeight = -500
                end
            end)
        end
    
        K:ApplyFpsCap()
        K:StartHeartbeat()
        K:InitProfileData()
        -- INSTANT OPT: vừa execute là opt luôn — không chờ boot/lobby/round.
        -- (Heartbeat hub đã chạy → destroy pump sẵn sàng xả queue.)
        if Config.InstantOpt then
            K:ApplyEarlyOpt()
        end
        -- resolveRemotes có WaitForChild — chạy async để không chặn init
        K._maid:Give("connectRemotes", task.spawn(function()
            K:ConnectRemotes()
        end))
        K:ArmAutoRejoin()
    
        if player.Character then
            K:BindCharacter(player.Character)
        end
        K._maid:Give("charAdded", player.CharacterAdded:Connect(function(char)
            safe(function() K:BindCharacter(char) end)
        end))
    
        K._maid:Give("mainThread", task.spawn(function()
            -- boot trước (mobile/acc mới), rồi optimization, rồi sync mid-round
            K:WaitForGameReady()
            K:EnsureHud()
            K:InitPlayerData()
            K:InitProfileData()
            K:ApplyOptimizationOnce()
            K:StartAntiAfk()
            K:StartWatchdog()
            if K.Phase == PHASE.BOOT then
                local _, hrp = getCharacter()
                if hrp and isLobbyY(hrp.Position.Y) then
                    K:SetPhase(PHASE.LOBBY, "boot-done")
                    K:CaptureLobbySpawn()
                else
                    K:SetPhase(PHASE.LOBBY, "boot-done-unknown")
                end
            end
            K:SyncMidRound()
            K:StartSummer2026()
            log("Ready — phase=" .. K.Phase)
        end))
    end
    
    G.MM2KaitunV2 = K
    return K
