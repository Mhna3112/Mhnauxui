--[[
    ═══════════════════════════════════════════════════════════════════════════
    ✨ MHNAA UI LIBRARY (PRO VERSION) ✨
    Designed to perfectly match the modern dark "Nousigi [PRO]" interface:
      • Topbar with Icon, Title ("Mhnaa"), Tag ("[PRO]"), and Search Bar (Ctrl+K)
      • Sidebar with Game Header, Rounded Pill Active Tabs, and Pinned UI Setting
      • Modern Checkbox Toggles with Subtitles/Descriptions
      • Elegant Dropdown Comboboxes with Smooth Expand/Collapse
      • Drag-to-Resize Handle at Bottom-Right (◢)
      • Smooth Draggable Topbar & Keyboard Hotkey (RightControl)
      • Toast Notification System
      • Multi-Game Compatibility: Ready for Dungeon Quest, Anime Vanguards, etc.
    ═══════════════════════════════════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local MhnaaUI = {
    Windows = {},
    CurrentTheme = {
        Background = Color3.fromRGB(26, 26, 28),
        Sidebar = Color3.fromRGB(21, 21, 23),
        Topbar = Color3.fromRGB(30, 30, 34),
        CardBackground = Color3.fromRGB(33, 33, 37),
        CardBorder = Color3.fromRGB(44, 44, 50),
        Accent = Color3.fromRGB(104, 157, 248), -- Clean Dodger/Sky Blue as in screenshot
        AccentHover = Color3.fromRGB(124, 172, 255),
        TagColor = Color3.fromRGB(245, 166, 35), -- Warm Amber/Orange for [PRO]
        TextTitle = Color3.fromRGB(240, 242, 245),
        TextMuted = Color3.fromRGB(138, 140, 150),
        SidebarText = Color3.fromRGB(155, 158, 170),
        InputBorder = Color3.fromRGB(45, 45, 52),
        InputBackground = Color3.fromRGB(24, 24, 27)
    }
}

-- Target parent container safe for all executors
local function getSafeGuiParent()
    local success, parent = pcall(function()
        return gethui and gethui() or CoreGui
    end)
    if success and parent then
        return parent
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Smooth tween helper
local function tween(object, info, properties)
    local anim = TweenService:Create(object, info, properties)
    anim:Play()
    return anim
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🔔 NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════
local NotificationHolder = nil

local function getNotificationHolder()
    if NotificationHolder and NotificationHolder.Parent then
        return NotificationHolder
    end

    local guiParent = getSafeGuiParent()
    local holderGui = guiParent:FindFirstChild("Mhnaa_Notifications")
    if not holderGui then
        holderGui = Instance.new("ScreenGui")
        holderGui.Name = "Mhnaa_Notifications"
        holderGui.ResetOnSpawn = false
        holderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        holderGui.Parent = guiParent
    end

    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Size = UDim2.new(0, 300, 1, -40)
    container.Position = UDim2.new(1, -320, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = holderGui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    NotificationHolder = container
    return NotificationHolder
end

function MhnaaUI:Notify(config)
    local title = config.Title or "Notification"
    local content = config.Content or ""
    local duration = config.Duration or 3.5

    local container = getNotificationHolder()

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 68)
    card.BackgroundColor3 = MhnaaUI.CurrentTheme.Background
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = MhnaaUI.CurrentTheme.CardBorder
    stroke.Thickness = 1
    stroke.Transparency = 1
    stroke.Parent = card

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -24, 0, 20)
    titleLbl.Position = UDim2.new(0, 12, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = title
    titleLbl.TextColor3 = MhnaaUI.CurrentTheme.Accent
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTransparency = 1
    titleLbl.Parent = card

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, -24, 0, 32)
    descLbl.Position = UDim2.new(0, 12, 0, 28)
    descLbl.BackgroundTransparency = 1
    descLbl.Font = Enum.Font.Gotham
    descLbl.Text = content
    descLbl.TextColor3 = MhnaaUI.CurrentTheme.TextMuted
    descLbl.TextSize = 12
    descLbl.TextWrapped = true
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.TextYAlignment = Enum.TextYAlignment.Top
    descLbl.TextTransparency = 1
    descLbl.Parent = card

    -- Fade In
    tween(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
    tween(stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0})
    tween(titleLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})
    tween(descLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0})

    task.delay(duration, function()
        if card and card.Parent then
            local fadeOut = tween(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
            tween(stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1})
            tween(titleLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})
            tween(descLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})
            fadeOut.Completed:Connect(function()
                card:Destroy()
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🪟 WINDOW BUILDER
-- ═══════════════════════════════════════════════════════════════════════════
function MhnaaUI:CreateWindow(opt)
    opt = opt or {}
    local Title = opt.Title or "Mhnaa"
    local Tag = opt.Tag or "[PRO]"
    local GameName = opt.Game or "DUNGEON QUEST"
    local WindowSize = opt.Size or UDim2.new(0, 680, 0, 420)
    local ToggleKey = opt.ToggleKey or Enum.KeyCode.RightControl
    local AccentColor = opt.AccentColor or MhnaaUI.CurrentTheme.Accent

    MhnaaUI.CurrentTheme.Accent = AccentColor

    -- Clean old existing GUI with same name
    local safeParent = getSafeGuiParent()
    local oldGui = safeParent:FindFirstChild("Mhnaa_UI_Root")
    if oldGui then oldGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Mhnaa_UI_Root"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = safeParent

    -- Main Container Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = WindowSize
    MainFrame.Position = UDim2.new(0.5, -WindowSize.X.Offset / 2, 0.5, -WindowSize.Y.Offset / 2)
    MainFrame.BackgroundColor3 = MhnaaUI.CurrentTheme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = false
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = MhnaaUI.CurrentTheme.CardBorder
    MainStroke.Thickness = 1.2
    MainStroke.Parent = MainFrame

    -- TOPBAR
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 46)
    Topbar.BackgroundColor3 = MhnaaUI.CurrentTheme.Topbar
    Topbar.BorderSizePixel = 0
    Topbar.Parent = MainFrame

    local TopbarCorner = Instance.new("UICorner")
    TopbarCorner.CornerRadius = UDim.new(0, 10)
    TopbarCorner.Parent = Topbar

    -- Bottom cover to keep bottom corners square for topbar
    local TopbarSquareFix = Instance.new("Frame")
    TopbarSquareFix.Size = UDim2.new(1, 0, 0, 10)
    TopbarSquareFix.Position = UDim2.new(0, 0, 1, -10)
    TopbarSquareFix.BackgroundColor3 = MhnaaUI.CurrentTheme.Topbar
    TopbarSquareFix.BorderSizePixel = 0
    TopbarSquareFix.Parent = Topbar

    local TopbarDivider = Instance.new("Frame")
    TopbarDivider.Size = UDim2.new(1, 0, 0, 1)
    TopbarDivider.Position = UDim2.new(0, 0, 1, -1)
    TopbarDivider.BackgroundColor3 = MhnaaUI.CurrentTheme.CardBorder
    TopbarDivider.BorderSizePixel = 0
    TopbarDivider.Parent = Topbar

    -- Brand Icon (Bunny/Avatar)
    local IconImage = Instance.new("ImageLabel")
    IconImage.Name = "BrandIcon"
    IconImage.Size = UDim2.new(0, 26, 0, 26)
    IconImage.Position = UDim2.new(0, 12, 0.5, -13)
    IconImage.BackgroundTransparency = 1
    IconImage.Image = opt.Icon or "rbxassetid://134731362241695"
    IconImage.ScaleType = Enum.ScaleType.Fit
    IconImage.Parent = Topbar

    -- Title Label ("Mhnaa")
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(0, 0, 1, 0)
    TitleLabel.Position = UDim2.new(0, 44, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = Title .. " "
    TitleLabel.TextColor3 = MhnaaUI.CurrentTheme.TextTitle
    TitleLabel.TextSize = 14
    TitleLabel.AutomaticSize = Enum.AutomaticSize.X
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Topbar

    -- Tag Label ("[PRO]")
    local TagLabel = Instance.new("TextLabel")
    TagLabel.Name = "TagLabel"
    TagLabel.Size = UDim2.new(0, 0, 1, 0)
    TagLabel.Position = UDim2.new(1, 4, 0, 0)
    TagLabel.BackgroundTransparency = 1
    TagLabel.Font = Enum.Font.GothamBold
    TagLabel.Text = Tag
    TagLabel.TextColor3 = MhnaaUI.CurrentTheme.TagColor
    TagLabel.TextSize = 13
    TagLabel.AutomaticSize = Enum.AutomaticSize.X
    TagLabel.TextXAlignment = Enum.TextXAlignment.Left
    TagLabel.Parent = TitleLabel

    -- Back Arrow / Collapse Icon (<)
    local BackArrowBtn = Instance.new("TextButton")
    BackArrowBtn.Name = "BackArrow"
    BackArrowBtn.Size = UDim2.new(0, 24, 0, 24)
    BackArrowBtn.Position = UDim2.new(0, 190, 0.5, -12)
    BackArrowBtn.BackgroundTransparency = 1
    BackArrowBtn.Font = Enum.Font.GothamBold
    BackArrowBtn.Text = "‹"
    BackArrowBtn.TextColor3 = MhnaaUI.CurrentTheme.SidebarText
    BackArrowBtn.TextSize = 18
    BackArrowBtn.Parent = Topbar

    local PipeDivider = Instance.new("Frame")
    PipeDivider.Size = UDim2.new(0, 1, 0, 16)
    PipeDivider.Position = UDim2.new(0, 218, 0.5, -8)
    PipeDivider.BackgroundColor3 = MhnaaUI.CurrentTheme.CardBorder
    PipeDivider.BorderSizePixel = 0
    PipeDivider.Parent = Topbar

    -- SEARCH BAR (With Ctrl+K badge as in screenshot)
    local SearchContainer = Instance.new("Frame")
    SearchContainer.Name = "SearchContainer"
    SearchContainer.Size = UDim2.new(1, -290, 0, 30)
    SearchContainer.Position = UDim2.new(0, 230, 0.5, -15)
    SearchContainer.BackgroundColor3 = MhnaaUI.CurrentTheme.InputBackground
    SearchContainer.BorderSizePixel = 0
    SearchContainer.Parent = Topbar

    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, 6)
    SearchCorner.Parent = SearchContainer

    local SearchStroke = Instance.new("UIStroke")
    SearchStroke.Color = MhnaaUI.CurrentTheme.CardBorder
    SearchStroke.Thickness = 1
    SearchStroke.Parent = SearchContainer

    local SearchIcon = Instance.new("TextLabel")
    SearchIcon.Size = UDim2.new(0, 24, 1, 0)
    SearchIcon.Position = UDim2.new(0, 6, 0, 0)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Font = Enum.Font.GothamMedium
    SearchIcon.Text = "🔍"
    SearchIcon.TextSize = 11
    SearchIcon.TextColor3 = MhnaaUI.CurrentTheme.TextMuted
    SearchIcon.Parent = SearchContainer

    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "SearchBox"
    SearchBox.Size = UDim2.new(1, -90, 1, 0)
    SearchBox.Position = UDim2.new(0, 30, 0, 0)
    SearchBox.BackgroundTransparency = 1
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.PlaceholderText = "Enter keywords to search features...."
    SearchBox.PlaceholderColor3 = MhnaaUI.CurrentTheme.TextMuted
    SearchBox.Text = ""
    SearchBox.TextColor3 = MhnaaUI.CurrentTheme.TextTitle
    SearchBox.TextSize = 11
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false
    SearchBox.Parent = SearchContainer

    -- Ctrl K Badge
    local CtrlKBadge = Instance.new("Frame")
    CtrlKBadge.Name = "CtrlKBadge"
    CtrlKBadge.Size = UDim2.new(0, 48, 0, 20)
    CtrlKBadge.Position = UDim2.new(1, -54, 0.5, -10)
    CtrlKBadge.BackgroundColor3 = Color3.fromRGB(36, 36, 40)
    CtrlKBadge.BorderSizePixel = 0
    CtrlKBadge.Parent = SearchContainer

    local CtrlKCorner = Instance.new("UICorner")
    CtrlKCorner.CornerRadius = UDim.new(0, 4)
    CtrlKCorner.Parent = CtrlKBadge

    local CtrlKStroke = Instance.new("UIStroke")
    CtrlKStroke.Color = MhnaaUI.CurrentTheme.CardBorder
    CtrlKStroke.Thickness = 1
    CtrlKStroke.Parent = CtrlKBadge

    local CtrlKText = Instance.new("TextLabel")
    CtrlKText.Size = UDim2.new(1, 0, 1, 0)
    CtrlKText.BackgroundTransparency = 1
    CtrlKText.Font = Enum.Font.GothamMedium
    CtrlKText.Text = "Ctrl K"
    CtrlKText.TextColor3 = MhnaaUI.CurrentTheme.TextMuted
    CtrlKText.TextSize = 10
    CtrlKText.Parent = CtrlKBadge

    -- Window Controls (Minimize & Close)
    local WindowControls = Instance.new("Frame")
    WindowControls.Name = "WindowControls"
    WindowControls.Size = UDim2.new(0, 48, 1, 0)
    WindowControls.Position = UDim2.new(1, -52, 0, 0)
    WindowControls.BackgroundTransparency = 1
    WindowControls.Parent = Topbar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 22, 0, 22)
    CloseBtn.Position = UDim2.new(1, -26, 0.5, -11)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = MhnaaUI.CurrentTheme.TextMuted
    CloseBtn.TextSize = 17
    CloseBtn.Parent = WindowControls

    CloseBtn.MouseEnter:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 80, 80)})
    end)
    CloseBtn.MouseLeave:Connect(function()
        tween(CloseBtn, TweenInfo.new(0.15), {TextColor3 = MhnaaUI.CurrentTheme.TextMuted})
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        MhnaaUI:Notify({
            Title = Title,
            Content = "UI Hidden. Press " .. ToggleKey.Name .. " to open again.",
            Duration = 3
        })
    end)

    -- SIDEBAR (Left Menu)
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 180, 1, -46)
    Sidebar.Position = UDim2.new(0, 0, 0, 46)
    Sidebar.BackgroundColor3 = MhnaaUI.CurrentTheme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 10)
    SidebarCorner.Parent = Sidebar

    local SidebarSquareFix = Instance.new("Frame")
    SidebarSquareFix.Size = UDim2.new(0, 10, 1, 0)
    SidebarSquareFix.Position = UDim2.new(1, -10, 0, 0)
    SidebarSquareFix.BackgroundColor3 = MhnaaUI.CurrentTheme.Sidebar
    SidebarSquareFix.BorderSizePixel = 0
    SidebarSquareFix.Parent = Sidebar

    local SidebarDivider = Instance.new("Frame")
    SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
    SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
    SidebarDivider.BackgroundColor3 = MhnaaUI.CurrentTheme.CardBorder
    SidebarDivider.BorderSizePixel = 0
    SidebarDivider.Parent = Sidebar

    -- Sidebar Game Category Header (e.g. "DUNGEON QUEST" / "ANIME VANGUARDS")
    local GameHeader = Instance.new("TextLabel")
    GameHeader.Name = "GameHeader"
    GameHeader.Size = UDim2.new(1, -24, 0, 26)
    GameHeader.Position = UDim2.new(0, 14, 0, 10)
    GameHeader.BackgroundTransparency = 1
    GameHeader.Font = Enum.Font.GothamBold
    GameHeader.Text = string.upper(GameName)
    GameHeader.TextColor3 = MhnaaUI.CurrentTheme.SidebarText
    GameHeader.TextSize = 11
    GameHeader.TextXAlignment = Enum.TextXAlignment.Left
    GameHeader.Parent = Sidebar

    -- Tabs Container ScrollingFrame
    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.Name = "TabScroll"
    TabScroll.Size = UDim2.new(1, -16, 1, -88)
    TabScroll.Position = UDim2.new(0, 8, 0, 38)
    TabScroll.BackgroundTransparency = 1
    TabScroll.BorderSizePixel = 0
    TabScroll.ScrollBarThickness = 2
    TabScroll.ScrollBarImageColor3 = Color3.fromRGB(40, 40, 45)
    TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabScroll.Parent = Sidebar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Parent = TabScroll

    -- Pinned UI Setting at the bottom of sidebar
    local SettingDivider = Instance.new("Frame")
    SettingDivider.Size = UDim2.new(1, -16, 0, 1)
    SettingDivider.Position = UDim2.new(0, 8, 1, -48)
    SettingDivider.BackgroundColor3 = MhnaaUI.CurrentTheme.CardBorder
    SettingDivider.BorderSizePixel = 0
    SettingDivider.Parent = Sidebar

    local SettingBtn = Instance.new("TextButton")
    SettingBtn.Name = "UISettingBtn"
    SettingBtn.Size = UDim2.new(1, -16, 0, 34)
    SettingBtn.Position = UDim2.new(0, 8, 1, -42)
    SettingBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    SettingBtn.BackgroundTransparency = 1
    SettingBtn.BorderSizePixel = 0
    SettingBtn.Font = Enum.Font.GothamMedium
    SettingBtn.Text = "   ⚙  UI Setting"
    SettingBtn.TextColor3 = MhnaaUI.CurrentTheme.SidebarText
    SettingBtn.TextSize = 12
    SettingBtn.TextXAlignment = Enum.TextXAlignment.Left
    SettingBtn.Parent = Sidebar

    local SettingCorner = Instance.new("UICorner")
    SettingCorner.CornerRadius = UDim.new(0, 6)
    SettingCorner.Parent = SettingBtn

    -- CONTENT AREA (Right Panel)
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -180, 1, -46)
    ContentArea.Position = UDim2.new(0, 180, 0, 46)
    ContentArea.BackgroundColor3 = MhnaaUI.CurrentTheme.Background
    ContentArea.BorderSizePixel = 0
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = MainFrame

    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 10)
    ContentCorner.Parent = ContentArea

    -- RESIZE HANDLE (Bottom Right Corner ◢)
    local ResizeHandle = Instance.new("ImageButton")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Size = UDim2.new(0, 16, 0, 16)
    ResizeHandle.Position = UDim2.new(1, -16, 1, -16)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.Image = "rbxassetid://6034306437" -- Triangle grip
    ResizeHandle.ImageColor3 = MhnaaUI.CurrentTheme.SidebarText
    ResizeHandle.ZIndex = 15
    ResizeHandle.Parent = MainFrame

    -- RESIZING LOGIC
    local resizing = false
    local resizeStart = nil
    local startSize = nil

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = MainFrame.AbsoluteSize
        end
    end)

    -- DRAGGING LOGIC (Smooth dragging from Topbar)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not SearchContainer:IsAncestorOf(input.Target) and input.Target ~= CloseBtn then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            resizing = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        elseif resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newWidth = math.max(540, startSize.X + delta.X)
            local newHeight = math.max(340, startSize.Y + delta.Y)
            MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)

    -- HOTKEY TOGGLE (RightControl or custom)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == ToggleKey then
            MainFrame.Visible = not MainFrame.Visible
        elseif not gameProcessed and input.KeyCode == Enum.KeyCode.K and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            SearchBox:CaptureFocus()
        end
    end)

    -- TAB MANAGEMENT TABLE
    local Window = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        ContentArea = ContentArea,
        Tabs = {},
        TabButtons = {},
        ActiveTab = nil,
        AllCards = {}, -- For global search
        Config = {}
    }

    -- GLOBAL SEARCH FILTERING
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(SearchBox.Text)
        if query == "" then
            for _, card in ipairs(Window.AllCards) do
                card.Frame.Visible = true
            end
        else
            for _, card in ipairs(Window.AllCards) do
                local matchTitle = card.Title and string.find(string.lower(card.Title), query)
                local matchDesc = card.Desc and string.find(string.lower(card.Desc), query)
                card.Frame.Visible = (matchTitle or matchDesc) and true or false
            end
        end
    end)

    -- ═══════════════════════════════════════════════════════════════════════
    -- 📑 CREATE TAB METHOD
    -- ═══════════════════════════════════════════════════════════════════════
    function Window:CreateTab(tabOpt)
        tabOpt = tabOpt or {}
        local TabName = type(tabOpt) == "string" and tabOpt or (tabOpt.Name or "Tab")
        local TabIcon = type(tabOpt) == "table" and tabOpt.Icon or ""

        -- Content Page (Scrolling Frame)
        local Page = Instance.new("ScrollingFrame")
        Page.Name = TabName .. "Page"
        Page.Size = UDim2.new(1, -24, 1, -16)
        Page.Position = UDim2.new(0, 16, 0, 12)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Color3.fromRGB(48, 48, 56)
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.Visible = false
        Page.Parent = ContentArea

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        -- Tab Title Header inside Content Area (e.g. "Joiner")
        local PageTitle = Instance.new("TextLabel")
        PageTitle.Name = "PageTitle"
        PageTitle.Size = UDim2.new(1, 0, 0, 32)
        PageTitle.BackgroundTransparency = 1
        PageTitle.Font = Enum.Font.GothamBold
        PageTitle.Text = TabName
        PageTitle.TextColor3 = MhnaaUI.CurrentTheme.TextTitle
        PageTitle.TextSize = 16
        PageTitle.TextXAlignment = Enum.TextXAlignment.Left
        PageTitle.LayoutOrder = 0
        PageTitle.Parent = Page

        -- Tab Button on Sidebar
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = TabName .. "Btn"
        TabBtn.Size = UDim2.new(1, 0, 0, 34)
        TabBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        TabBtn.BackgroundTransparency = 1
        TabBtn.BorderSizePixel = 0
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.Text = "   " .. (TabIcon ~= "" and (TabIcon .. "  ") or "") .. TabName
        TabBtn.TextColor3 = MhnaaUI.CurrentTheme.SidebarText
        TabBtn.TextSize = 12
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = TabScroll

        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 6)
        TabBtnCorner.Parent = TabBtn

        local function activateTab()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
            end
            for _, b in pairs(Window.TabButtons) do
                tween(b, TweenInfo.new(0.18), {
                    BackgroundTransparency = 1,
                    TextColor3 = MhnaaUI.CurrentTheme.SidebarText
                })
            end

            Page.Visible = true
            Window.ActiveTab = TabName

            -- Active tab pill styling (Dodger Blue background with pure white text)
            TabBtn.BackgroundColor3 = MhnaaUI.CurrentTheme.Accent
            tween(TabBtn, TweenInfo.new(0.18), {
                BackgroundTransparency = 0,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
        end

        TabBtn.MouseButton1Click:Connect(activateTab)

        -- Hover effect for inactive state
        TabBtn.MouseEnter:Connect(function()
            if Window.ActiveTab ~= TabName then
                tween(TabBtn, TweenInfo.new(0.15), {
                    BackgroundTransparency = 0.85,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    TextColor3 = Color3.fromRGB(220, 222, 230)
                })
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Window.ActiveTab ~= TabName then
                tween(TabBtn, TweenInfo.new(0.15), {
                    BackgroundTransparency = 1,
                    TextColor3 = MhnaaUI.CurrentTheme.SidebarText
                })
            end
        end)

        table.insert(Window.TabButtons, TabBtn)
        local TabObject = {
            Page = Page,
            Button = TabBtn,
            Name = TabName,
            Order = #Window.TabButtons
        }
        Window.Tabs[TabName] = TabObject

        -- Set first tab active by default
        if #Window.TabButtons == 1 then
            activateTab()
        end

        -- ═══════════════════════════════════════════════════════════════════
        -- 🔲 COMPONENT: CHECKBOX TOGGLE (Exact match to screenshot)
        -- ═══════════════════════════════════════════════════════════════════
        function TabObject:CreateToggle(tOpt)
            tOpt = tOpt or {}
            local Title = tOpt.Title or "Toggle"
            local Description = tOpt.Description or ""
            local Default = tOpt.Default or false
            local Callback = tOpt.Callback or function() end

            local hasDesc = Description ~= ""
            local cardHeight = hasDesc and 54 or 40

            local Card = Instance.new("Frame")
            Card.Name = Title .. "Toggle"
            Card.Size = UDim2.new(1, -6, 0, cardHeight)
            Card.BackgroundColor3 = MhnaaUI.CurrentTheme.CardBackground
            Card.BorderSizePixel = 0
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 6)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = MhnaaUI.CurrentTheme.CardBorder
            CardStroke.Thickness = 1
            CardStroke.Parent = Card

            -- Title
            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -60, 0, 18)
            TitleLabel.Position = UDim2.new(0, 12, 0, hasDesc and 8 or 11)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Font = Enum.Font.GothamBold
            TitleLabel.Text = Title
            TitleLabel.TextColor3 = MhnaaUI.CurrentTheme.TextTitle
            TitleLabel.TextSize = 13
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = Card

            -- Subtitle / Description (If provided)
            if hasDesc then
                local DescLabel = Instance.new("TextLabel")
                DescLabel.Size = UDim2.new(1, -60, 0, 16)
                DescLabel.Position = UDim2.new(0, 12, 0, 28)
                DescLabel.BackgroundTransparency = 1
                DescLabel.Font = Enum.Font.Gotham
                DescLabel.Text = Description
                DescLabel.TextColor3 = MhnaaUI.CurrentTheme.TextMuted
                DescLabel.TextSize = 11
                DescLabel.TextXAlignment = Enum.TextXAlignment.Left
                DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
                DescLabel.Parent = Card
            end

            -- Checkbox Container (Square with rounded corner, as in screenshot)
            local CheckBox = Instance.new("TextButton")
            CheckBox.Name = "CheckBox"
            CheckBox.Size = UDim2.new(0, 20, 0, 20)
            CheckBox.Position = UDim2.new(1, -32, 0.5, -10)
            CheckBox.BackgroundColor3 = Default and MhnaaUI.CurrentTheme.Accent or Color3.fromRGB(24, 24, 28)
            CheckBox.BorderSizePixel = 0
            CheckBox.Text = ""
            CheckBox.Parent = Card

            local CheckCorner = Instance.new("UICorner")
            CheckCorner.CornerRadius = UDim.new(0, 4)
            CheckCorner.Parent = CheckBox

            local CheckStroke = Instance.new("UIStroke")
            CheckStroke.Color = Default and MhnaaUI.CurrentTheme.Accent or MhnaaUI.CurrentTheme.CardBorder
            CheckStroke.Thickness = 1.2
            CheckStroke.Parent = CheckBox

            -- Checkmark Icon (Vector check)
            local Checkmark = Instance.new("TextLabel")
            Checkmark.Size = UDim2.new(1, 0, 1, 0)
            Checkmark.BackgroundTransparency = 1
            Checkmark.Font = Enum.Font.GothamBold
            Checkmark.Text = "✓"
            Checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
            Checkmark.TextSize = 13
            Checkmark.TextTransparency = Default and 0 or 1
            Checkmark.Parent = CheckBox

            local state = Default

            local function setState(newState, fireCallback)
                state = newState
                if state then
                    tween(CheckBox, TweenInfo.new(0.18), {BackgroundColor3 = MhnaaUI.CurrentTheme.Accent})
                    tween(CheckStroke, TweenInfo.new(0.18), {Color = MhnaaUI.CurrentTheme.Accent})
                    tween(Checkmark, TweenInfo.new(0.18), {TextTransparency = 0})
                else
                    tween(CheckBox, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(24, 24, 28)})
                    tween(CheckStroke, TweenInfo.new(0.18), {Color = MhnaaUI.CurrentTheme.CardBorder})
                    tween(Checkmark, TweenInfo.new(0.18), {TextTransparency = 1})
                end
                if fireCallback ~= false then
                    pcall(Callback, state)
                end
            end

            CheckBox.MouseButton1Click:Connect(function()
                setState(not state)
            end)

            table.insert(Window.AllCards, {
                Title = Title,
                Desc = Description,
                Frame = Card
            })

            return {
                Set = function(_, val) setState(val, true) end,
                GetValue = function() return state end,
                Card = Card
            }
        end

        -- ═══════════════════════════════════════════════════════════════════
        -- 🔽 COMPONENT: DROPDOWN COMBOBOX (Exact match to screenshot)
        -- ═══════════════════════════════════════════════════════════════════
        function TabObject:CreateDropdown(dOpt)
            dOpt = dOpt or {}
            local Title = dOpt.Title or "Dropdown"
            local Options = dOpt.Options or {}
            local Default = dOpt.Default or Options[1] or "Select..."
            local Callback = dOpt.Callback or function() end

            local currentVal = Default
            local isExpanded = false

            local DropFrame = Instance.new("Frame")
            DropFrame.Name = Title .. "Dropdown"
            DropFrame.Size = UDim2.new(1, -6, 0, 68)
            DropFrame.BackgroundTransparency = 1
            DropFrame.ClipsDescendants = false
            DropFrame.Parent = Page

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, 0, 0, 18)
            TitleLabel.Position = UDim2.new(0, 4, 0, 2)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Font = Enum.Font.GothamBold
            TitleLabel.Text = Title
            TitleLabel.TextColor3 = MhnaaUI.CurrentTheme.TextTitle
            TitleLabel.TextSize = 13
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = DropFrame

            -- Main Dropdown Button
            local SelectorBtn = Instance.new("TextButton")
            SelectorBtn.Name = "SelectorBtn"
            SelectorBtn.Size = UDim2.new(1, 0, 0, 38)
            SelectorBtn.Position = UDim2.new(0, 0, 0, 24)
            SelectorBtn.BackgroundColor3 = MhnaaUI.CurrentTheme.CardBackground
            SelectorBtn.BorderSizePixel = 0
            SelectorBtn.AutoButtonColor = false
            SelectorBtn.Text = ""
            SelectorBtn.Parent = DropFrame

            local SelCorner = Instance.new("UICorner")
            SelCorner.CornerRadius = UDim.new(0, 6)
            SelCorner.Parent = SelectorBtn

            local SelStroke = Instance.new("UIStroke")
            SelStroke.Color = MhnaaUI.CurrentTheme.CardBorder
            SelStroke.Thickness = 1
            SelStroke.Parent = SelectorBtn

            local SelectedText = Instance.new("TextLabel")
            SelectedText.Size = UDim2.new(1, -36, 1, 0)
            SelectedText.Position = UDim2.new(0, 14, 0, 0)
            SelectedText.BackgroundTransparency = 1
            SelectedText.Font = Enum.Font.Gotham
            SelectedText.Text = Title .. ": " .. tostring(currentVal)
            SelectedText.TextColor3 = MhnaaUI.CurrentTheme.TextTitle
            SelectedText.TextSize = 12
            SelectedText.TextXAlignment = Enum.TextXAlignment.Left
            SelectedText.Parent = SelectorBtn

            local Chevron = Instance.new("TextLabel")
            Chevron.Size = UDim2.new(0, 24, 1, 0)
            Chevron.Position = UDim2.new(1, -28, 0, 0)
            Chevron.BackgroundTransparency = 1
            Chevron.Font = Enum.Font.GothamBold
            Chevron.Text = "∨"
            Chevron.TextColor3 = MhnaaUI.CurrentTheme.TextMuted
            Chevron.TextSize = 13
            Chevron.Parent = SelectorBtn

            -- Expandable Option List Container
            local OptionList = Instance.new("Frame")
            OptionList.Name = "OptionList"
            OptionList.Size = UDim2.new(1, 0, 0, 0)
            OptionList.Position = UDim2.new(0, 0, 0, 66)
            OptionList.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
            OptionList.BorderSizePixel = 0
            OptionList.ClipsDescendants = true
            OptionList.Visible = false
            OptionList.ZIndex = 20
            OptionList.Parent = DropFrame

            local OptCorner = Instance.new("UICorner")
            OptCorner.CornerRadius = UDim.new(0, 6)
            OptCorner.Parent = OptionList

            local OptStroke = Instance.new("UIStroke")
            OptStroke.Color = MhnaaUI.CurrentTheme.CardBorder
            OptStroke.Thickness = 1
            OptStroke.Parent = OptionList

            local OptScroll = Instance.new("ScrollingFrame")
            OptScroll.Size = UDim2.new(1, -8, 1, -8)
            OptScroll.Position = UDim2.new(0, 4, 0, 4)
            OptScroll.BackgroundTransparency = 1
            OptScroll.BorderSizePixel = 0
            OptScroll.ScrollBarThickness = 2
            OptScroll.ScrollBarImageColor3 = Color3.fromRGB(48, 48, 56)
            OptScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            OptScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            OptScroll.ZIndex = 21
            OptScroll.Parent = OptionList

            local OptLayout = Instance.new("UIListLayout")
            OptLayout.Padding = UDim.new(0, 3)
            OptLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptLayout.Parent = OptScroll

            local function renderOptions()
                for _, child in ipairs(OptScroll:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                for _, item in ipairs(Options) do
                    local itemBtn = Instance.new("TextButton")
                    itemBtn.Size = UDim2.new(1, 0, 0, 28)
                    itemBtn.BackgroundColor3 = (item == currentVal) and Color3.fromRGB(38, 38, 45) or Color3.fromRGB(0, 0, 0)
                    itemBtn.BackgroundTransparency = (item == currentVal) and 0 or 1
                    itemBtn.BorderSizePixel = 0
                    itemBtn.Font = Enum.Font.Gotham
                    itemBtn.Text = "   " .. tostring(item)
                    itemBtn.TextColor3 = (item == currentVal) and MhnaaUI.CurrentTheme.Accent or MhnaaUI.CurrentTheme.TextTitle
                    itemBtn.TextSize = 12
                    itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                    itemBtn.ZIndex = 22
                    itemBtn.Parent = OptScroll

                    local itemCorner = Instance.new("UICorner")
                    itemCorner.CornerRadius = UDim.new(0, 4)
                    itemCorner.Parent = itemBtn

                    itemBtn.MouseEnter:Connect(function()
                        if item ~= currentVal then
                            tween(itemBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(45, 45, 52)})
                        end
                    end)
                    itemBtn.MouseLeave:Connect(function()
                        if item ~= currentVal then
                            tween(itemBtn, TweenInfo.new(0.15), {BackgroundTransparency = 1})
                        end
                    end)

                    itemBtn.MouseButton1Click:Connect(function()
                        currentVal = item
                        SelectedText.Text = Title .. ": " .. tostring(currentVal)
                        isExpanded = false
                        tween(Chevron, TweenInfo.new(0.2), {Rotation = 0})
                        tween(OptionList, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}).Completed:Connect(function()
                            OptionList.Visible = false
                            DropFrame.Size = UDim2.new(1, -6, 0, 68)
                        end)
                        renderOptions()
                        pcall(Callback, currentVal)
                    end)
                end
            end

            renderOptions()

            local function toggleDropdown()
                isExpanded = not isExpanded
                if isExpanded then
                    OptionList.Visible = true
                    local targetH = math.min(#Options * 31 + 10, 140)
                    DropFrame.Size = UDim2.new(1, -6, 0, 68 + targetH + 6)
                    tween(Chevron, TweenInfo.new(0.2), {Rotation = 180})
                    tween(OptionList, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, targetH)})
                else
                    tween(Chevron, TweenInfo.new(0.2), {Rotation = 0})
                    tween(OptionList, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}).Completed:Connect(function()
                        OptionList.Visible = false
                        DropFrame.Size = UDim2.new(1, -6, 0, 68)
                    end)
                end
            end

            SelectorBtn.MouseButton1Click:Connect(toggleDropdown)

            table.insert(Window.AllCards, {
                Title = Title,
                Desc = "",
                Frame = DropFrame
            })

            return {
                Set = function(_, val)
                    currentVal = val
                    SelectedText.Text = Title .. ": " .. tostring(currentVal)
                    renderOptions()
                    pcall(Callback, currentVal)
                end,
                SetOptions = function(_, newOptions)
                    Options = newOptions
                    renderOptions()
                end,
                GetValue = function() return currentVal end,
                Frame = DropFrame
            }
        end

        -- ═══════════════════════════════════════════════════════════════════
        -- 🎚️ COMPONENT: SLIDER
        -- ═══════════════════════════════════════════════════════════════════
        function TabObject:CreateSlider(sOpt)
            sOpt = sOpt or {}
            local Title = sOpt.Title or "Slider"
            local Min = sOpt.Min or 0
            local Max = sOpt.Max or 100
            local Default = sOpt.Default or Min
            local Suffix = sOpt.Suffix or ""
            local Decimals = sOpt.Decimals or 0
            local Callback = sOpt.Callback or function() end

            local currentVal = math.clamp(Default, Min, Max)

            local Card = Instance.new("Frame")
            Card.Name = Title .. "Slider"
            Card.Size = UDim2.new(1, -6, 0, 56)
            Card.BackgroundColor3 = MhnaaUI.CurrentTheme.CardBackground
            Card.BorderSizePixel = 0
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 6)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = MhnaaUI.CurrentTheme.CardBorder
            CardStroke.Thickness = 1
            CardStroke.Parent = Card

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(0.65, 0, 0, 20)
            TitleLabel.Position = UDim2.new(0, 12, 0, 6)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Font = Enum.Font.GothamBold
            TitleLabel.Text = Title
            TitleLabel.TextColor3 = MhnaaUI.CurrentTheme.TextTitle
            TitleLabel.TextSize = 13
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = Card

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0.3, 0, 0, 20)
            ValLabel.Position = UDim2.new(0.7, -14, 0, 6)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Font = Enum.Font.GothamMedium
            ValLabel.Text = tostring(currentVal) .. Suffix
            ValLabel.TextColor3 = MhnaaUI.CurrentTheme.Accent
            ValLabel.TextSize = 12
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = Card

            local Track = Instance.new("Frame")
            Track.Name = "Track"
            Track.Size = UDim2.new(1, -24, 0, 6)
            Track.Position = UDim2.new(0, 12, 0, 36)
            Track.BackgroundColor3 = Color3.fromRGB(44, 44, 52)
            Track.BorderSizePixel = 0
            Track.Parent = Card

            local TrackCorner = Instance.new("UICorner")
            TrackCorner.CornerRadius = UDim.new(1, 0)
            TrackCorner.Parent = Track

            local Fill = Instance.new("Frame")
            local initPct = math.clamp((currentVal - Min) / (Max - Min), 0, 1)
            Fill.Size = UDim2.new(initPct, 0, 1, 0)
            Fill.BackgroundColor3 = MhnaaUI.CurrentTheme.Accent
            Fill.BorderSizePixel = 0
            Fill.Parent = Track

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = Fill

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.new(0, 12, 0, 12)
            Knob.Position = UDim2.new(1, -6, 0.5, -6)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.BorderSizePixel = 0
            Knob.Parent = Fill

            local KnobCorner = Instance.new("UICorner")
            KnobCorner.CornerRadius = UDim.new(1, 0)
            KnobCorner.Parent = Knob

            local dragging = false

            local function updateSlider(input)
                local relX = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                Fill.Size = UDim2.new(relX, 0, 1, 0)

                local rawVal = Min + (Max - Min) * relX
                if Decimals > 0 then
                    local mult = 10 ^ Decimals
                    currentVal = math.floor(rawVal * mult) / mult
                else
                    currentVal = math.floor(rawVal)
                end

                ValLabel.Text = tostring(currentVal) .. Suffix
                pcall(Callback, currentVal)
            end

            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)

            table.insert(Window.AllCards, {
                Title = Title,
                Desc = "",
                Frame = Card
            })

            return {
                Set = function(_, val)
                    currentVal = math.clamp(val, Min, Max)
                    local pct = math.clamp((currentVal - Min) / (Max - Min), 0, 1)
                    Fill.Size = UDim2.new(pct, 0, 1, 0)
                    ValLabel.Text = tostring(currentVal) .. Suffix
                    pcall(Callback, currentVal)
                end,
                GetValue = function() return currentVal end,
                Card = Card
            }
        end

        -- ═══════════════════════════════════════════════════════════════════
        -- 🔘 COMPONENT: BUTTON
        -- ═══════════════════════════════════════════════════════════════════
        function TabObject:CreateButton(bOpt)
            bOpt = bOpt or {}
            local Title = bOpt.Title or "Button"
            local Description = bOpt.Description or ""
            local ButtonText = bOpt.ButtonText or "CLICK"
            local Callback = bOpt.Callback or function() end

            local hasDesc = Description ~= ""
            local cardHeight = hasDesc and 54 or 42

            local Card = Instance.new("Frame")
            Card.Name = Title .. "ButtonCard"
            Card.Size = UDim2.new(1, -6, 0, cardHeight)
            Card.BackgroundColor3 = MhnaaUI.CurrentTheme.CardBackground
            Card.BorderSizePixel = 0
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 6)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = MhnaaUI.CurrentTheme.CardBorder
            CardStroke.Thickness = 1
            CardStroke.Parent = Card

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -120, 0, 18)
            TitleLabel.Position = UDim2.new(0, 12, 0, hasDesc and 8 or 12)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Font = Enum.Font.GothamBold
            TitleLabel.Text = Title
            TitleLabel.TextColor3 = MhnaaUI.CurrentTheme.TextTitle
            TitleLabel.TextSize = 13
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = Card

            if hasDesc then
                local DescLabel = Instance.new("TextLabel")
                DescLabel.Size = UDim2.new(1, -120, 0, 16)
                DescLabel.Position = UDim2.new(0, 12, 0, 28)
                DescLabel.BackgroundTransparency = 1
                DescLabel.Font = Enum.Font.Gotham
                DescLabel.Text = Description
                DescLabel.TextColor3 = MhnaaUI.CurrentTheme.TextMuted
                DescLabel.TextSize = 11
                DescLabel.TextXAlignment = Enum.TextXAlignment.Left
                DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
                DescLabel.Parent = Card
            end

            local ActionBtn = Instance.new("TextButton")
            ActionBtn.Size = UDim2.new(0, 96, 0, 28)
            ActionBtn.Position = UDim2.new(1, -108, 0.5, -14)
            ActionBtn.BackgroundColor3 = MhnaaUI.CurrentTheme.Accent
            ActionBtn.BorderSizePixel = 0
            ActionBtn.Font = Enum.Font.GothamBold
            ActionBtn.Text = ButtonText
            ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            ActionBtn.TextSize = 11
            ActionBtn.Parent = Card

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 5)
            BtnCorner.Parent = ActionBtn

            ActionBtn.MouseButton1Click:Connect(function()
                tween(ActionBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 92, 0, 26), Position = UDim2.new(1, -106, 0.5, -13)})
                task.delay(0.1, function()
                    tween(ActionBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 96, 0, 28), Position = UDim2.new(1, -108, 0.5, -14)})
                end)
                pcall(Callback, ActionBtn)
            end)

            table.insert(Window.AllCards, {
                Title = Title,
                Desc = Description,
                Frame = Card
            })

            return {
                SetText = function(_, txt) ActionBtn.Text = txt end,
                Card = Card
            }
        end

        -- ═══════════════════════════════════════════════════════════════════
        -- 🏷️ COMPONENT: SECTION HEADER
        -- ═══════════════════════════════════════════════════════════════════
        function TabObject:CreateSection(titleText)
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Size = UDim2.new(1, -6, 0, 26)
            SectionFrame.BackgroundTransparency = 1
            SectionFrame.Parent = Page

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.GothamBold
            Label.Text = string.upper(titleText)
            Label.TextColor3 = MhnaaUI.CurrentTheme.SidebarText
            Label.TextSize = 11
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = SectionFrame

            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(1, 0, 0, 1)
            Line.Position = UDim2.new(0, 0, 1, -1)
            Line.BackgroundColor3 = MhnaaUI.CurrentTheme.CardBorder
            Line.BorderSizePixel = 0
            Line.Parent = SectionFrame

            return SectionFrame
        end

        -- ═══════════════════════════════════════════════════════════════════
        -- 📝 COMPONENT: TEXT INPUT
        -- ═══════════════════════════════════════════════════════════════════
        function TabObject:CreateInput(iOpt)
            iOpt = iOpt or {}
            local Title = iOpt.Title or "Input"
            local Placeholder = iOpt.Placeholder or "Type here..."
            local Default = iOpt.Default or ""
            local Callback = iOpt.Callback or function() end

            local Card = Instance.new("Frame")
            Card.Name = Title .. "InputCard"
            Card.Size = UDim2.new(1, -6, 0, 44)
            Card.BackgroundColor3 = MhnaaUI.CurrentTheme.CardBackground
            Card.BorderSizePixel = 0
            Card.Parent = Page

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 6)
            CardCorner.Parent = Card

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = MhnaaUI.CurrentTheme.CardBorder
            CardStroke.Thickness = 1
            CardStroke.Parent = Card

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
            TitleLabel.Position = UDim2.new(0, 12, 0, 0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Font = Enum.Font.GothamBold
            TitleLabel.Text = Title
            TitleLabel.TextColor3 = MhnaaUI.CurrentTheme.TextTitle
            TitleLabel.TextSize = 13
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = Card

            local BoxContainer = Instance.new("Frame")
            BoxContainer.Size = UDim2.new(0.46, 0, 0, 28)
            BoxContainer.Position = UDim2.new(0.52, 0, 0.5, -14)
            BoxContainer.BackgroundColor3 = MhnaaUI.CurrentTheme.InputBackground
            BoxContainer.BorderSizePixel = 0
            BoxContainer.Parent = Card

            local BoxCorner = Instance.new("UICorner")
            BoxCorner.CornerRadius = UDim.new(0, 4)
            BoxCorner.Parent = BoxContainer

            local BoxStroke = Instance.new("UIStroke")
            BoxStroke.Color = MhnaaUI.CurrentTheme.CardBorder
            BoxStroke.Thickness = 1
            BoxStroke.Parent = BoxContainer

            local TextBox = Instance.new("TextBox")
            TextBox.Size = UDim2.new(1, -12, 1, 0)
            TextBox.Position = UDim2.new(0, 6, 0, 0)
            TextBox.BackgroundTransparency = 1
            TextBox.Font = Enum.Font.Gotham
            TextBox.Text = Default
            TextBox.PlaceholderText = Placeholder
            TextBox.PlaceholderColor3 = MhnaaUI.CurrentTheme.TextMuted
            TextBox.TextColor3 = MhnaaUI.CurrentTheme.TextTitle
            TextBox.TextSize = 11
            TextBox.ClearTextOnFocus = false
            TextBox.Parent = BoxContainer

            TextBox.FocusLost:Connect(function(enterPressed)
                pcall(Callback, TextBox.Text, enterPressed)
            end)

            table.insert(Window.AllCards, {
                Title = Title,
                Desc = "",
                Frame = Card
            })

            return {
                Set = function(_, txt) TextBox.Text = txt end,
                Get = function() return TextBox.Text end,
                Card = Card
            }
        end

        return TabObject
    end

    -- ═══════════════════════════════════════════════════════════════════════
    -- ⚙️ PINNED UI SETTINGS TAB
    -- ═══════════════════════════════════════════════════════════════════════
    local SettingTab = Window:CreateTab({
        Name = "UI Setting",
        Icon = "⚙"
    })
    SettingTab.Button.Visible = false -- Kept hidden from standard tab list, accessed via pinned button

    SettingBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(Window.Tabs) do t.Page.Visible = false end
        for _, b in pairs(Window.TabButtons) do
            b.BackgroundTransparency = 1
            b.TextColor3 = MhnaaUI.CurrentTheme.SidebarText
        end
        SettingTab.Page.Visible = true
        Window.ActiveTab = "UI Setting"
        tween(SettingBtn, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(255, 255, 255)})
    end)

    SettingTab:CreateSection("INTERFACE PREFERENCES")
    SettingTab:CreateButton({
        Title = "Close / Unload UI",
        Description = "Safely destroys the entire user interface and listeners",
        ButtonText = "UNLOAD",
        Callback = function()
            ScreenGui:Destroy()
        end
    })

    return Window
end

return MhnaaUI
