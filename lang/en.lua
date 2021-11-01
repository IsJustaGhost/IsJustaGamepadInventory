------------------------------------------------
-- English localization for IsJustaGamepadInventory
------------------------------------------------

local strings = {
	SI_IJA_GPINVENTORY_SURVEYS_MAPS					= zo_strformat(SI_ADDON_MANAGER_STATE_STRING, GetString(SI_SPECIALIZEDITEMTYPE100), GetString(SI_SPECIALIZEDITEMTYPE101)),

	SI_IJA_GPINVENTORY_CATEGORIES					= "Category and filter options",

	SI_IJA_GPINVENTORY_CATEGORY_MAPS				= "Use Map Category",
	SI_IJA_GPINVENTORY_CATEGORY_TOOLTIP				= "Enabled: adds a dynamic category for Treasure Maps and Survey Reports.",
	SI_IJA_GPINVENTORY_FILTER_MAPS					= "Filter Maps",
	SI_IJA_GPINVENTORY_FILTER_MAPS_TOOLTIP			= "Enabled: removes Treasure Maps and Survey Reports from the Slotable Category.",

	SI_IJA_GPINVENTORY_CATEGORY_JUNK				= "Use Junk Category",
	SI_IJA_GPINVENTORY_CATEGORY_JUNK_TOOLTIP		= "Enabled: adds a dynamic category for items marked as junk.",
	SI_IJA_GPINVENTORY_FILTER_JUNK					= "Filter Junk",
	SI_IJA_GPINVENTORY_FILTER_JUNK_TOOLTIP			= "Enabled: removes items marked as junk from all other categories.",

	SI_IJA_GPINVENTORY_CATEGORY_STOLEN				= "Use Stolen Category",
	SI_IJA_GPINVENTORY_CATEGORY_STOLEN_TOOLTIP		= "Enabled: adds a dynamic category for Stolen items.",
	SI_IJA_GPINVENTORY_FILTER_STOLEN				= "Filter Stolen",
	SI_IJA_GPINVENTORY_FILTER_STOLEN_TOOLTIP		= "Enabled: removes Stolen items from all other categories.",

	SI_IJA_GPINVENTORY_SORTBANK_WITHDRAW			= "Bank Withdraw",
	SI_IJA_GPINVENTORY_SORTBANK_WITHDRAW_TOOLTIP	= "Enabled: Sorts junk in bank withdraw list to bottom.",

	SI_IJA_GPINVENTORY_SORTBANK_DEPOSIT				= "Bank Deposit",
	SI_IJA_GPINVENTORY_SORTBANK_DEPOSIT_TOOLTIP		= "Enabled: Sorts junk in bank and guild bank deposit lists to bottom."
}


ITEMFILTERTYPE_STOLEN = ITEMFILTERTYPE_ITERATION_END + 1
ITEMFILTERTYPE_MAPS = ITEMFILTERTYPE_STOLEN + 1
strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_STOLEN] = "Stolen"
strings["SI_ITEMFILTERTYPE" .. ITEMFILTERTYPE_MAPS] = "Surveys/Maps"

for stringId, stringValue in pairs(strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end