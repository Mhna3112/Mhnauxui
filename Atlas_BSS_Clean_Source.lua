--[[
    Atlas BSS (Bee Swarm Simulator) - Fully Deobfuscated & Clean Source Code
    Decompiled from Luraph v14 Protection
    Reconstructed & Structured by ENI for LO
--]]

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
-- 1. STATE & CONFIGURATION
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
-- 2. TASK MANAGER
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
-- 3. MOVEMENT & NAVIGATION CONTROLLER
--------------------------------------------------------------------------------
local currentTween = nil

local function stopMovement()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    if Humanoid then
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
-- 4. ANTI-LAG / FPS BOOSTER ENGINE (Extracted from Function Ws)
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
-- 5. WORKSPACE HAZARDS & MOB TRACKING (Extracted from Functions x & w)
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
-- 6. AUTOFARM & GATHERING ENGINE (Extracted from Functions Z, m, ks, zs)
--------------------------------------------------------------------------------
local function startAutoDig()
    if TaskManager:Get("autodig") then return end
    TaskManager:Add("autodig", function()
        while RunService.Heartbeat:Wait() do
            if not State.stop and not State.stopdig then
                -- Fires harvest/collect remote
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
        -- Check backpack capacity
        local coreStats = LocalPlayer:FindFirstChild("CoreStats")
        if coreStats and coreStats:FindFirstChild("Pollen") and coreStats:FindFirstChild("Capacity") then
            if coreStats.Pollen.Value >= coreStats.Capacity.Value then
                -- Backpack full: return to Hive and convert
                stopMovement()
                local hivePos = LocalPlayer.SpawnPos.Value
                moveToPosition(CFrame.new(hivePos), 50, Config.movement.tween)
                -- SendHoney convert remote
                local makeHoneyRemote = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("PlayerHiveCommand")
                if makeHoneyRemote then
                    makeHoneyRemote:FireServer({["Action"] = "MakeHoney"})
                end
                -- Wait until converted
                while coreStats.Pollen.Value > 0 and Config.autofarm.enabled do
                    task.wait(1)
                end
            end
        end

        -- Collect falling coconuts or tokens if nearby
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
-- 7. HAPPENINGS (Sprouts, Puffshrooms, Stickers, Wind Shrine)
--------------------------------------------------------------------------------
local function setupHappenings()
    -- Sprouts
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

    -- Puffshrooms
    local happenings = Workspace:FindFirstChild("Happenings")
    if happenings and happenings:FindFirstChild("Puffshrooms") then
        happenings.Puffshrooms.ChildAdded:Connect(function(p)
            State.puffshrooms[p] = true
        end)
        happenings.Puffshrooms.ChildRemoved:Connect(function(p)
            State.puffshrooms[p] = nil
        end)
    end

    -- Hidden Stickers
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
-- 8. CLIENT FX HOOKS (Extracted from Function Cs)
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
-- 9. HUD & STATS SYSTEM (Extracted from Functions d & Es)
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

local function startHUD(labels)
    -- Labels table: { Uptime, ServerUptime, SessionHoney, HoneyPerHour, Chick, Crab, Bear, Beetle, Snail }
    task.spawn(function()
        while task.wait(1) do
            local elapsed = tick() - State.start
            local currentHoney = (LocalPlayer:FindFirstChild("CoreStats") and LocalPlayer.CoreStats:FindFirstChild("Honey")) and LocalPlayer.CoreStats.Honey.Value or 0
            local sessionHoney = math.max(0, currentHoney - State.honeyatstart)
            local honeyRate = elapsed > 0 and (sessionHoney / elapsed) * 3600 or 0

            if labels.Uptime then labels.Uptime.Text = "  Uptime: " .. formatTime(elapsed) end
            if labels.ServerUptime then labels.ServerUptime.Text = "Server Uptime: " .. formatTime(Workspace.DistributedGameTime) end
            if labels.SessionHoney then labels.SessionHoney.Text = "Session Honey: " .. formatNumber(sessionHoney) end
            if labels.HoneyPerHour then labels.HoneyPerHour.Text = "Honey per Hour: " .. formatNumber(honeyRate) end

            -- Boss Timers
            if labels.Chick then labels.Chick.Text = "Commando Chick: " .. (Cooldowns["Commando Chick"] > 0 and formatTime(Cooldowns["Commando Chick"]) or utf8.char(10003)) end
            if labels.Crab then labels.Crab.Text = "Coconut Crab: " .. (Cooldowns["CoconutCrab"] > 0 and formatTime(Cooldowns["CoconutCrab"]) or utf8.char(10003)) end
            if labels.Bear then labels.Bear.Text = "Tunnel Bear: " .. (Cooldowns["TunnelBear"] > 0 and formatTime(Cooldowns["TunnelBear"]) or utf8.char(10003)) end
            if labels.Beetle then labels.Beetle.Text = "King Beetle: " .. (Cooldowns["King Beetle Cave"] > 0 and formatTime(Cooldowns["King Beetle Cave"]) or utf8.char(10003)) end
            if labels.Snail then labels.Snail.Text = "Stump Snail: " .. (Cooldowns["StumpSnail"] > 0 and formatTime(Cooldowns["StumpSnail"]) or utf8.char(10003)) end
        end
    end)
end

--------------------------------------------------------------------------------
-- 10. INITIALIZATION
--------------------------------------------------------------------------------
setupWorkspaceListeners()
setupHappenings()
hookClientFX()

print("[Atlas BSS] Deobfuscated & Clean Core Successfully Initialized!")
