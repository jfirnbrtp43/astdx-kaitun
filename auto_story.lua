local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetFunction = Remotes:WaitForChild("GetFunction")

-- Step 1: Interact with the StoryPod to open the story pod UI / prepare teleport
local interactArgs = {
    {
        Type = "Lobby",
        Object = workspace:WaitForChild("Map"):WaitForChild("Buildings"):WaitForChild("Pods"):WaitForChild("StoryPod"):WaitForChild("Interact"),
        Mode = "Pod"
    }
}

local success, err = pcall(function()
    GetFunction:InvokeServer(unpack(interactArgs))
end)

if not success then
    warn("Failed to interact with StoryPod:", err)
    return
end
print("Interacted with StoryPod successfully.")

-- Step 2: Get last unlocked story
local function getLastUnlockedStory()
    local success, result = pcall(function()
        return GetFunction:InvokeServer({ Type = "Quest", Mode = "Get" })
    end)

    if not success or not result or not result.Story or not result.Story.Quests then
        warn("❌ Failed to get story progression")
        return nil
    end

    local highestWorldNum = 0
    local highestActNum = 0
    local latestWorld, latestAct = nil, nil

    for _, quest in pairs(result.Story.Quests) do
        if quest.Map and quest.Act and quest.Act <= 6 then
            local worldNum = tonumber(quest.Map:match("%d+")) or 0
            local actNum = tonumber(quest.Act) or 0

            if quest.Completed or (worldNum > highestWorldNum or (worldNum == highestWorldNum and actNum > highestActNum)) then
                highestWorldNum = worldNum
                highestActNum = actNum
                latestWorld = quest.Map
                latestAct = actNum
            end
        end
    end

    return latestWorld, latestAct
end

local function teleportToLatestStory()
    local storyDifficulty = getgenv().AutoSummonConfig and getgenv().AutoSummonConfig.StoryDifficulty or "Normal"
    local world, chapter = getLastUnlockedStory()
    if not world or not chapter then
        warn("Could not find last unlocked story.")
        return
    end

    print("Teleporting to:", world, "Chapter:", chapter)

    -- Step 3: Send teleport request
    local teleportArgs = {
        {
            Chapter = chapter,
            Type = "Lobby",
            Name = world,
            Difficulty = storyDifficulty,
            Mode = "Pod",
            Friend = false,
            Update = true
        }
    }

    local success, err = pcall(function()
        GetFunction:InvokeServer(unpack(teleportArgs))
    end)

    if not success then
        warn("Failed to send teleport request:", err)
        return
    end
    print("Teleport request sent successfully.")

    wait(1) -- wait a bit before starting

    -- Step 4: Start the teleport
    local startArgs = {
        {
            Start = true,
            Type = "Lobby",
            Update = true,
            Mode = "Pod"
        }
    }

    local success, err = pcall(function()
        GetFunction:InvokeServer(unpack(startArgs))
    end)

    if success then
        print("Teleport started successfully.")
    else
        warn("Failed to start teleport:", err)
    end
end

teleportToLatestStory()
