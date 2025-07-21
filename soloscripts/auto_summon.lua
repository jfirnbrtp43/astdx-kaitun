-- ======= CONFIG (User-editable) =======

getgenv().Configs = getgenv().Configs or {}

local configs = getgenv().Configs

local targetUnits = configs.TargetUnits or {}

local useMultiSummon = configs.UseMultiSummon or false
local checkInterval = configs.CheckInterval or 3 -- seconds

local webhookURL = configs.WebhookURL

-- =====================================


-- ======= SERVICES & CONSTANTS =======

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetFunction")
local summonDisplay = ReplicatedStorage:WaitForChild("Mods"):WaitForChild("SummonDisplay")
local banner1 = summonDisplay:FindFirstChild("StandardSummon")
local banner2 = summonDisplay:FindFirstChild("StandardSummon2")

local bannerIndices = {
    StandardSummon = 1,
    StandardSummon2 = 2
}

local secretUnits = {
    ["Kokushibo"] = "StandardSummon2",
    ["Chrollo"] = "StandardSummon"
}

-- ===================================


-- ======= HELPER FUNCTIONS =======

local function sendEmbedWebhook(title, description, color)
    if webhookURL == "" or webhookURL == nil then return end
    local username = game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Unknown User"
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["timestamp"] = DateTime.now():ToIsoDate(),
            ["footer"] = {
                ["text"] = "Requested by: " .. username
            }
        }}
    }

    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = webhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })
    end)

    if not success then
        warn("❌ Webhook failed:", response)
    end
end

local function isUnitInBanner(bannerFolder, unitName, starLevel)
    if not bannerFolder then return false end
    local starFolder = bannerFolder:FindFirstChild(starLevel)
    if not starFolder then return false end
    return starFolder:FindFirstChild(unitName) ~= nil
end

local function getBannerForUnit(unitName, starLevel)
    if isUnitInBanner(banner1, unitName, starLevel) then
        return "StandardSummon"
    elseif isUnitInBanner(banner2, unitName, starLevel) then
        return "StandardSummon2"
    else
        return nil
    end
end

local function countUnitsByName(unitsTable, targetName)
    local count = 0
    for _, unit in pairs(unitsTable) do
        if unit.Name == targetName then
            count += 1
        end
    end
    return count
end

local function isSecretUnit(unitName)
    return secretUnits[unitName] ~= nil
end

-- ================================


-- ======= MAIN SCRIPT =======

-- Kill any previous runs cleanly
if getgenv().AutoSummonRunning then
    getgenv().AutoSummonRunning = false
    task.wait(0.5)
end
getgenv().AutoSummonRunning = true


while true do
    local success, inventory = pcall(function()
        return GetFunction:InvokeServer({
            Type = "Inventory",
            Mode = "Units"
        })
    end)

    if not success or not inventory then
        wait(checkInterval)
        continue
    end

    local allDone = true
    local bannerToUse, rarityFlag, foundUnitName = nil, nil, nil
    local rarityOrder = { "5", "4", "3" }

    for unitName, targetAmount in pairs(targetUnits) do
        local ownedCount = 0
        for _, unit in pairs(inventory) do
            if unit.Name == unitName then
                ownedCount += 1
            end
        end

        print("📦 You own", ownedCount, unitName)

        if ownedCount >= targetAmount then
            continue
        end

        if isSecretUnit(unitName) then
            bannerToUse = secretUnits[unitName]
            rarityFlag = "Secret"
            foundUnitName = unitName
            allDone = false
            break
        else
            local foundOnBanner = false
            for _, rarity in ipairs(rarityOrder) do
                if isUnitInBanner(banner1, unitName, rarity) then
                    bannerToUse = "StandardSummon"
                    rarityFlag = rarity
                    foundUnitName = unitName
                    if not getgenv()._unitAnnounced then getgenv()._unitAnnounced = {} end
                    if not getgenv()._unitAnnounced[unitName] then
                        sendEmbedWebhook(
                            "📢 Unit Available on Banner",
                            "**" .. unitName .. "** (⭐️" .. rarityFlag .. ") is on `" .. bannerToUse .. "`.",
                            5793266
                        )
                        getgenv()._unitAnnounced[unitName] = true
                    end
                    foundOnBanner = true
                    break
                elseif isUnitInBanner(banner2, unitName, rarity) then
                    bannerToUse = "StandardSummon2"
                    rarityFlag = rarity
                    foundUnitName = unitName
                    if not getgenv()._unitAnnounced then getgenv()._unitAnnounced = {} end
                    if not getgenv()._unitAnnounced[unitName] then
                        sendEmbedWebhook(
                            "📢 Unit Available on Banner",
                            "**" .. unitName .. "** (⭐️" .. rarityFlag .. ") is on `" .. bannerToUse .. "`.",
                            5793266
                        )
                        getgenv()._unitAnnounced[unitName] = true
                    end
                    foundOnBanner = true
                    break
                end
            end

            if foundOnBanner then
                allDone = false
                break
            else
                print("❌ " .. unitName .. " not on any banner. Skipping summon for this unit.")
            end
        end
    end

    if allDone then
        sendEmbedWebhook(
            "✅ Auto-Summon Complete",
            "All target units have been obtained or are no longer on banners.\nAuto-summon has stopped.",
            65280
        )
        break
    end

    if bannerToUse and foundUnitName then
        local autoTable = {
            T3 = false, S3 = false, N3 = false,
            T4 = false, S4 = false, N4 = false,
            T5 = false, S5 = false, N5 = false
        }

        local summonArgs = {
            {
                Type = "Gacha",
                Auto = autoTable,
                Mode = "Purchase",
                Bundle = useMultiSummon,
                Index = bannerToUse
            }
        }

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

-- ===========================
