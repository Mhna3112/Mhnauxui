--[[
    ═══════════════════════════════════════════════════════════════════════════
    ✨ MHNAA UI - MULTI-GAME STARTER TEMPLATE ✨
    Copy and customize this template for ANY Roblox game (Anime Vanguards,
    Blox Fruits, Fisch, Pet Simulator 99, Rivals, etc.)
    ═══════════════════════════════════════════════════════════════════════════
]]

-- 1. LOAD THE LIBRARY (Direct from GitHub or Local Fallback)
local MhnaaUI
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/MhnaaUI.luau"

local successGit, resultGit = pcall(function()
    return loadstring(game:HttpGet(GITHUB_RAW_URL))()
end)

if successGit and resultGit then
    MhnaaUI = resultGit
else
    if isfile and isfile("MhnaaUI.luau") then
        MhnaaUI = loadstring(readfile("MhnaaUI.luau"))()
    elseif loadfile then
        local fn = loadfile("MhnaaUI.luau")
        if fn then MhnaaUI = fn() end
    end
end

if not MhnaaUI then
    error("Could not find MhnaaUI.luau! Please upload MhnaaUI.luau to GitHub Mhna3112/Mhnauxui or place it in executor workspace.")
end

-- 2. CREATE WINDOW (Change Title, Tag, and Game Name as desired)
local Window = MhnaaUI:CreateWindow({
    Title = "Mhnaa",
    Tag = "[PRO]",
    Game = "ANIME VANGUARDS",               -- Name shown on top of sidebar
    Size = UDim2.new(0, 680, 0, 420),        -- Window size
    AccentColor = Color3.fromRGB(104, 157, 248), -- Sky/Dodger blue
    ToggleKey = Enum.KeyCode.RightControl   -- Hotkey to hide/show UI
})

-- 3. CREATE TABS
local LobbyTab    = Window:CreateTab({ Name = "Lobby",     Icon = "🏠" })
local JoinerTab   = Window:CreateTab({ Name = "Joiner",    Icon = "🚀" })
local GameTab     = Window:CreateTab({ Name = "Game",      Icon = "🎮" })
local AutoPlayTab = Window:CreateTab({ Name = "Auto Play", Icon = "⚡" })
local MacroTab    = Window:CreateTab({ Name = "Macro",     Icon = "📜" })
local WebhookTab  = Window:CreateTab({ Name = "Webhook",   Icon = "🔔" })
local MiscTab     = Window:CreateTab({ Name = "Misc",      Icon = "⚙️" })

-- 4. ADD COMPONENTS TO TAB (Exact replica of the screenshot)

-- Checkbox Toggle with Title & Description
JoinerTab:CreateToggle({
    Title = "Auto Join Stage",
    Description = "Automatically joins the selected Stage and Act when you're in the Lobby",
    Default = true,
    Callback = function(state)
        print("Auto Join Stage is now:", state)
    end
})

-- Dropdown Combobox
JoinerTab:CreateDropdown({
    Title = "Select Stage",
    Options = {
        "Planet Namak",
        "Double Dungeon",
        "Shibuya Station",
        "Hidden Sand Village",
        "Cursed Academy"
    },
    Default = "Planet Namak",
    Callback = function(selected)
        print("Selected Stage:", selected)
    end
})

JoinerTab:CreateDropdown({
    Title = "Select Act",
    Options = {"Act 1", "Act 2", "Act 3", "Act 4", "Infinite"},
    Default = "Infinite",
    Callback = function(selected)
        print("Selected Act:", selected)
    end
})

JoinerTab:CreateToggle({
    Title = "Nightmare Mode",
    Description = "Enables nightmare difficulty multiplier",
    Default = false,
    Callback = function(state)
        print("Nightmare Mode is:", state)
    end
})

-- 5. OTHER AVAILABLE COMPONENTS

-- Slider
GameTab:CreateSlider({
    Title = "Unit Placement Speed",
    Min = 1,
    Max = 10,
    Default = 5,
    Suffix = "x",
    Callback = function(val)
        print("Speed set to:", val)
    end
})

-- Action Button
MiscTab:CreateButton({
    Title = "Server Hop",
    Description = "Finds and teleports to a different active server",
    ButtonText = "HOP SERVER",
    Callback = function(btn)
        MhnaaUI:Notify({
            Title = "Server Hop",
            Content = "Searching for a low-ping server...",
            Duration = 3
        })
    end
})

-- Text Input
WebhookTab:CreateInput({
    Title = "Discord Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Default = "",
    Callback = function(text, enterPressed)
        print("Webhook saved:", text)
    end
})

-- Startup Notification
MhnaaUI:Notify({
    Title = "Mhnaa [PRO]",
    Content = "Script loaded successfully! Press RightControl to hide/show.",
    Duration = 3.5
})
