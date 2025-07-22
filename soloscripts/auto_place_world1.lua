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

local WebhookURL = "https://ptb.discord.com/api/webhooks/987499746853806110/XYjpFsIq4PxIk-v271EKeSIS4outAl-o19rJoc6Z3eoK_ZEqdbTB2w19xkIuuSt7UtbM"

local function getYen()
    return LocalPlayer:WaitForChild("Money").Value
end

local HttpService = game:GetService("HttpService")

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
    local summonList = {
        { name = "Uryu", cf = CFrame.new(-73.682, 10.279, -33.302) },
        { name = "Uryu", cf = CFrame.new(-76.248, 10.212, -33.382) },
        { name = "Uryu", cf = CFrame.new(-75.015, 10.054, -35.915) },
        { name = "Goku", cf = CFrame.new(-71.866, 3.759, -31.528) },
        { name = "Goku", cf = CFrame.new(-70.710, 3.759, -33.567) },
        { name = "Goku", cf = CFrame.new(-70.704, 3.759, -36.204) },
        { name = "Goku", cf = CFrame.new(-69.109, 3.759, -31.374) },
    }

    local placedUnits = {}

    for _, info in ipairs(summonList) do
        local positionOccupied = false
        local units = UnitFolder:GetChildren()

        for _, unit in ipairs(units) do
            if unit:IsA("Model") and unit:GetPrimaryPartCFrame()
                and (unit.PrimaryPart.Position - info.cf.Position).Magnitude < 0.1 then
                positionOccupied = true
                break
            end
        end

        if positionOccupied then
            continue
        end

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

    for _, unit in ipairs(placedUnits) do
        local formData = FormInfo:InvokeServer(unit.Name)
        local maxUpgrades = #formData

        while (unit:GetAttribute("UpgradeLevel") or 0) < maxUpgrades do
            pcall(function()
                GetFunction:InvokeServer({ Type = "GameStuff" }, { "Upgrade", unit })
            end)
            task.wait(1)
        end
    end
end

local function waitForResultFrame()
    local resultFrame = MainUI:WaitForChild("ResultFrame")
    repeat task.wait() until resultFrame.Visible
    return resultFrame
end

local function waitForButtonEnabled(name)
    local buttonPath = MainUI.ResultFrame.Result.ExpandFrame.ButtonFrame.ButtonExpand
    local disabledFrame = buttonPath[name].ButtonDesign.ExpandFrame.DisabledFrame
    repeat task.wait() until not disabledFrame.Visible
end

-- ✅ Start Vote Function
local function startVote()
    task.wait(5)
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

    sendWebhook({
        username = "ASTDX Bot",
        embeds = {{
            title = resultText or "Unknown Result",
            description = "**Stage ended with:** " .. (resultText or "Unknown"),
            color = resultText == "Victory" and 65280 or 16711680,
            footer = {
                text = "Completed at " .. completedTime .. " | " .. username
            }
        }}
    })

    print("📤 Webhook sent for result:", resultText)
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
