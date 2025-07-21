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
