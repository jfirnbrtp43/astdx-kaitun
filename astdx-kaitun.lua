--[[
getgenv().AutoSummonConfig = {
    WebhookURL = "https://ptb.discord.com/api/webhooks/987499746853806110/XYjpFsIq4PxIk-v271EKeSIS4outAl-o19rJoc6Z3eoK_ZEqdbTB2w19xkIuuSt7UtbM",
    UseMultiSummon = true,
    CheckInterval = 3,
    TargetUnits = {
        ["Rukia"] = 1,
        ["GokuEpic"] = 3,
        ["Sanji"] = 1
    },
    -- T = Trait, S = Shiny, N = Normal
    AutoSellSettings = {
        T3 = true, S3 = false, N3 = true,
        T4 = false, S4 = false, N4 = false,
        T5 = false, S5 = false, N5 = false
    }
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/main/astdx-kaitun.lua"))()
]]--

-- 🌐 SERVICES
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetFunction")
local summonDisplay = ReplicatedStorage:WaitForChild("Mods"):WaitForChild("SummonDisplay")
local banner1 = summonDisplay:FindFirstChild("StandardSummon")
local banner2 = summonDisplay:FindFirstChild("StandardSummon2")

-- 🧠 LOAD CONFIG
local config = getgenv().AutoSummonConfig or {}
local targetUnits = config.TargetUnits or {
    ["GokuEpic"] = 3,
    ["Sanji"] = 1
}
local useMultiSummon = config.UseMultiSummon or false
local checkInterval = config.CheckInterval or 3
local webhookURL = config.WebhookURL or ""
local redeemCodes = config.RedeemCodes or {
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
    "MBSHUTDOWNB"
}
local autoSellSettings = config.AutoSellSettings or {
    T3 = false, S3 = false, N3 = false,
    T4 = false, S4 = false, N4 = false,
    T5 = false, S5 = false, N5 = false
}


-- Enable Game Settings
local function applyGameSettings()
    local settingsList = {
        { Auto = true },
        { EnemyName = true },
        { Enemy = true },
        { EnemyHints = true },
        { Element = true },
        { Low = true },
        { WVFX = "None" },
        { Walk = true },
        { Cutscene = "Never" },
        { DMG = "None" }
    }

    for _, setting in ipairs(settingsList) do
        pcall(function()
            GetFunction:InvokeServer({
                Type = "Settings",
                Mode = "Set",
                List = setting
            })
        end)
    end
end

applyGameSettings()

-- 🎯 Auto Claim Completed Quests
local function autoClaimQuests()
    local success, questData = pcall(function()
        return GetFunction:InvokeServer({
            Type = "Quest",
            Mode = "Get"
        })
    end)

    if not success or type(questData) ~= "table" then
        return
    end

    for key, questTypes in pairs(questData) do
        for index, quest in pairs(questTypes) do
            if quest.Completed and not quest.Claimed then
                pcall(function()
                    GetFunction:InvokeServer({
                        Mode = "Claim",
                        Type = "Quest",
                        Key = key,
                        Index = index
                    })
                end)
            end
        end
    end
end

autoClaimQuests()



-- 🎁 REDEEM CODES
for _, code in ipairs(redeemCodes) do
    pcall(function()
        GetFunction:InvokeServer({
            Type = "Code",
            Mode = "Redeem",
            Code = code
        })
    end)
end
wait(2)

-- 🔁 WEBHOOK SENDER
local function sendEmbedWebhook(title, description, color)
    if webhookURL == "" then return end
    local username = game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Unknown User"
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["timestamp"] = DateTime.now():ToIsoDate(),
            ["footer"] = {
                ["text"] = "**" .. username .. "**"
            }
        }}
    }

    pcall(function()
        HttpService:RequestAsync({
            Url = webhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })
    end)
end

-- 🛑 KILL PREVIOUS RUNS
if getgenv().AutoSummonRunning then
    getgenv().AutoSummonRunning = false
    task.wait(0.5)
end
getgenv().AutoSummonRunning = true

-- 🔎 HELPERS
local function isUnitInBanner(bannerFolder, unitName, starLevel)
    if not bannerFolder then return false end
    local starFolder = bannerFolder:FindFirstChild(starLevel)
    if not starFolder then return false end
    return starFolder:FindFirstChild(unitName) ~= nil
end

local secretUnits = {
    ["Kokushibo"] = "StandardSummon2",
    ["Chrollo"] = "StandardSummon"
}

local function isSecretUnit(unitName)
    return secretUnits[unitName] ~= nil
end

-- 🔁 MAIN LOOP
while true do
    local success, inventory = pcall(function()
        return GetFunction:InvokeServer({ Type = "Inventory", Mode = "Units" })
    end)
    if not success or not inventory then wait(checkInterval) continue end

    local allDone = true
    local bannerToUse, rarityFlag, foundUnitName = nil, nil, nil
    local rarityOrder = { "5", "4", "3" }

    for unitName, targetAmount in pairs(targetUnits) do
        local ownedCount = 0
        for _, unit in pairs(inventory) do
            if unit.Name == unitName then ownedCount += 1 end
        end
        print("📦 You own", ownedCount, unitName)
        if ownedCount >= targetAmount then continue end

        if isSecretUnit(unitName) then
            bannerToUse = secretUnits[unitName]
            rarityFlag = "Secret"
            foundUnitName = unitName
            allDone = false
            break
        else
            for _, rarity in ipairs(rarityOrder) do
                if isUnitInBanner(banner1, unitName, rarity) then
                    bannerToUse, rarityFlag, foundUnitName = "StandardSummon", rarity, unitName
                    allDone = false
                    break
                elseif isUnitInBanner(banner2, unitName, rarity) then
                    bannerToUse, rarityFlag, foundUnitName = "StandardSummon2", rarity, unitName
                    allDone = false
                    break
                end
            end

            if bannerToUse and not getgenv()._unitAnnounced then
                getgenv()._unitAnnounced = {}
            end

            if bannerToUse and not getgenv()._unitAnnounced[unitName] then
                sendEmbedWebhook(
                    "📢 Unit Available on Banner",
                    "**" .. unitName .. "** (⭐️" .. rarityFlag .. ") is on `" .. bannerToUse .. "`.",
                    5793266
                )
                getgenv()._unitAnnounced[unitName] = true
            end
        end
    end

    if allDone then
        sendEmbedWebhook("✅ Auto-Summon Complete", "All target units obtained or not on banners.", 65280)
        break
    end

    if bannerToUse and foundUnitName then
        local autoTable = {
            T3 = false, S3 = false, N3 = false,
            T4 = false, S4 = false, N4 = false,
            T5 = false, S5 = false, N5 = false
        }

        local summonArgs = {{
            Type = "Gacha",
            Auto = autoSellSettings,
            Mode = "Purchase",
            Bundle = useMultiSummon,
            Index = bannerToUse
        }}

        local summonSuccess, summonResult = pcall(function()
            return GetFunction:InvokeServer(unpack(summonArgs))
        end)

        if summonSuccess then
            print("🎲 Summoned on banner:", bannerToUse, "| Rarity:", rarityFlag)
        else
            warn("⚠️ Summon failed:", summonResult)
            break
        end
    else
        print("⏳ No target units currently available on banners, waiting...")
        wait(10)
    end

    wait(checkInterval)
end
