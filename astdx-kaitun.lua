local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/main/Config.lua"))()
local Helpers = loadstring(game:HttpGet("https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/main/Helpers.lua"))()
local Webhook = loadstring(game:HttpGet("https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/main/Webhook.lua"))()

-- Access config values from Config table
local targetUnits = Config.TargetUnits or {}
local useMultiSummon = Config.UseMultiSummon or false
local checkInterval = Config.CheckInterval or 3
local webhookURL = Config.WebhookURL or ""
local redeemCodes = Config.RedeemCodes or {}
local autoSellSettings = Config.AutoSellSettings or {}

-- Roblox services
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetFunction")
local summonDisplay = ReplicatedStorage:WaitForChild("Mods"):WaitForChild("SummonDisplay")
local banner1 = summonDisplay:FindFirstChild("StandardSummon")
local banner2 = summonDisplay:FindFirstChild("StandardSummon2")

-- Use your webhook function from Webhook module
-- e.g., Webhook.sendEmbedWebhook(title, description, color)
-- You can override the webhook URL if needed
Webhook.setWebhookURL(webhookURL)

-- Redeem codes
for _, code in ipairs(redeemCodes) do
    pcall(function()
        GetFunction:InvokeServer({
            { Type = "Code", Mode = "Redeem", Code = code }
        })
    end)
end
task.wait(2)

-- Apply game settings (you can move this to a Utils module too if you want)
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

-- Kill previous runs if any
if getgenv().AutoSummonRunning then
    getgenv().AutoSummonRunning = false
    task.wait(0.5)
end
getgenv().AutoSummonRunning = true

-- Main loop
while getgenv().AutoSummonRunning do
    local success, inventory = pcall(function()
        return GetFunction:InvokeServer({ Type = "Inventory", Mode = "Units" })
    end)
    if not success or not inventory then
        task.wait(checkInterval)
        continue
    end

    local allDone = true
    local bannerToUse, rarityFlag, foundUnitName = nil, nil, nil
    local rarityOrder = { "5", "4", "3" }

    for unitName, targetAmount in pairs(targetUnits) do
        local ownedCount = 0
        for _, unit in pairs(inventory) do
            if unit.Name == unitName then ownedCount += 1 end
        end

        print("📦 You own", ownedCount, unitName)
        if ownedCount >= targetAmount then
            continue
        end

        if Helpers.isSecretUnit(unitName) then
            bannerToUse = Helpers.secretUnits[unitName]
            rarityFlag = "Secret"
            foundUnitName = unitName
            allDone = false
            break
        else
            for _, rarity in ipairs(rarityOrder) do
                if Helpers.isUnitInBanner(banner1, unitName, rarity) then
                    bannerToUse, rarityFlag, foundUnitName = "StandardSummon", rarity, unitName
                    allDone = false
                    break
                elseif Helpers.isUnitInBanner(banner2, unitName, rarity) then
                    bannerToUse, rarityFlag, foundUnitName = "StandardSummon2", rarity, unitName
                    allDone = false
                    break
                end
            end
        end

        if bannerToUse and not getgenv()._unitAnnounced then
            getgenv()._unitAnnounced = {}
        end

        if bannerToUse and not getgenv()._unitAnnounced[unitName] then
            Webhook.sendEmbedWebhook(
                "📢 Unit Available on Banner",
                "**" .. unitName .. "** (⭐️" .. rarityFlag .. ") is on `" .. bannerToUse .. "`.",
                5793266
            )
            getgenv()._unitAnnounced[unitName] = true
        end
    end

    if allDone then
        Webhook.sendEmbedWebhook("✅ Auto-Summon Complete", "All target units obtained or not on banners.", 65280)
        break
    end

    if bannerToUse and foundUnitName then
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
        task.wait(10)
    end

    task.wait(checkInterval)
end
