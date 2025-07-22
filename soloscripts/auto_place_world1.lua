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
        HttpService:PostAsync(WebhookURL, HttpService:JSONEncode(data))
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

local function reportStageResult()
    local resultText = MainUI.ResultFrame.Result.ExpandFrame.TopFrame.BoxFrame
        .InfoFrame2.InnerFrame.CanvasFrame.CanvasGroup.StampFrame.StampFrame.Title.Text

    local username = Players.LocalPlayer.Name
    local completedTime = os.date("%Y-%m-%d %H:%M:%S")

    local stats = MainUI.ResultFrame.Result.ExpandFrame.StatsFrame
    local damage = stats and stats.DamageDealt and stats.DamageDealt.Text or "Unknown"
    local timeTaken = stats and stats.TimeTaken and stats.TimeTaken.Text or "Unknown"
    
    local rewardFrame = MainUI.ResultFrame.Result.ExpandFrame.DropFrame
    local rewards = {}
    local totalCount = 0

    for _, reward in pairs(rewardFrame:GetChildren()) do
        if reward:IsA("Frame") and reward:FindFirstChild("Amount") and reward:FindFirstChild("ItemName") then
            local amount = tonumber(reward.Amount.Text:match("%d+")) or 0
            local name = reward.ItemName.Text
            table.insert(rewards, name .. " x" .. amount)
            totalCount += amount
        end
    end

    local stageInfo = MainUI.StageInfo.MapTitle.Text .. " - " .. MainUI.StageInfo.ActTitle.Text

    sendWebhook({
        username = "ASTDX Bot",
        embeds = {{
            title = resultText,
            description = "**Stage**: " .. stageInfo ..
                         "\n**Damage**: " .. damage ..
                         "\n**Time Taken**: " .. timeTaken ..
                         "\n**Rewards**: " .. table.concat(rewards, ", ") ..
                         " [`" .. totalCount .. "` total]",
            color = resultText == "Victory" and 65280 or 16711680,
            footer = {
                text = "Completed at " .. completedTime .. " | " .. username
            }
        }}
    })
end


-- ✅ Initial vote before first match
startVote()

-- 🔁 Main Loop
while true do
    autoPlaceAndUpgrade()
    waitForResultFrame()
    waitForButtonEnabled("Next")
    tryGameResultActions()
    reportStageResult()
    task.wait(3)
end
