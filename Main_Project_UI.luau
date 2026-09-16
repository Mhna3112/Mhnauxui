--[[
    ═══════════════════════════════════════════════════════════════════════════
    ✨ MHNAA HUB [PRO] - HYBRID TELEPORT & TWEEN AUTO FARM ✨
    Chuyên biệt cho [Bleach!] Legacy Piece (Max Level 12,000)
    - Tự Động Cộng Điểm (Auto Stat: Weapon, Strength, Defense, Ability, All Evenly)
    - Tự Động Hủy Quest Cũ Out-Level & Nhận Quest Mới Theo Cấp Độ Chính Xác
    - Tự Động Teleport Qua Đảo Chứa Quest Tương Ứng (Không Bị Gameplay Paused)
    - Dùng Tween Lướt Mượt Đến Bãi Quái Và Khóa Góc Đánh (Above, Beside, Behind, Under)
    - Quản lý phiên chạy đơn (Single Instance) chống kẹt luồng ngầm
    ═══════════════════════════════════════════════════════════════════════════
]]

-- DỌN DẸP PHIÊN CHẠY CŨ
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

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Dọn dẹp ScreenGui cũ nếu có
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

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. TỰ ĐỘNG CHẶN BẢNG THÔNG BÁO GAMEPLAY PAUSED
-- ═══════════════════════════════════════════════════════════════════════════
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
-- 3. BẢNG CẤU HÌNH (CONFIG)
-- ═══════════════════════════════════════════════════════════════════════════
local Config = {
    -- Auto Stat
    AutoStat = false,
    SelectedStat = "Weapon", -- "Weapon", "Strength", "Defense", "Ability", "All Evenly (Chia đều)"
    StatPointsPerBatch = 10,
    
    -- Auto Prestige
    AutoPrestige = false,
    PrestigeMode = "Khi đủ nhiệm vụ",
    
    -- Auto Farm
    AutoFarm = false,
    AutoQuest = true,
    FarmPosition = "Above (Bên trên)", -- "Above (Bên trên)", "Beside (Bên cạnh)", "Behind (Phía sau)", "Under (Bên dưới)"
    FarmDistance = 7,
    TweenSpeed = 160, -- Tốc độ bay Tween trên đảo (studs/s)
    AutoAttack = true,
    AttackSpeed = 0.08,
    
    -- Weapon & Skills
    AutoEquipWeapon = true,
    SelectedWeapon = "Ace",
    AutoUseSkills = false,
    SkillDelay = 0.5,
    Skills = {
        Z = true,
        X = true,
        C = true,
        V = false,
        E = false,
        R = false
    },
    
    -- Fishing
    AutoFish = false,
    FishingMode = "Fast / Instant Reel",
    AutoEquipRod = true,
    AutoSellFish = false,
    
    -- Misc / Performance
    FPSBooster = false,
    Disable3DRender = false,
    AntiAFK = true,
    
    -- Player Modifiers
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. BẢNG DỮ LIỆU CÁC QUEST CHÍNH THEO CẤP ĐỘ (CHÍNH XÁC TỪ QUESTDATA)
-- ═══════════════════════════════════════════════════════════════════════════
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

-- Tọa độ trung tâm hoặc Teleporter của từng Đảo
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

-- Portal ID chính thức tương ứng
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

-- Điểm Teleport Spot theo Remote TeleportToIslandSpot
local IslandSpots = {
    ["Jujutsu Academy"]    = { Island = "Jujutsu Academy", Spot = "The Gatekeeper" },
    ["Starter Island"]     = { Island = "Starter Island", Spot = "Mining" },
    ["Legacy Island"]      = { Island = "Legacy Island", Spot = "Summon" },
    ["7th Company Island"] = { Island = "7th Company Island", Spot = "Captain Burns" },
    ["Fishman Island"]     = { Island = "Fishman Island", Spot = "Fishman Elder" },
    ["Ice Island"]         = { Island = "Ice Island", Spot = "Fish Shop" },
    ["Ruin City"]          = { Island = "Ruin City", Spot = "Sacrifice Table" },
    ["Jungle Island"]      = { Island = "Jungle Island", Spot = "Flashstep" },
    ["A-City"]             = { Island = "A-City", Spot = "Observation Haki" },
    ["Quincy Castle"]      = { Island = "Quincy Castle", Spot = "Quincy Herald" }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. HÀM TRỢ GIÚP TIỆN ÍCH
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

-- Xác định người chơi đang ở đảo nào dựa trên tọa độ
local function getCurrentIsland()
    local root = getRoot()
    if not root then return "Unknown" end
    local pos = root.Position
    local closestIsland = "Starter Island"
    local minDist = math.huge
    for isl, center in pairs(IslandCenters) do
        local dist = (pos - center).Magnitude
        if dist < minDist then
            minDist = dist
            closestIsland = isl
        end
    end
    return closestIsland
end

-- Lấy Quest phù hợp nhất theo cấp độ
local function getBestQuestInfo(level)
    local best = QuestDatabase[1]
    for _, q in ipairs(QuestDatabase) do
        if level >= q.minLevel then
            best = q
        end
    end
    return best
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
-- 6. HỆ THỐNG TELEPORT QUA ĐẢO & TWEEN TRÊN ĐẢO (ZERO GAMEPLAY PAUSED)
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

-- Tween mượt mà trên đảo tới mục tiêu
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

-- Chuyển qua đảo khác an toàn bằng hệ thống Teleporter của game
local function teleportToIsland(targetIsland)
    stopCurrentTween()
    local current = getCurrentIsland()
    if current == targetIsland then return true end

    local tpUI = getTeleportUI()
    
    -- Phương án 1: Dùng _G.TeleportUI chọn đảo và dịch chuyển
    if tpUI and tpUI.selectIsland and tpUI.teleport then
        pcall(function()
            tpUI:selectIsland(targetIsland)
            task.wait(0.2)
            tpUI:teleport()
        end)
        task.wait(1.5)
        if getCurrentIsland() == targetIsland then return true end
    end

    -- Phương án 2: Kích hoạt Teleporter prompt trên đảo hiện tại nếu cần
    local root = getRoot()
    local nearestTeleporter = nil
    local minDist = math.huge
    if root and workspace:FindFirstChild("NPCs") then
        for _, c in ipairs(workspace.NPCs:GetChildren()) do
            if c.Name == "Teleporter" then
                local dist = (c:GetPivot().Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearestTeleporter = c
                end
            end
        end
    end

    if nearestTeleporter and minDist > 8 and minDist < 600 then
        tweenTo(nearestTeleporter:GetPivot() * CFrame.new(0, 0, 4), 220)
        local prompt = nearestTeleporter:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function() fireproximityprompt(prompt) end)
            task.wait(0.4)
        end
        if tpUI and tpUI.selectIsland and tpUI.teleport then
            pcall(function()
                tpUI:selectIsland(targetIsland)
                task.wait(0.2)
                tpUI:teleport()
            end)
            task.wait(1.5)
            if getCurrentIsland() == targetIsland then return true end
        end
    end

    -- Phương án 3: Dùng Remote trực tiếp
    local tpSpotRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("TeleportToIslandSpot")
    local tpPortalRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("TeleportToPortal")

    local spotInfo = IslandSpots[targetIsland]
    if tpSpotRemote and spotInfo then
        pcall(function()
            tpSpotRemote:FireServer(spotInfo.Island, spotInfo.Spot)
        end)
        task.wait(1.2)
        if getCurrentIsland() == targetIsland then return true end
    end

    local portalId = IslandPortalIds[targetIsland]
    if tpPortalRemote and portalId then
        pcall(function()
            tpPortalRemote:FireServer(portalId)
        end)
        task.wait(1.2)
        if getCurrentIsland() == targetIsland then return true end
    end

    return getCurrentIsland() == targetIsland
end

-- Tính toán CFrame vị trí đứng quanh NPC / Quái theo tùy chọn
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

    distance = distance or 7

    if positionMode == "Above (Bên trên)" then
        return targetCF * CFrame.new(0, distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    elseif positionMode == "Beside (Bên cạnh)" then
        return targetCF * CFrame.new(distance, 1, 0) * CFrame.Angles(0, math.rad(-90), 0)
    elseif positionMode == "Behind (Phía sau)" then
        return targetCF * CFrame.new(0, 1, distance)
    elseif positionMode == "Under (Bên dưới)" then
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

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. AUTO STAT WORKER (TỰ ĐỘNG CỘNG ĐIỂM)
-- ═══════════════════════════════════════════════════════════════════════════
task.spawn(function()
    while scriptRunning do
        task.wait(0.5)
        if Config.AutoStat then
            pcall(function()
                local points = LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Points") and LocalPlayer.Data.Points.Value
                if points and points > 0 then
                    local inputFunc = getInputFunction()
                    if inputFunc then
                        local batch = math.clamp(Config.StatPointsPerBatch or 10, 1, points)
                        if Config.SelectedStat == "All Evenly (Chia đều)" then
                            local each = math.max(1, math.floor(batch / 4))
                            inputFunc:InvokeServer("AddPoint", "Weapon", each)
                            inputFunc:InvokeServer("AddPoint", "Strength", each)
                            inputFunc:InvokeServer("AddPoint", "Defense", each)
                            inputFunc:InvokeServer("AddPoint", "Ability", each)
                        else
                            local stat = Config.SelectedStat or "Weapon"
                            inputFunc:InvokeServer("AddPoint", stat, batch)
                        end
                    end
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 8. AUTO FARM WORKER CHÍNH (TELEPORT QUA ĐẢO + TWEEN FARM QUÁI)
-- ═══════════════════════════════════════════════════════════════════════════
local currentMobTarget = nil

task.spawn(function()
    while scriptRunning do
        task.wait(0.1)
        if Config.AutoFarm then
            pcall(function()
                local char = getCharacter()
                local root = getRoot()
                local hum = getHumanoid()
                if not char or not root or not hum or hum.Health <= 0 then return end

                if Config.AutoEquipWeapon then
                    equipSelectedWeapon(Config.SelectedWeapon)
                end

                local playerLevel = (LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Level") and LocalPlayer.Data.Level.Value) or 1
                local inputFunc = getInputFunction()

                -- 1. Quản lý trạng thái Quest hiện tại
                local activeQuestFolder = LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Quests") and LocalPlayer.Data.Quests:FindFirstChild("Main")
                local activeQuestObj = activeQuestFolder and activeQuestFolder:GetChildren()[1]

                local targetQuestInfo = getBestQuestInfo(playerLevel)

                if activeQuestObj then
                    local activeName = activeQuestObj.Name
                    local activeInfo = getQuestInfoByName(activeName)

                    -- Kiểm tra nếu quest đã hoàn thành (Claim quest)
                    local isCompleted = activeQuestObj:FindFirstChild("Completed") and activeQuestObj.Completed.Value == true
                    if isCompleted and inputFunc then
                        inputFunc:InvokeServer("Quest", "Claim", activeName)
                        task.wait(0.5)
                        return
                    end

                    -- Kiểm tra nếu quest hiện tại đã out-level (Cấp người chơi đã vượt ngưỡng maxLevel của quest)
                    if Config.AutoQuest and activeInfo and playerLevel >= activeInfo.maxLevel and activeName ~= targetQuestInfo.quest then
                        -- Tự động hủy quest cũ để không bị kẹt ở đảo thấp cấp!
                        if inputFunc then
                            inputFunc:InvokeServer("Quest", "Cancel", activeName)
                            task.wait(0.5)
                        end
                        return
                    end

                    -- Nếu quest vẫn đang phù hợp thì tiếp tục làm quest này
                    if activeInfo then
                        targetQuestInfo = activeInfo
                    end
                else
                    -- Chưa có quest nào: Nếu bật AutoQuest, cần nhận quest mới
                    if Config.AutoQuest and inputFunc then
                        local neededIsland = targetQuestInfo.island
                        local currentIsland = getCurrentIsland()

                        -- Nếu khác đảo, dịch chuyển sang đảo của Quest
                        if currentIsland ~= neededIsland then
                            teleportToIsland(neededIsland)
                            task.wait(1.5)
                            return
                        end

                        -- Đã ở trên đảo: Tìm NPC giao quest
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

                -- 2. Kiểm tra Đảo hiện tại so với mục tiêu Farm
                local neededIsland = targetQuestInfo.island
                local currentIsland = getCurrentIsland()
                if currentIsland ~= neededIsland then
                    teleportToIsland(neededIsland)
                    task.wait(1.5)
                    return
                end

                -- 3. Tìm Quái Mục Tiêu (Enemies)
                local bestMob = nil
                local shortestDist = math.huge
                local enemiesFolder = workspace:FindFirstChild("Enemies")

                if enemiesFolder then
                    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                        if enemy:IsA("Model") and enemy ~= char and enemy.Name ~= "Dummy" then
                            local eHum = enemy:FindFirstChildOfClass("Humanoid")
                            local eRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso") or enemy.PrimaryPart
                            if eHum and eRoot and eHum.Health > 0 then
                                -- Ưu tiên quái đúng mục tiêu của quest
                                local isQuestTarget = string.find(string.lower(enemy.Name), string.lower(targetQuestInfo.target))
                                local dist = (eRoot.Position - root.Position).Magnitude
                                if isQuestTarget then
                                    dist = dist - 500 -- Ưu tiên cao hơn
                                end
                                if dist < shortestDist then
                                    shortestDist = dist
                                    bestMob = enemy
                                end
                            end
                        end
                    end
                end

                currentMobTarget = bestMob

                -- 4. Di chuyển & Khóa vị trí quái
                if bestMob then
                    local targetCF = calculateTargetCFrame(bestMob, Config.FarmPosition, Config.FarmDistance)
                    if targetCF then
                        local distToMob = (targetCF.Position - root.Position).Magnitude
                        if distToMob > 10 then
                            tweenTo(targetCF, Config.TweenSpeed)
                        else
                            root.Velocity = Vector3.zero
                            root.RotVelocity = Vector3.zero
                            root.CFrame = targetCF
                        end
                    end
                else
                    -- Chưa có quái: Tween nhẹ quanh vị trí Quest NPC để đợi quái hồi sinh
                    local npcModel = workspace.NPCs:FindFirstChild(targetQuestInfo.npc)
                    if npcModel then
                        local npcPos = npcModel:GetPivot().Position
                        local distToNpc = (npcPos - root.Position).Magnitude
                        if distToNpc > 25 then
                            tweenTo(CFrame.new(npcPos + Vector3.new(0, 15, 0)), Config.TweenSpeed)
                        else
                            root.Velocity = Vector3.zero
                            root.RotVelocity = Vector3.zero
                            root.CFrame = CFrame.new(npcPos + Vector3.new(0, 15, 0))
                        end
                    end
                end
            end)
        else
            stopCurrentTween()
            currentMobTarget = nil
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 9. VÒNG LẶP TẤN CÔNG (AUTO ATTACK & AUTO SKILL)
-- ═══════════════════════════════════════════════════════════════════════════
task.spawn(function()
    while scriptRunning do
        task.wait(Config.AttackSpeed or 0.08)
        if Config.AutoFarm and currentMobTarget and not isTweening then
            pcall(function()
                local char = getCharacter()
                if not char then return end

                if Config.AutoAttack then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    end
                    VirtualUser:CaptureController()
                    VirtualUser:Button1Down(Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2))
                end
            end)
        end
    end
end)

-- Auto Skill Combos
task.spawn(function()
    local skillKeys = {
        { Key = "Z", EnumKey = Enum.KeyCode.Z },
        { Key = "X", EnumKey = Enum.KeyCode.X },
        { Key = "C", EnumKey = Enum.KeyCode.C },
        { Key = "V", EnumKey = Enum.KeyCode.V },
        { Key = "E", EnumKey = Enum.KeyCode.E },
        { Key = "R", EnumKey = Enum.KeyCode.R }
    }
    while scriptRunning do
        task.wait(Config.SkillDelay or 0.5)
        if Config.AutoFarm and Config.AutoUseSkills and currentMobTarget and not isTweening then
            for _, sk in ipairs(skillKeys) do
                if Config.Skills[sk.Key] and currentMobTarget and not isTweening then
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, sk.EnumKey, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, sk.EnumKey, false, game)
                    end)
                    task.wait(Config.SkillDelay or 0.5)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 10. AUTO PRESTIGE WORKER
-- ═══════════════════════════════════════════════════════════════════════════
task.spawn(function()
    while scriptRunning do
        task.wait(2)
        if Config.AutoPrestige then
            pcall(function()
                local inputFunc = getInputFunction()
                if not inputFunc then return end

                local pDataMod = ReplicatedStorage.Modules.Configurations:FindFirstChild("PrestigeData")
                if pDataMod then
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

-- ═══════════════════════════════════════════════════════════════════════════
-- 11. AUTO FISHING SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════════════════
-- 12. GIẢM LAG & TIỆN ÍCH
-- ═══════════════════════════════════════════════════════════════════════════
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

-- Noclip chung
RunService.Stepped:Connect(function()
    if Config.Noclip and not Config.AutoFarm and scriptRunning then
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
-- 13. GIAO DIỆN UX/UI (MAIN, MISC, SETTING)
-- ═══════════════════════════════════════════════════════════════════════════
local Window = MhnaaUI:CreateWindow({
    Title = "Mhnaa Hub",
    Tag = "[PRO-MULTI]",
    Game = "LEGACY PIECE",
    Size = UDim2.new(0, 680, 0, 450),
    AccentColor = Color3.fromRGB(104, 157, 248),
    ToggleKey = Enum.KeyCode.RightControl
})

-- Tạo 3 Tabs chính: Main, Misc, Setting
local MainTab    = Window:CreateTab({ Name = "Main",    Icon = "⚡" })
local MiscTab    = Window:CreateTab({ Name = "Misc",    Icon = "⚙️" })
local SettingTab = Window:CreateTab({ Name = "Setting", Icon = "🛠️" })

-- ─────────────────────────────────────────────────────────────────────────
-- 🌟 MAIN TAB
-- ─────────────────────────────────────────────────────────────────────────
MainTab:CreateSection("TỰ ĐỘNG CỘNG ĐIỂM (AUTO STAT)")

MainTab:CreateToggle({
    Title = "Auto Stat (Tự động cộng điểm)",
    Description = "Tự động phát hiện điểm Points dư thừa và cộng vào thuộc tính đã chọn",
    Default = Config.AutoStat,
    Callback = function(state) Config.AutoStat = state end
})

MainTab:CreateDropdown({
    Title = "Chọn Chỉ Số Ưu Tiên",
    Options = {
        "Weapon",
        "Strength",
        "Defense",
        "Ability",
        "All Evenly (Chia đều)"
    },
    Default = Config.SelectedStat,
    Callback = function(selected) Config.SelectedStat = selected end
})

MainTab:CreateSlider({
    Title = "Số Điểm Mỗi Đợt Cộng (Batch Amount)",
    Min = 1,
    Max = 100,
    Default = Config.StatPointsPerBatch,
    Suffix = " pts",
    Callback = function(val) Config.StatPointsPerBatch = val end
})

MainTab:CreateSection("AUTO PRESTIGE / CHUYỂN SINH")

MainTab:CreateToggle({
    Title = "Auto Prestige (Tự động chuyển sinh)",
    Description = "Tự động kiểm tra điều kiện và chuyển sinh ngay khi đủ điều kiện",
    Default = Config.AutoPrestige,
    Callback = function(state) Config.AutoPrestige = state end
})

MainTab:CreateDropdown({
    Title = "Chế độ Prestige",
    Options = { "Khi đủ nhiệm vụ", "Khi đạt Max Level", "Ngay lập tức" },
    Default = Config.PrestigeMode,
    Callback = function(selected) Config.PrestigeMode = selected end
})

MainTab:CreateSection("AUTO FARM (TELEPORT ĐẢO + TWEEN QUÁI)")

MainTab:CreateToggle({
    Title = "Auto Farm Mobs",
    Description = "Tự động tìm đảo, tele cổng không bị paused -> Tween bay mượt đến quái và farm",
    Default = Config.AutoFarm,
    Callback = function(state)
        Config.AutoFarm = state
        if not state then
            stopCurrentTween()
            currentMobTarget = nil
        end
    end
})

MainTab:CreateToggle({
    Title = "Auto Nhận Quest Theo Level & Đổi Đảo",
    Description = "Tự động hủy quest cũ out-level, tele sang đảo mới và nhận quest theo cấp",
    Default = Config.AutoQuest,
    Callback = function(state) Config.AutoQuest = state end
})

MainTab:CreateSlider({
    Title = "Tốc Độ Bay Tween (Tween Speed)",
    Min = 50,
    Max = 300,
    Default = Config.TweenSpeed,
    Suffix = " studs/s",
    Callback = function(val)
        Config.TweenSpeed = val
    end
})

MainTab:CreateDropdown({
    Title = "Vị trí đứng quanh NPC / Quái",
    Options = {
        "Above (Bên trên)",
        "Beside (Bên cạnh)",
        "Behind (Phía sau)",
        "Under (Bên dưới)"
    },
    Default = Config.FarmPosition,
    Callback = function(selected) Config.FarmPosition = selected end
})

MainTab:CreateSlider({
    Title = "Khoảng cách đứng (Distance)",
    Min = 3,
    Max = 25,
    Default = Config.FarmDistance,
    Suffix = " studs",
    Callback = function(val) Config.FarmDistance = val end
})

MainTab:CreateToggle({
    Title = "Auto Fast Attack",
    Description = "Tự động kích hoạt đòn đánh chém liên tục với tốc độ cao",
    Default = Config.AutoAttack,
    Callback = function(state) Config.AutoAttack = state end
})

MainTab:CreateSection("VŨ KHÍ & AUTO SKILL")

MainTab:CreateToggle({
    Title = "Auto Equip Weapon (Tự Cầm Vũ Khí)",
    Description = "Tự động rút và trang bị vũ khí đã chọn lên tay",
    Default = Config.AutoEquipWeapon,
    Callback = function(state) Config.AutoEquipWeapon = state end
})

MainTab:CreateDropdown({
    Title = "Chọn Loại Vũ Khí",
    Options = { "Ace", "Combat", "Tatsumaki", "Joestar", "Sword" },
    Default = Config.SelectedWeapon,
    Callback = function(selected) Config.SelectedWeapon = selected end
})

MainTab:CreateToggle({
    Title = "Auto Sử Dụng Chiêu Thức (Skills)",
    Description = "Tự động tung combo các chiêu thức đã chọn khi farm",
    Default = Config.AutoUseSkills,
    Callback = function(state) Config.AutoUseSkills = state end
})

MainTab:CreateToggle({
    Title = "Skill [Z]",
    Description = "Tự động tung chiêu phím Z khi farm",
    Default = Config.Skills.Z,
    Callback = function(s) Config.Skills.Z = s end
})

MainTab:CreateToggle({
    Title = "Skill [X]",
    Description = "Tự động tung chiêu phím X khi farm",
    Default = Config.Skills.X,
    Callback = function(s) Config.Skills.X = s end
})

MainTab:CreateToggle({
    Title = "Skill [C]",
    Description = "Tự động tung chiêu phím C khi farm",
    Default = Config.Skills.C,
    Callback = function(s) Config.Skills.C = s end
})

MainTab:CreateToggle({
    Title = "Skill [V]",
    Description = "Tự động tung chiêu phím V khi farm",
    Default = Config.Skills.V,
    Callback = function(s) Config.Skills.V = s end
})

MainTab:CreateToggle({
    Title = "Skill [E]",
    Description = "Tự động tung chiêu phím E khi farm",
    Default = Config.Skills.E,
    Callback = function(s) Config.Skills.E = s end
})

MainTab:CreateToggle({
    Title = "Skill [R]",
    Description = "Tự động tung chiêu phím R khi farm",
    Default = Config.Skills.R,
    Callback = function(s) Config.Skills.R = s end
})

MainTab:CreateSlider({
    Title = "Thời gian nghỉ giữa các chiêu",
    Min = 0.1,
    Max = 3.0,
    Default = Config.SkillDelay,
    Decimals = 1,
    Suffix = "s",
    Callback = function(val) Config.SkillDelay = val end
})

MainTab:CreateSection("AUTO CÂU CÁ (MAIN)")

MainTab:CreateToggle({
    Title = "Auto Câu Cá",
    Description = "Tự động thả câu và kéo cá khi có cắn câu",
    Default = Config.AutoFish,
    Callback = function(state) Config.AutoFish = state end
})

MainTab:CreateDropdown({
    Title = "Chế độ kéo cần",
    Options = { "Fast / Instant Reel", "Legit / Normal" },
    Default = Config.FishingMode,
    Callback = function(selected) Config.FishingMode = selected end
})

-- ─────────────────────────────────────────────────────────────────────────
-- ⚙️ MISC TAB
-- ─────────────────────────────────────────────────────────────────────────
MiscTab:CreateSection("GIẢM LAG & TỐI ƯU HIỆU NĂNG")

MiscTab:CreateToggle({
    Title = "Giảm Lag Đồ Họa (FPS Booster)",
    Description = "Tắt bóng đổ, khử hiệu ứng hạt, hạ chi tiết vật liệu để tối đa FPS",
    Default = Config.FPSBooster,
    Callback = function(state)
        Config.FPSBooster = state
        if state then applyFPSBoost() end
    end
})

MiscTab:CreateToggle({
    Title = "Tắt Render 3D (Siêu Nhẹ Máy / Treo Đêm)",
    Description = "Dừng vẽ thế giới 3D giúp GPU về 0% khi cắm máy farm liên tục",
    Default = Config.Disable3DRender,
    Callback = function(state)
        Config.Disable3DRender = state
        RunService:Set3dRenderingEnabled(not state)
    end
})

MiscTab:CreateToggle({
    Title = "Anti-AFK (Chống Mất Kết Nối)",
    Description = "Ngăn Roblox kick sau 20 phút không hoạt động",
    Default = Config.AntiAFK,
    Callback = function(state) Config.AntiAFK = state end
})

MiscTab:CreateSection("DI CHUYỂN & NHÂN VẬT")

MiscTab:CreateSlider({
    Title = "Tốc Độ Di Chuyển (WalkSpeed)",
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

MiscTab:CreateSlider({
    Title = "Độ Cao Nhảy (JumpPower)",
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

MiscTab:CreateToggle({
    Title = "Infinite Jump (Nhảy Vô Hạn)",
    Description = "Cho phép nhảy liên tục giữa không trung",
    Default = Config.InfiniteJump,
    Callback = function(state) Config.InfiniteJump = state end
})

MiscTab:CreateToggle({
    Title = "Noclip Xuyên Tường",
    Description = "Đi xuyên qua mọi vật cản địa hình khi không farm",
    Default = Config.Noclip,
    Callback = function(state) Config.Noclip = state end
})

MiscTab:CreateSection("TIỆN ÍCH CÂU CÁ (MISC)")

MiscTab:CreateToggle({
    Title = "Auto Bỏ Cần Câu Vào Tay",
    Description = "Tự động lấy cần câu từ Balo cầm lên tay khi câu cá",
    Default = Config.AutoEquipRod,
    Callback = function(state) Config.AutoEquipRod = state end
})

MiscTab:CreateToggle({
    Title = "Auto Bán Cá Khi Đầy Rương",
    Description = "Tự động tương tác NPC bán cá khi túi đồ đầy",
    Default = Config.AutoSellFish,
    Callback = function(state) Config.AutoSellFish = state end
})

-- ─────────────────────────────────────────────────────────────────────────
-- 🛠️ SETTING TAB
-- ─────────────────────────────────────────────────────────────────────────
SettingTab:CreateSection("CẤU HÌNH GIAO DIỆN & HỆ THỐNG")

SettingTab:CreateKeybind({
    Title = "Phím Ẩn/Hiện Menu (Toggle UI)",
    Default = Enum.KeyCode.RightControl,
    Callback = function(key)
        Window:SetToggleKey(key)
    end
})

SettingTab:CreateDropdown({
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
        if colors[choice] then
            MhnaaUI:SetThemeColor("Accent", colors[choice])
        end
    end
})

SettingTab:CreateButton({
    Title = "Hủy Quest Hiện Tại (Force Cancel Quest)",
    Description = "Lập tức hủy bỏ nhiệm vụ đang nhận để giải phóng slot quest",
    Callback = function()
        local inputFunc = getInputFunction()
        local qFolder = LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Quests") and LocalPlayer.Data.Quests:FindFirstChild("Main")
        if inputFunc and qFolder and #qFolder:GetChildren() > 0 then
            local qName = qFolder:GetChildren()[1].Name
            inputFunc:InvokeServer("Quest", "Cancel", qName)
            MhnaaUI:Notify({ Title = "Quest System", Content = "Đã hủy quest: " .. qName, Duration = 3 })
        else
            MhnaaUI:Notify({ Title = "Quest System", Content = "Hiện không có quest nào!", Duration = 3 })
        end
    end
})

SettingTab:CreateButton({
    Title = "Teleport Về Đảo Chính (Legacy Island)",
    Description = "Dịch chuyển tức thì về đảo chính an toàn",
    Callback = function()
        teleportToIsland("Legacy Island")
    end
})

SettingTab:CreateButton({
    Title = "Đóng & Dừng Hoàn Toàn Hub",
    Description = "Dừng tất cả tiến trình farm, bay tween và gỡ giao diện",
    Callback = function()
        if _G.MhnaaHub_Stop then
            _G.MhnaaHub_Stop()
        end
        Window:Destroy()
        RunService:Set3dRenderingEnabled(true)
    end
})

SettingTab:CreateSection("THÔNG TIN NGƯỜI CHƠI (LIVE STATS)")

local statInfoLabel = SettingTab:CreateLabel({
    Title = "Đang tải dữ liệu người chơi..."
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
                
                statInfoLabel:SetText(string.format("Lv: %s | Points: %s\nĐảo hiện tại: %s\nQuest: %s", tostring(lvl), tostring(pts), curIsland, qName))
            end
        end)
        task.wait(1)
    end
end)

MhnaaUI:Notify({
    Title = "Mhnaa Hub [PRO]",
    Content = "Đã khởi chạy thành công! Nhấn [RightControl] để ẩn/hiện.",
    Duration = 4
})
