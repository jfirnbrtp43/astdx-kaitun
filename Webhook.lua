-- Webhook.lua
local HttpService = game:GetService("HttpService")
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/yourrepo/Config.lua"))()

local function sendEmbedWebhook(title, description, color)
    if Config.WebhookURL == "" then return end
    local username = game.Players.LocalPlayer and game.Players.LocalPlayer.Name or "Unknown User"
    local data = {
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["timestamp"] = DateTime.now():ToIsoDate(),
            ["footer"] = {
                ["text"] = "**" .. username .. "**"
            }
        }}
    }

    pcall(function()
        HttpService:RequestAsync({
            Url = Config.WebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })
    end)
end

return {
    sendEmbedWebhook = sendEmbedWebhook
}
