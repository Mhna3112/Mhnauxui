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
    
    -- Auto World Progression (Tự động mở map & điều kiện hands-free)
    AutoUnlockWorlds = true,
    AutoTeleportHighestWorld = true,
    SmartAutoResets = true,
    AutoPrestige = true,
    AutoEvil = true,
    AutoLoop = true,
    AutoDarkPrestige = true,
    AutoDarkEvil = true,
    AutoToken = true,
    AutoAntiPrestige = true,
    AutoAntiEvil = true,
    AutoSupernova = true,
    AutoTowerPrestige = true,
    AutoGodOffer = true,
    AutoBigbang = true,
    AutoAscend = true,
    AutoCycle = true,
    AutoRocketParts = true,
    
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
    
    -- World Selected
    SelectedWorld = "Spawn",
    
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

-- 6. Auto Unlock Worlds & Smart Progression Engine (100% Hands-Free)
task.spawn(function()
    while _G.UUT_Mhnaa_Running do
        if Config.AutoUnlockWorlds then
            pcall(function()
                local pd = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("PlayerData")
                local upgFolder = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Upgrades")
                local otherUI = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("OtherUI")
                
                if pd and Remotes then
                    -- 1. Auto Highest World Navigation & Unlocking
                    local highestWorldName, lastReset = getHighestUnlockedWorld()
                    if Config.AutoTeleportHighestWorld and pd:FindFirstChild("WorldIn") then
                        if pd.WorldIn.Value ~= highestWorldName then
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
                    
                    -- 2. Smart Auto Prestige & Evil Resets (Fast & Frequent Gains)
                    if Config.SmartAutoResets and ReadPlayerMulti and InfMaths then
                        -- Prestige check
                        if Config.AutoPrestige and Remotes:FindFirstChild("Prestige") then
                            local pendingPP = ReadPlayerMulti.PlayerPrestigeCount(LocalPlayer)
                            local currentPP = parseCurrency(pd:FindFirstChild("PrestigePoints") and pd.PrestigePoints.Value or "0")
                            if pendingPP and (pendingPP > InfMaths.new("0")) then
                                if currentPP < InfMaths.new("1e12") or pendingPP >= (currentPP * InfMaths.new("0.1")) then
                                    Remotes.Prestige:FireServer()
                                end
                            end
                        end
                        
                        -- Evil check
                        if Config.AutoEvil and Remotes:FindFirstChild("Evil") then
                            local pendingEP = ReadPlayerMulti.PlayerEvilCount(LocalPlayer)
                            local currentEP = parseCurrency(pd:FindFirstChild("EvilPoints") and pd.EvilPoints.Value or "0")
                            if pendingEP and (pendingEP > InfMaths.new("0")) then
                                if currentEP < InfMaths.new("1e12") or pendingEP >= (currentEP * InfMaths.new("0.1")) then
                                    Remotes.Evil:FireServer()
                                end
                            end
                        end
                    end
                    
                    -- 3. Auto Loop (Advances Loop from 9 -> 10 -> 11 when level requirement reached)
                    if Config.AutoLoop and Remotes:FindFirstChild("Loop") and otherUI then
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
                                    print("[Mhnaa [PRO]] 🔄 Đã tự động kích hoạt Loop reset thành công!")
                                end
                            end
                        end
                    end
                    
                    -- 4. Auto Dark Prestige (BlackHole)
                    if Config.AutoDarkPrestige and Remotes:FindFirstChild("DarkPrestige") then
                        if ReadPlayerMulti and InfMaths and pd:FindFirstChild("UnlockedDarkPrestiges") and pd.UnlockedDarkPrestiges.Value == true then
                            local pendingDPE = ReadPlayerMulti.PlayerDarkPrestigeEnergieCount and ReadPlayerMulti.PlayerDarkPrestigeEnergieCount(LocalPlayer)
                            local currentDPE = parseCurrency(pd:FindFirstChild("DarkPrestigeEnergie") and pd.DarkPrestigeEnergie.Value or "0")
                            if pendingDPE and (pendingDPE > InfMaths.new("0")) then
                                if currentDPE < InfMaths.new("1e6") or pendingDPE >= (currentDPE * InfMaths.new("0.1")) then
                                    Remotes.DarkPrestige:FireServer()
                                end
                            end
                        end
                    end
                    
                    -- 5. Auto Dark Evil (BlackHole)
                    if Config.AutoDarkEvil and Remotes:FindFirstChild("DarkEvil") then
                        if ReadPlayerMulti and InfMaths and pd:FindFirstChild("UnlockedDarkEvil") and pd.UnlockedDarkEvil.Value == true then
                            local pendingDEE = ReadPlayerMulti.PlayerDarkEvilEnergieCount and ReadPlayerMulti.PlayerDarkEvilEnergieCount(LocalPlayer)
                            local currentDEE = parseCurrency(pd:FindFirstChild("DarkEvilEnergie") and pd.DarkEvilEnergie.Value or "0")
                            if pendingDEE and (pendingDEE > InfMaths.new("0")) then
                                if currentDEE < InfMaths.new("1e6") or pendingDEE >= (currentDEE * InfMaths.new("0.1")) then
                                    Remotes.DarkEvil:FireServer()
                                end
                            end
                        end
                    end
                    
                    -- 5b. Auto Token Reset (BlackHole)
                    if Config.AutoToken and Remotes:FindFirstChild("Token") then
                        if pd:FindFirstChild("UnlockedToken") and pd.UnlockedToken.Value == true then
                            local u139 = upgFolder and upgFolder:FindFirstChild("139") and upgFolder["139"].Value or 0
                            local u140 = upgFolder and upgFolder:FindFirstChild("140") and upgFolder["140"].Value or 0
                            local u141 = upgFolder and upgFolder:FindFirstChild("141") and upgFolder["141"].Value or 0
                            local u142 = upgFolder and upgFolder:FindFirstChild("142") and upgFolder["142"].Value or 0
                            local tokenCount = pd:FindFirstChild("Token") and pd.Token.Value or 0
                            if (u139 < 1 or u140 < 1 or u141 < 1 or u142 < 1) and tokenCount < 4 then
                                Remotes.Token:FireServer()
                            end
                        end
                    end
                    
                    -- 6. Auto Anti Prestige & Anti Evil (Anti World)
                    if Config.AutoAntiPrestige and Remotes:FindFirstChild("AntiPrestige") then
                        if ReadPlayerMulti and InfMaths and pd:FindFirstChild("UnlockedAntiPrestige") and pd.UnlockedAntiPrestige.Value == true then
                            local pendingAPP = ReadPlayerMulti.PlayerAntiPrestigePointsCount and ReadPlayerMulti.PlayerAntiPrestigePointsCount(LocalPlayer)
                            local currentAPP = parseCurrency(pd:FindFirstChild("AntiPrestigePoint") and pd.AntiPrestigePoint.Value or "0")
                            if pendingAPP and (pendingAPP > InfMaths.new("0")) then
                                if (currentAPP < InfMaths.new("5") and pendingAPP >= InfMaths.new("1")) or (pendingAPP >= (currentAPP * InfMaths.new("0.1"))) then
                                    Remotes.AntiPrestige:FireServer()
                                end
                            end
                        end
                    end
                    if Config.AutoAntiEvil and Remotes:FindFirstChild("AntiEvil") then
                        if ReadPlayerMulti and InfMaths and pd:FindFirstChild("UnlockedAntiEvil") and pd.UnlockedAntiEvil.Value == true then
                            local pendingAEP = ReadPlayerMulti.PlayerAntiEvilPointsCount and ReadPlayerMulti.PlayerAntiEvilPointsCount(LocalPlayer)
                            local currentAEP = parseCurrency(pd:FindFirstChild("AntiEvilPoint") and pd.AntiEvilPoint.Value or "0")
                            if pendingAEP and (pendingAEP > InfMaths.new("0")) then
                                if (currentAEP < InfMaths.new("5") and pendingAEP >= InfMaths.new("1")) or (pendingAEP >= (currentAEP * InfMaths.new("0.1"))) then
                                    Remotes.AntiEvil:FireServer()
                                end
                            end
                        end
                    end
                    
                    -- 7. Auto Supernova (Supernova World)
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
                    
                    -- 8. Auto Tower Prestige & God Offer (Genesis / God Offer)
                    if Config.AutoTowerPrestige and Remotes:FindFirstChild("TowerPrestige") then
                        if ReadPlayerMulti and InfMaths then
                            local pendingTPP = ReadPlayerMulti.PlayerTowerPrestigePointsCount and ReadPlayerMulti.PlayerTowerPrestigePointsCount(LocalPlayer)
                            if pendingTPP and (pendingTPP > InfMaths.new("0")) then
                                Remotes.TowerPrestige:FireServer()
                            end
                        end
                    end
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

FarmTab:CreateSection("PRESTIGE & RESETS")

FarmTab:CreateToggle({
    Title = "Auto Prestige (Safe)",
    Description = "Automatically prestiges when PP can be gained",
    Default = Config.AutoPrestige,
    Callback = function(val)
        Config.AutoPrestige = val
    end
})

FarmTab:CreateToggle({
    Title = "Auto Evil Reset",
    Description = "Triggers Evil reset when available",
    Default = Config.AutoEvil,
    Callback = function(val)
        Config.AutoEvil = val
    end
})

FarmTab:CreateToggle({
    Title = "Auto Dark Prestige",
    Description = "Automatically triggers Dark Prestige when available",
    Default = Config.AutoDarkPrestige,
    Callback = function(val)
        Config.AutoDarkPrestige = val
    end
})

FarmTab:CreateToggle({
    Title = "Auto Supernova",
    Description = "Triggers Supernova reset when available",
    Default = Config.AutoSupernova,
    Callback = function(val)
        Config.AutoSupernova = val
    end
})

FarmTab:CreateToggle({
    Title = "Auto Anti Prestige",
    Description = "Tự động reset Anti Prestige khi đạt điểm tối ưu",
    Default = Config.AutoAntiPrestige,
    Callback = function(val)
        Config.AutoAntiPrestige = val
    end
})

FarmTab:CreateToggle({
    Title = "Auto Anti Evil",
    Description = "Tự động reset Anti Evil khi khả dụng",
    Default = Config.AutoAntiEvil,
    Callback = function(val)
        Config.AutoAntiEvil = val
    end
})

FarmTab:CreateToggle({
    Title = "Auto Loop Reset",
    Description = "Tự động Loop khi đủ điều kiện level yêu cầu",
    Default = Config.AutoLoop,
    Callback = function(val)
        Config.AutoLoop = val
    end
})

FarmTab:CreateToggle({
    Title = "Auto Token Reset (BlackHole)",
    Description = "Tự động reset Token trong Blackhole khi cần mở upgrade",
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

WorldTab:CreateSection("🌟 TỰ ĐỘNG MỞ TẤT CẢ MAP (HANDS-FREE)")

WorldTab:CreateToggle({
    Title = "Tự Động Mở Map & Điều Kiện",
    Description = "Tự động hoàn thành và mở khóa toàn bộ điều kiện map mới 100% không cần chạm tay",
    Default = Config.AutoUnlockWorlds,
    Callback = function(val)
        Config.AutoUnlockWorlds = val
    end
})

WorldTab:CreateToggle({
    Title = "Tự Động Vào Map Mới Nhất",
    Description = "Ngay khi map mới được unlock, script tự động dịch chuyển nhân vật vào map đó",
    Default = Config.AutoTeleportHighestWorld,
    Callback = function(val)
        Config.AutoTeleportHighestWorld = val
    end
})

WorldTab:CreateToggle({
    Title = "Smart Auto-Reset (Prestige & Evil)",
    Description = "Tự động reset khi đạt số nhân tối ưu hoặc cần mở khóa upgrade thế giới tiếp theo",
    Default = Config.SmartAutoResets,
    Callback = function(val)
        Config.SmartAutoResets = val
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
    Title = "Tự Động Dark Prestige & Dark Evil",
    Description = "Tự động reset tài nguyên Dark tại thế giới BlackHole",
    Default = Config.AutoDarkPrestige,
    Callback = function(val)
        Config.AutoDarkPrestige = val
        Config.AutoDarkEvil = val
    end
})

WorldTab:CreateToggle({
    Title = "Tự Động Anti Prestige & Anti Evil",
    Description = "Tự động reset Anti Points tại thế giới Anti World",
    Default = Config.AutoAntiPrestige,
    Callback = function(val)
        Config.AutoAntiPrestige = val
        Config.AutoAntiEvil = val
    end
})

WorldTab:CreateToggle({
    Title = "Tự Động Supernova / Genesis / Tower",
    Description = "Tự động kích hoạt Supernova và Tower Prestige khi khả dụng",
    Default = Config.AutoSupernova,
    Callback = function(val)
        Config.AutoSupernova = val
        Config.AutoTowerPrestige = val
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
