--[[
    ═══════════════════════════════════════════════════════════════════════════
    ✨ DUNGEON QUEST AUTOMATION & ADVANCED AUTOFARM ✨
    Features:
      • Save & Load Settings System (Auto-Save to JSON file & UI Sync)
      • Perfectly Stable Downward Aiming (Zero Jitter, Zero Gimbal Shake)
      • Strict Single-Target Lock (No erratic teleporting; finishes current mob first)
      • Smart Room Progression (Only teleports forward when room is 100% cleared)
      • Advanced Boss & Mob Skill Dodging (Hooks into BridgeNet2 precastHitbox)
      • Smooth Anti-Damage Flight Hovering (Configurable Height & Dodge Altitude)
      • Rapid Weapon & Abilities Rotation (Q & E Spells Auto-Cast)
      • Boss Annihilation & Auto Replay / Next Tier
      • Auto Skill Point Allocation & Auto Sell
      • Built-in Anti-AFK, Noclip, and Speed Enhancer
      • Exact Dark Modern Glassmorphism UI (Matching reference layout)
    ═══════════════════════════════════════════════════════════════════════════
]]

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CONFIGURATION & DEFAULT VALUES
local Config = {
    -- Dungeon Automation (Main Features from UI)
    AutoStartDungeon = true,
    AutoKillAura = true,
    AutoCompleteStage = true,
    AutoDodgeBossSkill = true,
    AutoReplayDungeon = true,
    AutoCastAbilities = true,

    -- Hitbox & Farming Configurations
    FarmHeight = 7,                 -- Normal hover height above target mob (studs)
    DodgeHeight = 18,               -- Height added when dodging boss/mob skills (studs)
    AttackDelay = 0.08,             -- Attack loop delay (seconds)
    AdvanceTier = false,            -- Auto next tier on replay
    SafeMode = true,                -- Ascend high when low on HP
    SafeHealthPercent = 0.25,       -- Low HP retreat threshold (25%)
    AutoRetryOnWipe = true,

    -- Player & Stats
    AutoAllocateStats = true,
    SelectedStat = "physicalPower", -- "physicalPower", "spellPower", "stamina"
    WalkSpeed = 16,
    JumpPower = 50,
    Noclip = true,
    AntiAFK = true,
    InfiniteJump = false,

    -- Auto Sell
    AutoSell = false,
    SellCommon = true,
    SellUncommon = true,
    SellRare = false,
    SellEpic = false,

    -- Settings & File
    AutoSave = true,
    MobESP = false,
    BossESP = true,
    UIKeybind = "RightControl"
}

local Runtime = {
    CurrentLockedTarget = nil,      -- Strict target lock (will not switch until dead)
    CurrentRoomName = "None",
    EnemiesRemaining = 0,
    BossHealth = 0,
    BossMaxHealth = 0,
    RunsCompleted = 0,
    IsReplaying = false,
    IsDodging = false,              -- Active skill dodge flag
    DodgeEndTime = 0,
    StatusMessage = "Idle",
    ESPObjects = {}
}

-- UI CONTROLLERS REGISTRY (For dynamically syncing UI upon LoadConfig)
local UIControllers = {
    Toggles = {},
    Sliders = {}
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 💾 SAVE & LOAD SETTINGS SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════
local CONFIG_FILE = "DQ_Automation_Config.json"

local function saveConfig()
    local serialized = {}
    for k, v in pairs(Config) do
        if typeof(v) ~= "function" and typeof(v) ~= "Instance" then
            serialized[k] = v
        end
    end

    local success, jsonStr = pcall(function()
        return HttpService:JSONEncode(serialized)
    end)

    if success and jsonStr then
        if writefile then
            pcall(function()
                writefile(CONFIG_FILE, jsonStr)
            end)
        else
            _G.DQ_SavedConfig = jsonStr
        end
    end
end

local function loadConfig()
    local jsonStr = nil
    if isfile and readfile and isfile(CONFIG_FILE) then
        pcall(function()
            jsonStr = readfile(CONFIG_FILE)
        end)
    elseif _G.DQ_SavedConfig then
        jsonStr = _G.DQ_SavedConfig
    end

    if jsonStr then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(jsonStr)
        end)

        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                if Config[k] ~= nil then
                    Config[k] = v
                    -- Update UI Toggle Switch
                    if UIControllers.Toggles[k] then
                        pcall(function() UIControllers.Toggles[k](v, false) end)
                    end
                    -- Update UI Slider
                    if UIControllers.Sliders[k] then
                        pcall(function() UIControllers.Sliders[k](v, false) end)
                    end
                end
            end
            print("[DQ Automation] Config loaded successfully!")
            return true
        end
    end
    return false
end

-- REMOTES
local Remotes = {
    WeaponUsed = ReplicatedStorage:WaitForChild("remotes"):WaitForChild("weaponUsed"),
    AbilityUsed = ReplicatedStorage:WaitForChild("remotes"):WaitForChild("abilityUsed"),
    ReplayDungeon = ReplicatedStorage:WaitForChild("remotes"):WaitForChild("replayDungeon"),
    SpendSkillPoint = ReplicatedStorage:WaitForChild("remotes"):WaitForChild("spendSkillPoint"),
    ChangeStartValue = ReplicatedStorage:WaitForChild("remotes"):FindFirstChild("changeStartValue"),
    ReadyUp = ReplicatedStorage:WaitForChild("remotes"):FindFirstChild("readyUp"),
    SellItemEvent = ReplicatedStorage:WaitForChild("remotes"):FindFirstChild("sellItemEvent")
}

-- HELPER FUNCTIONS
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

-- TARGET VALIDATION (Ensures target is truly alive before switching)
local function isTargetAlive(target)
    if not target or not target.model or not target.model.Parent then return false end
    if not target.humanoid or not target.humanoid.Parent or target.humanoid.Health <= 0 then return false end
    if not target.rootPart or not target.rootPart.Parent then return false end
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🛡️ ADVANCED SKILL DODGE ENGINE ("NÉ SKILL")
-- ═══════════════════════════════════════════════════════════════════════════
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
                
                -- If player is inside or near the incoming skill telegraph radius
                if dist <= (hitRadius + 8) then
                    Runtime.IsDodging = true
                    Runtime.DodgeEndTime = os.clock() + delayTime + 0.35
                    Runtime.StatusMessage = "⚡ Dodging Boss Skill!"
                    
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

-- ANTI-AFK PROTECTION
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

-- NOCLIP HANDLER
RunService.Stepped:Connect(function()
    if Config.Noclip and (Config.AutoCompleteStage or Config.AutoKillAura) then
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

-- ═══════════════════════════════════════════════════════════════════════════
-- 🛸 PERFECTLY STABLE DOWNWARD AIMING & ANTI-JITTER ENGINE
-- ═══════════════════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp = getRootPart()
    local hum = getHumanoid()

    if char and hrp and hum and hum.Health > 0 then
        if (Config.AutoCompleteStage or Config.AutoKillAura) and Runtime.CurrentLockedTarget and isTargetAlive(Runtime.CurrentLockedTarget) then
            -- Zero velocity to prevent any physics momentum / falling
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            -- Freeze humanoid animation physics state to eliminate character twitching/falling cycles
            if not hum.PlatformStand then
                hum.PlatformStand = true
            end

            -- Target positioning
            local targetPos = Runtime.CurrentLockedTarget.rootPart.Position
            local hoverY = Config.FarmHeight

            -- Skill Dodge Altitude
            if Runtime.IsDodging and Config.AutoDodgeBossSkill then
                hoverY = hoverY + Config.DodgeHeight
            end

            local hoverPos = targetPos + Vector3.new(0, hoverY, 0)

            -- Mathematically stable lookAt straight down without gimbal lock singularity
            -- Explicit orthogonal UpVector (0, 0, -1) prevents rotation flips
            local stableLookDownCF = CFrame.lookAt(hoverPos, targetPos, Vector3.new(0, 0, -1))
            hrp.CFrame = stableLookDownCF
        else
            -- Restore normal platform stand when not actively locked on a flying mob
            if hum.PlatformStand then
                hum.PlatformStand = false
            end
        end
    end
end)

-- AUTO START DUNGEON
local function handleAutoStart()
    if not Config.AutoStartDungeon then return end
    local startVal = Workspace:FindFirstChild("start")
    local dsVal = Workspace:FindFirstChild("dungeonStarted")
    
    if (startVal and startVal.Value == false) or (dsVal and dsVal.Value == false) then
        if Remotes.ChangeStartValue then
            Remotes.ChangeStartValue:FireServer()
        end
        if Remotes.ReadyUp then
            Remotes.ReadyUp:FireServer()
        end
    end
end

-- COMBAT ENGINE: WEAPON ATTACK
local function triggerWeaponAttack()
    local char = LocalPlayer.Character
    if not char then return end

    local weaponAccessory = nil
    for _, child in pairs(char:GetChildren()) do
        if child:IsA("Accessory") and child:FindFirstChild("Weapon") then
            weaponAccessory = child
            break
        end
    end

    if weaponAccessory then
        local swingRemote = weaponAccessory:FindFirstChildOfClass("RemoteEvent")
        if swingRemote then
            swingRemote:FireServer()
        end
        Remotes.WeaponUsed:FireServer()
    end
end

-- COMBAT ENGINE: ABILITIES (Q & E)
local function triggerAbilities()
    if not Config.AutoCastAbilities then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end

    local char = LocalPlayer.Character
    local busyCasting = char and char:FindFirstChild("busyCasting")
    if busyCasting and busyCasting.Value == true then return end

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("abilitySlot") then
            local slot = tool.abilitySlot.Value
            local cd = tool:FindFirstChild("cooldown")
            if cd and cd.Value <= 0 then
                local localEvent = tool:FindFirstChild("localEvent")
                if localEvent then
                    localEvent:Fire()
                end
                Remotes.AbilityUsed:FireServer(slot, tool)
            end
        end
    end
end

-- STAT ALLOCATION
local function autoAllocatePoints()
    if not Config.AutoAllocateStats then return end
    local sp = LocalPlayer:FindFirstChild("skillPoints")
    if sp and sp.Value > 0 then
        Remotes.SpendSkillPoint:FireServer(Config.SelectedStat, sp.Value)
    end
end

-- DUNGEON PROGRESSION & ROOM DETECTION
local function getSortedRooms()
    local rooms = {}
    local dungeon = Workspace:FindFirstChild("dungeon")
    if dungeon then
        for _, room in ipairs(dungeon:GetChildren()) do
            local order = 0
            local orderVal = room:FindFirstChild("order")
            if orderVal and (orderVal:IsA("IntValue") or orderVal:IsA("NumberValue")) then
                order = orderVal.Value
            elseif room.Name:lower():find("boss") then
                order = 9999
            end
            table.insert(rooms, {room = room, order = order, name = room.Name})
        end
    end
    table.sort(rooms, function(a, b) return a.order < b.order end)
    return rooms
end

local function getAliveEnemiesInFolder(folder)
    local list = {}
    if not folder then return list end
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Model") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso")
            if hum and hum.Health > 0 and hrp then
                table.insert(list, {
                    model = obj,
                    humanoid = hum,
                    rootPart = hrp,
                    isBoss = folder.Name:lower():find("boss") or obj.Name:lower():find("boss")
                })
            end
        end
    end
    return list
end

local function getAllAliveEnemies()
    local all = {}
    local dungeon = Workspace:FindFirstChild("dungeon")
    if dungeon then
        for _, room in ipairs(dungeon:GetChildren()) do
            local ef = room:FindFirstChild("enemyFolder") or room:FindFirstChild("bossFolder")
            local enemies = getAliveEnemiesInFolder(ef)
            for _, e in ipairs(enemies) do
                e.room = room
                table.insert(all, e)
            end
        end
    end

    local wsEnemies = Workspace:FindFirstChild("enemies")
    if wsEnemies then
        for _, e in ipairs(getAliveEnemiesInFolder(wsEnemies)) do
            table.insert(all, e)
        end
    end

    return all
end

local function collectDungeonData()
    local data = {}
    local dn = Workspace:FindFirstChild("dungeonName")
    if dn and dn:IsA("StringValue") then data.dungeonName = dn.Value end
    local dp = Workspace:FindFirstChild("dungeonProgress")
    if dp and dp:IsA("StringValue") then data.dungeonProgress = dp.Value end
    local ds = Workspace:FindFirstChild("dungeonStarted")
    if ds and ds:IsA("BoolValue") then data.dungeonStarted = ds.Value end
    local hc = Workspace:FindFirstChild("hardcore")
    if hc and hc:IsA("BoolValue") then
        data.hardcore = hc.Value
        data.isHardcore = hc.Value
    end

    local dungeon = Workspace:FindFirstChild("dungeon")
    if dungeon then
        for _, child in ipairs(dungeon:GetChildren()) do
            if child:IsA("ValueBase") then data[child.Name] = child.Value end
        end
        local bossRoom = dungeon:FindFirstChild("bossRoom")
        if bossRoom then
            for _, child in ipairs(bossRoom:GetChildren()) do
                if child:IsA("ValueBase") then data[child.Name] = child.Value end
            end
        end
    end

    if Config.AdvanceTier then
        data.advanceTier = true
    end
    return data
end

-- AUTO REPLAY CHECKER
local function checkDungeonCompleted()
    local dungeonProgress = Workspace:FindFirstChild("dungeonProgress")
    local bossRoom = Workspace:FindFirstChild("dungeon") and Workspace.dungeon:FindFirstChild("bossRoom")
    local dungeonFinished = bossRoom and bossRoom:FindFirstChild("dungeonFinished")

    local isFinished = false
    if dungeonProgress and (dungeonProgress.Value == "finished" or dungeonProgress.Value == "victory") then
        isFinished = true
    elseif dungeonFinished and dungeonFinished:IsA("BoolValue") and dungeonFinished.Value == true then
        isFinished = true
    end

    return isFinished
end

-- ESP SYSTEM
local function updateESP()
    for model, highlight in pairs(Runtime.ESPObjects) do
        if not model or not model.Parent or not model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildOfClass("Humanoid").Health <= 0 then
            highlight:Destroy()
            Runtime.ESPObjects[model] = nil
        end
    end

    if not Config.MobESP and not Config.BossESP then
        for model, highlight in pairs(Runtime.ESPObjects) do
            highlight:Destroy()
            Runtime.ESPObjects[model] = nil
        end
        return
    end

    local enemies = getAllAliveEnemies()
    for _, enemy in ipairs(enemies) do
        local isBoss = enemy.isBoss
        if (isBoss and Config.BossESP) or (not isBoss and Config.MobESP) then
            if not Runtime.ESPObjects[enemy.model] then
                local highlight = Instance.new("Highlight")
                highlight.Name = "DQ_ESP"
                highlight.Adornee = enemy.model
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                if isBoss then
                    highlight.FillColor = Color3.fromRGB(255, 170, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                else
                    highlight.FillColor = Color3.fromRGB(0, 162, 255)
                    highlight.OutlineColor = Color3.fromRGB(120, 200, 255)
                end
                highlight.Parent = enemy.model
                Runtime.ESPObjects[enemy.model] = highlight
            end
        end
    end
end

-- AUTO SELL SYSTEM
local function handleAutoSell()
    if not Config.AutoSell or not Remotes.SellItemEvent then return end
    local inv = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("inventory")
    local scroll = inv and inv.mainBackground.innerBackground.rightSideFrame.ScrollingFrame
    if not scroll then return end

    local toSell = { weapon = {}, ability = {}, chest = {}, helmet = {} }
    local hasItems = false

    for _, child in pairs(scroll:GetChildren()) do
        if child:IsA("ImageLabel") and child:FindFirstChild("itemType") and child:FindFirstChild("rarity") then
            local r = child.rarity.Value:lower()
            local shouldSell = false
            if r == "common" and Config.SellCommon then shouldSell = true
            elseif r == "uncommon" and Config.SellUncommon then shouldSell = true
            elseif r == "rare" and Config.SellRare then shouldSell = true
            elseif r == "epic" and Config.SellEpic then shouldSell = true
            end

            if shouldSell and child.itemType:FindFirstChild("uniqueItemNum") then
                local itype = child.itemType.Value
                if toSell[itype] then
                    table.insert(toSell[itype], child.itemType.uniqueItemNum.Value)
                    hasItems = true
                end
            end
        end
    end

    if hasItems then
        Remotes.SellItemEvent:FireServer(toSell)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🚀 CORE AUTOFARM LOOP (STRICT TARGET LOCKING & ZERO ERRATIC TELEPORTS)
-- ═══════════════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        handleAutoStart()

        local char = LocalPlayer.Character
        local hrp = getRootPart()
        local hum = getHumanoid()

        if char and hrp and hum and hum.Health > 0 then
            -- 1. Check if Dungeon is Completed
            if checkDungeonCompleted() then
                Runtime.CurrentLockedTarget = nil
                Runtime.StatusMessage = "Stage Cleared! Replaying..."
                if Config.AutoReplayDungeon and not Runtime.IsReplaying then
                    Runtime.IsReplaying = true
                    Runtime.RunsCompleted = Runtime.RunsCompleted + 1
                    handleAutoSell()
                    task.wait(2.0)
                    local replayData = collectDungeonData()
                    Remotes.ReplayDungeon:FireServer(replayData)
                    task.wait(3.0)
                    Runtime.IsReplaying = false
                end
            else
                if Config.AutoCompleteStage or Config.AutoKillAura then
                    -- 2. Safe Mode Low HP Retreat
                    if Config.SafeMode and (hum.Health / hum.MaxHealth) < Config.SafeHealthPercent then
                        Runtime.StatusMessage = "Safe Mode: Retreating Upwards..."
                        hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + 22, hrp.Position.Z)
                        triggerAbilities()
                        task.wait(0.4)
                    else
                        -- 3. Check if currently locked target is still alive
                        if not isTargetAlive(Runtime.CurrentLockedTarget) then
                            Runtime.CurrentLockedTarget = nil
                        end

                        local sortedRooms = getSortedRooms()

                        -- 4. If no locked target, find the next closest mob in the current active room
                        if not Runtime.CurrentLockedTarget then
                            for _, r in ipairs(sortedRooms) do
                                local ef = r.room:FindFirstChild("enemyFolder") or r.room:FindFirstChild("bossFolder")
                                local roomEnemies = getAliveEnemiesInFolder(ef)
                                if #roomEnemies > 0 then
                                    -- Lock onto the closest alive mob in this room
                                    local closest = nil
                                    local closestDist = math.huge
                                    for _, e in ipairs(roomEnemies) do
                                        local d = (hrp.Position - e.rootPart.Position).Magnitude
                                        if d < closestDist then
                                            closestDist = d
                                            closest = e
                                        end
                                    end
                                    Runtime.CurrentLockedTarget = closest
                                    Runtime.CurrentRoomName = r.name
                                    Runtime.EnemiesRemaining = #roomEnemies
                                    break
                                end
                            end
                        end

                        -- 5. If we have a locked target: Attack and cast skills
                        if Runtime.CurrentLockedTarget and isTargetAlive(Runtime.CurrentLockedTarget) then
                            local target = Runtime.CurrentLockedTarget
                            Runtime.StatusMessage = "Farming: " .. target.model.Name
                            
                            if target.isBoss then
                                Runtime.BossHealth = target.humanoid.Health
                                Runtime.BossMaxHealth = target.humanoid.MaxHealth
                            end

                            -- Attack current target & cast skills
                            triggerWeaponAttack()
                            triggerAbilities()

                        else
                            -- 6. All mobs in the active room are DEAD -> Only NOW advance to next room trigger!
                            Runtime.CurrentLockedTarget = nil
                            if Config.AutoCompleteStage then
                                local roomProgressed = false
                                for _, r in ipairs(sortedRooms) do
                                    if r.order > 0 then
                                        local barrier = r.room:FindFirstChild("barrier")
                                        local startPart = r.room:FindFirstChild("startPart") or r.room:FindFirstChild("checkPoint")
                                        if startPart and (not barrier or barrier.CanCollide == true) then
                                            Runtime.StatusMessage = "Room Cleared! Advancing to " .. r.name
                                            Runtime.CurrentRoomName = r.name
                                            -- Teleport ONCE to the room entrance
                                            hrp.CFrame = CFrame.new(startPart.Position + Vector3.new(0, 4, 0))
                                            roomProgressed = true
                                            task.wait(0.35) -- Wait for room wave to spawn
                                            break
                                        end
                                    end
                                end

                                if not roomProgressed then
                                    local bossRoom = Workspace:FindFirstChild("dungeon") and Workspace.dungeon:FindFirstChild("bossRoom")
                                    if bossRoom and bossRoom:FindFirstChild("startPart") then
                                        Runtime.StatusMessage = "Entering Boss Arena..."
                                        Runtime.CurrentRoomName = "bossRoom"
                                        hrp.CFrame = CFrame.new(bossRoom.startPart.Position + Vector3.new(0, 4, 0))
                                        task.wait(0.35)
                                    end
                                end
                            end
                        end
                    end
                end

                -- Auto Stat Allocation
                autoAllocatePoints()
            end
        else
            Runtime.CurrentLockedTarget = nil
            Runtime.StatusMessage = "Waiting for Respawn..."
        end

        updateESP()
        task.wait(Config.AttackDelay)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎨 EXACT REPLICA UI (Dark Glassmorphism with Blue Neon Toggles)
-- ═══════════════════════════════════════════════════════════════════════════

local GUI_NAME = "DQ_Automation_Modern_UI"
local existingGui = CoreGui:FindFirstChild(GUI_NAME) or LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(GUI_NAME)
if existingGui then existingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- MAIN ROOT FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 360)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(32, 34, 44)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- DRAGGABLE SYSTEM
local isDragging, dragStart, startPos = false, nil, nil
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then isDragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- LEFT SIDEBAR
local SideBar = Instance.new("Frame")
SideBar.Name = "SideBar"
SideBar.Size = UDim2.new(0, 135, 1, 0)
SideBar.BackgroundColor3 = Color3.fromRGB(15, 16, 21)
SideBar.BorderSizePixel = 0
SideBar.Parent = MainFrame

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 8)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = SideBar

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 14)
SidePadding.PaddingLeft = UDim.new(0, 10)
SidePadding.PaddingRight = UDim.new(0, 10)
SidePadding.Parent = SideBar

-- DIVIDER BETWEEN SIDEBAR AND CONTENT
local VerticalDivider = Instance.new("Frame")
VerticalDivider.Size = UDim2.new(0, 1, 1, 0)
VerticalDivider.Position = UDim2.new(0, 135, 0, 0)
VerticalDivider.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
VerticalDivider.BorderSizePixel = 0
VerticalDivider.Parent = MainFrame

-- RIGHT CONTENT CONTAINER
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -145, 1, 0)
ContentArea.Position = UDim2.new(0, 145, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame

local Tabs = {}
local TabButtons = {}

local function createTab(tabName, iconText)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = tabName .. "Page"
    scroll.Size = UDim2.new(1, -12, 1, -12)
    scroll.Position = UDim2.new(0, 0, 0, 8)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(45, 48, 62)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 560)
    scroll.Visible = false
    scroll.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local btn = Instance.new("TextButton")
    btn.Name = tabName .. "Tab"
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(22, 24, 31)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamMedium
    btn.Text = " " .. iconText .. "  " .. tabName
    btn.TextColor3 = Color3.fromRGB(150, 155, 170)
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = SideBar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(28, 30, 40)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.Visible = false end
        for _, b in pairs(TabButtons) do
            b.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
            b.TextColor3 = Color3.fromRGB(140, 145, 160)
            b:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(28, 30, 40)
        end
        scroll.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
        btn.TextColor3 = Color3.fromRGB(240, 240, 245)
        btnStroke.Color = Color3.fromRGB(45, 50, 68)
    end)

    table.insert(TabButtons, btn)
    Tabs[tabName] = scroll
    return scroll
end

-- UI HEADERS & TOGGLES (Matching Screenshot Exactly)
local function addSectionHeader(parent, text)
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, -10, 0, 26)
    headerFrame.BackgroundTransparency = 1
    headerFrame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 225, 235)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = headerFrame

    local underline = Instance.new("Frame")
    underline.Size = UDim2.new(1, 0, 0, 1)
    underline.Position = UDim2.new(0, 0, 1, -2)
    underline.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
    underline.BorderSizePixel = 0
    underline.Parent = headerFrame

    return headerFrame
end

local function addToggleRow(parent, configKey, title, defaultState, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(18, 19, 26)
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color = Color3.fromRGB(28, 30, 40)
    rowStroke.Thickness = 1
    rowStroke.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -65, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.Text = title
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    -- Switch Container (Pill)
    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 44, 0, 22)
    switch.Position = UDim2.new(1, -56, 0.5, -11)
    switch.BackgroundColor3 = defaultState and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(30, 32, 42)
    switch.BorderSizePixel = 0
    switch.Text = ""
    switch.Parent = row

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(1, 0)
    sCorner.Parent = switch

    -- Switch Knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = defaultState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = defaultState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 205)
    knob.BorderSizePixel = 0
    knob.Parent = switch

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

    local state = defaultState

    local function updateState(newState, triggerSave)
        state = newState
        Config[configKey] = newState
        TweenService:Create(switch, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = state and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(30, 32, 42)
        }):Play()

        knob:TweenPosition(
            state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.18,
            true
        )
        if callback then callback(state) end
        if triggerSave ~= false and Config.AutoSave then
            saveConfig()
        end
    end

    switch.MouseButton1Click:Connect(function()
        updateState(not state, true)
    end)

    if configKey then
        UIControllers.Toggles[configKey] = function(val, triggerSave)
            updateState(val, triggerSave)
        end
    end

    return row
end

local function addSliderRow(parent, configKey, title, minVal, maxVal, defaultVal, suffix, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(18, 19, 26)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(28, 30, 40)
    stroke.Thickness = 1
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 0, 22)
    label.Position = UDim2.new(0, 14, 0, 4)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.Text = title
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.3, 0, 0, 22)
    valLabel.Position = UDim2.new(0.7, -14, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.Code
    valLabel.Text = tostring(defaultVal) .. suffix
    valLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
    valLabel.TextSize = 12
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 5)
    track.Position = UDim2.new(0, 14, 0, 33)
    track.BackgroundColor3 = Color3.fromRGB(36, 39, 52)
    track.BorderSizePixel = 0
    track.Parent = frame

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = track

    local fill = Instance.new("Frame")
    local pct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(1, 0)
    fCorner.Parent = fill

    local sliding = false
    local function updateSlide(input, triggerSave)
        local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        local value
        if suffix == "s" then
            value = math.floor((minVal + (maxVal - minVal) * relX) * 100) / 100
        else
            value = math.floor(minVal + (maxVal - minVal) * relX)
        end
        valLabel.Text = tostring(value) .. suffix
        Config[configKey] = value
        if callback then callback(value) end
        if triggerSave ~= false and Config.AutoSave then
            saveConfig()
        end
    end

    local function setValue(val, triggerSave)
        local relX = math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        valLabel.Text = tostring(val) .. suffix
        Config[configKey] = val
        if callback then callback(val) end
        if triggerSave ~= false and Config.AutoSave then
            saveConfig()
        end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateSlide(input, true)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlide(input, true)
        end
    end)

    if configKey then
        UIControllers.Sliders[configKey] = function(val, triggerSave)
            setValue(val, triggerSave)
        end
    end

    return frame
end

local function addButtonRow(parent, title, btnText, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(18, 19, 26)
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color = Color3.fromRGB(28, 30, 40)
    rowStroke.Thickness = 1
    rowStroke.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -120, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.Text = title
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 26)
    btn.Position = UDim2.new(1, -108, 0.5, -13)
    btn.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.Text = btnText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Parent = row

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
    return row
end

-- INITIALIZE TABS
local AutoFarmTab = createTab("Auto Farm", "🔥")
local DungeonTab = createTab("Dungeon...", "🚀")
local PlayerTab = createTab("Player &...", "👤")
local SettingsTab = createTab("Settings", "⚙️")

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 1: AUTO FARM (Exact match with user image)
-- ═══════════════════════════════════════════════════════════════════════════
addSectionHeader(AutoFarmTab, "DUNGEON AUTOMATION")
addToggleRow(AutoFarmTab, "AutoStartDungeon", "Auto Start Dungeon", Config.AutoStartDungeon, function(val) Config.AutoStartDungeon = val end)
addToggleRow(AutoFarmTab, "AutoKillAura", "Auto Kill Aura (Attack Only)", Config.AutoKillAura, function(val) Config.AutoKillAura = val end)
addToggleRow(AutoFarmTab, "AutoCompleteStage", "Auto Complete Stage (Full Farm)", Config.AutoCompleteStage, function(val) Config.AutoCompleteStage = val end)
addToggleRow(AutoFarmTab, "AutoDodgeBossSkill", "Auto Dodge Boss skill", Config.AutoDodgeBossSkill, function(val) Config.AutoDodgeBossSkill = val end)
addToggleRow(AutoFarmTab, "AutoReplayDungeon", "Auto Replay Dungeon", Config.AutoReplayDungeon, function(val) Config.AutoReplayDungeon = val end)
addToggleRow(AutoFarmTab, "AutoCastAbilities", "Auto Cast Abilities (Q & E)", Config.AutoCastAbilities, function(val) Config.AutoCastAbilities = val end)

addSectionHeader(AutoFarmTab, "HITBOX & FARMING CONFIGURATIONS")
addSliderRow(AutoFarmTab, "FarmHeight", "Flight Height Above Mobs", 3, 18, Config.FarmHeight, " studs", function(val) Config.FarmHeight = val end)
addSliderRow(AutoFarmTab, "DodgeHeight", "Skill Dodge Altitude", 10, 30, Config.DodgeHeight, " studs", function(val) Config.DodgeHeight = val end)
addSliderRow(AutoFarmTab, "AttackDelay", "Attack Loop Delay", 0.05, 0.4, Config.AttackDelay, "s", function(val) Config.AttackDelay = val end)
addToggleRow(AutoFarmTab, "AdvanceTier", "Advance To Next Tier On Replay", Config.AdvanceTier, function(val) Config.AdvanceTier = val end)
addToggleRow(AutoFarmTab, "SafeMode", "Safe Mode (Ascend On Low HP)", Config.SafeMode, function(val) Config.SafeMode = val end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 2: DUNGEON UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════
addSectionHeader(DungeonTab, "DUNGEON CONTROLS")
addToggleRow(DungeonTab, "AutoRetryOnWipe", "Auto Retry On Wipe / Death", Config.AutoRetryOnWipe, function(val) Config.AutoRetryOnWipe = val end)
addToggleRow(DungeonTab, "Noclip", "Noclip & Trap Immunity", Config.Noclip, function(val) Config.Noclip = val end)
addToggleRow(DungeonTab, "BossESP", "Boss ESP Highlight", Config.BossESP, function(val) Config.BossESP = val end)
addToggleRow(DungeonTab, "MobESP", "Mob ESP Highlight", Config.MobESP, function(val) Config.MobESP = val end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 3: PLAYER & STATS
-- ═══════════════════════════════════════════════════════════════════════════
addSectionHeader(PlayerTab, "STAT AUTO-ALLOCATION")
addToggleRow(PlayerTab, "AutoAllocateStats", "Auto Allocate Skill Points", Config.AutoAllocateStats, function(val) Config.AutoAllocateStats = val end)
addToggleRow(PlayerTab, "FocusPhys", "Focus Physical Power (Melee)", Config.SelectedStat == "physicalPower", function(val)
    if val then Config.SelectedStat = "physicalPower" end
end)
addToggleRow(PlayerTab, "FocusSpell", "Focus Spell Power (Mage)", Config.SelectedStat == "spellPower", function(val)
    if val then Config.SelectedStat = "spellPower" end
end)
addToggleRow(PlayerTab, "FocusStam", "Focus Stamina (Max HP)", Config.SelectedStat == "stamina", function(val)
    if val then Config.SelectedStat = "stamina" end
end)

addSectionHeader(PlayerTab, "CHARACTER ENHANCEMENTS")
addSliderRow(PlayerTab, "WalkSpeed", "Player WalkSpeed", 16, 120, Config.WalkSpeed, " spd", function(val)
    Config.WalkSpeed = val
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = val end
end)
addToggleRow(PlayerTab, "InfiniteJump", "Infinite Jump in Air", Config.InfiniteJump, function(val) Config.InfiniteJump = val end)
addToggleRow(PlayerTab, "AntiAFK", "Anti-AFK 20-Min Protection", Config.AntiAFK, function(val) Config.AntiAFK = val end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 4: SETTINGS & AUTO SELL
-- ═══════════════════════════════════════════════════════════════════════════
addSectionHeader(SettingsTab, "CONFIG FILE & PRESETS")
addToggleRow(SettingsTab, "AutoSave", "Auto-Save Settings On Change", Config.AutoSave, function(val) Config.AutoSave = val end)
addButtonRow(SettingsTab, "Save Current Settings", "SAVE CONFIG", function(btn)
    saveConfig()
    btn.Text = "SAVED!"
    task.delay(1.5, function() btn.Text = "SAVE CONFIG" end)
end)
addButtonRow(SettingsTab, "Load Saved Settings", "LOAD CONFIG", function(btn)
    local loaded = loadConfig()
    btn.Text = loaded and "LOADED!" or "NO FILE"
    task.delay(1.5, function() btn.Text = "LOAD CONFIG" end)
end)

addSectionHeader(SettingsTab, "INVENTORY & AUTO SELL")
addToggleRow(SettingsTab, "AutoSell", "Enable Auto Sell", Config.AutoSell, function(val) Config.AutoSell = val end)
addToggleRow(SettingsTab, "SellCommon", "Sell Common Tier Items", Config.SellCommon, function(val) Config.SellCommon = val end)
addToggleRow(SettingsTab, "SellUncommon", "Sell Uncommon Tier Items", Config.SellUncommon, function(val) Config.SellUncommon = val end)
addToggleRow(SettingsTab, "SellRare", "Sell Rare Tier Items", Config.SellRare, function(val) Config.SellRare = val end)

-- DEFAULT ACTIVE TAB
Tabs["Auto Farm"].Visible = true
TabButtons[1].BackgroundColor3 = Color3.fromRGB(28, 30, 40)
TabButtons[1].TextColor3 = Color3.fromRGB(240, 240, 245)

-- MINIMIZE / TOGGLE KEYBIND
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode[Config.UIKeybind] then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- AUTO-LOAD CONFIGURATION ON STARTUP
loadConfig()

print("[DQ Automation] Successfully initialized with Save/Load Settings & Smooth Downward Stability!")
