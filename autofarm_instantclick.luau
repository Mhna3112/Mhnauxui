--[[
    ═══════════════════════════════════════════════════════════════════════════
    ✨ UNBOXING SIMULATOR & UNIVERSAL AUTO FARM PRO (V3) ✨
    ═══════════════════════════════════════════════════════════════════════════
    Features:
      • Manual Click-to-Target: Click ANY box to instantly prioritize and smash it!
      • Free WASD Movement: Move freely to eggs, shops, and portals without rubberbanding
      • Non-Intrusive Floating Mini-UI (Draggable, Minimizable, F1 hotkey)
      • Server-Paced Attack Engine: 0 rate-limit rejections, 0 height errors
      • 100% In-Game Only: Zero desktop cursor disruption
    ═══════════════════════════════════════════════════════════════════════════
]]

-- 1. CLEANUP PREVIOUS SCRIPT INSTANCES
local MyToken = os.clock()
_G.AutoFarm_Token = MyToken

if _G.AutoFarm_Cleanup and type(_G.AutoFarm_Cleanup) == "function" then
    pcall(_G.AutoFarm_Cleanup)
end

local cleanupTasks = {}
_G.AutoFarm_Cleanup = function()
    for _, fn in ipairs(cleanupTasks) do
        pcall(fn)
    end
    cleanupTasks = {}
end

-- Disconnect any lingering custom RunService connections
pcall(function()
    for _, conn in ipairs(getconnections(game:GetService("RunService").Heartbeat)) do
        if conn.Function then
            local src = debug.info(conn.Function, "s")
            if src and (string.find(src:lower(), "auto") or string.find(src:lower(), "instant") or src == "") then
                conn:Disconnect()
            end
        end
    end
end)

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- DETECT GAME ENVIRONMENT
local IsUnboxingSimulator = false
local Unboxing = {}
pcall(function()
    if ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Remotes") and ReplicatedStorage.Modules.Remotes:FindFirstChild("Boxes") then
        IsUnboxingSimulator = true
        Unboxing.Boxes = require(ReplicatedStorage.Modules.Remotes.Boxes)
        Unboxing.BoxController = require(ReplicatedStorage.Controllers.BoxController)
        Unboxing.Clock = require(ReplicatedStorage.Shared.Clock)
        Unboxing.Validation = require(ReplicatedStorage.Shared.BoxAttackValidation)
    end
end)

-- CONFIGURATION
local Config = {
    AutoFarmEnabled = true,
    AttackRate = 0.16,              -- Tuned to safely stay under server's 24 hits / 3s limit (0 rejections)
    StandDistance = 6.5,            -- Distance from box on the ground (keeps feet on ground)
    ScanRadius = 400,               -- Search radius for boxes
    AllowFreeWalk = true,           -- When pressing WASD, pauses teleport so you can walk freely
    AutoSwitchTarget = true,        -- Automatically target next closest box when target dies
    Noclip = true,
    AntiAFK = true,
    ToggleKey = Enum.KeyCode.F1
}

-- RUNTIME STATE
local State = {
    CurrentTarget = nil,
    ManualTarget = nil,             -- If user clicked a specific box
    ManualTargetLockTime = 0,
    TotalHits = 0,
    TotalSmashed = 0,
    HitsInLastSec = 0,
    CurrentCPS = 0,
    BoxesInField = 0,
    StatusMessage = "Idle",
    IsMoving = false
}

-- CHARACTER UTILITIES
local function getRootPart()
    local char = LocalPlayer.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎯 CLICK-TO-TARGET (HOOK NATIVE TARGETING SO USER CAN CLICK ANY BOX)
-- ═══════════════════════════════════════════════════════════════════════════

if IsUnboxingSimulator and Unboxing.BoxController then
    pcall(function()
        local uvs = getupvalues(Unboxing.BoxController.OnStart)
        local nativeSetTarget = uvs and uvs[31]
        if nativeSetTarget and hookfunction then
            local origSetTarget
            origSetTarget = hookfunction(nativeSetTarget, function(box, p2)
                if box and box.Id and box.Health and (box.Health - (box.Damage or 0) > 0) then
                    State.ManualTarget = {
                        box = box,
                        pos = box.CFrame.Position,
                        height = box.Height or 4,
                        hp = box.Health - (box.Damage or 0),
                        maxHp = box.Health,
                        id = box.Id
                    }
                    State.ManualTargetLockTime = os.clock()
                    State.CurrentTarget = State.ManualTarget
                    State.StatusMessage = string.format("Focused Box #%s (Manual Click)", tostring(box.Id))
                end
                return origSetTarget(box, p2)
            end)
            table.insert(cleanupTasks, function()
                pcall(hookfunction, nativeSetTarget, origSetTarget)
            end)
        end
    end)
end

-- TARGET FINDER
local function getBestBox()
    local root = getRootPart()
    if not root then return nil end
    local myPos = root.Position

    -- If user recently clicked a box manually, prioritize that box
    if State.ManualTarget and State.ManualTarget.box then
        local mBox = State.ManualTarget.box
        local remHp = mBox.Health - (mBox.Damage or 0)
        if remHp > 0 and not mBox.IsDestroyed and not mBox.IsOpen then
            return State.ManualTarget
        else
            State.ManualTarget = nil
        end
    end

    if IsUnboxingSimulator and Unboxing.BoxController then
        local curField = nil
        pcall(function()
            curField = Unboxing.BoxController.GetCurrentField(myPos)
        end)

        local candidates = {}
        if curField and curField.Boxes then
            for id, box in pairs(curField.Boxes) do
                if box and box.CFrame and not box.IsOpen and not box.IsDestroyed then
                    local remHp = box.Health - (box.Damage or 0)
                    if remHp > 0 then
                        local dist = (box.CFrame.Position - myPos).Magnitude
                        if dist <= Config.ScanRadius then
                            table.insert(candidates, {
                                box = box,
                                pos = box.CFrame.Position,
                                dist = dist,
                                height = box.Height or 4,
                                hp = remHp,
                                maxHp = box.Health,
                                id = box.Id
                            })
                        end
                    end
                end
            end
        end

        State.BoxesInField = #candidates
        if #candidates > 0 then
            table.sort(candidates, function(a, b) return a.dist < b.dist end)
            return candidates[1]
        end
    else
        -- Universal Mobs fallback
        local candidates = {}
        local myChar = LocalPlayer.Character
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("Humanoid") and desc.Health > 0 and desc.Parent ~= myChar then
                local m = desc.Parent
                if m and m:IsA("Model") and not Players:GetPlayerFromCharacter(m) then
                    local hrp = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                    if hrp then
                        local dist = (hrp.Position - myPos).Magnitude
                        if dist <= Config.ScanRadius then
                            table.insert(candidates, {
                                humanoid = desc,
                                model = m,
                                rootPart = hrp,
                                pos = hrp.Position,
                                dist = dist,
                                hp = desc.Health,
                                maxHp = desc.MaxHealth,
                                id = m.Name
                            })
                        end
                    end
                end
            end
        end
        State.BoxesInField = #candidates
        if #candidates > 0 then
            table.sort(candidates, function(a, b) return a.dist < b.dist end)
            return candidates[1]
        end
    end

    return nil
end

-- CPS TRACKER
task.spawn(function()
    while _G.AutoFarm_Token == MyToken do
        task.wait(1)
        State.CurrentCPS = State.HitsInLastSec
        State.HitsInLastSec = 0
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 🛸 MAIN FARM & AUTO SMASH LOOP
-- ═══════════════════════════════════════════════════════════════════════════

task.spawn(function()
    local lastAttack = 0

    while _G.AutoFarm_Token == MyToken do
        if Config.AutoFarmEnabled then
            local char = LocalPlayer.Character
            local root = getRootPart()
            local hum = getHumanoid()

            if char and root and hum and hum.Health > 0 then
                -- Check if user is actively walking with WASD or mobile stick
                local isMoving = (hum.MoveDirection.Magnitude > 0.1)
                State.IsMoving = isMoving

                -- Target Validation
                local target = State.CurrentTarget
                local isValid = false

                if target then
                    if IsUnboxingSimulator and target.box then
                        isValid = (not target.box.IsDestroyed and not target.box.IsOpen and (target.box.Health - (target.box.Damage or 0) > 0))
                    elseif target.humanoid then
                        isValid = (target.humanoid.Parent and target.humanoid.Health > 0)
                    end
                end

                if not isValid then
                    if target and State.TotalHits > 0 then
                        State.TotalSmashed = State.TotalSmashed + 1
                    end
                    State.CurrentTarget = getBestBox()
                    target = State.CurrentTarget
                end

                if target then
                    -- If user is holding WASD to walk to eggs, shop, or portals, don't freeze or teleport!
                    if not (Config.AllowFreeWalk and isMoving) then
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero

                        if IsUnboxingSimulator and target.box then
                            local box = target.box
                            local boxPos = box.CFrame.Position
                            local boxH = target.height
                            local v15 = boxH / 2
                            local v13 = root.Size.Y / 2 + hum.HipHeight

                            -- Position character standing firmly on the ground next to the box
                            local targetY = boxPos.Y + v15 + v13
                            local standPos = Vector3.new(boxPos.X + Config.StandDistance, targetY, boxPos.Z)

                            root.CFrame = CFrame.lookAt(standPos, Vector3.new(boxPos.X, targetY, boxPos.Z))
                        else
                            -- Universal mode
                            local standPos = target.pos + Vector3.new(0, 3, 0)
                            root.CFrame = CFrame.lookAt(standPos, target.pos)
                        end
                    end

                    -- Attack Execution (Only attacks when within valid striking distance)
                    local boxPos = target.pos or (target.box and target.box.CFrame.Position)
                    local distToBox = boxPos and (boxPos - root.Position).Magnitude or 999

                    if distToBox <= 28 then
                        local now = os.clock()
                        if now - lastAttack >= Config.AttackRate then
                            if IsUnboxingSimulator and target.box then
                                local box = target.box
                                local cNow = Unboxing.Clock.now()
                                local dmg = box:GetDamage()
                                box:TakeDamage(dmg, cNow)
                                Unboxing.Boxes.AttackBox.Fire(box.Field.Id, box.Id, cNow)
                                Unboxing.Boxes.SendEvents()

                                State.TotalHits = State.TotalHits + 1
                                State.HitsInLastSec = State.HitsInLastSec + 1
                                lastAttack = now

                                if (box.Health - (box.Damage or 0) <= 0) then
                                    State.TotalSmashed = State.TotalSmashed + 1
                                    State.CurrentTarget = nil
                                    State.ManualTarget = nil
                                end

                                local remHp = math.max(0, box.Health - (box.Damage or 0))
                                State.StatusMessage = string.format("Smashing Box #%s (%.0f HP)", tostring(box.Id), remHp)
                            else
                                local tool = char:FindFirstChildOfClass("Tool")
                                if tool then pcall(function() tool:Activate() end) end

                                State.TotalHits = State.TotalHits + 1
                                State.HitsInLastSec = State.HitsInLastSec + 1
                                lastAttack = now
                                State.StatusMessage = string.format("Attacking %s", tostring(target.id))
                            end
                        end
                    else
                        State.StatusMessage = isMoving and "Walking freely..." or "Approaching target..."
                    end
                else
                    State.StatusMessage = isMoving and "Walking freely..." or "Searching for boxes..."
                end
            end
        else
            State.StatusMessage = "Auto Farm Paused"
        end

        task.wait(0.03)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 🛡️ SAFEGUARDS: NOCLIP & ANTI-AFK
-- ═══════════════════════════════════════════════════════════════════════════

if getconnections then
    pcall(function()
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
            if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
        end
    end)
end

RunService.Stepped:Connect(function()
    if Config.Noclip and Config.AutoFarmEnabled and not State.IsMoving then
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
-- 🎨 ULTRA-COMPACT NON-INTRUSIVE FLOATING UI
-- ═══════════════════════════════════════════════════════════════════════════

local GUI_NAME = "AutoFarmInstantClickHub"
local oldGui = CoreGui:FindFirstChild(GUI_NAME) or LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(GUI_NAME)
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Minimized Pill (Visible when minimized)
local Pill = Instance.new("TextButton")
Pill.Name = "MiniPill"
Pill.Size = UDim2.new(0, 150, 0, 32)
Pill.Position = UDim2.new(1, -165, 0, 15)
Pill.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
Pill.Text = "⚡ FARM: 8 CPS"
Pill.Font = Enum.Font.GothamBold
Pill.TextColor3 = Color3.fromRGB(0, 230, 150)
Pill.TextSize = 12
Pill.BorderSizePixel = 0
Pill.Visible = false
Pill.Active = true
Pill.Parent = ScreenGui

local PillCorner = Instance.new("UICorner")
PillCorner.CornerRadius = UDim.new(0, 16)
PillCorner.Parent = Pill

local PillStroke = Instance.new("UIStroke")
PillStroke.Color = Color3.fromRGB(0, 230, 150)
PillStroke.Thickness = 1.2
PillStroke.Parent = Pill

-- Main Compact Floating Window (Positioned in Top-Right corner to leave center 100% open)
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 280, 0, 140)
Main.Position = UDim2.new(1, -295, 0, 15)
Main.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = false
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(38, 44, 62)
MainStroke.Thickness = 1.2
MainStroke.Parent = Main

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
TitleBar.BorderSizePixel = 0
TitleBar.Active = true
TitleBar.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "⚡ AUTOFARM V3"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, -65, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Active = false
TitleLabel.Parent = TitleBar

-- Minimize Button (─)
local MinBtn = Instance.new("TextButton")
MinBtn.Text = "─"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 12
MinBtn.TextColor3 = Color3.fromRGB(180, 185, 200)
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 56)
MinBtn.Size = UDim2.new(0, 22, 0, 22)
MinBtn.Position = UDim2.new(1, -50, 0.5, -11)
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = MinBtn

-- Close Button (✕)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.TextColor3 = Color3.fromRGB(180, 185, 200)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 56)
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -25, 0.5, -11)
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = CloseBtn

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Pill.Visible = true
end)

Pill.MouseButton1Click:Connect(function()
    Pill.Visible = false
    Main.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Pill.Visible = false
end)

-- Draggable implementation for TitleBar and Pill
local function makeDraggable(dragHandle, targetFrame)
    local isDragging, dragStart, startPos = false, nil, nil
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
end

makeDraggable(TitleBar, Main)
makeDraggable(Pill, Pill)

-- Content Frame
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -16, 1, -40)
Content.Position = UDim2.new(0, 8, 0, 36)
Content.BackgroundTransparency = 1
Content.Active = false
Content.Parent = Main

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Text = "Target: Searching..."
InfoLabel.Font = Enum.Font.GothamMedium
InfoLabel.TextSize = 11
InfoLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Size = UDim2.new(1, 0, 0, 16)
InfoLabel.Position = UDim2.new(0, 0, 0, 0)
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.Active = false
InfoLabel.Parent = Content

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Text = "Stats: 0 Smashed | 0 CPS"
StatsLabel.Font = Enum.Font.GothamMedium
StatsLabel.TextSize = 11
StatsLabel.TextColor3 = Color3.fromRGB(150, 220, 170)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Size = UDim2.new(1, 0, 0, 16)
StatsLabel.Position = UDim2.new(0, 0, 0, 18)
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.Active = false
StatsLabel.Parent = Content

local HintLabel = Instance.new("TextLabel")
HintLabel.Text = "💡 Click ANY box in-game to target it! | WASD to move"
HintLabel.Font = Enum.Font.Gotham
HintLabel.TextSize = 9
HintLabel.TextColor3 = Color3.fromRGB(140, 150, 175)
HintLabel.BackgroundTransparency = 1
HintLabel.Size = UDim2.new(1, 0, 0, 14)
HintLabel.Position = UDim2.new(0, 0, 0, 36)
HintLabel.TextXAlignment = Enum.TextXAlignment.Left
HintLabel.Active = false
HintLabel.Parent = Content

-- Main Action Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 28)
ToggleBtn.Position = UDim2.new(0, 0, 1, -30)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 230)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "AUTO FARM: ON (CLICK TO PAUSE)"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 11
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Active = true
ToggleBtn.Parent = Content

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    Config.AutoFarmEnabled = not Config.AutoFarmEnabled
    if Config.AutoFarmEnabled then
        ToggleBtn.Text = "AUTO FARM: ON (CLICK TO PAUSE)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 230)
        Pill.TextColor3 = Color3.fromRGB(0, 230, 150)
    else
        ToggleBtn.Text = "AUTO FARM: PAUSED (CLICK TO RESUME)"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
        Pill.TextColor3 = Color3.fromRGB(220, 80, 80)
    end
end)

-- UI Render Updates
RunService.RenderStepped:Connect(function()
    local target = State.CurrentTarget
    local targetText = "Target: None"
    if target then
        local curHp = target.hp or (target.box and (target.box.Health - (target.box.Damage or 0))) or 0
        local maxHp = target.maxHp or 100
        targetText = string.format("Box #%s (%.0f / %.0f HP)", tostring(target.id), math.max(0, curHp), maxHp)
    end

    if Main.Visible then
        InfoLabel.Text = (State.IsMoving and "🚶 " or "🎯 ") .. targetText
        StatsLabel.Text = string.format("Smashed: %d | %d CPS | %d Nearby", State.TotalSmashed, State.CurrentCPS, State.BoxesInField)
    end

    if Pill.Visible then
        Pill.Text = string.format("⚡ %d CPS (%d Smashed)", State.CurrentCPS, State.TotalSmashed)
    end
end)

-- Hotkey Toggle [F1]
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.ToggleKey then
        if Main.Visible or Pill.Visible then
            Main.Visible = false
            Pill.Visible = false
        else
            Main.Visible = true
            Pill.Visible = false
        end
    end
end)

print("[AutoFarm V3] Loaded! Click ANY box to target | WASD to move freely | F1 to toggle UI")
