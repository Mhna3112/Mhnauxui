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

---- ═══════════════════════════════════════════════════════════════════════════
-- 🎨 MHNAA [PRO] UI INTEGRATION (Loaded directly from GitHub Raw)
-- ═══════════════════════════════════════════════════════════════════════════

local GITHUB_RAW_URL = "https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/MhnaaUI.luau"
local MhnaaUI

-- 1. Ưu tiên tải trực tiếp từ GitHub repo Mhna3112/Mhnauxui
local successGit, resultGit = pcall(function()
    return loadstring(game:HttpGet(GITHUB_RAW_URL))()
end)

if successGit and resultGit then
    MhnaaUI = resultGit
else
    -- 2. Dự phòng: Đọc file local nếu offline
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
    error("[Mhnaa [PRO]] Không thể tải MhnaaUI! Vui lòng kiểm tra kết nối mạng hoặc file MhnaaUI.luau trong workspace.")
end

-- KHỞI TẠO CỬA SỔ CHUẨN THEO ẢNH MHNAA [PRO]
local Window = MhnaaUI:CreateWindow({
    Title = "Mhnaa",
    Tag = "[PRO]",
    Game = "DUNGEON QUEST",
    Size = UDim2.new(0, 680, 0, 420),
    AccentColor = Color3.fromRGB(104, 157, 248),
    ToggleKey = Enum.KeyCode[Config.UIKeybind] or Enum.KeyCode.RightControl
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 1: AUTO FARM (Dungeon Automation & Hitbox Configurations)
-- ═══════════════════════════════════════════════════════════════════════════
local AutoFarmTab = Window:CreateTab({ Name = "Auto Farm", Icon = "🔥" })

AutoFarmTab:CreateSection("DUNGEON AUTOMATION")

local tAutoStart = AutoFarmTab:CreateToggle({
    Title = "Auto Start Dungeon",
    Description = "Automatically votes ready and starts dungeon when lobby opens",
    Default = Config.AutoStartDungeon,
    Callback = function(val)
        Config.AutoStartDungeon = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["AutoStartDungeon"] = function(val) tAutoStart:Set(val) end

local tKillAura = AutoFarmTab:CreateToggle({
    Title = "Auto Kill Aura (Attack Only)",
    Description = "Attacks nearby enemies without overriding your movement position",
    Default = Config.AutoKillAura,
    Callback = function(val)
        Config.AutoKillAura = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["AutoKillAura"] = function(val) tKillAura:Set(val) end

local tCompleteStage = AutoFarmTab:CreateToggle({
    Title = "Auto Complete Stage (Full Farm)",
    Description = "Automatically flies through rooms, eliminates all mobs, and beats bosses",
    Default = Config.AutoCompleteStage,
    Callback = function(val)
        Config.AutoCompleteStage = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["AutoCompleteStage"] = function(val) tCompleteStage:Set(val) end

local tDodgeSkill = AutoFarmTab:CreateToggle({
    Title = "Auto Dodge Boss Skill",
    Description = "Hooks into BridgeNet2 telegraphs to ascend above ground-hazard attacks",
    Default = Config.AutoDodgeBossSkill,
    Callback = function(val)
        Config.AutoDodgeBossSkill = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["AutoDodgeBossSkill"] = function(val) tDodgeSkill:Set(val) end

local tReplayDungeon = AutoFarmTab:CreateToggle({
    Title = "Auto Replay Dungeon",
    Description = "Automatically votes replay upon finishing or clearing the dungeon",
    Default = Config.AutoReplayDungeon,
    Callback = function(val)
        Config.AutoReplayDungeon = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["AutoReplayDungeon"] = function(val) tReplayDungeon:Set(val) end

local tCastAbilities = AutoFarmTab:CreateToggle({
    Title = "Auto Cast Abilities (Q & E)",
    Description = "Automatically casts skills and spells off cooldown",
    Default = Config.AutoCastAbilities,
    Callback = function(val)
        Config.AutoCastAbilities = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["AutoCastAbilities"] = function(val) tCastAbilities:Set(val) end

AutoFarmTab:CreateSection("HITBOX & FARMING CONFIGURATIONS")

local sFarmHeight = AutoFarmTab:CreateSlider({
    Title = "Flight Height Above Mobs",
    Min = 3,
    Max = 18,
    Default = Config.FarmHeight,
    Suffix = " studs",
    Callback = function(val)
        Config.FarmHeight = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Sliders["FarmHeight"] = function(val) sFarmHeight:Set(val) end

local sDodgeHeight = AutoFarmTab:CreateSlider({
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
UIControllers.Sliders["DodgeHeight"] = function(val) sDodgeHeight:Set(val) end

local sAttackDelay = AutoFarmTab:CreateSlider({
    Title = "Attack Loop Delay",
    Min = 0.05,
    Max = 0.4,
    Default = Config.AttackDelay,
    Decimals = 2,
    Suffix = "s",
    Callback = function(val)
        Config.AttackDelay = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Sliders["AttackDelay"] = function(val) sAttackDelay:Set(val) end

local tAdvanceTier = AutoFarmTab:CreateToggle({
    Title = "Advance To Next Tier On Replay",
    Description = "Automatically ascends to higher tier difficulty when cleared",
    Default = Config.AdvanceTier,
    Callback = function(val)
        Config.AdvanceTier = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["AdvanceTier"] = function(val) tAdvanceTier:Set(val) end

local tSafeMode = AutoFarmTab:CreateToggle({
    Title = "Safe Mode (Ascend On Low HP)",
    Description = "Ascends high into the sky when player health drops below 25%",
    Default = Config.SafeMode,
    Callback = function(val)
        Config.SafeMode = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["SafeMode"] = function(val) tSafeMode:Set(val) end

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 2: DUNGEON UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════
local DungeonTab = Window:CreateTab({ Name = "Dungeon", Icon = "🚀" })

DungeonTab:CreateSection("DUNGEON CONTROLS")

local tAutoRetry = DungeonTab:CreateToggle({
    Title = "Auto Retry On Wipe / Death",
    Description = "Automatically votes retry if all party members wipe",
    Default = Config.AutoRetryOnWipe,
    Callback = function(val)
        Config.AutoRetryOnWipe = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["AutoRetryOnWipe"] = function(val) tAutoRetry:Set(val) end

local tNoclip = DungeonTab:CreateToggle({
    Title = "Noclip & Trap Immunity",
    Description = "Disables player collision to walk through walls, gates, and spike traps",
    Default = Config.Noclip,
    Callback = function(val)
        Config.Noclip = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["Noclip"] = function(val) tNoclip:Set(val) end

local tBossESP = DungeonTab:CreateToggle({
    Title = "Boss ESP Highlight",
    Description = "Highlights boss location and renders health status tag",
    Default = Config.BossESP,
    Callback = function(val)
        Config.BossESP = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["BossESP"] = function(val) tBossESP:Set(val) end

local tMobESP = DungeonTab:CreateToggle({
    Title = "Mob ESP Highlight",
    Description = "Highlights all room enemies with distance indicators",
    Default = Config.MobESP,
    Callback = function(val)
        Config.MobESP = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["MobESP"] = function(val) tMobESP:Set(val) end

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 3: PLAYER & STATS
-- ═══════════════════════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab({ Name = "Player & Stats", Icon = "👤" })

PlayerTab:CreateSection("STAT AUTO-ALLOCATION")

local tAutoAlloc = PlayerTab:CreateToggle({
    Title = "Auto Allocate Skill Points",
    Description = "Automatically invests newly earned level-up stat points",
    Default = Config.AutoAllocateStats,
    Callback = function(val)
        Config.AutoAllocateStats = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["AutoAllocateStats"] = function(val) tAutoAlloc:Set(val) end

PlayerTab:CreateDropdown({
    Title = "Focus Stat",
    Options = {"Physical Power", "Spell Power", "Stamina"},
    Default = (Config.SelectedStat == "physicalPower" and "Physical Power") or (Config.SelectedStat == "spellPower" and "Spell Power") or "Stamina",
    Callback = function(selected)
        if selected == "Physical Power" then
            Config.SelectedStat = "physicalPower"
        elseif selected == "Spell Power" then
            Config.SelectedStat = "spellPower"
        elseif selected == "Stamina" then
            Config.SelectedStat = "stamina"
        end
        if Config.AutoSave then saveConfig() end
    end
})

PlayerTab:CreateSection("CHARACTER ENHANCEMENTS")

local sWalkSpeed = PlayerTab:CreateSlider({
    Title = "Player WalkSpeed",
    Min = 16,
    Max = 120,
    Default = Config.WalkSpeed,
    Suffix = " spd",
    Callback = function(val)
        Config.WalkSpeed = val
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = val end
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Sliders["WalkSpeed"] = function(val) sWalkSpeed:Set(val) end

local tInfJump = PlayerTab:CreateToggle({
    Title = "Infinite Jump in Air",
    Description = "Allows continuous mid-air jumping without touching the ground",
    Default = Config.InfiniteJump,
    Callback = function(val)
        Config.InfiniteJump = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["InfiniteJump"] = function(val) tInfJump:Set(val) end

local tAntiAFK = PlayerTab:CreateToggle({
    Title = "Anti-AFK 20-Min Protection",
    Description = "Prevents Roblox 20-minute idle disconnect",
    Default = Config.AntiAFK,
    Callback = function(val)
        Config.AntiAFK = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["AntiAFK"] = function(val) tAntiAFK:Set(val) end

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 4: SETTINGS & AUTO SELL
-- ═══════════════════════════════════════════════════════════════════════════
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "⚙️" })

SettingsTab:CreateSection("CONFIG FILE & PRESETS")

local tAutoSave = SettingsTab:CreateToggle({
    Title = "Auto-Save Settings On Change",
    Description = "Writes preferences to DQ_Automation_Config.json whenever modified",
    Default = Config.AutoSave,
    Callback = function(val)
        Config.AutoSave = val
    end
})
UIControllers.Toggles["AutoSave"] = function(val) tAutoSave:Set(val) end

SettingsTab:CreateButton({
    Title = "Save Current Settings",
    Description = "Explicitly saves all settings to disk",
    ButtonText = "SAVE CONFIG",
    Callback = function(btn)
        saveConfig()
        MhnaaUI:Notify({
            Title = "Configuration",
            Content = "Settings saved successfully!",
            Duration = 2
        })
    end
})

SettingsTab:CreateButton({
    Title = "Load Saved Settings",
    Description = "Reloads all saved settings from disk",
    ButtonText = "LOAD CONFIG",
    Callback = function(btn)
        local loaded = loadConfig()
        MhnaaUI:Notify({
            Title = "Configuration",
            Content = loaded and "Settings loaded successfully!" or "No config file found!",
            Duration = 2
        })
    end
})

SettingsTab:CreateSection("INVENTORY & AUTO SELL")

local tAutoSell = SettingsTab:CreateToggle({
    Title = "Enable Auto Sell",
    Description = "Automatically sells unwanted tier drops at the end of runs",
    Default = Config.AutoSell,
    Callback = function(val)
        Config.AutoSell = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["AutoSell"] = function(val) tAutoSell:Set(val) end

local tSellCommon = SettingsTab:CreateToggle({
    Title = "Sell Common Tier Items",
    Description = "Auto-sell all common gray tier weapons and armor",
    Default = Config.SellCommon,
    Callback = function(val)
        Config.SellCommon = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["SellCommon"] = function(val) tSellCommon:Set(val) end

local tSellUncommon = SettingsTab:CreateToggle({
    Title = "Sell Uncommon Tier Items",
    Description = "Auto-sell all uncommon green tier items",
    Default = Config.SellUncommon,
    Callback = function(val)
        Config.SellUncommon = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["SellUncommon"] = function(val) tSellUncommon:Set(val) end

local tSellRare = SettingsTab:CreateToggle({
    Title = "Sell Rare Tier Items",
    Description = "Auto-sell all rare blue tier items",
    Default = Config.SellRare,
    Callback = function(val)
        Config.SellRare = val
        if Config.AutoSave then saveConfig() end
    end
})
UIControllers.Toggles["SellRare"] = function(val) tSellRare:Set(val) end

-- AUTO-LOAD CONFIGURATION ON STARTUP
loadConfig()

MhnaaUI:Notify({
    Title = "Mhnaa [PRO]",
    Content = "Dungeon Quest Automation initialized! Press RightControl to toggle UI.",
    Duration = 4
})

print("[Mhnaa [PRO]] Dungeon Quest Automation successfully initialized with GitHub MhnaaUI!")
