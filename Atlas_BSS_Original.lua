--[[
    Credits:
    Made by chris12089
    UI Library based on Elerium and Icons from Lucide
    Atlas BSS - Pure Reconstructed Source
--]]

if _G.loading then return end
_G.loading = true

if not getthreadidentity or getthreadidentity() < 8 then
    local sg = cloneref and cloneref(game:GetService("StarterGui")) or game:GetService("StarterGui")
    sg:SetCore("SendNotification", {
        Title = "Warning",
        Text = "Your executor is not supported.",
        Duration = 10
    })
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

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
-- STATE & CONFIGURATION (Pure Atlas BSS)
--------------------------------------------------------------------------------
local State = {
    start = tick(),
    honeyatstart = (LocalPlayer:FindFirstChild("CoreStats") and LocalPlayer.CoreStats:FindFirstChild("Honey")) and LocalPlayer.CoreStats.Honey.Value or 0,
    stop = false,
    stopdig = false,
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
        farmcoconuts = false,
        farmcombococonuts = false,
        farmshowers = false,
        farmmeteorshowers = false,
        field = "Pine Tree"
    },
    sprouts = {
        amount = 0,
        left = 0
    },
    toys = {
        shrineitem = "",
        shrineamount = 0
    },
    movement = {
        walkspeed = 16,
        fastcoconut = false,
        fastshower = false,
        tween = true
    },
    visuals = {
        hideparticles = false,
        hidemarks = false,
        hidetokens = false,
        antilag = false
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
-- TASK MANAGER
--------------------------------------------------------------------------------
local TaskManager = {
    tasks = {}
}

function TaskManager:Add(name, taskFunc)
    if self.tasks[name] then
        self:Cancel(name)
    end
    if typeof(taskFunc) == "RBXScriptConnection" then
        self.tasks[name] = taskFunc
    elseif type(taskFunc) == "function" then
        local thread = task.spawn(taskFunc)
        self.tasks[name] = thread
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
-- MOVEMENT & NAVIGATION CONTROLLER
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
        local duration = distance / (speed or 40)
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
-- ANTI-LAG / FPS BOOSTER (Pure Atlas Function Ws)
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
end

--------------------------------------------------------------------------------
-- WORKSPACE HAZARDS & OBJECTS (Functions w & x)
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
-- AUTOFARM ENGINE (Functions Z, m, ks, zs)
--------------------------------------------------------------------------------
local function startAutoDig()
    if TaskManager:Get("autodig") then return end
    TaskManager:Add("autodig", function()
        while RunService.Heartbeat:Wait() do
            if not State.stop and not State.stopdig then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("ClickEvent") then
                    tool.ClickEvent:FireServer()
                end
                task.wait(0.1)
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
            if coreStats.Pollen.Value >= coreStats.Capacity.Value then
                stopMovement()
                local hivePos = LocalPlayer.SpawnPos.Value
                moveToPosition(CFrame.new(hivePos), 50, Config.movement.tween)

                local makeHoneyRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("PlayerHiveCommand")
                if makeHoneyRemote then
                    makeHoneyRemote:FireServer({["Action"] = "MakeHoney"})
                end

                while coreStats.Pollen.Value > 0 and Config.autofarm.enabled do
                    task.wait(1)
                end
            end
        end

        for coconut, _ in pairs(State.coconuts) do
            if coconut and coconut.Parent then
                moveToPosition(coconut.CFrame, 60, Config.movement.tween)
            end
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
-- HAPPENINGS & SPECIALS (Sprouts, Puffshrooms, Stickers, Wind Shrine)
--------------------------------------------------------------------------------
local function setupHappenings()
    local sproutsFolder = Workspace:FindFirstChild("Sprouts")
    if sproutsFolder then
        sproutsFolder.ChildAdded:Connect(function(child)
            if child.Name == "Sprout" then
                State.sprouts[child] = true
            end
        end)
        sproutsFolder.ChildRemoved:Connect(function(child)
            State.sprouts[child] = nil
        end)
    end

    local happenings = Workspace:FindFirstChild("Happenings")
    if happenings and happenings:FindFirstChild("Puffshrooms") then
        happenings.Puffshrooms.ChildAdded:Connect(function(p)
            State.puffshrooms[p] = true
        end)
        happenings.Puffshrooms.ChildRemoved:Connect(function(p)
            State.puffshrooms[p] = nil
        end)
    end

    local hiddenStickers = Workspace:FindFirstChild("HiddenStickers")
    if hiddenStickers then
        hiddenStickers.ChildAdded:Connect(function(s)
            State.stickers[s] = true
        end)
        hiddenStickers.ChildRemoved:Connect(function(s)
            State.stickers[s] = nil
        end)
    end
end

--------------------------------------------------------------------------------
-- CLIENT FX HOOK (Function Cs)
--------------------------------------------------------------------------------
local function hookClientFX()
    pcall(function()
        local localFX = ReplicatedStorage:FindFirstChild("LocalFX")
        if localFX and hookfunction then
            local clientRun = require(localFX).ClientRun
            hookfunction(clientRun, function(...)
                local args = {...}
                local effectName = args[1]
                if Config.visuals.hideparticles and effectName then
                    return
                end
                return clientRun(...)
            end)
        end
    end)
end

--------------------------------------------------------------------------------
-- TIME & NUMBER FORMATTING (Functions d & Es)
--------------------------------------------------------------------------------
local function formatTime(seconds)
    if not seconds or seconds < 0 then return "00:00:00" end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function formatNumber(num)
    if not num then return "0" end
    if num >= 1e12 then return string.format("%.2fT", num / 1e12)
    elseif num >= 1e9 then return string.format("%.2fB", num / 1e9)
    elseif num >= 1e6 then return string.format("%.2fM", num / 1e6)
    elseif num >= 1e3 then return string.format("%.2fK", num / 1e3)
    else return tostring(math.floor(num)) end
end

--------------------------------------------------------------------------------
-- ELERIUM UI INTERFACE (Atlas BSS by chris12089)
--------------------------------------------------------------------------------
local function createAtlasUI()
    local AtlasGui = Instance.new("ScreenGui")
    AtlasGui.Name = "AtlasBSS"
    AtlasGui.ResetOnSpawn = false
    AtlasGui.Parent = CoreGui

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 520, 0, 360)
    Main.Position = UDim2.new(0.5, -260, 0.5, -180)
    Main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = AtlasGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 36)
    TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Main
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

    local Title = Instance.new("TextLabel")
    Title.Text = "Atlas BSS"
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Parent = TopBar

    local Credits = Instance.new("TextLabel")
    Credits.Text = "by chris12089"
    Credits.Size = UDim2.new(0, 100, 1, 0)
    Credits.Position = UDim2.new(0, 85, 0, 0)
    Credits.TextColor3 = Color3.fromRGB(150, 150, 150)
    Credits.TextSize = 11
    Credits.Font = Enum.Font.Gotham
    Credits.TextXAlignment = Enum.TextXAlignment.Left
    Credits.BackgroundTransparency = 1
    Credits.Parent = TopBar

    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(0, 120, 1, -44)
    TabContainer.Position = UDim2.new(0, 8, 0, 40)
    TabContainer.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = Main
    Instance.new("UICorner", TabContainer).CornerRadius = UDim.new(0, 6)

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -144, 1, -44)
    ContentContainer.Position = UDim2.new(0, 136, 0, 40)
    ContentContainer.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    ContentContainer.BorderSizePixel = 0
    ContentContainer.Parent = Main
    Instance.new("UICorner", ContentContainer).CornerRadius = UDim.new(0, 6)

    local tabs = { "Autofarm", "Movement", "Visuals", "Cooldowns", "Stats" }
    local tabButtons = {}
    local tabFrames = {}

    local tabLayout = Instance.new("UIListLayout", TabContainer)
    tabLayout.Padding = UDim.new(0, 4)

    local function selectTab(name)
        for tName, frame in pairs(tabFrames) do
            frame.Visible = (tName == name)
        end
        for tName, btn in pairs(tabButtons) do
            btn.BackgroundColor3 = (tName == name) and Color3.fromRGB(42, 42, 52) or Color3.fromRGB(32, 32, 40)
            btn.TextColor3 = (tName == name) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 160)
        end
    end

    for _, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Text = "  " .. name
        btn.Size = UDim2.new(1, -8, 0, 28)
        btn.Position = UDim2.new(0, 4, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        btn.TextColor3 = Color3.fromRGB(160, 160, 160)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamSemibold
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = TabContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local frame = Instance.new("ScrollingFrame")
        frame.Size = UDim2.new(1, -12, 1, -12)
        frame.Position = UDim2.new(0, 6, 0, 6)
        frame.BackgroundTransparency = 1
        frame.ScrollBarThickness = 4
        frame.Visible = false
        frame.Parent = ContentContainer
        local frameLayout = Instance.new("UIListLayout", frame)
        frameLayout.Padding = UDim.new(0, 6)

        tabButtons[name] = btn
        tabFrames[name] = frame

        btn.MouseButton1Click:Connect(function()
            selectTab(name)
        end)
    end

    -- Helper: Toggle
    local function addToggle(parent, text, default, callback)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -8, 0, 32)
        f.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

        local l = Instance.new("TextLabel")
        l.Text = text
        l.Size = UDim2.new(1, -50, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.TextColor3 = Color3.fromRGB(220, 220, 220)
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.BackgroundTransparency = 1
        l.Parent = f

        local b = Instance.new("TextButton")
        b.Text = default and utf8.char(10003) or ""
        b.Size = UDim2.new(0, 22, 0, 22)
        b.Position = UDim2.new(1, -30, 0.5, -11)
        b.BackgroundColor3 = default and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(50, 50, 60)
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

        local state = default
        b.MouseButton1Click:Connect(function()
            state = not state
            b.Text = state and utf8.char(10003) or ""
            b.BackgroundColor3 = state and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(50, 50, 60)
            callback(state)
        end)
    end

    -- Tab: Autofarm
    addToggle(tabFrames["Autofarm"], "Autofarm", Config.autofarm.enabled, function(val)
        toggleAutoFarm(val)
    end)
    addToggle(tabFrames["Autofarm"], "Farm Coconuts", Config.autofarm.farmcoconuts, function(val)
        Config.autofarm.farmcoconuts = val
    end)
    addToggle(tabFrames["Autofarm"], "Farm Combo Coconuts", Config.autofarm.farmcombococonuts, function(val)
        Config.autofarm.farmcombococonuts = val
    end)
    addToggle(tabFrames["Autofarm"], "Farm Showers", Config.autofarm.farmshowers, function(val)
        Config.autofarm.farmshowers = val
    end)
    addToggle(tabFrames["Autofarm"], "Farm Meteor Showers", Config.autofarm.farmmeteorshowers, function(val)
        Config.autofarm.farmmeteorshowers = val
    end)

    -- Tab: Movement
    addToggle(tabFrames["Movement"], "Tween", Config.movement.tween, function(val)
        Config.movement.tween = val
    end)
    addToggle(tabFrames["Movement"], "Fast Coconut", Config.movement.fastcoconut, function(val)
        Config.movement.fastcoconut = val
    end)
    addToggle(tabFrames["Movement"], "Fast Shower", Config.movement.fastshower, function(val)
        Config.movement.fastshower = val
    end)

    -- Tab: Visuals
    addToggle(tabFrames["Visuals"], "Antilag", Config.visuals.antilag, function(val)
        Config.visuals.antilag = val
        if val then runAntiLag() end
    end)
    addToggle(tabFrames["Visuals"], "Hide Particles", Config.visuals.hideparticles, function(val)
        Config.visuals.hideparticles = val
    end)
    addToggle(tabFrames["Visuals"], "Hide Marks", Config.visuals.hidemarks, function(val)
        Config.visuals.hidemarks = val
    end)
    addToggle(tabFrames["Visuals"], "Hide Tokens", Config.visuals.hidetokens, function(val)
        Config.visuals.hidetokens = val
    end)

    -- Tab: Cooldowns & Stats Labels
    local bossList = { "Commando Chick", "CoconutCrab", "TunnelBear", "King Beetle Cave", "StumpSnail" }
    local bossLabels = {}
    for _, bName in ipairs(bossList) do
        local l = Instance.new("TextLabel")
        l.Text = bName .. ": " .. utf8.char(10003)
        l.Size = UDim2.new(1, -8, 0, 26)
        l.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
        l.TextColor3 = Color3.fromRGB(220, 220, 220)
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.Parent = tabFrames["Cooldowns"]
        Instance.new("UICorner", l).CornerRadius = UDim.new(0, 6)
        bossLabels[bName] = l
    end

    local statList = { "Uptime", "ServerUptime", "SessionHoney", "HoneyPerHour" }
    local statLabels = {}
    for _, sName in ipairs(statList) do
        local l = Instance.new("TextLabel")
        l.Text = sName .. ": 0"
        l.Size = UDim2.new(1, -8, 0, 26)
        l.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
        l.TextColor3 = Color3.fromRGB(220, 220, 220)
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.Parent = tabFrames["Stats"]
        Instance.new("UICorner", l).CornerRadius = UDim.new(0, 6)
        statLabels[sName] = l
    end

    -- Live Loop
    task.spawn(function()
        while task.wait(1) do
            local elapsed = tick() - State.start
            local currentHoney = (LocalPlayer:FindFirstChild("CoreStats") and LocalPlayer.CoreStats:FindFirstChild("Honey")) and LocalPlayer.CoreStats.Honey.Value or 0
            local sessionHoney = math.max(0, currentHoney - State.honeyatstart)
            local honeyRate = elapsed > 0 and (sessionHoney / elapsed) * 3600 or 0

            statLabels.Uptime.Text = "Uptime: " .. formatTime(elapsed)
            statLabels.ServerUptime.Text = "Server Uptime: " .. formatTime(Workspace.DistributedGameTime)
            statLabels.SessionHoney.Text = "Session Honey: " .. formatNumber(sessionHoney)
            statLabels.HoneyPerHour.Text = "Honey per Hour: " .. formatNumber(honeyRate)

            for _, bName in ipairs(bossList) do
                local cd = Cooldowns[bName] or 0
                bossLabels[bName].Text = bName .. ": " .. (cd > 0 and formatTime(cd) or utf8.char(10003))
            end
        end
    end)

    selectTab("Autofarm")
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
setupWorkspaceListeners()
setupHappenings()
hookClientFX()
createAtlasUI()

print("[Atlas BSS] Loaded successfully.")
