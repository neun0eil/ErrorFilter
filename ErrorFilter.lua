--------------------------------------------------------------------------------------------------------
--                                         AceAddon init                                              --
--------------------------------------------------------------------------------------------------------
ErrorFilter = LibStub("AceAddon-3.0"):NewAddon("ErrorFilter", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ErrorFilter")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

--------------------------------------------------------------------------------------------------------
--                                        ErrorFilter variables                                       --
--------------------------------------------------------------------------------------------------------
local profileDB
local DATABASE_DEFAULTS = {
	profile = {
		mode = 1,
		filters = {
			[INTERRUPTED] = false,
			[ERR_ABILITY_COOLDOWN] = true,
			[ERR_ATTACK_CHANNEL] = false,
			[ERR_ATTACK_CHARMED] = false,
			[ERR_ATTACK_CONFUSED] = false,
			[ERR_ATTACK_DEAD] = false,
			[ERR_ATTACK_FLEEING] = false,
			[ERR_ATTACK_MOUNTED] = true,
			[ERR_ATTACK_PACIFIED] = false,
			[ERR_ATTACK_STUNNED] = false,
			[ERR_AUTOFOLLOW_TOO_FAR] = false,
			[ERR_BADATTACKFACING] = false,
			[ERR_BADATTACKPOS] = false,
			[ERR_CLIENT_LOCKED_OUT] = false,
			[ERR_GENERIC_NO_TARGET] = true,
			[ERR_GENERIC_NO_VALID_TARGETS] = true,
			[ERR_GENERIC_STUNNED] = false,
			[ERR_INVALID_ATTACK_TARGET] = true,
			[ERR_ITEM_COOLDOWN] = true,
			[ERR_NOEMOTEWHILERUNNING] = false,
			[ERR_NOT_IN_COMBAT] = false,
			[ERR_NOT_WHILE_DISARMED] = false,
			[ERR_NOT_WHILE_FALLING] = false,
			[ERR_NOT_WHILE_MOUNTED] = false,
			[ERR_NO_ATTACK_TARGET] = true,
			[ERR_OUT_OF_ENERGY] = true,
			[ERR_OUT_OF_FOCUS] = true,
			[ERR_OUT_OF_MANA] = true,
			[ERR_OUT_OF_RAGE] = true,
			[ERR_OUT_OF_RANGE] = true,
			[ERR_OUT_OF_RUNES] = true,
			[ERR_OUT_OF_RUNIC_POWER] = true,
			[ERR_SPELL_COOLDOWN] = true,
			[ERR_SPELL_OUT_OF_RANGE] = false,
			[ERR_TOO_FAR_TO_INTERACT] = false,
			[ERR_USE_BAD_ANGLE] = false,
			[ERR_USE_CANT_IMMUNE] = false,
			[ERR_USE_TOO_FAR] = false,
			[SPELL_FAILED_BAD_IMPLICIT_TARGETS] = true,
			[SPELL_FAILED_BAD_TARGETS] = true,
			[SPELL_FAILED_CASTER_AURASTATE] = true,
			[SPELL_FAILED_NO_COMBO_POINTS] = true,
			[SPELL_FAILED_SPELL_IN_PROGRESS] = true,
			[SPELL_FAILED_TARGET_AURASTATE] = true,
		},
		allows = {
			[INTERRUPTED] = true,
			[ERR_BADATTACKFACING] = true,
			[ERR_BADATTACKPOS] = true,
			[ERR_NOT_IN_COMBAT] = true,
			[ERR_OUT_OF_RANGE] = true,
			[ERR_SPELL_OUT_OF_RANGE] = true,
			[ERR_TOO_FAR_TO_INTERACT] = true,
			[ERR_USE_BAD_ANGLE] = true,
			[ERR_USE_TOO_FAR] = true,
		},
		custom_filters = {},
		custom_allows = {},
	},
}
-- sort by key
local a = {}
local filters_order = {}
for n in pairs(DATABASE_DEFAULTS.profile.filters) do table.insert(a, n) end
table.sort(a)
for i, n in ipairs(a) do filters_order[n] = i end

a = {}
local allows_order = {}
for n in pairs(DATABASE_DEFAULTS.profile.allows) do table.insert(a, n) end
table.sort(a)
for i, n in ipairs(a) do allows_order[n] = i end

local DO_NOTHING = 0
local FILTER_ONLY = 1
local ALLOW_ONLY = 2
local FILTER_ALL = 3
local REMOVE_FRAME = 4

--------------------------------------------------------------------------------------------------------
--                                   ErrorFilter options panel                                        --
--------------------------------------------------------------------------------------------------------
ErrorFilter.options = {
	type = "group",
	name = "ErrorFilter",
	args = {
		general = {
			order = 1,
			type = "group",
			name = L["General Settings"],
			cmdInline = true,
			args = {
				unregister = {
					order = 1,
					type = "select",
					style = "dropdown",
					name = L["Operation mode:"],
					desc = L["Choose how do you want ErrorFilter to work."],
					get = function()
						return profileDB.mode
					end,
					set = function(key, value)
						profileDB.mode = value
						ErrorFilter:UpdateEvents()
					end,
					values = function()
						return {
							[DO_NOTHING] = L["Do nothing"],
							[FILTER_ONLY] = L["Filter only ..."],
							[ALLOW_ONLY] = L["Allow only ..."],
							[FILTER_ALL] = L["Filter all errors"],
							[REMOVE_FRAME] = L["Remove UIErrorFrame"],
						}
					end,
				},
				separator = {
					order = 2,
					type = "description",
					name = "",
				},
				warning1 = {
					order = 3,
					type = "execute",
					name = L["Set filters"],
					desc = L["Open the menu to set custom filters."],
					func = function()
						InterfaceOptionsFrame_OpenToCategory(ErrorFilter.optionsFrames.filters)
					end,
					hidden = function()
						return not (profileDB.mode == FILTER_ONLY)
					end,
				},
				warning2 = {
					order = 3,
					type = "execute",
					name = L["Set filters"],
					desc = L["Open the menu to set custom filters."],
					func = function()
						InterfaceOptionsFrame_OpenToCategory(ErrorFilter.optionsFrames.allows)
					end,
					hidden = function()
						return not (profileDB.mode == ALLOW_ONLY)
					end,
				},
				warning3 = {
					order = 3,
					type = "description",
					name = "|cFFFF0202"..L["Warning! This will prevent all error messages from appearing in the UI Error Frame."].."|r",
					hidden = function()
						return not (profileDB.mode == FILTER_ALL)
					end,
				},
				warning4 = {
					order = 3,
					type = "description",
					name = "|cFFFF0202"..L["Warning! This will prevent any message from appearing in the UI Error Frame, including quest updates text."].."|r",
					hidden = function()
						return not (profileDB.mode == REMOVE_FRAME)
					end,
				},
			},
		},
		filters = {
			order = 1,
			type = "group",
			name = L["Filtered errors"],
			args = {
				separator1 = {
					order = 1,
					type = "header",
					name = "|cFF02FF02"..L["Manage custom filters:"].."|r",
				},
				new = {
					order = 2,
					type = "input",
					width = "full",
					name = L["New"],
					desc = L["Add a new string."],
					get = false,
					set = function(key, value)
						tinsert(profileDB.custom_filters, string.lower(value))
					end,
					disabled = function()
						return not (profileDB.mode == FILTER_ONLY)
					end,
				},
				delete = {
					order = 3,
					type = "select",
					width = "full",
					name = L["Delete"],
					desc = L["Delete a string from the list"],
					get = false,
					set = function(key, value)
						tremove(profileDB.custom_filters, value)
					end,
					values = function()
						return profileDB.custom_filters
					end,
					disabled = function()
						return not ((#profileDB.custom_filters > 0) and (profileDB.mode == FILTER_ONLY))
					end,
				},
				separator2 = {
					order = 9,
					type = "description",
					name = "\n",
				},
				separator3 = {
					order = 10,
					type = "header",
					name = "|cFF02FF02"..L["Choose the errors you do not want to see:"].."|r",
				},
			},
		},
		allows = {
			order = 1,
			type = "group",
			name = L["Allowed errors"],
			args = {
				separator1 = {
					order = 1,
					type = "header",
					name = "|cFF02FF02"..L["Manage custom allows:"].."|r",
				},
				new = {
					order = 2,
					type = "input",
					width = "full",
					name = L["New"],
					desc = L["Add a new string."],
					get = false,
					set = function(key, value)
						tinsert(profileDB.custom_allows, string.lower(value))
					end,
					disabled = function()
						return not (profileDB.mode == ALLOW_ONLY)
					end,
				},
				delete = {
					order = 3,
					type = "select",
					width = "full",
					name = L["Delete"],
					desc = L["Delete a string from the list"],
					get = false,
					set = function(key, value)
						tremove(profileDB.custom_allows, value)
					end,
					values = function()
						return profileDB.custom_allows
					end,
					disabled = function()
						return not ((#profileDB.custom_allows > 0) and (profileDB.mode == ALLOW_ONLY))
					end,
				},
				separator2 = {
					order = 9,
					type = "description",
					name = "\n",
				},
				separator3 = {
					order = 10,
					type = "header",
					name = "|cFF02FF02"..L["Choose the errors you want to see:"].."|r",
				},
			},
		},
	},
}

-- generate filters submenu
for k, v in pairs(DATABASE_DEFAULTS.profile.filters) do
	ErrorFilter.options.args.filters.args[string.format("error"..filters_order[k])] = {
		order = 10 + filters_order[k],
		width = "full",
		type = "toggle",
		name = k,
		desc = L["Toggle to filter this error."],
		get = function()
			return profileDB.filters[k]
		end,
		set = function(key, value)
			profileDB.filters[k] = value
		end,
		disabled = function()
			return not (profileDB.mode == FILTER_ONLY)
		end,
	}
end

-- generate allows submenu
for k, v in pairs(DATABASE_DEFAULTS.profile.allows) do
	ErrorFilter.options.args.allows.args[string.format("allow"..allows_order[k])] = {
		order = 10 + allows_order[k],
		width = "full",
		type = "toggle",
		name = k,
		desc = L["Toggle to allow this error."],
		get = function()
			return profileDB.allows[k]
		end,
		set = function(key, value)
			profileDB.allows[k] = value
		end,
		disabled = function()
			return not (profileDB.mode == ALLOW_ONLY)
		end,
	}
end

function ErrorFilter:SetupOptions()
	ErrorFilter.options.args.profile = AceDBOptions:GetOptionsTable(self.db)
	ErrorFilter.options.args.profile.order = -2
	
	AceConfig:RegisterOptionsTable("ErrorFilter", ErrorFilter.options, nil)
	
	self.optionsFrames = {}
	self.optionsFrames.general = AceConfigDialog:AddToBlizOptions("ErrorFilter", nil, nil, "general")
	self.optionsFrames.filters = AceConfigDialog:AddToBlizOptions("ErrorFilter", L["Filter only ..."], "ErrorFilter", "filters")
	self.optionsFrames.allows = AceConfigDialog:AddToBlizOptions("ErrorFilter", L["Allow only ..."], "ErrorFilter", "allows")
	self.optionsFrames.profile = AceConfigDialog:AddToBlizOptions("ErrorFilter", L["Profiles"], "ErrorFilter", "profile")
end

--------------------------------------------------------------------------------------------------------
--                                            ErrorFilter Init                                        --
--------------------------------------------------------------------------------------------------------
function ErrorFilter:OnInitialize()
	self.db = AceDB:New("ErrorFilterDB", DATABASE_DEFAULTS, true)
	if not self.db then
		Print("Error: Database not loaded correctly. Please exit out of WoW and delete ErrorFilter.lua found in: \\World of Warcraft\\WTF\\Account\\<Account Name>>\\SavedVariables\\")
	end
	
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	
	profileDB = self.db.profile
	self:SetupOptions()
	
	-- Create slash commands
	SLASH_ErrorFilter1 = "/erf"
	SLASH_ErrorFilter2 = "/errorfilter"
	SlashCmdList["ErrorFilter"] = ErrorFilter.ShowConfig
	
	-- Register events
	self:UpdateEvents()
end

--------------------------------------------------------------------------------------------------------
--                                       ErrorFilter event handlers                                   --
--------------------------------------------------------------------------------------------------------
function ErrorFilter:OnErrorMessage(self, event, msg)
	if profileDB.mode == FILTER_ONLY then
		-- check default filters
		if profileDB.filters[msg] then
			return
		end
		-- check custom filters
		for k, v in next, profileDB.custom_filters do
			if string.find(string.lower(msg), v) then
				return
			end
		end
		UIErrorsFrame:AddMessage(msg, 1.0, 0.1, 0.1, 1.0);
	elseif profileDB.mode == ALLOW_ONLY then
		-- check default allows
		if profileDB.allows[msg] then
			UIErrorsFrame:AddMessage(msg, 1.0, 0.1, 0.1, 1.0);
			return
		end
		-- check custom allows
		for k, v in next, profileDB.custom_allows do
			if string.find(string.lower(msg), v) then
				UIErrorsFrame:AddMessage(msg, 1.0, 0.1, 0.1, 1.0);
				return
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------
--                                        ErrorFilter functions                                       --
--------------------------------------------------------------------------------------------------------
-- Called after profile changed
function ErrorFilter:OnProfileChanged(event, database, newProfileKey)
	profileDB = database.profile
end

-- Open config window
function ErrorFilter:ShowConfig()
	InterfaceOptionsFrame_OpenToCategory(ErrorFilter.optionsFrames.profile)
	InterfaceOptionsFrame_OpenToCategory(ErrorFilter.optionsFrames.general)
end

-- Check options and set events
function ErrorFilter:UpdateEvents()
	if profileDB.mode == REMOVE_FRAME then
		UIErrorsFrame:Hide()
		self:UnregisterEvent("UI_ERROR_MESSAGE")
	else
		UIErrorsFrame:Show()
		if profileDB.mode == FILTER_ALL then
			UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
			self:UnregisterEvent("UI_ERROR_MESSAGE")
		elseif profileDB.mode == FILTER_ONLY or profileDB.mode == ALLOW_ONLY then
			UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
			self:RegisterEvent("UI_ERROR_MESSAGE","OnErrorMessage", self)
		elseif profileDB.mode == DO_NOTHING then
			UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
			self:UnregisterEvent("UI_ERROR_MESSAGE")
		end
	end
end
