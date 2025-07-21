local function getLastCompletedStory(storyData)
    local lastWorld, lastChapter = nil, nil

    local worldList = {}
    for worldName in pairs(storyData) do
        table.insert(worldList, worldName)
    end
    table.sort(worldList, function(a, b)
        return tonumber(a:match("%d+")) < tonumber(b:match("%d+"))
    end)

    for _, worldName in ipairs(worldList) do
        local chapters = storyData[worldName]
        for chapterName, data in pairs(chapters) do
            if data.Completed then
                lastWorld = worldName
                local chapNum = tonumber(chapterName:match("%d+"))
                if not lastChapter or chapNum > lastChapter then
                    lastChapter = chapNum
                end
            end
        end
    end

    return lastWorld, lastChapter
end


local function getLastUnlockedStory()
    local success, result = pcall(function()
        return game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("GetFunction"):InvokeServer({
            Type = "Quest",
            Mode = "Get"
        })
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

            -- If completed or (not completed but further along)
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

-- Use it like:
local world, chapter = getLastUnlockedStory()
if world and chapter then
    print("Last unlocked story map:", world, "Chapter", chapter)
end
