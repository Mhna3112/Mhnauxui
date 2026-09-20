local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local weaponUsed = ReplicatedStorage:WaitForChild("remotes"):WaitForChild("weaponUsed")

-- ========== SETTINGS ==========
local TP_OFFSET_Y = 5          -- height above enemy head
local ATTACK_COOLDOWN = 0.15   -- seconds between swings
local KILL_RANGE = 200         -- scan range for enemies (studs)
local TP_SPEED = 0.1           -- how fast to lerp to target

-- ========== STATE ==========
local enabled = false
local currentTarget = nil
local lastSwing = 0
local connections = {}

-- ========== UI ==========
local gui = Instance.new("ScreenGui")
gui.Name = "KillAuraUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main frame
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 220, 0, 200)
main.Position = UDim2.new(0, 20, 0.5, -100)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 90)
stroke.Thickness = 1.5
stroke.Parent = main

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Text = "⚔ KILL AURA"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Status indicator (dot)
local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 10, 0, 10)
statusDot.Position = UDim2.new(1, -18, 0.5, -5)
statusDot.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
statusDot.BorderSizePixel = 0
statusDot.Parent = titleBar
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = statusDot

-- Target info
local targetLabel = Instance.new("TextLabel")
targetLabel.Name = "TargetLabel"
targetLabel.Text = "Target: None"
targetLabel.Font = Enum.Font.Gotham
targetLabel.TextSize = 12
targetLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
targetLabel.BackgroundTransparency = 1
targetLabel.Size = UDim2.new(1, -20, 0, 20)
targetLabel.Position = UDim2.new(0, 12, 0, 46)
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = main

-- Distance info
local distLabel = Instance.new("TextLabel")
distLabel.Name = "DistLabel"
distLabel.Text = "Distance: --"
distLabel.Font = Enum.Font.Gotham
distLabel.TextSize = 12
distLabel.TextColor3 = Color3.fromRGB(140, 140, 155)
distLabel.BackgroundTransparency = 1
distLabel.Size = UDim2.new(1, -20, 0, 20)
distLabel.Position = UDim2.new(0, 12, 0, 66)
distLabel.TextXAlignment = Enum.TextXAlignment.Left
distLabel.Parent = main

-- Enemies count
local countLabel = Instance.new("TextLabel")
countLabel.Name = "CountLabel"
countLabel.Text = "Enemies nearby: --"
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 12
countLabel.TextColor3 = Color3.fromRGB(140, 140, 155)
countLabel.BackgroundTransparency = 1
countLabel.Size = UDim2.new(1, -20, 0, 20)
countLabel.Position = UDim2.new(0, 12, 0, 86)
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = main

-- Toggle button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
toggleBtn.Text = "OFF"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.Size = UDim2.new(1, -24, 0, 34)
toggleBtn.Position = UDim2.new(0, 12, 0, 116)
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = main
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleBtn

-- Hotkey hint
local hint = Instance.new("TextLabel")
hint.Text = "Press F1 to toggle"
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.TextColor3 = Color3.fromRGB(90, 90, 100)
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, 0, 0, 16)
hint.Position = UDim2.new(0, 0, 1, -20)
hint.TextXAlignment = Enum.TextXAlignment.Center
hint.Parent = main

-- Make draggable
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ========== FUNCTIONS ==========

local function updateUI(on)
    if on then
        toggleBtn.Text = "ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
        statusDot.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
    else
        toggleBtn.Text = "OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        statusDot.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        targetLabel.Text = "Target: None"
        distLabel.Text = "Distance: --"
    end
end

local function toggle()
    enabled = not enabled
    updateUI(enabled)
end

toggleBtn.MouseButton1Click:Connect(toggle)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        toggle()
    end
end)

local function getWeaponAccessory()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, child in pairs(char:GetChildren()) do
        if child:IsA("Accessory") and child:FindFirstChild("Weapon") then
            return child
        end
    end
    return nil
end

local function canAttack()
    if LocalPlayer.peaceful and LocalPlayer.peaceful.Value then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local busyCasting = char:FindFirstChild("busyCasting")
    if not busyCasting then return false end
    return busyCasting.Value == false
end

local function getEnemyInfo()
    local char = LocalPlayer.Character
    if not char then return nil, 0 end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil, 0 end
    local myPos = rootPart.Position

    local nearest = nil
    local nearestDist = KILL_RANGE
    local enemyCount = 0

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Health > 0 then
            local model = obj.Parent
            if model and model ~= char then
                local isPlayer = Players:GetPlayerFromCharacter(model)
                if not isPlayer then
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = (hrp.Position - myPos).Magnitude
                        enemyCount = enemyCount + 1
                        if dist < nearestDist then
                            nearestDist = dist
                            nearest = {model = model, hrp = hrp, humanoid = obj, dist = dist}
                        end
                    end
                end
            end
        end
    end

    return nearest, enemyCount
end

local function swingWeapon()
    local now = tick()
    if now - lastSwing < ATTACK_COOLDOWN then return end
    if not canAttack() then return end

    local weapon = getWeaponAccessory()
    if not weapon then return end

    local hitBox = weapon:FindFirstChild("hitBox")
    local remote = weapon:FindFirstChildOfClass("RemoteEvent")

    -- Always target currentTarget's hitbox if available
    if currentTarget and hitBox and remote then
        hitBox.CFrame = currentTarget.hrp.CFrame
        remote:FireServer()
        weaponUsed:FireServer()
        task.delay(0.05, function()
            if hitBox and hitBox.Parent then
                pcall(function() hitBox.CFrame = currentTarget.hrp.CFrame end)
            end
        end)
    elseif remote then
        remote:FireServer()
        weaponUsed:FireServer()
    end

    lastSwing = now
end

-- ========== MAIN LOOP ==========
connections.loop = RunService.Heartbeat:Connect(function(dt)
    local target, enemyCount = getEnemyInfo()
    countLabel.Text = "Enemies nearby: " .. tostring(enemyCount)

    if not enabled or not target then
        currentTarget = nil
        if not enabled then
            targetLabel.Text = "Target: None"
            distLabel.Text = "Distance: --"
        end
        return
    end

    currentTarget = target
    targetLabel.Text = "Target: " .. target.model.Name
    distLabel.Text = "Distance: " .. string.format("%.1f", target.dist) .. " studs"

    -- Teleport player on top of enemy's head
    local char = LocalPlayer.Character
    if char then
        local myHRP = char:FindFirstChild("HumanoidRootPart")
        if myHRP then
            local targetPos = target.hrp.Position + Vector3.new(0, TP_OFFSET_Y, 0)
            myHRP.CFrame = CFrame.new(targetPos)
        end
    end

    -- Swing weapon
    swingWeapon()
end)

-- Parent UI
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
updateUI(false)
print("[Kill Aura TP] Loaded! Press F1 or click the button.")