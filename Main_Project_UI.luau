--[[
    ========================================================================================
    DECOMPILED & RECONSTRUCTED SOURCE CODE
    Script: nhamnhi Hub - Legacy Piece
    Version: 1.0.3
    Discord: discord.gg/mcMEkVdebJ
    Key System: Junkie SDK (BYPASSED)
    Decompiled from: Luraph Obfuscated Luau Bytecode
    ========================================================================================
--]]

-- [1] Run Guard & Tránh thực thi lặp
if getgenv().meow_miao_sc_ini then
    pcall(function()
        if getgenv().meow_miao_stop then
            getgenv().meow_miao_stop()
        end
    end)
    warn("nhamnhi Hub: Reloading script instance...")
end
getgenv().meow_miao_sc_ini = true

local scriptRunning = true
getgenv().meow_miao_stop = function()
    scriptRunning = false
    getgenv().meow_miao_sc_ini = false
end

-- [2] Key System Bypass (Junkie SDK Mock)
local KeyResult = { valid = true, message = "Bypassed successfully" }

-- [3] Khởi tạo Services & Dependencies an toàn
local cloneref = cloneref or function(o) return o end
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TeleportService = cloneref(game:GetService("TeleportService"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- [4] Định vị Remotes & Cấu trúc mạng game
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RemoteEvents = Remotes:FindFirstChild("Events")
local RemoteFunctions = Remotes:FindFirstChild("Functions")

local RemoteInput = Remotes:WaitForChild("Input") -- RemoteEvent cho combat / skills
local RemoteFunctionsInput = RemoteFunctions and RemoteFunctions:WaitForChild("Input") -- RemoteFunction cho actions / reroll
local RemoteUseItem = Remotes:WaitForChild("RE_UseItem")

-- Remotes tính năng mở rộng
local TraitReroll = Remotes:FindFirstChild("TraitReroll")
local TraitUpdateAutoSkip = Remotes:FindFirstChild("TraitUpdateAutoSkip")
local SpecEnchantAttempt = Remotes:FindFirstChild("RE_SpecEnchantAttempt")
local GoldShopBuy = RemoteEvents and RemoteEvents:FindFirstChild("GoldShopBuy")
local DungeonShopBuy = RemoteEvents and RemoteEvents:FindFirstChild("DungeonShopBuy")
local InfiniteTowerAction = RemoteEvents and RemoteEvents:FindFirstChild("InfiniteTowerAction")
local TeleportToPortal = Remotes:FindFirstChild("TeleportToPortal")
local TeleportToIslandSpot = Remotes:FindFirstChild("TeleportToIslandSpot")

local ContractGetState = Remotes:FindFirstChild("RF_ContractGetState")
local ContractAccept = Remotes:FindFirstChild("RF_ContractAccept")
local ContractAbandon = Remotes:FindFirstChild("RF_ContractAbandon")
local ContractClaim = Remotes:FindFirstChild("RF_ContractClaim")
local SkillTreeGetState = Remotes:FindFirstChild("RF_SkillTreeGetState")
local SkillTreeUnlock = Remotes:FindFirstChild("RF_SkillTreeUnlock")
local TraitGetData = Remotes:FindFirstChild("TraitGetData")
local SpecEnchantGetSnapshot = Remotes:FindFirstChild("RF_SpecEnchantGetSnapshot")

-- [4.1] Bảng Dữ Liệu Game (Quests, Đảo, Boss)
local QuestDatabase = {
    { minLevel = 0,    maxLevel = 50,   quest = "Quest Bandits",             npc = "Quest Bandits",             target = "Bandit",             island = "Starter Island" },
    { minLevel = 50,   maxLevel = 200,  quest = "Quest Bandit Leader",        npc = "Quest Bandit Leader",        target = "Bandit Leader",      island = "Starter Island" },
    { minLevel = 200,  maxLevel = 250,  quest = "Quest Namekians",            npc = "Quest Namekians",            target = "Namekian",           island = "Jungle Island" },
    { minLevel = 250,  maxLevel = 500,  quest = "Quest Piccolo",              npc = "Quest Piccolo",              target = "Piccolo",            island = "Jungle Island" },
    { minLevel = 500,  maxLevel = 750,  quest = "Quest Serpoians",            npc = "Quest Serpoians",            target = "Serpoian",           island = "Jungle Island" },
    { minLevel = 750,  maxLevel = 1000, quest = "Quest Serpoian (True Form)",  npc = "Quest Serpoian (True Form)",  target = "Serpoian (True Form)", island = "Jungle Island" },
    { minLevel = 1000, maxLevel = 1350, quest = "Quest Beggars",             npc = "Quest Beggars",             target = "Beggar",             island = "Ice Island" },
    { minLevel = 1350, maxLevel = 1750, quest = "Quest Aristocrat",          npc = "Quest Aristocrat",          target = "Aristocrat",         island = "Ice Island" },
    { minLevel = 1750, maxLevel = 2250, quest = "Quest Cursed Students",     npc = "Quest Cursed Students",     target = "Cursed Student",     island = "Jujutsu Academy" },
    { minLevel = 2250, maxLevel = 2750, quest = "Quest Cursed Teacher",      npc = "Quest Cursed Teacher",      target = "Cursed Teacher",     island = "Jujutsu Academy" },
    { minLevel = 2750, maxLevel = 3250, quest = "Quest Hollows",             npc = "Quest Hollows",             target = "Hollow",             island = "Hollow Land" },
    { minLevel = 3250, maxLevel = 3850, quest = "Quest Shinigami",           npc = "Quest Shinigami",           target = "Shinigami",          island = "Hollow Land" },
    { minLevel = 3850, maxLevel = 4500, quest = "Quest Demon Slayers",        npc = "Quest Demon Slayers",        target = "Demon Slayer",       island = "Slayer Mansion" },
    { minLevel = 4500, maxLevel = 5250, quest = "Quest Nameless Pillar",     npc = "Quest Nameless Pillar",     target = "Nameless Pillar",    island = "Slayer Mansion" },
    { minLevel = 5250, maxLevel = 6000, quest = "Quest Ghoul Investigators", npc = "Quest Ghoul Investigators", target = "Ghoul Investigator", island = "Tokyo Ghoul" },
    { minLevel = 6000, maxLevel = 6750, quest = "Quest Ghouls",              npc = "Quest Ghouls",              target = "Ghoul",              island = "Tokyo Ghoul" },
    { minLevel = 7500, maxLevel = 7750, quest = "Quest Distortion Monsters", npc = "Quest Distortion Monsters", target = "Distortion Monster", island = "Ruin City" },
    { minLevel = 7750, maxLevel = 8100, quest = "Quest Hishaku Members",     npc = "Quest Hishaku Members",     target = "Hishaku Member",     island = "Ruin City" },
    { minLevel = 8500, maxLevel = 8700, quest = "Quest Fire Force Bandits",  npc = "Quest Fire Force Bandit",   target = "Fire Force Bandit",  island = "7th Company Island" },
    { minLevel = 8500, maxLevel = 8700, quest = "Quest Fire Force E.Bandit", npc = "Quest Fire Force E.Bandit", target = "Fire Force E.Bandit", island = "7th Company Island" },
    { minLevel = 8700, maxLevel = 9300, quest = "Quest Fishman Pirate",      npc = "Quest Fishman Pirate",      target = "Fishman Pirate",     island = "Fishman Island" }
}

local AllMobNames = {}
for _, q in ipairs(QuestDatabase) do
    table.insert(AllMobNames, q.target)
end

local IslandCenters = {
    ["Starter Island"]     = Vector3.new(-1644, 33, 1099),
    ["Jungle Island"]      = Vector3.new(-208, 25, 3108),
    ["Ice Island"]         = Vector3.new(-2086, 17, 309),
    ["A-City"]             = Vector3.new(1312, 25, 496),
    ["Jujutsu Academy"]    = Vector3.new(-757, 17, -1204),
    ["Hollow Land"]        = Vector3.new(415, 36, -3093),
    ["Slayer Mansion"]     = Vector3.new(2912, 40, -3144),
    ["Tokyo Ghoul"]        = Vector3.new(3613, 22, -490),
    ["Ruin City"]          = Vector3.new(10002, 1002, -7394),
    ["7th Company Island"] = Vector3.new(2672, 24, -5135),
    ["Fishman Island"]     = Vector3.new(1137, 15172, -27834),
    ["Legacy Island"]      = Vector3.new(-129, 17, 24),
    ["Grave Island"]       = Vector3.new(-2583, 29, 3138),
    ["Quincy Castle"]      = Vector3.new(-354, 22, 5153)
}

local IslandPortalIds = {
    ["Starter Island"]     = "Starter",
    ["Jungle Island"]      = "JungleIsland",
    ["Ice Island"]         = "IceIsland",
    ["A-City"]             = "ACity",
    ["Jujutsu Academy"]    = "JujutsuAcademy",
    ["Hollow Land"]        = "HollowLand",
    ["Slayer Mansion"]     = "SlayerMansion",
    ["Tokyo Ghoul"]        = "TokyoGhoul",
    ["Ruin City"]          = "RuinCity",
    ["7th Company Island"] = "7thCompanyIsland",
    ["Fishman Island"]     = "FishmanIsland",
    ["Legacy Island"]      = "Legacy",
    ["Grave Island"]       = "GraveIsland",
    ["Quincy Castle"]      = "QuincyCastle"
}

local KnownTeleporterPositions = {
    ["Starter Island"]     = Vector3.new(-1644, 33, 1099),
    ["Jungle Island"]      = Vector3.new(-208, 25, 3108),
    ["Ice Island"]         = Vector3.new(-2086, 17, 309),
    ["A-City"]             = Vector3.new(1312, 25, 496),
    ["Jujutsu Academy"]    = Vector3.new(-757, 17, -1204),
    ["Hollow Land"]        = Vector3.new(415, 36, -3093),
    ["Slayer Mansion"]     = Vector3.new(2912, 40, -3144),
    ["Tokyo Ghoul"]        = Vector3.new(3613, 22, -490),
    ["Ruin City"]          = Vector3.new(10002, 1002, -7394),
    ["7th Company Island"] = Vector3.new(2672, 24, -5135),
    ["Fishman Island"]     = Vector3.new(1137, 15172, -27834),
    ["Legacy Island"]      = Vector3.new(-129, 17, 24),
    ["Grave Island"]       = Vector3.new(-2583, 29, 3138),
    ["Quincy Castle"]      = Vector3.new(-354, 22, 5153)
}

local BossConfig = {
    ["Ken Kaneki"]              = { Summoner = "Kaneki Whisperer",   Island = "Tokyo Ghoul" },
    ["Aizen"]                   = { Summoner = "Aizen Whisperer",    Island = "Hollow Land" },
    ["Yuji Itadori"]            = { Summoner = "Itadori Whisperer",  Island = "Jujutsu Academy" },
    ["Ryomen Sukuna"]           = { Summoner = "Sukuna Whisperer",   Island = "Jujutsu Academy" },
    ["Kokushibo"]               = { Summoner = "Kokushibo Whisperer",Island = "Slayer Mansion" },
    ["Akaza"]                   = { Summoner = "Akaza Whisperer",    Island = "Slayer Mansion" },
    ["Gojo Satoru"]             = { Summoner = "Gojo Whisperer",     Island = "Jujutsu Academy" },
    ["Yuta Okkotsu"]            = { Summoner = "Yuta Whisperer",     Island = "Jujutsu Academy" },
    ["Jinwoo"]                  = { Summoner = "Jinwoo Whisperer",   Island = "A-City" },
    ["Beru"]                    = { Summoner = "Beru Whisperer",     Island = "A-City" },
    ["Igris"]                   = { Summoner = "Igris Whisperer",    Island = "A-City" },
    ["Garou"]                   = { Summoner = "Garou Whisperer",    Island = "A-City" },
    ["Boros"]                   = { Summoner = "Boros Whisperer",    Island = "A-City" },
    ["Ichigo True Bankai"]      = { Summoner = "Zangetsu",           Island = "Quincy Castle" },
    ["Dio"]                     = { Summoner = "Sacrifice Table",    Island = "Grave Island" },
    ["Cid Kagenou"]             = { Summoner = "Sacrifice Table",    Island = "Grave Island" },
    ["The Red Mist"]            = { Summoner = "Sacrifice Table",    Island = "Grave Island" },
    ["One-Eyed Owl"]            = { Summoner = "Sacrifice Table",    Island = "Grave Island" },
    ["Demon Infernal"]          = { Summoner = "Sacrifice Table",    Island = "Grave Island" }
}

local AllBossNames = {}
for bName, _ in pairs(BossConfig) do
    table.insert(AllBossNames, bName)
end
table.sort(AllBossNames)

-- [5] Cấu hình trung tâm (Config Table)
local HubConfig = {
    Farm = {
        MobFarm = false,
        AllMobFarm = false,
        LevelFarm = false,
        BossesFarm = false,
        AllBossesFarm = false,
        SummonBossFarm = false,
        PityBossFarm = false,
        BountyFarm = false,
        BountyAutoClaim = false,
        
        SelectedMob = "Ghoul Investigator",
        SelectedBosses = { "Ken Kaneki" },
        SelectedSummon = "Kaneki Whisperer",
        
        Position = "Behind", -- Behind | Above | Below
        Distance = 6,
        TweenSpeed = 100,
        
        AutoM1 = true,
        AutoSkill = false,
        AutoSkillMode = "Normal", -- Normal | Instant
        SkillTargetOnly = true,
        SkillBossOnly = false,
        
        AutoHakiArmament = false,
        AutoHakiObservation = false,
        
        InstaKill = false,
        InstaKillThreshold = 10,
    },
    FireForce = {
        Q1_FindCat = false,
        Q2_RescueHostage = false,
        Q3_Ambush = false,
        AutoClaimQuest = false,
    },
    Misc = {
        AutoCollectItem = false,
        AutoMeteor = false,
        AutoCoffin = false,
        AutoFindWhale = false,
        AutoOpenChest = false,
        AutoPrestige = false,
        AutoRedeemCode = false,
    },
    AutoStats = {
        Enabled = false,
        SelectedStats = { "Strength", "Defense" },
        AutoRollStats = false,
        AutoRollTrait = false,
        AutoRollRace = false,
        AutoRollClan = false,
        AutoEnchantSpec = false,
        AutoAscendSpec = false,
    },
    Dungeon = {
        AutoJoin = false,
        SelectedDungeon = "",
        StartFloor = 1,
        AutoJoinTower = false,
        AutoSelectDifficulty = false,
        AutoNext = false,
        AutoReplay = false,
        AutoLeave = false,
        LeaveFloor = 50,
        AutofarmDungeon = false,
    }
}

-- [6] Module điều khiển Nhân vật, Di chuyển & Tác chiến
local State = {
    Target = nil,
    ActiveTween = nil,
    ActiveAction = false,
    WhaleActive = false,
    LastM1 = 0,
    LastSkill = 0,
    NoclipConnection = nil,
    IsTeleporting = false,
}

local function GetCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 5) or char:FindFirstChild("Torso")
    local hum = char:WaitForChild("Humanoid", 5) or char:FindFirstChildOfClass("Humanoid")
    return char, root, hum
end

local function GetPlayerLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    if data and data:FindFirstChild("Level") then
        return data.Level.Value or 1
    end
    return 1
end

local function GetIslandFromPosition(pos)
    local closest = "Starter Island"
    local minDist = math.huge
    for island, center in pairs(IslandCenters) do
        local dist = (pos - center).Magnitude
        if dist < minDist then
            minDist = dist
            closest = island
        end
    end
    return closest
end

local function GetCurrentIsland()
    local _, root = GetCharacter()
    if not root then return "Starter Island" end
    return GetIslandFromPosition(root.Position)
end

local function GetBestQuestInfo(level)
    local best = QuestDatabase[1]
    for _, q in ipairs(QuestDatabase) do
        if level >= q.minLevel then
            best = q
        end
    end
    return best
end

local function GetQuestInfoByTarget(mobName)
    for _, q in ipairs(QuestDatabase) do
        if string.lower(q.target) == string.lower(mobName) or string.find(string.lower(q.target), string.lower(mobName)) then
            return q
        end
    end
    return nil
end

-- Kích hoạt / Hủy Noclip
local function SetNoclip(enabled)
    if enabled then
        if not State.NoclipConnection then
            State.NoclipConnection = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if State.NoclipConnection then
            State.NoclipConnection:Disconnect()
            State.NoclipConnection = nil
        end
    end
end

-- Hủy di chuyển & Triệt tiêu gia tốc
local function StopMovement()
    if State.ActiveTween then
        pcall(function() State.ActiveTween:Cancel() end)
        State.ActiveTween = nil
    end
    local _, root = GetCharacter()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

-- Di chuyển mượt (Tween Engine - Tốc độ an toàn)
local function MoveToCFrame(targetCFrame, customSpeed)
    local char, root, hum = GetCharacter()
    if not root or not hum or hum.Health <= 0 then return end
    
    local distance = (root.Position - targetCFrame.Position).Magnitude
    if distance < 5 then
        root.CFrame = targetCFrame
        return
    end
    
    SetNoclip(true)
    local speed = customSpeed or HubConfig.Farm.TweenSpeed or 100
    local time = distance / speed
    
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    State.ActiveTween = TweenService:Create(root, tweenInfo, { CFrame = targetCFrame })
    State.ActiveTween:Play()
    State.ActiveTween.Completed:Wait()
    State.ActiveTween = nil
end

-- Tìm Cổng Dịch Chuyển (Teleporter) gần nhất
local function GetNearestTeleporter()
    local _, root = GetCharacter()
    if not root then return nil, math.huge end
    local closest = nil
    local minDist = math.huge
    if Workspace:FindFirstChild("NPCs") then
        for _, obj in ipairs(Workspace.NPCs:GetChildren()) do
            if obj.Name == "Teleporter" and obj:IsA("Model") then
                local pivot = obj:GetPivot()
                local dist = (root.Position - pivot.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = obj
                end
            end
        end
    end
    return closest, minDist
end

-- Dịch chuyển giữa các đảo qua Cổng Teleport để chống Server Rubberband
local function TeleportToIslandSafe(targetIsland)
    local curIsland = GetCurrentIsland()
    if curIsland == targetIsland then return true end
    if State.IsTeleporting then return false end
    State.IsTeleporting = true

    StopMovement()
    local _, root = GetCharacter()
    if not root then
        State.IsTeleporting = false
        return false
    end

    local portalId = IslandPortalIds[targetIsland]
    if not portalId then
        State.IsTeleporting = false
        return false
    end

    local tpModel, distToTp = GetNearestTeleporter()
    local tpTargetCF = nil
    if tpModel then
        tpTargetCF = tpModel:GetPivot() * CFrame.new(0, 3, 0)
    else
        local fallbackPos = KnownTeleporterPositions[curIsland] or KnownTeleporterPositions["Starter Island"]
        tpTargetCF = CFrame.new(fallbackPos + Vector3.new(0, 3, 0))
        distToTp = (root.Position - tpTargetCF.Position).Magnitude
    end

    if distToTp and distToTp > 10 then
        MoveToCFrame(tpTargetCF, HubConfig.Farm.TweenSpeed)
        task.wait(0.3)
    end

    if tpModel then
        local prompt = tpModel:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            pcall(function() fireproximityprompt(prompt) end)
            task.wait(0.2)
        end
    end

    if TeleportToPortal then
        pcall(function()
            TeleportToPortal:FireServer(portalId)
        end)
    end

    local waited = 0
    while waited < 4 do
        task.wait(0.5)
        waited = waited + 0.5
        if GetCurrentIsland() == targetIsland then
            break
        end
    end

    State.IsTeleporting = false
    return GetCurrentIsland() == targetIsland
end

-- Tính toán CFrame vị trí đánh (Behind, Above, Below)
local function CalculateFarmOffset(targetPivot)
    local mode = HubConfig.Farm.Position
    local dist = HubConfig.Farm.Distance or 6
    
    if mode == "Behind" then
        return targetPivot * CFrame.new(0, 0, dist)
    elseif mode == "Above" then
        return targetPivot * CFrame.new(0, dist, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    elseif mode == "Below" then
        return targetPivot * CFrame.new(0, -dist, 0) * CFrame.Angles(math.rad(90), 0, 0)
    end
    return targetPivot * CFrame.new(0, 0, dist)
end

-- Tự động cầm vũ khí
local function EquipWeapon(weaponType)
    local char = LocalPlayer.Character
    if not char then return end
    
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and (not weaponType or currentTool:GetAttribute("Type") == weaponType) then
        return currentTool
    end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and not string.find(tool.Name:lower(), "rod") then
                if not weaponType or tool:GetAttribute("Type") == weaponType then
                    tool.Parent = char
                    return tool
                end
            end
        end
    end
    return currentTool
end

-- Thực hiện đòn đánh thường M1 & InstaKill Multi-Burst
local function AttackM1()
    EquipWeapon()
    if HubConfig.Farm.InstaKill then
        local hum = State.Target and State.Target:FindFirstChildOfClass("Humanoid")
        local burstCount = 3
        if hum and hum.MaxHealth > 0 then
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            if hpPercent <= (HubConfig.Farm.InstaKillThreshold or 10) then
                burstCount = 6
            end
        end
        for i = 1, burstCount do
            RemoteInput:FireServer("Tool", "M1")
        end
    else
        RemoteInput:FireServer("Tool", "M1")
    end
end

-- Tự động tung chiêu kỹ năng
local function CastSkills()
    if not HubConfig.Farm.AutoSkill then return end
    EquipWeapon()
    
    local skillKeys = {"Z", "X", "C", "V", "E"}
    for _, key in ipairs(skillKeys) do
        RemoteInput:FireServer("Skill", key)
        if HubConfig.Farm.AutoSkillMode == "Normal" then
            task.wait(0.12)
        end
    end
end

-- [7] Autofarm Combat Loops
task.spawn(function()
    while scriptRunning do
        local delayTime = 0.05
        if HubConfig.Farm.InstaKill then
            delayTime = 0.015
        end
        task.wait(delayTime)
        
        if State.Target and State.Target:FindFirstChild("Humanoid") and State.Target.Humanoid.Health > 0 then
            local _, root, hum = GetCharacter()
            local targetPart = State.Target:FindFirstChild("HumanoidRootPart") or State.Target.PrimaryPart
            if root and targetPart and hum and hum.Health > 0 then
                local farmCFrame = CalculateFarmOffset(targetPart.CFrame)
                local dist = (root.Position - farmCFrame.Position).Magnitude
                if dist > 8 then
                    MoveToCFrame(farmCFrame)
                else
                    root.CFrame = farmCFrame
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end
                
                if HubConfig.Farm.AutoM1 then
                    AttackM1()
                end
                
                if HubConfig.Farm.AutoSkill then
                    CastSkills()
                end
            end
        else
            State.Target = nil
        end
    end
end)

-- Quét tìm quái
local function FindMobTarget(mobName)
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    
    for _, enemy in ipairs(enemies:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
            if not mobName or string.find(enemy.Name:lower(), mobName:lower()) then
                return enemy
            end
        end
    end
    return nil
end

-- Nhận Quest tự động
local function AcceptQuest(qInfo)
    if not qInfo or not RemoteFunctionsInput then return end
    pcall(function()
        RemoteFunctionsInput:InvokeServer("Quest", "TakeQuest", qInfo.quest)
    end)
end

-- Bộ chọn mục tiêu tự động & Triệu Hồi Boss
task.spawn(function()
    while scriptRunning do
        task.wait(0.25)
        if State.IsTeleporting then continue end

        -- 1. Farm Quái Chỉ Định
        if HubConfig.Farm.MobFarm then
            local qInfo = GetQuestInfoByTarget(HubConfig.Farm.SelectedMob)
            if qInfo then
                local curIsland = GetCurrentIsland()
                if curIsland ~= qInfo.island then
                    TeleportToIslandSafe(qInfo.island)
                    task.wait(1)
                    continue
                end
                AcceptQuest(qInfo)
            end
            State.Target = FindMobTarget(HubConfig.Farm.SelectedMob)

        -- 2. Farm Mọi Loại Quái
        elseif HubConfig.Farm.AllMobFarm then
            State.Target = FindMobTarget()

        -- 3. Level Farm (Theo Cấp Độ)
        elseif HubConfig.Farm.LevelFarm then
            local lvl = GetPlayerLevel()
            local qInfo = GetBestQuestInfo(lvl)
            if qInfo then
                local curIsland = GetCurrentIsland()
                if curIsland ~= qInfo.island then
                    TeleportToIslandSafe(qInfo.island)
                    task.wait(1)
                    continue
                end
                AcceptQuest(qInfo)
                State.Target = FindMobTarget(qInfo.target)
            end

        -- 4. Farm Boss & Tự Động Triệu Hồi (Summon Boss)
        elseif HubConfig.Farm.BossesFarm then
            local targetBossName = HubConfig.Farm.SelectedBosses[1] or "Ken Kaneki"
            local bossModel = FindMobTarget(targetBossName)

            if bossModel then
                local bPos = bossModel:GetPivot().Position
                local bIsland = GetIslandFromPosition(bPos)
                if GetCurrentIsland() ~= bIsland then
                    TeleportToIslandSafe(bIsland)
                    task.wait(1)
                    continue
                end
                State.Target = bossModel
            else
                State.Target = nil
                -- Nếu chưa có Boss và bật SummonBossFarm -> Tự động đến NPC triệu hồi
                if HubConfig.Farm.SummonBossFarm then
                    local bInfo = BossConfig[targetBossName]
                    if bInfo and bInfo.Summoner then
                        local sIsland = bInfo.Island or "Tokyo Ghoul"
                        if GetCurrentIsland() ~= sIsland then
                            TeleportToIslandSafe(sIsland)
                            task.wait(1)
                            continue
                        end

                        local summonerNpc = Workspace.NPCs:FindFirstChild(bInfo.Summoner)
                        local _, root = GetCharacter()
                        if summonerNpc and root then
                            local dist = (summonerNpc:GetPivot().Position - root.Position).Magnitude
                            if dist > 18 then
                                MoveToCFrame(summonerNpc:GetPivot() * CFrame.new(0, 0, 5))
                            else
                                if RemoteFunctionsInput then
                                    RemoteFunctionsInput:InvokeServer("SpawnBoss", summonerNpc, targetBossName)
                                    task.wait(1.5)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- [8] Tự Động Nhiệm Vụ Fire Force
task.spawn(function()
    while scriptRunning do
        task.wait(0.5)
        if HubConfig.FireForce.Q1_FindCat or HubConfig.FireForce.Q2_RescueHostage or HubConfig.FireForce.Q3_Ambush then
            local extra = Workspace:FindFirstChild("Extra")
            if extra then
                local ffFolder = extra:FindFirstChild("FireForce") or extra:FindFirstChild("FireForceQuest")
                if ffFolder then
                    for _, item in ipairs(ffFolder:GetDescendants()) do
                        if item:IsA("ProximityPrompt") and item.Enabled then
                            local char, root = GetCharacter()
                            if root then
                                MoveToCFrame(item.Parent:GetPivot() or item.Parent.CFrame)
                                task.wait(0.2)
                                if fireproximityprompt then
                                    fireproximityprompt(item)
                                end
                            end
                        end
                    end
                end
            end
            
            if HubConfig.FireForce.Q3_Ambush then
                local ambusher = Workspace:FindFirstChild("Infernal Ambusher") or FindMobTarget("Ambusher")
                if ambusher then
                    State.Target = ambusher
                end
            end
        end
    end
end)

-- [9] Tự Động Nhặt Đồ Rơi, Rương & Săn Sự Kiện
task.spawn(function()
    while scriptRunning do
        task.wait(0.5)
        if HubConfig.Misc.AutoCollectItem then
            local itemsFolder = Workspace:FindFirstChild("SpawnedItems") or (Workspace:FindFirstChild("Extra") and Workspace.Extra:FindFirstChild("Items"))
            if itemsFolder then
                for _, item in ipairs(itemsFolder:GetChildren()) do
                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local basePart = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
                    if basePart and prompt and prompt.Enabled then
                        local _, root = GetCharacter()
                        if root then
                            MoveToCFrame(basePart.CFrame)
                            task.wait(0.15)
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                end
            end
        end

        if HubConfig.Misc.AutoOpenChest then
            local chestsFolder = Workspace:FindFirstChild("Chests") or (Workspace:FindFirstChild("Extra") and Workspace.Extra:FindFirstChild("Chests"))
            if chestsFolder then
                for _, chest in ipairs(chestsFolder:GetChildren()) do
                    local prompt = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local basePart = chest:IsA("BasePart") and chest or chest:FindFirstChildWhichIsA("BasePart")
                    if basePart and prompt and prompt.Enabled then
                        local _, root = GetCharacter()
                        if root then
                            MoveToCFrame(basePart.CFrame)
                            task.wait(0.15)
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- [9.1] Tự Động Cộng Điểm & Roll Traits
task.spawn(function()
    while scriptRunning do
        task.wait(0.5)
        if HubConfig.AutoStats.Enabled and RemoteFunctionsInput then
            local points = LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Points") and LocalPlayer.Data.Points.Value
            if points and points > 0 then
                for _, stat in ipairs(HubConfig.AutoStats.SelectedStats) do
                    pcall(function()
                        RemoteFunctionsInput:InvokeServer("AddPoint", stat, 1)
                    end)
                end
            end
        end

        if HubConfig.AutoStats.AutoRollTrait and TraitReroll then
            pcall(function()
                TraitReroll:FireServer()
            end)
            task.wait(0.5)
        end

        if HubConfig.AutoStats.AutoEnchantSpec and SpecEnchantAttempt then
            pcall(function()
                SpecEnchantAttempt:FireServer()
            end)
            task.wait(0.5)
        end
    end
end)

-- [9.2] Dungeon & Infinite Tower
task.spawn(function()
    while scriptRunning do
        task.wait(1)
        if HubConfig.Dungeon.AutoJoinTower and InfiniteTowerAction then
            pcall(function()
                InfiniteTowerAction:FireServer("Start")
            end)
        end
        if HubConfig.Dungeon.AutoNext and InfiniteTowerAction then
            pcall(function()
                InfiniteTowerAction:FireServer("Next")
            end)
        end
    end
end)

-- [10] Chống Treo Máy (Anti-AFK)
local function EnableAntiAFK()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
    end)
end
EnableAntiAFK()

-- [11] Khởi Tạo Giao Diện Người Dùng (Obsidian UI Library)
local function LoadUI()
    local success, Library = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/gix314/Obsidian/main/Library.lua"))()
    end)
    
    if not success or not Library then
        warn("[nhamnhi Hub] Không thể tải Obsidian Library! Vui lòng kiểm tra kết nối mạng hoặc executor.")
        return
    end

    local Window = Library:CreateWindow({
        Title = "nhamnhi | Legacy Piece [Bypassed]",
        Footer = "nhamnhi v1.0.3 | discord.gg/mcMEkVdebJ",
        Icon = 101058895845936,
        NotifySide = "Right",
        ShowCustomCursor = false,
    })

    -- Khởi tạo Tabs
    local Tabs = {
        Home = Window:AddTab({ Title = "Home", Name = "Home", Icon = "house", Description = "Thông tin chung & Trạng thái" }),
        Main = Window:AddTab({ Title = "Main", Name = "Main", Icon = "box", Description = "Tính năng Autofarm chính" }),
        FireForce = Window:AddTab({ Title = "Fire Force", Name = "Fire Force", Icon = "repeat-2", Description = "Tự động nhiệm vụ Fire Force" }),
        Automation = Window:AddTab({ Title = "Automation", Name = "Automation", Icon = "repeat", Description = "Tự động cơ chế in-game (Roll, Chest, Stats)" }),
        Dungeon = Window:AddTab({ Title = "Dungeon", Name = "Dungeon", Icon = "door-open", Description = "Phó bản & Infinite Tower" }),
        Teleport = Window:AddTab({ Title = "Teleport", Name = "Teleport", Icon = "map-pin", Description = "Dịch chuyển đảo & NPC" }),
    }

    -- ─────────────────────────────────────────────────────────────────────────
    -- Tab Home: General Information
    -- ─────────────────────────────────────────────────────────────────────────
    local HomeGroup = Tabs.Home:AddLeftGroupbox("Thông tin hệ thống")
    HomeGroup:AddLabel("Hub: nhamnhi Hub - Legacy Piece")
    HomeGroup:AddLabel("Version: 1.0.3 (Reconstructed)")
    HomeGroup:AddLabel("Status: Bypassed & Ready")

    local PlayerGroup = Tabs.Home:AddRightGroupbox("Trạng thái nhân vật")
    PlayerGroup:AddLabel("Tên: " .. LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")")
    PlayerGroup:AddLabel("Đảo hiện tại: " .. GetCurrentIsland())

    -- ─────────────────────────────────────────────────────────────────────────
    -- Tab Main: Autofarm Settings
    -- ─────────────────────────────────────────────────────────────────────────
    local FarmGroup = Tabs.Main:AddLeftGroupbox("Autofarm Settings")
    FarmGroup:AddToggle("MobFarm", {
        Text = "Auto Farm [Mob]",
        Default = false,
        Callback = function(v) 
            HubConfig.Farm.MobFarm = v 
            if not v then State.Target = nil StopMovement() end
        end
    })
    FarmGroup:AddToggle("AllMobFarm", {
        Text = "Auto Farm [All Mobs]",
        Default = false,
        Callback = function(v) 
            HubConfig.Farm.AllMobFarm = v 
            if not v then State.Target = nil StopMovement() end
        end
    })
    FarmGroup:AddToggle("LevelFarm", {
        Text = "Auto Farm [Theo Level Quest]",
        Default = false,
        Callback = function(v) 
            HubConfig.Farm.LevelFarm = v 
            if not v then State.Target = nil StopMovement() end
        end
    })
    FarmGroup:AddToggle("BossesFarm", {
        Text = "Auto Farm [Bosses]",
        Default = false,
        Callback = function(v) 
            HubConfig.Farm.BossesFarm = v 
            if not v then State.Target = nil StopMovement() end
        end
    })
    FarmGroup:AddToggle("SummonBossFarm", {
        Text = "Auto Summon Boss",
        Default = true,
        Callback = function(v) HubConfig.Farm.SummonBossFarm = v end
    })
    FarmGroup:AddToggle("AutoM1", {
        Text = "Auto M1 Attack",
        Default = true,
        Callback = function(v) HubConfig.Farm.AutoM1 = v end
    })
    FarmGroup:AddToggle("AutoSkill", {
        Text = "Auto Use Skills (Z, X, C, V, E)",
        Default = false,
        Callback = function(v) HubConfig.Farm.AutoSkill = v end
    })
    FarmGroup:AddToggle("InstaKill", {
        Text = "InstaKill Mob (Multi-Burst M1)",
        Default = false,
        Callback = function(v) HubConfig.Farm.InstaKill = v end
    })

    local PosGroup = Tabs.Main:AddRightGroupbox("Position & Speed")
    PosGroup:AddDropdown("SelectedMob", {
        Values = AllMobNames,
        Default = "Ghoul Investigator",
        Multi = false,
        Text = "Chọn quái cần farm",
        Callback = function(v) HubConfig.Farm.SelectedMob = v end
    })
    PosGroup:AddDropdown("SelectedBoss", {
        Values = AllBossNames,
        Default = "Ken Kaneki",
        Multi = false,
        Text = "Chọn Boss",
        Callback = function(v) HubConfig.Farm.SelectedBosses = { v } end
    })
    PosGroup:AddDropdown("FarmPos", {
        Values = { "Behind", "Above", "Below" },
        Default = "Behind",
        Multi = false,
        Text = "Vị trí farm",
        Callback = function(v) HubConfig.Farm.Position = v end
    })
    PosGroup:AddSlider("FarmDist", {
        Text = "Khoảng cách farm",
        Default = 6,
        Min = 2,
        Max = 15,
        Rounding = 1,
        Callback = function(v) HubConfig.Farm.Distance = v end
    })
    PosGroup:AddSlider("TweenSpeed", {
        Text = "Tốc độ bay (Tween)",
        Default = 100,
        Min = 50,
        Max = 300,
        Rounding = 0,
        Callback = function(v) HubConfig.Farm.TweenSpeed = v end
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- Tab Fire Force
    -- ─────────────────────────────────────────────────────────────────────────
    local FFGroup = Tabs.FireForce:AddLeftGroupbox("Nhiệm vụ Fire Force")
    FFGroup:AddToggle("FF_Q1", {
        Text = "Auto Tìm Mèo (Find Cat)",
        Default = false,
        Callback = function(v) HubConfig.FireForce.Q1_FindCat = v end
    })
    FFGroup:AddToggle("FF_Q2", {
        Text = "Auto Cứu Con Tin (Rescue Hostage)",
        Default = false,
        Callback = function(v) HubConfig.FireForce.Q2_RescueHostage = v end
    })
    FFGroup:AddToggle("FF_Q3", {
        Text = "Auto Đánh Lén (Ambush Thugs)",
        Default = false,
        Callback = function(v) HubConfig.FireForce.Q3_Ambush = v end
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- Tab Automation
    -- ─────────────────────────────────────────────────────────────────────────
    local AutoGroup = Tabs.Automation:AddLeftGroupbox("Vật phẩm & Rương")
    AutoGroup:AddToggle("AutoCollectItem", {
        Text = "Tự động nhặt đồ rơi (Collect Items)",
        Default = false,
        Callback = function(v) HubConfig.Misc.AutoCollectItem = v end
    })
    AutoGroup:AddToggle("AutoOpenChest", {
        Text = "Tự động mở rương (Open Chest)",
        Default = false,
        Callback = function(v) HubConfig.Misc.AutoOpenChest = v end
    })
    AutoGroup:AddToggle("AutoWhale", {
        Text = "Tự động săn Cá voi (Whale Event)",
        Default = false,
        Callback = function(v) HubConfig.Misc.AutoFindWhale = v end
    })

    local StatsGroup = Tabs.Automation:AddRightGroupbox("Tự Động Nâng Điểm")
    StatsGroup:AddToggle("AutoStats", {
        Text = "Auto Up Stats",
        Default = false,
        Callback = function(v) HubConfig.AutoStats.Enabled = v end
    })
    StatsGroup:AddDropdown("StatsSelect", {
        Values = { "Strength", "Stamina", "Defense", "Sword", "Fruit", "Gun" },
        Default = { "Strength", "Defense" },
        Multi = true,
        Text = "Chọn chỉ số nâng",
        Callback = function(tbl)
            HubConfig.AutoStats.SelectedStats = {}
            for k, val in pairs(tbl) do
                if val == true then
                    table.insert(HubConfig.AutoStats.SelectedStats, k)
                end
            end
        end
    })
    StatsGroup:AddToggle("AutoRollTrait", {
        Text = "Auto Roll Trait",
        Default = false,
        Callback = function(v) HubConfig.AutoStats.AutoRollTrait = v end
    })
    StatsGroup:AddToggle("AutoEnchantSpec", {
        Text = "Auto Enchant Spec",
        Default = false,
        Callback = function(v) HubConfig.AutoStats.AutoEnchantSpec = v end
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- Tab Dungeon
    -- ─────────────────────────────────────────────────────────────────────────
    local DunGroup = Tabs.Dungeon:AddLeftGroupbox("Infinite Tower & Dungeon")
    DunGroup:AddToggle("AutoJoinTower", {
        Text = "Auto Join Infinite Tower",
        Default = false,
        Callback = function(v) HubConfig.Dungeon.AutoJoinTower = v end
    })
    DunGroup:AddToggle("AutoNext", {
        Text = "Auto Next Floor (Tự qua tầng)",
        Default = false,
        Callback = function(v) HubConfig.Dungeon.AutoNext = v end
    })

    -- ─────────────────────────────────────────────────────────────────────────
    -- Tab Teleport
    -- ─────────────────────────────────────────────────────────────────────────
    local IslandList = {}
    for isl, _ in pairs(IslandPortalIds) do
        table.insert(IslandList, isl)
    end
    table.sort(IslandList)

    local TpGroup = Tabs.Teleport:AddLeftGroupbox("Dịch Chuyển Đảo (Anti-Rubberband)")
    local selectedTeleportIsland = "Starter Island"
    TpGroup:AddDropdown("IslandSelect", {
        Values = IslandList,
        Default = "Starter Island",
        Multi = false,
        Text = "Chọn đảo cần tới",
        Callback = function(v) selectedTeleportIsland = v end
    })
    TpGroup:AddButton({
        Text = "Teleport Đến Đảo (Qua Cổng Portal)",
        Func = function()
            TeleportToIslandSafe(selectedTeleportIsland)
        end
    })

    Library:Notify("nhamnhi Hub đã tải thành công! Key system đã được bypass hoàn toàn.", 5)
end

-- Chạy hàm tải UI
LoadUI()
print("[nhamnhi] Script loaded and initialized successfully!")
