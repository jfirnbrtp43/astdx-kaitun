-- Config.lua
local defaultConfig = {
    UseMultiSummon = false,
    CheckInterval = 5,
    TargetUnits = {
    },
    RedeemCodes = {
        "AFIRSTTIME3001",
        "FREENIMBUSMOUNT",
        "VERYHIGHLIKEB",
        "UPD2",
        "NEXTLIKEGOAL500K",
        "THANKYOUFORLIKES123",
        "THANKYOUFOR500MVISITS",
        "2MGROUPMEMBERS"
    },
    AutoSellSettings = {
        T3 = false, S3 = false, N3 = false,
        T4 = false, S4 = false, N4 = false,
        T5 = false, S5 = false, N5 = false
    }
}

EnableAutoStory = true

local userConfig = getgenv().AutoSummonConfig or {}

-- Shallow merge user config with defaults
for k, v in pairs(defaultConfig) do
    if userConfig[k] == nil then
        userConfig[k] = v
    end
end

return userConfig
