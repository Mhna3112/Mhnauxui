--[[
    ═══════════════════════════════════════════════════════════════════════════
    ✨ MHNAA HUB [PRO-NK] - FULL SUITE AUTO FARM & BOSS SYSTEM ✨
    Phân chia chuẩn 6 Tab theo kiến trúc NK HUB:
    - Tab 1: Home (Thông tin, Vũ khí, Auto Attack, Auto Skill, Khoảng cách)
    - Tab 2: Main (Auto Farm Quái, Auto Quest theo Level, Multi-Farm, Chuyển sinh, Câu cá)
    - Tab 3: Boss (Auto Farm Boss, Tự động triệu hồi Summon Boss qua Whisperer)
    - Tab 4: Stats (Auto Up Stats, Amount, Multi-Select Stats, Reset)
    - Tab 5: Teleport (Teleport Portal qua đảo không Pause, Teleport tới NPC)
    - Tab 6: Miscellaneous (Server Hop, Black Screen, Tắt 3D Render, FPS Boost, Anti-AFK)
    ═══════════════════════════════════════════════════════════════════════════
]]

-- DỌN DẸP PHIÊN CHẠY CŨ (SINGLE-INSTANCE CONTROLLER)
if _G.MhnaaHub_Stop then
    pcall(_G.MhnaaHub_Stop)
end

local scriptRunning = true
_G.MhnaaHub_Stop = function()
    scriptRunning = false
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Xóa giao diện cũ nếu có
local safeContainer = (gethui and gethui()) or CoreGui
local oldGui = safeContainer:FindFirstChild("Mhnaa_UI_Root")
if oldGui then
    pcall(function() oldGui:Destroy() end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. LOAD THƯ VIỆN MHNAA UI
-- ═══════════════════════════════════════════════════════════════════════════
local MhnaaUI
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/MhnaaUI.luau"

local successGit, resultGit = pcall(function()
    return loadstring(game:HttpGet(GITHUB_RAW_URL))()
end)

if successGit and resultGit then
    MhnaaUI = resultGit
else
    if isfile and isfile("MhnaaUI.luau") then
        local successLocal, resultLocal = pcall(function()
            return loadstring(readfile("MhnaaUI.luau"))()
        end)
        if successLocal then MhnaaUI = resultLocal end
    elseif loadfile then
        local successLoad, fn = pcall(loadfile, "MhnaaUI.luau")
        if successLoad and fn then MhnaaUI = fn() end
    end
end

if not MhnaaUI then
    warn("[Mhnaa Hub] Không tìm thấy thư viện MhnaaUI.luau!")
    return
end

-- Tự động chặn bảng thông báo Gameplay Paused
task.spawn(function()
    while scriptRunning do
        pcall(function()
            local pauseGui = CoreGui:FindFirstChild("RobloxNetworkPauseNotification")
            if pauseGui and pauseGui.Enabled then
                pauseGui.Enabled = false
            end
        end)
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. CẤU HÌNH TRUNG TÂM (CONFIG)
-- ═══════════════════════════════════════════════════════════════════════════
local Config = {
    -- Home Tab
    SelectWeapon = "Ace",
    AutoAttack = false,
    AttackSpeed = 0.08,
    SelectedSkillTable = { "Z", "X", "C" },
    AutoUseSelectedSkill = false,
    SkillDelay = 0.5,
    SelectFarmMode = "Above", -- Above, Beside, Behind, Below
    DistanceY = 7,
    TweenSpeed = 160,
    
    -- Main Tab (Farming)
    SelectedMob = "Ghoul Investigator",
    AutoFarmSelectedMob = false,
    AutoQuestByLevel = false,
    SelectedMultiMob = {},
    AutoFarmMulti = false,
    AutoPrestige = false,
    PrestigeMode = "Khi đủ nhiệm vụ",
    AutoFish = false,
    FishingMode = "Fast / Instant Reel",
    AutoEquipRod = true,
    AutoSellFish = false,
    
    -- Boss Tab
    SelectedBoss = "Ken Kaneki",
    SelectedBossTable = { "Ken Kaneki" },
    AutoFarmSelectedBoss = false,
    AutoSpawnBoss = true,
    
    -- Stats Tab
    Amount = 10,
    SelectedStatsTable = { "Weapon" },
    AutoUpSelectedStats = false,
    
    -- Teleport Tab
    SelectedMaps = "Tokyo Ghoul",
    SelectedNPC = "",
    
    -- Misc Tab
    FPSBooster = false,
    WhiteScreen = false,
    BlackScreen = false,
    Disable3DRender = false,
    AntiAFK = true,
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. BẢNG DỮ LIỆU GAME (QUESTS, ISLANDS, BOSSES)
-- ═══════════════════════════════════════════════════════════════════════════

-- 21 Mốc Quest chuẩn xác theo cấp độ từ QuestData
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

-- Danh sách tên quái chuẩn để hiển thị trong Dropdown Main
local AllMobNames = {}
for _, q in ipairs(QuestDatabase) do
    table.insert(AllMobNames, q.target)
end

-- Tọa độ trung tâm và Portal ID của 14 Đảo
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

-- Bảng thông tin Boss và NPC triệu hồi (Whisperer)
local BossConfig = {
    ["Ken Kaneki"]              = { Summoner = "Gray Whisperer",     Island = "Tokyo Ghoul" },
    ["Sosuke Aizen"]            = { Summoner = "The Whisperer",      Island = "Jungle Island" },
    ["Ichigo Kurosaki"]         = { Summoner = "The Whisperer",      Island = "Jungle Island" },
    ["Ichigo Kurosaki Bankai"]  = { Summoner = "The Whisperer",      Island = "Jungle Island" },
    ["Satoru Gojo"]             = { Summoner = "Yellow Whisperer",   Island = "Jujutsu Academy" },
    ["Ryomen Sukuna"]           = { Summoner = "Yellow Whisperer",   Island = "Jujutsu Academy" },
    ["Blast"]                   = { Summoner = "White Whisperer",    Island = "A-City" },
    ["Garou"]                   = { Summoner = "White Whisperer",    Island = "A-City" },
    ["Flashy Flash"]            = { Summoner = "White Whisperer",    Island = "A-City" },
    ["Akaza"]                   = { Summoner = "Pink Whisperer",     Island = "Starter Island" },
    ["Chihora"]                 = { Summoner = "PauPau Whisperer",   Island = "Grave Island" },
    ["Fishman Captain"]         = { Summoner = "Fish Whisperer",     Island = "Fishman Island" },
    ["Undyne"]                  = { Summoner = "Undyne Summon",      Island = "Ruin City" },
    ["Solemn Lament"]           = { Summoner = "Griefbound Ferryman",Island = "Ice Island" },
    ["Ichigo True Bankai"]      = { Summoner = "Zangetsu",           Island = "Quincy Castle" },
    ["Dio"]                     = { Summoner = "Sacrifice Table",    Island = "Ruin City" },
    ["Cid Kagenou"]             = { Summoner = "Sacrifice Table",    Island = "Ruin City" },
    ["The Red Mist"]            = { Summoner = "Sacrifice Table",    Island = "Ruin City" },
    ["One-Eyed Owl"]            = { Summoner = "Sacrifice Table",    Island = "Ruin City" },
    ["Demon Infernal"]          = { Summoner = "Sacrifice Table",    Island = "Ruin City" }
}

local AllBossNames = {}
for bName, _ in pairs(BossConfig) do
    table.insert(AllBossNames, bName)
end
table.sort(AllBossNames)

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. HÀM TRỢ GIÚP TIỆN ÍCH (HELPERS)
-- ═══════════════════════════════════════════════════════════════════════════
local renv = getrenv and getrenv() or {}
local function getInputFunction()
    return (renv._G and renv._G.InputFunction) 
        or (ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Functions") and ReplicatedStorage.Remotes.Functions:FindFirstChild("Input"))
end

local function getTeleportUI()
    local g = renv._G or _G
    return g.TeleportUI
end

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getRoot()
    local char = getCharacter()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function HasValue(Table, Value)
    return type(Table) == "table" and table.find(Table, Value) ~= nil
end

local function getCurrentIsland()
    local root = getRoot()
    if not root then return "Starter Island" end
    local pos = root.Position
    local closest = "Starter Island"
    local minDist = math.huge
    for isl, center in pairs(IslandCenters) do
        local dist = (pos - center).Magnitude
        if dist < minDist then
            minDist = dist
            closest = isl
        end
    end
    return closest
end

local function getBestQuestInfo(level)
    local best = QuestDatabase[1]
    for _, q in ipairs(QuestDatabase) do
        if level >= q.minLevel then
            best = q
        end
    end
    return best
end

local function getQuestInfoByTarget(mobName)
    for _, q in ipairs(QuestDatabase) do
        if string.lower(q.target) == string.lower(mobName) or string.find(string.lower(q.target), string.lower(mobName)) then
            return q
        end
    end
    return nil
end

local function getQuestInfoByName(questName)
    for _, q in ipairs(QuestDatabase) do
        if q.quest == questName or q.npc == questName then
            return q
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. HỆ THỐNG DI CHUYỂN HYBRID & TWEEN KHÓA VỊ TRÍ
-- ═══════════════════════════════════════════════════════════════════════════
local currentTween = nil
local isTweening = false

local function stopCurrentTween()
    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end
    isTweening = false
end

local function tweenTo(targetCFrame, customSpeed)
    local char = getCharacter()
    local root = getRoot()
    local hum = getHumanoid()
    if not char or not root or not hum or hum.Health <= 0 then return false end

    local speed = customSpeed or Config.TweenSpeed or 160
    local targetPos = targetCFrame.Position
    local dist = (targetPos - root.Position).Magnitude

    if dist <= 4 then
        root.CFrame = targetCFrame
        return true
    end

    local dur = math.max(dist / speed, 0.05)

    local noclipConn = RunService.Stepped:Connect(function()
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)

    hum:ChangeState(Enum.HumanoidStateType.Flying)
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero

    local lookDir = dist > 0.1 and (targetPos - root.Position).Unit or root.CFrame.LookVector
    local tw = TweenService:Create(root, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(targetPos, targetPos + lookDir)
    })
    currentTween = tw
    isTweening = true

    tw:Play()
    tw.Completed:Wait()

    noclipConn:Disconnect()
    isTweening = false
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
    root.CFrame = targetCFrame
    return true
end

local function teleportToIsland(targetIsland)
    stopCurrentTween()
    local current = getCurrentIsland()
    if current == targetIsland then return true end

    local tpUI = getTeleportUI()
    if tpUI and tpUI.selectIsland and tpUI.teleport then
        pcall(function()
            tpUI:selectIsland(targetIsland)
            task.wait(0.2)
            tpUI:teleport()
        end)
        task.wait(1.5)
        if getCurrentIsland() == targetIsland then return true end
    end

    local portalId = IslandPortalIds[targetIsland]
    local tpPortalRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("TeleportToPortal")
    if tpPortalRemote and portalId then
        pcall(function() tpPortalRemote:FireServer(portalId) end)
        task.wait(1.2)
        if getCurrentIsland() == targetIsland then return true end
    end

    return getCurrentIsland() == targetIsland
end

local function calculateTargetCFrame(targetInstance, positionMode, distance)
    local targetCF
    if targetInstance:IsA("Model") then
        local targetRoot = targetInstance:FindFirstChild("HumanoidRootPart") 
            or targetInstance:FindFirstChild("Torso") 
            or targetInstance.PrimaryPart 
            or targetInstance:FindFirstChildWhichIsA("BasePart")
        if targetRoot then
            targetCF = targetRoot.CFrame
        else
            targetCF = targetInstance:GetPivot()
        end
    elseif targetInstance:IsA("BasePart") then
        targetCF = targetInstance.CFrame
    else
        return nil
    end

    distance = distance or Config.DistanceY or 7

    if positionMode == "Above" or positionMode == "Upper" then
        return targetCF * CFrame.new(0, distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    elseif positionMode == "Beside" then
        return targetCF * CFrame.new(distance, 1, 0) * CFrame.Angles(0, math.rad(-90), 0)
    elseif positionMode == "Behind" then
        return targetCF * CFrame.new(0, 1, distance)
    elseif positionMode == "Below" or positionMode == "Under" then
        return targetCF * CFrame.new(0, -distance, 0) * CFrame.Angles(math.rad(90), 0, 0)
    else
        return targetCF * CFrame.new(0, distance, 0)
    end
end

-- Tự động cầm vũ khí
local function equipSelectedWeapon(weaponName)
    local char = getCharacter()
    local hum = getHumanoid()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not hum or not backpack then return end

    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and string.find(string.lower(currentTool.Name), string.lower(weaponName)) then
        return currentTool
    end

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and string.find(string.lower(tool.Name), string.lower(weaponName)) then
            hum:EquipTool(tool)
            return tool
        end
    end
end

-- Quét danh sách vũ khí
local WeaponList = {}
local function refreshWeapons()
    table.clear(WeaponList)
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and not table.find(WeaponList, t.Name) then
                table.insert(WeaponList, t.Name)
            end
        end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and not table.find(WeaponList, t.Name) then
                table.insert(WeaponList, t.Name)
            end
        end
    end
    if #WeaponList == 0 then
        table.insert(WeaponList, "Ace")
        table.insert(WeaponList, "Combat")
    end
end
refreshWeapons()

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. WORKERS TỰ ĐỘNG (ATTACK, SKILL, STATS, FARM, BOSS)
-- ═══════════════════════════════════════════════════════════════════════════
local currentCombatTarget = nil

-- Worker: Tấn công thường (Fast Attack)
task.spawn(function()
    while scriptRunning do
        task.wait(Config.AttackSpeed or 0.08)
        if (Config.AutoAttack or Config.AutoFarmSelectedMob or Config.AutoQuestByLevel or Config.AutoFarmMulti or Config.AutoFarmSelectedBoss) 
            and currentCombatTarget and not isTweening then
            pcall(function()
                local char = getCharacter()
                if not char then return end
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                end
                VirtualUser:CaptureController()
                VirtualUser:Button1Down(Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2))
            end)
        end
    end
end)

-- Worker: Combo Chiêu Thức (Auto Skill)
task.spawn(function()
    local skillKeyMap = {
        Z = Enum.KeyCode.Z,
        X = Enum.KeyCode.X,
        C = Enum.KeyCode.C,
        V = Enum.KeyCode.V,
        E = Enum.KeyCode.E,
        R = Enum.KeyCode.R
    }
    while scriptRunning do
        task.wait(Config.SkillDelay or 0.5)
        if Config.AutoUseSelectedSkill and currentCombatTarget and not isTweening then
            for _, k in ipairs(Config.SelectedSkillTable) do
                local enumK = skillKeyMap[k]
                if enumK and currentCombatTarget and not isTweening then
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, enumK, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, enumK, false, game)
                    end)
                    task.wait(Config.SkillDelay or 0.5)
                end
            end
        end
    end
end)

-- Worker: Tự Động Cộng Điểm (Auto Up Stats)
task.spawn(function()
    while scriptRunning do
        task.wait(0.5)
        if Config.AutoUpSelectedStats then
            pcall(function()
                local points = LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Points") and LocalPlayer.Data.Points.Value
                if points and points > 0 then
                    local inputFunc = getInputFunction()
                    if inputFunc then
                        local batch = math.clamp(Config.Amount or 10, 1, points)
                        if HasValue(Config.SelectedStatsTable, "All Evenly") or HasValue(Config.SelectedStatsTable, "All Evenly (Chia đều)") then
                            local each = math.max(1, math.floor(batch / 4))
                            inputFunc:InvokeServer("AddPoint", "Weapon", each)
                            inputFunc:InvokeServer("AddPoint", "Strength", each)
                            inputFunc:InvokeServer("AddPoint", "Defense", each)
                            inputFunc:InvokeServer("AddPoint", "Ability", each)
                        else
                            for _, stat in ipairs(Config.SelectedStatsTable) do
                                inputFunc:InvokeServer("AddPoint", stat, batch)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Worker: Auto Farm Quái (Selected Mob & Auto Quest theo Level)
task.spawn(function()
    while scriptRunning do
        task.wait(0.1)
        local isMobFarming = (Config.AutoFarmSelectedMob or Config.AutoQuestByLevel or Config.AutoFarmMulti) and not Config.AutoFarmSelectedBoss
        if isMobFarming then
            pcall(function()
                local char = getCharacter()
                local root = getRoot()
                local hum = getHumanoid()
                if not char or not root or not hum or hum.Health <= 0 then return end

                equipSelectedWeapon(Config.SelectWeapon)

                local playerLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
                local inputFunc = getInputFunction()

                -- Xác định mục tiêu quest
                local targetQuestInfo = nil
                if Config.AutoQuestByLevel then
                    targetQuestInfo = getBestQuestInfo(playerLevel)
                else
                    targetQuestInfo = getQuestInfoByTarget(Config.SelectedMob) or QuestDatabase[1]
                end

                -- Quản lý Quest dở dang
                local activeQuestFolder = LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Quests") and LocalPlayer.Data.Quests:FindFirstChild("Main")
                local activeQuestObj = activeQuestFolder and activeQuestFolder:GetChildren()[1]

                if activeQuestObj then
                    local activeName = activeQuestObj.Name
                    local activeInfo = getQuestInfoByName(activeName)

                    -- Claim quest nếu đã xong
                    local isCompleted = activeQuestObj:FindFirstChild("Completed") and activeQuestObj.Completed.Value == true
                    if isCompleted and inputFunc then
                        inputFunc:InvokeServer("Quest", "Claim", activeName)
                        task.wait(0.5)
                        return
                    end

                    -- Hủy quest nếu out-level (khi bật AutoQuestByLevel)
                    if Config.AutoQuestByLevel and activeInfo and playerLevel >= activeInfo.maxLevel and activeName ~= targetQuestInfo.quest then
                        if inputFunc then
                            inputFunc:InvokeServer("Quest", "Cancel", activeName)
                            task.wait(0.5)
                        end
                        return
                    end

                    if activeInfo then
                        targetQuestInfo = activeInfo
                    end
                else
                    -- Nhận quest mới
                    if inputFunc then
                        local neededIsland = targetQuestInfo.island
                        local currentIsland = getCurrentIsland()

                        if currentIsland ~= neededIsland then
                            teleportToIsland(neededIsland)
                            task.wait(1.5)
                            return
                        end

                        local npcModel = workspace.NPCs:FindFirstChild(targetQuestInfo.npc)
                        if npcModel then
                            local distToNpc = (npcModel:GetPivot().Position - root.Position).Magnitude
                            if distToNpc > 15 then
                                tweenTo(npcModel:GetPivot() * CFrame.new(0, 0, 4), Config.TweenSpeed)
                            else
                                inputFunc:InvokeServer("Quest", "Accept", npcModel)
                                task.wait(0.5)
                            end
                            return
                        end
                    end
                end

                -- Chuyển đảo nếu khác
                local neededIsland = targetQuestInfo.island
                if getCurrentIsland() ~= neededIsland then
                    teleportToIsland(neededIsland)
                    task.wait(1.5)
                    return
                end

                -- Tìm quái mục tiêu
                local bestMob = nil
                local shortestDist = math.huge
                local enemiesFolder = workspace:FindFirstChild("Enemies")

                if enemiesFolder then
                    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                        if enemy:IsA("Model") and enemy ~= char and enemy.Name ~= "Dummy" then
                            local eHum = enemy:FindFirstChildOfClass("Humanoid")
                            local eRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso") or enemy.PrimaryPart
                            if eHum and eRoot and eHum.Health > 0 then
                                local match = false
                                if Config.AutoFarmMulti and #Config.SelectedMultiMob > 0 then
                                    for _, mName in ipairs(Config.SelectedMultiMob) do
                                        if string.find(string.lower(enemy.Name), string.lower(mName)) then
                                            match = true
                                            break
                                        end
                                    end
                                else
                                    match = string.find(string.lower(enemy.Name), string.lower(targetQuestInfo.target))
                                end

                                local dist = (eRoot.Position - root.Position).Magnitude
                                if match then dist = dist - 500 end
                                if dist < shortestDist then
                                    shortestDist = dist
                                    bestMob = enemy
                                end
                            end
                        end
                    end
                end

                currentCombatTarget = bestMob

                if bestMob then
                    local targetCF = calculateTargetCFrame(bestMob, Config.SelectFarmMode, Config.DistanceY)
                    if targetCF then
                        local dist = (targetCF.Position - root.Position).Magnitude
                        if dist > 10 then
                            tweenTo(targetCF, Config.TweenSpeed)
                        else
                            root.Velocity = Vector3.zero
                            root.RotVelocity = Vector3.zero
                            root.CFrame = targetCF
                        end
                    end
                else
                    -- Chưa có quái: Tween lơ lửng gần NPC
                    local npcModel = workspace.NPCs:FindFirstChild(targetQuestInfo.npc)
                    if npcModel then
                        local npcPos = npcModel:GetPivot().Position
                        if (npcPos - root.Position).Magnitude > 25 then
                            tweenTo(CFrame.new(npcPos + Vector3.new(0, 15, 0)), Config.TweenSpeed)
                        else
                            root.CFrame = CFrame.new(npcPos + Vector3.new(0, 15, 0))
                        end
                    end
                end
            end)
        else
            if not Config.AutoFarmSelectedBoss then
                currentCombatTarget = nil
            end
        end
    end
end)

-- Worker: Auto Farm Boss & Triệu Hồi Boss (Whisperer System)
task.spawn(function()
    while scriptRunning do
        task.wait(0.15)
        if Config.AutoFarmSelectedBoss then
            pcall(function()
                local char = getCharacter()
                local root = getRoot()
                local hum = getHumanoid()
                if not char or not root or not hum or hum.Health <= 0 then return end

                equipSelectedWeapon(Config.SelectWeapon)

                local targetBossName = Config.SelectedBoss
                local bossInfo = BossConfig[targetBossName]
                local targetIsland = bossInfo and bossInfo.Island or "Tokyo Ghoul"

                -- 1. Kiểm tra Boss đã xuất hiện trong workspace chưa
                local currentBossModel = nil
                local enemiesFolder = workspace:FindFirstChild("Enemies")
                if enemiesFolder then
                    for _, e in ipairs(enemiesFolder:GetChildren()) do
                        if e:IsA("Model") and e:FindFirstChildOfClass("Humanoid") and e.Humanoid.Health > 0 then
                            if string.find(string.lower(e.Name), string.lower(targetBossName)) then
                                currentBossModel = e
                                break
                            end
                        end
                    end
                end

                -- 2. Nếu Boss chưa xuất hiện -> Đi triệu hồi bằng NPC Whisperer
                if not currentBossModel then
                    currentCombatTarget = nil
                    if Config.AutoSpawnBoss and bossInfo and bossInfo.Summoner then
                        -- Kiểm tra đảo của NPC triệu hồi
                        if getCurrentIsland() ~= targetIsland then
                            teleportToIsland(targetIsland)
                            task.wait(1.5)
                            return
                        end

                        -- Tìm NPC Summoner (Whisperer / Sacrifice Table / Zangetsu)
                        local summonerNpc = workspace.NPCs:FindFirstChild(bossInfo.Summoner)
                        if summonerNpc then
                            local distToSummoner = (summonerNpc:GetPivot().Position - root.Position).Magnitude
                            if distToSummoner > 20 then
                                tweenTo(summonerNpc:GetPivot() * CFrame.new(0, 0, 5), Config.TweenSpeed)
                            else
                                local inputFunc = getInputFunction()
                                if inputFunc then
                                    inputFunc:InvokeServer("SpawnBoss", summonerNpc, targetBossName)
                                    task.wait(1)
                                end
                            end
                        end
                    end
                    return
                end

                -- 3. Khi Boss đã xuất hiện -> Khóa vị trí đánh
                currentCombatTarget = currentBossModel
                local targetCF = calculateTargetCFrame(currentBossModel, Config.SelectFarmMode, Config.DistanceY)
                if targetCF then
                    local dist = (targetCF.Position - root.Position).Magnitude
                    if dist > 12 then
                        tweenTo(targetCF, Config.TweenSpeed)
                    else
                        root.Velocity = Vector3.zero
                        root.RotVelocity = Vector3.zero
                        root.CFrame = targetCF
                    end
                end
            end)
        end
    end
end)

-- Worker: Auto Fishing
task.spawn(function()
    while scriptRunning do
        task.wait(0.5)
        if Config.AutoFish then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

                if Config.AutoEquipRod and hum and backpack then
                    local equipped = char:FindFirstChildOfClass("Tool")
                    if not (equipped and (string.find(string.lower(equipped.Name), "rod") or string.find(string.lower(equipped.Name), "cần"))) then
                        for _, t in ipairs(backpack:GetChildren()) do
                            if t:IsA("Tool") and (string.find(string.lower(t.Name), "rod") or string.find(string.lower(t.Name), "cần")) then
                                hum:EquipTool(t)
                                break
                            end
                        end
                    end
                end

                local rod = char and char:FindFirstChildOfClass("Tool")
                if rod then
                    local fishGui = LocalPlayer.PlayerGui:FindFirstChild("FishMinigame")
                    if not fishGui or not fishGui.Enabled then
                        rod:Activate()
                    else
                        local frame = fishGui:FindFirstChild("Frame")
                        if frame then
                            local m1 = frame:FindFirstChild("Minigame1")
                            if m1 and m1.Visible then
                                local clickBtn = m1:FindFirstChild("CLICK")
                                if clickBtn then
                                    for _, conn in pairs(getconnections(clickBtn.MouseButton1Click)) do
                                        conn:Fire()
                                    end
                                end
                            end
                            local inputFunc = getInputFunction()
                            if inputFunc then
                                inputFunc:InvokeServer("Settings", "AutoFishing", true)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Worker: Auto Prestige
task.spawn(function()
    while scriptRunning do
        task.wait(2)
        if Config.AutoPrestige then
            pcall(function()
                local inputFunc = getInputFunction()
                local pDataMod = ReplicatedStorage.Modules.Configurations:FindFirstChild("PrestigeData")
                if inputFunc and pDataMod then
                    local pData = require(pDataMod)
                    local curPrestige = LocalPlayer.Data.Prestige.Value
                    local curLevel = LocalPlayer.Data.Level.Value
                    local canPrestige = true

                    if pData and pData.GetRequirements then
                        local reqs = pData.GetRequirements(curPrestige + 1)
                        if reqs then
                            for _, req in ipairs(reqs) do
                                if req.Type == "Level" and curLevel < req.Value then
                                    canPrestige = false
                                end
                            end
                        end
                    end
                    if canPrestige then
                        inputFunc:InvokeServer("Prestige")
                    end
                end
            end)
        end
    end
end)

-- Tiện ích: Giảm lag đồ họa
local function applyFPSBoost()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1
        for _, fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("PostProcessEffect") or fx:IsA("BloomEffect") or fx:IsA("BlurEffect") or fx:IsA("SunRaysEffect") then
                fx.Enabled = false
            end
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.CastShadow = false
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") then
                obj.Enabled = false
            end
        end
    end)
end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK and scriptRunning then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and scriptRunning then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if Config.Noclip and not (Config.AutoFarmSelectedMob or Config.AutoQuestByLevel or Config.AutoFarmSelectedBoss) and scriptRunning then
        pcall(function()
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
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. GIAO DIỆN UX/UI (6 TABS CHUẨN KIẾN TRÚC NK HUB)
-- ═══════════════════════════════════════════════════════════════════════════
local Window = MhnaaUI:CreateWindow({
    Title = "Mhnaa Hub",
    Tag = "[NK-SUITE]",
    Game = "LEGACY PIECE",
    Size = UDim2.new(0, 700, 0, 460),
    AccentColor = Color3.fromRGB(104, 157, 248),
    ToggleKey = Enum.KeyCode.RightControl
})

-- Tạo 6 Tab phân chia theo đúng phong cách NK HUB
local TabHome     = Window:CreateTab({ Name = "Home",     Icon = "🏠" })
local TabMain     = Window:CreateTab({ Name = "Main",     Icon = "⚔️" })
local TabBoss     = Window:CreateTab({ Name = "Boss",     Icon = "💣" })
local TabStats    = Window:CreateTab({ Name = "Stats",    Icon = "🌪️" })
local TabTeleport = Window:CreateTab({ Name = "Teleport", Icon = "🌐" })
local TabMisc     = Window:CreateTab({ Name = "Misc",     Icon = "⚙️" })

-- ─────────────────────────────────────────────────────────────────────────
-- 🏠 TAB 1: HOME
-- ─────────────────────────────────────────────────────────────────────────
TabHome:CreateSection("THÔNG TIN NGƯỜI CHƠI (LIVE STATS)")

local homeInfoLabel = TabHome:CreateLabel({
    Title = "Đang tải dữ liệu nhân vật..."
})

task.spawn(function()
    while scriptRunning do
        pcall(function()
            if LocalPlayer.Data then
                local lvl = LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value or 0
                local pts = LocalPlayer.Data:FindFirstChild("Points") and LocalPlayer.Data.Points.Value or 0
                local curIsland = getCurrentIsland()
                local qFolder = LocalPlayer.Data:FindFirstChild("Quests") and LocalPlayer.Data.Quests:FindFirstChild("Main")
                local qName = (qFolder and #qFolder:GetChildren() > 0) and qFolder:GetChildren()[1].Name or "Không có"
                
                homeInfoLabel:SetText(string.format("Level: %s | Points: %s | Đảo: %s\nNhiệm vụ: %s", tostring(lvl), tostring(pts), curIsland, qName))
            end
        end)
        task.wait(1)
    end
end)

TabHome:CreateSection("VŨ KHÍ (WEAPON)")

local weaponDropdown = TabHome:CreateDropdown({
    Title = "Select Weapon (Chọn vũ khí)",
    Options = WeaponList,
    Default = WeaponList[1] or "Ace",
    Callback = function(val)
        Config.SelectWeapon = val
    end
})

TabHome:CreateButton({
    Title = "Refresh Weapon (Làm mới túi đồ)",
    Description = "Quét lại toàn bộ vũ khí hiện có trong Balo",
    Callback = function()
        refreshWeapons()
        weaponDropdown:Set(WeaponList)
        MhnaaUI:Notify({ Title = "Weapon", Content = "Đã cập nhật danh sách vũ khí!", Duration = 2 })
    end
})

TabHome:CreateSection("TẤN CÔNG (ATTACK)")

TabHome:CreateToggle({
    Title = "Auto Attack",
    Description = "Tự động chém liên tục với tốc độ cao",
    Default = Config.AutoAttack,
    Callback = function(state) Config.AutoAttack = state end
})

TabHome:CreateSlider({
    Title = "Tốc độ chém (Attack Delay)",
    Min = 0.05,
    Max = 0.5,
    Default = Config.AttackSpeed,
    Decimals = 2,
    Suffix = "s",
    Callback = function(val) Config.AttackSpeed = val end
})

TabHome:CreateSection("KỸ NĂNG (SKILL)")

TabHome:CreateDropdown({
    Title = "Select Skill (Chọn phím chiêu thức)",
    Options = { "Z", "X", "C", "V", "E", "R" },
    Default = "Z",
    MultiSelect = true,
    Callback = function(tbl)
        Config.SelectedSkillTable = {}
        for k, v in pairs(tbl) do
            if v == true then table.insert(Config.SelectedSkillTable, k) end
        end
    end
})

TabHome:CreateToggle({
    Title = "Auto Use Selected Skill",
    Description = "Tự động tung các chiêu thức đã chọn theo chu kỳ",
    Default = Config.AutoUseSelectedSkill,
    Callback = function(state) Config.AutoUseSelectedSkill = state end
})

TabHome:CreateSlider({
    Title = "Skill Delay (Độ trễ tung chiêu)",
    Min = 0.1,
    Max = 2.0,
    Default = Config.SkillDelay,
    Decimals = 1,
    Suffix = "s",
    Callback = function(val) Config.SkillDelay = val end
})

TabHome:CreateSection("KHOẢNG CÁCH FARM (DISTANCE FARM)")

TabHome:CreateDropdown({
    Title = "Select Farm Mode (Góc đứng đánh)",
    Options = { "Above", "Behind", "Beside", "Below" },
    Default = Config.SelectFarmMode,
    Callback = function(val) Config.SelectFarmMode = val end
})

TabHome:CreateSlider({
    Title = "Farming Distance (Khoảng cách đứng)",
    Min = 3,
    Max = 25,
    Default = Config.DistanceY,
    Suffix = " studs",
    Callback = function(val) Config.DistanceY = val end
})

TabHome:CreateSlider({
    Title = "Tween Speed (Tốc độ bay Tween)",
    Min = 50,
    Max = 300,
    Default = Config.TweenSpeed,
    Suffix = " studs/s",
    Callback = function(val) Config.TweenSpeed = val end
})

-- ─────────────────────────────────────────────────────────────────────────
-- ⚔️ TAB 2: MAIN
-- ─────────────────────────────────────────────────────────────────────────
TabMain:CreateSection("AUTO FARM THEO QUÁI CHỌN (SINGLE FARM)")

TabMain:CreateDropdown({
    Title = "Select Mob (Chọn quái cần farm)",
    Options = AllMobNames,
    Default = "Ghoul Investigator",
    Callback = function(val) Config.SelectedMob = val end
})

TabMain:CreateToggle({
    Title = "Auto Farm Selected Mob",
    Description = "Tự động nhận quest tương ứng và bay đến farm quái đã chọn",
    Default = Config.AutoFarmSelectedMob,
    Callback = function(state)
        Config.AutoFarmSelectedMob = state
        if not state then stopCurrentTween() currentCombatTarget = nil end
    end
})

TabMain:CreateSection("AUTO QUEST THEO LEVEL (LEVEL PROGRESSION)")

TabMain:CreateToggle({
    Title = "Auto Farm Theo Cấp Độ (Auto Level 0 - 9300+)",
    Description = "Tự động hủy quest cũ out-level, tele sang đảo mới và nhận quest theo cấp",
    Default = Config.AutoQuestByLevel,
    Callback = function(state)
        Config.AutoQuestByLevel = state
        if not state then stopCurrentTween() currentCombatTarget = nil end
    end
})

TabMain:CreateSection("AUTO FARM NHIỀU QUÁI (MULTI-SELECT)")

TabMain:CreateDropdown({
    Title = "Select Multi Mob (Chọn nhiều loại quái)",
    Options = AllMobNames,
    Default = AllMobNames[1] or "Bandit",
    MultiSelect = true,
    Callback = function(tbl)
        Config.SelectedMultiMob = {}
        for k, v in pairs(tbl) do
            if v == true then table.insert(Config.SelectedMultiMob, k) end
        end
    end
})

TabMain:CreateToggle({
    Title = "Auto Farm Multi Selected Mob",
    Description = "Tự động gom và farm lần lượt các loại quái đã chọn",
    Default = Config.AutoFarmMulti,
    Callback = function(state)
        Config.AutoFarmMulti = state
        if not state then stopCurrentTween() currentCombatTarget = nil end
    end
})

TabMain:CreateSection("AUTO PRESTIGE (CHUYỂN SINH)")

TabMain:CreateToggle({
    Title = "Auto Prestige",
    Description = "Tự động kiểm tra điều kiện và chuyển sinh ngay khi đủ điều kiện",
    Default = Config.AutoPrestige,
    Callback = function(state) Config.AutoPrestige = state end
})

TabMain:CreateDropdown({
    Title = "Chế độ Prestige",
    Options = { "Khi đủ nhiệm vụ", "Khi đạt Max Level", "Ngay lập tức" },
    Default = Config.PrestigeMode,
    Callback = function(val) Config.PrestigeMode = val end
})

TabMain:CreateSection("AUTO CÂU CÁ (FISHING)")

TabMain:CreateToggle({
    Title = "Auto Câu Cá",
    Description = "Tự động thả câu và kéo cá khi có cắn câu",
    Default = Config.AutoFish,
    Callback = function(state) Config.AutoFish = state end
})

TabMain:CreateDropdown({
    Title = "Chế độ kéo cần",
    Options = { "Fast / Instant Reel", "Legit / Normal" },
    Default = Config.FishingMode,
    Callback = function(val) Config.FishingMode = val end
})

-- ─────────────────────────────────────────────────────────────────────────
-- 💣 TAB 3: BOSS (AUTO FARM & SUMMON BOSS)
-- ─────────────────────────────────────────────────────────────────────────
TabBoss:CreateSection("AUTO FARM BOSS ĐÃ CHỌN (SELECTED BOSS)")

TabBoss:CreateDropdown({
    Title = "Select Boss (Chọn Boss)",
    Options = AllBossNames,
    Default = "Ken Kaneki",
    Callback = function(val)
        Config.SelectedBoss = val
    end
})

TabBoss:CreateToggle({
    Title = "Auto Spawn Boss (Tự động triệu hồi)",
    Description = "Tự động bay đến NPC Whisperer tương ứng và triệu hồi Boss nếu chưa spawn",
    Default = Config.AutoSpawnBoss,
    Callback = function(state) Config.AutoSpawnBoss = state end
})

TabBoss:CreateToggle({
    Title = "Auto Farm Selected Boss",
    Description = "Tự động dịch chuyển, khóa góc đánh và tiêu diệt Boss đã chọn",
    Default = Config.AutoFarmSelectedBoss,
    Callback = function(state)
        Config.AutoFarmSelectedBoss = state
        if not state then stopCurrentTween() currentCombatTarget = nil end
    end
})

TabBoss:CreateButton({
    Title = "Force Spawn Selected Boss (Triệu hồi ngay)",
    Description = "Lập tức gọi lệnh triệu hồi Boss đã chọn",
    Callback = function()
        local bInfo = BossConfig[Config.SelectedBoss]
        local summoner = bInfo and workspace.NPCs:FindFirstChild(bInfo.Summoner)
        local inputFunc = getInputFunction()
        if inputFunc and summoner then
            inputFunc:InvokeServer("SpawnBoss", summoner, Config.SelectedBoss)
            MhnaaUI:Notify({ Title = "Boss System", Content = "Đã gửi yêu cầu triệu hồi: " .. Config.SelectedBoss, Duration = 3 })
        else
            MhnaaUI:Notify({ Title = "Boss System", Content = "Không tìm thấy NPC triệu hồi của Boss này!", Duration = 3 })
        end
    end
})

TabBoss:CreateSection("AUTO FARM NHIỀU BOSS (MULTI BOSS)")

TabBoss:CreateDropdown({
    Title = "Select Multi Bosses (Chọn nhiều Boss)",
    Options = AllBossNames,
    Default = AllBossNames[1] or "Ken Kaneki",
    MultiSelect = true,
    Callback = function(tbl)
        Config.SelectedBossTable = {}
        for k, v in pairs(tbl) do
            if v == true then table.insert(Config.SelectedBossTable, k) end
        end
    end
})

-- ─────────────────────────────────────────────────────────────────────────
-- 🌪️ TAB 4: STATS
-- ─────────────────────────────────────────────────────────────────────────
TabStats:CreateSection("CỘNG ĐIỂM TIỀM NĂNG (STATS)")

TabStats:CreateSlider({
    Title = "Amount (Số điểm mỗi lần cộng)",
    Min = 1,
    Max = 200,
    Default = Config.Amount,
    Suffix = " pts",
    Callback = function(val) Config.Amount = val end
})

TabStats:CreateDropdown({
    Title = "Select Stats (Chọn chỉ số ưu tiên)",
    Options = { "Weapon", "Strength", "Defense", "Ability", "All Evenly" },
    Default = "Weapon",
    MultiSelect = true,
    Callback = function(tbl)
        Config.SelectedStatsTable = {}
        for k, v in pairs(tbl) do
            if v == true then table.insert(Config.SelectedStatsTable, k) end
        end
    end
})

TabStats:CreateToggle({
    Title = "Auto Up Selected Stats",
    Description = "Tự động phát hiện Points dư và cộng vào chỉ số đã chọn",
    Default = Config.AutoUpSelectedStats,
    Callback = function(state) Config.AutoUpSelectedStats = state end
})

TabStats:CreateButton({
    Title = "Cộng Toàn Bộ Điểm Vào Weapon",
    Callback = function()
        local pts = LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Points") and LocalPlayer.Data.Points.Value or 0
        local inputFunc = getInputFunction()
        if inputFunc and pts > 0 then
            inputFunc:InvokeServer("AddPoint", "Weapon", pts)
            MhnaaUI:Notify({ Title = "Stats", Content = "Đã cộng toàn bộ " .. pts .. " điểm vào Weapon!", Duration = 3 })
        end
    end
})

-- ─────────────────────────────────────────────────────────────────────────
-- 🌐 TAB 5: TELEPORT
-- ─────────────────────────────────────────────────────────────────────────
TabTeleport:CreateSection("TELEPORT TO MAPS (DỊCH CHUYỂN QUA ĐẢO)")

local IslandNameList = {}
for isl, _ in pairs(IslandCenters) do
    table.insert(IslandNameList, isl)
end
table.sort(IslandNameList)

TabTeleport:CreateDropdown({
    Title = "Select Map (Chọn đảo)",
    Options = IslandNameList,
    Default = "Tokyo Ghoul",
    Callback = function(val) Config.SelectedMaps = val end
})

TabTeleport:CreateButton({
    Title = "Teleport To Map",
    Description = "Dịch chuyển tức thì qua cổng game (0% Gameplay Paused)",
    Callback = function()
        teleportToIsland(Config.SelectedMaps)
    end
})

TabTeleport:CreateSection("TELEPORT TO NPCS (DỊCH CHUYỂN TỚI NPC)")

local AllNpcNames = {}
if workspace:FindFirstChild("NPCs") then
    for _, c in ipairs(workspace.NPCs:GetChildren()) do
        if not table.find(AllNpcNames, c.Name) then
            table.insert(AllNpcNames, c.Name)
        end
    end
end
table.sort(AllNpcNames)

local npcDropdown = TabTeleport:CreateDropdown({
    Title = "Select NPC (Chọn NPC)",
    Options = AllNpcNames,
    Default = AllNpcNames[1] or "",
    Callback = function(val) Config.SelectedNPC = val end
})

TabTeleport:CreateButton({
    Title = "Teleport To NPC",
    Description = "Dùng Tween lướt mượt đến trước mặt NPC đã chọn",
    Callback = function()
        local targetNpc = workspace.NPCs:FindFirstChild(Config.SelectedNPC)
        if targetNpc then
            tweenTo(targetNpc:GetPivot() * CFrame.new(0, 0, 4), Config.TweenSpeed)
        end
    end
})

TabTeleport:CreateSection("TIỆN ÍCH KHẨN CẤP")

TabTeleport:CreateButton({
    Title = "Về Đảo Chính (Legacy Island)",
    Callback = function()
        teleportToIsland("Legacy Island")
    end
})

TabTeleport:CreateButton({
    Title = "Hủy Quest Đang Kẹt (Force Cancel Quest)",
    Callback = function()
        local inputFunc = getInputFunction()
        local qFolder = LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Quests") and LocalPlayer.Data.Quests:FindFirstChild("Main")
        if inputFunc and qFolder and #qFolder:GetChildren() > 0 then
            local qName = qFolder:GetChildren()[1].Name
            inputFunc:InvokeServer("Quest", "Cancel", qName)
            MhnaaUI:Notify({ Title = "Quest", Content = "Đã hủy quest: " .. qName, Duration = 3 })
        end
    end
})

-- ─────────────────────────────────────────────────────────────────────────
-- ⚙️ TAB 6: MISCELLANEOUS
-- ─────────────────────────────────────────────────────────────────────────
TabMisc:CreateSection("SERVER")

TabMisc:CreateButton({
    Title = "Rejoin Server (Vào lại server)",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

TabMisc:CreateButton({
    Title = "Hop Server (Đổi server ngẫu nhiên)",
    Callback = function()
        pcall(function()
            local sfUrl = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
            local req = HttpService:JSONDecode(game:HttpGet(sfUrl))
            if req and req.data then
                for _, s in ipairs(req.data) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                        break
                    end
                end
            end
        end)
    end
})

TabMisc:CreateSection("OPTIMIZE (TỐI ƯU HÓA MÁY)")

TabMisc:CreateButton({
    Title = "White Screen (Bật/Tắt màn hình trắng)",
    Callback = function()
        Config.WhiteScreen = not Config.WhiteScreen
        RunService:Set3dRenderingEnabled(not Config.WhiteScreen)
        MhnaaUI:Notify({ Title = "Optimize", Content = "White Screen: " .. tostring(Config.WhiteScreen), Duration = 2 })
    end
})

TabMisc:CreateButton({
    Title = "Black Screen (Bật/Tắt màn hình đen)",
    Callback = function()
        local existing = LocalPlayer.PlayerGui:FindFirstChild("BlackoutOverlay")
        if existing then
            existing:Destroy()
            MhnaaUI:Notify({ Title = "Optimize", Content = "Đã tắt Black Screen", Duration = 2 })
        else
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "BlackoutOverlay"
            screenGui.ResetOnSpawn = false
            screenGui.IgnoreGuiInset = true
            screenGui.DisplayOrder = 999999
            screenGui.Parent = LocalPlayer.PlayerGui

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BorderSizePixel = 0
            frame.Parent = screenGui
            MhnaaUI:Notify({ Title = "Optimize", Content = "Đã bật Black Screen", Duration = 2 })
        end
    end
})

TabMisc:CreateToggle({
    Title = "Tắt Render 3D (GPU 0% - Treo Đêm)",
    Description = "Dừng dựng hình 3D giúp GPU cực mát khi cắm farm qua đêm",
    Default = Config.Disable3DRender,
    Callback = function(state)
        Config.Disable3DRender = state
        RunService:Set3dRenderingEnabled(not state)
    end
})

TabMisc:CreateToggle({
    Title = "FPS Booster (Giảm lag đồ họa)",
    Description = "Khử bóng đổ, chuyển vật liệu nhựa trơn, tắt hiệu ứng hạt",
    Default = Config.FPSBooster,
    Callback = function(state)
        Config.FPSBooster = state
        if state then applyFPSBoost() end
    end
})

TabMisc:CreateSection("DI CHUYỂN & CHỐNG AFK")

TabMisc:CreateSlider({
    Title = "WalkSpeed (Tốc độ chạy)",
    Min = 16,
    Max = 250,
    Default = Config.WalkSpeed,
    Suffix = " spd",
    Callback = function(val)
        Config.WalkSpeed = val
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = val end
    end
})

TabMisc:CreateSlider({
    Title = "JumpPower (Độ cao nhảy)",
    Min = 50,
    Max = 300,
    Default = Config.JumpPower,
    Suffix = " pwr",
    Callback = function(val)
        Config.JumpPower = val
        local hum = getHumanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = val
        end
    end
})

TabMisc:CreateToggle({
    Title = "Infinite Jump (Nhảy vô hạn)",
    Default = Config.InfiniteJump,
    Callback = function(state) Config.InfiniteJump = state end
})

TabMisc:CreateToggle({
    Title = "Noclip Xuyên Tường",
    Default = Config.Noclip,
    Callback = function(state) Config.Noclip = state end
})

TabMisc:CreateToggle({
    Title = "Anti-AFK (Chống bị kick 20p)",
    Default = Config.AntiAFK,
    Callback = function(state) Config.AntiAFK = state end
})

TabMisc:CreateSection("CẤU HÌNH HUB")

TabMisc:CreateKeybind({
    Title = "Phím Ẩn/Hiện Menu (Toggle Key)",
    Default = Enum.KeyCode.RightControl,
    Callback = function(key) Window:SetToggleKey(key) end
})

TabMisc:CreateDropdown({
    Title = "Màu Sắc Chủ Đạo (Theme Accent)",
    Options = { "Dodger Blue", "Emerald Green", "Crimson Red", "Amber Gold", "Purple Haze" },
    Default = "Dodger Blue",
    Callback = function(choice)
        local colors = {
            ["Dodger Blue"]  = Color3.fromRGB(104, 157, 248),
            ["Emerald Green"]= Color3.fromRGB(46, 204, 113),
            ["Crimson Red"]  = Color3.fromRGB(231, 76, 60),
            ["Amber Gold"]   = Color3.fromRGB(241, 196, 15),
            ["Purple Haze"]  = Color3.fromRGB(155, 89, 182)
        }
        if colors[choice] then MhnaaUI:SetThemeColor("Accent", colors[choice]) end
    end
})

TabMisc:CreateButton({
    Title = "Đóng & Dừng Hoàn Toàn Hub",
    Callback = function()
        if _G.MhnaaHub_Stop then _G.MhnaaHub_Stop() end
        Window:Destroy()
        RunService:Set3dRenderingEnabled(true)
    end
})

MhnaaUI:Notify({
    Title = "Mhnaa Hub [NK-SUITE]",
    Content = "Đã nạp thành công bộ 6 Tab chuẩn NK Hub! Nhấn [RightControl] để ẩn/hiện.",
    Duration = 4
})
