-- // SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

-- // CLIENT & UI
local LocalPlayer = Players.LocalPlayer
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kash-001/luau-ui-libraries/refs/heads/main/KavoUiLibrary.lua"))()
local Window = Library.CreateLib("Gooning v2", "BloodTheme")

-- // WAITING FOR DATA
while not LocalPlayer:FindFirstChild("leaderstats") do
    task.wait()
end

-- // GLOBAL VARIABLES
if not _G.SellingTreshold then
    _G.SellingTreshold = 0
end

-- // STATE VARIABLES
local IsAutoFarmEnabled = false
local IsAutoMineEnabled = false
local IsAutoSellEnabled = false
local IsAutoSellFullBagEnabled = false
local IsAutoRebirthEnabled = false
local IsNotGoingBackToMine = true

-- // DYNAMIC CHARACTER VARIABLES
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- // GAME LOCALS
local Remote = ReplicatedStorage.Network:InvokeServer()
local InventoryAmount = LocalPlayer.PlayerGui.ScreenGui.StatsFrame2.Inventory.Amount
local RebirthsAmount = LocalPlayer.leaderstats.Rebirths
local DepthAmount = LocalPlayer.PlayerGui.ScreenGui.TopInfoFrame.Depth
local SellPointPosition = CFrame.new(41.96064, 15.8550873, -1239.64648, 1, 0, 0, 0, 1, 0, 0, 0, 1)

-- // FORWARD DECLARATION
local GoBackMining

-- // SECURE ANTI-AFK
local function SecureAntiAFK()
    if getconnections then
        for _, v in pairs(getconnections(LocalPlayer.Idled)) do
            v:Disable()
        end
    else
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end
SecureAntiAFK()

-- // CHARACTER HANDLER
LocalPlayer.CharacterAdded:Connect(function(NewChar)
    Character = NewChar
    HumanoidRootPart = NewChar:WaitForChild("HumanoidRootPart", 10)
    Humanoid = NewChar:WaitForChild("Humanoid", 10)

    SecureAntiAFK()

    -- AUTO-RESUME LOGIC
    if IsAutoFarmEnabled then
        task.wait(1)
        warn("Respawn detected. Resuming Autofarm...")
        GoBackMining()
    end
end)

-----------------------------------
----------- FUNCTIONS -------------
-----------------------------------

local function Split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function formatNumberThreeDigits(num)
    return string.format("%0.0f", num):reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^%s+", "")
end

local function GetInventoryAmount()
    if not InventoryAmount then return 0 end
    local Amount = InventoryAmount.Text
    Amount = Amount:gsub('%s+', '')
    Amount = Amount:gsub(',', '')

    local stringTable = Amount:split("/")
    return tonumber(stringTable[1]) or 0
end

local function IsInventoryFull()
    local Amount = InventoryAmount.Text
    Amount = Amount:gsub('%s+', '')
    Amount = Amount:gsub(',', '')

    local stringTable = Amount:split("/")
    if tonumber(stringTable[1]) == tonumber(stringTable[2]) then
        return true
    else
        return false
    end
end

local function SellInventory()
    if not HumanoidRootPart then return end

    local ActualInventorySize = GetInventoryAmount()

    while ActualInventorySize ~= 0 do
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = SellPointPosition
            Remote:FireServer("SellItems",{{}})
        else
            break
        end
        RunService.Stepped:Wait()
        ActualInventorySize = GetInventoryAmount()
    end
end

local function GetTotalCoins()
    local coins = LocalPlayer.leaderstats.Coins.value
    local StringCoins = tostring(coins)
    StringCoins = StringCoins:gsub(',', '')
    return tonumber(StringCoins)
end

local function SendError(GivenError)
    game.StarterGui:SetCore("SendNotification", {
        Title = "WARNING";
        Text = GivenError;
        Duration = 5;
    })
end

local function SendInformation(GivenInfo)
    game.StarterGui:SetCore("SendNotification", {
        Title = "INFORMATION";
        Text = GivenInfo;
        Duration = 5;
    })
end


GoBackMining = function()
    if not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then return end

    local WasAutoFarmEnabled = IsAutoFarmEnabled
    if IsAutoFarmEnabled then
        IsAutoFarmEnabled = false
        IsNotGoingBackToMine = false
    end

    pcall(function()
        Humanoid.WalkSpeed = 0
        Humanoid.JumpPower = 0
        HumanoidRootPart.Anchored = true

        Remote:FireServer("MoveTo", {{"LavaSpawn"}})

        local className = "Part"
        local parent = game.Workspace
        local part = Instance.new(className, parent)
        part.Anchored = true
        part.Size = Vector3.new(10, 0.5 , 100)
        part.Material = "ForceField"
        part.Position = Vector3.new(21, 9.5, 26285)

        task.wait(1)

        if HumanoidRootPart then HumanoidRootPart.Anchored = false end

        local startTime = tick()
        while HumanoidRootPart and HumanoidRootPart.Position.Z > 26220 do
            if tick() - startTime > 10 then break end
            HumanoidRootPart.CFrame = CFrame.new(Vector3.new(HumanoidRootPart.Position.X,13.05,HumanoidRootPart.Position.Z-0.5))
            RunService.Stepped:Wait()
        end

        if HumanoidRootPart then
            HumanoidRootPart.CFrame = CFrame.new(33, 12, 26220)
        end
        if Humanoid then
            Humanoid.WalkSpeed = 16
            Humanoid.JumpPower = 50
        end

        if part then part:Destroy() end
    end)

    if WasAutoFarmEnabled then
        task.wait(0.5)
        IsAutoFarmEnabled = true
        IsNotGoingBackToMine = true
    end
end

-----------------------------------
----------- CORE LOOPS ------------
-----------------------------------

-- 1. Main AutoFarm Loop
task.spawn(function()
    while true do
        if IsAutoFarmEnabled and Character and Humanoid and Humanoid.Health > 0 and HumanoidRootPart then
            pcall(function()
                local min = HumanoidRootPart.CFrame + Vector3.new(-10,-10,-10)
                local max = HumanoidRootPart.CFrame + Vector3.new(10,10,10)
                local region = Region3.new(min.Position, max.Position)

                local parts = workspace:FindPartsInRegion3WithWhiteList(region, {Workspace.Blocks}, 100)

                for _, block in pairs(parts) do
                    if not IsAutoFarmEnabled then break end

                    if block:IsA("BasePart") then
                        local BlockModel = block.Parent
                        Remote:FireServer("MineBlock",{{BlockModel}})
                        RunService.Stepped:Wait()
                    end

                    local InventoryContains = GetInventoryAmount()
                    if InventoryContains >= _G.SellingTreshold and IsNotGoingBackToMine and _G.SellingTreshold > 0 then
                        SellInventory()
                    end
                end
            end)
        end
        RunService.Stepped:Wait()
    end
end)

-- 2. Auto Mine Only Loop
task.spawn(function()
    while true do
        if IsAutoMineEnabled and Character and Humanoid and Humanoid.Health > 0 and HumanoidRootPart then
            pcall(function()
                local min = HumanoidRootPart.CFrame + Vector3.new(-10,-10,-10)
                local max = HumanoidRootPart.CFrame + Vector3.new(10,10,10)
                local region = Region3.new(min.Position, max.Position)
                local parts = workspace:FindPartsInRegion3WithWhiteList(region, {Workspace.Blocks}, 100)

                for _, block in pairs(parts) do
                    if not IsAutoMineEnabled then break end
                    if block:IsA("BasePart") then
                        local BlockModel = block.Parent
                        Remote:FireServer("MineBlock",{{BlockModel}})
                        RunService.Stepped:Wait()
                    end
                end
            end)
        end
        RunService.Stepped:Wait()
    end
end)

-- 3. Auto Sell Loop
task.spawn(function()
    while true do
        if IsAutoSellEnabled and _G.SellingTreshold > 0 then
             local InventoryContains = GetInventoryAmount()
             if InventoryContains >= _G.SellingTreshold then
                 SellInventory()
                 task.wait(0.5)
             end
        end
        task.wait(0.5)
    end
end)

-- 4. Auto Sell Full Bag Loop
task.spawn(function()
    while true do
        if IsAutoSellFullBagEnabled then
            if IsInventoryFull() then
                local InventoryContains = GetInventoryAmount()
                while InventoryContains ~= 0 and IsAutoSellFullBagEnabled do
                    SellInventory()
                    InventoryContains = GetInventoryAmount()
                    task.wait()
                end
            end
        end
        task.wait(0.5)
    end
end)


-----------------------------------
----------- AUTO TAB --------------
-----------------------------------
local AutosTab = Window:NewTab("Autos")
local AutosTabSection = AutosTab:NewSection("Automations")

AutosTabSection:NewToggle("AutoSell","Autosell your bag on treshold", function(state)
    IsAutoSellEnabled = state
    if state and _G.SellingTreshold <= 0 then
        SendError("Configure sell treshold !")
        IsAutoSellEnabled = false
    end
end)

AutosTabSection:NewToggle("AutoRebirth","Autorebirth when enough money", function(state)
    IsAutoRebirthEnabled = state
end)

AutosTabSection:NewToggle("AutoMine","Auto Mine blocks in 2 radius", function(state)
    IsAutoMineEnabled = state
end)

AutosTabSection:NewToggle("AutoFarm","Auto Mine / Rebirth / Sell", function(state)
    IsAutoFarmEnabled = state
    if state then
        if _G.SellingTreshold > 0 then
            GoBackMining()
        else
            SendError("Configure sell treshold !")
            IsAutoFarmEnabled = false
        end
    end
end)

-----------------------------------
----------- SELLING TAB -----------
-----------------------------------
local SellTab = Window:NewTab("Sell")
local SellTabSection = SellTab:NewSection("Selling")

SellTabSection:NewButton("One Time Sell", "Sell your inventory one time", function()
    SellInventory()
end)

SellTabSection:NewToggle("Full Bag AutoSell","Sell each time your bag is full", function(state)
    IsAutoSellFullBagEnabled = state
end)

-----------------------------------
----------- MISC TAB --------------
-----------------------------------
local MiscTab = Window:NewTab("Misc")
local MiscTabSection = MiscTab:NewSection("Misc")

MiscTabSection:NewButton("Destroy Gooning", "Kills the UI and the scripts", function()
    local KavoInstanceToDestroy = _G.isKavo
    _G.isKavo = nil
    if game.CoreGui:FindFirstChild(KavoInstanceToDestroy) then
        game.CoreGui[KavoInstanceToDestroy]:Destroy()
    end
end)

MiscTabSection:NewButton("Halloween Shop", "Opens Halloween's shop", function()
    if HumanoidRootPart then
        HumanoidRootPart.Anchored = true
        HumanoidRootPart.CFrame = Workspace.Activation.Halloween2019.CFrame
        wait(0.3)
        HumanoidRootPart.Anchored = false
    end
end)

MiscTabSection:NewButton('Classic Shop', "Opens Classic Shop", function()
    if HumanoidRootPart then
        HumanoidRootPart.Anchored = true
        HumanoidRootPart.CFrame = Workspace.Activation.Store.CFrame
        wait(0.3)
        HumanoidRootPart.Anchored = false
    end
end)


-----------------------------------
---------- CONFIG TAB -------------
-----------------------------------
local ConfigTab = Window:NewTab("Config")
local ConfigTabSection = ConfigTab:NewSection("Configurations")

local SellingTresholdLabel = ConfigTabSection:NewLabel("Selling Treshold : ".._G.SellingTreshold)

ConfigTabSection:NewTextBox("Selling Treshold", "Enter at how much blocks you sell", function(txt)
    _G.SellingTreshold = tonumber(txt)
    SendInformation("Treshold set to ".._G.SellingTreshold)
    SellingTresholdLabel:UpdateLabel("Selling Treshold : ".._G.SellingTreshold)
end)

-----------------------------------
----------- STATS TAB -------------
-----------------------------------

local StatsTab = Window:NewTab("Stats")
local StatsTabSection = StatsTab:NewSection("Statistics")

local TotalRebirthsLabel = StatsTabSection:NewLabel("Total Rebirths : "..formatNumberThreeDigits(LocalPlayer.leaderstats.Rebirths.Value))
local TotalBlocksMinedLabel = StatsTabSection:NewLabel("Total Blocks : "..formatNumberThreeDigits(LocalPlayer.leaderstats["Blocks Mined"].Value))

-----------------------------------
----------- LISTENERS -------------
-----------------------------------

if Workspace:FindFirstChild("Collapsed") then
    Workspace.Collapsed.Changed:connect(function()
        if IsAutoFarmEnabled then
            task.wait(1)
            GoBackMining()
        end
    end)
end

DepthAmount.Changed:connect(function()
    local depth = Split(DepthAmount.Text," ")
    if tonumber(depth[1]) and tonumber(depth[1]) >= 1000 then
        GoBackMining()
    end
end)

RunService:BindToRenderStep("Rebirth", Enum.RenderPriority.Camera.Value, function()
    if (IsAutoRebirthEnabled or IsAutoFarmEnabled) and GetTotalCoins() >= (10000000 * (RebirthsAmount.Value + 1)) then
        Remote:FireServer("Rebirth", {{}})
    end
end)

LocalPlayer.leaderstats["Blocks Mined"].Changed:connect(function()
    TotalBlocksMinedLabel:UpdateLabel("Total Blocks : "..formatNumberThreeDigits(LocalPlayer.leaderstats["Blocks Mined"].Value))
end)

LocalPlayer.leaderstats.Rebirths.Changed:connect(function()
    TotalRebirthsLabel:UpdateLabel("Total Blocks : "..formatNumberThreeDigits(LocalPlayer.leaderstats.Rebirths.Value))
end)

