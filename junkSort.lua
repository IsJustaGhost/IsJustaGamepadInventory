local IJA_GPInventory = IJA_GPINVENTORY
local savedVars

---------------------------------------------------------------------------------------------------------------
-- Sort Functions
---------------------------------------------------------------------------------------------------------------
local DEFAULT_SORT_KEYS ={
	bestGamepadItemCategoryName = { tiebreaker = "name" },
	name = { tiebreaker = "requiredLevel" },
	requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
	requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
	iconFile = { tiebreaker = "uniqueId" },
	uniqueId = { isId64 = true },
	customSortOrder = { tiebreaker = "bestGamepadItemCategoryName", isNumeric = true },
	isJunk = { tiebreaker = "bestGamepadItemCategoryName" },
	equipType = { tiebreaker = "bestGamepadItemCategoryName" , isNumeric = true },
	specializedItemType = { tiebreaker = "bestGamepadItemCategoryName" },
}
	
local function sortJunkToTOP(data1, data2)
	if data1.isJunk or data2.isJunk then
		return ZO_TableOrderingFunction(data1, data2, "isJunk", DEFAULT_SORT_KEYS, ZO_SORT_ORDER_DOWN)
	end
	return ZO_TableOrderingFunction(data1, data2, "bestGamepadItemCategoryName", DEFAULT_SORT_KEYS, ZO_SORT_ORDER_UP)
end
local function sortJunkToBottom(data1, data2)
	if data1.isJunk or data2.isJunk then
		return ZO_TableOrderingFunction(data1, data2, "isJunk", DEFAULT_SORT_KEYS, savedVars.deposit)
	end
	return ZO_TableOrderingFunction(data1, data2, "bestGamepadItemCategoryName", DEFAULT_SORT_KEYS, ZO_SORT_ORDER_UP)
end

local SELL_SORT_KEYS ={
	bestGamepadItemCategoryName = { tiebreaker = "name" },
	name = { tiebreaker = "requiredLevel" },
	requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
	requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
	iconFile = { tiebreaker = "uniqueId" },
	uniqueId = { isId64 = true },
	customSortOrder = { tiebreaker = "bestGamepadItemCategoryName", isNumeric = true },
	isJunk = { tiebreaker = "customSortOrder", tieBreakerSortOrder = ZO_SORT_ORDER_UP }
}
local function SellSortFunc(data1, data2)
	if data1.isJunk or data2.isJunk then
		return ZO_TableOrderingFunction(data1, data2, "isJunk", SELL_SORT_KEYS, ZO_SORT_ORDER_DOWN)
	end
	return ZO_TableOrderingFunction(data1, data2, "customSortOrder", SELL_SORT_KEYS, ZO_SORT_ORDER_UP)
end

---------------------------------------------------------------------------------------------------------------
-- Merch/Bank junk sort
---------------------------------------------------------------------------------------------------------------
function IJA_GPInventory:InitJunkSort()
	savedVars = self.sv
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
	
	local function bankWithdrawSort(left, right)
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
			if left.isJunk or right.isJunk then
				return ZO_TableOrderingFunction(left, right, "isJunk", DEFAULT_SORT_KEYS, savedVars.withdraw)
			end
			return ZO_TableOrderingFunction(left, right, "bestGamepadItemCategoryName", DEFAULT_SORT_KEYS, ZO_SORT_ORDER_UP)
		else
			return false
		end
	end

	local function stateChange(oldState, newState)
		if newState == SCENE_SHOWING then
			gamepadBankSCene:UnregisterCallback("StateChange", stateChange)
			
			GAMEPAD_BANKING.withdrawList.list:SetSortFunction(bankWithdrawSort)
			GAMEPAD_BANKING.depositList:SetSortFunction(sortJunkToBottom)
		end
	end
	gamepadBankSCene:RegisterCallback("StateChange", stateChange)
end
