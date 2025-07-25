local Players = game:GetService("Players")

local StatusDisplay = {}
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatusGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "StatusLabel"
label.Size = UDim2.new(0.3, 0, 0.05, 0)
label.Position = UDim2.new(0.02, 0, 0.02, 0)
label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
label.BackgroundTransparency = 0.4
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.SourceSansBold
label.TextScaled = true
label.Text = ""
label.Visible = false
label.Parent = screenGui

function StatusDisplay.set(text)
    label.Text = text
    label.Visible = true
end

function StatusDisplay.hide()
    label.Visible = false
end

return StatusDisplay
