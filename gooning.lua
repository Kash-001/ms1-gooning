-- UI LOCALS
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
-- local Window = Library.CreateLib("Gooning", "DarkTheme")
local Window = Library.CreateLib("Gooning", "BloodTheme")
-- local Window = Library.CreateLib("Gooning", "Synapse")
_G.SellingTreshold = 0

-- GMAE LOCALS
local LocalPlayer = game.Players.LocalPlayer
local Remote = game.ReplicatedStorage.Network:InvokeServer()
local Character = LocalPlayer.Character
local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
local InventoryAmount = LocalPlayer.PlayerGui.ScreenGui.StatsFrame2.Inventory.Amount
local Blocks = game.Workspace.Blocks

-- TP SELL LOCALS
local x = -117.57
local y = 10.39
local z = 42.77

-----------------------------------
----------- FUNCTIONS -------------
-----------------------------------
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
        HumanoidRootPart.CFrame = CFrame.new(x,y,z)
        Remote:FireServer("SellItems",{{               }})
        wait()
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

        while IsAutoRebirthEnabled do
            if GetTotalCoins() >= GetRebirthPrice() then
                Remote:FireServer("Rebirth",{{					                }})
            end
            wait(0.2)
        end
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
                        wait()
                    end
                end
            end
            wait()
        end
    else
        IsAutoMineEnabled = false
    end
end)

AutosTabSection:NewToggle("AutoFarm","Auto Mine / Rebirth / Sell", function(state)
    if state then
        if _G.SellingTreshold ~= 0 then
            IsAutoFarmEnabled = true

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
                            wait()
                        end
                        InventoryContains = GetInventoryAmount()
                        if InventoryContains >= _G.SellingTreshold then
                            SellInventory()
                            wait(0.2)
                            Remote:FireServer("Rebirth",{{					                }})
                        end
                    end
                end
                wait()
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
