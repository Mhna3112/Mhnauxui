--[[
    ═══════════════════════════════════════════════════════════════════════════
    ✨ ADVANCED AUTO FARM & KILL AURA DASHBOARD ✨
    Supports: Final Swarm & Dungeon Quest
    Features:
      • Multi-Tab Dark Modern Glassmorphism UI (Tabs, Neon Toggles, Sliders)
      • Smart Game Auto-Detection
      • Anti-Damage Flight Hovering (Adjustable Height, zero jitter, zero damage)
      • Strict Single-Target Lock (Finishes mob first)
      • Auto Collect Drops (Vacuum XP, Gems & Chests in workspace.VFX)
      • Instant Auto-Upgrade Selector (Picks level-up cards without pausing)
      • Auto Skip Wave
      • Noclip & Anti-AFK
      • Keybind: [F1] to Hide/Show UI
    ═══════════════════════════════════════════════════════════════════════════
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local VirtualInputManager
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

-- Configuration Table
local Config = {
    Enabled = true,
    AutoFarm = true,
    KillAura = true,
    InstantClick = true,            -- Instant Clicker engine
    ClickOnTargetOnly = false,      -- Clicks only when hovering target if true
    ClickCPS = 0,                   -- 0 = Instant / Max uncapped
    InternalOnly = true,            -- 100% in-game internal execution; DOES NOT touch Windows mouse/screen
    ClickTool = true,               -- Auto activate equipped weapon/tool (tool:Activate())
    ClickRemotes = true,            -- Auto fire attack and click remotes
    ClickDetectors = true,          -- Auto fire nearby ClickDetectors
    ClickMouse = false,             -- Physical mouse simulation (Keep false to never affect screen)
    HoverHeight = 11,               -- Studs above enemy
    ScanRange = 300,                -- Search radius (studs)
    AutoCollect = true,             -- Vacuum XP and chests
    CollectInterval = 1.2,          -- Seconds between drop sweep cycles
    AutoUpgrade = true,             -- Automatically select upgrade cards
    AutoSkipWave = true,            -- Automatically vote/skip wave
    Noclip = true,
    AntiAFK = true,
    ToggleKey = Enum.KeyCode.F1
}

-- Detect Game Mode
local GameMode = "Unknown"
if Workspace:FindFirstChild("Enemies") and ReplicatedStorage:FindFirstChild("Shared") then
    GameMode = "Final Swarm"
elseif Workspace:FindFirstChild("dungeon") or (ReplicatedStorage:FindFirstChild("remotes") and ReplicatedStorage.remotes:FindFirstChild("weaponUsed")) then
    GameMode = "Dungeon Quest"
else
    GameMode = "Generic RPG"
end

print(string.format("[AutoFarm] Game detected: %s (PlaceId: %d)", GameMode, game.PlaceId))

-- State
local State = {
    CurrentTarget = nil,
    EnemiesRemaining = 0,
    StatusMessage = "Idle",
    TotalClicks = 0,
    CurrentCPS = 0,
    ClicksInLastSecond = 0,
    LastCollectTime = 0,
    LastSkipCheck = 0,
    LastSwingTime = 0,
    LastUpgradeCheck = 0,
    Connections = {}
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🛡️ CORE UTILITIES & HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function getRootPart()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isTargetAlive(target)
    if not target or not target.model or not target.model.Parent then return false end
    if not target.humanoid or not target.humanoid.Parent or target.humanoid.Health <= 0 then return false end
    if not target.rootPart or not target.rootPart.Parent then return false end
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 👾 ENEMY DETECTION & TARGET LOCK
-- ═══════════════════════════════════════════════════════════════════════════

local function getAliveEnemies()
    local list = {}
    local myRoot = getRootPart()
    if not myRoot then return list end
    local myPos = myRoot.Position

    if GameMode == "Final Swarm" then
        local folder = Workspace:FindFirstChild("Enemies")
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Model") then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                    if hum and hum.Health > 0 and hrp then
                        local dist = (hrp.Position - myPos).Magnitude
                        if dist <= Config.ScanRange then
                            table.insert(list, {
                                model = obj,
                                humanoid = hum,
                                rootPart = hrp,
                                dist = dist,
                                name = obj.Name,
                                isBoss = obj.Name:lower():find("boss") ~= nil
                            })
                        end
                    end
                end
            end
        end
    elseif GameMode == "Dungeon Quest" then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Health > 0 then
                local model = obj.Parent
                if model and model ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(model) then
                    local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                    if hrp then
                        local dist = (hrp.Position - myPos).Magnitude
                        if dist <= Config.ScanRange then
                            table.insert(list, {
                                model = model,
                                humanoid = obj,
                                rootPart = hrp,
                                dist = dist,
                                name = model.Name,
                                isBoss = model.Name:lower():find("boss") ~= nil
                            })
                        end
                    end
                end
            end
        end
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Health > 0 and obj.Parent ~= LocalPlayer.Character then
                local model = obj.Parent
                if model and not Players:GetPlayerFromCharacter(model) then
                    local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                    if hrp then
                        local dist = (hrp.Position - myPos).Magnitude
                        if dist <= Config.ScanRange then
                            table.insert(list, {
                                model = model,
                                humanoid = obj,
                                rootPart = hrp,
                                dist = dist,
                                name = model.Name,
                                isBoss = false
                            })
                        end
                    end
                end
            end
        end
    end

    table.sort(list, function(a, b)
        if a.isBoss and not b.isBoss then return true end
        if b.isBoss and not a.isBoss then return false end
        return a.dist < b.dist
    end)

    return list
end

local function getLockedTarget()
    if State.CurrentTarget and isTargetAlive(State.CurrentTarget) then
        local myRoot = getRootPart()
        if myRoot then
            State.CurrentTarget.dist = (State.CurrentTarget.rootPart.Position - myRoot.Position).Magnitude
        end
        return State.CurrentTarget
    end

    local enemies = getAliveEnemies()
    State.EnemiesRemaining = #enemies
    if #enemies > 0 then
        State.CurrentTarget = enemies[1]
        return State.CurrentTarget
    end

    State.CurrentTarget = nil
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ⚔️ COMBAT & MULTI-VECTOR INSTANT CLICK ENGINE
-- ═══════════════════════════════════════════════════════════════════════════

local function fireTargetClick(screenPos)
    if Config.InternalOnly or not Config.ClickMouse then
        return
    end

    local x = screenPos and screenPos.X or (Camera.ViewportSize.X / 2)
    local y = screenPos and screenPos.Y or (Camera.ViewportSize.Y / 2)

    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end)
    end
end

local function triggerEquippedTool()
    local char = LocalPlayer.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
        if Config.ClickRemotes then
            for _, child in ipairs(tool:GetChildren()) do
                if child:IsA("RemoteEvent") then
                    pcall(function() child:FireServer() end)
                end
            end
        end
    end
end

local function triggerNearbyClickDetectors()
    local root = getRootPart()
    if not root or not fireclickdetector then return end
    local myPos = root.Position

    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("ClickDetector") then
            local p = desc.Parent
            if p and p:IsA("BasePart") and (p.Position - myPos).Magnitude <= (desc.MaxActivationDistance or 32) then
                pcall(function() fireclickdetector(desc, 0) end)
            end
        end
    end
end

local function executeSingleClick()
    local screenCoord = nil
    if State.CurrentTarget and State.CurrentTarget.rootPart then
        local wvp, onScreen = Camera:WorldToViewportPoint(State.CurrentTarget.rootPart.Position)
        if onScreen then
            screenCoord = Vector2.new(wvp.X, wvp.Y)
        end
    end

    if Config.ClickTool then
        triggerEquippedTool()
    end

    if Config.ClickMouse then
        fireTargetClick(screenCoord)
    end

    if Config.ClickDetectors then
        triggerNearbyClickDetectors()
    end

    State.TotalClicks = State.TotalClicks + 1
    State.ClicksInLastSecond = State.ClicksInLastSecond + 1
end

-- Live CPS Tracker
task.spawn(function()
    while true do
        task.wait(1)
        State.CurrentCPS = State.ClicksInLastSecond
        State.ClicksInLastSecond = 0
    end
end)

-- Dedicated Instant Click Thread
task.spawn(function()
    while true do
        if Config.Enabled and Config.InstantClick then
            local canClick = true
            if Config.ClickOnTargetOnly and (not State.CurrentTarget or not isTargetAlive(State.CurrentTarget)) then
                canClick = false
            end

            if canClick then
                if Config.ClickCPS <= 0 then
                    executeSingleClick()
                    executeSingleClick()
                    RunService.Heartbeat:Wait()
                else
                    local interval = 1 / math.clamp(Config.ClickCPS, 1, 300)
                    executeSingleClick()
                    task.wait(interval)
                end
            else
                task.wait(0.05)
            end
        else
            task.wait(0.1)
        end
    end
end)

local function performAttack(target)
    if not Config.KillAura or not target then return end

    if GameMode == "Dungeon Quest" then
        local now = os.clock()
        if now - State.LastSwingTime < 0.08 then return end

        local char = LocalPlayer.Character
        if not char then return end

        local weapon = nil
        for _, child in pairs(char:GetChildren()) do
            if child:IsA("Accessory") and child:FindFirstChild("Weapon") then
                weapon = child
                break
            end
        end

        local remotes = ReplicatedStorage:FindFirstChild("remotes")
        local weaponUsed = remotes and remotes:FindFirstChild("weaponUsed")

        if weapon then
            local hitBox = weapon:FindFirstChild("hitBox")
            local remote = weapon:FindFirstChildOfClass("RemoteEvent")

            if hitBox and remote and target.rootPart then
                local origCF = hitBox.CFrame
                hitBox.CFrame = target.rootPart.CFrame
                remote:FireServer()
                if weaponUsed then weaponUsed:FireServer() end
                task.delay(0.04, function()
                    if hitBox and hitBox.Parent then
                        hitBox.CFrame = origCF
                    end
                end)
            elseif remote then
                remote:FireServer()
                if weaponUsed then weaponUsed:FireServer() end
            end
        end
        State.LastSwingTime = now
    else
        -- Universal attack fallback for Generic RPGs & Final Swarm
        executeSingleClick()
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 💎 AUTO COLLECT DROPS (XP & CHESTS)
-- ═══════════════════════════════════════════════════════════════════════════

local function sweepCollectDrops()
    if not Config.AutoCollect or GameMode ~= "Final Swarm" then return end
    local now = os.clock()
    if now - State.LastCollectTime < Config.CollectInterval then return end

    local vfx = Workspace:FindFirstChild("VFX")
    local myRoot = getRootPart()
    if not vfx or not myRoot then return end

    local drops = {}
    for _, item in ipairs(vfx:GetChildren()) do
        if item.Name == "xp" or item.Name:find("Chest") or item.Name:find("Gem") or item.Name:find("Coin") then
            local pivot = item:GetPivot()
            local dist = (pivot.Position - myRoot.Position).Magnitude
            if dist < 250 then
                table.insert(drops, {item = item, pos = pivot.Position, dist = dist})
            end
        end
    end

    if #drops > 0 then
        table.sort(drops, function(a, b) return a.dist < b.dist end)
        State.StatusMessage = string.format("Vacuuming %d drops...", #drops)

        local origCFrame = myRoot.CFrame
        local maxSweep = math.min(#drops, 8)
        task.spawn(function()
            for i = 1, maxSweep do
                local d = drops[i]
                if d.item and d.item.Parent and myRoot and myRoot.Parent then
                    myRoot.CFrame = CFrame.new(d.pos + Vector3.new(0, 1.5, 0))
                    task.wait(0.04)
                end
            end
            if myRoot and myRoot.Parent then
                myRoot.CFrame = origCFrame
            end
        end)
    end

    State.LastCollectTime = now
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎴 AUTO UPGRADE CARD PICKER
-- ═══════════════════════════════════════════════════════════════════════════

local function handleAutoUpgrade()
    if not Config.AutoUpgrade then return end
    local now = os.clock()
    if now - State.LastUpgradeCheck < 0.25 then return end
    State.LastUpgradeCheck = now

    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pgui then return end

    local frames = pgui:FindFirstChild("Frames")
    local upgrades = frames and frames:FindFirstChild("Upgrades")
    if not upgrades or not upgrades.Visible then return end

    local holder = upgrades:FindFirstChild("Holder")
    if not holder then return end

    for i = 1, 5 do
        local btn = holder:FindFirstChild("Selection" .. i)
        if btn and btn:IsA("ImageButton") and btn.Visible then
            pcall(function()
                if getconnections then
                    for _, c in ipairs(getconnections(btn.MouseButton1Down)) do c:Fire() end
                    task.wait(0.03)
                    for _, c in ipairs(getconnections(btn.MouseButton1Up)) do c:Fire() end
                end
            end)
            State.StatusMessage = "Selected Upgrade #" .. i
            break
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ⏭️ AUTO SKIP WAVE
-- ═══════════════════════════════════════════════════════════════════════════

local function handleAutoSkipWave()
    if not Config.AutoSkipWave then return end
    local now = os.clock()
    if now - State.LastSkipCheck < 1.5 then return end
    State.LastSkipCheck = now

    pcall(function()
        if GameMode == "Final Swarm" then
            local esc = require(ReplicatedStorage.Shared.Services.EnemyService.EnemyServiceClient)
            if esc and esc.RequestSkipVote then
                esc:RequestSkipVote()
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🛡️ ANTI-AFK & NOCLIP
-- ═══════════════════════════════════════════════════════════════════════════

if getconnections then
    for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
        if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
    end
end

LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function()
            VirtualUser:Button2Down(Vector2.zero, Camera.CFrame)
            task.wait(0.05)
            VirtualUser:Button2Up(Vector2.zero, Camera.CFrame)
        end)
    end
end)

RunService.Stepped:Connect(function()
    if Config.Noclip and Config.Enabled and Config.AutoFarm then
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
-- 🛸 MAIN FARM & HOVER ENGINE
-- ═══════════════════════════════════════════════════════════════════════════

State.Connections.MainLoop = RunService.Heartbeat:Connect(function()
    handleAutoUpgrade()
    handleAutoSkipWave()

    if not Config.Enabled or not Config.AutoFarm then
        local hum = getHumanoid()
        if hum and hum.PlatformStand then
            hum.PlatformStand = false
        end
        State.StatusMessage = "Farm Paused"
        return
    end

    local myRoot = getRootPart()
    local hum = getHumanoid()
    if not myRoot or not hum or hum.Health <= 0 then
        State.StatusMessage = "Waiting for Respawn"
        return
    end

    local target = getLockedTarget()

    if target and isTargetAlive(target) then
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero

        if not hum.PlatformStand then
            hum.PlatformStand = true
        end

        local targetPos = target.rootPart.Position
        local hoverPos = targetPos + Vector3.new(0, Config.HoverHeight, 0)

        myRoot.CFrame = CFrame.lookAt(hoverPos, targetPos, Vector3.new(0, 0, -1))
        State.StatusMessage = string.format("Farming %s (HP: %.0f)", target.name, target.humanoid.Health)

        performAttack(target)
    else
        if hum.PlatformStand then
            hum.PlatformStand = false
        end
        State.StatusMessage = "Scanning for Mobs..."
        sweepCollectDrops()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎨 COMPLETE MULTI-TAB MODERN GLASSMORPHISM UI DASHBOARD
-- ═══════════════════════════════════════════════════════════════════════════

local GUI_NAME = "AutoFarmProDashboard"
local oldGui = CoreGui:FindFirstChild(GUI_NAME) or LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(GUI_NAME)
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Main Container Frame
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 560, 0, 360)
Main.Position = UDim2.new(0.5, -280, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(35, 38, 50)
MainStroke.Thickness = 1.2
MainStroke.Parent = Main

-- Top Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "⚡ AUTOFARM HUB PRO"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(0, 200, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local GameBadge = Instance.new("TextLabel")
GameBadge.Text = GameMode
GameBadge.Font = Enum.Font.GothamBold
GameBadge.TextSize = 10
GameBadge.TextColor3 = Color3.fromRGB(0, 180, 255)
GameBadge.BackgroundColor3 = Color3.fromRGB(18, 38, 60)
GameBadge.Size = UDim2.new(0, 95, 0, 20)
GameBadge.Position = UDim2.new(0, 180, 0.5, -10)
GameBadge.BorderSizePixel = 0
GameBadge.Parent = TitleBar
local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(0, 5)
BadgeCorner.Parent = GameBadge

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(160, 160, 175)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -12)
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

-- Make Window Draggable
local isDragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then isDragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Sidebar
local SideBar = Instance.new("Frame")
SideBar.Name = "SideBar"
SideBar.Size = UDim2.new(0, 135, 1, -38)
SideBar.Position = UDim2.new(0, 0, 0, 38)
SideBar.BackgroundColor3 = Color3.fromRGB(17, 18, 25)
SideBar.BorderSizePixel = 0
SideBar.Parent = Main

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 6)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = SideBar

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 10)
SidePadding.PaddingLeft = UDim.new(0, 8)
SidePadding.PaddingRight = UDim.new(0, 8)
SidePadding.Parent = SideBar

local VerticalDivider = Instance.new("Frame")
VerticalDivider.Size = UDim2.new(0, 1, 1, -38)
VerticalDivider.Position = UDim2.new(0, 135, 0, 38)
VerticalDivider.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
VerticalDivider.BorderSizePixel = 0
VerticalDivider.Parent = Main

-- Content Container
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -145, 1, -44)
ContentArea.Position = UDim2.new(0, 142, 0, 42)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.Parent = Main

local Tabs = {}
local TabButtons = {}

local function createTab(tabName, iconText)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = tabName .. "Page"
    scroll.Size = UDim2.new(1, -6, 1, -6)
    scroll.Position = UDim2.new(0, 2, 0, 4)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(50, 54, 70)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 480)
    scroll.Visible = false
    scroll.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local btn = Instance.new("TextButton")
    btn.Name = tabName .. "Tab"
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamMedium
    btn.Text = " " .. iconText .. "  " .. tabName
    btn.TextColor3 = Color3.fromRGB(150, 155, 170)
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = SideBar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(28, 30, 40)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.Visible = false end
        for _, b in pairs(TabButtons) do
            b.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
            b.TextColor3 = Color3.fromRGB(150, 155, 170)
            b:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(28, 30, 40)
        end
        scroll.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(28, 32, 45)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnStroke.Color = Color3.fromRGB(0, 162, 255)
    end)

    table.insert(TabButtons, btn)
    Tabs[tabName] = scroll
    return scroll
end

-- Component Builders
local function addSectionHeader(parent, text)
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, -10, 0, 24)
    headerFrame.BackgroundTransparency = 1
    headerFrame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Color3.fromRGB(0, 180, 255)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = headerFrame

    local underline = Instance.new("Frame")
    underline.Size = UDim2.new(1, 0, 0, 1)
    underline.Position = UDim2.new(0, 0, 1, -2)
    underline.BackgroundColor3 = Color3.fromRGB(35, 38, 50)
    underline.BorderSizePixel = 0
    underline.Parent = headerFrame

    return headerFrame
end

local function addToggleRow(parent, configKey, title, defaultState, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -10, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(19, 21, 29)
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color = Color3.fromRGB(28, 31, 42)
    rowStroke.Thickness = 1
    rowStroke.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -65, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = title
    label.TextColor3 = Color3.fromRGB(225, 225, 230)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 42, 0, 20)
    switch.Position = UDim2.new(1, -54, 0.5, -10)
    switch.BackgroundColor3 = defaultState and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(35, 38, 48)
    switch.BorderSizePixel = 0
    switch.Text = ""
    switch.Parent = row

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(1, 0)
    sCorner.Parent = switch

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = defaultState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switch

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

    local state = defaultState
    switch.MouseButton1Click:Connect(function()
        state = not state
        Config[configKey] = state
        TweenService:Create(switch, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = state and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(35, 38, 48)
        }):Play()

        knob:TweenPosition(
            state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.18,
            true
        )
        if callback then callback(state) end
    end)

    return row
end

local function addSliderRow(parent, configKey, title, minVal, maxVal, defaultVal, suffix, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(19, 21, 29)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(28, 31, 42)
    stroke.Thickness = 1
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = title
    label.TextColor3 = Color3.fromRGB(225, 225, 230)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valLabel.Position = UDim2.new(0.7, -12, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Font = Enum.Font.GothamBold
    valLabel.Text = tostring(defaultVal) .. suffix
    valLabel.TextColor3 = Color3.fromRGB(0, 162, 255)
    valLabel.TextSize = 11
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 5)
    track.Position = UDim2.new(0, 12, 0, 31)
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
    local function updateSlide(input)
        local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        local value
        if suffix == "s" then
            value = math.floor((minVal + (maxVal - minVal) * relX) * 10) / 10
        else
            value = math.floor(minVal + (maxVal - minVal) * relX)
        end
        valLabel.Text = tostring(value) .. suffix
        Config[configKey] = value
        if callback then callback(value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateSlide(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlide(input)
        end
    end)

    return frame
end

local function addCard(parent, title, content)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(19, 21, 29)
    card.BorderSizePixel = 0
    card.Parent = parent

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent = card

    local cStroke = Instance.new("UIStroke")
    cStroke.Color = Color3.fromRGB(28, 31, 42)
    cStroke.Thickness = 1
    cStroke.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text = title
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 10
    titleLbl.TextColor3 = Color3.fromRGB(150, 155, 170)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size = UDim2.new(1, -20, 0, 16)
    titleLbl.Position = UDim2.new(0, 12, 0, 6)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    local valLbl = Instance.new("TextLabel")
    valLbl.Name = "ValueLabel"
    valLbl.Text = content
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
    valLbl.BackgroundTransparency = 1
    valLbl.Size = UDim2.new(1, -20, 0, 22)
    valLbl.Position = UDim2.new(0, 12, 0, 24)
    valLbl.TextXAlignment = Enum.TextXAlignment.Left
    valLbl.Parent = card

    return card, valLbl
end

-- Initialize Tabs
local AutoFarmTab = createTab("Auto Farm", "🔥")
local InstantClickTab = createTab("Instant Click", "⚡")
local CombatTab = createTab("Combat", "⚔️")
local PlayerTab = createTab("Player", "👤")
local StatusTab = createTab("Dashboard", "📊")

-- TAB 1: AUTO FARM
addSectionHeader(AutoFarmTab, "FARMING AUTOMATION")
addToggleRow(AutoFarmTab, "AutoFarm", "Auto Farm (Hovering Flight)", Config.AutoFarm, function(val) Config.AutoFarm = val end)
addToggleRow(AutoFarmTab, "KillAura", "Kill Aura Attacks", Config.KillAura, function(val) Config.KillAura = val end)
addToggleRow(AutoFarmTab, "AutoCollect", "Auto Collect Drops (XP / Chests)", Config.AutoCollect, function(val) Config.AutoCollect = val end)
addToggleRow(AutoFarmTab, "AutoUpgrade", "Auto Upgrade Cards (Instant)", Config.AutoUpgrade, function(val) Config.AutoUpgrade = val end)
addToggleRow(AutoFarmTab, "AutoSkipWave", "Auto Skip Waves", Config.AutoSkipWave, function(val) Config.AutoSkipWave = val end)

-- TAB 2: INSTANT CLICK
addSectionHeader(InstantClickTab, "INSTANT CLICK ENGINE")
addToggleRow(InstantClickTab, "InstantClick", "Enable Instant Clicker", Config.InstantClick, function(val) Config.InstantClick = val end)
addToggleRow(InstantClickTab, "ClickOnTargetOnly", "Only Click When Locked On Target", Config.ClickOnTargetOnly, function(val) Config.ClickOnTargetOnly = val end)
addSliderRow(InstantClickTab, "ClickCPS", "Click Speed / CPS (0 = Max Instant)", 0, 150, Config.ClickCPS, " CPS", function(val) Config.ClickCPS = val end)
addSectionHeader(InstantClickTab, "CLICK METHODS & HOOKS")
addToggleRow(InstantClickTab, "ClickTool", "Auto Activate Weapon / Tool", Config.ClickTool, function(val) Config.ClickTool = val end)
addToggleRow(InstantClickTab, "ClickMouse", "Virtual Mouse Left-Click", Config.ClickMouse, function(val) Config.ClickMouse = val end)
addToggleRow(InstantClickTab, "ClickDetectors", "Auto Fire ClickDetectors", Config.ClickDetectors, function(val) Config.ClickDetectors = val end)

-- TAB 3: COMBAT SETTINGS
addSectionHeader(CombatTab, "HOVER & TARGETING CONFIG")
addSliderRow(CombatTab, "HoverHeight", "Hover Height Above Mobs", 4, 25, Config.HoverHeight, " studs", function(val) Config.HoverHeight = val end)
addSliderRow(CombatTab, "ScanRange", "Enemy Search Radius", 50, 500, Config.ScanRange, " studs", function(val) Config.ScanRange = val end)
addSliderRow(CombatTab, "CollectInterval", "Drop Vacuum Interval", 0.5, 3.0, Config.CollectInterval, "s", function(val) Config.CollectInterval = val end)

-- TAB 4: PLAYER SETTINGS
addSectionHeader(PlayerTab, "PLAYER SAFEGUARDS")
addToggleRow(PlayerTab, "Noclip", "Noclip (Walk Through Objects)", Config.Noclip, function(val) Config.Noclip = val end)
addToggleRow(PlayerTab, "AntiAFK", "Anti-AFK Protection", Config.AntiAFK, function(val) Config.AntiAFK = val end)

-- TAB 5: DASHBOARD & LIVE STATS
addSectionHeader(StatusTab, "REAL-TIME MONITOR")
local _, liveTargetLbl = addCard(StatusTab, "CURRENT LOCKED TARGET", "Target: None")
local _, liveCpsLbl = addCard(StatusTab, "LIVE CLICKS PER SECOND", "0 CPS")
local _, liveClicksLbl = addCard(StatusTab, "TOTAL CLICKS DELIVERED", "0 Clicks")
local _, liveEnemyCountLbl = addCard(StatusTab, "ENEMIES REMAINING", "0 Mobs")
local _, liveStatusLbl = addCard(StatusTab, "FARM ENGINE STATUS", "Active")

-- Bottom Status Bar
local BottomBar = Instance.new("Frame")
BottomBar.Size = UDim2.new(1, 0, 0, 22)
BottomBar.Position = UDim2.new(0, 0, 1, -22)
BottomBar.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
BottomBar.BorderSizePixel = 0
BottomBar.Parent = Main

local HintText = Instance.new("TextLabel")
HintText.Text = "Press [F1] to Hide / Show UI"
HintText.Font = Enum.Font.Gotham
HintText.TextSize = 10
HintText.TextColor3 = Color3.fromRGB(110, 115, 130)
HintText.BackgroundTransparency = 1
HintText.Size = UDim2.new(1, 0, 1, 0)
HintText.TextXAlignment = Enum.TextXAlignment.Center
HintText.Parent = BottomBar

-- Live Updates
RunService.RenderStepped:Connect(function()
    if not ScreenGui.Parent or not Main.Visible then return end
    local target = State.CurrentTarget
    if target and isTargetAlive(target) then
        local hp = target.humanoid and target.humanoid.Health or 0
        local maxHp = target.humanoid and target.humanoid.MaxHealth or 100
        liveTargetLbl.Text = string.format("%s (%.0f / %.0f HP)", target.name, hp, maxHp)
    else
        liveTargetLbl.Text = "None (Searching...)"
    end
    liveCpsLbl.Text = string.format("%d CPS", State.CurrentCPS)
    liveClicksLbl.Text = string.format("%s Clicks", tostring(State.TotalClicks))
    liveEnemyCountLbl.Text = string.format("%d Enemies in Range", State.EnemiesRemaining)
    liveStatusLbl.Text = State.StatusMessage
end)

-- Toggle UI with Keybind
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.ToggleKey then
        Main.Visible = not Main.Visible
    end
end)

-- Default to first tab
TabButtons[1].MouseButton1Click:Fire()

print("[AutoFarm Pro] Loaded successfully! Press F1 to toggle Dashboard.")