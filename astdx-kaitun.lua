-- 🧠 SETTINGS
-- [UnitName] = [TargetAmount]
local targetUnits = {
    ["Ulqiorra"] = 1,
    ["Rukia"] = 1
}
local useMultiSummon = false
local checkInterval = 3 -- seconds

-- SERVICES
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetFunction")
local summonDisplay = ReplicatedStorage:WaitForChild("Mods"):WaitForChild("SummonDisplay")
local banner1 = summonDisplay:FindFirstChild("StandardSummon")
local banner2 = summonDisplay:FindFirstChild("StandardSummon2")

-- Replace or add your known codes here
local codes = {
    "AFIRSTTIME3001",
    "FREENIMBUSMOUNT",
    "VERYHIGHLIKEB",
    "UPD1",
    "LIKEF5",
    "THREEHUNDREDTHOUSANDPLAYERS",
    "FOLLOWS10KBREAD",
    "UPD2",
    "NEXTLIKEGOAL500K",
    "THANKYOUFORLIKES123"
}

for _, code in ipairs(codes) do
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
end


-- Banner indices (used for the summon request)
local bannerIndices = {
    StandardSummon = 1,
    StandardSummon2 = 2
}

-- 🌐 Webhook URL
local webhookURL = "https://ptb.discord.com/api/webhooks/987499746853806110/XYjpFsIq4PxIk-v271EKeSIS4outAl-o19rJoc6Z3eoK_ZEqdbTB2w19xkIuuSt7UtbM"

-- 🔁 Function to send webhook
local function sendEmbedWebhook(title, description, color)
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


-- Kill previous runs
if getgenv().AutoSummonRunning then
    getgenv().AutoSummonRunning = false
    task.wait(0.5)
end
getgenv().AutoSummonRunning = true

-- 🔁 Helper: Check if unit is in a banner
local function isUnitInBanner(bannerFolder, unitName, starLevel)
    if not bannerFolder then return false end
    local starFolder = bannerFolder:FindFirstChild(starLevel)
    if not starFolder then return false end
    return starFolder:FindFirstChild(unitName) ~= nil
end

-- 🔁 Determine which banner to summon from
local function getBannerForUnit(unitName, starLevel)
    if isUnitInBanner(banner1, unitName, starLevel) then
        return "StandardSummon"
    elseif isUnitInBanner(banner2, unitName, starLevel) then
        return "StandardSummon2"
    else
        return nil
    end
end

-- 🔍 Count owned units
local function countUnitsByName(unitsTable, targetName)
    local count = 0
    for _, unit in pairs(unitsTable) do
        if unit.Name == targetName then
            count += 1
        end
    end
    return count
end

-- MAIN LOOP
while true do
    -- Get inventory
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

    -- Track if all targets met or not on banner
    local allDone = true

    -- Variables to hold the summon info for the current attempt
    local bannerToUse, rarityFlag, foundUnitName = nil, nil, nil

    local rarityOrder = { "5", "4", "3" }

    -- Check each unit independently
    for unitName, targetAmount in pairs(targetUnits) do
        local ownedCount = 0
        -- Count how many owned
        for _, unit in pairs(inventory) do
            if unit.Name == unitName then
                ownedCount += 1
            end
        end

        print("📦 You own", ownedCount, unitName)

        -- Skip summoning if target met
        if ownedCount >= targetAmount then
            -- Already have enough, no summon for this unit
            continue
        end

        -- Find if unit is on any banner (any rarity)
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
                        5793266 -- light blue
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
                        5793266 -- light blue
                    )
                    getgenv()._unitAnnounced[unitName] = true
                end

                foundOnBanner = true
                break
            end
        end

        if foundOnBanner then
            allDone = false
            break -- Only summon for one unit at a time
        else
            -- This unit is missing target copies but not on banner -> skip summon for this unit
            print("❌ " .. unitName .. " not on any banner. Skipping summon for this unit.")
        end
    end

    -- If all units either met targets or not on banner, stop
    if allDone then
        sendEmbedWebhook(
        "✅ Auto-Summon Complete",
        "All target units have been obtained or are no longer on banners.\nAuto-summon has stopped.",
        65280 -- green
    )

        break
    end

    -- Summon only if a banner & unit found
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
            -- No webhook here to avoid spam
        else
            warn("⚠️ Summon failed:", summonResult)
            break
        end
    else
        -- No units found on any banner to summon for
        print("⏳ No target units currently available on banners, waiting...")
        wait(10)
    end

    wait(checkInterval)
end
