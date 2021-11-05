local defaults = {
	displayName = "|cFF00FFIsJusta|r |cffffffGamepad Inventory Update|r",
	name = "IsJustaGamepadInventory",
	version = "2.4"
}

local svVersion = 2.4

local INVENTORY_CATEGORY_LIST = "categoryList"
local INVENTORY_ITEM_LIST = "itemList"
local INVENTORY_CRAFT_BAG_LIST = "craftBagList"

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
	self.savedVars = AccountWideSavedVars
	
	self:InitJunkSort()
end

function IJA_GPInventory:OnPlayerActivated()
	self.control:UnregisterForEvent(EVENT_PLAYER_ACTIVATED)

	self:SetupSettings()
	self:AddInventoryActions()
	d( self.displayName .. " version: " .. self.version)
end

---------------------------------------------------------------------------------------------------------------
-- Custom Categories
---------------------------------------------------------------------------------------------------------------
local isCutomCategory = {
	[ITEMFILTERTYPE_JUNK] = true,
	[ITEMFILTERTYPE_CONTAINER] = true,
	[ITEMFILTERTYPE_FOOD_DRINK] = true,
	[ITEMFILTERTYPE_MAPS] = true,
	[ITEMFILTERTYPE_POTION] = true,
	[ITEMFILTERTYPE_RECIPE_STYLE_PAGE] = true,
	[ITEMFILTERTYPE_REPAIR] = true,
	[ITEMFILTERTYPE_SIEGE] = true,
	[ITEMFILTERTYPE_STOLEN] = true,
	[ITEMFILTERTYPE_TREASURE] = true,
	[ITEMFILTERTYPE_WRIT] = true
}

---------------------------------------------------------------------------------------------------------------
-- Comparetors
---------------------------------------------------------------------------------------------------------------
local ITEMTYPE_CONTAINER = {
	[SPECIALIZED_ITEMTYPE_CONTAINER_EVENT] = true,	-- SPECIALIZED_ITEMTYPE_CONTAINER_EVENT = 851
	[SPECIALIZED_ITEMTYPE_CONTAINER] = true,	-- SPECIALIZED_ITEMTYPE_CONTAINER = 850
}
local ITEMTYPE_FOOD_DRINK = {
	[SPECIALIZED_ITEMTYPE_DRINK_ALCOHOLIC] = true,	-- SPECIALIZED_ITEMTYPE_DRINK_ALCOHOLIC = 20
	[SPECIALIZED_ITEMTYPE_DRINK_CORDIAL_TEA] = true,	-- SPECIALIZED_ITEMTYPE_DRINK_CORDIAL_TEA = 25
	[SPECIALIZED_ITEMTYPE_DRINK_DISTILLATE] = true,	-- SPECIALIZED_ITEMTYPE_DRINK_DISTILLATE = 26
	[SPECIALIZED_ITEMTYPE_DRINK_LIQUEUR] = true,	-- SPECIALIZED_ITEMTYPE_DRINK_LIQUEUR = 23
	[SPECIALIZED_ITEMTYPE_DRINK_TEA] = true,	-- SPECIALIZED_ITEMTYPE_DRINK_TEA = 21
	[SPECIALIZED_ITEMTYPE_DRINK_TINCTURE] = true,	-- SPECIALIZED_ITEMTYPE_DRINK_TINCTURE = 24
	[SPECIALIZED_ITEMTYPE_DRINK_TONIC] = true,	-- SPECIALIZED_ITEMTYPE_DRINK_TONIC = 22
	[SPECIALIZED_ITEMTYPE_DRINK_UNIQUE] = true,	-- SPECIALIZED_ITEMTYPE_DRINK_UNIQUE = 27
	[SPECIALIZED_ITEMTYPE_FOOD_ENTREMET] = true,	-- SPECIALIZED_ITEMTYPE_FOOD_ENTREMET = 6
	[SPECIALIZED_ITEMTYPE_FOOD_FRUIT] = true,	-- SPECIALIZED_ITEMTYPE_FOOD_FRUIT = 2
	[SPECIALIZED_ITEMTYPE_FOOD_GOURMET] = true,	-- SPECIALIZED_ITEMTYPE_FOOD_GOURMET = 7
	[SPECIALIZED_ITEMTYPE_FOOD_MEAT] = true,	-- SPECIALIZED_ITEMTYPE_FOOD_MEAT = 1
	[SPECIALIZED_ITEMTYPE_FOOD_RAGOUT] = true,	-- SPECIALIZED_ITEMTYPE_FOOD_RAGOUT = 5
	[SPECIALIZED_ITEMTYPE_FOOD_SAVOURY] = true,	-- SPECIALIZED_ITEMTYPE_FOOD_SAVOURY = 4
	[SPECIALIZED_ITEMTYPE_FOOD_UNIQUE] = true,	-- SPECIALIZED_ITEMTYPE_FOOD_UNIQUE = 8
	[SPECIALIZED_ITEMTYPE_FOOD_VEGETABLE] = true	-- SPECIALIZED_ITEMTYPE_FOOD_VEGETABLE = 3
}
local ITEMTYPE_TROPHY_SURVEY_REPORT_TREASURE_MAP = {
	[SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP] = true,	-- SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP = 100
	[SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT] = true	-- SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT = 101
}
local ITEMTYPE_POTION = {
	[SPECIALIZED_ITEMTYPE_POTION] = true	-- SPECIALIZED_ITEMTYPE_POTION = 450
}
local ITEMTYPE_RECIPE_STYLE_PAGE = {
	[SPECIALIZED_ITEMTYPE_CONTAINER_STYLE_PAGE] = true,	-- SPECIALIZED_ITEMTYPE_CONTAINER_STYLE_PAGE = 852
	[SPECIALIZED_ITEMTYPE_RECIPE_ALCHEMY_FORMULA_FURNISHING] = true,	-- SPECIALIZED_ITEMTYPE_RECIPE_ALCHEMY_FORMULA_FURNISHING = 175
	[SPECIALIZED_ITEMTYPE_RECIPE_BLACKSMITHING_DIAGRAM_FURNISHING] = true,	-- SPECIALIZED_ITEMTYPE_RECIPE_BLACKSMITHING_DIAGRAM_FURNISHING = 172
	[SPECIALIZED_ITEMTYPE_RECIPE_CLOTHIER_PATTERN_FURNISHING] = true,	-- SPECIALIZED_ITEMTYPE_RECIPE_CLOTHIER_PATTERN_FURNISHING = 173
	[SPECIALIZED_ITEMTYPE_RECIPE_ENCHANTING_SCHEMATIC_FURNISHING] = true,	-- SPECIALIZED_ITEMTYPE_RECIPE_ENCHANTING_SCHEMATIC_FURNISHING = 174
	[SPECIALIZED_ITEMTYPE_RECIPE_JEWELRYCRAFTING_SKETCH_FURNISHING] = true,	-- SPECIALIZED_ITEMTYPE_RECIPE_JEWELRYCRAFTING_SKETCH_FURNISHING = 178
	[SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_DESIGN_FURNISHING] = true,	-- SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_DESIGN_FURNISHING = 176
	[SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK] = true,	-- SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK = 171
	[SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD] = true,	-- SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD = 170
	[SPECIALIZED_ITEMTYPE_RECIPE_WOODWORKING_BLUEPRINT_FURNISHING] = true	-- SPECIALIZED_ITEMTYPE_RECIPE_WOODWORKING_BLUEPRINT_FURNISHING = 177
}
local ITEMTYPE_REPAIRKIT = {
	[SPECIALIZED_ITEMTYPE_CROWN_REPAIR] = true,	-- SPECIALIZED_ITEMTYPE_CROWN_REPAIR = 2500
	[SPECIALIZED_ITEMTYPE_GROUP_REPAIR] = true,	-- SPECIALIZED_ITEMTYPE_GROUP_REPAIR = 3150
}

local ITEMTYPE_SIEGE = {
	[SPECIALIZED_ITEMTYPE_AVA_REPAIR] = true,	-- SPECIALIZED_ITEMTYPE_AVA_REPAIR = 2100
	[SPECIALIZED_ITEMTYPE_SIEGE_BALLISTA] = true,	-- SPECIALIZED_ITEMTYPE_SIEGE_BALLISTA = 401
	[SPECIALIZED_ITEMTYPE_SIEGE_BATTLE_STANDARD] = true,	-- SPECIALIZED_ITEMTYPE_SIEGE_BATTLE_STANDARD = 408
	[SPECIALIZED_ITEMTYPE_SIEGE_CATAPULT] = true,	-- SPECIALIZED_ITEMTYPE_SIEGE_CATAPULT = 404
	[SPECIALIZED_ITEMTYPE_SIEGE_GRAVEYARD] = true,	-- SPECIALIZED_ITEMTYPE_SIEGE_GRAVEYARD = 405
	[SPECIALIZED_ITEMTYPE_SIEGE_LANCER] = true,	-- SPECIALIZED_ITEMTYPE_SIEGE_LANCER = 409
	[SPECIALIZED_ITEMTYPE_SIEGE_MONSTER] = true,	-- SPECIALIZED_ITEMTYPE_SIEGE_MONSTER = 406
	[SPECIALIZED_ITEMTYPE_SIEGE_OIL] = true,	-- SPECIALIZED_ITEMTYPE_SIEGE_OIL = 407
	[SPECIALIZED_ITEMTYPE_SIEGE_RAM] = true,	-- SPECIALIZED_ITEMTYPE_SIEGE_RAM = 402
	[SPECIALIZED_ITEMTYPE_SIEGE_TREBUCHET] = true,	-- SPECIALIZED_ITEMTYPE_SIEGE_TREBUCHET = 400
	[SPECIALIZED_ITEMTYPE_SIEGE_UNIVERSAL] = true,	-- SPECIALIZED_ITEMTYPE_SIEGE_UNIVERSAL = 403
	[SPECIALIZED_ITEMTYPE_RECALL_STONE_KEEP] = true	-- SPECIALIZED_ITEMTYPE_RECALL_STONE_KEEP = 3100
}
local ITEMTYPE_TREASURE = {
	[SPECIALIZED_ITEMTYPE_COLLECTIBLE_RARE_FISH] = true,	-- SPECIALIZED_ITEMTYPE_COLLECTIBLE_RARE_FISH = 80
	[SPECIALIZED_ITEMTYPE_COLLECTIBLE_MONSTER_TROPHY] = true,	-- SPECIALIZED_ITEMTYPE_COLLECTIBLE_MONSTER_TROPHY = 81
	[SPECIALIZED_ITEMTYPE_TROPHY_TOY] = true,	-- SPECIALIZED_ITEMTYPE_TROPHY_TOY = 111
--	[SPECIALIZED_ITEMTYPE_TREASURE] = true,	-- SPECIALIZED_ITEMTYPE_TREASURE = 2550
}
local ITEMTYPE_WRIT = {
	[SPECIALIZED_ITEMTYPE_HOLIDAY_WRIT] = true,	-- SPECIALIZED_ITEMTYPE_HOLIDAY_WRIT = 2760
	[SPECIALIZED_ITEMTYPE_MASTER_WRIT] = true	-- SPECIALIZED_ITEMTYPE_MASTER_WRIT = 2750
}

local function isContainerItem(itemData)
	return ITEMTYPE_CONTAINER[itemData.specializedItemType] or false
end
local function isFoodItem(itemData)
	return ITEMTYPE_FOOD_DRINK[itemData.specializedItemType] or false
end
local function isJunkItem(itemData)
	return itemData.isJunk or false
end
local function isMapItem(itemData)
	return ITEMTYPE_TROPHY_SURVEY_REPORT_TREASURE_MAP[itemData.specializedItemType] or false
end
local function isPotionItem(itemData)
	return ITEMTYPE_POTION[itemData.specializedItemType] or false
end
local function isRecipeItem(itemData)
	return ITEMTYPE_RECIPE_STYLE_PAGE[itemData.specializedItemType] or itemData.itemType == ITEMTYPE_RACIAL_STYLE_MOTIF or false
end
local function isRepairItem(itemData)
	return ITEMTYPE_REPAIRKIT[itemData.specializedItemType] or false
end
local function isSiegeItem(itemData)
	return ITEMTYPE_SIEGE[itemData.specializedItemType] or false
end
local function isStolenItem(itemData)
	return itemData.stolen or false
end
local function isTreasureItem(itemData)
	return ITEMTYPE_TREASURE[itemData.specializedItemType] or false
end
local function isWritItem(itemData)
	return ITEMTYPE_WRIT[itemData.specializedItemType] or false
end

local filterTypeComparators = {
	[ITEMTYPE_CONTAINER]				= function(itemData) return isContainerItem(itemData) end,
	[ITEMFILTERTYPE_FOOD_DRINK]			= function(itemData) return isFoodItem(itemData) end,
	[ITEMFILTERTYPE_JUNK]				= function(itemData) return isJunkItem(itemData) end,
	[ITEMFILTERTYPE_MAPS]				= function(itemData) return isMapItem(itemData) end,
	[ITEMFILTERTYPE_POTION]				= function(itemData) return isPotionItem(itemData) end,
	[ITEMFILTERTYPE_RECIPE_STYLE_PAGE]	= function(itemData) return isRecipeItem(itemData) end,
	[ITEMFILTERTYPE_REPAIR]				= function(itemData) return isRepairItem(itemData) end,
	[ITEMFILTERTYPE_SIEGE]				= function(itemData) return isSiegeItem(itemData) end,
	[ITEMFILTERTYPE_STOLEN]				= function(itemData) return isStolenItem(itemData) end,
	[ITEMFILTERTYPE_TREASURE]			= function(itemData) return isTreasureItem(itemData) end,
	[ITEMFILTERTYPE_WRIT]				= function(itemData) return isWritItem(itemData) end,

}

---------------------------------------------------------------------------------------------------------------
-- Helper functions
---------------------------------------------------------------------------------------------------------------
local function itemDataToFilterType(itemData)
	if itemData.isJunk then
		return IJA_GPINVENTORY.savedVars.enabledCategories[ITEMFILTERTYPE_JUNK] and ITEMFILTERTYPE_JUNK
	end
	if itemData.stolen then
	return IJA_GPINVENTORY.savedVars.filteredCategories[ITEMFILTERTYPE_STOLEN] and ITEMFILTERTYPE_STOLEN
	end

	for filterType, comparator in pairs(filterTypeComparators) do
	
		if comparator(itemData) then
			return filterType
		end
	end
end

local function showJunkOrStolen(itemData, currentFilter)
--	if GAMEPAD_INVENTORY.currentListType == "categoryList" then return true end
	if currentFilter ~= ITEMFILTERTYPE_JUNK and currentFilter ~= ITEMFILTERTYPE_STOLEN then
		if itemData.isJunk then
			if IJA_GPINVENTORY.savedVars.enabledCategories[ITEMFILTERTYPE_JUNK] then
				return not IJA_GPINVENTORY.savedVars.filteredCategories[ITEMFILTERTYPE_JUNK]
			end
		end
		if itemData.stolen then
			if IJA_GPINVENTORY.savedVars.enabledCategories[ITEMFILTERTYPE_STOLEN] then
				return not IJA_GPINVENTORY.savedVars.filteredCategories[ITEMFILTERTYPE_STOLEN]
			end
		end
	end
	
	return true
end

local function filterDisabled(itemData, currentFilter)
	local filterType = itemDataToFilterType(itemData)
	if filterType ~= currentFilter then
		return not IJA_GPINVENTORY.savedVars.filteredCategories[filterType]
	end
	
	return showJunkOrStolen(itemData, currentFilter)
end

local shouldAddItem = {
	[ITEMFILTERTYPE_ALL] = function(itemData, filterType)
		if isCutomCategory[filterType] then
			return filterDisabled(itemData)
		else
			for i, filter in ipairs(itemData.filterData) do
				if filter == filterType then
					return true
				end
			end
		end
	end,
	[ITEMFILTERTYPE_JUNK] = function(itemData, filterType)
		if itemData.isJunk and IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			return filterDisabled(itemData, filterType)
		end
	end,
	[ITEMFILTERTYPE_CONTAINER] = function(itemData, filterType)
		if isContainerItem(itemData) and IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			return filterDisabled(itemData, filterType)
		end
	end,
	[ITEMFILTERTYPE_FOOD_DRINK] = function(itemData, filterType)
		if isFoodItem(itemData) and IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			return filterDisabled(itemData, filterType)
		end
	end,
	[ITEMFILTERTYPE_MAPS] = function(itemData, filterType)
		if isMapItem(itemData) and IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			return filterDisabled(itemData, filterType)
		end
	end,
	[ITEMFILTERTYPE_POTION] = function(itemData, filterType)
		if isPotionItem(itemData) and IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			return filterDisabled(itemData, filterType)
		end
	end,
	[ITEMFILTERTYPE_RECIPE_STYLE_PAGE] = function(itemData, filterType)
		if isRecipeItem(itemData) and IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			return filterDisabled(itemData, filterType)
		end
	end,
	[ITEMFILTERTYPE_REPAIR] = function(itemData, filterType)
		if isRepairItem(itemData) and IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			return filterDisabled(itemData, filterType)
		end
	end,
	[ITEMFILTERTYPE_SIEGE] = function(itemData, filterType)
		if isSiegeItem(itemData) and IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			return filterDisabled(itemData, filterType)
		end
	end,
	[ITEMFILTERTYPE_STOLEN] = function(itemData, filterType)
		if IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			return itemData.stolen
		end
	end,
	[ITEMFILTERTYPE_TREASURE] = function(itemData, filterType)
		if isTreasureItem(itemData) and IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			return filterDisabled(itemData, filterType)
		end
	end,
	[ITEMFILTERTYPE_WRIT] = function(itemData, filterType)
		if isWritItem(itemData) and IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			return filterDisabled(itemData, filterType)
		end
	end,
}
	
---------------------------------------------------------------------------------------------------------------
-- Category Description functions
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
	[ITEMTYPE_REPAIRKIT] = GAMEPAD_ITEM_CATEGORY_TOOL,
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
	
	local customFilter = itemDataToFilterType(itemData)
	if isCutomCategory[customFilter] and IJA_GPINVENTORY.savedVars.filteredCategories[customFilter] then
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

function ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(itemData)
	return GetBestItemCategoryDescription(itemData)
end

---------------------------------------------------------------------------------------------------------------
-- Main Filters
---------------------------------------------------------------------------------------------------------------
local original_GetItemDataFilterComparator = GAMEPAD_INVENTORY.GetItemDataFilterComparator
function GAMEPAD_INVENTORY:GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
	local function doesItemPassFilter(itemData, currentFilter)
		-- get original or libFilters filter
		local comparator = original_GetItemDataFilterComparator(GAMEPAD_INVENTORY, filteredEquipSlot, currentFilter)
		local result = comparator(itemData)
		
		if result then
			if isCutomCategory[nonEquipableFilterType] then
				return shouldAddItem[nonEquipableFilterType](itemData, nonEquipableFilterType)
			end
			
			local customFilter = itemDataToFilterType(itemData)
			if isCutomCategory[customFilter] then
				return shouldAddItem[ITEMFILTERTYPE_ALL](itemData, customFilter)
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
	
	local comparetor = filterTypeComparators[filterType]
	
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

local quickSlotFilters = {
	[ITEMFILTERTYPE_POTION] = true,
	[ITEMFILTERTYPE_FOOD_DRINK] = true,
	[ITEMFILTERTYPE_MAPS] = true,
	[ITEMFILTERTYPE_CONTAINER] = true,
	[ITEMFILTERTYPE_SIEGE] = true,
	[ITEMFILTERTYPE_REPAIR] = true,
}

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
	
	if isCutomCategory[filterType] and self:GetCurrentList():IsActive() then
		local headerData
		
		local headerText = GetString("SI_ITEMFILTERTYPE", filterType)
--		local headerText = GetString("SI_IJA_GPINVENTORY_HEADER", filterType)

		if filterType == ITEMFILTERTYPE_MAPS then
			self.mapsHeaderData.titleText = headerText
			dynamicMapHeaders_Update()
			headerData = self.mapsHeaderData
			
		else
			self.customHeaderData.titleText = headerText
			headerData = self.customHeaderData
		end
		
		if quickSlotFilters[filterType] then self.selectedItemFilterType = ITEMFILTERTYPE_QUICKSLOT end
		ZO_GamepadGenericHeader_Refresh(self.header, headerData, blockCallback)
		return true
	else
		-- if not custom category then run default RefreshHeader
		return false
	end
end)

---------------------------------------------------------------------------------------------------------------
-- Category list
---------------------------------------------------------------------------------------------------------------
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


	local customHeader = nil

	local function AddFilteredBackpackCategoryIfEnabled(filterType, iconFile)
		if IJA_GPINVENTORY.savedVars.enabledCategories[filterType] then
			local isListEmpty = self:IsItemListEmpty(nil, filterType)
			if not isListEmpty then
				local name = GetString("SI_ITEMFILTERTYPE", filterType)
				local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, filterType, BAG_BACKPACK)
				local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
				data.filterType = filterType
				data:SetIconTintOnSelection(true)
				
				if customHeader == nil then
					customHeader = GetString(SI_IJA_GPINVENTORY_CATEGORIES_HEADER)
					self.categoryList:AddEntry("ZO_GamepadItemEntryTemplateWithHeader", data)
					data:SetHeader(customHeader)
				else
					self.categoryList:AddEntry("ZO_GamepadItemEntryTemplate", data)
				end
			end
		end
	end
		
	AddFilteredBackpackCategoryIfEnabled(ITEMFILTERTYPE_POTION, "/esoui/art/tradinghouse/gamepad/gp_tradinghouse_materials_potions_potionsolvent.dds")
	AddFilteredBackpackCategoryIfEnabled(ITEMFILTERTYPE_FOOD_DRINK, "/esoui/art/tradinghouse/gamepad/gp_tradinghouse_materials_provisioning_food.dds")
	AddFilteredBackpackCategoryIfEnabled(ITEMFILTERTYPE_MAPS, "EsoUI/Art/crafting/Gamepad/gp_crafting_menuicon_designs.dds")
	AddFilteredBackpackCategoryIfEnabled(ITEMFILTERTYPE_CONTAINER, "/esoui/art/icons/servicemappins/servicepin_bank.dds")
	AddFilteredBackpackCategoryIfEnabled(ITEMFILTERTYPE_REPAIR, "/esoui/art/treeicons/gamepad/gp_tools.dds")
	AddFilteredBackpackCategoryIfEnabled(ITEMFILTERTYPE_RECIPE_STYLE_PAGE, "/esoui/art/crafting/gamepad/gp_crafting_menuicon_schematics.dds")
	AddFilteredBackpackCategoryIfEnabled(ITEMFILTERTYPE_TREASURE, "/esoui/art/tradinghouse/gamepad/gp_tradinghouse_other_trophy_types.dds")
	AddFilteredBackpackCategoryIfEnabled(ITEMFILTERTYPE_WRIT, "/esoui/art/tradinghouse/gamepad/gp_tradinghouse_master_writ.dds")
	AddFilteredBackpackCategoryIfEnabled(ITEMFILTERTYPE_SIEGE, "/esoui/art/treeicons/gamepad/gp_tutorial_idexicon_ava.dds")
	AddFilteredBackpackCategoryIfEnabled(ITEMFILTERTYPE_JUNK, "esoui/art/inventory/inventory_tabicon_junk_up.dds")
	AddFilteredBackpackCategoryIfEnabled(ITEMFILTERTYPE_STOLEN, "esoui/art/inventory/gamepad/gp_inventory_icon_stolenitem.dds")
	
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
	savedVars = self.savedVars
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
	--		GAMEPAD_INVENTORY:SwitchActiveList(INVENTORY_CATEGORY_LIST, true)
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
		name = self.displayName,
		displayName = self.displayName,
		author = "IsJustaGhost",
		version = self.version,
		registerForRefresh = true,
		registerForDefaults = true
	}
	LAM2:RegisterAddonPanel(self.name, panelData)

	if not self.savedVars.enabledCategories then self.savedVars.enabledCategories = {} end
	if not self.savedVars.filteredCategories then self.savedVars.filteredCategories = {} end
	
	local controlList = {}
	for filterType,v in pairs(isCutomCategory) do
		local control = {
			type = "checkbox",
			name = GetString("SI_IJA_GPINVENTORY_CATEGORY", filterType),
			tooltip = GetString("SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP", filterType),
			getFunc = function() return self.savedVars.enabledCategories[filterType] end,
			setFunc = function(value) 
				self.savedVars.enabledCategories[filterType] = value 
				if value ~= true then self.savedVars.filteredCategories[filterType] = value end
			end,
			width = "half"
		}
		controlList[#controlList + 1] = control
		
		local control = {
			type = "checkbox",
			name = GetString("SI_IJA_GPINVENTORY_CATEGORY_FILTER", filterType),
			tooltip = GetString("SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP", filterType),
			getFunc = function() return self.savedVars.filteredCategories[filterType] end,
			setFunc = function(value) self.savedVars.filteredCategories[filterType] = value end,
			width = "half",
			disabled = function() return not self.savedVars.enabledCategories[filterType] end,
		}
		
		controlList[#controlList + 1] = control
	end
	
	local optionsTable = {
		{
            type = "header",
            name = GetString(SI_IJA_GPINVENTORY_CATEGORIES),
            width = "full",
        },
	
		{
			type = "checkbox",
			name = GetString(SI_IJA_GPINVENTORY_SORTBANK_WITHDRAW),
			tooltip = GetString(SI_IJA_GPINVENTORY_SORTBANK_WITHDRAW_TOOLTIP),
			getFunc = function() return self.savedVars.withdraw end,
			setFunc = function(value) self.savedVars.withdraw = value end,
            width = "half"
		},
		{
			type = "checkbox",
			name = GetString(SI_IJA_GPINVENTORY_SORTBANK_DEPOSIT),
			tooltip = GetString(SI_IJA_GPINVENTORY_SORTBANK_DEPOSIT_TOOLTIP),
			getFunc = function() return self.savedVars.deposit end,
			setFunc = function(value) self.savedVars.deposit = value end,
            width = "half",
		},
		{
			type = "submenu",
			name = GetString(SI_IJA_GPINVENTORY_CATEGORIES),
			reference = "CustomCategories",
			controls = controlList,
		}
	}
	LAM2:RegisterOptionControls(self.name, optionsTable)
end

---------------------------------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------------------------------
function IJA_GPInventory_Initialize( ... )
    IJA_GPINVENTORY = IJA_GPInventory:New( ... )
end




--[[
2.4
added more catigories


--]]


