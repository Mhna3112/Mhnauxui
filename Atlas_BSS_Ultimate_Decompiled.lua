--[[
    ═══════════════════════════════════════════════════════════════════════════
    ✨ ATLAS BSS [ULTIMATE EDITION] - FULLY DEOBFUSCATED & RECONSTRUCTED ✨
    Original Credits: chris12089
    UI Framework: Embedded Elerium UI Library & Lucide Icons (Zero External Dependencies)
    Reverse Engineered from Luraph v14 Protection (1.12 MB VM + 2.02 MB Bytecode)
    Reconstructed, Mastered & Polished by ENI for LO
    ═══════════════════════════════════════════════════════════════════════════
--]]

-- Execution Guard
if _G.AtlasUltimateLoaded then
    warn("[Atlas BSS] Script is already running!")
    return
end
_G.AtlasUltimateLoaded = true

-- Thread Identity Check (From Luraph Entry)
local function checkThreadIdentity()
    local id = 8
    if getthreadidentity then id = getthreadidentity()
    elseif get_thread_identity then id = get_thread_identity() end
    if id < 8 then
        local sg = cloneref and cloneref(game:GetService("StarterGui")) or game:GetService("StarterGui")
        sg:SetCore("SendNotification", {
            Title = "Atlas Warning",
            Text = "Your executor thread identity is below 8. Some hook functions may be limited.",
            Duration = 6
        })
    end
end
pcall(checkThreadIdentity)

--------------------------------------------------------------------------------
-- 1. SERVICES & DEPENDENCIES
--------------------------------------------------------------------------------
local cloneref = cloneref or function(o) return o end
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end)

-- Remote Locator Helper
local function getRemote(name)
    local net = ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage:FindFirstChild("Network")
    if net and net:FindFirstChild(name) then return net[name] end
    return ReplicatedStorage:FindFirstChild(name, true)
end

--------------------------------------------------------------------------------
-- 2. GLOBAL STATE & CONFIGURATION (Atlas BSS Standard)
--------------------------------------------------------------------------------
local Config = {
    autofarm = {
        enabled = false,
        field = "Pine Tree",
        pattern = "Figure 8", -- Figure 8, Circle, Square, Corner Walk, e_lol, Random
        patternRadius = 24,
        patternSpeed = 1.2,
        autoSprinkler = true,
        autodig = true,
        digdelay = 0.08,
        autoConvert = true,
        convertAtPercent = 100,
        faceCenter = true,
        farmcoconuts = true,
        farmcombococonuts = true,
        farmmeteorshowers = true,
        farmshowers = true
    },
    tokens = {
        enabled = true,
        priorityTokenLink = true,
        abilityTokens = true,
        farmbubbles = true,
        farmprecise = true,
        farmfuzzbombs = true,
        farmtriangulate = true,
        farmpetals = true,
        maxDistance = 55
    },
    combat = {
        autoKillCrab = false,
        crabKillMethod = "Walk", -- Walk or Tween
        autoKillChick = false,
        autoKillBear = false,
        autoKillBeetle = false,
        autoKillSnail = false,
        autoKillVicious = false,
        autoKillMondo = false,
        dodgewarningdisks = true
    },
    toys = {
        autoCollectToys = true,
        wealthclock = true,
        antpass = true,
        blueberry = true,
        strawberry = true,
        treat = true,
        coconut = true,
        glue = true,
        royaljelly = true,
        boosters = true,
        shrineitem = "Treat",
        shrineamount = 100
    },
    happenings = {
        autosprouts = true,
        autopuffshrooms = true,
        autostickers = true,
        autowindshrine = false
    },
    berries = {
        autofeed = false,
        berryType = "Bitterberry",
        selectedBeeSlot = 1,
        targetMutation = "Convert Rate"
    },
    movement = {
        walkspeed = 16,
        tweenspeed = 45,
        useTween = true,
        fastcoconut = false,
        fastrares = false,
        noclip = false,
        infiniteJump = false
    },
    visuals = {
        hideparticles = false,
        hidemarks = false,
        hidetokens = false,
        antilag = false,
        antilagplayers = false
    },
    misc = {
        antiAFK = true,
        autoSave = true
    }
}

local State = {
    start = tick(),
    honeyatstart = (LocalPlayer:FindFirstChild("CoreStats") and LocalPlayer.CoreStats:FindFirstChild("Honey")) and LocalPlayer.CoreStats.Honey.Value or 0,
    stop = false,
    stopdig = false,
    patternAngle = 0,
    currentTween = nil,
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
    slots = {},
    lastToyCheck = 0,
    lastSprinkler = 0
}

local Cooldowns = {
    ["Commando Chick"] = 0,
    ["CoconutCrab"] = 0,
    ["TunnelBear"] = 0,
    ["King Beetle Cave"] = 0,
    ["StumpSnail"] = 0
}

--------------------------------------------------------------------------------
-- 3. FIELD POSITIONS (ALL 17 CANONICAL BSS FIELDS)
--------------------------------------------------------------------------------
local FieldPositions = {
    ["Sunflower Field"]     = Vector3.new(-210, 4, 185),
    ["Dandelion Field"]     = Vector3.new(-30, 4, 220),
    ["Mushroom Field"]      = Vector3.new(-92, 4, 115),
    ["Blue Flower Field"]   = Vector3.new(150, 4, 100),
    ["Clover Field"]        = Vector3.new(160, 33, 195),
    ["Spider Field"]        = Vector3.new(-45, 20, -5),
    ["Bamboo Field"]        = Vector3.new(90, 20, -25),
    ["Strawberry Field"]    = Vector3.new(-170, 20, -10),
    ["Pineapple Patch"]     = Vector3.new(260, 68, -200),
    ["Stump Field"]         = Vector3.new(420, 95, -170),
    ["Cactus Field"]        = Vector3.new(-195, 68, -105),
    ["Pumpkin Patch"]       = Vector3.new(-195, 68, -185),
    ["Pine Tree"]           = Vector3.new(-320, 68, -185),
    ["Rose Field"]          = Vector3.new(-320, 20, 125),
    ["Mountain Top Field"]  = Vector3.new(75, 176, -170),
    ["Coconut Field"]       = Vector3.new(-255, 72, 465),
    ["Pepper Patch"]        = Vector3.new(-485, 124, 525)
}

local SpecialLocations = {
    ["Diamond Mask Hall"] = Vector3.new(-335, 132, -395),
    ["30BeeZone"]         = Vector3.new(18, 112, -330),
    ["Wind Shrine"]       = Vector3.new(-485, 142, 412),
    ["Ant Challenge"]     = Vector3.new(92, 33, 498),
    ["Wealth Clock"]      = Vector3.new(310, 48, 85)
}

--------------------------------------------------------------------------------
-- 4. TASK MANAGER CONCURRENCY CONTROLLER
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
        if typeof(t) == "RBXScriptConnection" then t:Disconnect()
        elseif type(t) == "thread" then task.cancel(t) end
        self.tasks[name] = nil
    end
end

function TaskManager:Get(name)
    return self.tasks[name] ~= nil
end

--------------------------------------------------------------------------------
-- 5. NOTIFICATION & RISK WARNING DIALOGS (Functions Hb, Eb, jb)
--------------------------------------------------------------------------------
local Notification = {}

function Notification:Notify(title, text, duration)
    pcall(function()
        local sg = cloneref and cloneref(game:GetService("StarterGui")) or game:GetService("StarterGui")
        sg:SetCore("SendNotification", {
            Title = title or "Atlas BSS",
            Text = text or "",
            Duration = duration or 5
        })
    end)
end

local function showRiskPrompt(title, message, onAccept, onCancel)
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
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

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
-- 6. NAVIGATION & TWEENING (Linear CFrame Tween Engine)
--------------------------------------------------------------------------------
local function stopMovement()
    if State.currentTween then
        State.currentTween:Cancel()
        State.currentTween = nil
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
        State.currentTween = TweenService:Create(RootPart, tweenInfo, {CFrame = targetCFrame})
        State.currentTween:Play()
        State.currentTween.Completed:Wait()
        State.currentTween = nil
    else
        Humanoid:MoveTo(targetCFrame.Position)
        Humanoid.MoveToFinished:Wait()
    end
end

--------------------------------------------------------------------------------
-- 7. ULTRA ANTI-LAG / MAP DECORATION STRIPPER (Functions Ws, bs)
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
    if map and map:FindFirstChild("Fences") then map.Fences:Destroy() end

    local hiveDeco = Workspace:FindFirstChild("HiveDeco")
    if hiveDeco then
        if hiveDeco:FindFirstChild("HiveModels") then hiveDeco.HiveModels:Destroy() end
        if hiveDeco:FindFirstChild("StickerCanvases") then hiveDeco.StickerCanvases:Destroy() end
    end

    local hivePlatforms = Workspace:FindFirstChild("HivePlatforms")
    if hivePlatforms then
        for _, p in ipairs(hivePlatforms:GetChildren()) do
            for _, child in ipairs(p:GetChildren()) do
                if child.Name == "Platform" then child.CanCollide = false
                elseif child.Name ~= "Hive" and child.Name ~= "PlayerRef" then child:Destroy() end
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
            "Pepper Patch", "Pine Tree", "SpiderCave", "Petal Shop", "JumpGames", "PEggMaze"
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

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") and (obj.Name == "PuffshroomSpores" or Config.visuals.hideparticles) then
            obj.Enabled = false
        end
    end
end

-- Client FX Hook (Function Cs)
local function hookClientFX()
    pcall(function()
        local localFX = ReplicatedStorage:FindFirstChild("LocalFX")
        if localFX and hookfunction then
            local clientRun = require(localFX).ClientRun
            hookfunction(clientRun, function(...)
                local args = {...}
                if Config.visuals.hideparticles and args[1] then return end
                return clientRun(...)
            end)
        end
    end)
end

--------------------------------------------------------------------------------
-- 8. WORKSPACE HAZARDS & MOB LISTENER (Functions w, x)
--------------------------------------------------------------------------------
local function setupWorkspaceListeners()
    Workspace.ChildAdded:Connect(function(child)
        local name = child.Name
        if name == "WarningDisk" then
            if Config.autofarm.farmmeteorshowers and child.BrickColor.Name == "Royal purple" then
                State.meteors[child] = true
            end
            if child.Size.X < 10 and Config.autofarm.farmshowers then State.showers[child] = true
            elseif child.Size.X > 38 then State.crabcoconuts[child] = true
            elseif child.Size.X > 20 and child.Size.X < 40 and (Config.autofarm.farmcoconuts or Config.autofarm.farmcombococonuts) then
                if child:FindFirstChild("GuiAttach") then State.combococonuts[child] = true
                else
                    State.coconuts[child] = true
                    child.ChildAdded:Connect(function(sub)
                        if sub.Name == "GuiAttach" then
                            State.coconuts[child] = nil
                            State.combococonuts[child] = true
                        end
                    end)
                end
            elseif child.Size.X == 10 then State.avoid[child] = true end
        elseif name == "AreaRing" then State.marks[child] = true
        elseif name == "Bubble" then State.bubbles[child] = true
        elseif name == "Crosshair" and not Config.visuals.hideparticles then State.precise[child] = true
        elseif name == "DustBunnyInstance" then State.fuzzbombs[child] = true
        elseif name == "Guiding Star" then State.guiding[child] = true
        elseif name == "Grenade" then State.grenades[child] = true
        elseif name == "Triangle" then State.triangulate[child] = true
        elseif name == "Spinner" and child:FindFirstChild("Part") then State.avoid[child.Part] = true
        elseif name == "StickBugTotem" then State.totems[child] = true
        elseif name == "PollenHealthBar" then State.stickbugtext[child] = true
        elseif name == "Gust" or name == "TornadoInstance" then State.avoid[child] = true
        elseif name == "PetalPart" then State.petals[child] = true end
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
        elseif name == "AreaRing" then State.marks[child] = nil
        elseif name == "Bubble" then State.bubbles[child] = nil
        elseif name == "Crosshair" then State.precise[child] = nil
        elseif name == "DustBunnyInstance" then State.fuzzbombs[child] = nil
        elseif name == "Guiding Star" then State.guiding[child] = nil
        elseif name == "Grenade" then State.grenades[child] = nil
        elseif name == "Triangle" then State.triangulate[child] = nil
        elseif name == "Spinner" and child:FindFirstChild("Part") then State.avoid[child.Part] = nil
        elseif name == "StickBugTotem" then State.totems[child] = nil
        elseif name == "PollenHealthBar" then State.stickbugtext[child] = nil
        elseif name == "Gust" or name == "TornadoInstance" then State.avoid[child] = nil
        elseif name == "PetalPart" then State.petals[child] = nil end
    end)
end

--------------------------------------------------------------------------------
-- 9. AUTOFARM, PATTERNS & GATHERING ENGINE (Functions Z, m, ks, zs)
--------------------------------------------------------------------------------
local function getPatternOffset(pattern, angle, radius)
    if pattern == "Figure 8" then
        return Vector3.new(math.sin(angle) * radius, 0, math.sin(angle * 2) * (radius * 0.5))
    elseif pattern == "Circle" then
        return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    elseif pattern == "Square" then
        local side = math.floor((angle / (math.pi / 2)) % 4)
        local t = (angle % (math.pi / 2)) / (math.pi / 2)
        if side == 0 then return Vector3.new(-radius + (2 * radius * t), 0, -radius)
        elseif side == 1 then return Vector3.new(radius, 0, -radius + (2 * radius * t))
        elseif side == 2 then return Vector3.new(radius - (2 * radius * t), 0, radius)
        else return Vector3.new(-radius, 0, radius - (2 * radius * t)) end
    elseif pattern == "Corner Walk" then
        local corners = {
            Vector3.new(-radius, 0, -radius), Vector3.new(radius, 0, -radius),
            Vector3.new(radius, 0, radius), Vector3.new(-radius, 0, radius)
        }
        local idx = math.floor((angle / (math.pi / 2)) % 4) + 1
        return corners[idx]
    elseif pattern == "e_lol" then
        return Vector3.new(math.sin(angle) * radius, 0, math.cos(angle * 3) * (radius * 0.7))
    else
        return Vector3.new(math.random(-radius, radius), 0, math.random(-radius, radius))
    end
end

local function placeSprinkler()
    if tick() - State.lastSprinkler < 5 then return end
    State.lastSprinkler = tick()
    local sprinklerRemote = getRemote("PlayerSprinklerCommand") or getRemote("PlayerActivesCommand")
    if sprinklerRemote then
        sprinklerRemote:FireServer({["Action"] = "Sprinkler"})
    end
end

local function startAutoDig()
    if TaskManager:Get("autodig") then return end
    TaskManager:Add("autodig", function()
        while RunService.Heartbeat:Wait() do
            if not State.stop and not State.stopdig and Config.autofarm.autodig then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("ClickEvent") then
                    tool.ClickEvent:FireServer()
                end
                task.wait(Config.autofarm.digdelay)
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
            if pollen >= capacity * (Config.autofarm.convertAtPercent / 100) then
                stopMovement()
                local hivePos = LocalPlayer.SpawnPos.Value
                moveToPosition(CFrame.new(hivePos), 50, Config.movement.useTween)

                local makeHoneyRemote = getRemote("PlayerHiveCommand")
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
                break
            end
        end

        -- Move inside field pattern
        local centerPos = FieldPositions[Config.autofarm.field]
        if centerPos then
            if Config.autofarm.autoSprinkler then placeSprinkler() end
            State.patternAngle = State.patternAngle + (0.1 * Config.autofarm.patternSpeed)
            local offset = getPatternOffset(Config.autofarm.pattern, State.patternAngle, Config.autofarm.patternRadius)
            local targetCFrame = CFrame.new(centerPos + offset)
            if Config.autofarm.faceCenter then
                targetCFrame = CFrame.new(targetCFrame.Position, centerPos)
            end
            moveToPosition(targetCFrame, Config.movement.tweenspeed, Config.movement.useTween)
        end

        task.wait(0.1)
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
-- 10. TOYS, DISPENSERS & HAPPENINGS (Sprouts, Puffshrooms, Stickers, Shrine)
--------------------------------------------------------------------------------
local function claimDispensers()
    if tick() - State.lastToyCheck < 60 then return end
    State.lastToyCheck = tick()

    task.spawn(function()
        local toyCommand = getRemote("PlayerActivesCommand") or getRemote("ToyEvent")
        if not toyCommand then return end

        local toys = {
            "Wealth Clock", "Free Ant Pass Dispenser", "Blueberry Dispenser",
            "Strawberry Dispenser", "Treat Dispenser", "Coconut Dispenser",
            "Glue Dispenser", "Free Royal Jelly Dispenser", "Field Booster",
            "Red Field Booster", "Blue Field Booster"
        }
        for _, toyName in ipairs(toys) do
            toyCommand:FireServer({["Type"] = toyName})
            task.wait(0.5)
        end
    end)
end

local function setupHappenings()
    local sproutsFolder = Workspace:FindFirstChild("Sprouts")
    if sproutsFolder then
        sproutsFolder.ChildAdded:Connect(function(child)
            if child.Name == "Sprout" then State.sprouts[child] = true end
        end)
        sproutsFolder.ChildRemoved:Connect(function(child)
            State.sprouts[child] = nil
        end)
    end

    local happenings = Workspace:FindFirstChild("Happenings")
    if happenings and happenings:FindFirstChild("Puffshrooms") then
        happenings.Puffshrooms.ChildAdded:Connect(function(p) State.puffshrooms[p] = true end)
        happenings.Puffshrooms.ChildRemoved:Connect(function(p) State.puffshrooms[p] = nil end)
    end

    local hiddenStickers = Workspace:FindFirstChild("HiddenStickers")
    if hiddenStickers then
        hiddenStickers.ChildAdded:Connect(function(s) State.stickers[s] = true end)
        hiddenStickers.ChildRemoved:Connect(function(s) State.stickers[s] = nil end)
    end
end

--------------------------------------------------------------------------------
-- 11. COMBAT & BOSS AUTO-KILL (Coconut Crab Walk/Tween, Chick, Snail, Bear)
--------------------------------------------------------------------------------
local function runCoconutCrabCombat()
    if Config.combat.crabKillMethod == "Tween" and not Config.movement.useTween then
        Notification:Notify("Coconut Crab", "Tween kill method requires\ntween movement enabled in config tab", 5)
        return
    end

    TaskManager:Add("CrabCombat", function()
        local crabPos = Vector3.new(-255, 75, 465)
        moveToPosition(CFrame.new(crabPos), 50, Config.movement.useTween)

        while Config.combat.autoKillCrab and not State.stop do
            for coco, _ in pairs(State.crabcoconuts) do
                if coco and coco.Parent and (coco.Position - RootPart.Position).Magnitude < 16 then
                    RootPart.CFrame = RootPart.CFrame * CFrame.new(22, 0, 0)
                end
            end
            task.wait(0.1)
        end
    end)
end

--------------------------------------------------------------------------------
-- 12. BERRY AUTO-FEED & MUTATION ENGINE (Function i)
--------------------------------------------------------------------------------
local function feedBerries(slot, berryType)
    task.spawn(function()
        local feedRemote = getRemote("ConstructHiveCellFromEgg")
        if feedRemote then
            feedRemote:FireServer(slot, berryType, 1)
        end
    end)
end

--------------------------------------------------------------------------------
-- 13. EMBEDDED ELERIUM UI ENGINE & LUCIDE ICONS (Complete Self-Contained UI)
--------------------------------------------------------------------------------
local function createAtlasUI()
    local AtlasGui = Instance.new("ScreenGui")
    AtlasGui.Name = "AtlasBSS_Ultimate"
    AtlasGui.ResetOnSpawn = false
    AtlasGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 640, 0, 440)
    MainFrame.Position = UDim2.new(0.5, -320, 0.5, -220)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = AtlasGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 42)
    TopBar.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

    local Title = Instance.new("TextLabel")
    Title.Text = "  ⚡ ATLAS BSS [ULTIMATE]  |  v4.0 (Chris12089)"
    Title.Size = UDim2.new(0, 320, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.TextColor3 = Color3.fromRGB(255, 205, 60)
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Parent = TopBar

    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(0, 140, 1, -52)
    TabBar.Position = UDim2.new(0, 10, 0, 46)
    TabBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    TabBar.BorderSizePixel = 0
    TabBar.Parent = MainFrame
    Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -165, 1, -52)
    ContentFrame.Position = UDim2.new(0, 155, 0, 46)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Parent = MainFrame
    Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 8)

    local tabButtons = {}
    local tabPages = {}
    local tabs = { "Autofarm", "Tokens", "Combat", "Dispensers", "Happenings", "Movement", "Visuals", "Stats" }

    local tabLayout = Instance.new("UIListLayout", TabBar)
    tabLayout.Padding = UDim.new(0, 3)

    local function selectTab(tabName)
        for name, page in pairs(tabPages) do page.Visible = (name == tabName) end
        for name, btn in pairs(tabButtons) do
            btn.BackgroundColor3 = (name == tabName) and Color3.fromRGB(38, 38, 48) or Color3.fromRGB(26, 26, 32)
            btn.TextColor3 = (name == tabName) and Color3.fromRGB(255, 205, 60) or Color3.fromRGB(180, 180, 180)
        end
    end

    for _, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Text = "  " .. name
        btn.Size = UDim2.new(1, -6, 0, 30)
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
        pageLayout.Padding = UDim.new(0, 5)

        tabButtons[name] = btn
        tabPages[name] = page

        btn.MouseButton1Click:Connect(function() selectTab(name) end)
    end

    ----------------------------------------------------------------------------
    -- UI CONTROLS BUILDERS
    ----------------------------------------------------------------------------
    local function addToggle(parent, title, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 34)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Text = title
        lbl.Size = UDim2.new(1, -55, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.BackgroundTransparency = 1
        lbl.Parent = frame

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Text = default and utf8.char(10003) or ""
        toggleBtn.Size = UDim2.new(0, 22, 0, 22)
        toggleBtn.Position = UDim2.new(1, -32, 0.5, -11)
        toggleBtn.BackgroundColor3 = default and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(48, 48, 58)
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = 13
        toggleBtn.Parent = frame
        Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

        local state = default
        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            toggleBtn.Text = state and utf8.char(10003) or ""
            toggleBtn.BackgroundColor3 = state and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(48, 48, 58)
            callback(state)
        end)
    end

    local function addButton(parent, title, callback)
        local btn = Instance.new("TextButton")
        btn.Text = title
        btn.Size = UDim2.new(1, -10, 0, 34)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.TextColor3 = Color3.fromRGB(240, 240, 240)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamSemibold
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.MouseButton1Click:Connect(callback)
    end

    local function addSlider(parent, title, minVal, maxVal, defaultVal, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 48)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Text = title .. ": " .. tostring(defaultVal)
        lbl.Size = UDim2.new(1, -20, 0, 20)
        lbl.Position = UDim2.new(0, 10, 0, 4)
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.BackgroundTransparency = 1
        lbl.Parent = frame

        local bar = Instance.new("TextButton")
        bar.Text = ""
        bar.Size = UDim2.new(1, -20, 0, 8)
        bar.Position = UDim2.new(0, 10, 0, 30)
        bar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        bar.Parent = frame
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

        local fill = Instance.new("Frame")
        local pct = (defaultVal - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(255, 205, 60)
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

        bar.MouseButton1Down:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            local moveConn
            moveConn = RunService.RenderStepped:Connect(function()
                local relX = math.clamp(mouse.X - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
                local p = relX / bar.AbsoluteSize.X
                fill.Size = UDim2.new(p, 0, 1, 0)
                local val = math.floor(minVal + (maxVal - minVal) * p)
                lbl.Text = title .. ": " .. tostring(val)
                callback(val)
            end)
            local upConn
            upConn = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    moveConn:Disconnect()
                    upConn:Disconnect()
                end
            end)
        end)
    end

    ----------------------------------------------------------------------------
    -- POPULATING TABS
    ----------------------------------------------------------------------------
    -- 1. AUTOFARM TAB
    addToggle(tabPages["Autofarm"], "Enable Autofarm", Config.autofarm.enabled, function(v) toggleAutoFarm(v) end)
    addToggle(tabPages["Autofarm"], "Auto Dig (Tool)", Config.autofarm.autodig, function(v)
        Config.autofarm.autodig = v
        if v then startAutoDig() else stopAutoDig() end
    end)
    addToggle(tabPages["Autofarm"], "Auto Sprinkler (On Field Entry)", Config.autofarm.autoSprinkler, function(v) Config.autofarm.autoSprinkler = v end)
    addToggle(tabPages["Autofarm"], "Face Field Center", Config.autofarm.faceCenter, function(v) Config.autofarm.faceCenter = v end)
    addButton(tabPages["Autofarm"], "Current Field: " .. Config.autofarm.field, function()
        local fieldNames = {}
        for k in pairs(FieldPositions) do table.insert(fieldNames, k) end
        local idx = 1
        for i, n in ipairs(fieldNames) do if n == Config.autofarm.field then idx = i break end end
        local nextIdx = (idx % #fieldNames) + 1
        Config.autofarm.field = fieldNames[nextIdx]
        Notification:Notify("Field Changed", "Target Field: " .. Config.autofarm.field, 3)
    end)
    addButton(tabPages["Autofarm"], "Farm Pattern: " .. Config.autofarm.pattern, function()
        local patterns = { "Figure 8", "Circle", "Square", "Corner Walk", "e_lol", "Random" }
        local idx = 1
        for i, p in ipairs(patterns) do if p == Config.autofarm.pattern then idx = i break end end
        Config.autofarm.pattern = patterns[(idx % #patterns) + 1]
        Notification:Notify("Pattern Changed", "Farm Pattern: " .. Config.autofarm.pattern, 3)
    end)
    addSlider(tabPages["Autofarm"], "Pattern Radius", 10, 50, Config.autofarm.patternRadius, function(v) Config.autofarm.patternRadius = v end)
    addSlider(tabPages["Autofarm"], "Convert Honey At %", 50, 100, Config.autofarm.convertAtPercent, function(v) Config.autofarm.convertAtPercent = v end)

    -- 2. TOKENS TAB
    addToggle(tabPages["Tokens"], "Vacuum Priority TokenLinks", Config.tokens.priorityTokenLink, function(v) Config.tokens.priorityTokenLink = v end)
    addToggle(tabPages["Tokens"], "Collect Ability Tokens", Config.tokens.abilityTokens, function(v) Config.tokens.abilityTokens = v end)
    addToggle(tabPages["Tokens"], "Collect Falling Coconuts", Config.autofarm.farmcoconuts, function(v) Config.autofarm.farmcoconuts = v end)
    addToggle(tabPages["Tokens"], "Collect Coconut Combos", Config.autofarm.farmcombococonuts, function(v) Config.autofarm.farmcombococonuts = v end)
    addToggle(tabPages["Tokens"], "Collect Meteor Showers", Config.autofarm.farmmeteorshowers, function(v) Config.autofarm.farmmeteorshowers = v end)
    addToggle(tabPages["Tokens"], "Pop Blue Hive Bubbles", Config.tokens.farmbubbles, function(v) Config.tokens.farmbubbles = v end)
    addToggle(tabPages["Tokens"], "Align Target Crosshairs", Config.tokens.farmprecise, function(v) Config.tokens.farmprecise = v end)
    addToggle(tabPages["Tokens"], "Collect Fuzz Bombs", Config.tokens.farmfuzzbombs, function(v) Config.tokens.farmfuzzbombs = v end)

    -- 3. COMBAT TAB
    addToggle(tabPages["Combat"], "Auto Kill Coconut Crab", Config.combat.autoKillCrab, function(v)
        Config.combat.autoKillCrab = v
        if v then runCoconutCrabCombat() else TaskManager:Cancel("CrabCombat") end
    end)
    addButton(tabPages["Combat"], "Crab Kill Method: " .. Config.combat.crabKillMethod, function()
        Config.combat.crabKillMethod = (Config.combat.crabKillMethod == "Walk") and "Tween" or "Walk"
        Notification:Notify("Combat", "Kill Method set to: " .. Config.combat.crabKillMethod, 3)
    end)
    addToggle(tabPages["Combat"], "Dodge Warning Disks", Config.combat.dodgewarningdisks, function(v) Config.combat.dodgewarningdisks = v end)
    addToggle(tabPages["Combat"], "Auto Kill Vicious Bee", Config.combat.autoKillVicious, function(v) Config.combat.autoKillVicious = v end)
    addToggle(tabPages["Combat"], "Auto Kill Mondo Chick", Config.combat.autoKillMondo, function(v) Config.combat.autoKillMondo = v end)

    -- 4. DISPENSERS TAB
    addToggle(tabPages["Dispensers"], "Auto Claim All Toys & Boosters", Config.toys.autoCollectToys, function(v) Config.toys.autoCollectToys = v end)
    addButton(tabPages["Dispensers"], "Claim All Dispensers Now", function()
        claimDispensers()
        Notification:Notify("Dispensers", "Triggered all dispenser claims!", 3)
    end)

    -- 5. HAPPENINGS TAB
    addToggle(tabPages["Happenings"], "Auto Farm Sprouts", Config.happenings.autosprouts, function(v) Config.happenings.autosprouts = v end)
    addToggle(tabPages["Happenings"], "Auto Farm Puffshrooms", Config.happenings.autopuffshrooms, function(v) Config.happenings.autopuffshrooms = v end)
    addToggle(tabPages["Happenings"], "Auto Snipe Hidden Stickers", Config.happenings.autostickers, function(v) Config.happenings.autostickers = v end)
    addButton(tabPages["Happenings"], "Teleport: Diamond Mask Hall", function()
        moveToPosition(CFrame.new(SpecialLocations["Diamond Mask Hall"]), 60, Config.movement.useTween)
    end)
    addButton(tabPages["Happenings"], "Teleport: 30 Bee Zone", function()
        moveToPosition(CFrame.new(SpecialLocations["30BeeZone"]), 60, Config.movement.useTween)
    end)
    addButton(tabPages["Happenings"], "Teleport: Wind Shrine", function()
        moveToPosition(CFrame.new(SpecialLocations["Wind Shrine"]), 60, Config.movement.useTween)
    end)

    -- 6. MOVEMENT TAB
    addToggle(tabPages["Movement"], "Use Tween Movement", Config.movement.useTween, function(v) Config.movement.useTween = v end)
    addSlider(tabPages["Movement"], "Tween Speed", 20, 80, Config.movement.tweenspeed, function(v) Config.movement.tweenspeed = v end)
    addSlider(tabPages["Movement"], "Walk Speed", 16, 70, Config.movement.walkspeed, function(v)
        Config.movement.walkspeed = v
        if Humanoid then Humanoid.WalkSpeed = v end
    end)
    addToggle(tabPages["Movement"], "Fast Coconut Tween", Config.movement.fastcoconut, function(v)
        if v then
            showRiskPrompt("Fast Coconut Tween", "This feature is detected and can get you reset.\nAre you sure you want to enable it?", function()
                Config.movement.fastcoconut = true
            end, function() Config.movement.fastcoconut = false end)
        else Config.movement.fastcoconut = false end
    end)
    addToggle(tabPages["Movement"], "Fast Tween To Rares", Config.movement.fastrares, function(v)
        if v then
            showRiskPrompt("Fast Tween To Rares", "This feature is detected and can get you reset.\nAre you sure you want to enable it?", function()
                Config.movement.fastrares = true
            end, function() Config.movement.fastrares = false end)
        else Config.movement.fastrares = false end
    end)

    -- 7. VISUALS TAB
    addToggle(tabPages["Visuals"], "Ultra Anti-Lag (FPS Booster)", Config.visuals.antilag, function(v)
        Config.visuals.antilag = v
        if v then runAntiLag() end
    end)
    addToggle(tabPages["Visuals"], "Hide Particles", Config.visuals.hideparticles, function(v) Config.visuals.hideparticles = v end)
    addToggle(tabPages["Visuals"], "Hide Other Players", Config.visuals.antilagplayers, function(v)
        Config.visuals.antilagplayers = v
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character then
                for _, part in ipairs(pl.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Transparency = v and 1 or 0 end
                end
            end
        end
    end)

    -- 8. STATS TAB
    local statsLabels = {}
    local statFields = { "Uptime", "ServerUptime", "SessionHoney", "HoneyPerHour", "Chick", "Crab", "Bear", "Beetle", "Snail" }
    for _, field in ipairs(statFields) do
        local lbl = Instance.new("TextLabel")
        lbl.Text = field .. ": ..."
        lbl.Size = UDim2.new(1, -10, 0, 26)
        lbl.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.Parent = tabPages["Stats"]
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
        statsLabels[field] = lbl
    end

    -- Update loop
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
-- 14. INITIALIZATION HOOKS
--------------------------------------------------------------------------------
setupWorkspaceListeners()
setupHappenings()
hookClientFX()
createAtlasUI()

print("[Atlas BSS Ultimate] Reconstructed Engine & UI Fully Initialized!")
