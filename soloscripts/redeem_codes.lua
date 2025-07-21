local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetFunction = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetFunction")

-- Replace or add your known codes here
local codes = {
    "AFIRSTTIME3001",
    "FREENIMBUSMOUNT",
    "VERYHIGHLIKEB",
    "UPD1",
    "LIKEF5",
    "THREEHUNDREDTHOUSANDPLAYERS",
    "FOLLOWS10KBREAD",
    "UPD2",
    "NEXTLIKEGOAL500K",
    "THANKYOUFORLIKES123"
}

for _, code in ipairs(codes) do
    local args = {
        {
            Type = "Code",
            Mode = "Redeem",
            Code = code
        }
    }
    local success, response = pcall(function()
        return GetFunction:InvokeServer(unpack(args))
    end)

    if success then
        print("✅ Redeemed code:", code)
    else
        warn("❌ Failed to redeem code:", code)
    end
end
