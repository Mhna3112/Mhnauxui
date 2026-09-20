-- ? STEAL AN EGG AUTOFARM + GUI ?
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')
local TweenService = game:GetService('TweenService')
local CoreGui = game:GetService('CoreGui')

if _G.AutoFarm_Connection then _G.AutoFarm_Connection:Disconnect() end
if CoreGui:FindFirstChild("EggFarmUI") then CoreGui.EggFarmUI:Destroy() end

_G.AutoFarm_Enabled = false
_G.TargetEggName = "All"
local isTweening = false

-- -------------------------
-- GUI SETUP
-- -------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EggFarmUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "? Steal An Egg Farm ?"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 40)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "Auto Farm: OFF"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = MainFrame

local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Size = UDim2.new(0.9, 0, 0, 20)
SelectedLabel.Position = UDim2.new(0.05, 0, 0, 80)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SelectedLabel.Text = "Target Egg: All"
SelectedLabel.Font = Enum.Font.Gotham
SelectedLabel.TextSize = 12
SelectedLabel.Parent = MainFrame

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0.9, 0, 0, 25)
RefreshBtn.Position = UDim2.new(0.05, 0, 0, 105)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.Text = "Refresh Egg List"
RefreshBtn.Font = Enum.Font.Gotham
RefreshBtn.TextSize = 12
RefreshBtn.Parent = MainFrame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(0.9, 0, 0, 200)
ScrollFrame.Position = UDim2.new(0.05, 0, 0, 140)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = ScrollFrame

-- -------------------------
-- LOGIC
-- -------------------------
local function createEggButton(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.Parent = ScrollFrame
    
    btn.MouseButton1Click:Connect(function()
        _G.TargetEggName = name
        SelectedLabel.Text = "Target Egg: " .. name
    end)
end

local function populateEggList()
    for _, child in ipairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    createEggButton("All")
    
    local eggsFolder = Workspace:FindFirstChild('AreaEggSlotsClient')
    if not eggsFolder then return end
    
    local uniqueEggs = {}
    for _, eggModel in ipairs(eggsFolder:GetChildren()) do
        if eggModel:IsA('Model') then
            local eggName = string.split(eggModel.Name, ":")[1]
            if not uniqueEggs[eggName] then
                uniqueEggs[eggName] = true
                createEggButton(eggName)
            end
        end
    end
    
    local count = 0
    for _ in pairs(uniqueEggs) do count = count + 1 end
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, (count + 1) * 35)
end

ToggleBtn.MouseButton1Click:Connect(function()
    _G.AutoFarm_Enabled = not _G.AutoFarm_Enabled
    if _G.AutoFarm_Enabled then
        ToggleBtn.Text = "Auto Farm: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        ToggleBtn.Text = "Auto Farm: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

RefreshBtn.MouseButton1Click:Connect(populateEggList)
populateEggList() -- Initial population

local function fireAttack(target)
    -- Needs attack logic
end

local function getBestEgg()
    local myPos = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.Position
    if not myPos then return nil end

    local bestEgg = nil
    local bestDist = math.huge
    local eggsFolder = Workspace:FindFirstChild('AreaEggSlotsClient')
    
    if not eggsFolder then return nil end

    for _, eggModel in ipairs(eggsFolder:GetChildren()) do
        if eggModel:IsA('Model') then
            local eggName = string.split(eggModel.Name, ":")[1]
            if _G.TargetEggName == "All" or string.find(eggName, _G.TargetEggName) then
                local hitbox = eggModel:FindFirstChild('Hitbox')
                if hitbox then
                    local dist = (hitbox.Position - myPos).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestEgg = eggModel
                    end
                end
            end
        end
    end
    return bestEgg
end

local function farmEgg(egg)
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    local hrp = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    
    local hitbox = egg:FindFirstChild('Hitbox')
    if hitbox and not isTweening then
        local targetCFrame = hitbox.CFrame * CFrame.new(0, 3, 0)
        local dist = (hrp.Position - targetCFrame.Position).Magnitude
        
        if dist > 5 then
            isTweening = true
            local tweenInfo = TweenInfo.new(dist / 250, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
            tween.Completed:Connect(function()
                isTweening = false
                fireAttack(egg)
            end)
            tween:Play()
        else
            hrp.CFrame = targetCFrame
            fireAttack(egg)
        end
    end
end

_G.AutoFarm_Connection = RunService.Heartbeat:Connect(function()
    if not _G.AutoFarm_Enabled then return end
    local target = getBestEgg()
    if target then
        farmEgg(target)
    end
end)

