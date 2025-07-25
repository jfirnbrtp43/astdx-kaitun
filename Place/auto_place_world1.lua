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
        CFrame.new(-73.682, 10.279, -33.302),
        CFrame.new(-76.248, 10.212, -33.382),
        CFrame.new(-75.015, 10.054, -35.915),
        CFrame.new(-72.336, 9.712, -35.338)
    }

    local gokuCFs = {
        CFrame.new(-71.866, 3.759, -31.528),
        CFrame.new(-70.710, 3.759, -33.567),
        CFrame.new(-70.704, 3.759, -36.204),
        CFrame.new(-69.109, 3.759, -31.374),
    }

    local hillCFs = {
        CFrame.new(-76.025, 10.428, -6.167),
        CFrame.new(-73.503, 10.627, -6.572),
        CFrame.new(-73.226, 10.620, -3.531),
        CFrame.new(-76.118, 10.335, -2.948),
    }

    local groundCFs = {
        CFrame.new(-79.88250732421875, 3.7593679428100586, -62.93911361694336),
        CFrame.new(-79.89116668701172, 3.7593679428100586, -60.192501068115234),
        CFrame.new(-81.67688751220703, 3.7593679428100586, -61.904972076416016),
        CFrame.new(-77.65828704833984, 3.7593679428100586, -61.29658126831055),
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

    local resultFrame = MainUI:WaitForChild("ResultFrame", 10)
    repeat task.wait() until resultFrame.Visible

    local screenSize = workspace.CurrentCamera.ViewportSize
    local centerX = screenSize.X / 2
    local centerY = screenSize.Y / 2

    local timeout = 10
    local elapsed = 0

    while elapsed < timeout do
        -- Click middle of screen
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
        end)

        local stampText = nil

        pcall(function()
            local stampFrame = MainUI.ResultFrame.Result.ExpandFrame.TopFrame.BoxFrame
                .InfoFrame2.InnerFrame.CanvasFrame.CanvasGroup:FindFirstChild("StampFrame")

            local innerStamp = stampFrame and stampFrame:FindFirstChild("StampFrame")
            local title = innerStamp and innerStamp:FindFirstChild("Title")
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
