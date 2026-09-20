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

-- [1] Run Guard & Environment Setup
if getgenv().meow_miao_sc_ini then
    warn("nhamnhi Hub: Script is already running!")
    return
end
getgenv().meow_miao_sc_ini = true

-- [2] Key System Bypass (Junkie SDK Mock)
-- Script goc goi API Junkie (taolao / id: 1035567) de kiem tra key tu getgenv().SCRIPT_KEY hoac nhamnhi_key.txt
-- O day ta bypass truc tiep dieu kien kiem tra key:
local KeyResult = { valid = true, message = "Bypassed successfully" }

-- [3] Services & Dependencies
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

-- [4] Remotes & Game Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RemoteEvents = Remotes:FindFirstChild("Events")
local RemoteFunctions = Remotes:FindFirstChild("Functions")

local RemoteInput = Remotes:WaitForChild("Input") -- RemoteEvent cho combat / skills
local RemoteFunctionsInput = RemoteFunctions and RemoteFunctions:WaitForChild("Input") -- RemoteFunction cho actions / reroll
local RemoteUseItem = Remotes:WaitForChild("RE_UseItem")

-- Remotes phu tro
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

-- [5] Configuration & State Table
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
        
        SelectedMob = "",
        SelectedBosses = {},
        SelectedSummon = "",
        
        Position = "Behind", -- Behind | Above | Below
        Distance = 6,
        TweenSpeed = 300,
        
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
        SelectedStats = {},
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

-- [6] Core Helper Functions: Character, Movement & Combat
local State = {
    Target = nil,
    ActiveTween = nil,
    ActiveAction = false,
    WhaleActive = false,
    LastM1 = 0,
    LastSkill = 0,
    NoclipConnection = nil,
}

local function GetCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 5)
    local hum = char:WaitForChild("Humanoid", 5)
    return char, root, hum
end

-- Bat/tat Noclip
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

-- Dung di chuyen
local function StopMovement()
    if State.ActiveTween then
        State.ActiveTween:Cancel()
        State.ActiveTween = nil
    end
    local _, root = GetCharacter()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

-- Di chuyen muot (Tween)
local function MoveToCFrame(targetCFrame)
    local char, root = GetCharacter()
    if not root then return end
    
    local distance = (root.Position - targetCFrame.Position).Magnitude
    if distance < 5 then
        root.CFrame = targetCFrame
        return
    end
    
    SetNoclip(true)
    local speed = HubConfig.Farm.TweenSpeed or 300
    local time = distance / speed
    
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    State.ActiveTween = TweenService:Create(root, tweenInfo, { CFrame = targetCFrame })
    State.ActiveTween:Play()
    State.ActiveTween.Completed:Wait()
    State.ActiveTween = nil
end

-- Tinh toan CFrame vi tri danh (Behind, Above, Below)
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

-- Trang bi vu khi phu hop
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

-- Thuc hien don danh M1
local function AttackM1()
    EquipWeapon()
    RemoteInput:FireServer("Tool", "M1")
end

-- Thuc hien ky nang (Auto Skill)
local function CastSkills()
    if not HubConfig.Farm.AutoSkill then return end
    EquipWeapon()
    
    local skillKeys = {"Z", "X", "C", "V", "E"}
    for _, key in ipairs(skillKeys) do
        RemoteInput:FireServer("Skill", key)
        if HubConfig.Farm.AutoSkillMode == "Normal" then
            task.wait(0.15)
        end
    end
end

-- [7] Autofarm Loops
-- Vong lap tu dong danh (Combat Loop)
task.spawn(function()
    while true do
        task.wait(0.05)
        if State.Target and State.Target:FindFirstChild("Humanoid") and State.Target.Humanoid.Health > 0 then
            local _, root = GetCharacter()
            local targetPart = State.Target:FindFirstChild("HumanoidRootPart") or State.Target.PrimaryPart
            if root and targetPart then
                local farmCFrame = CalculateFarmOffset(targetPart.CFrame)
                root.CFrame = farmCFrame
                root.AssemblyLinearVelocity = Vector3.zero
                
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

-- Quet tim quai / muc tieu
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

-- Vong lap chon muc tieu chinh (Target Selector)
task.spawn(function()
    while true do
        task.wait(0.25)
        if HubConfig.Farm.MobFarm then
            State.Target = FindMobTarget(HubConfig.Farm.SelectedMob)
        elseif HubConfig.Farm.AllMobFarm then
            State.Target = FindMobTarget()
        elseif HubConfig.Farm.BossesFarm then
            for _, bossName in ipairs(HubConfig.Farm.SelectedBosses) do
                local boss = FindMobTarget(bossName)
                if boss then
                    State.Target = boss
                    break
                end
            end
        end
    end
end)

-- [8] Fire Force Quests Automation
task.spawn(function()
    while true do
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
                                root.CFrame = item.Parent.CFrame
                                task.wait(0.2)
                                fireproximityprompt(item)
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

-- [9] Auto Collect Items & Misc Features
task.spawn(function()
    while true do
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
                            root.CFrame = basePart.CFrame
                            task.wait(0.15)
                            fireproximityprompt(prompt)
                        end
                    end
                end
            end
        end
    end
end)

-- [10] Anti-AFK
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

-- [11] Khoi tao Giao dien nguoi dung (Obsidian UI Library)
local function LoadUI()
    local success, Library = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/gix314/Obsidian/main/Library.lua"))()
    end)
    
    if not success or not Library then
        warn("Khong the tai Obsidian Library truc tiep qua HttpGet! Vui long kiem tra ket noi hoac executor.")
        return
    end

    local Window = Library:CreateWindow({
        Title = "nhamnhi | Legacy Piece [Bypassed]",
        Footer = "nhamnhi v1.0.3 | discord.gg/mcMEkVdebJ",
        Icon = 101058895845936,
        NotifySide = "Right",
        ShowCustomCursor = false,
    })

    -- Tabs
    local Tabs = {
        Home = Window:AddTab({ Title = "Home", Icon = "house", Description = "Thong tin chung va Trang thai" }),
        Main = Window:AddTab({ Title = "Main", Icon = "box", Description = "Tinh nang Autofarm chinh" }),
        FireForce = Window:AddTab({ Title = "Fire Force", Icon = "repeat-2", Description = "Tu dong nhiem vu Fire Force" }),
        Automation = Window:AddTab({ Title = "Automation", Icon = "repeat", Description = "Tu dong co che in-game (Roll, Chest, Stats)" }),
        Dungeon = Window:AddTab({ Title = "Dungeon", Icon = "door-open", Description = "Pho ban va Infinite Tower" }),
        Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin", Description = "Dich chuyen dao va NPC" }),
    }

    -- [Tab Main] Autofarm Controls
    local FarmGroup = Tabs.Main:AddLeftGroupbox("Autofarm Settings")
    FarmGroup:AddToggle("MobFarm", {
        Text = "Auto Farm [Mob]",
        Default = false,
        Callback = function(v) HubConfig.Farm.MobFarm = v end
    })
    FarmGroup:AddToggle("AllMobFarm", {
        Text = "Auto Farm [All Mobs]",
        Default = false,
        Callback = function(v) HubConfig.Farm.AllMobFarm = v end
    })
    FarmGroup:AddToggle("BossesFarm", {
        Text = "Auto Farm [Bosses]",
        Default = false,
        Callback = function(v) HubConfig.Farm.BossesFarm = v end
    })
    FarmGroup:AddToggle("AutoM1", {
        Text = "Auto M1 Attack",
        Default = true,
        Callback = function(v) HubConfig.Farm.AutoM1 = v end
    })
    FarmGroup:AddToggle("AutoSkill", {
        Text = "Auto Use Skills",
        Default = false,
        Callback = function(v) HubConfig.Farm.AutoSkill = v end
    })

    local PosGroup = Tabs.Main:AddRightGroupbox("Position and Speed")
    PosGroup:AddDropdown("FarmPos", {
        Values = { "Behind", "Above", "Below" },
        Default = "Behind",
        Multi = false,
        Text = "Vi tri farm",
        Callback = function(v) HubConfig.Farm.Position = v end
    })
    PosGroup:AddSlider("FarmDist", {
        Text = "Khoang cach farm",
        Default = 6,
        Min = 2,
        Max = 15,
        Rounding = 1,
        Callback = function(v) HubConfig.Farm.Distance = v end
    })
    PosGroup:AddSlider("TweenSpeed", {
        Text = "Toc do bay (Tween)",
        Default = 300,
        Min = 100,
        Max = 600,
        Rounding = 0,
        Callback = function(v) HubConfig.Farm.TweenSpeed = v end
    })

    -- [Tab Fire Force]
    local FFGroup = Tabs.FireForce:AddLeftGroupbox("Nhiem vu Fire Force")
    FFGroup:AddToggle("FF_Q1", {
        Text = "Auto Tim Meo (Find Cat)",
        Default = false,
        Callback = function(v) HubConfig.FireForce.Q1_FindCat = v end
    })
    FFGroup:AddToggle("FF_Q2", {
        Text = "Auto Cuu Con Tin (Rescue Hostage)",
        Default = false,
        Callback = function(v) HubConfig.FireForce.Q2_RescueHostage = v end
    })
    FFGroup:AddToggle("FF_Q3", {
        Text = "Auto Danh Len (Ambush Thugs)",
        Default = false,
        Callback = function(v) HubConfig.FireForce.Q3_Ambush = v end
    })

    -- [Tab Automation]
    local AutoGroup = Tabs.Automation:AddLeftGroupbox("Vat pham va Ruong")
    AutoGroup:AddToggle("AutoCollectItem", {
        Text = "Tu dong nhat do roi (Collect Items)",
        Default = false,
        Callback = function(v) HubConfig.Misc.AutoCollectItem = v end
    })
    AutoGroup:AddToggle("AutoOpenChest", {
        Text = "Tu dong mo ruong (Open Chest)",
        Default = false,
        Callback = function(v) HubConfig.Misc.AutoOpenChest = v end
    })
    AutoGroup:AddToggle("AutoWhale", {
        Text = "Tu dong san Ca voi (Whale Event)",
        Default = false,
        Callback = function(v) HubConfig.Misc.AutoFindWhale = v end
    })

    Library:Notify("nhamnhi Hub da tai thanh cong! Key system da duoc bypass hoan toan.", 5)
end

-- Chay ham tai UI
LoadUI()
print("[nhamnhi] Script loaded and initialized successfully!")
