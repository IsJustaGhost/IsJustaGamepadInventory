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
local customCategoies = {
	[ITEMFILTERTYPE_MAPS] = {
		['icon'] = "/esoui/art/crafting/gamepad/gp_crafting_menuicon_designs.dds"
	},
	[ITEMFILTERTYPE_JUNK] = {
		['icon'] = "/esoui/art/inventory/inventory_tabicon_junk_up.dds"
	},
	[ITEMFILTERTYPE_STOLEN] = {
		['icon'] = "/esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds"
	}
}

local isCutomCategory = {}
for filterType, icon in pairs(customCategoies) do
	isCutomCategory[filterType] = true
end

local function categoryNotEmpty(filterType)
	local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_BACKPACK)
	for slotId, itemData in pairs(bagCache) do
		if filterType == ITEMFILTERTYPE_STOLEN then
			if itemData.stolen then
				return true
			end
		elseif filterType == ITEMFILTERTYPE_MAPS then
			if isItemMap(itemData) then
				return true
			end
		elseif filterType == ITEMFILTERTYPE_MAPS then
			if isItemMap(itemData) then
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

local specialized_itemtype_map_survey_report = {
	[SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP] = true,
	[SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT] = true,
}
local function isItemMap(itemData)
	return specialized_itemtype_map_survey_report[itemData.specializedItemType] or false
end




local function filterDisabled(itemData)
	if itemData.isJunk then
		if IJA_GPINVENTORY.sv.filterJunk then
			return false
		else
			return true
		end
	end
	if itemData.stolen then
		if IJA_GPINVENTORY.sv.filterStolen then
			return false
		else
			return true
		end
	end
	if isItemMap(itemData) then
		if IJA_GPINVENTORY.sv.filterMaps then
			return false
		else
			return true
		end
	end
end

local function IsStolenItem(itemData)
	local isStolen = itemData.stolen
	if optFilterFunction then
		return isStolen and optFilterFunction(itemData)
	else
		return isStolen
	end
end
local function IsJunkItem(itemData)
	local isJunk = itemData.isJunk
	if optFilterFunction then
		return isJunk and optFilterFunction(itemData)
	else
		return isJunk
	end
--[[	
	if not itemData.stolen then
		return IsItemJunk(itemData.bagId, itemData.slotIndex)
	end
--]]
end
local function IsMap(itemData)
	local isMap = isItemMap(itemData)
	if optFilterFunction then
		return isMap and optFilterFunction(itemData)
	else
		return isMap
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


local function shouldShowNewSupplies()
	local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, BAG_BACKPACK)
	for slotId, itemData in pairs(bagCache) do
		if itemData.brandNew and ZO_InventoryUtils_DoesNewItemMatchSupplies(itemData) then
			if not (itemData.isJunk or itemData.stolen) then
				return true	
			end
		end
	end
end

---------------------------------------------------------------------------------------------------------------
-- Category Description Functions
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
	
	if itemData.specializedItemType == 100 then
		return zo_strformat(SI_INVENTORY_HEADER, GetString(SI_SPECIALIZEDITEMTYPE100))
	end
	if itemData.specializedItemType == 101 then
		return zo_strformat(SI_INVENTORY_HEADER, GetString(SI_SPECIALIZEDITEMTYPE101))
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
-- 
---------------------------------------------------------------------------------------------------------------
function ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, currentFilter)
    if not currentFilter then return true end
	
	if currentFilter == ITEMFILTERTYPE_JUNK and IJA_GPINVENTORY.sv.junkCategory then
		return shouldAddItem[ITEMFILTERTYPE_JUNK](itemData)
	elseif currentFilter == ITEMFILTERTYPE_STOLEN and IJA_GPINVENTORY.sv.stolenCategory then
		return shouldAddItem[ITEMFILTERTYPE_STOLEN](itemData)
	elseif currentFilter == ITEMFILTERTYPE_MAPS and IJA_GPINVENTORY.sv.mapsCategory then
		return shouldAddItem[ITEMFILTERTYPE_MAPS](itemData)
	else
		for i, filter in ipairs(itemData.filterData) do
			if filter == currentFilter then
				return true
			end
		end
	end
    return false
end

--[[
function ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, currentFilter)
    if not currentFilter then return true end
    for i, filter in ipairs(itemData.filterData) do
        if filter == currentFilter then
            return true
        end
    end
    return false
end
]]

local function GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
	return function(itemData)
		if filteredEquipSlot then
			return ZO_Character_DoesEquipSlotUseEquipType(filteredEquipSlot, itemData.equipType)
		end

		if nonEquipableFilterType then
			return ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, nonEquipableFilterType)
		end
		
		return ZO_InventoryUtils_DoesNewItemMatchSupplies(itemData)
	end
end

---------------------------------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------------------------------


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
	local comparetor = function(itemData)
		return (IJA_GPINVENTORY.showJunk and itemData.isJunk) or (IJA_GPINVENTORY.showStolen and itemData.stolen)
	end
	
	local bagCache = SHARED_INVENTORY:GenerateFullSlotData(comparetor, BAG_BACKPACK)
	
	local total = 0
	local test = 1
	for slotId, itemData in pairs(bagCache) do
		total = total + itemData.stackSellPrice
	end
	return zo_strformat(SI_TOOLTIP_ITEM_VALUE_FORMAT, total, GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS))
end
local function updateDynamicMapsHeader()
	local isSurvey = function(itemData) return itemData.specializedItemType == 101 end
	local isMap = function(itemData) return itemData.specializedItemType == 100 end
	
	local surveyCache = SHARED_INVENTORY:GenerateFullSlotData(isSurvey, BAG_BACKPACK)
	local mapCache = SHARED_INVENTORY:GenerateFullSlotData(isMap, BAG_BACKPACK)

	if #surveyCache > 0 then
		GAMEPAD_INVENTORY.mapsHeaderData.data3HeaderText = zo_strformat(SI_INVENTORY_HEADER, "Resource Surveys")
		GAMEPAD_INVENTORY.mapsHeaderData.data3Text = zo_strformat(SI_TOOLTIP_ITEM_VALUE_FORMAT, #surveyCache, "")
	end

	if #mapCache > 0 then
		if #surveyCache > 0 then
			GAMEPAD_INVENTORY.mapsHeaderData.data4HeaderText = zo_strformat(SI_INVENTORY_HEADER, "Treasure Maps")
			GAMEPAD_INVENTORY.mapsHeaderData.data4Text = zo_strformat(SI_TOOLTIP_ITEM_VALUE_FORMAT, #mapCache, "")
		else
			if GAMEPAD_INVENTORY.mapsHeaderData.data4HeaderText then GAMEPAD_INVENTORY.mapsHeaderData.data4HeaderText = nil end
			if GAMEPAD_INVENTORY.mapsHeaderData.data4Text then GAMEPAD_INVENTORY.mapsHeaderData.data4Text = nil end
			GAMEPAD_INVENTORY.mapsHeaderData.data3HeaderText = zo_strformat(SI_INVENTORY_HEADER, "Treasure Maps")
			GAMEPAD_INVENTORY.mapsHeaderData.data3Text = zo_strformat(SI_TOOLTIP_ITEM_VALUE_FORMAT, #mapCache, "")
		end
	end
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
	local headerData
	
	IJA_GPINVENTORY.showJunk = false
	IJA_GPINVENTORY.showStolen = false
	
	
	if self.categoryList:GetTargetData().showJunk and self:GetCurrentList():IsActive() then
		IJA_GPINVENTORY.showJunk = true
		self.customHeaderData.titleText = GetString(SI_ITEMFILTERTYPE9)
		headerData = self.customHeaderData
	elseif self.categoryList:GetTargetData().showStolen then
		IJA_GPINVENTORY.showStolen = true
		self.customHeaderData.titleText = GetString(SI_GAMEPAD_ITEM_STOLEN_LABEL)
		headerData = self.customHeaderData
	elseif self.categoryList:GetTargetData().showMaps then
		IJA_GPINVENTORY.showStolen = true
		self.mapsHeaderData.titleText = GetString("Surveys and Maps")
		updateDynamicMapsHeader()
		headerData = self.mapsHeaderData
	else
		return false
	end
	
	ZO_GamepadGenericHeader_Refresh(self.header, headerData, blockCallback)
	return true
end)

---------------------------------------------------------------------------------------------------------------
-- Category list
---------------------------------------------------------------------------------------------------------------
ZO_PreHook(GAMEPAD_INVENTORY, "RefreshCategoryList", function(self)
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
	--		local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchSupplies, nil, BAG_BACKPACK)
			local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, shouldShowNewSupplies())
			data:SetIconTintOnSelection(true)
			self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
		end
	end

	-- Materials
	if categoryNotEmpty(ITEMFILTERTYPE_CRAFTING)then 
		self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_CRAFTING, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_materials.dds")
	end
	-- Consumables
	if categoryNotEmpty(ITEMFILTERTYPE_QUICKSLOT)then 
		self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_QUICKSLOT, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_quickslot.dds")
	end
	-- Furnishing
	if categoryNotEmpty(ITEMFILTERTYPE_FURNISHING)then 
		self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_FURNISHING, "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_furnishings.dds")
	end
	-- Companion Items
	if categoryNotEmpty(ITEMFILTERTYPE_COMPANION)then 
		self:AddFilteredBackpackCategoryIfPopulated(ITEMFILTERTYPE_COMPANION, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_companionItems.dds")
	end

	do -- Quest Items
		local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
		if next(questCache) then
			local name = GetString(SI_GAMEPAD_INVENTORY_QUEST_ITEMS)
			local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_quest.dds"
			local data = ZO_GamepadEntryData:New(name, iconFile)
			data.filterType = ITEMFILTERTYPE_QUEST
			data:SetIconTintOnSelection(true)
			self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
		end
	end
		
	do	-- custom categories
		for filterType, icon in pairs(customCategoies) do
			if categoryNotEmpty(filterType) then
				self:AddFilteredBackpackCategoryIfPopulated(filterType, icon)
			end
		end
	end
		
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

---------------------------------------------------------------------------------------------------------------
-- Item list
---------------------------------------------------------------------------------------------------------------

--[[

local customCategoies = {
	[ITEMFILTERTYPE_MAPS] = {
		['icon'] = "/esoui/art/crafting/gamepad/gp_crafting_menuicon_designs.dds"
	},
	[ITEMFILTERTYPE_JUNK] = {
		['icon'] = "/esoui/art/inventory/inventory_tabicon_junk_up.dds"
	},
	[ITEMFILTERTYPE_STOLEN] = {
		['icon'] = "/esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds"
	}
}

	for filterType, icon in pairs(customCategoies) do
		if categoryNotEmpty(filterType) then
			self:AddFilteredBackpackCategoryIfPopulated(filterType, icon)
		end
	end

	do	-- custom categories
		for filterType, icon in pairs(customCategoies) do
			if categoryNotEmpty(filterType) then
				self:AddFilteredBackpackCategoryIfPopulated(filterType, icon)
			end
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
		
		
ZO_PreHook(GAMEPAD_INVENTORY, "RefreshItemList", function(self)
	self.itemList:Clear()
	if self.categoryList:IsEmpty() then return end
	
	local targetCategoryData 		= self.categoryList:GetTargetData()
	local filteredEquipSlot 		= targetCategoryData.equipSlot
	local nonEquipableFilterType 	= targetCategoryData.filterType
	local showMapCategory 			= targetCategoryData.showMaps
	local showJunkCategory 			= targetCategoryData.showJunk
	local showStolenCategory 		= targetCategoryData.showStolen
	local showBoPCategory 			= targetCategoryData.BoPAndTradeable

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
		local comparator = GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
		if showJunkCategory then
			filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(IsJunkItem, BAG_BACKPACK, BAG_WORN)
		elseif showStolenCategory then
			filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(IsStolenItem, BAG_BACKPACK, BAG_WORN)
		elseif showBoPCategory then
			filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(isBoPCureentlyTradeable, BAG_BACKPACK, BAG_WORN)
		elseif showMapCategory then
			filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(IsMap, BAG_BACKPACK, BAG_WORN)
--				table.sort(filteredDataTable, function(data1, data2) return ZO_TableOrderingFunction(data1, data2, "specializedItemType", DEFAULT_SORT_KEYS, ZO_SORT_ORDER_UP)  end)
		else
			filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(comparator, BAG_BACKPACK, BAG_WORN)
		end	
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

		entryData.isMap = isItemMap(itemData)
		
		if showStolenCategory and itemData.stolen then
			addToList(itemData, entryData)
		elseif showJunkCategory and itemData.isJunk then
			if itemData.stolen then
				if filterDisabled(itemData) then addToList(itemData, entryData) end
			else
				addToList(itemData, entryData)
			end
		elseif showMapCategory and entryData.isMap then
			if itemData.isJunk then
				if filterDisabled(itemData) then addToList(itemData, entryData) end
			else
				addToList(itemData, entryData)
			end
		elseif showBoPCategory and itemData.isBoPTradeable then
			if itemData.isJunk then
				if filterDisabled(itemData) then addToList(itemData, entryData) end
			else
				addToList(itemData, entryData)
			end
		else
			if itemData.isJunk or itemData.stolen or entryData.isMap or itemData.isBoPTradeable then
				if filterDisabled(itemData) then addToList(itemData, entryData) end
			else
				addToList(itemData, entryData)
			end
		end
	end
	self.itemList:Commit()
	self:RefreshKeybinds()
	self:RefreshItemActions()
	return true
end)
]]


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
	SetItemIsJunk(bagId, slotIndex, isJunk)
	PlaySound(isJunk and SOUNDS.INVENTORY_ITEM_JUNKED or SOUNDS.INVENTORY_ITEM_UNJUNKED)
	
	if SCENE_MANAGER:IsShowing("gamepad_inventory_root") or SCENE_MANAGER:IsSceneOnStack("gamepad_inventory_root") then
		local lastItem = GAMEPAD_INVENTORY:GetCurrentList():GetNumEntries() == 1 and true or false
		if lastItem then
			GAMEPAD_INVENTORY:SwitchActiveList(INVENTORY_CATEGORY_LIST, true)
			GAMEPAD_INVENTORY.actionMode = CATEGORY_ITEM_ACTION_MODE
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

---------------------------------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------------------------------
function IJA_GPInventory_Initialize( ... )
    IJA_GPINVENTORY = IJA_GPInventory:New( ... )
end



--[[

--]]