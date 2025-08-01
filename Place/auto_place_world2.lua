local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SetEvent = Remotes:WaitForChild("SetEvent")
local GetFunction = Remotes:WaitForChild("GetFunction")
local FormInfo = Remotes:WaitForChild("FormInfo")
local UnitFolder = workspace:WaitForChild("UnitFolder")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MainUI = PlayerGui:WaitForChild("MainUI")
local GU = PlayerGui:WaitForChild("GU")
local matchEnded = false

local WebhookURL = ""

local function getYen()
    return LocalPlayer:WaitForChild("Money").Value
end

local HttpService = game:GetService("HttpService")

local function getMapAndArc()
    local mapTitlePath = GU.MenuFrame.MapFrame.MapExpand.BoxFrame
        .InfoFrame2.InnerFrame.CanvasFrame.CanvasGroup.TopFrame.MapTitle
    local arcTitlePath = GU.MenuFrame.MapFrame.MapExpand.BoxFrame
        .InfoFrame2.InnerFrame.CanvasFrame.CanvasGroup.TopFrame.ActTitle

    local mapTitle = mapTitlePath and mapTitlePath.Text or "Unknown Map"
    local arcTitle = arcTitlePath and arcTitlePath.Text or "Unknown Arc"
    
    return mapTitle, arcTitle
end


local function sendWebhook(data)
    local success, err = pcall(function()
        HttpService:RequestAsync({
            Url = WebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })
    end)

    if not success then
        warn("❌ Webhook error:", err)
    end
end


local function autoPlaceAndUpgrade()
    local success, inventory = pcall(function()
        return GetFunction:InvokeServer({ Type = "Inventory", Mode = "Units" })
    end)
    if not success or typeof(inventory) ~= "table" then
        warn("❌ Failed to load inventory")
        return
    end

    local equippedUnits = {}
    for _, unit in ipairs(inventory) do
        if unit.Equipped and tonumber(unit.Equipped) then
            table.insert(equippedUnits, unit)
        end
    end

    -- Collect all 4 star equipped units except Goku and Uryu
    local fourStarUnits = {}
    for _, unit in ipairs(equippedUnits) do
        if unit.Rarity >= 4 and unit.Name ~= "Goku" and unit.Name ~= "Uryu" then
            table.insert(fourStarUnits, unit)
        end
    end

    local uryuCFs = {
        CFrame.new(94.82, 50.81, -43.10),
        CFrame.new(67.50, 50.76, -50.06),
        CFrame.new(65.22, 50.68, -51.12),
        CFrame.new(64.45, 50.57, -54.23)
    }

    local gokuCFs = {
        CFrame.new(61.28, 48.47, -47.04),
        CFrame.new(62.67, 48.47, -45.27),
        CFrame.new(59.29, 48.47, -45.13),
        CFrame.new(61.39, 48.47, -43.39)
    }

    local hillCFs = {
        CFrame.new(70.97645568847656, 51.11415100097656, -53.69337463378906),
        CFrame.new(72.38360595703125, 50.766273498535156, -51.24742889404297),
        CFrame.new(68.97288513183594, 51.25102615356445, -55.15991973876953),
        CFrame.new(95.22781372070312, 51.493534088134766, -46.00629806518555)
    }

    local groundCFs = {
        CFrame.new(71.22026062011719, 48.47781753540039, -34.87504577636719),
        CFrame.new(71.08145141601562, 48.47781753540039, -31.973312377929688),
        CFrame.new(74.13055419921875, 48.47781753540039, -34.81660461425781),
        CFrame.new(73.7650146484375, 48.47781753540039, -31.66815185546875)
    }

    local summonList = {}


    -- Place Uryu exactly 3 times at fixed positions
    for i = 1, #uryuCFs do
        table.insert(summonList, { name = "Uryu", cf = uryuCFs[i] })
    end

    -- Place Goku exactly 4 times at fixed positions
    for i = 1, #gokuCFs do
        table.insert(summonList, { name = "Goku", cf = gokuCFs[i] })
    end

    -- Place each 4-star unit (max 4) according to their place type
    for _, unit in ipairs(fourStarUnits) do
        local placeType = unit.Place
        local maxPlace = math.clamp(unit.Max or 3, 1, 4)
        local coords = nil

        if placeType == "Hill" then
            coords = hillCFs
        elseif placeType == "Ground" then
            coords = groundCFs
        else
            warn("⚠️ Unknown place type for unit:", unit.Name)
            continue
        end

        for i = 1, maxPlace do
            if i > #coords then break end
            table.insert(summonList, { name = unit.Name, cf = coords[i] })
        end
    end

    local placedUnits = {}

    -- Place all units in summonList
    for _, info in ipairs(summonList) do
        local positionOccupied = false
        for _, unit in ipairs(UnitFolder:GetChildren()) do
            if unit:IsA("Model") and unit:GetPrimaryPartCFrame()
                and (unit.PrimaryPart.Position - info.cf.Position).Magnitude < 0.1 then
                positionOccupied = true
                break
            end
        end

        if positionOccupied then continue end

        local maxAttempts = 50
        local placed = false

        while not placed and maxAttempts > 0 do
            local before = UnitFolder:GetChildren()
            SetEvent:FireServer("GameStuff", { "Summon", info.name, info.cf })
            task.wait(1)

            local after = UnitFolder:GetChildren()
            for _, unit in ipairs(after) do
                if unit.Name == info.name and not table.find(before, unit)
                    and not table.find(placedUnits, unit) then
                    table.insert(placedUnits, unit)
                    placed = true
                    break
                end
            end
            maxAttempts -= 1
        end
    end

    -- Upgrade priority:
    -- 1) All Uryu units
    for _, unit in ipairs(placedUnits) do
        if unit.Name == "Uryu" then
            local formData = FormInfo:InvokeServer(unit.Name)
            local maxUpgrades = #formData
            while (unit:GetAttribute("UpgradeLevel") or 0) < maxUpgrades do
                local resultFrame = MainUI:FindFirstChild("ResultFrame")
                if resultFrame and resultFrame.Visible then
                    warn("🛑 Match ended. Stopping upgrade for", unit.Name)
                    break
                end
                pcall(function()
                    GetFunction:InvokeServer({ Type = "GameStuff" }, { "Upgrade", unit })
                end)
                task.wait(1)
            end
        end
    end

    -- 2) All Goku units
    for _, unit in ipairs(placedUnits) do
        if unit.Name == "Goku" then
            local formData = FormInfo:InvokeServer(unit.Name)
            local maxUpgrades = #formData
            while (unit:GetAttribute("UpgradeLevel") or 0) < maxUpgrades do
                local resultFrame = MainUI:FindFirstChild("ResultFrame")
                if resultFrame and resultFrame.Visible then
                    warn("🛑 Match ended. Stopping upgrade for", unit.Name)
                    break
                end
                pcall(function()
                    GetFunction:InvokeServer({ Type = "GameStuff" }, { "Upgrade", unit })
                end)
                task.wait(1)
            end
        end
    end

    -- 3) All 4-star units (except Goku and Uryu)
    for _, unit in ipairs(placedUnits) do
        for _, fsUnit in ipairs(fourStarUnits) do
            if unit.Name == fsUnit.Name then
                local formData = FormInfo:InvokeServer(unit.Name)
                local maxUpgrades = #formData
                while (unit:GetAttribute("UpgradeLevel") or 0) < maxUpgrades do
                    local resultFrame = MainUI:FindFirstChild("ResultFrame")
                    if resultFrame and resultFrame.Visible then
                        warn("🛑 Match ended. Stopping upgrade for", unit.Name)
                        break
                    end
                    pcall(function()
                        GetFunction:InvokeServer({ Type = "GameStuff" }, { "Upgrade", unit })
                    end)
                    task.wait(1)
                end
            end
        end
    end

    
end

local function waitForResultFrame()
    local resultFrame = MainUI:WaitForChild("ResultFrame")
    repeat task.wait() until resultFrame.Visible
    matchEnded = true -- ✅ stop upgrades now
    return resultFrame
end

-- ✅ Start Vote Function
local function startVote()
    task.wait(2.5)
    pcall(function()
        Remotes:WaitForChild("GameStuff"):FireServer("StartVoteYes")
    end)
end

-- ✅ Set game speed to 2x at the start
task.wait(1)
pcall(function()
    GetFunction:InvokeServer({ Index = 2, Type = "Speed" })
end)

-- 🔁 Game Result Handling
local function tryGameResultActions()
    for _ = 1, 3 do
        local success = pcall(function()
            GetFunction:InvokeServer({
                Type = "Game",
                Index = "Level",
                Mode = "Reward"
            })
        end)
        if success then
            startVote() -- ✅ Restart vote after Next
            return
        end
        task.wait(1)
    end

    local replaySuccess = pcall(function()
        GetFunction:InvokeServer({
            Type = "Game",
            Index = "Replay",
            Mode = "Reward"
        })
    end)
    if replaySuccess then
        startVote() -- ✅ Restart vote after Replay
        return
    end

    pcall(function()
        GetFunction:InvokeServer({
            Type = "Game",
            Index = "Return",
            Mode = "Reward"
        })
    end)
end

local function waitForResultText()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local camera = workspace.CurrentCamera
    local screenSize = camera.ViewportSize
    local centerX = screenSize.X / 2
    local centerY = screenSize.Y / 2

    local resultFrame = MainUI:WaitForChild("ResultFrame", 10)
    if not resultFrame then return "Unknown" end

    local skipText = resultFrame:WaitForChild("Result"):FindFirstChild("SkipText")
    local timeout = 999
    local elapsed = 0

    -- 🟡 Phase 1: Tap until SkipText disappears (animation finished)
    while skipText and skipText.Visible and elapsed < timeout do
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
        end)
        task.wait(0.1)
        elapsed += 0.1
    end

    -- 🟢 Phase 2: Wait for "Victory"/"Defeat" stamp to appear
    local stampText
    elapsed = 0
    while elapsed < timeout do
        pcall(function()
            local stampFrame = MainUI.ResultFrame.Result.ExpandFrame.TopFrame.BoxFrame
                .InfoFrame2.InnerFrame.CanvasFrame.CanvasGroup:FindFirstChild("StampFrame")
            local title = stampFrame and stampFrame:FindFirstChild("StampFrame") and stampFrame.StampFrame:FindFirstChild("Title")
            if title then
                stampText = title.Text
                print("📘 Detected result text:", stampText)
            end
        end)

        if stampText then
            local normalized = stampText:lower()
            if normalized == "victory" or normalized == "defeat" then
                return normalized:sub(1, 1):upper() .. normalized:sub(2)
            end
        end

        task.wait(0.1)
        elapsed += 0.1
    end

    return "Unknown"
end

local function reportStageResult(resultText)
    local username = Players.LocalPlayer.Name
    local completedTime = os.date("%Y-%m-%d %H:%M:%S")
    
    local mapName, arcName = getMapAndArc()

    sendWebhook({
        username = "ASTDX Bot",
        embeds = {{
            title = resultText or "Unknown Result",
            description = table.concat({
                "**Stage ended with:** " .. (resultText or "Unknown"),
                "**World:** " .. mapName,
                "**Arc:** " .. arcName,
            }, "\n"),
            color = resultText == "Victory" and 65280 or 16711680,
            footer = {
                text = "Completed at " .. completedTime .. " | " .. username
            }
        }}
    })

    print("📤 Webhook sent for result:", resultText, "📍", mapName, "-", arcName)
end

-- ✅ Initial vote before first match
startVote()

-- 🔁 Main Loop
while true do
    autoPlaceAndUpgrade()
    waitForResultFrame()

    local resultText = waitForResultText()
    reportStageResult(resultText)
    tryGameResultActions()
    task.wait(3)
end
