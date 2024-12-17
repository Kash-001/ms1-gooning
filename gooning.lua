-- UI LOCALS
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kash-001/luau-ui-libraries/refs/heads/main/KavoUiLibrary.lua"))()
-- local Window = Library.CreateLib("Gooning", "DarkTheme")
local Window = Library.CreateLib("Gooning", "BloodTheme")
-- local Window = Library.CreateLib("Gooning", "Synapse")

-- GLOBAL VARIABLES
if not _G.SellingTreshold then
    _G.SellingTreshold = 0
end

-- GAME LOCALS
local LocalPlayer = game.Players.LocalPlayer
local Remote = game.ReplicatedStorage.Network:InvokeServer()
local RunService = game:GetService("RunService")
local RunServiceStepped = game:GetService("RunService").Stepped
local Character = LocalPlayer.Character
local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
local InventoryAmount = LocalPlayer.PlayerGui.ScreenGui.StatsFrame2.Inventory.Amount
local Humanoid = Character:WaitForChild("Humanoid")
local Blocks = game.Workspace.Blocks
local GC = getconnections or get_signal_cons
local cloneref = cloneref or function(o) return o end
local RebirthsAmount = LocalPlayer.leaderstats.Rebirths
local DepthAmount = LocalPlayer.PlayerGui.ScreenGui.TopInfoFrame.Depth

-- POSITIONS
local SellPointPosition = CFrame.new(41.96064, 15.8550873, -1239.64648, 1, 0, 0, 0, 1, 0, 0, 0, 1)

-----------------------------------
----------- FUNCTIONS -------------
-----------------------------------
local function Split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function GetInventoryAmount()
	local Amount = InventoryAmount.Text
	Amount = Amount:gsub('%s+', '')
	Amount = Amount:gsub(',', '')
	
	local stringTable = Amount:split("/")
	return tonumber(stringTable[1])
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
    local ActualInventorySize = GetInventoryAmount()

    while ActualInventorySize ~= 0 do
        HumanoidRootPart.CFrame = SellPointPosition
        Remote:FireServer("SellItems",{{}})
        RunServiceStepped:Wait()
        ActualInventorySize = GetInventoryAmount()
    end
end

local function GetTotalCoins()
    local coins = LocalPlayer.leaderstats.Coins.value
    local StringCoins = tostring(coins)
    StringCoins = StringCoins:gsub(',', '')

	return tonumber(StringCoins)
end

local function GetTotalRebirths()
    local rebirths = LocalPlayer.leaderstats.Rebirths.value
    local StringRebirths = tostring(rebirths)    
    StringRebirths = StringRebirths:gsub(',', '')

	return tonumber(StringRebirths)
end

local function GetRebirthPrice()
    return tonumber((GetTotalRebirths() + 1) * 10000000)
end

local function SendError(GivenError)
    game.StarterGui:SetCore("SendNotification", {
        Title = "WARNING",
        Text = GivenError,
        Duration = 5,
    })
end

local function SendInformation(GivenInfo)
    game.StarterGui:SetCore("SendNotification", {
        Title = "INFORMATION",
        Text = GivenInfo,
        Duration = 5,
    })
end

local function GoBackMining()
    if IsAutoFarmEnabled then
        IsAutoFarmEnabled = false
        local WasAutoFarmEnabled = true
    end

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
    local pos = Vector3.new(21, 9.5, 26285)
    part.Position = pos
    wait(1)
    HumanoidRootPart.Anchored = false
    while HumanoidRootPart.Position.Z > 26220 do
        HumanoidRootPart.CFrame = CFrame.new(Vector3.new(HumanoidRootPart.Position.X,13.05,HumanoidRootPart.Position.Z-0.5))
        wait()
    end
    HumanoidRootPart.CFrame = CFrame.new(33, 12, 26220)
    Humanoid.WalkSpeed = 16
    Humanoid.JumpPower = 50
    
    if WasAutoFarmEnabled then
        wait(1)
        IsAutoFarmEnabled = true
    end
end

-----------------------------------
----------- AUTO TAB --------------
-----------------------------------
local AutosTab = Window:NewTab("Autos")
local AutosTabSection = AutosTab:NewSection("Automations")

local InventoryContains = GetInventoryAmount()
local IsAutoSellEnabled = false
local IsAutoRebirthEnabled = false
local IsAutoMineEnabled = false
local IsAutoFarmEnabled = false

AutosTabSection:NewToggle("AutoSell","Autosell your bag on treshold", function(state)
    if state then
        if _G.SellingTreshold > 0 then
            IsAutoSellEnabled = true

            while IsAutoSellEnabled do
                InventoryContains = GetInventoryAmount()
                if InventoryContains >= _G.SellingTreshold then
                    SellInventory()
                    wait(0.5)
                end
                wait()
            end
        else
            SendError("Configure sell treshold !")
        end
    else
        IsAutoSellEnabled = false
    end
end)

AutosTabSection:NewToggle("AutoRebirth","Autorebirth when enough money", function(state)
    if state then
        IsAutoRebirthEnabled = true
    else
        IsAutoRebirthEnabled = false
    end
end)

AutosTabSection:NewToggle("AutoMine","Auto Mine blocks in 2 radius", function(state)
    if state then
        IsAutoMineEnabled = true

        while IsAutoMineEnabled do
			if HumanoidRootPart then
                local min = HumanoidRootPart.CFrame + Vector3.new(-10,-10,-10)
                local max = HumanoidRootPart.CFrame + Vector3.new(10,10,10)
                local region = Region3.new(min.Position, max.Position)
                local parts = workspace:FindPartsInRegion3WithWhiteList(region, {game.Workspace.Blocks}, 100)

                for each, block in pairs(parts) do
                    if block:IsA("BasePart") then
                        local BlockModel = block.Parent
                        Remote:FireServer("MineBlock",{{BlockModel}})
                        RunServiceStepped:Wait()
                    end
                end
            end
            RunServiceStepped:Wait()
        end
    else
        IsAutoMineEnabled = false
    end
end)

AutosTabSection:NewToggle("AutoFarm","Auto Mine / Rebirth / Sell", function(state)
    if state then
        if _G.SellingTreshold > 0 then
            IsAutoFarmEnabled = true
            GoBackMining()

            while IsAutoFarmEnabled do
                if HumanoidRootPart then
                    local min = HumanoidRootPart.CFrame + Vector3.new(-10,-10,-10)
                    local max = HumanoidRootPart.CFrame + Vector3.new(10,10,10)
                    local region = Region3.new(min.Position, max.Position)
                    local parts = workspace:FindPartsInRegion3WithWhiteList(region, {game.Workspace.Blocks}, 100)

                    for each, block in pairs(parts) do
                        if block:IsA("BasePart") then
                            local BlockModel = block.Parent
                            Remote:FireServer("MineBlock",{{BlockModel}})
                            RunServiceStepped:Wait()
                        end
                        InventoryContains = GetInventoryAmount()
                        if InventoryContains >= _G.SellingTreshold then
                            SellInventory()
                            wait(0.2)
                            Remote:FireServer("Rebirth",{{}})
                        end
                    end
                end
                RunServiceStepped:Wait()
            end
        else
            SendError("Configure sell treshold !")
        end
    else
        IsAutoFarmEnabled = false
    end
end)
-----------------------------------
----------- SELLING TAB -----------
-----------------------------------
local SellTab = Window:NewTab("Sell")
local SellTabSection = SellTab:NewSection("Selling")

local IsAutoSellFullBagEnabled = false

SellTabSection:NewButton("One Time Sell", "Sell your inventory one time", function()
    InventoryContains = GetInventoryAmount()
    while InventoryContains ~= 0 do
        SellInventory()
        wait()
    end
end)

SellTabSection:NewToggle("Full Bag AutoSell","Sell each time your bag is full", function(state)
    if state then
        IsAutoSellFullBagEnabled = true

        while IsAutoSellFullBagEnabled do
            if IsInventoryFull() then
                InventoryContains = GetInventoryAmount()
                while InventoryContains ~= 0 do
                    SellInventory()
                    InventoryContains = GetInventoryAmount()
                    wait()
                end
            end
            wait()
        end
    else
        IsAutoSellFullBagEnabled = false
    end
end)


-----------------------------------
----------- MISC TAB --------------
-----------------------------------
local MiscTab = Window:NewTab("Misc")
local MiscTabSection = MiscTab:NewSection("Misc")

MiscTabSection:NewButton("Anti AFK", "Enable Anti AFK (no disable)", function()
    if GC then
        for i,v in pairs(GC(LocalPlayer.Idled)) do
            if v["Disable"] then
                v["Disable"](v)
            elseif v["Disconnect"] then
                v["Disconnect"](v)
            end
        end
    else
        local VirtualUser = cloneref(game:GetService("VirtualUser"))
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

MiscTabSection:NewButton("Destroy Gooning", "Kills the UI and the scripts", function()
    local KavoInstanceToDestroy = _G.isKavo
    _G.isKavo = nil
    game.CoreGui[KavoInstanceToDestroy]:Destroy()
end)

MiscTabSection:NewButton("Halloween Shop", "Opens Halloween's shop", function()
    HumanoidRootPart.CFrame = game.workspace.Activation.Halloween2019.CFrame
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
----------- LISTENERS -------------
-----------------------------------
game.Workspace.Collapsed.Changed:connect(function()
    if IsAutoFarmEnabled then
	    wait(1)
        GoBackMining()
    end
end)

DepthAmount.Changed:connect(function()
    local depth = Split(DepthAmount.Text," ")
    if tonumber(depth[1]) >= 1000 then
        GoBackMining()
    end
end)

RunService:BindToRenderStep("Rebirth", Enum.RenderPriority.Camera.Value, function()
    if (IsAutoRebirthEnabled or IsAutoFarmEnabled) and GetCoinsAmount() >= (10000000 * (RebirthsAmount.Value + 1)) then
        Remote:FireServer("Rebirth", {{}})
    end
end)
