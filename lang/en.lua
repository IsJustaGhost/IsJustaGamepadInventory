------------------------------------------------
-- English localization for IsJustaGamepadInventory
------------------------------------------------
--	Create global custom ITEMFILTERTYPEs dynamically based on ITEMFILTERTYPE_ITERATION_END
ITEMFILTERTYPE_CONTAINER = ITEMFILTERTYPE_ITERATION_END + 1
ITEMFILTERTYPE_FOOD_DRINK = ITEMFILTERTYPE_CONTAINER + 1
ITEMFILTERTYPE_MAPS = ITEMFILTERTYPE_FOOD_DRINK + 1
ITEMFILTERTYPE_POTION = ITEMFILTERTYPE_MAPS + 1
ITEMFILTERTYPE_RECIPE_STYLE_PAGE = ITEMFILTERTYPE_POTION + 1
ITEMFILTERTYPE_REPAIR = ITEMFILTERTYPE_RECIPE_STYLE_PAGE + 1
ITEMFILTERTYPE_SIEGE = ITEMFILTERTYPE_REPAIR + 1
ITEMFILTERTYPE_STOLEN = ITEMFILTERTYPE_SIEGE + 1
ITEMFILTERTYPE_TREASURE = ITEMFILTERTYPE_STOLEN + 1
ITEMFILTERTYPE_WRIT = ITEMFILTERTYPE_TREASURE + 1

-- localized strings
local containerString = GetString(SI_ITEMTYPEDISPLAYCATEGORY26) -- SI_ITEMTYPEDISPLAYCATEGORY26 = "Containers"
--	SI_ITEMTYPEDISPLAYCATEGORY19 = "Food" SI_ITEMTYPEDISPLAYCATEGORY20 = "Drinks"
local foofDrinkString = zo_strformat(SI_UNIT_FRAME_BARVALUE, GetString(SI_ITEMTYPEDISPLAYCATEGORY19), GetString(SI_ITEMTYPEDISPLAYCATEGORY20))
local potionString = GetString(SI_ITEMTYPEDISPLAYCATEGORY22) -- SI_ITEMTYPEDISPLAYCATEGORY22 = "Potions"
 -- SI_ITEMTYPEDISPLAYCATEGORY21 = "Recipes" SI_ITEMTYPEDISPLAYCATEGORY24 = "Style Motifs"
local recipesString = zo_strformat(SI_UNIT_FRAME_BARVALUE, GetString(SI_ITEMTYPEDISPLAYCATEGORY21), GetString(SI_ITEMTYPEDISPLAYCATEGORY24))
local repairKitsString = GetString(SI_HOOK_POINT_STORE_REPAIR_KIT_HEADER):gsub(":$", "") -- SI_HOOK_POINT_STORE_REPAIR_KIT_HEADER = "Repair Kits:"
local siegeString = GetString(SI_ITEMTYPEDISPLAYCATEGORY32) -- SI_ITEMTYPEDISPLAYCATEGORY32 = "Siege Items"
local treasuresString = GetString(SI_ITEMTYPE56) .. "s" -- SI_ITEMTYPE56 = "Treasure"
local writsString = GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES212) -- SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES212 = "Writs"
local stolenString = GetString(SI_GAMEPAD_ITEM_STOLEN_LABEL) -- SI_GAMEPAD_ITEM_STOLEN_LABEL = 5568 = "Stolen"

local surveyString = GetString(SI_SPECIALIZEDITEMTYPE101):gsub(" .*$", '')
surveyString = zo_strformat(SI_UNIT_NAME, surveyString .. 's')

local mapsSurveyString = zo_strformat(SI_UNIT_FRAME_BARVALUE, zo_strformat(SI_UNIT_NAME, surveyString .. 's'), GetString(SI_MAIN_MENU_MAP) .. "s")
-- custom strings
local strings = {
	SI_IJA_GPINVENTORY_CATEGORIES_HEADER			= "Sorted Categories",
	SI_IJA_GPINVENTORY_CATEGORIES					= "Category and filter options",

	SI_IJA_GPINVENTORY_SORTBANK_WITHDRAW			= "Bank Withdraw",
	SI_IJA_GPINVENTORY_SORTBANK_WITHDRAW_TOOLTIP	= "Enabled: Sorts junk in bank withdraw list to bottom.",

	SI_IJA_GPINVENTORY_SORTBANK_DEPOSIT				= "Bank Deposit",
	SI_IJA_GPINVENTORY_SORTBANK_DEPOSIT_TOOLTIP		= "Enabled: sorts junk in bank and guild bank deposit lists to bottom."
}





strings["SI_IJA_GPINVENTORY_CATEGORY" .. ITEMFILTERTYPE_CONTAINER]					= "Use " .. containerString .. " Category"
strings["SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP" .. ITEMFILTERTYPE_CONTAINER]			= "Enabled: adds a dynamic category for select containers."
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER" .. ITEMFILTERTYPE_CONTAINER]			= "Filter " .. containerString
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP" .. ITEMFILTERTYPE_CONTAINER]	= "Enabled: removes containers from all other categories."

strings["SI_IJA_GPINVENTORY_CATEGORY" .. ITEMFILTERTYPE_FOOD_DRINK]							= "Use " .. foofDrinkString .. " Category"
strings["SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP" .. ITEMFILTERTYPE_FOOD_DRINK]			= "Enabled: adds a dynamic category for " .. foofDrinkString .. "."
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER" .. ITEMFILTERTYPE_FOOD_DRINK]			= "Filter " .. foofDrinkString
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP" .. ITEMFILTERTYPE_FOOD_DRINK]	= "Enabled: removes " .. foofDrinkString .. " from all other categories."

strings["SI_IJA_GPINVENTORY_CATEGORY" .. ITEMFILTERTYPE_JUNK]						= "Use " .. GetString(SI_ITEMFILTERTYPE9) .. " Category"
strings["SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP" .. ITEMFILTERTYPE_JUNK]				= "Enabled: adds a dynamic category for items marked as junk."
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER" .. ITEMFILTERTYPE_JUNK]				= "Filter Junk"
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP" .. ITEMFILTERTYPE_JUNK]		= "Enabled: removes items marked as junk from all other categories."

strings["SI_IJA_GPINVENTORY_CATEGORY" .. ITEMFILTERTYPE_POTION]						= "Use " .. potionString .. " Category"
strings["SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP" .. ITEMFILTERTYPE_POTION]				= "Enabled: adds a dynamic category for " .. potionString .. "."
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER" .. ITEMFILTERTYPE_POTION]				= "Filter " .. potionString
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP" .. ITEMFILTERTYPE_POTION]		= "Enabled: removes " .. potionString .. " from all other categories."

strings["SI_IJA_GPINVENTORY_CATEGORY" .. ITEMFILTERTYPE_MAPS]						= "Use " .. mapsSurveyString .. " Category"
strings["SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP" .. ITEMFILTERTYPE_MAPS]				= "Enabled: adds a dynamic category for " .. mapsSurveyString .. "."
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER" .. ITEMFILTERTYPE_MAPS]				= "Filter " .. mapsSurveyString
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP" .. ITEMFILTERTYPE_MAPS]		= "Enabled: removes " .. mapsSurveyString .. " from all other categories."

strings["SI_IJA_GPINVENTORY_CATEGORY" .. ITEMFILTERTYPE_RECIPE_STYLE_PAGE]				= "Use " .. recipesString .. " Category"
strings["SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP" .. ITEMFILTERTYPE_RECIPE_STYLE_PAGE]		= "Enabled: adds a dynamic category for " .. recipesString .. "."
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER" .. ITEMFILTERTYPE_RECIPE_STYLE_PAGE]			= "Filter " .. recipesString
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP" .. ITEMFILTERTYPE_RECIPE_STYLE_PAGE]	= "Enabled: removes " .. recipesString .. " from all other categories."

strings["SI_IJA_GPINVENTORY_CATEGORY" .. ITEMFILTERTYPE_REPAIR]						= "Use " .. repairKitsString .. " Category"
strings["SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP" .. ITEMFILTERTYPE_REPAIR]				= "Enabled: adds a dynamic category for repair kits."
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER" .. ITEMFILTERTYPE_REPAIR]				= "Filter ".. repairKitsString
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP" .. ITEMFILTERTYPE_REPAIR]		= "Enabled: removes repair kits from all other categories."

strings["SI_IJA_GPINVENTORY_CATEGORY" .. ITEMFILTERTYPE_SIEGE]						= "Use " .. siegeString .. " Category"
strings["SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP" .. ITEMFILTERTYPE_SIEGE]				= "Enabled: adds a dynamic category for AVA items."
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER" .. ITEMFILTERTYPE_SIEGE]				= "Filter " .. siegeString
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP" .. ITEMFILTERTYPE_SIEGE]		= "Enabled: removes AVA items from all other categories."

strings["SI_IJA_GPINVENTORY_CATEGORY" .. ITEMFILTERTYPE_STOLEN]						= "Use " .. stolenString .. " Category"
strings["SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP" .. ITEMFILTERTYPE_STOLEN]				= "Enabled: adds a dynamic category for stolen items."
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER" .. ITEMFILTERTYPE_STOLEN ]				= "Filter " .. stolenString
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP" .. ITEMFILTERTYPE_STOLEN]		= "Enabled: removes stolen items from all other categories."

strings["SI_IJA_GPINVENTORY_CATEGORY" .. ITEMFILTERTYPE_TREASURE]					= "Use " .. treasuresString .. " Category"
strings["SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP" .. ITEMFILTERTYPE_TREASURE]			= "Enabled: adds a dynamic category for \"Sell to merchant\" treasure items."
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER" .. ITEMFILTERTYPE_TREASURE]			= "Filter " .. treasuresString
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP" .. ITEMFILTERTYPE_TREASURE]	= "Enabled: removes treasure items from all other categories."

strings["SI_IJA_GPINVENTORY_CATEGORY" .. ITEMFILTERTYPE_WRIT]						= "Use " .. writsString .. " Category"
strings["SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP" .. ITEMFILTERTYPE_WRIT]				= "Enabled: adds a dynamic category for writs."
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER" .. ITEMFILTERTYPE_WRIT]				= "Filter " .. writsString
strings["SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP" .. ITEMFILTERTYPE_WRIT]		= "Enabled: removes writs from all other categories."

-- used for categoryList item
strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_CONTAINER] = containerString
strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_FOOD_DRINK] = foofDrinkString
strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_POTION] = potionString
strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_RECIPE_STYLE_PAGE] = recipesString
strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_REPAIR] = repairKitsString
strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_SIEGE] = siegeString
strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_STOLEN] = stolenString
strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_TREASURE] = treasuresString
strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_WRIT] = writsString

strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_MAPS] = zo_strformat(SI_UNIT_FRAME_BARVALUE, surveyString, GetString(SI_MAIN_MENU_MAP) .. "s")
--[[
-- used for category header
strings["SI_IJA_GPINVENTORY_HEADER" .. ITEMFILTERTYPE_CONTAINER] = containerString
strings["SI_IJA_GPINVENTORY_HEADER" .. ITEMFILTERTYPE_JUNK] = containerString
strings["SI_IJA_GPINVENTORY_HEADER" .. ITEMFILTERTYPE_FOOD_DRINK] = foofDrinkString
strings["SI_IJA_GPINVENTORY_HEADER" .. ITEMFILTERTYPE_POTION] = potionString
strings["SI_IJA_GPINVENTORY_HEADER" .. ITEMFILTERTYPE_RECIPE_STYLE_PAGE] = recipesString
strings["SI_IJA_GPINVENTORY_HEADER" .. ITEMFILTERTYPE_REPAIR] = repairKitsString
strings["SI_IJA_GPINVENTORY_HEADER" .. ITEMFILTERTYPE_SIEGE] = siegeString
strings["SI_IJA_GPINVENTORY_HEADER" .. ITEMFILTERTYPE_STOLEN] = stolenString
strings["SI_IJA_GPINVENTORY_HEADER" .. ITEMFILTERTYPE_TREASURE] = treasuresString
strings["SI_IJA_GPINVENTORY_HEADER" .. ITEMFILTERTYPE_WRIT] = writsString

strings["SI_IJA_GPINVENTORY_HEADER" .. ITEMFILTERTYPE_MAPS] = zo_strformat(SI_STATS_BAR_VALUE,  GetString(SI_SPECIALIZEDITEMTYPE101) .. 's', GetString(SI_SPECIALIZEDITEMTYPE100) .. 's')
]]

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end
--	/script for i=1, 37 do d(GetString("SI_IJA_GPINVENTORY_CATEGORY_FILTER_TOOLTIP", i)) end


--	/script for i=27, 37 do d(GetString("SI_ITEMFILTERTYPE", i), GetString("SI_IJA_GPINVENTORY_HEADER", i)) end


--	/script d(GetString("SI_IJA_GPINVENTORY_HEADER", ITEMFILTERTYPE_POTION))