local defaults = {
	displayName = "|cFF00FFIsJusta|r |cffffffGamepad Inventory Update|r",
	name = "IsJustaGamepadInventory",
	version = "2.2.1",

	filterStolen = true,
	stolenCategory = true,
	filterJunk = true,
	junkCategory = true,
	filterMaps = true,
	mapsCategory = true,
}

local svVersion = 2.1

local savedVars = {}
---------------------------------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------------------------------
local IJA_GPInventory = ZO_CallbackObject:Subclass()

function IJA_GPInventory:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function IJA_GPInventory:Initialize(control)
	self.control = control
    self.control:RegisterForEvent( EVENT_ADD_ON_LOADED, function( ... ) self:OnLoaded( ... ) end )
end

-- update saves
function IJA_GPInventory:OnLoaded(event, addon)
    self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
	self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function(eventCode, ...) self:OnPlayerActivated(...) end)
	
	self.displayName	= defaults.displayName
	self.name 			= defaults.name
	self.version 		= defaults.version
	
	local AccountWideSavedVars = ZO_SavedVars:NewAccountWide("IJA_GPInventory_SavedVars", svVersion, nil, defaults, GetWorldName())
	self.sv = AccountWideSavedVars
	savedVars = self.sv
	
	self:SetupSettings()
	self:InitJunkSort()
end

function IJA_GPInventory:OnPlayerActivated()
	self.control:UnregisterForEvent(EVENT_PLAYER_ACTIVATED)

	self:AddInventoryActions()
	d( self.displayName .. " version: " .. self.version)
end

---------------------------------------------------------------------------------------------------------------
-- Settings menu
---------------------------------------------------------------------------------------------------------------
function IJA_GPInventory:SetupSettings()
	local LAM2 = LibAddonMenu2
	if not LAM2 then
		return
	end

	local panelData = {
		type = "panel",
		name = self.name,
		displayName = self.displayName,
		author = "IsJustaGhost",
		version = self.version,
		registerForRefresh = true,
		registerForDefaults = true
	}
	LAM2:RegisterAddonPanel(self.name, panelData)

	local optionsTable = {
		{
            type = "header",
            name = GetString(SI_IJA_GPINVENTORY_CATEGORIES),
            width = "full",
        },
		{
			type = "checkbox",
			name = GetString(SI_IJA_GPINVENTORY_CATEGORY_MAPS),
			tooltip = GetString(SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP),
			getFunc = function() return self.sv.mapsCategory end,
			setFunc = function(value) 
				self.sv.mapsCategory = value 
				if value ~= true then self.sv.filterMaps = value end
			end,
            width = "half"
		},
		{
			type = "checkbox",
			name = GetString(SI_IJA_GPINVENTORY_FILTER_MAPS),
			tooltip = GetString(SI_IJA_GPINVENTORY_FILTER_MAPS_TOOLTIP),
			getFunc = function() return self.sv.filterMaps end,
			setFunc = function(value) self.sv.filterMaps = value end,
            width = "half",
			disabled = function() return not self.sv.mapsCategory end,
		},
		{
			type = "checkbox",
			name = GetString(SI_IJA_GPINVENTORY_CATEGORY_JUNK),
			tooltip = GetString(SI_IJA_GPINVENTORY_CATEGORY_JUNK_TOOLTIP),
			getFunc = function() return self.sv.junkCategory end,
			setFunc = function(value) 
				self.sv.junkCategory = value 
				if value ~= true then self.sv.filterJunk = value end
			end,
            width = "half"
		},
		{
			type = "checkbox",
			name = GetString(SI_IJA_GPINVENTORY_FILTER_JUNK),
			tooltip = GetString(SI_IJA_GPINVENTORY_FILTER_JUNK_TOOLTIP),
			getFunc = function() return self.sv.filterJunk end,
			setFunc = function(value) self.sv.filterJunk = value end,
            width = "half",
			disabled = function() return not self.sv.junkCategory end,
		},
		{
			type = "checkbox",
			name = GetString(SI_IJA_GPINVENTORY_CATEGORY_STOLEN),
			tooltip = GetString(SI_IJA_GPINVENTORY_CATEGORY_STOLEN_TOOLTIP),
			getFunc = function() return self.sv.stolenCategory end,
			setFunc = function(value) 
				self.sv.stolenCategory = value 
				if value ~= true then self.sv.filterStolen = value end
			end,
            width = "half"
		},
		{
			type = "checkbox",
			name = GetString(SI_IJA_GPINVENTORY_FILTER_STOLEN),
			tooltip = GetString(SI_IJA_GPINVENTORY_FILTER_STOLEN_TOOLTIP),
			getFunc = function() return self.sv.filterStolen end,
			setFunc = function(value) self.sv.filterStolen = value end,
            width = "half",
			disabled = function() return not self.sv.stolenCategory end,
		},

		{
			type = "checkbox",
			name = GetString(SI_IJA_GPINVENTORY_SORTBANK_WITHDRAW),
			tooltip = GetString(SI_IJA_GPINVENTORY_SORTBANK_WITHDRAW_TOOLTIP),
			getFunc = function() return self.sv.withdraw end,
			setFunc = function(value) self.sv.withdraw = value end,
            width = "half"
		},
		{
			type = "checkbox",
			name = GetString(SI_IJA_GPINVENTORY_SORTBANK_DEPOSIT),
			tooltip = GetString(SI_IJA_GPINVENTORY_SORTBANK_DEPOSIT_TOOLTIP),
			getFunc = function() return self.sv.deposit end,
			setFunc = function(value) self.sv.deposit = value end,
            width = "half",
		}
	}
	LAM2:RegisterOptionControls(self.name, optionsTable)
end

---------------------------------------------------------------------------------------------------------------
-- Helper functions
---------------------------------------------------------------------------------------------------------------
local INVENTORY_CATEGORY_LIST = "categoryList"
local INVENTORY_ITEM_LIST = "itemList"
local INVENTORY_CRAFT_BAG_LIST = "craftBagList"

local specialized_itemtype_map_survey_report = {
	[SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP] = true,
	[SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT] = true,
}

local isCutomCategory = {
	[ITEMFILTERTYPE_MAPS] = true,
	[ITEMFILTERTYPE_JUNK] = true,
	[ITEMFILTERTYPE_STOLEN] = true,
}
		
local function isItemMap(itemData)
	return specialized_itemtype_map_survey_report[itemData.specializedItemType] or false
end

local function filterDisabled(itemData)
	if isItemMap(itemData) then
		return not IJA_GPINVENTORY.sv.filterMaps
	end
	if itemData.stolen then
		return not IJA_GPINVENTORY.sv.filterStolen
	end
	if itemData.isJunk then
		return not IJA_GPINVENTORY.sv.filterJunk
	end
end

local function categoryNotEmpty(filterType)
	local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_BACKPACK)
	for slotId, itemData in pairs(bagCache) do
		if filterType == ITEMFILTERTYPE_JUNK then
			if (itemData.isJunk and not itemData.stolen) then
				return true
			end
		elseif filterType == ITEMFILTERTYPE_MAPS then
			if isItemMap(itemData) then
				return true
			end
		elseif filterType == ITEMFILTERTYPE_STOLEN then
			if itemData.stolen then
				return true
			end
		else
			if not itemData.isJunk or not itemData.stolen then
				for i, filter in ipairs(itemData.filterData) do
					if filter == filterType then
						return true
					end
				end
			end
		end
	end
end

local shouldAddItem = {
	[ITEMFILTERTYPE_ALL] = function(itemData)
		if itemData.stolen or itemData.isJunk or isItemMap(itemData) then
			return filterDisabled(itemData)
		else
			return true
		end
	end,
	[ITEMFILTERTYPE_MAPS] = function(itemData)
		if isItemMap(itemData) then
			if itemData.isJunk or itemData.stolen then
				return filterDisabled(itemData)
			end
			return true
		end
	end,
	[ITEMFILTERTYPE_JUNK] = function(itemData)
		if itemData.isJunk then
			if itemData.stolen then
				return filterDisabled(itemData)
			end
			return true
		end
	end,
	[ITEMFILTERTYPE_STOLEN] = function(itemData)
		return itemData.stolen
	end
}

---------------------------------------------------------------------------------------------------------------
-- Merch/Bank junk sort
---------------------------------------------------------------------------------------------------------------
function IJA_GPInventory:InitJunkSort()
	-------------------------------------
	-- Gamepad Merchant Inventory List
	-------------------------------------
	local gamePadSellModeList = STORE_WINDOW_GAMEPAD.components[ZO_MODE_STORE_SELL].list
	ZO_PostHook(gamePadSellModeList, "UpdateList", function(self)
		self:Clear()
		local items = self.updateFunc(self.searchContext)
		table.sort(items, SellSortFunc)
		self:AddItems(items)
	end)

	-------------------------------------
	-- Initialize Gamepad Guild Bank Deposit Sort
	-------------------------------------
	local guildBankSCene = SCENE_MANAGER:GetScene("gamepad_guild_bank")
	guildBankSCene:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_SHOWING then
			guildBankSCene:UnregisterCallback("StateChange")
			GAMEPAD_GUILD_BANK.depositList:SetSortFunction(sortJunkToBottom)
		elseif newState == SCENE_SHOWN then
		end
	end)
	
	
	-------------------------------------
	-- Initialize Gamepad Bank Inventory Sort
	-------------------------------------
	local ENTRY_ORDER_CURRENCY = 1
	local ENTRY_ORDER_OTHER = 2
	local gamepadBankSCene = SCENE_MANAGER:GetScene("gamepad_banking")
	gamepadBankSCene:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_SHOWING then
			gamepadBankSCene:UnregisterCallback("StateChange")
			
			GAMEPAD_BANKING.withdrawList.list:SetSortFunction(function(left, right)
				local leftOrder = ENTRY_ORDER_OTHER
				if left.isCurrenciesMenuEntry or left.currencyType then
					leftOrder = ENTRY_ORDER_CURRENCY
				end
				
				local rightOrder = ENTRY_ORDER_OTHER
				if right.isCurrenciesMenuEntry or right.currencyType then
					rightOrder = ENTRY_ORDER_CURRENCY
				end
				
				if leftOrder < rightOrder then
					return true
				elseif leftOrder > rightOrder then
					return false
				elseif leftOrder == ENTRY_ORDER_OTHER then
		--               return ZO_TableOrderingFunction(left, right, self:GetCurrentSortParams())
					
					if left.isJunk or right.isJunk then
						return ZO_TableOrderingFunction(left, right, "isJunk", DEFAULT_SORT_KEYS, savedVars.withdraw)
					end
					return ZO_TableOrderingFunction(left, right, "bestGamepadItemCategoryName", DEFAULT_SORT_KEYS, ZO_SORT_ORDER_UP)
				else
					return false
				end
			end)
			GAMEPAD_BANKING.depositList:SetSortFunction(sortJunkToBottom)
		end
	end)
	
end

---------------------------------------------------------------------------------------------------------------
-- Add Mark/Unmark as Junk to Inventory Item Action list
---------------------------------------------------------------------------------------------------------------
local menu = LibCustomMenu
local function canSceneHandleJunk()
	local sceneName = SCENE_MANAGER:GetCurrentScene():GetName()
	if sceneName == 'gamepad_banking' then
		return true
	end
	return SCENE_MANAGER:IsShowing("gamepad_inventory_root") or SCENE_MANAGER:IsSceneOnStack("gamepad_inventory_root")
end

local function MarkAsJunkHelper(bagId, slotIndex, isJunk)
	local lastItem = GAMEPAD_INVENTORY:GetCurrentList():GetNumEntries() == 1 and true or false
	SetItemIsJunk(bagId, slotIndex, isJunk)
	PlaySound(isJunk and SOUNDS.INVENTORY_ITEM_JUNKED or SOUNDS.INVENTORY_ITEM_UNJUNKED)
	
	if SCENE_MANAGER:IsShowing("gamepad_inventory_root") or SCENE_MANAGER:IsSceneOnStack("gamepad_inventory_root") then
		if lastItem then
			GAMEPAD_INVENTORY:SwitchActiveList(INVENTORY_CATEGORY_LIST)
		end
	end
	CALLBACK_MANAGER:FireCallbacks("InventorySlotUpdate", {bagId, slotIndex})
end

local function AddItem(inventorySlot, slotActions)
	local valid = ZO_Inventory_GetBagAndIndex(inventorySlot)
	if not valid or inventorySlot.stolen then return end
	if canSceneHandleJunk() then
--	for k,v in pairs(inventorySlot.dataSource) do d(k) end
		local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
		if not IsItemPlayerLocked(bag, index) and CanItemBeMarkedAsJunk(bag, index) and not IsItemJunk(bag, index) and not QUICKSLOT_WINDOW:AreQuickSlotsShowing() and IsInGamepadPreferredMode() then
			slotActions:AddCustomSlotAction(SI_ITEM_ACTION_MARK_AS_JUNK, function() MarkAsJunkHelper(bag, index, true) end, "")
		end
		if not IsItemPlayerLocked(bag, index) and CanItemBeMarkedAsJunk(bag, index) and IsItemJunk(bag, index) and not QUICKSLOT_WINDOW:AreQuickSlotsShowing() and IsInGamepadPreferredMode() then
			slotActions:AddCustomSlotAction(SI_ITEM_ACTION_UNMARK_AS_JUNK, function() MarkAsJunkHelper(bag, index, false) end, "")
		end
	end
end

function IJA_GPInventory:AddInventoryActions()
	menu:RegisterKeyStripEnter(AddItem, menu.CATEGORY_PRIMARY)
end
-------------------------------------
function IJA_GPInventory_Initialize( ... )
    IJA_GPINVENTORY = IJA_GPInventory:New( ... )
end


--[[
removed bop

--]]