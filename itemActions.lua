local IJA_GPInventory = IJA_GPINVENTORY

---------------------------------------------------------------------------------------------------------------
-- Add Mark/Unmark as Junk to Inventory Item Action list
---------------------------------------------------------------------------------------------------------------
local menu = LibCustomMenu

local INVENTORY_CATEGORY_LIST = "categoryList"
local INVENTORY_ITEM_LIST = "itemList"
local INVENTORY_CRAFT_BAG_LIST = "craftBagList"

local function canSceneHandleJunk()
	local sceneName = SCENE_MANAGER:GetCurrentScene():GetName()
	if sceneName == 'gamepad_banking' then
		return true
	end
	return SCENE_MANAGER:IsShowing("gamepad_inventory_root") or SCENE_MANAGER:IsSceneOnStack("gamepad_inventory_root")
end

local function MarkAsJunkHelper(bagId, slotIndex, isJunk)
	local lastItem = GAMEPAD_INVENTORY:GetCurrentList():GetNumEntries() == 1 and true or false
	d( 'lastItem',lastItem)
	SetItemIsJunk(bagId, slotIndex, isJunk)
	PlaySound(isJunk and SOUNDS.INVENTORY_ITEM_JUNKED or SOUNDS.INVENTORY_ITEM_UNJUNKED)
	
	d( 'gamepad_inventory_root', SCENE_MANAGER:IsShowing("gamepad_inventory_root"))
	d( 'gamepad_inventory_root', SCENE_MANAGER:IsSceneOnStack("gamepad_inventory_root"))
	
	
	
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
