-- Helpers.lua

local function isUnitInBanner(bannerFolder, unitName, starLevel)
    if not bannerFolder then return false end
    local starFolder = bannerFolder:FindFirstChild(starLevel)
    if not starFolder then return false end
    return starFolder:FindFirstChild(unitName) ~= nil
end

local secretUnits = {
    ["Kokushibo"] = "StandardSummon2",
    ["Chrollo"] = "StandardSummon"
}

local function isSecretUnit(unitName)
    return secretUnits[unitName] ~= nil
end

return {
    isUnitInBanner = isUnitInBanner,
    isSecretUnit = isSecretUnit
}
