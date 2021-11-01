local IJA_GPInventory = IJA_GPINVENTORY

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
