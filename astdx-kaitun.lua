-- Kaitun Auto Summon Bootstrapper

getgenv().AutoSummonConfig = {
    WebhookURL = "https://ptb.discord.com/api/webhooks/987499746853806110/XYjpFsIq4PxIk-v271EKeSIS4outAl-o19rJoc6Z3eoK_ZEqdbTB2w19xkIuuSt7UtbM",
    UseMultiSummon = true,
    CheckInterval = 3,
    TargetUnits = {
        ["Rukia"] = 1,
        ["GokuEpic"] = 3,
        ["Sanji"] = 1
    },
    AutoSellSettings = {
        T3 = true, S3 = false, N3 = true,
        T4 = false, S4 = false, N4 = false,
        T5 = false, S5 = false, N5 = false
    }
}

-- ✅ Run the main logic
loadstring(game:HttpGet("https://raw.githubusercontent.com/jfirnbrtp43/astdx-kaitun/main/Main.lua"))()
