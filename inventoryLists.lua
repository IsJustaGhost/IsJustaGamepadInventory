local IJA_GPInventory = IJA_GPINVENTORY

---------------------------------------------------------------------------------------------------------------
-- Custom Categories
---------------------------------------------------------------------------------------------------------------
local customCategoies = {
	[ITEMFILTERTYPE_MAPS] = {
		['icon'] = "esoui/art/crafting/gamepad/gp_crafting_menuicon_designs.dds"
	},
	[ITEMFILTERTYPE_JUNK] = {
		['icon'] = "esoui/art/inventory/inventory_tabicon_junk_up.dds"
	},
	[ITEMFILTERTYPE_STOLEN] = {
		['icon'] = "esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds"
	}
}

local isCutomCategory = {}
for filterType, icon in pairs(customCategoies) do
	isCutomCategory[filterType] = true
end

---------------------------------------------------------------------------------------------------------------
-- Comparetors
---------------------------------------------------------------------------------------------------------------
local specialized_itemtype_treasure_map_survey_report = {
	[SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP] = true,
	[SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT] = true,
}
local function isMapItem(itemData)
	return specialized_itemtype_treasure_map_survey_report[itemData.specializedItemType] or false
end

local function IsStolenItem(itemData)
	return itemData.stolen
end
local function IsJunkItem(itemData)
	return itemData.isJunk
end

---------------------------------------------------------------------------------------------------------------
-- Helper functions
---------------------------------------------------------------------------------------------------------------
local function categoryNotEmpty(filterType)
	local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_BACKPACK)
	for slotId, itemData in pairs(bagCache) do
		if filterType == ITEMFILTERTYPE_STOLEN then
			if itemData.stolen then
				return true
			end
		elseif filterType == ITEMFILTERTYPE_JUNK then
			if itemData.isJunk then
				return true
			end
		elseif filterType == ITEMFILTERTYPE_MAPS then
			if isMapItem(itemData) then
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

local function filterDisabled(itemData, filterType)
	if itemData.isJunk then
		return not IJA_GPINVENTORY.sv.filterJunk and filterType ~= ITEMFILTERTYPE_JUNK
	end
	if itemData.stolen then
		return not IJA_GPINVENTORY.sv.filterStolen and filterType ~= ITEMFILTERTYPE_STOLEN
	end
	if isMapItem(itemData) then
		return not IJA_GPINVENTORY.sv.filterMaps and filterType ~= ITEMFILTERTYPE_MAPS
	end
end

local function areAnyItemsNew(filterType)
	local bagCache = SHARED_INVENTORY:GenerateFullSlotData(filterType, BAG_BACKPACK)
	for slotId, slotData in pairs(bagCache) do
		if slotData.brandNew then
			return true
		end
	end
end

local shouldAddItem = {
	[ITEMFILTERTYPE_ALL] = function(itemData, filterType)
		if itemData.stolen or itemData.isJunk or isMapItem(itemData) then
			return filterDisabled(itemData, filterType)
		else
			for i, filter in ipairs(itemData.filterData) do
				if filter == filterType then
					return true
				end
			end
		end
	end,
	[ITEMFILTERTYPE_MAPS] = function(itemData, filterType)
		if isMapItem(itemData) and IJA_GPINVENTORY.sv.mapsCategory then
			if itemData.isJunk or itemData.stolen then
				return filterDisabled(itemData, filterType)
			end
			return true
		end
	end,
	[ITEMFILTERTYPE_JUNK] = function(itemData, filterType)
		if itemData.isJunk and IJA_GPINVENTORY.sv.junkCategory then
			if itemData.stolen then
				return filterDisabled(itemData, filterType)
			end
			return true
		end
	end,
	[ITEMFILTERTYPE_STOLEN] = function(itemData, filterType)
		if IJA_GPINVENTORY.sv.stolenCategory then
			return itemData.stolen
		end
	end
}

---------------------------------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------------------------------

--[[
function ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(itemData)
	local category = nil
	if itemData.isJunk then 
		return GetString(SI_ITEMFILTERTYPE9)
	end
	if itemData.itemType == ITEMTYPE_WEAPON then
		category = GetCategoryFromWeapon(itemData)
	elseif itemData.itemType == ITEMTYPE_ARMOR then
		category = GetCategoryFromArmor(itemData)
	else
		category = GetCategoryFromItemType(itemData.itemType)
	end
	if category then
		return GetString("SI_GAMEPADITEMCATEGORY", category)
	end
	return zo_strformat(SI_INVENTORY_HEADER, GetString("SI_ITEMTYPE", itemData.itemType))
end
]]


---------------------------------------------------------------------------------------------------------------
-- Main Filters
---------------------------------------------------------------------------------------------------------------
local function IJA_GPInventory_DoesNewItemMatchFilterType(itemData, currentFilter)
    if not currentFilter then return true end
	
	if currentFilter == ITEMFILTERTYPE_JUNK then
		return shouldAddItem[ITEMFILTERTYPE_JUNK](itemData, currentFilter)
	elseif currentFilter == ITEMFILTERTYPE_STOLEN then
		return shouldAddItem[ITEMFILTERTYPE_STOLEN](itemData, currentFilter)
	elseif currentFilter == ITEMFILTERTYPE_MAPS then
		return shouldAddItem[ITEMFILTERTYPE_MAPS](itemData, currentFilter)
	end
    return false
end

--[[



function ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, currentFilter)
    if not currentFilter then return true end
	
	if currentFilter == ITEMFILTERTYPE_JUNK and IJA_GPINVENTORY.sv.junkCategory then
		return shouldAddItem[ITEMFILTERTYPE_JUNK](itemData)
	elseif currentFilter == ITEMFILTERTYPE_STOLEN and IJA_GPINVENTORY.sv.stolenCategory then
		return shouldAddItem[ITEMFILTERTYPE_STOLEN](itemData)
	elseif currentFilter == ITEMFILTERTYPE_MAPS and IJA_GPINVENTORY.sv.mapsCategory then
		return shouldAddItem[ITEMFILTERTYPE_MAPS](itemData)
	else
		if GAMEPAD_INVENTORY.currentListType == INVENTORY_ITEM_LIST or GAMEPAD_INVENTORY.itemList:IsActive() then
			if itemData.isJunk or itemData.stolen or isMapItem(itemData) then
				return filterDisabled(itemData)
			else
				for i, filter in ipairs(itemData.filterData) do
					if filter == currentFilter then
						return true
					end
				end
			end
		else
			for i, filter in ipairs(itemData.filterData) do
				if filter == currentFilter then
					return true
				end
			end
		end
	end
    return false
end



function ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, currentFilter)
    if not currentFilter then return true end
    for i, filter in ipairs(itemData.filterData) do
        if filter == currentFilter then
            return true
        end
    end
    return false
end

local function GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
	return function(itemData)
		if filteredEquipSlot then
			return ZO_Character_DoesEquipSlotUseEquipType(filteredEquipSlot, itemData.equipType)
		end

		if nonEquipableFilterType then
			local filterType = GetItemFilterTypeInfo(itemData.bagId, itemData.slotIndex)
			local currentFilter = isCutomCategory[nonEquipableFilterType] and filterType or nonEquipableFilterType

			return ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, currentFilter)
		end
		
		return ZO_InventoryUtils_DoesNewItemMatchSupplies(itemData)
	end
end

]]
local original_GetItemDataFilterComparator = GAMEPAD_INVENTORY.GetItemDataFilterComparator
function GAMEPAD_INVENTORY:GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
	local function doesItemPassFilter(itemData, currentFilter)
		-- get original or libFilters filter
		local comparator = original_GetItemDataFilterComparator(GAMEPAD_INVENTORY, filteredEquipSlot, currentFilter)
		local result = comparator(itemData)
		
		if result then
			if isCutomCategory[nonEquipableFilterType] then
				result = IJA_GPInventory_DoesNewItemMatchFilterType(itemData, nonEquipableFilterType)
			elseif itemData.isJunk or itemData.stolen or isMapItem(itemData) then
				result = shouldAddItem[ITEMFILTERTYPE_ALL](itemData, currentFilter)
			end
		end
		return result
	end

	return function(itemData)
		local filterType = GetItemFilterTypeInfo(itemData.bagId, itemData.slotIndex)
		local currentFilter = isCutomCategory[nonEquipableFilterType] and filterType or nonEquipableFilterType
		
		return doesItemPassFilter(itemData, currentFilter)
	end
end

---------------------------------------------------------------------------------------------------------------
-- Header functions
---------------------------------------------------------------------------------------------------------------
local function UpdateGold(control)
	ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
	return true
end

local function UpdateCapacityString()
	return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
end

local function UpdateSellValueString(control)
	local filterType = GAMEPAD_INVENTORY.categoryList:GetTargetData().filterType
	local comparetor = function(itemData)
		return (filterType == ITEMFILTERTYPE_JUNK and itemData.isJunk) or
			(filterType == ITEMFILTERTYPE_STOLEN and itemData.stolen)
	end
	
	local bagCache = SHARED_INVENTORY:GenerateFullSlotData(comparetor, BAG_BACKPACK)
	
	local total = 0
	for slotId, itemData in pairs(bagCache) do
		total = total + itemData.stackSellPrice
	end
	return zo_strformat(SI_TOOLTIP_ITEM_VALUE_FORMAT, total, GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS))
end

local function dynamicMapHeaders_Clear()
	if GAMEPAD_INVENTORY.mapsHeaderData.data3HeaderText then GAMEPAD_INVENTORY.mapsHeaderData.data3HeaderText = nil end
	if GAMEPAD_INVENTORY.mapsHeaderData.data3Text then GAMEPAD_INVENTORY.mapsHeaderData.data3Text = nil end
	if GAMEPAD_INVENTORY.mapsHeaderData.data4HeaderText then GAMEPAD_INVENTORY.mapsHeaderData.data4HeaderText = nil end
	if GAMEPAD_INVENTORY.mapsHeaderData.data4Text then GAMEPAD_INVENTORY.mapsHeaderData.data4Text = nil end
end
local function dynamicMapHeaders_Set(surveyCache, mapCache)
	local function getSurveyCount(surveyCache)
		local count = 0
		for k, itemData in pairs(surveyCache) do
			count = count + itemData.stackCount
		end
		return count
	end
	
	local plural = GetString(SI_IJA_GPINVENTORY_PLURAL)
	local mapString		= zo_strformat(plural, GetString(SI_SPECIALIZEDITEMTYPE100))
	local surveyString	= zo_strformat(plural, GetString(SI_SPECIALIZEDITEMTYPE101))

	if #surveyCache > 0 then
		GAMEPAD_INVENTORY.mapsHeaderData.data3HeaderText = zo_strformat(SI_INVENTORY_HEADER, surveyString)
		GAMEPAD_INVENTORY.mapsHeaderData.data3Text = zo_strformat(SI_TOOLTIP_ITEM_VALUE_FORMAT, getSurveyCount(surveyCache), "")
	elseif #mapCache > 0 then
		GAMEPAD_INVENTORY.mapsHeaderData.data3HeaderText = zo_strformat(SI_INVENTORY_HEADER, mapString)
		GAMEPAD_INVENTORY.mapsHeaderData.data3Text = zo_strformat(SI_TOOLTIP_ITEM_VALUE_FORMAT, #mapCache, "")
		return
	end
	if #mapCache > 0 then
		GAMEPAD_INVENTORY.mapsHeaderData.data4HeaderText = zo_strformat(SI_INVENTORY_HEADER, mapString)
		GAMEPAD_INVENTORY.mapsHeaderData.data4Text = zo_strformat(SI_TOOLTIP_ITEM_VALUE_FORMAT, #mapCache, "")
	end
end
local function dynamicMapHeaders_Update()
	local isMap		= function(itemData) return itemData.specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP end
	local isSurvey	= function(itemData) return itemData.specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT end
	
	local surveyCache	= SHARED_INVENTORY:GenerateFullSlotData(isSurvey, BAG_BACKPACK)
	local mapCache		= SHARED_INVENTORY:GenerateFullSlotData(isMap, BAG_BACKPACK)

	dynamicMapHeaders_Clear()
	dynamicMapHeaders_Set(surveyCache, mapCache)
end

ZO_PreHook(GAMEPAD_INVENTORY, "InitializeHeader", function(self)
	self.customHeaderData = {
		data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
		data1Text = UpdateGold,

		data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
		data2Text = UpdateCapacityString,
		
		data3HeaderText = GetString(SI_INVENTORY_SORT_TYPE_PRICE),
		data3Text = UpdateSellValueString,
	}
			
	self.mapsHeaderData = {
		data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
		data1Text = UpdateGold,

		data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
		data2Text = UpdateCapacityString,
	}
	
	
	return false
end)

ZO_PreHook(GAMEPAD_INVENTORY, "RefreshHeader", function(self, blockCallback)
	if self.currentListType == "categoryList" then return false end

	local filterType = GAMEPAD_INVENTORY.categoryList:GetTargetData().filterType
	local headerData
	
	if filterType == ITEMFILTERTYPE_JUNK and self:GetCurrentList():IsActive() then
		self.customHeaderData.titleText = GetString(SI_ITEMFILTERTYPE9)
		headerData = self.customHeaderData
	elseif filterType == ITEMFILTERTYPE_STOLEN then
		self.customHeaderData.titleText = GetString(SI_GAMEPAD_ITEM_STOLEN_LABEL)
		headerData = self.customHeaderData
	elseif filterType == ITEMFILTERTYPE_MAPS then
		self.mapsHeaderData.titleText = GetString(SI_IJA_GPINVENTORY_SURVEYS_MAPS)
		dynamicMapHeaders_Update()
		headerData = self.mapsHeaderData
	else
		-- if not custom category then run default RefreshHeader
		return false
	end
	
	ZO_GamepadGenericHeader_Refresh(self.header, headerData, blockCallback)
	return true
end)

---------------------------------------------------------------------------------------------------------------
-- Category list
---------------------------------------------------------------------------------------------------------------
local function GetCategoryTypeFromWeaponType(bagId, slotIndex)
	local weaponType = GetItemWeaponType(bagId, slotIndex)
	if weaponType == WEAPONTYPE_AXE or weaponType == WEAPONTYPE_HAMMER or weaponType == WEAPONTYPE_SWORD or weaponType == WEAPONTYPE_DAGGER then
		return GAMEPAD_WEAPON_CATEGORY_ONE_HANDED_MELEE
	elseif weaponType == WEAPONTYPE_TWO_HANDED_SWORD or weaponType == WEAPONTYPE_TWO_HANDED_AXE or weaponType == WEAPONTYPE_TWO_HANDED_HAMMER then
		return GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_MELEE
	elseif weaponType == WEAPONTYPE_FIRE_STAFF or weaponType == WEAPONTYPE_FROST_STAFF or weaponType == WEAPONTYPE_LIGHTNING_STAFF then
		return GAMEPAD_WEAPON_CATEGORY_DESTRUCTION_STAFF
	elseif weaponType == WEAPONTYPE_HEALING_STAFF then
		return GAMEPAD_WEAPON_CATEGORY_RESTORATION_STAFF
	elseif weaponType == WEAPONTYPE_BOW then
		return GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_BOW
	elseif weaponType ~= WEAPONTYPE_NONE then
		return GAMEPAD_WEAPON_CATEGORY_UNCATEGORIZED
	end
end

local function IsTwoHandedWeaponCategory(categoryType)
	return categoryType == GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_MELEE or
		categoryType == GAMEPAD_WEAPON_CATEGORY_DESTRUCTION_STAFF or
		categoryType == GAMEPAD_WEAPON_CATEGORY_RESTORATION_STAFF or
		categoryType == GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_BOW
end

--=============================================================================================================
ZO_PostHook(GAMEPAD_INVENTORY, "RefreshCategoryList", function(self)
	self.categoryList:Clear()
	
	do -- Currencies
		local name = GetString(SI_INVENTORY_CURRENCIES)
		local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_currencies.dds"
		local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, false)
		data.isCurrencyEntry = true
		data:SetIconTintOnSelection(true)
		self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
	end

	do -- Supplies
		local isListEmpty = self:IsItemListEmpty()
		if not isListEmpty then
			local name = GetString(SI_INVENTORY_SUPPLIES)
			local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_all.dds"
			local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchSupplies, nil, BAG_BACKPACK)
			local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
			data:SetIconTintOnSelection(true)
			self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
		end
	end

	-- Materials
	self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_CRAFTING, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_materials.dds")
	-- Consumables
	self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_QUICKSLOT, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_quickslot.dds")
	-- Furnishing
	self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_FURNISHING, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_furnishings.dds")
	-- Companion Items
	self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_COMPANION, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_companionItems.dds")

	do -- Quest Items
		local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
		local textSearchFilterdQuestCache = {}
		for _, questItems in pairs(questCache) do
			for _, questItem in pairs(questItems) do
				if self:GetQuestItemDataFilterComparator(questItem.questItemId) then
					table.insert(textSearchFilterdQuestCache, questCache)
				end
			end
		end

		if next(textSearchFilterdQuestCache) then
			local name = GetString(SI_GAMEPAD_INVENTORY_QUEST_ITEMS)
			local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_quest.dds"
			local data = ZO_GamepadEntryData:New(name, iconFile)
			data.filterType = ITEMFILTERTYPE_QUEST
			data:SetIconTintOnSelection(true)
			self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
		end
	end

	do	-- custom categories
		-- Treasure maps and Survey reports
		self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_MAPS, "EsoUI/Art/crafting/Gamepad/gp_crafting_menuicon_designs.dds")
		-- Junk
		self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_JUNK, "esoui/art/inventory/inventory_tabicon_junk_up.dds")
		-- Stolen
		self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_STOLEN, "esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds")
	end
--[[
	do -- Treasure Maps and Survey Reports
		if categoryNotEmpty(ITEMFILTERTYPE_MAPS) and IJA_GPINVENTORY.sv.mapsCategory then
			local name = GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_MAPS)
			local iconFile = "esoui/art/crafting/gamepad/gp_crafting_menuicon_designs.dds"
			local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, areAnyItemsNew(isMapItem))
			data.filterType = ITEMFILTERTYPE_MAPS
			data:SetIconTintOnSelection(true)
			self.categoryList:AddEntry("ZO_GamepadItemEntryTemplateWithHeader", data)
			data:SetHeader("Custom")
		end
	end

	do -- Junked Items
		if categoryNotEmpty(ITEMFILTERTYPE_JUNK) and IJA_GPINVENTORY.sv.junkCategory then
			local name = GetString(SI_ITEMFILTERTYPE9)
			local iconFile = "esoui/art/inventory/inventory_tabicon_junk_up.dds"
			local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, areAnyItemsNew(IsJunkItem))
			data.filterType = ITEMFILTERTYPE_JUNK
			data:SetIconTintOnSelection(true)
			self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
		end
	end

	do -- Stolen Items
		if(AreAnyItemsStolen(BAG_BACKPACK)) and IJA_GPINVENTORY.sv.stolenCategory then
			local name = GetString(SI_GAMEPAD_ITEM_STOLEN_LABEL)
			local iconFile = "esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds"
			local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, areAnyItemsNew(IsStolenItem))
			data.filterType = ITEMFILTERTYPE_STOLEN
			data:SetIconTintOnSelection(true)
			self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
		end
	end
]]
	local twoHandIconFile
	local headersUsed = {}
	for i, equipSlot in ZO_Character_EnumerateOrderedEquipSlots() do -- equipable items
		local locked = IsLockedWeaponSlot(equipSlot)
		local isListEmpty = self:IsItemListEmpty(equipSlot, nil)
		if not locked and not isListEmpty then
			local name = zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_EQUIPSLOT", equipSlot))
			local iconFile, slotHasItem = GetEquippedItemInfo(equipSlot)
			if not slotHasItem then
				iconFile = nil
			end

			--special case where a two handed weapon icon shows up in offhand slot at lower opacity
			local weaponCategoryType = GetCategoryTypeFromWeaponType(BAG_WORN, equipSlot)
			if iconFile
				and (equipSlot == EQUIP_SLOT_MAIN_HAND or equipSlot == EQUIP_SLOT_BACKUP_MAIN)
				and IsTwoHandedWeaponCategory(weaponCategoryType) then
				twoHandIconFile = iconFile
			end

			local offhandTransparency
			if twoHandIconFile and (equipSlot == EQUIP_SLOT_OFF_HAND or equipSlot == EQUIP_SLOT_BACKUP_OFF) then
				iconFile = twoHandIconFile
				twoHandIconFile = nil
				offhandTransparency = 0.5
			end

			local function DoesNewItemMatchEquipSlot(itemData)
				return ZO_Character_DoesEquipSlotUseEquipType(equipSlot, itemData.equipType)
			end

			local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(DoesNewItemMatchEquipSlot, nil, BAG_BACKPACK)
			
			local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
			data:SetMaxIconAlpha(offhandTransparency)
			data.equipSlot = equipSlot
			data.filterType = (GetItemFilterTypeInfo(BAG_WORN, equipSlot)) -- first filter only

			if (equipSlot == EQUIP_SLOT_POISON or equipSlot == EQUIP_SLOT_BACKUP_POISON) then
				data.stackCount = select(2, GetItemInfo(BAG_WORN, equipSlot))
			end

			--Headers for Equipment Visual Categories (Weapons, Apparel, Accessories): display header for the first equip slot of a category to be visible 
			local visualCategory = ZO_Character_GetEquipSlotVisualCategory(equipSlot)
			if headersUsed[visualCategory] == nil then
				self.categoryList:AddEntry("ZO_GamepadItemEntryTemplateWithHeader", data)
				data:SetHeader(GetString("SI_EQUIPSLOTVISUALCATEGORY", visualCategory))

				headersUsed[visualCategory] = true
			--No Header Needed
			else
				self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
			end
		end
	end

	self.categoryList:Commit()
	return true
end)

--[[
	
	do -- Treasure Maps and Survey Reports
		if categoryNotEmpty("map") and IJA_GPINVENTORY.sv.mapsCategory then
			local name = "Maps"
			local iconFile = "/esoui/art/crafting/gamepad/gp_crafting_menuicon_designs.dds"
			local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, areAnyItemsNew(IsMap))
			data.showMaps = true
			data:SetIconTintOnSelection(true)
			self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
		end
	end

	do -- Junked Items
		if categoryNotEmpty(ITEMFILTERTYPE_JUNK) and IJA_GPINVENTORY.sv.junkCategory then
			local name = GetString(SI_ITEMFILTERTYPE9)
			local iconFile = "esoui/art/inventory/inventory_tabicon_junk_up.dds"
			local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, areAnyItemsNew(IsJunkItem))
			data.showJunk = true
			data:SetIconTintOnSelection(true)
			self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
		end
	end

	do -- Stolen Items
		if(AreAnyItemsStolen(BAG_BACKPACK)) and IJA_GPINVENTORY.sv.stolenCategory then
			local name = GetString(SI_GAMEPAD_ITEM_STOLEN_LABEL)
			local iconFile = "esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds"
			local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, areAnyItemsNew(IsStolenItem))
			data.showStolen = true
			data:SetIconTintOnSelection(true)
			self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
		end
	end

	do	-- custom categories
		-- Treasure maps and Survey reports
		self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_MAPS, "EsoUI/Art/crafting/Gamepad/gp_crafting_menuicon_designs.dds")
		-- Junk
		self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_JUNK, "esoui/art/inventory/inventory_tabicon_junk_up.dds")
		-- Stolen
		self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_STOLEN, "esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds")
	end
		
		
function ZO_GamepadInventory:AddFilteredBackpackCategoryIfPopulated(filterType, iconFile)
    local isListEmpty = self:IsItemListEmpty(nil, filterType)
    if not isListEmpty then
        local name = GetString("SI_ITEMFILTERTYPE", filterType)
        local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, filterType, BAG_BACKPACK)
        local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
        data.filterType = filterType
        data:SetIconTintOnSelection(true)
        self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
    end
end

	do	-- custom categories
		-- Treasure Maps and Survey Reports
		if categoryNotEmpty(ITEMFILTERTYPE_MAPS) then
			self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_MAPS, "/esoui/art/crafting/gamepad/gp_crafting_menuicon_designs.dds")
		end
		-- Junked Items
		if categoryNotEmpty(ITEMFILTERTYPE_JUNK) then
			self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_JUNK, "/esoui/art/inventory/inventory_tabicon_junk_up.dds")
		end
		-- Stolen Items
		if categoryNotEmpty(ITEMFILTERTYPE_STOLEN) then
			self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_STOLEN, "/esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds")
		end
	end

	nonEquipableFilterType == ITEMFILTERTYPE_JUNK
	nonEquipableFilterType == ITEMFILTERTYPE_STOLEN
	nonEquipableFilterType == ITEMFILTERTYPE_MAPS
]]
---------------------------------------------------------------------------------------------------------------
-- Item list
---------------------------------------------------------------------------------------------------------------
local ITEM_TYPE_TO_CATEGORY_MAP = {
	[ITEMTYPE_REAGENT] = GAMEPAD_ITEM_CATEGORY_ALCHEMY,
	[ITEMTYPE_POTION_BASE] = GAMEPAD_ITEM_CATEGORY_ALCHEMY,
	[ITEMTYPE_POISON_BASE] = GAMEPAD_ITEM_CATEGORY_ALCHEMY,
	[ITEMTYPE_LURE] = GAMEPAD_ITEM_CATEGORY_BAIT,
	[ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = GAMEPAD_ITEM_CATEGORY_BLACKSMITH,
	[ITEMTYPE_BLACKSMITHING_MATERIAL] = GAMEPAD_ITEM_CATEGORY_BLACKSMITH,
	[ITEMTYPE_BLACKSMITHING_BOOSTER] = GAMEPAD_ITEM_CATEGORY_BLACKSMITH,
	[ITEMTYPE_CLOTHIER_RAW_MATERIAL] = GAMEPAD_ITEM_CATEGORY_CLOTHIER,
	[ITEMTYPE_CLOTHIER_MATERIAL] = GAMEPAD_ITEM_CATEGORY_CLOTHIER,
	[ITEMTYPE_CLOTHIER_BOOSTER] = GAMEPAD_ITEM_CATEGORY_CLOTHIER,
	[ITEMTYPE_FOOD] = GAMEPAD_ITEM_CATEGORY_CONSUMABLE,
	[ITEMTYPE_DRINK] = GAMEPAD_ITEM_CATEGORY_CONSUMABLE,
	[ITEMTYPE_RECIPE] = GAMEPAD_ITEM_CATEGORY_CONSUMABLE,
	[ITEMTYPE_COSTUME] = GAMEPAD_ITEM_CATEGORY_COSTUME,
	[ITEMTYPE_ENCHANTING_RUNE_POTENCY] = GAMEPAD_ITEM_CATEGORY_ENCHANTING,
	[ITEMTYPE_ENCHANTING_RUNE_ASPECT] = GAMEPAD_ITEM_CATEGORY_ENCHANTING,
	[ITEMTYPE_ENCHANTING_RUNE_ESSENCE] = GAMEPAD_ITEM_CATEGORY_ENCHANTING,
	[ITEMTYPE_GLYPH_WEAPON] = GAMEPAD_ITEM_CATEGORY_GLYPHS,
	[ITEMTYPE_GLYPH_ARMOR] = GAMEPAD_ITEM_CATEGORY_GLYPHS,
	[ITEMTYPE_GLYPH_JEWELRY] = GAMEPAD_ITEM_CATEGORY_GLYPHS,
	[ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL] = GAMEPAD_ITEM_CATEGORY_JEWELRYCRAFTING,
	[ITEMTYPE_JEWELRYCRAFTING_MATERIAL] = GAMEPAD_ITEM_CATEGORY_JEWELRYCRAFTING,
	[ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER] = GAMEPAD_ITEM_CATEGORY_JEWELRYCRAFTING,
	[ITEMTYPE_JEWELRYCRAFTING_BOOSTER] = GAMEPAD_ITEM_CATEGORY_JEWELRYCRAFTING,
	[ITEMTYPE_POTION] = GAMEPAD_ITEM_CATEGORY_POTION,
	[ITEMTYPE_INGREDIENT] = GAMEPAD_ITEM_CATEGORY_PROVISIONING,
	[ITEMTYPE_ADDITIVE] = GAMEPAD_ITEM_CATEGORY_PROVISIONING,
	[ITEMTYPE_SPICE] = GAMEPAD_ITEM_CATEGORY_PROVISIONING,
	[ITEMTYPE_FLAVORING] = GAMEPAD_ITEM_CATEGORY_PROVISIONING,
	[ITEMTYPE_SIEGE] = GAMEPAD_ITEM_CATEGORY_SIEGE,
	[ITEMTYPE_AVA_REPAIR] = GAMEPAD_ITEM_CATEGORY_SIEGE,
	[ITEMTYPE_RACIAL_STYLE_MOTIF] = GAMEPAD_ITEM_CATEGORY_STYLE_MATERIAL,
	[ITEMTYPE_STYLE_MATERIAL] = GAMEPAD_ITEM_CATEGORY_STYLE_MATERIAL,
	[ITEMTYPE_SOUL_GEM] = GAMEPAD_ITEM_CATEGORY_SOUL_GEM,
	[ITEMTYPE_LOCKPICK] = GAMEPAD_ITEM_CATEGORY_TOOL,
	[ITEMTYPE_TOOL] = GAMEPAD_ITEM_CATEGORY_TOOL,
	[ITEMTYPE_ARMOR_TRAIT] = GAMEPAD_ITEM_CATEGORY_TRAIT_ITEM,
	[ITEMTYPE_WEAPON_TRAIT] = GAMEPAD_ITEM_CATEGORY_TRAIT_ITEM,
	[ITEMTYPE_JEWELRY_RAW_TRAIT] = GAMEPAD_ITEM_CATEGORY_TRAIT_ITEM,
	[ITEMTYPE_JEWELRY_TRAIT] = GAMEPAD_ITEM_CATEGORY_TRAIT_ITEM,
	[ITEMTYPE_TROPHY] = GAMEPAD_ITEM_CATEGORY_TROPHY,
	[ITEMTYPE_WOODWORKING_RAW_MATERIAL] = GAMEPAD_ITEM_CATEGORY_WOODWORKING,
	[ITEMTYPE_WOODWORKING_MATERIAL] = GAMEPAD_ITEM_CATEGORY_WOODWORKING,
	[ITEMTYPE_WOODWORKING_BOOSTER] = GAMEPAD_ITEM_CATEGORY_WOODWORKING,
}
local function GetCategoryFromItemType(itemType)
	-- This is not an exhaustive map: when we don't have a category we'll just use the raw itemtype instead.
	return ITEM_TYPE_TO_CATEGORY_MAP[itemType]
end

local WEAPON_TYPE_TO_CATEGORY_MAP = {
	[WEAPONTYPE_AXE] = GAMEPAD_ITEM_CATEGORY_AXE,
	[WEAPONTYPE_TWO_HANDED_AXE] = GAMEPAD_ITEM_CATEGORY_AXE,
	[WEAPONTYPE_BOW] = GAMEPAD_ITEM_CATEGORY_BOW,
	[WEAPONTYPE_DAGGER] = GAMEPAD_ITEM_CATEGORY_DAGGER,
	[WEAPONTYPE_HAMMER] = GAMEPAD_ITEM_CATEGORY_HAMMER,
	[WEAPONTYPE_TWO_HANDED_HAMMER] = GAMEPAD_ITEM_CATEGORY_HAMMER,
	[WEAPONTYPE_SHIELD] = GAMEPAD_ITEM_CATEGORY_SHIELD,
	[WEAPONTYPE_HEALING_STAFF] = GAMEPAD_ITEM_CATEGORY_STAFF,
	[WEAPONTYPE_FIRE_STAFF] = GAMEPAD_ITEM_CATEGORY_STAFF,
	[WEAPONTYPE_FROST_STAFF] = GAMEPAD_ITEM_CATEGORY_STAFF,
	[WEAPONTYPE_LIGHTNING_STAFF] = GAMEPAD_ITEM_CATEGORY_STAFF,
	[WEAPONTYPE_SWORD] = GAMEPAD_ITEM_CATEGORY_SWORD,
	[WEAPONTYPE_TWO_HANDED_SWORD] = GAMEPAD_ITEM_CATEGORY_SWORD,
}
local function GetCategoryFromWeapon(itemData)
	local weaponType
	if itemData.isJunk then 
		return zo_strformat(SI_INVENTORY_HEADER, GetString(SI_ITEMFILTERTYPE9))
	end
	if itemData.bagId and itemData.slotIndex then
		weaponType = GetItemWeaponType(itemData.bagId, itemData.slotIndex)
	else
		weaponType = GetItemLinkWeaponType(itemData.itemLink)
	end
	local category = WEAPON_TYPE_TO_CATEGORY_MAP[weaponType]
	internalassert(category)
	return category
end

local ARMOR_EQUIP_TYPE_TO_CATEGORY_MAP = {
	[EQUIP_TYPE_CHEST] = GAMEPAD_ITEM_CATEGORY_CHEST,
	[EQUIP_TYPE_FEET] = GAMEPAD_ITEM_CATEGORY_FEET,
	[EQUIP_TYPE_HAND] = GAMEPAD_ITEM_CATEGORY_HANDS,
	[EQUIP_TYPE_HEAD] = GAMEPAD_ITEM_CATEGORY_HEAD,
	[EQUIP_TYPE_LEGS] = GAMEPAD_ITEM_CATEGORY_LEGS,
	[EQUIP_TYPE_NECK] = GAMEPAD_ITEM_CATEGORY_AMULET,
	[EQUIP_TYPE_RING] = GAMEPAD_ITEM_CATEGORY_RING,
	[EQUIP_TYPE_SHOULDERS] = GAMEPAD_ITEM_CATEGORY_SHOULDERS,
	[EQUIP_TYPE_WAIST] = GAMEPAD_ITEM_CATEGORY_WAIST,
}
local function GetCategoryFromArmor(itemData)
	if itemData.isJunk then 
		return zo_strformat(SI_INVENTORY_HEADER, GetString(SI_ITEMFILTERTYPE9))
	end
	local category = ARMOR_EQUIP_TYPE_TO_CATEGORY_MAP[itemData.equipType]
	internalassert(category)
	return category
end

local function GetBestItemCategoryDescriptionForOther(itemData)
	local category = nil
	if itemData.itemType == ITEMTYPE_WEAPON then
		category = GetCategoryFromWeapon(itemData)
	elseif itemData.itemType == ITEMTYPE_ARMOR then
		category = GetCategoryFromArmor(itemData)
	else
		category = GetCategoryFromItemType(itemData.itemType)
	end
	if category then
		return GetString("SI_GAMEPADITEMCATEGORY", category)
	end
	return zo_strformat(SI_INVENTORY_HEADER, GetString("SI_ITEMTYPE", itemData.itemType))
end

local function GetBestItemCategoryDescription(itemData)
	if itemData.isJunk then
		itemData.sellInformationSortOrder = 1
		return zo_strformat(SI_INVENTORY_HEADER, GetString(SI_ITEMFILTERTYPE9))
	end
	
	if isMapItem(itemData) then
		return zo_strformat(SI_INVENTORY_HEADER, GetString("SI_SPECIALIZEDITEMTYPE", itemData.specializedItemType))
	end

	if itemData.itemType == ITEMTYPE_FURNISHING then
		local furnitureDataId = GetItemFurnitureDataId(itemData.bagId, itemData.slotIndex)
		if furnitureDataId ~= 0 then
			local categoryId, subcategoryId = GetFurnitureDataCategoryInfo(furnitureDataId)
			if categoryId then
				local categoryName = GetFurnitureCategoryInfo(categoryId)
				if categoryName ~= "" then
					return categoryName
				end
			end
		end
	end

	local categoryType = GetCategoryTypeFromWeaponType(itemData.bagId, itemData.slotIndex)
	if categoryType ==GAMEPAD_WEAPON_CATEGORY_UNCATEGORIZED then
		local weaponType = GetItemWeaponType(itemData.bagId, itemData.slotIndex)
		return GetString("SI_WEAPONTYPE", weaponType)
	elseif categoryType then
		return GetString("SI_GAMEPADWEAPONCATEGORY", categoryType)
	end

	local armorType = GetItemArmorType(itemData.bagId, itemData.slotIndex)
	if armorType ~= ARMORTYPE_NONE then
		return GetString("SI_ARMORTYPE", armorType)
	end

	return GetBestItemCategoryDescriptionForOther(itemData)
end

local function GetBestQuestItemCategoryDescription(questItemData)
	if questItemData.isJunk then 
		return zo_strformat(SI_INVENTORY_HEADER, GetString(SI_ITEMFILTERTYPE9))
	end
	local questItemCategory = GAMEPAD_QUEST_ITEM_CATEGORY_NOT_SLOTTABLE
	if CanQuickslotQuestItemById(questItemData.questItemId) then
		questItemCategory = GAMEPAD_QUEST_ITEM_CATEGORY_SLOTTABLE
	end

	return GetString("SI_GAMEPADQUESTITEMCATEGORY", questItemCategory)
	
end

function ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(itemData)
	return GetBestItemCategoryDescription(itemData)
end
--=============================================================================================================
--[[


ZO_PreHook(GAMEPAD_INVENTORY, "RefreshItemList", function(self)
	self.itemList:Clear()
	if self.categoryList:IsEmpty() then return end
	
	local targetCategoryData 		= self.categoryList:GetTargetData()
	local filteredEquipSlot 		= targetCategoryData.equipSlot
	local nonEquipableFilterType 	= targetCategoryData.filterType

	local listCategory = isCutomCategory[nonEquipableFilterType] and nonEquipableFilterType or ITEMFILTERTYPE_ALL
	local filteredDataTable
		
	local isQuestItemFilter = nonEquipableFilterType == ITEMFILTERTYPE_QUEST
	--special case for quest items
	if isQuestItemFilter then
		filteredDataTable = {}
		local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
		for _, questItems in pairs(questCache) do
			for _, questItem in pairs(questItems) do
				table.insert(filteredDataTable, questItem)
				questItem.bestItemCategoryName = zo_strformat(SI_INVENTORY_HEADER, GetBestQuestItemCategoryDescription(questItem))
			end
		end
		table.sort(filteredDataTable, ZO_GamepadInventory_QuestItemSortComparator)
	else
		local comparator = self:GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
		filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(comparator, BAG_BACKPACK, BAG_WORN)

		for _, itemData in pairs(filteredDataTable) do
			itemData.bestItemCategoryName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(itemData))
		end
		table.sort(filteredDataTable, ZO_GamepadInventory_DefaultItemSortComparator)
	end
	
	local lastBestItemCategoryName
	
	local function addToList(itemData, entryData)
		if itemData.bestItemCategoryName ~= lastBestItemCategoryName then
			lastBestItemCategoryName = itemData.bestItemCategoryName

			entryData:SetHeader(lastBestItemCategoryName)
			self.itemList:AddEntry("ZO_GamepadItemSubEntryTemplateWithHeader", entryData)
		else
			self.itemList:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
		end
	end

	for i, itemData in ipairs(filteredDataTable) do
		local entryData = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
		
		entryData:InitializeInventoryVisualData(itemData)

		if itemData.bagId == BAG_WORN then
			entryData.isEquippedInCurrentCategory = itemData.slotIndex == filteredEquipSlot
			entryData.isHiddenByWardrobe = WouldEquipmentBeHidden(itemData.slotIndex or EQUIP_SLOT_NONE)
			
		elseif isQuestItemFilter then
			local slotIndex = FindActionSlotMatchingSimpleAction(ACTION_TYPE_QUEST_ITEM, itemData.questItemId)
			entryData.isEquippedInCurrentCategory = slotIndex ~= nil
		else
			local slotIndex = FindActionSlotMatchingItem(itemData.bagId, itemData.slotIndex)
			entryData.isEquippedInCurrentCategory = slotIndex ~= nil
		end

		local remaining, duration
		if isQuestItemFilter then
			if itemData.toolIndex then
				remaining, duration = GetQuestToolCooldownInfo(itemData.questIndex, itemData.toolIndex)
			elseif itemData.stepIndex and itemData.conditionIndex then
				remaining, duration = GetQuestItemCooldownInfo(itemData.questIndex, itemData.stepIndex, itemData.conditionIndex)
			end

			ZO_InventorySlot_SetType(entryData, SLOT_TYPE_QUEST_ITEM)
		else
			remaining, duration = GetItemCooldownInfo(itemData.bagId, itemData.slotIndex)

			ZO_InventorySlot_SetType(entryData, SLOT_TYPE_GAMEPAD_INVENTORY_ITEM)
		end
		if remaining > 0 and duration > 0 then
			entryData:SetCooldown(remaining, duration)
		end
		
		entryData:SetIgnoreTraitInformation(true)

		if shouldAddItem[listCategory](itemData) then
			if itemData.bestItemCategoryName ~= lastBestItemCategoryName then
				lastBestItemCategoryName = itemData.bestItemCategoryName

				entryData:SetHeader(lastBestItemCategoryName)
				self.itemList:AddEntry("ZO_GamepadItemSubEntryTemplateWithHeader", entryData)
			else
				self.itemList:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
			end
		end
	end

	self.itemList:Commit()

	--	self:RefreshKeybinds()
	--	self:RefreshItemActions()
	return true
end)
]]
