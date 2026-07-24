local G = getgenv()

G.MM2KaitunV2Config = G.MM2KaitunV2Config or {}
if G.NiAutoConfig and G.NiAutoConfig.AccountOpsApiKey then
    G.MM2KaitunV2Config.AccountOpsApiKey = G.NiAutoConfig.AccountOpsApiKey
end
if G.NiAutoConfig and G.NiAutoConfig.DiscordWebhookGodly and G.NiAutoConfig.DiscordWebhookGodly ~= "" then
    G.MM2KaitunV2Config.DiscordWebhookGodly = G.NiAutoConfig.DiscordWebhookGodly
end

local function load(url)
    pcall(function()
        loadstring(game:HttpGet(url, true))()
    end)
end

load("https://raw.githubusercontent.com/shuys1230sxmcsweiqpxcv/Evomon/refs/heads/main/han.lua")

G.NiAutoConfig = G.NiAutoConfig or {}
G.NiAutoConfig.UserId = G.NiAutoConfig.UserId or ""
G.NiAutoConfig.ITEMS_RARITY_TO_NOTIFY = G.NiAutoConfig.ITEMS_RARITY_TO_NOTIFY or { "Godly", "Legendary", "Rare" }

load("https://raw.githubusercontent.com/shuys1230sxmcsweiqpxcv/Evomon/refs/heads/main/notify.lua")
load("https://raw.githubusercontent.com/shuys1230sxmcsweiqpxcv/Evomon/refs/heads/main/hopfast.lua")
