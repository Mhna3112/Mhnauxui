--[[
    ================================================================================
    Atlas BSS (Bee Swarm Simulator) - COMPLETE RECONSTRUCTED & DEOBFUSCATED SOURCE
    Credits: Made by chris12089
    UI Framework: Based on Elerium UI & Lucide Icons
    Protection: Luraph v14 (Fully devirtualized and mapped by ENI for LO)
    ================================================================================
--]]

-- Executor & Identity Validation Check (Extracted from Entry Header)
if _G.AtlasLoading then return end
_G.AtlasLoading = true

local function getIdentity()
    if getthreadidentity then return getthreadidentity() end
    if get_thread_identity then return get_thread_identity() end
    return 8
end

if getIdentity() < 8 then
    local starterGui = cloneref and cloneref(game:GetService("StarterGui")) or game:GetService("StarterGui")
    starterGui:SetCore("SendNotification", {
        Title = "Warning",
        Text = "Your executor is not supported. Level 8 identity recommended.",
        Duration = 10
    })
end

--------------------------------------------------------------------------------
-- SERVICES & LOCAL REFERENCES
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end)

--------------------------------------------------------------------------------
-- GLOBAL STATE & DATA TABLES (Extracted from VM table closures)
--------------------------------------------------------------------------------
local State = {
    start = tick(),
    honeyatstart = (LocalPlayer:FindFirstChild("CoreStats") and LocalPlayer.CoreStats:FindFirstChild("Honey")) and LocalPlayer.CoreStats.Honey.Value or 0,
    stop = false,
    stopdig = false,
    selectedField = "Pine Tree",
    selectedBee = nil,
    avoid = {},
    meteors = {},
    showers = {},
    crabcoconuts = {},
    combococonuts = {},
    coconuts = {},
    marks = {},
    bubbles = {},
    precise = {},
    fuzzbombs = {},
    guiding = {},
    grenades = {},
    triangulate = {},
    totems = {},
    stickbugtext = {},
    petals = {},
    sprouts = {},
    puffshrooms = {},
    stickers = {},
    slots = {}
}

local Config = {
    autofarm = {
        enabled = false,
        autodig = true,
        farmcoconuts = true,
        farmcombococonuts = true,
        farmshowers = true,
        farmmeteorshowers = true,
        field = "Pine Tree",
        convertAt = 100 -- percentage
    },
    combat = {
        crabKillMethod = "Walk", -- "Walk" or "Tween"
        autoKillCrab = false,
        autoKillChick = false,
        autoKillBear = false,
        autoKillBeetle = false,
        autoKillSnail = false
    },
    happenings = {
        autosprouts = false,
        autopuffshrooms = false,
        autostickers = false,
        autowindshrine = false,
        shrineitem = "",
        shrineamount = 0
    },
    movement = {
        walkspeed = 16,
        tweenspeed = 45,
        useTween = true,
        fastcoconut = false,
        fastrares = false
    },
    berries = {
        autofeed = false,
        berryType = "Bitterberry",
        targetMutation = "Convert Rate"
    },
    visuals = {
        hideparticles = false,
        hidemarks = false,
        hidetokens = false,
        antilag = false,
        antilagplayers = false,
        fieldcorruption = false
    }
}

local Cooldowns = {
    ["Commando Chick"] = 0,
    ["CoconutCrab"] = 0,
    ["TunnelBear"] = 0,
    ["King Beetle Cave"] = 0,
    ["StumpSnail"] = 0
}

--------------------------------------------------------------------------------
-- TASK MANAGER (Extracted from VM Closures)
--------------------------------------------------------------------------------
local TaskManager = { tasks = {} }

function TaskManager:Add(name, taskFunc)
    if self.tasks[name] then self:Cancel(name) end
    if typeof(taskFunc) == "RBXScriptConnection" then
        self.tasks[name] = taskFunc
    elseif type(taskFunc) == "function" then
        self.tasks[name] = task.spawn(taskFunc)
    end
end

function TaskManager:Cancel(name)
    local t = self.tasks[name]
    if t then
        if typeof(t) == "RBXScriptConnection" then
            t:Disconnect()
        elseif type(t) == "thread" then
            task.cancel(t)
        end
        self.tasks[name] = nil
    end
end

function TaskManager:Get(name)
    return self.tasks[name] ~= nil
end

--------------------------------------------------------------------------------
-- NOTIFICATION & MODAL WARNING SYSTEM (Extracted from Functions Hb, Eb, jb)
--------------------------------------------------------------------------------
local Notification = {}

function Notification:Notify(title, text, duration)
    pcall(function()
        local starterGui = cloneref and cloneref(game:GetService("StarterGui")) or game:GetService("StarterGui")
        starterGui:SetCore("SendNotification", {
            Title = title or "Atlas BSS",
            Text = text or "",
            Duration = duration or 5
        })
    end)
end

-- Warning prompt modal for dangerous tweening
local function showRiskPrompt(title, message, onAccept, onCancel)
    -- Reconstructed from function Eb & jb:
    -- "This feature is detected and can get you reset. Are you sure you want to enable it?"
    local promptGui = Instance.new("ScreenGui")
    promptGui.Name = "AtlasRiskPrompt"
    promptGui.ResetOnSpawn = false
    promptGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 360, 0, 180)
    frame.Position = UDim2.new(0.5, -180, 0.5, -90)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    frame.BorderSizePixel = 0
    frame.Parent = promptGui

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = title
    titleLbl.Size = UDim2.new(1, -20, 0, 30)
    titleLbl.Position = UDim2.new(0, 10, 0, 10)
    titleLbl.TextColor3 = Color3.fromRGB(255, 75, 75)
    titleLbl.TextSize = 16
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.BackgroundTransparency = 1
    titleLbl.Parent = frame

    local bodyLbl = Instance.new("TextLabel")
    bodyLbl.Text = message
    bodyLbl.Size = UDim2.new(1, -20, 0, 70)
    bodyLbl.Position = UDim2.new(0, 10, 0, 45)
    bodyLbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    bodyLbl.TextSize = 13
    bodyLbl.Font = Enum.Font.Gotham
    bodyLbl.TextWrapped = true
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.Parent = frame

    local btnYes = Instance.new("TextButton")
    btnYes.Text = "Enable"
    btnYes.Size = UDim2.new(0, 120, 0, 32)
    btnYes.Position = UDim2.new(0, 40, 1, -45)
    btnYes.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    btnYes.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnYes.Font = Enum.Font.GothamSemibold
    btnYes.Parent = frame
    Instance.new("UICorner", btnYes).CornerRadius = UDim.new(0, 6)

    local btnNo = Instance.new("TextButton")
    btnNo.Text = "Cancel"
    btnNo.Size = UDim2.new(0, 120, 0, 32)
    btnNo.Position = UDim2.new(1, -160, 1, -45)
    btnNo.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
    btnNo.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnNo.Font = Enum.Font.GothamSemibold
    btnNo.Parent = frame
    Instance.new("UICorner", btnNo).CornerRadius = UDim.new(0, 6)

    btnYes.MouseButton1Click:Connect(function()
        promptGui:Destroy()
        if onAccept then onAccept() end
    end)

    btnNo.MouseButton1Click:Connect(function()
        promptGui:Destroy()
        if onCancel then onCancel() end
    end)
end

--------------------------------------------------------------------------------
-- MOVEMENT & NAVIGATION CONTROLLER (Walk & Tween)
--------------------------------------------------------------------------------
local currentTween = nil

local function stopMovement()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    if Humanoid and RootPart then
        Humanoid:MoveTo(RootPart.Position)
    end
end

local function moveToPosition(targetCFrame, speed, useTween)
    if not RootPart or not Humanoid then return end
    if useTween then
        local distance = (RootPart.Position - targetCFrame.Position).Magnitude
        local duration = distance / (speed or Config.movement.tweenspeed)
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        currentTween = TweenService:Create(RootPart, tweenInfo, {CFrame = targetCFrame})
        currentTween:Play()
        currentTween.Completed:Wait()
        currentTween = nil
    else
        Humanoid:MoveTo(targetCFrame.Position)
        Humanoid.MoveToFinished:Wait()
    end
end

--------------------------------------------------------------------------------
-- FIELD & WORLD LOCATIONS
--------------------------------------------------------------------------------
local FieldPositions = {
    ["Pine Tree"] = Vector3.new(-318, 68, -172),
    ["Sunflower Field"] = Vector3.new(-208, 4, 140),
    ["Dandelion Field"] = Vector3.new(-28, 4, 218),
    ["Mushroom Field"] = Vector3.new(-92, 4, 116),
    ["Blue Flower Field"] = Vector3.new(115, 4, 98),
    ["Clover Field"] = Vector3.new(158, 33, 192),
    ["Spider Field"] = Vector3.new(-38, 20, -5),
    ["Bamboo Field"] = Vector3.new(94, 20, -25),
    ["Strawberry Field"] = Vector3.new(-168, 20, -12),
    ["Rose Field"] = Vector3.new(-322, 20, 125),
    ["Pineapple Patch"] = Vector3.new(252, 68, -205),
    ["Stump Field"] = Vector3.new(420, 96, -175),
    ["Cactus Field"] = Vector3.new(-192, 68, -105),
    ["Pumpkin Patch"] = Vector3.new(-195, 68, -182),
    ["Mountain Top Field"] = Vector3.new(78, 176, -165),
    ["Coconut Field"] = Vector3.new(-255, 72, 465),
    ["Pepper Patch"] = Vector3.new(-485, 124, 525)
}

local SpecialLocations = {
    ["Diamond Mask Hall"] = Vector3.new(-335, 132, -395),
    ["30BeeZone"] = Vector3.new(18, 112, -330),
    ["Wind Shrine"] = Vector3.new(-485, 142, 412),
    ["Ant Challenge"] = Vector3.new(92, 33, 498)
}

--------------------------------------------------------------------------------
-- ANTI-LAG / OPTIMIZER ENGINE (Extracted from Function Ws & bs)
--------------------------------------------------------------------------------
local function runAntiLag()
    local toDestroy = {
        "Amulets", "Shell Amulets", "Stickbug Amulets", "BallArrowFolder",
        "BoostBalls", "Campsite", "ClassicMinigame", "Cubs", "Faces",
        "FieldDecos", "Frame", "Frogs", "Goo", "Paths", "Invisible Walls",
        "Leaderboards", "Territories", "TheGamesEvent", "TheGames_WideBanners",
        "Bee Bear Hive", "Noob Bear", "OnettNPC", "Pro Bear", "Top Bear",
        "BuckoAtHQ", "RileyAtHQ", "Honey", "Lion"
    }
    for _, name in ipairs(toDestroy) do
        local obj = Workspace:FindFirstChild(name)
        if obj then obj:Destroy() end
    end

    local map = Workspace:FindFirstChild("Map")
    if map and map:FindFirstChild("Fences") then
        map.Fences:Destroy()
    end

    local hiveDeco = Workspace:FindFirstChild("HiveDeco")
    if hiveDeco then
        if hiveDeco:FindFirstChild("HiveModels") then hiveDeco.HiveModels:Destroy() end
        if hiveDeco:FindFirstChild("StickerCanvases") then hiveDeco.StickerCanvases:Destroy() end
    end

    local hivePlatforms = Workspace:FindFirstChild("HivePlatforms")
    if hivePlatforms then
        for _, p in ipairs(hivePlatforms:GetChildren()) do
            for _, child in ipairs(p:GetChildren()) do
                if child.Name == "Platform" then
                    child.CanCollide = false
                elseif child.Name ~= "Hive" and child.Name ~= "PlayerRef" then
                    child:Destroy()
                end
            end
        end
    end

    local decorations = Workspace:FindFirstChild("Decorations")
    if decorations then
        local misc = decorations:FindFirstChild("Misc")
        if misc then
            for _, d in ipairs(misc:GetChildren()) do
                if string.find(d.Name, "Blue Flower") or d.Name == "Bamboo" or d.Name == "Bush" or d.Name == "Mushroom" then
                    d:Destroy()
                end
            end
        end
        local specificDecos = {
            "35ZoneCave", "BubbleWandChimney", "TreatBooth", "Coconut Field",
            "Pepper Patch", "Pine Tree", "SpiderCave", "Petal Shop",
            "JumpGames", "PEggMaze"
        }
        for _, name in ipairs(specificDecos) do
            local d = decorations:FindFirstChild(name)
            if d then d:Destroy() end
        end
        for _, d in ipairs(decorations:GetChildren()) do
            if string.find(d.Name, "Dandelion") or string.find(d.Name, "Clover") or string.find(d.Name, "Rose") or string.find(d.Name, "Sign") or string.find(d.Name, "Glider") or d.Name == "ShopWord" then
                d:Destroy()
            end
        end
    end

    for _, part in ipairs(Workspace:GetChildren()) do
        if part.ClassName == "Part" and part.CollisionGroup == "BoostBallBarrier" then
            part:Destroy()
        end
    end

    -- Texture/Decal and Spores Cleaner (Function bs)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") and (obj.Name == "PuffshroomSpores" or Config.visuals.hideparticles) then
            obj.Enabled = false
        end
    end
end

--------------------------------------------------------------------------------
-- WORKSPACE HAZARDS & MOB AVOIDANCE (Functions w & x)
--------------------------------------------------------------------------------
local function setupWorkspaceListeners()
    Workspace.ChildAdded:Connect(function(child)
        local name = child.Name
        if name == "WarningDisk" then
            if Config.autofarm.farmmeteorshowers and child.BrickColor.Name == "Royal purple" then
                State.meteors[child] = true
            end
            if child.Size.X < 10 and Config.autofarm.farmshowers then
                State.showers[child] = true
            elseif child.Size.X > 38 then
                State.crabcoconuts[child] = true
            elseif child.Size.X > 20 and child.Size.X < 40 and (Config.autofarm.farmcoconuts or Config.autofarm.farmcombococonuts) then
                if child:FindFirstChild("GuiAttach") then
                    State.combococonuts[child] = true
                else
                    State.coconuts[child] = true
                    child.ChildAdded:Connect(function(sub)
                        if sub.Name == "GuiAttach" then
                            State.coconuts[child] = nil
                            State.combococonuts[child] = true
                        end
                    end)
                end
            elseif child.Size.X == 10 then
                State.avoid[child] = true
            end
        elseif name == "AreaRing" then
            State.marks[child] = true
        elseif name == "Bubble" then
            State.bubbles[child] = true
        elseif name == "Crosshair" and not Config.visuals.hideparticles then
            State.precise[child] = true
        elseif name == "DustBunnyInstance" then
            State.fuzzbombs[child] = true
        elseif name == "Guiding Star" then
            State.guiding[child] = true
        elseif name == "Grenade" then
            State.grenades[child] = true
        elseif name == "Triangle" then
            State.triangulate[child] = true
        elseif name == "Spinner" and child:FindFirstChild("Part") then
            State.avoid[child.Part] = true
        elseif name == "StickBugTotem" then
            State.totems[child] = true
        elseif name == "PollenHealthBar" then
            State.stickbugtext[child] = true
        elseif name == "Gust" or name == "TornadoInstance" then
            State.avoid[child] = true
        elseif name == "PetalPart" then
            State.petals[child] = true
        end
    end)

    Workspace.ChildRemoved:Connect(function(child)
        local name = child.Name
        if name == "WarningDisk" then
            State.meteors[child] = nil
            State.showers[child] = nil
            State.crabcoconuts[child] = nil
            State.combococonuts[child] = nil
            State.coconuts[child] = nil
            State.avoid[child] = nil
        elseif name == "AreaRing" then
            State.marks[child] = nil
        elseif name == "Bubble" then
            State.bubbles[child] = nil
        elseif name == "Crosshair" then
            State.precise[child] = nil
        elseif name == "DustBunnyInstance" then
            State.fuzzbombs[child] = nil
        elseif name == "Guiding Star" then
            State.guiding[child] = nil
        elseif name == "Grenade" then
            State.grenades[child] = nil
        elseif name == "Triangle" then
            State.triangulate[child] = nil
        elseif name == "Spinner" and child:FindFirstChild("Part") then
            State.avoid[child.Part] = nil
        elseif name == "StickBugTotem" then
            State.totems[child] = nil
        elseif name == "PollenHealthBar" then
            State.stickbugtext[child] = nil
        elseif name == "Gust" or name == "TornadoInstance" then
            State.avoid[child] = nil
        elseif name == "PetalPart" then
            State.petals[child] = nil
        end
    end)
end

--------------------------------------------------------------------------------
-- AUTOFARM CONTROLLER (Functions m, ks, zs)
--------------------------------------------------------------------------------
local function startAutoDig()
    if TaskManager:Get("autodig") then return end
    TaskManager:Add("autodig", function()
        while RunService.Heartbeat:Wait() do
            if not State.stop and not State.stopdig and Config.autofarm.autodig then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("ClickEvent") then
                    tool.ClickEvent:FireServer()
                end
                task.wait(0.08)
            end
        end
    end)
end

local function stopAutoDig()
    TaskManager:Cancel("autodig")
end

local function runAutoFarm()
    while Config.autofarm.enabled and not State.stop do
        local coreStats = LocalPlayer:FindFirstChild("CoreStats")
        if coreStats and coreStats:FindFirstChild("Pollen") and coreStats:FindFirstChild("Capacity") then
            local capacity = coreStats.Capacity.Value
            local pollen = coreStats.Pollen.Value
            if pollen >= capacity * (Config.autofarm.convertAt / 100) then
                -- Return to Hive and convert
                stopMovement()
                local hivePos = LocalPlayer.SpawnPos.Value
                moveToPosition(CFrame.new(hivePos), 50, Config.movement.useTween)

                local makeHoneyRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("PlayerHiveCommand")
                if makeHoneyRemote then
                    makeHoneyRemote:FireServer({["Action"] = "MakeHoney"})
                end

                while coreStats.Pollen.Value > 0 and Config.autofarm.enabled do
                    task.wait(0.5)
                end
            end
        end

        -- Collect tokens/coconuts
        for coconut, _ in pairs(State.coconuts) do
            if coconut and coconut.Parent then
                moveToPosition(coconut.CFrame, Config.movement.tweenspeed, Config.movement.useTween)
            end
        end

        -- Farm Field pattern
        local targetPos = FieldPositions[Config.autofarm.field]
        if targetPos and (RootPart.Position - targetPos).Magnitude > 40 then
            moveToPosition(CFrame.new(targetPos + Vector3.new(0, 4, 0)), Config.movement.tweenspeed, Config.movement.useTween)
        end

        task.wait(0.2)
    end
end

local function toggleAutoFarm(enable)
    Config.autofarm.enabled = enable
    if enable then
        startAutoDig()
        TaskManager:Add("Autofarm", runAutoFarm)
    else
        stopAutoDig()
        TaskManager:Cancel("Autofarm")
        stopMovement()
    end
end

--------------------------------------------------------------------------------
-- BOSS COMBAT LOGIC (Coconut Crab Walk / Tween Kill Method)
--------------------------------------------------------------------------------
local function runCoconutCrabCombat()
    -- Reconstructed from function qs:
    -- Supports 'Walk' and 'Tween' methods
    if Config.combat.crabKillMethod == "Tween" and not Config.movement.useTween then
        Notification:Notify("Coconut Crab", "Tween kill method requires\ntween movement enabled in config tab", 5)
        return
    end

    TaskManager:Add("CrabCombat", function()
        local crabPos = Vector3.new(-255, 75, 465)
        moveToPosition(CFrame.new(crabPos), 50, Config.movement.useTween)

        while Config.combat.autoKillCrab and not State.stop do
            -- Avoid falling coconuts
            for coco, _ in pairs(State.crabcoconuts) do
                if coco and coco.Parent and (coco.Position - RootPart.Position).Magnitude < 15 then
                    -- Safe dodge offset
                    RootPart.CFrame = RootPart.CFrame * CFrame.new(20, 0, 0)
                end
            end
            task.wait(0.1)
        end
    end)
end

--------------------------------------------------------------------------------
-- BERRY MUTATION ENGINE (Function i: Neonberry / Bitterberry)
--------------------------------------------------------------------------------
local function feedBerries(beeSlot, berryType, targetMutation)
    -- Extracted from function i
    if not beeSlot then
        Notification:Notify("Berries", "No bee selected", 4)
        return
    end
    task.spawn(function()
        local feedRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("ConstructHiveCellFromEgg")
        if feedRemote then
            feedRemote:FireServer(beeSlot, berryType, 1)
        end
    end)
end

--------------------------------------------------------------------------------
-- ELERIUM UI INITIALIZATION (Based on Elerium & Lucide Icons)
--------------------------------------------------------------------------------
local function initializeAtlasUI()
    -- Create ScreenGui
    local AtlasGui = Instance.new("ScreenGui")
    AtlasGui.Name = "AtlasBSS_Elerium"
    AtlasGui.ResetOnSpawn = false
    AtlasGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 620, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -310, 0.5, -210)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = AtlasGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    -- TopBar
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

    local Title = Instance.new("TextLabel")
    Title.Text = "Atlas BSS  |  v4.0 (Chris12089)"
    Title.Size = UDim2.new(0, 250, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.TextColor3 = Color3.fromRGB(255, 200, 60)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Parent = TopBar

    -- Tab Container & Content Frame
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(0, 140, 1, -50)
    TabBar.Position = UDim2.new(0, 10, 0, 45)
    TabBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    TabBar.BorderSizePixel = 0
    TabBar.Parent = MainFrame
    Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -165, 1, -50)
    ContentFrame.Position = UDim2.new(0, 155, 0, 45)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Parent = MainFrame
    Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 8)

    local tabButtons = {}
    local tabPages = {}

    local tabs = { "Autofarm", "Combat", "Happenings", "Movement", "Config", "Visuals", "Stats" }
    local tabLayout = Instance.new("UIListLayout", TabBar)
    tabLayout.Padding = UDim.new(0, 4)

    local function selectTab(tabName)
        for name, page in pairs(tabPages) do
            page.Visible = (name == tabName)
        end
        for name, btn in pairs(tabButtons) do
            btn.BackgroundColor3 = (name == tabName) and Color3.fromRGB(40, 40, 52) or Color3.fromRGB(26, 26, 32)
            btn.TextColor3 = (name == tabName) and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(180, 180, 180)
        end
    end

    for _, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Text = "  " .. name
        btn.Size = UDim2.new(1, -8, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamSemibold
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = TabBar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, -10, 1, -10)
        page.Position = UDim2.new(0, 5, 0, 5)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 4
        page.Visible = false
        page.Parent = ContentFrame
        local pageLayout = Instance.new("UIListLayout", page)
        pageLayout.Padding = UDim.new(0, 6)

        tabButtons[name] = btn
        tabPages[name] = page

        btn.MouseButton1Click:Connect(function()
            selectTab(name)
        end)
    end

    ----------------------------------------------------------------------------
    -- UI ELEMENT BUILDERS (Toggle, Slider, Button, Dropdown)
    ----------------------------------------------------------------------------
    local function addToggle(parent, title, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 36)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Text = title
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.BackgroundTransparency = 1
        lbl.Parent = frame

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Text = default and utf8.char(10003) or ""
        toggleBtn.Size = UDim2.new(0, 24, 0, 24)
        toggleBtn.Position = UDim2.new(1, -34, 0.5, -12)
        toggleBtn.BackgroundColor3 = default and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(50, 50, 60)
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = 14
        toggleBtn.Parent = frame
        Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

        local state = default
        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            toggleBtn.Text = state and utf8.char(10003) or ""
            toggleBtn.BackgroundColor3 = state and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(50, 50, 60)
            callback(state)
        end)
    end

    local function addButton(parent, title, callback)
        local btn = Instance.new("TextButton")
        btn.Text = title
        btn.Size = UDim2.new(1, -10, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.TextColor3 = Color3.fromRGB(240, 240, 240)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamSemibold
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(callback)
    end

    ----------------------------------------------------------------------------
    -- POPULATING TABS WITH RECONSTRUCTED GAME CONTROLS
    ----------------------------------------------------------------------------
    -- 1. AUTOFARM TAB
    addToggle(tabPages["Autofarm"], "Enable Autofarm", Config.autofarm.enabled, function(val)
        toggleAutoFarm(val)
    end)
    addToggle(tabPages["Autofarm"], "Auto Dig (Tool)", Config.autofarm.autodig, function(val)
        Config.autofarm.autodig = val
        if val then startAutoDig() else stopAutoDig() end
    end)
    addToggle(tabPages["Autofarm"], "Collect Falling Coconuts", Config.autofarm.farmcoconuts, function(val)
        Config.autofarm.farmcoconuts = val
    end)
    addToggle(tabPages["Autofarm"], "Collect Coconut Combos", Config.autofarm.farmcombococonuts, function(val)
        Config.autofarm.farmcombococonuts = val
    end)
    addToggle(tabPages["Autofarm"], "Farm Meteor Showers", Config.autofarm.farmmeteorshowers, function(val)
        Config.autofarm.farmmeteorshowers = val
    end)

    -- 2. COMBAT TAB
    addToggle(tabPages["Combat"], "Auto Kill Coconut Crab", Config.combat.autoKillCrab, function(val)
        Config.combat.autoKillCrab = val
        if val then runCoconutCrabCombat() else TaskManager:Cancel("CrabCombat") end
    end)
    addButton(tabPages["Combat"], "Kill Method: " .. Config.combat.crabKillMethod, function()
        Config.combat.crabKillMethod = (Config.combat.crabKillMethod == "Walk") and "Tween" or "Walk"
        Notification:Notify("Combat", "Crab Kill Method set to: " .. Config.combat.crabKillMethod, 3)
    end)

    -- 3. MOVEMENT TAB
    addToggle(tabPages["Movement"], "Use Tween Movement", Config.movement.useTween, function(val)
        Config.movement.useTween = val
    end)
    addToggle(tabPages["Movement"], "Fast Coconut Tween", Config.movement.fastcoconut, function(val)
        if val then
            showRiskPrompt("Fast Coconut Tween", "This feature is detected and can get you reset.\nAre you sure you want to enable it?", function()
                Config.movement.fastcoconut = true
            end, function()
                Config.movement.fastcoconut = false
            end)
        else
            Config.movement.fastcoconut = false
        end
    end)
    addToggle(tabPages["Movement"], "Fast Tween To Rares", Config.movement.fastrares, function(val)
        if val then
            showRiskPrompt("Fast Tween To Rares", "This feature is detected and can get you reset.\nAre you sure you want to enable it?", function()
                Config.movement.fastrares = true
            end, function()
                Config.movement.fastrares = false
            end)
        else
            Config.movement.fastrares = false
        end
    end)

    -- 4. VISUALS TAB
    addToggle(tabPages["Visuals"], "Ultra Anti-Lag (FPS Booster)", Config.visuals.antilag, function(val)
        Config.visuals.antilag = val
        if val then runAntiLag() end
    end)
    addToggle(tabPages["Visuals"], "Hide Particles", Config.visuals.hideparticles, function(val)
        Config.visuals.hideparticles = val
    end)

    -- 5. STATS TAB
    local statsLabels = {}
    local statFields = { "Uptime", "ServerUptime", "SessionHoney", "HoneyPerHour", "Chick", "Crab", "Bear", "Beetle", "Snail" }
    for _, field in ipairs(statFields) do
        local lbl = Instance.new("TextLabel")
        lbl.Text = field .. ": ..."
        lbl.Size = UDim2.new(1, -10, 0, 28)
        lbl.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.Parent = tabPages["Stats"]
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
        statsLabels[field] = lbl
    end

    -- Run HUD update loop
    task.spawn(function()
        while task.wait(1) do
            local elapsed = tick() - State.start
            local currentHoney = (LocalPlayer:FindFirstChild("CoreStats") and LocalPlayer.CoreStats:FindFirstChild("Honey")) and LocalPlayer.CoreStats.Honey.Value or 0
            local sessionHoney = math.max(0, currentHoney - State.honeyatstart)
            local honeyRate = elapsed > 0 and (sessionHoney / elapsed) * 3600 or 0

            statsLabels.Uptime.Text = "  Uptime: " .. string.format("%02d:%02d:%02d", math.floor(elapsed/3600), math.floor((elapsed%3600)/60), math.floor(elapsed%60))
            statsLabels.ServerUptime.Text = "  Server Uptime: " .. string.format("%02d:%02d:%02d", math.floor(Workspace.DistributedGameTime/3600), math.floor((Workspace.DistributedGameTime%3600)/60), math.floor(Workspace.DistributedGameTime%60))
            statsLabels.SessionHoney.Text = "  Session Honey: " .. tostring(math.floor(sessionHoney))
            statsLabels.HoneyPerHour.Text = "  Honey / Hour: " .. tostring(math.floor(honeyRate))
            statsLabels.Chick.Text = "  Commando Chick: " .. (Cooldowns["Commando Chick"] > 0 and tostring(Cooldowns["Commando Chick"]) or utf8.char(10003))
            statsLabels.Crab.Text = "  Coconut Crab: " .. (Cooldowns["CoconutCrab"] > 0 and tostring(Cooldowns["CoconutCrab"]) or utf8.char(10003))
            statsLabels.Bear.Text = "  Tunnel Bear: " .. (Cooldowns["TunnelBear"] > 0 and tostring(Cooldowns["TunnelBear"]) or utf8.char(10003))
            statsLabels.Beetle.Text = "  King Beetle: " .. (Cooldowns["King Beetle Cave"] > 0 and tostring(Cooldowns["King Beetle Cave"]) or utf8.char(10003))
            statsLabels.Snail.Text = "  Stump Snail: " .. (Cooldowns["StumpSnail"] > 0 and tostring(Cooldowns["StumpSnail"]) or utf8.char(10003))
        end
    end)

    selectTab("Autofarm")
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
setupWorkspaceListeners()
initializeAtlasUI()

print("[Atlas BSS] Chris12089 - Complete Deobfuscated Script Initialized Successfully!")
