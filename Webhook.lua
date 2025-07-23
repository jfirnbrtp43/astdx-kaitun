local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Webhook = {}
local currentWebhookURL = ""

function Webhook.setWebhookURL(url)
    currentWebhookURL = url or ""
end

function Webhook.sendEmbedWebhook(title, description, color)
    if currentWebhookURL == "" then return end

    local username = Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown User"

    local data = {
        ["username"] = "ASTDX Bot",
        ["embeds"] = {{
            ["title"] = title or "No Title",
            ["description"] = description or "No Description",
            ["color"] = tonumber(color) or 65280,
            ["footer"] = {
                ["text"] = "**" .. username .. "**"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    local success, err = pcall(function()
        HttpService:RequestAsync({
            Url = currentWebhookURL,
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
