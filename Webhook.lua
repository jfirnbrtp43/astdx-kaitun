local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Webhook = {}

function Webhook.sendEmbedWebhook(title, description, color)
    local config = getgenv().AutoSummonConfig or {}
    local webhookURL = config.WebhookURL or ""
    if webhookURL == "" then return end

    local username = Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown User"

    local data = {
        ["username"] = "ASTDX Bot",
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = tonumber(color) or 65280,
            ["footer"] = {
                ["text"] = "**" .. username .. "**"
            },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }

    local success, err = pcall(function()
        HttpService:RequestAsync({
            Url = webhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })
    end)

    if not success then
        warn("❌ Webhook Error:", err)
    end
end

return Webhook
