-- main.lua

--[[getgenv().AutoSummonConfig = {
    WebhookURL = "https://ptb.discord.com/api/webhooks/....",
    UseMultiSummon = true,
    CheckInterval = 3,
    TargetUnits = {
        ["Rukia"] = 1,
        ["GokuEpic"] = 3,
        ["Sanji"] = 1
    },
    AutoSellSettings = {
        T3 = true, S3 = false, N3 = true,
        T4 = false, S4 = false, N4 = false,
        T5 = false, S5 = false, N5 = false
    }
}


]]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

task.wait(15)

-- 📦 Code Redemption (Runs once at start)
local redeemCodes = {
    "AFIRSTTIME3001",
    "FREENIMBUSMOUNT",
    "VERYHIGHLIKEB",
    "UPD1",
    "LIKEF5",
    "THREEHUNDREDTHOUSANDPLAYERS",
    "FOLLOWS10KBREAD",
    "UPD2",
    "NEXTLIKEGOAL500K",
    "THANKYOUFORLIKES123",
    "MBSHUTDOWNB",
    "THANKYOUFOR500MVISITS",
    "2MGROUPMEMBERS"
}

local GetFunction = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("GetFunction")

for _, code in ipairs(redeemCodes) do
    local args = {
        {
            Type = "Code",
            Mode = "Redeem",
            Code = code
        }
    }
    local success, response = pcall(function()
        return GetFunction:InvokeServer(unpack(args))
    end)
    if success then
        print("✅ Redeemed code:", code, "| Response:", response)
    else
        warn("❌ Failed to redeem code:", code, "| Error:", response)
    end
    task.wait(1)
end
task.wait(2) -- Wait a bit after redeeming codes

-- Map of world names to placement script URLs
local worldToScriptUrl = {
    ["Innovation Island"] = "https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/refs/heads/main/Place/auto_place_world1.lua",
    ["City of Voldstandig"] = "https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/refs/heads/main/Place/auto_place_world2.lua",
    ["Future City (Ruins)"] = "https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/refs/heads/main/Place/auto_place_world3.lua",
    ["Hidden Storm Village"] = "https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/refs/heads/main/Place/auto_place_world4.lua",
    ["Giant Island"] = "https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/refs/heads/main/Place/auto_place_world5.lua",
    ["City of York"] = "https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/refs/heads/main/Place/auto_place_world6.lua",
}



-- Helper: Get current world/map name
local function getCurrentWorld()
    local success, mapName = pcall(function()
        return PlayerGui
            :WaitForChild("GU")
            :WaitForChild("MenuFrame")
            :WaitForChild("MapFrame")
            :WaitForChild("MapExpand")
            :WaitForChild("BoxFrame")
            :WaitForChild("InfoFrame2")
            :WaitForChild("InnerFrame")
            :WaitForChild("CanvasFrame")
            :WaitForChild("CanvasGroup")
            :WaitForChild("TopFrame")
            :WaitForChild("MapTitle").Text
    end)
    return success and mapName or "Unknown"
end

-- Helper: Detect if player is in Lobby by checking banners
local function isInLobby()
    local summonDisplay = ReplicatedStorage:FindFirstChild("Mods")
        and ReplicatedStorage.Mods:FindFirstChild("SummonDisplay")

    if not summonDisplay then return false end

    return summonDisplay:FindFirstChild("StandardSummon") or summonDisplay:FindFirstChild("StandardSummon2")
end



-- Main logic
if isInLobby() then
    print("🧭 Detected Lobby — loading Auto Summon script...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/main/auto_summon.lua"))()
else
    local currentWorld = getCurrentWorld()
    print("🌍 Detected Story World:", currentWorld)

    local placementScriptUrl = worldToScriptUrl[currentWorld]
    if placementScriptUrl then
        print("🚀 Loading placement script for:", currentWorld)
        loadstring(game:HttpGet(placementScriptUrl))()
    else
        warn("❌ No placement script found for world:", currentWorld)
    end
end
