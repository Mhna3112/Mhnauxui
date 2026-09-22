--[[
    ═══════════════════════════════════════════════════════════════════════════
    ✨ MHNAA [PRO] - UNTITLED UPGRADE TREE AUTOMATION & AUTOFARM ✨
    Game: Untitled Upgrade Tree (PlaceId: 113814738390716)
    Powered by: MhnaaUI Library
    Features:
      • Modern Dark Mhnaa [PRO] Interface with Instant Search (Ctrl+K)
      • Smart Auto Upgrade Buyer (Calculates affordability, prerequisites, formulas)
      • Turbo Auto Clicker (Clicker & Space Click)
      • Rapid Battle Stage Auto Attack & Boss Clear
      • Auto Collect Minigame Blocks & Rocks
      • Auto RNG Roll & Daily Rewards Claim
      • Auto Prestige & World Reset Automation
      • Teleport to All Worlds (Spawn, Space, Void, Genesis, Tower, etc.)
      • Movement Utilities: WalkSpeed, JumpPower, Infinite Jump, Noclip, Anti-AFK
    ═══════════════════════════════════════════════════════════════════════════
--]]

-- Cleanup previous running sessions
if _G.UUT_Mhnaa_Running then
    _G.UUT_Mhnaa_Running = false
    task.wait(0.3)
end
_G.UUT_Mhnaa_Running = true

-- LOAD MHNAA UI LIBRARY (Local file first for development, GitHub fallback)
local MhnaaUI = nil
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/MhnaaUI.luau"

local successLocal, resultLocal = pcall(function()
    if isfile and isfile("MhnaaUI.luau") then
        return loadstring(readfile("MhnaaUI.luau"))()
    elseif isfile and isfile("robloxscript/MhnaaUI.luau") then
        return loadstring(readfile("robloxscript/MhnaaUI.luau"))()
    elseif loadfile then
        local fn = loadfile("MhnaaUI.luau") or loadfile("robloxscript/MhnaaUI.luau")
        if fn then return fn() end
    end
end)

if successLocal and resultLocal then
    MhnaaUI = resultLocal
else
    local successGit, resultGit = pcall(function()
        return loadstring(game:HttpGet(GITHUB_RAW_URL))()
    end)
    if successGit and resultGit then
        MhnaaUI = resultGit
    end
end

if not MhnaaUI then
    error("[Mhnaa [PRO]] Không thể tải MhnaaUI library! Vui lòng kiểm tra kết nối mạng hoặc file MhnaaUI.luau.")
end

-- SERVICES & PLAYER
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- MODULES
local InfMaths = nil
local ConfertTable = nil
local UpgradesModule = nil
local ReadPlayerMulti = nil

pcall(function() InfMaths = require(ReplicatedStorage.Modules.InfMaths) end)
pcall(function() ConfertTable = require(ReplicatedStorage.Modules.ConfertTable) end)
pcall(function() UpgradesModule = require(ReplicatedStorage.Modules.Upgrades) end)
pcall(function() ReadPlayerMulti = require(ReplicatedStorage.Modules.ReadPlayerMulti) end)

local UpgradeDefs = {}
if UpgradesModule then
    UpgradeDefs = UpgradesModule.GiveValues and UpgradesModule.GiveValues() or UpgradesModule
end

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)

-- CONFIGURATION
local Config = {
    -- Auto Farm
    AutoClick = true,
    ClickDelay = 0.05,
    AutoBuyUpgrades = true,
    UpgradeDelay = 0.15,
    
    -- 🧠 SMART PRESTIGES ENGINE (TẤT CẢ THẾ GIỚI)
    SmartPrestiges = true,
    SmartPrestigeMultiplier = 2.5,
    SmartTargetNextUpgrade = true,
    SmartWaitBuyables = true,
    
    -- Toggles riêng từng loại Smart Prestige
    SmartOverworldPrestige = true,
    SmartOverworldEvil = true,
    SmartDarkPrestige = true,
    SmartDarkEvil = true,
    SmartAntiPrestige = true,
    SmartAntiEvil = true,
    SmartTowerPrestige = true,
    
    -- 🛡️ CHỐNG LẶP LẠI MAP ĐÃ HOÀN THÀNH (ANTI-REPEAT SHIELD)
    SkipCompletedWorlds = true,             -- Bỏ qua không bao giờ quay lại các map đã hoàn thành 100% (Galaxy, Spawn...)
    BlockCompletedResets = true,            -- Chặn tuyệt đối Prestige / Evil / Dark Prestige / Reset khi map đó đã max hết upgrade
    AutoProgressUnfinishedWorlds = false,   -- Tự động tuần tự chuyển đến map tiếp theo chưa xong (Spawn -> Galaxy -> BlackHole -> AntiWorld...)
    SafeAutoLoop = true,                    -- Không tự động Loop reset nếu đang dở dang cày cuốc map hiện tại
    
    -- Resets & Progression khác
    AutoUnlockWorlds = true,
    AutoLoop = true,
    AutoToken = true,
    AutoSupernova = true,
    AutoGodOffer = true,
    AutoBigbang = true,
    AutoAscend = true,
    AutoCycle = true,
    AutoRocketParts = true,
    
    -- World Navigation
    AutoTeleportHighestWorld = false,
    StayInCurrentWorld = true,
    SelectedWorld = "AntiWorld",
    
    -- Combat & Minigames
    AutoBattle = true,
    BattleDelay = 0.08,
    AutoCollect = true,
    AutoRoll = true,
    AutoStars = true,
    AutoDaily = true,
    
    -- Target Boosts to Stop At
    StopOnTargetBoost = true,
    StopPreset = "Custom",
    StopOnBoosts = {
        ["God"] = true,
        ["Master"] = true,
        ["Supernova"] = true,
        ["Galactic"] = true,
        ["Blackhole"] = true,
        ["Divine"] = true,
        ["Gambling"] = true,
        ["Infinity"] = true,
        ["Singularity"] = true,
        ["Origin"] = true,
        ["Evil"] = false,
        ["Rich"] = false,
    },
    
    -- Movement & Misc
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Noclip = false,
    AntiAFK = true,
}

local AutoRollToggleRef = nil

-- WORLD PROGRESSION DATA & DETECTOR
local WorldProgressionList = {
    { name = "Spawn", requiredResets = 0, coords = Vector3.new(0.0, 9.5, 1.5) },
    { name = "Galaxy", requiredResets = 3, coords = Vector3.new(-3822.0, 12.5, -4.5) },
    { name = "BlackHole", requiredResets = 5, coords = Vector3.new(4312.5, 8.0, 25.5) },
    { name = "AntiWorld", requiredResets = 6, coords = Vector3.new(-8190.5, 8.0, 25.5) },
    { name = "Supernova", requiredResets = 7, coords = Vector3.new(-3785.0, 13.5, 5084.5) },
    { name = "Genesis", requiredResets = 8, coords = Vector3.new(-8.5, 8.5, -10306.2) },
    { name = "God", requiredResets = 10, coords = Vector3.new(-10032.0, 16.7, -10708.4) },
    { name = "Bigbang", requiredResets = 11, coords = Vector3.new(-18855.0, 22.0, -5007.0) },
    { name = "Void", requiredResets = 12, coords = Vector3.new(-20620.5, 10.0, -22433.0) },
    { name = "newWorld", requiredResets = 13, coords = Vector3.new(-6199.5, 6.4, -22343.0) },
    { name = "Cycle", requiredResets = 14, coords = Vector3.new(-20663.0, 8.0, -29386.0) },
    { name = "Space", requiredResets = 15, coords = Vector3.new(9637.5, 2.0, -25526.5) },
}

local function getHighestUnlockedWorld()
    local pd = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
    if not pd or not pd:FindFirstChild("LastReset") then return "Spawn", 0, Vector3.new(0, 9.5, 1.5) end
    local lastReset = pd.LastReset.Value or 0
    local highest = WorldProgressionList[1]
    for _, w in ipairs(WorldProgressionList) do
        if lastReset >= w.requiredResets then
            highest = w
        end
    end
    return highest.name, lastReset, highest.coords
end

-- 🛡️ WORLD & CURRENCY COMPLETION DETECTORS (ANTI-REPEAT SYSTEM)
local WorldCurrencyMap = {
    ["Spawn"] = { "PrestigePoints", "EvilPoints", "Clicks" },
    ["Galaxy"] = { "GalaxyPoints", "Rocks", "Steel", "TotalRolls", "Alpha" },
    ["BlackHole"] = { "DarkEnergie", "DarkPrestigeEnergie", "DarkEvilEnergie", "Token" },
    ["AntiWorld"] = { "AntiPoint", "AntiLevelsToken", "AntiPrestigePoint", "AntiEvilPoint" },
    ["Supernova"] = { "SupernovaPoint" },
    ["Genesis"] = { "TowerPoints", "TowerPrestigePoints", "Blocks", "Units" },
    ["God"] = { "WishToken" },
    ["Bigbang"] = { "Memories" },
    ["Void"] = { "VoidCurrency" },
    ["World 2"] = { "WorldCurrency", "Coins" },
    ["Cycle"] = { "Shards", "AscendPoints" },
    ["Space"] = { "CosmicMatter", "HellPoints", "Bubbles", "RocketParts" },
}

local function getUnboughtUpgradeCount(currencyName)
    local upgFolder = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Upgrades")
    if not upgFolder then return 0 end
    local unbought = 0
    for id = 1, #UpgradeDefs do
        local def = UpgradeDefs[id]
        if def and def.CurrencyCost == currencyName then
            local curUpg = upgFolder:FindFirstChild(tostring(id))
            local maxVal = type(def.Max) == "function" and def.Max(LocalPlayer, true) or def.Max
            local val = curUpg and curUpg.Value or 0
            if not maxVal or val < maxVal then
                unbought = unbought + 1
            end
        end
    end
    return unbought
end

local function isCurrencyCompleted(currencyName)
    return getUnboughtUpgradeCount(currencyName) == 0
end

local function isWorldCompleted(worldName)
    local curList = WorldCurrencyMap[worldName]
    if not curList then return false end
    for _, cur in ipairs(curList) do
        if getUnboughtUpgradeCount(cur) > 0 then
            return false
        end
    end
    return true
end

local function getNextUnfinishedWorld()
    local pd = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
    local lastReset = pd and pd:FindFirstChild("LastReset") and pd.LastReset.Value or 0
    
    for _, w in ipairs(WorldProgressionList) do
        if lastReset >= w.requiredResets then
            if not isWorldCompleted(w.name) then
                return w.name, w.coords
            end
        end
    end
    local highest = WorldProgressionList[#WorldProgressionList]
    return highest.name, highest.coords
end

-- CURRENCY & UPGRADE CHECKERS
local function parseCurrency(valStr)
    local s = tostring(valStr or "0")
    if not InfMaths or not ConfertTable then
        return tonumber(s) or 0
    end
    local ok, t = pcall(function()
        return ConfertTable.stringToTable(s)
    end)
    if ok and t then
        return InfMaths.new(t)
    end
    return InfMaths.new(s)
end

local function canBuyUpgrade(id)
    local def = UpgradeDefs[id]
    if not def then return false end

    local upgFolder = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Upgrades")
    if not upgFolder then return false end

    local currentUpg = upgFolder:FindFirstChild(tostring(id))
    if not currentUpg then return false end

    local maxVal = type(def.Max) == "function" and def.Max(LocalPlayer, true) or def.Max
    if maxVal and currentUpg.Value >= maxVal then return false end

    -- Check Unlock Prerequisite
    local unlockId = tonumber(def.Unlock)
    if unlockId and unlockId ~= 0 then
        local prereq = upgFolder:FindFirstChild(tostring(unlockId))
        if not prereq or prereq.Value <= 0 then
            return false
        end
    end

    -- Check HasUnlock Prerequisite
    local hasUnlockId = tonumber(def.HasUnlock)
    if hasUnlockId and hasUnlockId ~= 0 then
        local prereq = upgFolder:FindFirstChild(tostring(hasUnlockId))
        if not prereq or prereq.Value <= 0 then
            return false
        end
    end

    -- Special Conditions
    local pd = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
    if not pd then return false end

    if def.Unlock == "SupernovaMilestone" and (pd:FindFirstChild("SupernovaMilestone") and pd.SupernovaMilestone.Value < (def.HasUnlock or 0)) then
        return false
    elseif def.Unlock == "Loop" and (pd:FindFirstChild("Loop") and pd.Loop.Value < (def.HasUnlock or 0)) then
        return false
    elseif def.Unlock == "Cycle" and (pd:FindFirstChild("Cycle") and pd.Cycle.Value < (def.HasUnlock or 0)) then
        return false
    elseif def.Unlock == "Stage" and (pd:FindFirstChild("Stage") and pd.Stage.Value < (def.HasUnlock or 0)) then
        return false
    elseif def.Unlock == "UnlockedSupernova" and (not pd:FindFirstChild("UnlockedSupernova") or not pd.UnlockedSupernova.Value) then
        return false
    end

    if def.HasUnlock == "Cycle" and (not pd:FindFirstChild("Cycle") or pd.Cycle.Value < 1) then
        return false
    end

    -- Cost Check
    if not def.CurrencyCost or not pd:FindFirstChild(def.CurrencyCost) then
        return false
    end

    local okAfford, canAfford = pcall(function()
        local playerCur = parseCurrency(pd[def.CurrencyCost].Value)
        local priceStr = type(def.Price) == "function" and def.Price(LocalPlayer) or def.Price
        if not priceStr or priceStr == "" then return false end

        local baseCost = InfMaths.parseAbbreviatedNumber(tostring(priceStr))
        local priceInc = tonumber(def.PriceInc) or 1
        local currentLevel = currentUpg.Value

        local totalCost
        if currentLevel == 0 or priceInc == 1 then
            totalCost = baseCost
        else
            totalCost = baseCost * (InfMaths.new(tostring(priceInc)) ^ InfMaths.new(tostring(currentLevel)))
        end

        return playerCur >= totalCost
    end)

    return okAfford and canAfford
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🧠 SMART PRESTIGE ENGINE LOGIC (ALL WORLDS)
-- ═══════════════════════════════════════════════════════════════════════════

local function hasPrerequisites(def)
    local upgFolder = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Upgrades")
    if not upgFolder then return false end
    
    local unlockId = tonumber(def.Unlock)
    if unlockId and unlockId ~= 0 then
        local prereq = upgFolder:FindFirstChild(tostring(unlockId))
        if not prereq or prereq.Value <= 0 then return false end
    end
    
    local hasUnlockId = tonumber(def.HasUnlock)
    if hasUnlockId and hasUnlockId ~= 0 then
        local prereq = upgFolder:FindFirstChild(tostring(hasUnlockId))
        if not prereq or prereq.Value <= 0 then return false end
    end
    
    return true
end

local function getNextUpgradeTargetCost(currencyName)
    local upgFolder = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Upgrades")
    if not upgFolder or not InfMaths then return nil end
    
    local lowestReachableCost = nil
    local lowestFallbackCost = nil
    
    for id = 1, #UpgradeDefs do
        local def = UpgradeDefs[id]
        if def and def.CurrencyCost == currencyName then
            local curUpg = upgFolder:FindFirstChild(tostring(id))
            local maxVal = type(def.Max) == "function" and def.Max(LocalPlayer, true) or def.Max
            local val = curUpg and curUpg.Value or 0
            if not maxVal or val < maxVal then
                local priceStr = type(def.Price) == "function" and def.Price(LocalPlayer) or def.Price
                if priceStr and priceStr ~= "" then
                    local baseCost = InfMaths.parseAbbreviatedNumber(tostring(priceStr))
                    local priceInc = tonumber(def.PriceInc) or 1
                    local cost = (val == 0 or priceInc == 1) and baseCost or (baseCost * (InfMaths.new(tostring(priceInc)) ^ InfMaths.new(tostring(val))))
                    
                    if hasPrerequisites(def) then
                        if not lowestReachableCost or cost < lowestReachableCost then
                            lowestReachableCost = cost
                        end
                    else
                        if not lowestFallbackCost or cost < lowestFallbackCost then
                            lowestFallbackCost = cost
                        end
                    end
                end
            end
        end
    end
    
    return lowestReachableCost or lowestFallbackCost
end

local function hasAffordableBuyables(currencyList)
    if not currencyList then return false end
    for _, cur in ipairs(currencyList) do
        for id = 1, #UpgradeDefs do
            local def = UpgradeDefs[id]
            if def and def.CurrencyCost == cur and canBuyUpgrade(id) then
                return true
            end
        end
    end
    return false
end

local function shouldTriggerSmartPrestige(currencyName, pendingAmount, currentAmount, primaryCurrencies)
    if not pendingAmount or pendingAmount <= InfMaths.new("0") then
        return false, "no_pending"
    end
    
    -- 🛡️ Chống lặp lại: Nếu currency của map này đã mua max 100% tất cả upgrade, KHÔNG BAO GIỜ reset nữa!
    if Config.BlockCompletedResets and isCurrencyCompleted(currencyName) then
        return false, "currency_all_upgrades_maxed"
    end
    
    -- 1. Nếu có upgrade đang mua được bằng tiền tệ hiện tại trong map, ưu tiên mua trước
    if Config.SmartWaitBuyables and primaryCurrencies and hasAffordableBuyables(primaryCurrencies) then
        return false, "waiting_for_buyables"
    end
    
    -- 2. Tìm giá của Upgrade kế tiếp trong cây kỹ năng
    local targetUpgradeCost = getNextUpgradeTargetCost(currencyName)
    local totalAfterReset = currentAmount + pendingAmount
    
    -- Nếu đạt đủ mua Upgrade kế tiếp, reset ngay để lấy nâng cấp mới!
    if Config.SmartTargetNextUpgrade and targetUpgradeCost then
        if totalAfterReset >= targetUpgradeCost then
            return true, "reached_next_upgrade"
        end
    end
    
    -- 3. Đánh giá theo Bội Số Thông Minh (Multiplier)
    if currentAmount <= InfMaths.new("0") then
        -- Khởi đầu thế giới: reset ngay khi đạt mốc tối thiểu để bắt đầu sản xuất
        local minInitial = targetUpgradeCost or InfMaths.new("0.1")
        if pendingAmount >= minInitial then
            return true, "initial_bootstrap"
        end
    else
        local mult = InfMaths.new(tostring(Config.SmartPrestigeMultiplier or 2.5))
        local targetGain = currentAmount * mult
        if pendingAmount >= targetGain then
            return true, "multiplier_gain_reached"
        end
    end
    
    return false, "waiting_for_optimal_threshold"
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ⚡ AUTOMATION BACKGROUND THREADS
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Auto Clicker Loop
task.spawn(function()
    while _G.UUT_Mhnaa_Running do
        if Config.AutoClick and Remotes then
            pcall(function()
                if Remotes:FindFirstChild("Clicker") then
                    Remotes.Clicker:FireServer()
                end
                local pd = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
                if pd and pd:FindFirstChild("WorldIn") and pd.WorldIn.Value == "Space" then
                    if Remotes:FindFirstChild("ClickedSpace") then
                        Remotes.ClickedSpace:FireServer()
                    end
                end
            end)
        end
        task.wait(Config.ClickDelay)
    end
end)

-- 2. Smart Auto Buy Upgrades Loop
task.spawn(function()
    while _G.UUT_Mhnaa_Running do
        if Config.AutoBuyUpgrades and Remotes and Remotes:FindFirstChild("BuyUpg") then
            pcall(function()
                -- Prioritize AntiLevel Token upgrades if tokens are available
                local pd = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
                local altTokens = pd and pd:FindFirstChild("AntiLevelsToken") and tonumber(pd.AntiLevelsToken.Value) or 0
                if altTokens and altTokens > 0 then
                    local tokenUpgs = {157, 158, 172, 173, 186}
                    for _, id in ipairs(tokenUpgs) do
                        if canBuyUpgrade(id) then
                            Remotes.BuyUpg:FireServer(id)
                            task.wait(0.02)
                        end
                    end
                end

                for id = 1, #UpgradeDefs do
                    if not _G.UUT_Mhnaa_Running or not Config.AutoBuyUpgrades then break end
                    if canBuyUpgrade(id) then
                        Remotes.BuyUpg:FireServer(id)
                        task.wait(0.015)
                    end
                end
            end)
        end
        task.wait(Config.UpgradeDelay)
    end
end)

-- 3. Auto Battle Attack & Combat Loop
task.spawn(function()
    while _G.UUT_Mhnaa_Running do
        if Config.AutoBattle and Remotes then
            pcall(function()
                if Remotes:FindFirstChild("BattleAttack") then
                    Remotes.BattleAttack:FireServer()
                end
                local pd = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
                if pd and pd:FindFirstChild("AutoCombat") and pd.AutoCombat.Value == false then
                    if Remotes:FindFirstChild("ChangeAutoFight") then
                        Remotes.ChangeAutoFight:FireServer()
                    end
                end
            end)
        end
        task.wait(Config.BattleDelay)
    end
end)

-- 4. Auto Collect Blocks & Rocks
task.spawn(function()
    while _G.UUT_Mhnaa_Running do
        if Config.AutoCollect and Remotes then
            pcall(function()
                if Remotes:FindFirstChild("BlockCollected") then
                    Remotes.BlockCollected:FireServer()
                end
                if Remotes:FindFirstChild("CollectRock") then
                    Remotes.CollectRock:FireServer()
                end
            end)
        end
        task.wait(0.4)
    end
end)

local function getRollCooldown()
    local upgFolder = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Upgrades")
    local u65 = upgFolder and upgFolder:FindFirstChild("65") and upgFolder["65"].Value or 0
    local u488 = upgFolder and upgFolder:FindFirstChild("488") and upgFolder["488"].Value or 0
    
    local cd = 1.0 - (0.1 * u65)
    if u488 > 0 then
        cd = cd / (4 ^ u488)
    end
    return math.clamp(cd + 0.05, 0.05, 1.0)
end

-- 5. Auto Roll Loop (Manual Bypass Mode & Target Stop)
task.spawn(function()
    while _G.UUT_Mhnaa_Running do
        if Config.AutoRoll and Remotes and Remotes:FindFirstChild("Roll") then
            pcall(function()
                local upgFolder = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Upgrades")
                local u53 = upgFolder and upgFolder:FindFirstChild("53") and upgFolder["53"].Value or 0
                if u53 >= 1 then
                    -- Passing true simulates manual roll, completely bypassing Upgrade 66 AutoRollLocked
                    local res = Remotes.Roll:InvokeServer(true)
                    
                    if typeof(res) == "table" then
                        local rolledBoost = res.Equipped or res.Kept
                        if not rolledBoost or rolledBoost == "" then
                            local pd = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
                            rolledBoost = pd and pd:FindFirstChild("CurrenctBoost") and pd.CurrenctBoost.Value
                        end
                        
                        if rolledBoost and rolledBoost ~= "" and Config.StopOnTargetBoost then
                            local shouldStop = false
                            
                            if Config.StopPreset == "At least God" then
                                shouldStop = table.find({"God", "Master", "Supernova", "Galactic", "Blackhole", "Divine", "Gambling", "Infinity", "Singularity", "Origin"}, rolledBoost) ~= nil
                            elseif Config.StopPreset == "At least Supernova" then
                                shouldStop = table.find({"Supernova", "Galactic", "Blackhole", "Divine", "Gambling", "Infinity", "Singularity", "Origin"}, rolledBoost) ~= nil
                            elseif Config.StopPreset == "At least Galactic" then
                                shouldStop = table.find({"Galactic", "Blackhole", "Divine", "Gambling", "Infinity", "Singularity", "Origin"}, rolledBoost) ~= nil
                            elseif Config.StopPreset == "At least Blackhole" then
                                shouldStop = table.find({"Blackhole", "Divine", "Gambling", "Infinity", "Singularity", "Origin"}, rolledBoost) ~= nil
                            end
                            
                            if Config.StopOnBoosts[rolledBoost] then
                                shouldStop = true
                            end
                            
                            if shouldStop then
                                Config.AutoRoll = false
                                if AutoRollToggleRef then
                                    AutoRollToggleRef:Set(false)
                                end
                                MhnaaUI:Notify({
                                    Title = "🎯 ĐÃ ROLL TRÚNG: " .. tostring(rolledBoost),
                                    Content = "Tự động dừng Auto Roll đúng theo cài đặt của bạn!",
                                    Duration = 6
                                })
                                print(string.format("[Mhnaa [PRO]] Đã trúng boost mục tiêu [%s]! Tự động dừng Auto Roll.", tostring(rolledBoost)))
                            end
                        end
                    end
                end
            end)
        end
        task.wait(getRollCooldown())
    end
end)

---- 6. Auto Unlock Worlds & Smart Progression Engine (100% Hands-Free)
local lastSeenReset = nil

task.spawn(function()
    while _G.UUT_Mhnaa_Running do
        if Config.AutoUnlockWorlds then
            pcall(function()
                local pd = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
                local upgFolder = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Upgrades")
                local otherUI = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("OtherUI")
                
                if pd and Remotes then
                    -- 1. Auto World Navigation (Tiến trình thế giới thông minh, không bao giờ lặp lại map đã xong)
                    if Config.AutoProgressUnfinishedWorlds and not Config.StayInCurrentWorld then
                        local nextWorld, coords = getNextUnfinishedWorld()
                        local currentWorld = pd:FindFirstChild("WorldIn") and pd.WorldIn.Value
                        if nextWorld and currentWorld and currentWorld ~= nextWorld then
                            if Remotes:FindFirstChild("ChangeWorld") then
                                Remotes.ChangeWorld:FireServer(nextWorld)
                                print(string.format("[Mhnaa [PRO]] 🚀 Tiến trình thông minh: Chuyển tới map đang cần cày: %s (Bỏ qua map đã xong)", nextWorld))
                                MhnaaUI:Notify({
                                    Title = "🚀 CHUYỂN TỚI MAP CẦN FARM",
                                    Content = "Map hiện tại đã xong. Đang farm tiếp: " .. nextWorld,
                                    Duration = 4
                                })
                            end
                        end
                    elseif Config.AutoTeleportHighestWorld and not Config.StayInCurrentWorld then
                        local highestWorldName, lastReset = getHighestUnlockedWorld()
                        if lastSeenReset == nil then
                            lastSeenReset = lastReset
                        elseif lastReset > lastSeenReset then
                            lastSeenReset = lastReset
                            if pd:FindFirstChild("WorldIn") and pd.WorldIn.Value ~= highestWorldName then
                                if Remotes:FindFirstChild("ChangeWorld") then
                                    Remotes.ChangeWorld:FireServer(highestWorldName)
                                    print(string.format("[Mhnaa [PRO]] 🌟 Tự động chuyển tới thế giới mới mở: %s (LastReset: %d)", highestWorldName, lastReset))
                                    MhnaaUI:Notify({
                                        Title = "🌟 THẾ GIỚI MỚI ĐÃ MỞ KHÓA!",
                                        Content = "Đã tự động dịch chuyển tới: " .. highestWorldName,
                                        Duration = 4
                                    })
                                end
                            end
                        end
                    end
                    
                    -- 2. 🧠 SMART PRESTIGES (ÁP DỤNG THÔNG MINH CHO TẤT CẢ THẾ GIỚI)
                    if Config.SmartPrestiges and ReadPlayerMulti and InfMaths then
                        -- A. Smart Anti-Prestige (Anti World)
                        if Config.SmartAntiPrestige and Remotes:FindFirstChild("AntiPrestige") then
                            if pd:FindFirstChild("UnlockedAntiPrestige") and pd.UnlockedAntiPrestige.Value == true then
                                local pendingAPP = ReadPlayerMulti.PlayerAntiPrestigePointsCount and ReadPlayerMulti.PlayerAntiPrestigePointsCount(LocalPlayer)
                                local currentAPP = parseCurrency(pd:FindFirstChild("AntiPrestigePoint") and pd.AntiPrestigePoint.Value or "0")
                                local shouldReset, reason = shouldTriggerSmartPrestige("AntiPrestigePoint", pendingAPP, currentAPP, { "AntiPoint", "AntiLevelsToken" })
                                if shouldReset then
                                    Remotes.AntiPrestige:FireServer()
                                    print(string.format("[Mhnaa [PRO]] ⚛️ Smart Anti-Prestige kích hoạt! (Lý do: %s | Nhận: %s APP$)", reason, tostring(pendingAPP)))
                                end
                            end
                        end
                        
                        -- B. Smart Anti-Evil (Anti World)
                        if Config.SmartAntiEvil and Remotes:FindFirstChild("AntiEvil") then
                            if pd:FindFirstChild("UnlockedAntiEvil") and pd.UnlockedAntiEvil.Value == true then
                                local pendingAEP = ReadPlayerMulti.PlayerAntiEvilPointsCount and ReadPlayerMulti.PlayerAntiEvilPointsCount(LocalPlayer)
                                local currentAEP = parseCurrency(pd:FindFirstChild("AntiEvilPoint") and pd.AntiEvilPoint.Value or "0")
                                local shouldReset, reason = shouldTriggerSmartPrestige("AntiEvilPoint", pendingAEP, currentAEP, { "AntiPoint", "AntiPrestigePoint", "AntiLevelsToken" })
                                if shouldReset then
                                    Remotes.AntiEvil:FireServer()
                                    print(string.format("[Mhnaa [PRO]] 😈 Smart Anti-Evil kích hoạt! (Lý do: %s | Nhận: %s AEP$)", reason, tostring(pendingAEP)))
                                end
                            end
                        end
                        
                        -- C. Smart Dark Prestige (BlackHole)
                        if Config.SmartDarkPrestige and Remotes:FindFirstChild("DarkPrestige") then
                            if pd:FindFirstChild("UnlockedDarkPrestiges") and pd.UnlockedDarkPrestiges.Value == true then
                                local pendingDPE = ReadPlayerMulti.PlayerDarkPrestigeEnergieCount and ReadPlayerMulti.PlayerDarkPrestigeEnergieCount(LocalPlayer)
                                local currentDPE = parseCurrency(pd:FindFirstChild("DarkPrestigeEnergie") and pd.DarkPrestigeEnergie.Value or "0")
                                local shouldReset, reason = shouldTriggerSmartPrestige("DarkPrestigeEnergie", pendingDPE, currentDPE, { "DarkEnergie" })
                                if shouldReset then
                                    Remotes.DarkPrestige:FireServer()
                                    print(string.format("[Mhnaa [PRO]] 🕳️ Smart Dark-Prestige kích hoạt! (Lý do: %s | Nhận: %s DPE)", reason, tostring(pendingDPE)))
                                end
                            end
                        end
                        
                        -- D. Smart Dark Evil (BlackHole)
                        if Config.SmartDarkEvil and Remotes:FindFirstChild("DarkEvil") then
                            if pd:FindFirstChild("UnlockedDarkEvil") and pd.UnlockedDarkEvil.Value == true then
                                local pendingDEE = ReadPlayerMulti.PlayerDarkEvilEnergieCount and ReadPlayerMulti.PlayerDarkEvilEnergieCount(LocalPlayer)
                                local currentDEE = parseCurrency(pd:FindFirstChild("DarkEvilEnergie") and pd.DarkEvilEnergie.Value or "0")
                                local shouldReset, reason = shouldTriggerSmartPrestige("DarkEvilEnergie", pendingDEE, currentDEE, { "DarkEnergie", "DarkPrestigeEnergie" })
                                if shouldReset then
                                    Remotes.DarkEvil:FireServer()
                                    print(string.format("[Mhnaa [PRO]] 🖤 Smart Dark-Evil kích hoạt! (Lý do: %s | Nhận: %s DEE)", reason, tostring(pendingDEE)))
                                end
                            end
                        end
                        
                        -- E. Smart Overworld Prestige & Evil
                        local loopVal = pd:FindFirstChild("Loop") and pd.Loop.Value or 0
                        if Config.SmartOverworldPrestige and Remotes:FindFirstChild("Prestige") then
                            -- Nếu Overworld Prestige đã max hết toàn bộ upgrade, tuyệt đối không reset nữa!
                            if not (Config.BlockCompletedResets and isCurrencyCompleted("PrestigePoints")) then
                                local pendingPP = ReadPlayerMulti.PlayerPrestigeCount and ReadPlayerMulti.PlayerPrestigeCount(LocalPlayer)
                                if pendingPP and pendingPP > InfMaths.new("0") then
                                    if loopVal >= 2 then
                                        -- Loop 2: Prestiges & Evils don't reset anything! Miễn phí 100%!
                                        Remotes.Prestige:FireServer()
                                    else
                                        local currentPP = parseCurrency(pd:FindFirstChild("PrestigePoints") and pd.PrestigePoints.Value or "0")
                                        local shouldReset = shouldTriggerSmartPrestige("PrestigePoints", pendingPP, currentPP, { "Points", "Clicks" })
                                        if shouldReset then
                                            Remotes.Prestige:FireServer()
                                        end
                                    end
                                end
                            end
                        end
                        if Config.SmartOverworldEvil and Remotes:FindFirstChild("Evil") then
                            -- Nếu Overworld Evil đã max hết toàn bộ upgrade, tuyệt đối không reset nữa!
                            if not (Config.BlockCompletedResets and isCurrencyCompleted("EvilPoints")) then
                                local pendingEP = ReadPlayerMulti.PlayerEvilCount and ReadPlayerMulti.PlayerEvilCount(LocalPlayer)
                                if pendingEP and pendingEP > InfMaths.new("0") then
                                    if loopVal >= 2 then
                                        Remotes.Evil:FireServer()
                                    else
                                        local currentEP = parseCurrency(pd:FindFirstChild("EvilPoints") and pd.EvilPoints.Value or "0")
                                        local shouldReset = shouldTriggerSmartPrestige("EvilPoints", pendingEP, currentEP, { "Points", "PrestigePoints" })
                                        if shouldReset then
                                            Remotes.Evil:FireServer()
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- F. Smart Tower Prestige (Genesis / Tower)
                        if Config.SmartTowerPrestige and Remotes:FindFirstChild("TowerPrestige") then
                            local pendingTPP = ReadPlayerMulti.PlayerTowerPrestigePointsCount and ReadPlayerMulti.PlayerTowerPrestigePointsCount(LocalPlayer)
                            local currentTPP = parseCurrency(pd:FindFirstChild("TowerPrestigePoints") and pd.TowerPrestigePoints.Value or "0")
                            local shouldReset, reason = shouldTriggerSmartPrestige("TowerPrestigePoints", pendingTPP, currentTPP, { "TowerPoints" })
                            if shouldReset then
                                Remotes.TowerPrestige:FireServer()
                                print(string.format("[Mhnaa [PRO]] 🗼 Smart Tower Prestige kích hoạt! (Lý do: %s)", reason))
                            end
                        end
                    end
                    
                    -- 3. Auto Loop (Advances Loop from 9 -> 10 -> 11 when level requirement reached)
                    if Config.AutoLoop and Remotes:FindFirstChild("Loop") and otherUI then
                        local allowLoop = true
                        if Config.SafeAutoLoop then
                            local currentWorld = pd:FindFirstChild("WorldIn") and pd.WorldIn.Value or "Spawn"
                            if not isWorldCompleted(currentWorld) then
                                allowLoop = false -- Đang cày dở map chưa xong, giữ an toàn không loop reset
                            end
                        end
                        if allowLoop then
                            local loopUI = otherUI:FindFirstChild("Loop")
                            if loopUI and loopUI:FindFirstChild("Main") then
                                local btn = loopUI.Main:FindFirstChild("TextButton")
                                if btn and btn.Visible then
                                    local canLoop = true
                                    for _, lbl in ipairs(loopUI:GetDescendants()) do
                                        if (lbl:IsA("TextLabel") or lbl:IsA("TextButton")) and string.find(lbl.Text, "Require") then
                                            local sanitized = string.gsub(lbl.Text, ",", "")
                                            local reqLvl = tonumber(string.match(sanitized, "(%d+)"))
                                            local curLvl = pd:FindFirstChild("Levels") and pd.Levels.Value or 0
                                            if reqLvl and curLvl < reqLvl then
                                                canLoop = false
                                            end
                                        end
                                    end
                                    if canLoop then
                                        Remotes.Loop:FireServer()
                                        print("[Mhnaa [PRO]] 🔄 Đã tự động kích hoạt Loop reset an toàn (map hiện tại đã xong)!")
                                    end
                                end
                            end
                        end
                    end
                    
                    -- 4. Auto Token Reset (BlackHole)
                    if Config.AutoToken and Remotes:FindFirstChild("Token") then
                        if pd:FindFirstChild("UnlockedToken") and pd.UnlockedToken.Value == true then
                            local u139 = upgFolder and upgFolder:FindFirstChild("139") and upgFolder["139"].Value or 0
                            local u140 = upgFolder and upgFolder:FindFirstChild("140") and upgFolder["140"].Value or 0
                            local u141 = upgFolder and upgFolder:FindFirstChild("141") and upgFolder["141"].Value or 0
                            local u142 = upgFolder and upgFolder:FindFirstChild("142") and upgFolder["142"].Value or 0
                            local tokenCount = pd:FindFirstChild("Token") and pd.Token.Value or 0
                            local tokenUpgradesDone = (u139 >= 1 and u140 >= 1 and u141 >= 1 and u142 >= 1)
                            -- Nếu đã mua hết 4 upgrade Token, tuyệt đối không reset BlackHole nữa!
                            if not (Config.BlockCompletedResets and tokenUpgradesDone) and (u139 < 1 or u140 < 1 or u141 < 1 or u142 < 1) and tokenCount < 4 then
                                Remotes.Token:FireServer()
                            end
                        end
                    end
                    
                    -- 5. Auto Supernova (Supernova World)
                    if Config.AutoSupernova and Remotes:FindFirstChild("Supernova") then
                        if otherUI and otherUI:FindFirstChild("Supernova") and otherUI.Supernova:FindFirstChild("Main") then
                            local snBtn = otherUI.Supernova.Main:FindFirstChild("TextButton")
                            if snBtn and snBtn.Visible then
                                Remotes.Supernova:FireServer()
                            end
                        elseif pd:FindFirstChild("UnlockedSupernova") and pd.UnlockedSupernova.Value == true then
                            Remotes.Supernova:FireServer()
                        end
                    end
                    
                    -- 6. Auto God Offer (Genesis / God Offer)
                    if Config.AutoGodOffer and Remotes:FindFirstChild("GodOffer") then
                        if otherUI and otherUI:FindFirstChild("God") and otherUI.God:FindFirstChild("Main") then
                            local gBtn = otherUI.God.Main:FindFirstChild("TextButton")
                            if gBtn and gBtn.Visible then
                                Remotes.GodOffer:FireServer()
                            end
                        end
                    end
                    
                    -- 9. Auto Bigbang, Ascend, Cycle & RocketParts
                    if Config.AutoBigbang and Remotes:FindFirstChild("Bigbang") then
                        local u348 = upgFolder and upgFolder:FindFirstChild("348") and upgFolder["348"].Value or 0
                        if u348 >= 1 then
                            Remotes.Bigbang:FireServer()
                        end
                    end
                    if Config.AutoAscend and Remotes:FindFirstChild("Ascend") then
                        if ReadPlayerMulti and InfMaths then
                            local pendingAT = ReadPlayerMulti.PlayerAscendTokenCount and ReadPlayerMulti.PlayerAscendTokenCount(LocalPlayer)
                            if pendingAT and (pendingAT > InfMaths.new("0")) then
                                Remotes.Ascend:FireServer()
                            end
                        end
                    end
                    if Config.AutoCycle and Remotes:FindFirstChild("Cycle") then
                        local u405 = upgFolder and upgFolder:FindFirstChild("405") and upgFolder["405"].Value or 0
                        if u405 >= 1 then
                            Remotes.Cycle:FireServer()
                        end
                    end
                    if Config.AutoRocketParts and Remotes:FindFirstChild("RocketParts") then
                        if otherUI and otherUI:FindFirstChild("RocketParts") and otherUI.RocketParts:FindFirstChild("Main") then
                            local rBtn = otherUI.RocketParts.Main:FindFirstChild("TextButton")
                            if rBtn and rBtn.Visible then
                                Remotes.RocketParts:FireServer()
                            end
                        end
                    end
                    
                    -- 10. Star & Daily claims
                    if Config.AutoStars and Remotes:FindFirstChild("Stars") then
                        Remotes.Stars:FireServer()
                    end
                    if Config.AutoDaily and Remotes:FindFirstChild("Daily") then
                        Remotes.Daily:FireServer()
                    end
                end
            end)
        end
        task.wait(0.35)
    end
end)

-- 7. Movement & Player Utilities
RunService.Stepped:Connect(function()
    if not _G.UUT_Mhnaa_Running then return end
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if Config.WalkSpeed ~= 16 then
                humanoid.WalkSpeed = Config.WalkSpeed
            end
            if Config.JumpPower ~= 50 then
                humanoid.JumpPower = Config.JumpPower
            end
        end
        
        if Config.Noclip then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if _G.UUT_Mhnaa_Running and Config.InfiniteJump then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if _G.UUT_Mhnaa_Running and Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎨 BUILD MHNAA [PRO] USER INTERFACE
-- ═══════════════════════════════════════════════════════════════════════════
local Window = MhnaaUI:CreateWindow({
    Title = "Mhnaa",
    Tag = "[PRO]",
    Game = "UNTITLED UPGRADE TREE",
    Size = UDim2.new(0, 680, 0, 420),
    AccentColor = Color3.fromRGB(104, 157, 248),
    ToggleKey = Enum.KeyCode.RightControl
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 1: AUTO FARM
-- ═══════════════════════════════════════════════════════════════════════════
local FarmTab = Window:CreateTab({
    Name = "Auto Farm",
    Icon = "⚡"
})

FarmTab:CreateSection("CLICKER & UPGRADE AUTOMATION")

FarmTab:CreateToggle({
    Title = "Auto Clicker",
    Description = "Spams clicker and space clicks automatically for fastest progression",
    Default = Config.AutoClick,
    Callback = function(val)
        Config.AutoClick = val
    end
})

FarmTab:CreateSlider({
    Title = "Clicker Delay",
    Min = 0.01,
    Max = 0.3,
    Default = Config.ClickDelay,
    Decimals = 2,
    Suffix = "s",
    Callback = function(val)
        Config.ClickDelay = val
    end
})

FarmTab:CreateToggle({
    Title = "Smart Auto Upgrades",
    Description = "Automatically buys all affordable, unlocked upgrades across the entire tree",
    Default = Config.AutoBuyUpgrades,
    Callback = function(val)
        Config.AutoBuyUpgrades = val
    end
})

FarmTab:CreateSlider({
    Title = "Upgrade Scan Delay",
    Min = 0.05,
    Max = 1.0,
    Default = Config.UpgradeDelay,
    Decimals = 2,
    Suffix = "s",
    Callback = function(val)
        Config.UpgradeDelay = val
    end
})

FarmTab:CreateSection("⭐ SMART PRESTIGES ENGINE (TẤT CẢ THẾ GIỚI)")

FarmTab:CreateToggle({
    Title = "Kích Hoạt Smart Prestiges",
    Description = "Tự động phân tích sản lượng & mục tiêu upgrade để reset đúng thời điểm tối ưu",
    Default = Config.SmartPrestiges,
    Callback = function(val)
        Config.SmartPrestiges = val
    end
})

FarmTab:CreateSlider({
    Title = "Smart Gain Multiplier",
    Min = 1.5,
    Max = 10.0,
    Default = Config.SmartPrestigeMultiplier,
    Decimals = 1,
    Suffix = "x",
    Callback = function(val)
        Config.SmartPrestigeMultiplier = val
    end
})

FarmTab:CreateToggle({
    Title = "Reset Ngay Khi Đủ Điểm Mua Upgrade Tiếp Theo",
    Description = "Tự động nhận diện nâng cấp kế tiếp trong cây và kích hoạt reset ngay khi đủ điểm",
    Default = Config.SmartTargetNextUpgrade,
    Callback = function(val)
        Config.SmartTargetNextUpgrade = val
    end
})

FarmTab:CreateToggle({
    Title = "Ưu Tiên Mua Hết Upgrade Trước Khi Reset",
    Description = "Đảm bảo mua hết tất cả nâng cấp khả dụng trong thế giới trước khi xoá điểm",
    Default = Config.SmartWaitBuyables,
    Callback = function(val)
        Config.SmartWaitBuyables = val
    end
})

FarmTab:CreateSection("CÀI ĐẶT PRESTIGE TỪNG THẾ GIỚI")

FarmTab:CreateToggle({
    Title = "Smart Anti-Prestige (Anti World)",
    Description = "Reset Anti Points & Levels thông minh khi đạt APP$ tối ưu cho Anti World",
    Default = Config.SmartAntiPrestige,
    Callback = function(val)
        Config.SmartAntiPrestige = val
    end
})

FarmTab:CreateToggle({
    Title = "Smart Anti-Evil (Anti World)",
    Description = "Tự động kích hoạt Anti Evil khi đủ điều kiện và đạt lợi nhuận cao nhất",
    Default = Config.SmartAntiEvil,
    Callback = function(val)
        Config.SmartAntiEvil = val
    end
})

FarmTab:CreateToggle({
    Title = "Smart Dark Prestige (BlackHole)",
    Description = "Reset Dark Prestige thông minh tại thế giới BlackHole",
    Default = Config.SmartDarkPrestige,
    Callback = function(val)
        Config.SmartDarkPrestige = val
    end
})

FarmTab:CreateToggle({
    Title = "Smart Dark Evil (BlackHole)",
    Description = "Reset Dark Evil thông minh tại BlackHole",
    Default = Config.SmartDarkEvil,
    Callback = function(val)
        Config.SmartDarkEvil = val
    end
})

FarmTab:CreateToggle({
    Title = "Smart Overworld Prestige & Evil",
    Description = "Tự động Prestige & Evil Overworld (Miễn phí 100% khi đạt Loop 2)",
    Default = Config.SmartOverworldPrestige,
    Callback = function(val)
        Config.SmartOverworldPrestige = val
        Config.SmartOverworldEvil = val
    end
})

FarmTab:CreateToggle({
    Title = "Smart Tower Prestige (Genesis)",
    Description = "Tự động reset Tower Prestige khi đạt mốc tối ưu",
    Default = Config.SmartTowerPrestige,
    Callback = function(val)
        Config.SmartTowerPrestige = val
    end
})

FarmTab:CreateToggle({
    Title = "Auto Loop Reset",
    Description = "Tự động chuyển Loop ngay khi đủ cấp độ yêu cầu",
    Default = Config.AutoLoop,
    Callback = function(val)
        Config.AutoLoop = val
    end
})

FarmTab:CreateToggle({
    Title = "Auto Supernova",
    Description = "Kích hoạt Supernova khi khả dụng",
    Default = Config.AutoSupernova,
    Callback = function(val)
        Config.AutoSupernova = val
    end
})

FarmTab:CreateToggle({
    Title = "Auto Token Reset (BlackHole)",
    Description = "Tự động reset Token trong BlackHole khi cần mở nâng cấp mới",
    Default = Config.AutoToken,
    Callback = function(val)
        Config.AutoToken = val
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 2: COMBAT & MINIGAMES
-- ═══════════════════════════════════════════════════════════════════════════
local CombatTab = Window:CreateTab({
    Name = "Combat & Drops",
    Icon = "⚔"
})

CombatTab:CreateSection("BATTLE STAGE COMBAT")

CombatTab:CreateToggle({
    Title = "Auto Battle Attack",
    Description = "Rapidly fires battle attacks against stage bosses and clears battle waves",
    Default = Config.AutoBattle,
    Callback = function(val)
        Config.AutoBattle = val
    end
})

CombatTab:CreateSlider({
    Title = "Battle Attack Delay",
    Min = 0.02,
    Max = 0.3,
    Default = Config.BattleDelay,
    Decimals = 2,
    Suffix = "s",
    Callback = function(val)
        Config.BattleDelay = val
    end
})

CombatTab:CreateSection("MINIGAMES & DROP COLLECTORS")

CombatTab:CreateToggle({
    Title = "Auto Collect Blocks & Rocks",
    Description = "Automatically collects floating blocks and spawned rocks for extra points",
    Default = Config.AutoCollect,
    Callback = function(val)
        Config.AutoCollect = val
    end
})

CombatTab:CreateSection("RNG AUTO ROLL & TARGET BOOSTS (TỰ ĐỘNG DỪNG)")

AutoRollToggleRef = CombatTab:CreateToggle({
    Title = "Auto Roll (RNG)",
    Description = "Tự động quay RNG và tự dừng ngay khi quay trúng các Boost mong muốn bên dưới",
    Default = Config.AutoRoll,
    Callback = function(val)
        Config.AutoRoll = val
    end
})

CombatTab:CreateDropdown({
    Title = "Chọn Preset Dừng Nhanh",
    Options = {
        "Custom (Theo các tick bên dưới)",
        "At least God (God, Master, Supernova+)",
        "At least Supernova (Supernova, Galactic+)",
        "At least Galactic (Galactic, Blackhole+)",
        "At least Blackhole (Blackhole+)"
    },
    Default = "Custom (Theo các tick bên dưới)",
    Callback = function(selected)
        if string.find(selected, "God") then
            Config.StopPreset = "At least God"
        elseif string.find(selected, "Supernova") then
            Config.StopPreset = "At least Supernova"
        elseif string.find(selected, "Galactic") then
            Config.StopPreset = "At least Galactic"
        elseif string.find(selected, "Blackhole") then
            Config.StopPreset = "At least Blackhole"
        else
            Config.StopPreset = "Custom"
        end
    end
})

CombatTab:CreateToggle({
    Title = "Dừng khi trúng: God (1%)",
    Description = "x50 Luck cho lần Roll kế tiếp",
    Default = Config.StopOnBoosts["God"],
    Callback = function(val) Config.StopOnBoosts["God"] = val end
})

CombatTab:CreateToggle({
    Title = "Dừng khi trúng: Master (0.5%)",
    Description = "x2 P$, x2 Exp",
    Default = Config.StopOnBoosts["Master"],
    Callback = function(val) Config.StopOnBoosts["Master"] = val end
})

CombatTab:CreateToggle({
    Title = "Dừng khi trúng: Supernova (0.1%)",
    Description = "x1.5 all currency (Overworld, Galaxy, Blackhole & Anti World)",
    Default = Config.StopOnBoosts["Supernova"],
    Callback = function(val) Config.StopOnBoosts["Supernova"] = val end
})

CombatTab:CreateToggle({
    Title = "Dừng khi trúng: Galactic (1 in 10k)",
    Description = "x2 all currency (Overworld, Galaxy, Blackhole & Anti World)",
    Default = Config.StopOnBoosts["Galactic"],
    Callback = function(val) Config.StopOnBoosts["Galactic"] = val end
})

CombatTab:CreateToggle({
    Title = "Dừng khi trúng: Blackhole (1 in 100k)",
    Description = "x2.5 all currency (Overworld, Galaxy, Blackhole & Anti World)",
    Default = Config.StopOnBoosts["Blackhole"],
    Callback = function(val) Config.StopOnBoosts["Blackhole"] = val end
})

CombatTab:CreateToggle({
    Title = "Dừng khi trúng: Divine & Cao Hơn (1 in 3M+)",
    Description = "Bao gồm Divine, Gambling, Infinity, Singularity, Origin",
    Default = Config.StopOnBoosts["Divine"],
    Callback = function(val)
        Config.StopOnBoosts["Divine"] = val
        Config.StopOnBoosts["Gambling"] = val
        Config.StopOnBoosts["Infinity"] = val
        Config.StopOnBoosts["Singularity"] = val
        Config.StopOnBoosts["Origin"] = val
    end
})

CombatTab:CreateToggle({
    Title = "Dừng khi trúng: Evil (2%)",
    Description = "x2 Ep$",
    Default = Config.StopOnBoosts["Evil"],
    Callback = function(val) Config.StopOnBoosts["Evil"] = val end
})

CombatTab:CreateToggle({
    Title = "Dừng khi trúng: Rich (7.5%)",
    Description = "x1.2 all currency (Overworld, Galaxy, Blackhole & Anti World)",
    Default = Config.StopOnBoosts["Rich"],
    Callback = function(val) Config.StopOnBoosts["Rich"] = val end
})

CombatTab:CreateToggle({
    Title = "Auto Claim Stars",
    Description = "Claims star currency rewards on interval",
    Default = Config.AutoStars,
    Callback = function(val)
        Config.AutoStars = val
    end
})

CombatTab:CreateToggle({
    Title = "Auto Daily Reward",
    Description = "Claims daily reward instantly when available",
    Default = Config.AutoDaily,
    Callback = function(val)
        Config.AutoDaily = val
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 3: TELEPORT & WORLDS
-- ═══════════════════════════════════════════════════════════════════════════
local WorldTab = Window:CreateTab({
    Name = "Worlds & Teleport",
    Icon = "🚀"
})

WorldTab:CreateSection("🛡️ CHỐNG LẶP LẠI MAP ĐÃ HOÀN THÀNH (ANTI-REPEAT)")

WorldTab:CreateToggle({
    Title = "Bỏ Qua Map Đã Xong (Skip Completed Worlds)",
    Description = "Tuyệt đối không bao giờ quay lại hay farm các map đã hoàn thành 100% (Galaxy, Spawn...)",
    Default = Config.SkipCompletedWorlds,
    Callback = function(val)
        Config.SkipCompletedWorlds = val
    end
})

WorldTab:CreateToggle({
    Title = "Chặn Reset / Prestige Các Map Đã Max",
    Description = "Chặn hoàn toàn việc kích hoạt Prestige/Evil/Dark Prestige khi map đó đã mua max hết upgrade",
    Default = Config.BlockCompletedResets,
    Callback = function(val)
        Config.BlockCompletedResets = val
    end
})

WorldTab:CreateToggle({
    Title = "Auto Farm Tuần Tự (Smart World Flow)",
    Description = "Tự động chuyển tới map tiếp theo chưa xong, xong map nào qua map đó, không lặp lại map cũ",
    Default = Config.AutoProgressUnfinishedWorlds,
    Callback = function(val)
        Config.AutoProgressUnfinishedWorlds = val
    end
})

WorldTab:CreateToggle({
    Title = "Chỉ Loop Khi Xong Map Hiện Tại (Safe Auto Loop)",
    Description = "Không bao giờ tự ý Loop reset khi bạn đang dở dang cày cuốc map chưa hoàn thành",
    Default = Config.SafeAutoLoop,
    Callback = function(val)
        Config.SafeAutoLoop = val
    end
})

WorldTab:CreateButton({
    Title = "🎯 Dịch Chuyển Tới Map Cần Cày Kế Tiếp",
    Description = "Tự động phát hiện và đưa bạn tới map đang cần cày tiếp theo (Bỏ qua map đã xong)",
    Callback = function()
        local nextWorld, coords = getNextUnfinishedWorld()
        if Remotes and Remotes:FindFirstChild("ChangeWorld") then
            Remotes.ChangeWorld:FireServer(nextWorld)
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and coords then hrp.CFrame = CFrame.new(coords) end
            end)
            MhnaaUI:Notify({ Title = "🚀 Tiến Trình Thế Giới", Content = "Đang chuyển tới map cần cày: " .. nextWorld, Duration = 3 })
        end
    end
})

WorldTab:CreateSection("🌟 QUẢN LÝ TIẾN TRÌNH THẾ GIỚI (HANDS-FREE)")

WorldTab:CreateToggle({
    Title = "Tự Động Mở Map & Điều Kiện",
    Description = "Tự động hoàn thành và mở khóa toàn bộ điều kiện map mới 100% không cần chạm tay",
    Default = Config.AutoUnlockWorlds,
    Callback = function(val)
        Config.AutoUnlockWorlds = val
    end
})

WorldTab:CreateToggle({
    Title = "Giữ Nguyên Map Hiện Tại (Không Ép Chuyển)",
    Description = "Không tự ý chuyển map để bạn thoải mái cày cuốc tại Anti World hoặc bất kỳ map nào",
    Default = Config.StayInCurrentWorld,
    Callback = function(val)
        Config.StayInCurrentWorld = val
    end
})

WorldTab:CreateToggle({
    Title = "Tự Động Vào Map Mới (Chỉ Khi Vừa Unlock Lần Đầu)",
    Description = "Chỉ tự động dịch chuyển 1 lần duy nhất khi vừa mở khóa thành công thế giới mới",
    Default = Config.AutoTeleportHighestWorld,
    Callback = function(val)
        Config.AutoTeleportHighestWorld = val
    end
})

WorldTab:CreateToggle({
    Title = "Tự Động Loop (Loop 9 -> 10 -> 11...)",
    Description = "Tự động kích hoạt Loop reset ngay khi đủ điều kiện level",
    Default = Config.AutoLoop,
    Callback = function(val)
        Config.AutoLoop = val
    end
})

WorldTab:CreateToggle({
    Title = "Tự Động Supernova / Genesis / Tower",
    Description = "Tự động kích hoạt Supernova và Tower Prestige khi khả dụng",
    Default = Config.AutoSupernova,
    Callback = function(val)
        Config.AutoSupernova = val
    end
})

WorldTab:CreateToggle({
    Title = "Tự Động God Offer, Bigbang & Ascend",
    Description = "Tự động cúng dường God Offer, kích hoạt Big Bang và Ascend",
    Default = Config.AutoBigbang,
    Callback = function(val)
        Config.AutoGodOffer = val
        Config.AutoBigbang = val
        Config.AutoAscend = val
        Config.AutoCycle = val
        Config.AutoRocketParts = val
    end
})

WorldTab:CreateSection("⚡ DỊCH CHUYỂN NHANH 1-CHẠM (QUICK TRAVEL)")

WorldTab:CreateButton({
    Title = "🚀 Dịch Chuyển Tới Anti World",
    Description = "Vào ngay Anti World để cày Anti Points & Anti Levels",
    Callback = function()
        if Remotes and Remotes:FindFirstChild("ChangeWorld") then
            Remotes.ChangeWorld:FireServer("AntiWorld")
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(Vector3.new(-8190.5, 8.0, 25.5)) end
            end)
            MhnaaUI:Notify({ Title = "Thế Giới", Content = "Đang vào Anti World...", Duration = 3 })
        end
    end
})

WorldTab:CreateButton({
    Title = "🕳️ Dịch Chuyển Tới BlackHole",
    Description = "Vào BlackHole để cày Dark Energie & Token",
    Callback = function()
        if Remotes and Remotes:FindFirstChild("ChangeWorld") then
            Remotes.ChangeWorld:FireServer("BlackHole")
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(Vector3.new(4312.5, 8.0, 25.5)) end
            end)
            MhnaaUI:Notify({ Title = "Thế Giới", Content = "Đang vào BlackHole...", Duration = 3 })
        end
    end
})

WorldTab:CreateButton({
    Title = "🌍 Dịch Chuyển Tới Overworld (Spawn)",
    Description = "Về thế giới ban đầu để cày Level, Points, Clicks",
    Callback = function()
        if Remotes and Remotes:FindFirstChild("ChangeWorld") then
            Remotes.ChangeWorld:FireServer("Spawn")
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(Vector3.new(0.0, 9.5, 1.5)) end
            end)
            MhnaaUI:Notify({ Title = "Thế Giới", Content = "Đang về Overworld...", Duration = 3 })
        end
    end
})

WorldTab:CreateSection("DỊCH CHUYỂN THỦ CÔNG TỚI MAP")

WorldTab:CreateDropdown({
    Title = "Chọn Thế Giới Mục Tiêu",
    Options = {
        "Spawn",
        "Galaxy",
        "BlackHole",
        "AntiWorld",
        "Supernova",
        "Genesis",
        "God",
        "Bigbang",
        "Void",
        "newWorld",
        "Cycle",
        "Space"
    },
    Default = Config.SelectedWorld,
    Callback = function(selected)
        Config.SelectedWorld = selected
    end
})

WorldTab:CreateButton({
    Title = "Dịch Chuyển Tới Map Đã Chọn",
    Description = "Gửi lệnh chuyển map và dịch chuyển tọa độ nhân vật",
    Callback = function()
        if Remotes and Remotes:FindFirstChild("ChangeWorld") then
            Remotes.ChangeWorld:FireServer(Config.SelectedWorld)
            
            -- Set character position if available
            pcall(function()
                for _, w in ipairs(WorldProgressionList) do
                    if w.name == Config.SelectedWorld and w.coords then
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = CFrame.new(w.coords)
                        end
                    end
                end
            end)
            
            MhnaaUI:Notify({
                Title = "Chuyển Thế Giới",
                Content = "Đang chuyển tới: " .. Config.SelectedWorld,
                Duration = 3
            })
        end
    end
})

WorldTab:CreateButton({
    Title = "Dịch Chuyển Tới Map Cao Nhất Đã Mở",
    Description = "Tự động nhận diện và dịch chuyển tới map cao nhất bạn đã unlock",
    Callback = function()
        local highestWorldName, lastReset, coords = getHighestUnlockedWorld()
        if Remotes and Remotes:FindFirstChild("ChangeWorld") then
            Remotes.ChangeWorld:FireServer(highestWorldName)
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and coords then
                    hrp.CFrame = CFrame.new(coords)
                end
            end)
            MhnaaUI:Notify({
                Title = "Map Cao Nhất: " .. highestWorldName,
                Content = string.format("LastReset: %d | Đã vào %s!", lastReset, highestWorldName),
                Duration = 4
            })
        end
    end
})

WorldTab:CreateSection("KÍCH HOẠT RESET THỦ CÔNG")

WorldTab:CreateButton({
    Title = "Kích Hoạt Loop Reset",
    Description = "Fires Loop remote",
    Callback = function()
        if Remotes and Remotes:FindFirstChild("Loop") then
            Remotes.Loop:FireServer()
            MhnaaUI:Notify({ Title = "Loop", Content = "Đã gửi tín hiệu Loop!", Duration = 2 })
        end
    end
})

WorldTab:CreateButton({
    Title = "Kích Hoạt Ascend",
    Description = "Fires Ascend remote",
    Callback = function()
        if Remotes and Remotes:FindFirstChild("Ascend") then
            Remotes.Ascend:FireServer()
            MhnaaUI:Notify({ Title = "Ascend", Content = "Ascend triggered!", Duration = 2 })
        end
    end
})

WorldTab:CreateButton({
    Title = "Kích Hoạt Cycle",
    Description = "Fires Cycle remote",
    Callback = function()
        if Remotes and Remotes:FindFirstChild("Cycle") then
            Remotes.Cycle:FireServer()
            MhnaaUI:Notify({ Title = "Cycle", Content = "Cycle triggered!", Duration = 2 })
        end
    end
})

WorldTab:CreateButton({
    Title = "Kích Hoạt Bigbang",
    Description = "Fires Bigbang remote",
    Callback = function()
        if Remotes and Remotes:FindFirstChild("Bigbang") then
            Remotes.Bigbang:FireServer()
            MhnaaUI:Notify({ Title = "Bigbang", Content = "Bigbang triggered!", Duration = 2 })
        end
    end
})

WorldTab:CreateButton({
    Title = "Cúng Dường God Offer",
    Description = "Fires GodOffer remote",
    Callback = function()
        if Remotes and Remotes:FindFirstChild("GodOffer") then
            Remotes.GodOffer:FireServer()
            MhnaaUI:Notify({ Title = "GodOffer", Content = "GodOffer triggered!", Duration = 2 })
        end
    end
})

-- ═══════════════════════════════════════════════════════════════════════════
-- TAB 4: PLAYER & UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════
local MiscTab = Window:CreateTab({
    Name = "Player & Misc",
    Icon = "👤"
})

MiscTab:CreateSection("MOVEMENT MODIFICATIONS")

MiscTab:CreateSlider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Suffix = " studs/s",
    Callback = function(val)
        Config.WalkSpeed = val
    end
})

MiscTab:CreateSlider({
    Title = "JumpPower",
    Min = 50,
    Max = 300,
    Default = 50,
    Suffix = " power",
    Callback = function(val)
        Config.JumpPower = val
    end
})

MiscTab:CreateToggle({
    Title = "Infinite Jump",
    Description = "Allows infinite jumping in mid-air",
    Default = Config.InfiniteJump,
    Callback = function(val)
        Config.InfiniteJump = val
    end
})

MiscTab:CreateToggle({
    Title = "Noclip",
    Description = "Walk through walls and obstacles without collision",
    Default = Config.Noclip,
    Callback = function(val)
        Config.Noclip = val
    end
})

MiscTab:CreateSection("UTILITIES & SYSTEM")

MiscTab:CreateToggle({
    Title = "Anti-AFK",
    Description = "Prevents Roblox 20-minute idle disconnection",
    Default = Config.AntiAFK,
    Callback = function(val)
        Config.AntiAFK = val
    end
})

MiscTab:CreateButton({
    Title = "Rejoin Server",
    Description = "Rejoins the same server instance",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

MiscTab:CreateButton({
    Title = "Unload / Close Script",
    Description = "Stops all background loops and closes Mhnaa UI",
    Callback = function()
        _G.UUT_Mhnaa_Running = false
        pcall(function()
            if Window.Gui and Window.Gui.Parent then
                Window.Gui:Destroy()
            end
        end)
    end
})

MhnaaUI:Notify({
    Title = "Mhnaa [PRO]",
    Content = "Untitled Upgrade Tree AutoFarm loaded successfully!",
    Duration = 3
})

print("[Mhnaa [PRO]] Untitled Upgrade Tree script initialized successfully!")
