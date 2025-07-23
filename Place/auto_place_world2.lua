-- auto_story2.lua

-- Services & Remotes
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
local matchEnded = false

local HttpService = game:GetService("HttpService")
local WebhookURL = "https://ptb.discord.com/api/webhooks/987499746853806110/XYjpFsIq4PxIk-v271EKeSIS4outAl-o19rJoc6Z3eoK_ZEqdbTB2w19xkIuuSt7UtbM"

local function getMapAndArc()
    local mapTitlePath = MainUI.GU.MenuFrame.MapFrame.MapExpand.BoxFrame
        .InfoFrame2.InnerFrame.CanvasFrame.CanvasGroup.TopFrame.MapTitle
    local arcTitlePath = MainUI.GU.MenuFrame.MapFrame.MapExpand.BoxFrame
        .InfoFrame2.InnerFrame.CanvasFrame.CanvasGroup.TopFrame.ActTitle

    return mapTitlePath.Text, arcTitlePath.Text
end

local function sendWebhook(data)
    pcall(function()
        HttpService:RequestAsync({
            Url = WebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end)
end

local function autoPlaceAndUpgrade()
    local success, inventory = pcall(function()
        return GetFunction:InvokeServer({ Type = "Inventory", Mode = "Units" })
    end)
    if not success then return end

    local equippedUnits = {}
    for _, unit in ipairs(inventory) do
        if unit.Equipped then
            table.insert(equippedUnits, unit)
        end
    end

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
        CFrame.new(65.13, 50.65, -55.88),
        CFrame.new(67.74, 51.33, -54.91),
        CFrame.new(69.04, 51.60, -53.22),
        CFrame.new(69.76, 51.12, -51.25)
    }

    local groundCFs = {
        CFrame.new(54.51, 48.47, -43.71),
        CFrame.new(55.14, 48.47, -41.65),
        CFrame.new(52.50, 48.47, -41.81),
        CFrame.new(54.57, 48.47, -37.76)
    }

    local summonList = {}
    for _, cf in ipairs(uryuCFs) do table.insert(summonList, { name = "Uryu", cf = cf }) end
    for _, cf in ipairs(gokuCFs) do table.insert(summonList, { name = "Goku", cf = cf }) end

    for _, unit in ipairs(fourStarUnits) do
        local place = unit.Place
        local list = (place == "Hill") and hillCFs or groundCFs
        for i = 1, math.min(4, #list) do
            table.insert(summonList, { name = unit.Name, cf = list[i] })
        end
    end

    local placedUnits = {}

    for _, summon in ipairs(summonList) do
        local placed = false
        for attempt = 1, 40 do
            SetEvent:FireServer("GameStuff", { "Summon", summon.name, summon.cf })
            task.wait(1)

            for _, unit in ipairs(UnitFolder:GetChildren()) do
                if unit.Name == summon.name and not table.find(placedUnits, unit) then
                    table.insert(placedUnits, unit)
                    placed = true
                    break
                end
            end
            if placed then break end
        end
    end

    local function upgradeUnit(nameFilter)
        for _, unit in ipairs(placedUnits) do
            if nameFilter(unit.Name) then
                local form = FormInfo:InvokeServer(unit.Name)
                local maxUp = #form
                while (unit:GetAttribute("UpgradeLevel") or 0) < maxUp do
                    -- 🛑 Check for match end dynamically
                    local resultFrame = MainUI:FindFirstChild("ResultFrame")
                    if resultFrame and resultFrame.Visible then
                        warn("🛑 Match ended. Stopping upgrade for", unit.Name)
                        return
                    end

                    pcall(function()
                        GetFunction:InvokeServer({ Type = "GameStuff" }, { "Upgrade", unit })
                    end)
                    task.wait(1)
                end
            end
        end
    end


    upgradeUnit(function(name) return name == "Uryu" end)
    upgradeUnit(function(name) return name == "Goku" end)
    upgradeUnit(function(name)
        for _, unit in ipairs(fourStarUnits) do
            if unit.Name == name then return true end
        end
        return false
    end)
end

local function waitForResultFrame()
    local resultFrame = MainUI:WaitForChild("ResultFrame")
    repeat task.wait() until resultFrame.Visible
    matchEnded = true
    return resultFrame
end

local function waitForResultText()
    local stampText
    local timeout = 10
    local elapsed = 0
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local cam = workspace.CurrentCamera
    local cx, cy = cam.ViewportSize.X/2, cam.ViewportSize.Y/2

    while elapsed < timeout do
        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)

        pcall(function()
            local title = MainUI.ResultFrame.Result.ExpandFrame.TopFrame.BoxFrame
                .InfoFrame2.InnerFrame.CanvasFrame.CanvasGroup.StampFrame
                .StampFrame.Title
            stampText = title.Text
        end)

        if stampText then
            local t = stampText:lower()
            if t == "victory" or t == "defeat" then
                return t:sub(1, 1):upper() .. t:sub(2)
            end
        end
        elapsed += 0.1
        task.wait(0.1)
    end
    return "Unknown"
end

local function reportStageResult(resultText)
    local map, arc = getMapAndArc()
    local username = Players.LocalPlayer.Name
    sendWebhook({
        username = "ASTDX Bot",
        embeds = {{
            title = resultText,
            description = "**Stage ended with:** " .. resultText ..
                         "\n**World:** " .. map ..
                         "\n**Arc:** " .. arc,
            color = resultText == "Victory" and 65280 or 16711680,
            footer = { text = "Completed at " .. os.date("%Y-%m-%d %H:%M:%S") .. " | " .. username }
        }}
    })
end

local function startVote()
    task.wait(5)
    pcall(function()
        Remotes:WaitForChild("GameStuff"):FireServer("StartVoteYes")
    end)
end

local function tryGameResultActions()
    for _ = 1, 3 do
        local success = pcall(function()
            GetFunction:InvokeServer({ Type = "Game", Index = "Level", Mode = "Reward" })
        end)
        if success then startVote() return end
        task.wait(1)
    end
    if pcall(function()
        GetFunction:InvokeServer({ Type = "Game", Index = "Replay", Mode = "Reward" })
    end) then
        startVote()
    else
        pcall(function()
            GetFunction:InvokeServer({ Type = "Game", Index = "Return", Mode = "Reward" })
        end)
    end
end

pcall(function() GetFunction:InvokeServer({ Index = 2, Type = "Speed" }) end)
startVote()

while true do
    autoPlaceAndUpgrade()
    waitForResultFrame()
    local resultText = waitForResultText()
    reportStageResult(resultText)
    tryGameResultActions()
    task.wait(3)
end
