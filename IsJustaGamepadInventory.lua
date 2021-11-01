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
	
	self:InitJunkSort()
end

function IJA_GPInventory:OnPlayerActivated()
	self.control:UnregisterForEvent(EVENT_PLAYER_ACTIVATED)

	self:SetupSettings()
	self:AddInventoryActions()
	d( self.displayName .. " version: " .. self.version)
end

---------------------------------------------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------------------------------------------
function IJA_GPInventory_Initialize( ... )
    IJA_GPINVENTORY = IJA_GPInventory:New( ... )
end



--[[

--]]