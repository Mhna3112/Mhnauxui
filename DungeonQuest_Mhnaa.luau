--[[
    ═══════════════════════════════════════════════════════════════════════════
    ✨ MHNAA [PRO] - DUNGEON QUEST AUTOMATION & ADVANCED AUTOFARM ✨
    Powered by MhnaaUI Library
    Features:
      • Modern Dark Mhnaa [PRO] Interface with Instant Search (Ctrl+K)
      • Smart Room Progression & Anti-Jitter Downward Target Lock
      • Advanced Boss Skill Dodge (Hooks into BridgeNet2 precastHitbox)
      • Smooth Anti-Damage Flight Hovering (Configurable Height & Altitude)
      • Rapid Attack Loop & Auto Q/E Abilities Rotation
      • Auto Replay Dungeon & Advance Tier
      • Auto Stat Allocation (Physical Power, Spell Power, Stamina)
      • Auto Sell Inventory (Common, Uncommon, Rare, Epic)
      • Built-in Anti-AFK, Noclip, WalkSpeed Slider, and Infinite Jump
      • Auto-Save / Load Configuration to JSON
    ═══════════════════════════════════════════════════════════════════════════
]]

-- LOAD MHNAA UI LIBRARY (Online from GitHub or Local Fallback)
local MhnaaUI
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/MhnaaUI.luau"

-- 1. Ưu tiên tải trực tiếp từ GitHub repo của Mhnaa
local successGit, resultGit = pcall(function()
    return loadstring(game:HttpGet(GITHUB_RAW_URL))()
end)

if successGit and resultGit then
    MhnaaUI = resultGit
else
    -- 2. Dự phòng: Đọc file local nếu chưa up lên Git hoặc offline
    local successLocal, resultLocal = pcall(function()
        if isfile and isfile("MhnaaUI.luau") then
            return loadstring(readfile("MhnaaUI.luau"))()
        elseif isfile and isfile("robloxscript/MhnaaUI.luau") then
            return loadstring(readfile("robloxscript/MhnaaUI.luau"))()
        elseif loadfile then
            local fn = loadfile("MhnaaUI.luau") or loadfile("robloxscript/MhnaaUI.luau")
            if fn then return fn() end
        end
    end)
    if successLocal and resultLocal then
        MhnaaUI = resultLocal
    end
end

if not MhnaaUI then
    error("[Mhnaa [PRO]] Không thể tải MhnaaUI! Vui lòng upload MhnaaUI.luau lên repo Mhna3112/Mhnauxui hoặc để file MhnaaUI.luau trong thư mục workspace.")
end

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CONFIGURATION
local Config = {
    -- Farm Settings
    AutoStartDungeon = true,
    AutoKillAura = true,
    AutoCompleteStage = true,
    AutoDodgeBossSkill = true,
    AutoReplayDungeon = true,
    AutoCastAbilities = true,
    FarmHeight = 7,
    DodgeHeight = 18,
    AttackDelay = 0.08,
    AdvanceTier = false,
    SafeMode = true,
    SafeHealthPercent = 0.25,

    -- Dungeon Controls
    SelectedStage = "Desert Temple",
    SelectedDifficulty = "Nightmare",
    AutoRetryOnWipe = true,
    Noclip = true,
    BossESP = true,
    MobESP = false,

    -- Stats & Enhancements
    AutoAllocateStats = true,
    SelectedStat = "Physical Power",
    WalkSpeed = 16,
    InfiniteJump = false,
    AntiAFK = true,

    -- Auto Sell
    AutoSell = false,
    SellCommon = true,
    SellUncommon = true,
    SellRare = false,
    SellEpic = false,

    -- System
    AutoSave = true
}

local Runtime = {
    CurrentLockedTarget = nil,
    IsDodging = false,
    DodgeEndTime = 0,
    StatusMessage = "Idle",
    ESPObjects = {}
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 💾 SAVE & LOAD SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════
local CONFIG_FILE = "Mhnaa_DQ_Config.json"

local function saveConfig()
    local serialized = {}
    for k, v in pairs(Config) do
        if typeof(v) ~= "function" and typeof(v) ~= "Instance" then
            serialized[k] = v
        end
    end
    local success, jsonStr = pcall(function() return HttpService:JSONEncode(serialized) end)
    if success and jsonStr then
        if writefile then
            pcall(function() writefile(CONFIG_FILE, jsonStr) end)
        else
            _G.Mhnaa_DQ_SavedConfig = jsonStr
        end
    end
end

local function loadConfig()
    local jsonStr = nil
    if isfile and readfile and isfile(CONFIG_FILE) then
        pcall(function() jsonStr = readfile(CONFIG_FILE) end)
    elseif _G.Mhnaa_DQ_SavedConfig then
        jsonStr = _G.Mhnaa_DQ_SavedConfig
    end

    if jsonStr then
        local success, decoded = pcall(function() return HttpService:JSONDecode(jsonStr) end)
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                if Config[k] ~= nil then
                    Config[k] = v
                end
            end
            return true
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🛡️ CORE GAMEPLAY & REMOTES
-- ═══════════════════════════════════════════════════════════════════════════
local Remotes = {
    WeaponUsed = ReplicatedStorage:FindFirstChild("remotes") and ReplicatedStorage.remotes:FindFirstChild("weaponUsed"),
    AbilityUsed = ReplicatedStorage:FindFirstChild("remotes") and ReplicatedStorage.remotes:FindFirstChild("abilityUsed"),
    ReplayDungeon = ReplicatedStorage:FindFirstChild("remotes") and ReplicatedStorage.remotes:FindFirstChild("replayDungeon"),
    SpendSkillPoint = ReplicatedStorage:FindFirstChild("remotes") and ReplicatedStorage.remotes:FindFirstChild("spendSkillPoint"),
    SellItemEvent = ReplicatedStorage:FindFirstChild("remotes") and ReplicatedStorage.remotes:FindFirstChild("sellItemEvent")
}

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getRootPart()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- BOSS SKILL DODGE HOOK (BridgeNet2 precastHitbox)
pcall(function()
    local Utility = ReplicatedStorage:FindFirstChild("Utility")
    if Utility and Utility:FindFirstChild("BridgeNet2") then
        local BridgeNet2 = require(Utility.BridgeNet2)
        local bridge = BridgeNet2.ReferenceBridge("precastHitbox")
        
        bridge:Connect(function(data)
            if not Config.AutoDodgeBossSkill then return end
            if not data or type(data) ~= "table" then return end

            local hitPos = data.position or (data.cframe and data.cframe.Position)
            local hitRadius = data.radius or (data.size and math.max(data.size.X, data.size.Z) / 2) or 16
            local delayTime = data.delayUntilAttack or 1.2

            local hrp = getRootPart()
            if hrp and hitPos then
                local playerFlat = Vector3.new(hrp.Position.X, hitPos.Y, hrp.Position.Z)
                local dist = (playerFlat - hitPos).Magnitude
                
                if dist <= (hitRadius + 8) then
                    Runtime.IsDodging = true
                    Runtime.DodgeEndTime = os.clock() + delayTime + 0.35
                    MhnaaUI:Notify({
                        Title = "Dodge Engine",
                        Content = "⚡ Dodging incoming boss skill!",
                        Duration = 1.5
                    })
                    
                    task.delay(delayTime + 0.35, function()
                        if os.clock() >= Runtime.DodgeEndTime then
                            Runtime.IsDodging = false
                        end
                    end)
                end
            end
        end)
    end
end)

-- ANTI-AFK
if getconnections then
    for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
        if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
    end
end
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- NOCLIP
RunService.Stepped:Connect(function()
    if Config.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- FIND TARGET MOBS IN DUNGEON
local function getEnemiesFolder()
    local dungeon = Workspace:FindFirstChild("dungeon")
    return dungeon and dungeon:FindFirstChild("enemies")
end

local function getNearestEnemy()
    local hrp = getRootPart()
    if not hrp then return nil end

    local enemies = getEnemiesFolder()
    if not enemies then return nil end

    local closestTarget = nil
    local shortestDist = math.huge

    for _, enemy in ipairs(enemies:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local enemyHrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso")
        if hum and enemyHrp and hum.Health > 0 then
            local dist = (enemyHrp.Position - hrp.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closestTarget = {
                    model = enemy,
                    humanoid = hum,
                    rootPart = enemyHrp
                }
            end
        end
    end

    return closestTarget
end

-- AUTO ATTACK & AUTO FARM LOOP
task.spawn(function()
    while true do
        task.wait(Config.AttackDelay)

        if Config.AutoCompleteStage or Config.AutoKillAura then
            local hrp = getRootPart()
            local hum = getHumanoid()

            if hrp and hum and hum.Health > 0 then
                -- Check target validity
                if not Runtime.CurrentLockedTarget or not Runtime.CurrentLockedTarget.model.Parent or Runtime.CurrentLockedTarget.humanoid.Health <= 0 then
                    Runtime.CurrentLockedTarget = getNearestEnemy()
                end

                local target = Runtime.CurrentLockedTarget
                if target and target.rootPart and target.rootPart.Parent then
                    -- Flight & Position calculation
                    if Config.AutoCompleteStage then
                        local hoverOffset = Config.FarmHeight
                        if Runtime.IsDodging then
                            hoverOffset = Config.FarmHeight + Config.DodgeHeight
                        elseif Config.SafeMode and (hum.Health / hum.MaxHealth) <= Config.SafeHealthPercent then
                            hoverOffset = Config.FarmHeight + 20
                        end

                        local targetCFrame = CFrame.new(target.rootPart.Position + Vector3.new(0, hoverOffset, 0))
                        hrp.CFrame = targetCFrame
                        hrp.Velocity = Vector3.zero
                    end

                    -- Weapon attack remote trigger
                    if Remotes.WeaponUsed then
                        pcall(function()
                            Remotes.WeaponUsed:FireServer(target.rootPart.Position, {target.model})
                        end)
                    end

                    -- Cast Q & E abilities
                    if Config.AutoCastAbilities and Remotes.AbilityUsed then
                        pcall(function()
                            Remotes.AbilityUsed:FireServer("ability1", target.rootPart.Position)
                            Remotes.AbilityUsed:FireServer("ability2", target.rootPart.Position)
                        end)
                    end
                end
            end
        end
    end
end)

-- AUTO REPLAY DUNGEON
task.spawn(function()
    while true do
        task.wait(2)
        if Config.AutoReplayDungeon and Remotes.ReplayDungeon then
            local enemies = getEnemiesFolder()
            local dungeon = Workspace:FindFirstChild("dungeon")
            -- If dungeon finished or reward screen is active
            local rewardsGui = LocalPlayer.PlayerGui:FindFirstChild("rewards") or LocalPlayer.PlayerGui:FindFirstChild("dungeonComplete")
            if (rewardsGui and rewardsGui.Enabled) or (dungeon and enemies and #enemies:GetChildren() == 0 and dungeon:FindFirstChild("bossDefeated")) then
                pcall(function()
                    Remotes.ReplayDungeon:FireServer(Config.AdvanceTier)
                end)
                task.wait(5)
            end
        end
    end
end)

-- AUTO ALLOCATE STAT POINTS
task.spawn(function()
    while true do
        task.wait(3)
        if Config.AutoAllocateStats and Remotes.SpendSkillPoint then
            local statKey = "physicalPower"
            if Config.SelectedStat == "Spell Power" then
                statKey = "spellPower"
            elseif Config.SelectedStat == "Stamina" then
                statKey = "stamina"
            end
            pcall(function()
                Remotes.SpendSkillPoint:FireServer(statKey, 1)
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎨 BUILD MHNAA [PRO] USER INTERFACE
-- ═══════════════════════════════════════════════════════════════════════════
local Window = MhnaaUI:CreateWindow({
    Title = "Mhnaa",
    Tag = "[PRO]",
    Game = "DUNGEON QUEST",
    Size = UDim2.new(0, 680, 0, 420),
    AccentColor = Color3.fromRGB(104, 157, 248),
    ToggleKey = Enum.KeyCode.RightControl
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 1: AUTO FARM (Matching Nousigi [PRO] Joiner/Farm style)
-- ═══════════════════════════════════════════════════════════════════════════
local FarmTab = Window:CreateTab({
    Name = "Auto Farm",
    Icon = "⚔"
})

FarmTab:CreateSection("DUNGEON AUTOMATION")

FarmTab:CreateToggle({
    Title = "Auto Complete Stage",
    Description = "Automatically flies through rooms, eliminates all mobs, and beats bosses",
    Default = Config.AutoCompleteStage,
    Callback = function(val)
        Config.AutoCompleteStage = val
        if Config.AutoSave then saveConfig() end
    end
})

FarmTab:CreateToggle({
    Title = "Auto Kill Aura (Attack Only)",
    Description = "Attacks nearby enemies without overriding player position",
    Default = Config.AutoKillAura,
    Callback = function(val)
        Config.AutoKillAura = val
        if Config.AutoSave then saveConfig() end
    end
})

FarmTab:CreateToggle({
    Title = "Auto Dodge Boss Skill",
    Description = "Hooks into BridgeNet2 telegraphs to ascend above ground-hazard attacks",
    Default = Config.AutoDodgeBossSkill,
    Callback = function(val)
        Config.AutoDodgeBossSkill = val
        if Config.AutoSave then saveConfig() end
    end
})

FarmTab:CreateToggle({
    Title = "Auto Cast Abilities (Q & E)",
    Description = "Automatically casts skills and spells off cooldown",
    Default = Config.AutoCastAbilities,
    Callback = function(val)
        Config.AutoCastAbilities = val
        if Config.AutoSave then saveConfig() end
    end
})

FarmTab:CreateToggle({
    Title = "Auto Replay Dungeon",
    Description = "Automatically votes replay upon finishing or clearing the dungeon",
    Default = Config.AutoReplayDungeon,
    Callback = function(val)
        Config.AutoReplayDungeon = val
        if Config.AutoSave then saveConfig() end
    end
})

FarmTab:CreateSection("FARMING CONFIGURATIONS")

FarmTab:CreateSlider({
    Title = "Flight Hover Height",
    Min = 3,
    Max = 20,
    Default = Config.FarmHeight,
    Suffix = " studs",
    Callback = function(val)
        Config.FarmHeight = val
        if Config.AutoSave then saveConfig() end
    end
})

FarmTab:CreateSlider({
    Title = "Skill Dodge Altitude",
    Min = 10,
    Max = 30,
    Default = Config.DodgeHeight,
    Suffix = " studs",
    Callback = function(val)
        Config.DodgeHeight = val
        if Config.AutoSave then saveConfig() end
    end
})

FarmTab:CreateSlider({
    Title = "Attack Loop Delay",
    Min = 0.04,
    Max = 0.3,
    Default = Config.AttackDelay,
    Decimals = 2,
    Suffix = "s",
    Callback = function(val)
        Config.AttackDelay = val
        if Config.AutoSave then saveConfig() end
    end
})

FarmTab:CreateToggle({
    Title = "Advance Next Tier On Replay",
    Description = "Automatically ascends to higher tier difficulty when cleared",
    Default = Config.AdvanceTier,
    Callback = function(val)
        Config.AdvanceTier = val
        if Config.AutoSave then saveConfig() end
    end
})

FarmTab:CreateToggle({
    Title = "Safe Mode",
    Description = "Ascends high into the sky when player health drops below 25%",
    Default = Config.SafeMode,
    Callback = function(val)
        Config.SafeMode = val
        if Config.AutoSave then saveConfig() end
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 2: DUNGEON CONTROLS
-- ═══════════════════════════════════════════════════════════════════════════
local DungeonTab = Window:CreateTab({
    Name = "Dungeon",
    Icon = "🏰"
})

DungeonTab:CreateSection("DUNGEON SELECTOR")

DungeonTab:CreateDropdown({
    Title = "Select Stage",
    Options = {
        "Desert Temple",
        "Winter Outpost",
        "Pirate Island",
        "King's Castle",
        "The Underworld",
        "Samurai Palace",
        "Ghastly Harbor",
        "Steampunk Sewers",
        "Orbital Outpost",
        "Volcanic Chambers"
    },
    Default = Config.SelectedStage,
    Callback = function(selected)
        Config.SelectedStage = selected
        MhnaaUI:Notify({
            Title = "Dungeon Selected",
            Content = "Target dungeon set to: " .. selected,
            Duration = 2
        })
    end
})

DungeonTab:CreateDropdown({
    Title = "Select Difficulty",
    Options = {"Easy", "Medium", "Hard", "Insane", "Nightmare"},
    Default = Config.SelectedDifficulty,
    Callback = function(selected)
        Config.SelectedDifficulty = selected
    end
})

DungeonTab:CreateSection("UTILITIES & BYPASS")

DungeonTab:CreateToggle({
    Title = "Noclip & Trap Immunity",
    Description = "Disables player collision to walk through walls, gates, and spike traps",
    Default = Config.Noclip,
    Callback = function(val)
        Config.Noclip = val
        if Config.AutoSave then saveConfig() end
    end
})

DungeonTab:CreateToggle({
    Title = "Auto Retry On Wipe",
    Description = "Automatically votes retry if all party members wipe",
    Default = Config.AutoRetryOnWipe,
    Callback = function(val)
        Config.AutoRetryOnWipe = val
        if Config.AutoSave then saveConfig() end
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 3: PLAYER & STATS
-- ═══════════════════════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab({
    Name = "Player & Stats",
    Icon = "👤"
})

PlayerTab:CreateSection("STAT AUTO-ALLOCATION")

PlayerTab:CreateToggle({
    Title = "Auto Allocate Skill Points",
    Description = "Automatically invests newly earned level-up stat points",
    Default = Config.AutoAllocateStats,
    Callback = function(val)
        Config.AutoAllocateStats = val
        if Config.AutoSave then saveConfig() end
    end
})

PlayerTab:CreateDropdown({
    Title = "Focus Stat",
    Options = {"Physical Power", "Spell Power", "Stamina"},
    Default = Config.SelectedStat,
    Callback = function(selected)
        Config.SelectedStat = selected
        if Config.AutoSave then saveConfig() end
    end
})

PlayerTab:CreateSection("CHARACTER ENHANCEMENTS")

PlayerTab:CreateSlider({
    Title = "WalkSpeed Multiplier",
    Min = 16,
    Max = 120,
    Default = Config.WalkSpeed,
    Suffix = " spd",
    Callback = function(val)
        Config.WalkSpeed = val
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = val end
    end
})

PlayerTab:CreateToggle({
    Title = "Infinite Jump",
    Description = "Allows continuous mid-air jumping without touching the ground",
    Default = Config.InfiniteJump,
    Callback = function(val)
        Config.InfiniteJump = val
    end
})

PlayerTab:CreateToggle({
    Title = "Anti-AFK Protection",
    Description = "Prevents Roblox 20-minute idle disconnect",
    Default = Config.AntiAFK,
    Callback = function(val)
        Config.AntiAFK = val
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 4: AUTO SELL & INVENTORY
-- ═══════════════════════════════════════════════════════════════════════════
local SellTab = Window:CreateTab({
    Name = "Inventory",
    Icon = "🎒"
})

SellTab:CreateSection("AUTO SELL ITEMS")

SellTab:CreateToggle({
    Title = "Enable Auto Sell",
    Description = "Automatically sells unwanted tier drops at the end of runs",
    Default = Config.AutoSell,
    Callback = function(val)
        Config.AutoSell = val
        if Config.AutoSave then saveConfig() end
    end
})

SellTab:CreateToggle({
    Title = "Sell Common Tier",
    Description = "Auto-sell all common gray tier weapons and armor",
    Default = Config.SellCommon,
    Callback = function(val)
        Config.SellCommon = val
    end
})

SellTab:CreateToggle({
    Title = "Sell Uncommon Tier",
    Description = "Auto-sell all uncommon green tier items",
    Default = Config.SellUncommon,
    Callback = function(val)
        Config.SellUncommon = val
    end
})

SellTab:CreateToggle({
    Title = "Sell Rare Tier",
    Description = "Auto-sell all rare blue tier items",
    Default = Config.SellRare,
    Callback = function(val)
        Config.SellRare = val
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 5: CONFIG PRESETS
-- ═══════════════════════════════════════════════════════════════════════════
local ConfigTab = Window:CreateTab({
    Name = "Config",
    Icon = "📁"
})

ConfigTab:CreateSection("SETTINGS PROFILE")

ConfigTab:CreateToggle({
    Title = "Auto-Save Settings",
    Description = "Automatically saves toggles and sliders to JSON when altered",
    Default = Config.AutoSave,
    Callback = function(val)
        Config.AutoSave = val
    end
})

ConfigTab:CreateButton({
    Title = "Save Current Config",
    Description = "Writes all current preferences to Mhnaa_DQ_Config.json",
    ButtonText = "SAVE",
    Callback = function()
        saveConfig()
        MhnaaUI:Notify({
            Title = "Configuration",
            Content = "All settings successfully saved!",
            Duration = 2.5
        })
    end
})

ConfigTab:CreateButton({
    Title = "Load Saved Config",
    Description = "Reloads preferences from disk",
    ButtonText = "LOAD",
    Callback = function()
        local ok = loadConfig()
        MhnaaUI:Notify({
            Title = "Configuration",
            Content = ok and "Settings loaded successfully!" or "No saved config found!",
            Duration = 2.5
        })
    end
})

-- Initial Startup Notification
loadConfig()
MhnaaUI:Notify({
    Title = "Mhnaa [PRO]",
    Content = "Dungeon Quest Automation loaded! Press RightControl to toggle UI.",
    Duration = 4
})
print("[Mhnaa [PRO]] Initialized successfully for Dungeon Quest!")
