-- Compat-335.lua
-- Comprehensive API compatibility shim for WoW 3.3.5a (WotLK) private servers.

local _, _, _, tocversion = GetBuildInfo()
local tocInt = tonumber(tocversion) or 0
local isWOTLK = (tocInt >= 30000 and tocInt < 40000) or (tocInt == 30300)

-- Set global for other files
_G.XP_IsWOTLK = isWOTLK

if not isWOTLK then return end

-- Global Enum tables for 3.3.5a are now handled in Compat-Lua.lua

-----------------------------------------------------------------------
-- Global unpack safety wrapper for 3.3.5a
-----------------------------------------------------------------------
local _G = _G
local original_unpack = _G.unpack or unpack
_G.unpack = function(t, ...)
	if t == nil then return end
	return original_unpack(t, ...)
end

-- Missing API Polyfills are now handled in Compat-Lua.lua
if not _G.table.wipe and _G.wipe then
	_G.table.wipe = _G.wipe
end

if not _G.GetCurrentRegion then
	_G.GetCurrentRegion = function() return 1 end
end

if not _G.GetCurrentRegionName then
	_G.GetCurrentRegionName = function() return "US" end
end

-- Stub for TextureLoadingGroupMixin if missing (required by TaintLess on legacy clients)
if not _G.TextureLoadingGroupMixin then
	_G.TextureLoadingGroupMixin = {
		AddTexture = function() end,
		RemoveTexture = function() end,
	}
end

-----------------------------------------------------------------------
-- BackdropTemplate shim for WotLK
-- AceGUI-3.0 and other libs use "BackdropTemplate" which doesn't exist in WotLK
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- BackdropTemplate shim for WotLK
-- AceGUI-3.0 and other libs use "BackdropTemplate" which doesn't exist in WotLK
-----------------------------------------------------------------------
if not BackdropTemplate then
	_G.BackdropTemplate = {}
end

-- Redefine CreateFrame to catch 'BackdropTemplate' and redirect it to our virtual shim.
-- We only do this on WotLK (isWOTLK guard at top of file) so Retail remains untouched.
local originalCreateFrame = _G.CreateFrame
_G.CreateFrame = function(frameType, name, parent, template)
	if template and type(template) == "string" and template:find("BackdropTemplate") then
		template = template:gsub("BackdropTemplate", "XLIB_BackdropTemplate")
		-- Fail-safe: collapse double accidental prefixing
		template = template:gsub("XLIB_XLIB_BackdropTemplate", "XLIB_BackdropTemplate")
	end
	return originalCreateFrame(frameType, name, parent, template)
end

-- SetShown polyfill for 3.3.5a (WotLK) frames
-- This is a retail-port convenience method.
local function PatchSetShown(obj)
	local mt = getmetatable(obj).__index
	if not mt.SetShown then
		mt.SetShown = function(self, show)
			if show then self:Show() else self:Hide() end
		end
	end
end

local f = originalCreateFrame("Frame")
PatchSetShown(f)
PatchSetShown(f:CreateTexture())
PatchSetShown(f:CreateFontString())
f:Hide()


-- This file MUST be loaded FIRST, before any other addon code.
-- It creates all missing C_* namespaces, Enum tables, and WOW_PROJECT constants
-- that the Retail codebase depends on.

local COMPAT_VERSION = "1.0"

-- CRITICAL: Create ALL missing namespaces BEFORE any library code runs
-- These must be global (_G prefix not needed since we're in global scope)

-- C_AddOns shim
_G.C_AddOns = _G.C_AddOns or {}
C_AddOns.GetAddOnMetadata = C_AddOns.GetAddOnMetadata or GetAddOnMetadata
C_AddOns.GetAddOnInfo = C_AddOns.GetAddOnInfo or GetAddOnInfo
C_AddOns.GetNumAddOns = C_AddOns.GetNumAddOns or GetNumAddOns
C_AddOns.IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded
C_AddOns.EnableAddOn = C_AddOns.EnableAddOn or EnableAddOn
C_AddOns.DisableAddOn = C_AddOns.DisableAddOn or DisableAddOn

-- C_UnitAuras shim (Retail returns a table, WotLK returns raw values)
_G.C_UnitAuras = _G.C_UnitAuras or {}
C_UnitAuras.GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex or function(unit, index, filter)
	local isBuff = not filter or not filter:find("HARMFUL")
	local fn = isBuff and UnitBuff or UnitDebuff
	local name, rank, icon, count, debuffType, duration, expirationTime,
		unitCaster, isStealable, shouldConsolidate, spellID = fn(unit, index)
	if not name then return nil end
	return {
		name = name,
		icon = icon,
		applications = count or 0,
		dispelName = debuffType,
		duration = duration or 0,
		expirationTime = expirationTime or 0,
		sourceUnit = unitCaster,
		spellId = spellID or 0,
		isStealable = isStealable,
		auraInstanceID = index,
		isHelpful = isBuff,
		isHarmful = not isBuff,
	}
end
C_UnitAuras.GetBuffDataByIndex = C_UnitAuras.GetBuffDataByIndex or function(unit, index, filter)
	return C_UnitAuras.GetAuraDataByIndex(unit, index, filter or "HELPFUL")
end
C_UnitAuras.GetDebuffDataByIndex = C_UnitAuras.GetDebuffDataByIndex or function(unit, index, filter)
	return C_UnitAuras.GetAuraDataByIndex(unit, index, filter or "HARMFUL")
end

-- C_Map namespace (Heavy shimming for 3.3.5a)
_G.C_Map = _G.C_Map or {}
C_Map._mapInfoCache = C_Map._mapInfoCache or {}
C_Map._mapChildrenCache = C_Map._mapChildrenCache or {}
C_Map._mapGroupCache = C_Map._mapGroupCache or {}
C_Map._areaToMapID = C_Map._areaToMapID or {}
C_Map._mapToAreaID = C_Map._mapToAreaID or {}

C_Map.GetBestMapForUnit = C_Map.GetBestMapForUnit or function(unitToken)
	if unitToken == "player" then
		SetMapToCurrentZone()
		local areaID = GetCurrentMapAreaID()
		if areaID and C_Map._areaToMapID[areaID] then
			return C_Map._areaToMapID[areaID]
		end
		return areaID or 0
	end
	return 0
end

C_Map.GetMapInfo = C_Map.GetMapInfo or function(mapID)
	if not mapID then return nil end
	local cached = C_Map._mapInfoCache[mapID]
	if cached then return cached end
	return {
		mapID = mapID,
		name = GetMapInfo() or "Unknown",
		mapType = Enum.UIMapType and Enum.UIMapType.Zone or 3,
		parentMapID = 0,
	}
end

C_Map.GetPlayerMapPosition = C_Map.GetPlayerMapPosition or function(mapID, unitToken)
	if unitToken == "player" then
		local x, y = GetPlayerMapPosition("player")
		if x and y then
			return { x = x, y = y }
		end
	end
	return nil
end

C_Map.GetMapChildrenInfo = C_Map.GetMapChildrenInfo or function(mapID, mapType, allDescendants)
	local children = C_Map._mapChildrenCache[mapID]
	if not children then return {} end
	if not mapType then return children end
	local filtered = {}
	for _, child in ipairs(children) do
		if child.mapType == mapType then
			table.insert(filtered, child)
		end
	end
	return filtered
end

C_Map.GetWorldPosFromMapPos = C_Map.GetWorldPosFromMapPos or function(mapID, mapPos)
	return 0, CreateVector2D and CreateVector2D(0, 0) or { x = 0, y = 0 }
end

C_Map.GetMapGroupID = C_Map.GetMapGroupID or function(mapID)
	return C_Map._mapGroupCache[mapID] or 0
end

C_Map.GetMapGroupMembersInfo = C_Map.GetMapGroupMembersInfo or function(groupID)
	return {}
end

C_Map.GetMapInfoAtPosition = C_Map.GetMapInfoAtPosition or function(mapID, x, y)
	return nil
end

C_Map.GetMapLinksForMap = C_Map.GetMapLinksForMap or function(mapID)
	return {}
end

C_Map.GetFallbackWorldMapID = C_Map.GetFallbackWorldMapID or function()
	return 947 -- Azeroth
end

C_Map.GetMapArtID = C_Map.GetMapArtID or function(mapID)
	return 0
end

C_Map.GetMapLevels = C_Map.GetMapLevels or function(mapID)
	return 0, 0
end

C_Map.GetAreaInfo = C_Map.GetAreaInfo or function(areaID)
	if GetAreaInfo then return GetAreaInfo(areaID) end
	return nil
end

-- Enum (Retail-only global)
_G.Enum = _G.Enum or {}
Enum.UIWidgetScaleMode = Enum.UIWidgetScaleMode or { Automatic = 0, Manual = 1 }
Enum.CommonQuality = Enum.CommonQuality or { Common = 0, Uncommon = 1, Rare = 2, Epic = 3, Legendary = 4 }
Enum.ItemQuality = Enum.ItemQuality or { Poor = 0, Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Artifact = 6, Heirloom = 7 }
Enum.UIMapType = Enum.UIMapType or { Cosmic = 0, World = 1, Continent = 2, Zone = 3, Dungeon = 4, Micro = 5, Orphan = 6 }
Enum.QuestFrequency = Enum.QuestFrequency or { Default = 0, Daily = 1, Weekly = 2 }
Enum.QuestTagType = Enum.QuestTagType or { None = 0, Elite = 1, Primary = 2, Secondary = 3, PvP = 4, Dungeon = 5, Scenario = 6, Raid = 7, Heroic = 8, Ridable = 9 }
Enum.QuestWatchType = Enum.QuestWatchType or { Automatic = 0, Manual = 1 }
-- Enum.GamePadKeyCode
if not Enum.GamePadKeyCode then
	Enum.GamePadKeyCode = {
		Invalid = 0,
		ButtonA = 1,
		ButtonB = 2,
		ButtonX = 3,
		ButtonY = 4,
	}
end
-- Enum.UIWidgetIndentType
if not Enum.UIWidgetIndentType then
	Enum.UIWidgetIndentType = { None = 0, Inclusive = 1, Hidden = 2 }
end
-- Enum.UIWidgetWidthBehavior
if not Enum.UIWidgetWidthBehavior then
	Enum.UIWidgetWidthBehavior = { Auto = 0, Fill = 1, Absolute = 2 }
end
-- Enum.UIWidgetAlignment
if not Enum.UIWidgetAlignment then
	Enum.UIWidgetAlignment = { Left = 0, Center = 1, Right = 2 }
end
-- Enum.UIWidgetIconDirection
if not Enum.UIWidgetIconDirection then
	Enum.UIWidgetIconDirection = { Left = 0, Right = 1 }
end
-- Enum.UIWidgetTextureKit
if not Enum.UIWidgetTextureKit then
	Enum.UIWidgetTextureKit = { None = 0 }
end
-- Enum.UIWidgetVisualLayout
if not Enum.UIWidgetVisualLayout then
	Enum.UIWidgetVisualLayout = { Normal = 0, Wide = 1, DoubleWide = 2 }
end

-- C_Item (Retail API for item interactions)
C_Item = C_Item or {}
C_Item.IsItemDataCached = C_Item.IsItemDataCached or function() return true end
C_Item.GetItemInfo = C_Item.GetItemInfo or function(item)
	if type(item) == "number" then
		return GetItemInfo(item)
	end
	return nil, nil, nil, nil, nil, nil, nil, nil, nil
end
C_Item.GetItemIcon = C_Item.GetItemIcon or function(itemId)
	local link = GetItemIcon(itemId)
	return link
end
C_Item.GetItemQualityColor = C_Item.GetItemQualityColor or function(quality)
	local r, g, b = GetItemQualityColor(quality or 0)
	return r, g, b
end
C_Item.GetItemCount = C_Item.GetItemCount or function(itemId)
	return GetItemCount(itemId, false, false)
end
C_Item.PlayerCanInteractWithItem = C_Item.PlayerCanInteractWithItem or function() return true end
C_Item.PlayerHasEquippedItem = C_Item.PlayerHasEquippedItem or function(itemId)
	for i = 1, 19 do
		local equipped = GetInventoryItemID("player", i)
		if equipped == itemId then return true end
	end
	return false
end

-- C_Spell (Retail API for spell operations)
_G.C_Spell = _G.C_Spell or {}
C_Spell.GetSpellInfo = C_Spell.GetSpellInfo or function(spellId)
	if not spellId then return nil end
	local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(spellId)
	if not name then return nil end
	return { name = name, nameID = name, iconID = icon, castTime = castTime, minRange = minRange, maxRange = maxRange }
end
C_Spell.GetSpellTexture = C_Spell.GetSpellTexture or function(spellId)
	local _, _, icon = GetSpellInfo(spellId)
	return icon
end
C_Spell.IsSpellKnown = C_Spell.IsSpellKnown or function(spellId)
	return IsSpellKnown(spellId)
end
C_Spell.IsPlayerSpell = C_Spell.IsPlayerSpell or function(spellId)
	return IsPlayerSpell(spellId)
end

-- C_Housing (Retail-only for garrisons/housing)
C_Housing = C_Housing or {}
C_Housing.GetCurrentSubregionID = C_Housing.GetCurrentSubregionID or function() return 0 end
C_Housing.IsPlayerInHouse = C_Housing.IsPlayerInHouse or function() return false end
C_Housing.GetAvailableHouse = C_Housing.GetAvailableHouse or function() return 0 end
C_Housing.SetSelectedHouse = C_Housing.SetSelectedHouse or function() end

-- C_ChatInfo (Retail chat channel API)
C_ChatInfo = _G.C_ChatInfo or {}
C_ChatInfo.GetChannelInfo = C_ChatInfo.GetChannelInfo or function() return {} end
C_ChatInfo.GetChannelRosterInfo = C_ChatInfo.GetChannelRosterInfo or function() return nil end
C_ChatInfo.SetChannelOwner = C_ChatInfo.SetChannelOwner or function() end
C_ChatInfo.IsChannelPassword = C_ChatInfo.IsChannelPassword or function() return false end
C_ChatInfo.RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix or _G.RegisterAddonMessagePrefix or function() return true end
C_ChatInfo.SendAddonMessage = C_ChatInfo.SendAddonMessage or _G.SendAddonMessage or function() end

-- C_Spell logic consolidated above

-- C_Minimicons
C_Minimicons = C_Minimicons or {}
C_Minimicons.GetTextureWidth = C_Minimicons.GetTextureWidth or function() return 0 end
C_Minimicons.GetTextureHeight = C_Minimicons.GetTextureHeight or function() return 0 end

-- C_Club
C_Club = C_Club or {}
C_Club.GetClubIds = C_Club.GetClubIds or function() return {} end
C_Club.GetClubInfo = C_Club.GetClubInfo or function() return nil end

-- C_QuestLog namespace (Robust shimming for 3.3.5a)
_G.C_QuestLog = _G.C_QuestLog or {}

C_QuestLog.GetNumQuestLogEntries = C_QuestLog.GetNumQuestLogEntries or function()
	return GetNumQuestLogEntries()
end

C_QuestLog.GetInfo = C_QuestLog.GetInfo or function(index)
	local title, level, questTag, suggestedGroup, isHeader, isCollapsed,
		isComplete, isDaily, questID = GetQuestLogTitle(index)
	if not title then return nil end
	local frequency = 0
	if isDaily then
		frequency = Enum.QuestFrequency.Daily
	end
	return {
		title = title,
		level = level,
		questID = questID or 0,
		isHeader = isHeader,
		isCollapsed = isCollapsed,
		frequency = frequency,
		isBounty = false,
		suggestedGroup = suggestedGroup,
		questTag = questTag,
		isComplete = isComplete,
	}
end

C_QuestLog.IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted or function(questID)
	if IsQuestFlaggedCompleted then
		return IsQuestFlaggedCompleted(questID)
	end
	return false
end

C_QuestLog.IsQuestFlaggedCompletedOnAccount = C_QuestLog.IsQuestFlaggedCompletedOnAccount or function(questID)
	return C_QuestLog.IsQuestFlaggedCompleted(questID)
end

C_QuestLog.IsComplete = C_QuestLog.IsComplete or function(questID)
	local numEntries = GetNumQuestLogEntries()
	for i = 1, numEntries do
		local title, level, questTag, suggestedGroup, isHeader, isCollapsed,
			isComplete, isDaily, qid = GetQuestLogTitle(i)
		if qid == questID then
			return isComplete and isComplete > 0
		end
	end
	return false
end

C_QuestLog.IsFailed = C_QuestLog.IsFailed or function(questID)
	local numEntries = GetNumQuestLogEntries()
	for i = 1, numEntries do
		local title, level, questTag, suggestedGroup, isHeader, isCollapsed,
			isComplete, isDaily, qid = GetQuestLogTitle(i)
		if qid == questID then
			return isComplete and isComplete < 0
		end
	end
	return false
end

C_QuestLog.IsOnQuest = C_QuestLog.IsOnQuest or function(questID)
	local numEntries = GetNumQuestLogEntries()
	for i = 1, numEntries do
		local title, level, questTag, suggestedGroup, isHeader, isCollapsed,
			isComplete, isDaily, qid = GetQuestLogTitle(i)
		if qid == questID and not isHeader then
			return true
		end
	end
	return false
end

C_QuestLog.GetSelectedQuest = C_QuestLog.GetSelectedQuest or function()
	return GetQuestLogSelection()
end

C_QuestLog.SetSelectedQuest = C_QuestLog.SetSelectedQuest or function(questID)
	local numEntries = GetNumQuestLogEntries()
	for i = 1, numEntries do
		local title, level, questTag, suggestedGroup, isHeader, isCollapsed,
			isComplete, isDaily, qid = GetQuestLogTitle(i)
		if qid == questID then
			SelectQuestLogEntry(i)
			return
		end
	end
end

C_QuestLog.SetAbandonQuest = C_QuestLog.SetAbandonQuest or function()
	SetAbandonQuest()
end

C_QuestLog.AbandonQuest = C_QuestLog.AbandonQuest or function()
	AbandonQuest()
end

C_QuestLog.GetTitleForLogIndex = C_QuestLog.GetTitleForLogIndex or function(index)
	local title = GetQuestLogTitle(index)
	return title
end

C_QuestLog.GetTitleForQuestID = C_QuestLog.GetTitleForQuestID or function(questID)
	local numEntries = GetNumQuestLogEntries()
	for i = 1, numEntries do
		local title, level, questTag, suggestedGroup, isHeader, isCollapsed,
			isComplete, isDaily, qid = GetQuestLogTitle(i)
		if qid == questID and not isHeader then
			return title
		end
	end
	return nil
end

C_QuestLog.GetQuestInfo = C_QuestLog.GetQuestInfo or function(questID)
	return C_QuestLog.GetTitleForQuestID(questID)
end

C_QuestLog.GetNumWorldQuestWatches = C_QuestLog.GetNumWorldQuestWatches or function()
	return 0
end

C_QuestLog.GetQuestIDForWorldQuestWatchIndex = C_QuestLog.GetQuestIDForWorldQuestWatchIndex or function()
	return nil
end

C_QuestLog.GetQuestWatchType = C_QuestLog.GetQuestWatchType or function(questID)
	if IsQuestWatched then
		local numEntries = GetNumQuestLogEntries()
		for i = 1, numEntries do
			local title, level, questTag, suggestedGroup, isHeader, isCollapsed,
				isComplete, isDaily, qid = GetQuestLogTitle(i)
			if qid == questID and not isHeader then
				if IsQuestWatched(i) then
					return Enum.QuestWatchType.Manual
				end
				return nil
			end
		end
	end
	return nil
end

C_QuestLog.AddQuestWatch = C_QuestLog.AddQuestWatch or function(questID, watchType)
	if AddQuestWatch then
		local numEntries = GetNumQuestLogEntries()
		for i = 1, numEntries do
			local title, level, questTag, suggestedGroup, isHeader, isCollapsed,
				isComplete, isDaily, qid = GetQuestLogTitle(i)
			if qid == questID and not isHeader then
				AddQuestWatch(i)
				return
			end
		end
	end
end

C_QuestLog.RemoveQuestWatch = C_QuestLog.RemoveQuestWatch or function(questID)
	if RemoveQuestWatch then
		local numEntries = GetNumQuestLogEntries()
		for i = 1, numEntries do
			local title, level, questTag, suggestedGroup, isHeader, isCollapsed,
				isComplete, isDaily, qid = GetQuestLogTitle(i)
			if qid == questID and not isHeader then
				RemoveQuestWatch(i)
				return
			end
		end
	end
end

C_QuestLog.GetNumQuestWatches = C_QuestLog.GetNumQuestWatches or function()
	if GetNumQuestWatches then
		return GetNumQuestWatches()
	end
	return 0
end

C_QuestLog.GetActiveThreatMaps = C_QuestLog.GetActiveThreatMaps or function()
	return nil
end

C_QuestLog.RequestLoadQuestByID = C_QuestLog.RequestLoadQuestByID or function(questID)
	-- no-op in 3.3.5a
end

-----------------------------------------------------------------------
-- Vector2D polyfill for 3.3.5a
-----------------------------------------------------------------------
if not CreateVector2D then
	local Vector2DMixin = {
		GetXY = function(self) return self.x, self.y end,
		SetXY = function(self, x, y) self.x = x; self.y = y end,
		Clone = function(self) return CreateVector2D(self.x, self.y) end,
	}
	CreateVector2D = function(x, y)
		local vec = { x = x or 0, y = y or 0 }
		for k, v in pairs(Vector2DMixin) do vec[k] = v end
		return vec
	end
end

-- C_Container - used by modern inventory libs
_G.C_Container = _G.C_Container or {}
C_Container.GetContainerNumSlots = C_Container.GetContainerNumSlots or GetContainerNumSlots
C_Container.GetContainerItemInfo = C_Container.GetContainerItemInfo or function(bagID, slot)
	local texture, count, locked, quality, readable, lootable, link, isFiltered, hasNoValue, itemID, isBound = GetContainerItemInfo(bagID, slot)
	if not texture then return nil end
	return {
		iconFileID = texture,
		stackCount = count,
		isLocked = locked,
		quality = quality,
		isReadable = readable,
		hasLoot = lootable,
		hyperlink = link,
		isFiltered = isFiltered,
		hasNoValue = hasNoValue,
		itemID = itemID,
		isBound = isBound,
	}
end
if GetContainerItemLink then
    C_Container.GetContainerItemLink = C_Container.GetContainerItemLink or GetContainerItemLink
end

-- C_Map Namespace Stabilization (Consolidated)

-- IsPlayerSpell Shim for 3.3.5a
if not _G.IsPlayerSpell then
	_G.IsPlayerSpell = function(spellID)
		if not spellID then return false end
		return GetSpellInfo(spellID) ~= nil
	end
end

-- WorldMapFrame / UIParent AddDataProvider shim for HereBeDragons
-- Removed: Modifying secure global frames (UIParent, WorldMapFrame, GameTooltip) 
-- from insecure addon code causes massive taint and breaks standard Blizz keybinds.


-----------------------------------------------------------------------
-- C_Timer shim
-----------------------------------------------------------------------
if not C_Timer then
	C_Timer = {}
	local timerFrame = CreateFrame("Frame")
	local timers = {}
	timerFrame:SetScript("OnUpdate", function(self, elapsed)
		for i = #timers, 1, -1 do
			local t = timers[i]
			t.timeLeft = t.timeLeft - elapsed
			if t.timeLeft <= 0 then
				local callback = t.callback
				table.remove(timers, i)
				if type(callback) == "function" then
					local ok, err = pcall(callback)
					if not ok and DEFAULT_CHAT_FRAME then
						DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Compat-335 C_Timer error:|r " .. tostring(err))
					end
				end
			end
		end
	end)
	C_Timer.After = function(duration, callback)
		table.insert(timers, { timeLeft = duration, callback = callback })
	end
end
-- regardless of which private server expansion is running.
-----------------------------------------------------------------------
if not WOW_PROJECT_MAINLINE then WOW_PROJECT_MAINLINE = 1 end
if not WOW_PROJECT_CLASSIC then WOW_PROJECT_CLASSIC = 2 end
if not WOW_PROJECT_BURNING_CRUSADE_CLASSIC then WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5 end
if not WOW_PROJECT_WRATH_CLASSIC then WOW_PROJECT_WRATH_CLASSIC = 11 end
if not WOW_PROJECT_CATACLYSM_CLASSIC then WOW_PROJECT_CATACLYSM_CLASSIC = 14 end
if not WOW_PROJECT_MISTS_CLASSIC then WOW_PROJECT_MISTS_CLASSIC = 19 end

if not WOW_PROJECT_ID then
	local tocVersion = select(4, GetBuildInfo()) or 0 -- returns interface number e.g. 30300
	if tocVersion >= 110000 then
		WOW_PROJECT_ID = WOW_PROJECT_MAINLINE     -- TWW / Retail
	elseif tocVersion >= 100000 then
		WOW_PROJECT_ID = WOW_PROJECT_MAINLINE      -- Dragonflight
	elseif tocVersion >= 90000 then
		WOW_PROJECT_ID = WOW_PROJECT_MAINLINE      -- Shadowlands
	elseif tocVersion >= 80000 then
		WOW_PROJECT_ID = WOW_PROJECT_MAINLINE      -- BfA
	elseif tocVersion >= 70000 then
		WOW_PROJECT_ID = WOW_PROJECT_MAINLINE      -- Legion
	elseif tocVersion >= 60000 then
		WOW_PROJECT_ID = WOW_PROJECT_MAINLINE      -- WoD
	elseif tocVersion >= 50000 then
		WOW_PROJECT_ID = WOW_PROJECT_MISTS_CLASSIC -- MoP
	elseif tocVersion >= 40000 then
		WOW_PROJECT_ID = WOW_PROJECT_CATACLYSM_CLASSIC
	elseif tocVersion >= 30000 then
		WOW_PROJECT_ID = WOW_PROJECT_WRATH_CLASSIC
	elseif tocVersion >= 20000 then
		WOW_PROJECT_ID = WOW_PROJECT_BURNING_CRUSADE_CLASSIC
	elseif tocVersion >= 10000 then
		WOW_PROJECT_ID = WOW_PROJECT_CLASSIC
	else
		WOW_PROJECT_ID = WOW_PROJECT_WRATH_CLASSIC -- safe fallback
	end
end

-- Enum logic consolidated above

if not Enum.UIMapSystem then
	Enum.UIMapSystem = {
		Bows = 2,
		Guns = 3,
		Mace1H = 4,
		Mace2H = 5,
		Polearm = 6,
		Sword1H = 7,
		Sword2H = 8,
		Warglaive = 9,
		Staff = 10,
		Bearclaw = 11,
		Catclaw = 12,
		Unarmed = 13,
		Generic = 14,
		Dagger = 15,
		Thrown = 16,
		Obsolete3 = 17,
		Crossbow = 18,
		Wand = 19,
		Fishingpole = 20,
	}
end

if not Enum.ItemMiscellaneousSubclass then
	Enum.ItemMiscellaneousSubclass = {
		Junk = 0,
		Reagent = 1,
		CompanionPet = 2,
		Holiday = 3,
		Other = 4,
		Mount = 5,
	}
end

if not Enum.ItemRecipeSubclass then
	Enum.ItemRecipeSubclass = {
		Book = 0,
		Leatherworking = 1,
		Tailoring = 2,
		Engineering = 3,
		Blacksmithing = 4,
		Cooking = 5,
		Alchemy = 6,
		FirstAid = 7,
		Enchanting = 8,
		Fishing = 9,
		Jewelcrafting = 10,
		Inscription = 11,
	}
end

-----------------------------------------------------------------------
-- Constants shims
-----------------------------------------------------------------------
if not Constants then Constants = {} end
if not Constants.QuestWatchConsts then
	Constants.QuestWatchConsts = {
		MAX_QUEST_WATCHES = 25,
	}
end
if not Constants.TimerunningConsts then
	Constants.TimerunningConsts = {
		TIMERUNNING_SEASON_PANDARIA = 1,
		TIMERUNNING_SEASON_LEGION = 2,
	}
end

-----------------------------------------------------------------------
-- PI constant (needed by MapCoords.lua and others)
-----------------------------------------------------------------------
if not PI then PI = math.pi end

-----------------------------------------------------------------------
-- EventRegistry shim (Retail global event callback system)
-----------------------------------------------------------------------
if not EventRegistry then
	EventRegistry = {
		RegisterCallback = function() end,
		UnregisterCallback = function() end,
		TriggerEvent = function() end,
	}
end

-----------------------------------------------------------------------
-- MapUtil shim
-----------------------------------------------------------------------
if not MapUtil then
	MapUtil = {
		GetMapCenterOnMap = function(mapID, containerMapID)
			return 0.5, 0.5
		end,
	}
end

-- C_AddOns logic consolidated above

-- C_QuestLog logic consolidated above

-- C_Map logic consolidated above
-- C_Map logic consolidated above

-----------------------------------------------------------------------
-- CreateVector2D shim
-----------------------------------------------------------------------
if not CreateVector2D then
	CreateVector2D = function(x, y)
		local vec = { x = x or 0, y = y or 0 }
		function vec:GetXY() return self.x, self.y end
		return vec
	end
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- Polyfills modern UI Object Methods
-- Note: It is inherently impossible to modify Object Metatables (TextureMeta, FrameMeta, etc.)
-- on the WotLK client without severe UI Taint. Native UI code indexes frames expecting
-- pure WoW C-code, and encountering an addon closure triggers an action blocked event. 
--
-- For universal compatibility, addons MUST use feature detection natively:
-- e.g. `if tex.SetColorTexture then tex:SetColorTexture(r,g,b) else tex:SetTexture(r,g,b) end`
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Mixin / CreateFromMixins shims
-----------------------------------------------------------------------
if not Mixin then
	Mixin = function(obj, ...)
		for i = 1, select("#", ...) do
			local mixin = select(i, ...)
			if mixin then
				for k, v in pairs(mixin) do
					obj[k] = v
				end
			end
		end
		return obj
	end
end

if not CreateFromMixins then
	CreateFromMixins = function(...)
		return Mixin({}, ...)
	end
end

-- C_UnitAuras logic consolidated above

-----------------------------------------------------------------------
-- C_GossipInfo namespace
-----------------------------------------------------------------------
if not C_GossipInfo then
	C_GossipInfo = {}

	C_GossipInfo.GetOptions = function()
		if not GetGossipOptions then return {} end
		local options = {}
		local args = { GetGossipOptions() }
		for i = 1, #args, 2 do
			local title = args[i]
			local gossipType = args[i + 1]
			if title then
				table.insert(options, {
					name = title,
					type = gossipType,
					gossipOptionID = math.ceil(i / 2),
				})
			end
		end
		return options
	end

	C_GossipInfo.SelectOption = function(optionID)
		if SelectGossipOption then
			SelectGossipOption(optionID)
		end
	end

	C_GossipInfo.GetNumOptions = function()
		if GetNumGossipOptions then
			return GetNumGossipOptions()
		end
		return 0
	end

	C_GossipInfo.GetNumAvailableQuests = function()
		if GetNumGossipAvailableQuests then
			return GetNumGossipAvailableQuests()
		end
		return 0
	end

	C_GossipInfo.GetNumActiveQuests = function()
		if GetNumGossipActiveQuests then
			return GetNumGossipActiveQuests()
		end
		return 0
	end

	C_GossipInfo.GetText = function()
		if GetGossipText then
			return GetGossipText()
		end
		return ""
	end
end

-----------------------------------------------------------------------
-- C_Container namespace
-----------------------------------------------------------------------
if not C_Container then
	C_Container = {}

	C_Container.GetContainerNumSlots = function(containerIndex)
		return GetContainerNumSlots(containerIndex)
	end

	C_Container.GetContainerItemInfo = function(containerIndex, slotIndex)
		local texture, itemCount, locked, quality, readable, lootable, itemLink = GetContainerItemInfo(containerIndex, slotIndex)
		if not texture then return nil end
		return {
			iconFileID = texture,
			stackCount = itemCount or 0,
			isLocked = locked,
			quality = quality,
			isReadable = readable,
			hasLoot = lootable,
			hyperlink = itemLink,
		}
	end

	C_Container.GetContainerItemID = function(containerIndex, slotIndex)
		local link = GetContainerItemLink(containerIndex, slotIndex)
		if link then
			local id = tonumber(link:match("item:(%d+)"))
			return id
		end
		return nil
	end

	C_Container.GetContainerNumFreeSlots = function(containerIndex)
		return GetContainerNumFreeSlots(containerIndex)
	end

	C_Container.GetContainerItemLink = function(containerIndex, slotIndex)
		return GetContainerItemLink(containerIndex, slotIndex)
	end

	C_Container.UseContainerItem = function(containerIndex, slotIndex, target)
		UseContainerItem(containerIndex, slotIndex, target)
	end

	C_Container.GetContainerItemCooldown = function(containerIndex, slotIndex)
		return GetContainerItemCooldown(containerIndex, slotIndex)
	end

	C_Container.ContainerIDToInventoryID = function(containerID)
		-- Container slots 0-4 map to inventory slots 20, 21, 22, 23, 24 (CONTAINER_OFFSET)
		if containerID == 0 then return 0 end
		local bagSlotOffsets = {20, 21, 22, 23, 24}  -- Standard bag slot mappings
		return bagSlotOffsets[containerID] or (containerID + 19)
	end
end

-- Always add ContainerIDToInventoryID if missing (outside the if not C_Container block)
if C_Container and not C_Container.ContainerIDToInventoryID then
	C_Container.ContainerIDToInventoryID = function(containerID)
		if containerID == 0 then return 0 end
		local bagSlotOffsets = {20, 21, 22, 23, 24}
		return bagSlotOffsets[containerID] or (containerID + 19)
	end
end

-----------------------------------------------------------------------
-- C_Item namespace
-----------------------------------------------------------------------
if not C_Item then
	C_Item = {}

	C_Item.GetItemInfo = function(itemID)
		return GetItemInfo(itemID)
	end

	C_Item.GetItemInfoInstant = function(itemID)
		return GetItemInfo(itemID)
	end

	C_Item.GetItemIconByID = function(itemID)
		local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
		return icon
	end

	C_Item.GetItemNameByID = function(itemID)
		local name = GetItemInfo(itemID)
		return name
	end

	C_Item.GetItemQualityByID = function(itemID)
		local _, _, quality = GetItemInfo(itemID)
		return quality
	end

	C_Item.IsItemDataCachedByID = function(itemID)
		local name = GetItemInfo(itemID)
		return name ~= nil
	end

	C_Item.RequestLoadItemDataByID = function(itemID)
		-- In 3.3.5a items are loaded synchronously via tooltip queries
		GameTooltip:SetHyperlink("item:" .. itemID)
		GameTooltip:Hide()
	end

	C_Item.GetItemLink = function(itemID)
		local name, link = GetItemInfo(itemID)
		return link
	end

	C_Item.DoesItemExistByID = function(itemID)
		return GetItemInfo(itemID) ~= nil
	end

	C_Item.GetItemClassInfo = function(classID)
		if GetItemClassInfo then
			return GetItemClassInfo(classID)
		end
		return nil
	end

	C_Item.GetItemSubClassInfo = function(classID, subClassID)
		if GetItemSubClassInfo then
			return GetItemSubClassInfo(classID, subClassID)
		end
		return nil
	end
end

-----------------------------------------------------------------------
-- C_Spell namespace (extends Retrofit.lua)
-----------------------------------------------------------------------
if not C_Spell then
	C_Spell = {}

	C_Spell.GetSpellInfo = function(spellID)
		local name, rank, iconID, castTime, minRange, maxRange, sid, originalIconID = GetSpellInfo(spellID)
		if not name then return nil end
		return {
			name = name,
			iconID = iconID,
			castTime = castTime,
			minRange = minRange,
			maxRange = maxRange,
			spellID = sid or spellID,
			originalIconID = originalIconID,
		}
	end

	C_Spell.GetSpellCooldown = function(spellID)
		local startTime, duration, isEnabled, modRate = GetSpellCooldown(spellID)
		return {
			startTime = startTime,
			duration = duration,
			isEnabled = isEnabled,
			modRate = modRate or 1,
		}
	end

	C_Spell.GetSpellName = function(spellID)
		local name = GetSpellInfo(spellID)
		return name
	end

	C_Spell.GetSpellTexture = function(spellID)
		local _, _, icon = GetSpellInfo(spellID)
		return icon
	end

	C_Spell.IsSpellUsable = function(spellID)
		if IsUsableSpell then
			return IsUsableSpell(spellID)
		end
		return false
	end
end

-----------------------------------------------------------------------
-- C_Timer namespace
-----------------------------------------------------------------------
if not C_Timer then
	C_Timer = {}

	local timerFrame = CreateFrame("Frame")
	timerFrame:Hide()
	local timers = {}
	local timerID = 0

	timerFrame:SetScript("OnUpdate", function(self, elapsed)
		local toRemove = {}
		for id, timer in pairs(timers) do
			timer.remaining = timer.remaining - elapsed
			if timer.remaining <= 0 then
				local ok, err = pcall(timer.callback)
				if not ok and DEFAULT_CHAT_FRAME then
					DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Compat-335 C_Timer error:|r " .. tostring(err))
				end
				if timer.isTicker then
					timer.remaining = timer.duration
				else
					table.insert(toRemove, id)
				end
			end
		end
		for _, id in ipairs(toRemove) do
			timers[id] = nil
		end
		if not next(timers) then
			timerFrame:Hide()
		end
	end)

	C_Timer.After = function(duration, callback)
		timerID = timerID + 1
		timers[timerID] = {
			remaining = duration,
			duration = duration,
			callback = callback,
			isTicker = false,
		}
		timerFrame:Show()
		return timerID
	end

	C_Timer.NewTimer = function(duration, callback)
		local id = C_Timer.After(duration, callback)
		return {
			Cancel = function(self)
				timers[id] = nil
			end,
			IsCancelled = function(self)
				return timers[id] == nil
			end,
		}
	end

	C_Timer.NewTicker = function(duration, callback, iterations)
		timerID = timerID + 1
		local thisID = timerID
		local count = 0
		timers[thisID] = {
			remaining = duration,
			duration = duration,
			callback = function()
				count = count + 1
				callback()
				if iterations and count >= iterations then
					timers[thisID] = nil
				end
			end,
			isTicker = true,
		}
		timerFrame:Show()
		return {
			Cancel = function(self)
				timers[thisID] = nil
			end,
			IsCancelled = function(self)
				return timers[thisID] == nil
			end,
		}
	end
end

-----------------------------------------------------------------------
-- C_Reputation namespace
-----------------------------------------------------------------------
if not C_Reputation then
	C_Reputation = {}

	C_Reputation.GetFactionDataByID = function(factionID)
		if GetFactionInfoByID then
			local name, description, standingID, barMin, barMax, barValue, atWarWith,
				canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfoByID(factionID)
			if not name then return nil end
			return {
				name = name,
				description = description,
				reaction = standingID,
				currentReactionThreshold = barMin,
				nextReactionThreshold = barMax,
				currentStanding = barValue,
				atWarWith = atWarWith,
				canToggleAtWar = canToggleAtWar,
				isHeader = isHeader,
				isCollapsed = isCollapsed,
				isWatched = isWatched,
				factionID = factionID,
			}
		end
		return nil
	end

	C_Reputation.GetFactionParagonInfo = function(factionID)
		return 0, 0, 0, false, false
	end

	C_Reputation.IsFactionParagon = function(factionID)
		return false
	end
end

-----------------------------------------------------------------------
-- C_CurrencyInfo namespace
-----------------------------------------------------------------------
if not C_CurrencyInfo then
	C_CurrencyInfo = {}

	C_CurrencyInfo.GetCurrencyInfo = function(currencyType)
		if GetCurrencyInfo then
			local name, currentAmount, texture, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo(currencyType)
			if not name then return nil end
			return {
				name = name,
				quantity = currentAmount,
				iconFileID = texture,
				currencyID = currencyType,
				maxQuantity = totalMax,
				isDiscovered = isDiscovered,
			}
		end
		return nil
	end
end

-----------------------------------------------------------------------
-- C_SuperTrack namespace (stubs)
-----------------------------------------------------------------------
if not C_SuperTrack then
	C_SuperTrack = {}
	C_SuperTrack.SetSuperTrackedQuestID = function() end
	C_SuperTrack.GetSuperTrackedQuestID = function() return 0 end
	C_SuperTrack.IsSuperTrackingQuest = function() return false end
	C_SuperTrack.SetSuperTrackedUserWaypoint = function() end
	C_SuperTrack.IsSuperTrackingUserWaypoint = function() return false end
end

-----------------------------------------------------------------------
-- C_TaxiMap namespace (stubs)
-----------------------------------------------------------------------
if not C_TaxiMap then
	C_TaxiMap = {}
	C_TaxiMap.GetAllTaxiNodes = function(mapID)
		return {}
	end
	C_TaxiMap.GetTaxiNodesForMap = function(mapID)
		return {}
	end
end

-----------------------------------------------------------------------
-- C_PlayerChoice namespace (stubs)
-----------------------------------------------------------------------
if not C_PlayerChoice then
	C_PlayerChoice = nil
end

-----------------------------------------------------------------------
-- C_Housing namespace (stubs, TWW housing)
-----------------------------------------------------------------------
if not C_Housing then
	C_Housing = {}
	C_Housing.IsHousingModeEnabled = function() return false end
	C_Housing.GetHousingPlotInfo = function() return nil end
end

-----------------------------------------------------------------------
-- C_Seasons namespace (stubs)
-----------------------------------------------------------------------
if not C_Seasons then
	C_Seasons = {}
	C_Seasons.HasActiveSeason = function() return false end
	C_Seasons.GetActiveSeason = function() return nil end
end

-----------------------------------------------------------------------
-- C_TaskQuest namespace (stubs, no world quests in 3.3.5a)
-----------------------------------------------------------------------
if not C_TaskQuest then
	C_TaskQuest = {}
	C_TaskQuest.GetQuestsForPlayerByMapID = function() return {} end
	C_TaskQuest.GetQuestInfoByQuestID = function() return nil end
	C_TaskQuest.IsActive = function() return false end
end

-----------------------------------------------------------------------
-- C_AchievementInfo namespace
-----------------------------------------------------------------------
if not C_AchievementInfo then
	C_AchievementInfo = {}

	C_AchievementInfo.GetRewardItemID = function(achievementID)
		return nil
	end

	C_AchievementInfo.GetAchievementNextID = function(achievementID)
		return nil
	end
end

-----------------------------------------------------------------------
-- C_Transmog / C_MountJournal / C_PetJournal stubs
-----------------------------------------------------------------------
if not C_Transmog then
	C_Transmog = {}
	C_Transmog.GetSlotInfo = function() return false, false, false end
end

if not C_MountJournal then
	C_MountJournal = {}
	C_MountJournal.GetNumMounts = function() return 0 end
	C_MountJournal.GetMountInfoByID = function() return nil end
	C_MountJournal.GetNumDisplayedMounts = function() return 0 end
end

if not C_PetJournal then
	C_PetJournal = {}
	C_PetJournal.GetNumPets = function() return 0 end
	C_PetJournal.GetPetInfoByPetID = function() return nil end
end

-----------------------------------------------------------------------
-- C_Garrison stubs
-----------------------------------------------------------------------
if not C_Garrison then
	C_Garrison = {}
	C_Garrison.GetLandingPageGarrisonType = function() return 0 end
	C_Garrison.HasGarrison = function() return false end
end

-----------------------------------------------------------------------
-- C_Covenants stubs
-----------------------------------------------------------------------
if not C_Covenants then
	C_Covenants = {}
	C_Covenants.GetActiveCovenantID = function() return 0 end
	C_Covenants.GetCovenantData = function() return nil end
end

-----------------------------------------------------------------------
-- CreateFramePool shim
-----------------------------------------------------------------------
if not CreateFramePool then
	CreateFramePool = function(frameType, parent, template, resetterFunc, forbidden, initFunc)
		local pool = {}
		pool.frameType = frameType
		pool.parent = parent
		pool.template = template
		pool.resetterFunc = resetterFunc
		pool.initFunc = initFunc
		pool.active = {}
		pool.inactive = {}
		pool.numActive = 0

		pool.Acquire = function(self)
			local frame = table.remove(self.inactive)
			if not frame then
				frame = CreateFrame(self.frameType, nil, self.parent, self.template)
				if self.initFunc then
					pcall(self.initFunc, frame)
				end
			end
			self.active[frame] = true
			self.numActive = self.numActive + 1
			return frame, true
		end

		pool.Release = function(self, frame)
			if not self.active[frame] then return end
			self.active[frame] = nil
			self.numActive = self.numActive - 1
			if self.resetterFunc then
				pcall(self.resetterFunc, self, frame)
			end
			table.insert(self.inactive, frame)
		end

		pool.ReleaseAll = function(self)
			for frame in pairs(self.active) do
				self:Release(frame)
			end
		end

		pool.EnumerateActive = function(self)
			return pairs(self.active)
		end

		pool.EnumerateInactive = function(self)
			return ipairs(self.inactive)
		end

		pool.GetNumActive = function(self)
			return self.numActive
		end

		return pool
	end
end

-----------------------------------------------------------------------
-- Frame API shims
-----------------------------------------------------------------------

-- SetResizeBounds (modern) -> SetMinResize/SetMaxResize (3.3.5a)
-- The addon already guards this with `if frame.SetResizeBounds then`, so no action needed.

-- GetPhysicalScreenSize -> GetScreenWidth/GetScreenHeight
if not GetPhysicalScreenSize then
	GetPhysicalScreenSize = function()
		return GetScreenWidth(), GetScreenHeight()
	end
end

-- Settings API shim for options registration (WotLK fallback)
if not Settings then
	Settings = {}
end

local settingsCategoryMap = {}
local settingsCategoryID = 0

Settings.GetCategory = function(categoryID)
	if type(categoryID) == "string" then
		return settingsCategoryMap[categoryID]
	end
	return settingsCategoryMap[categoryID]
end

Settings.RegisterCanvasLayoutCategory = function(frame, name)
	settingsCategoryID = settingsCategoryID + 1
	local categoryID = settingsCategoryID
	local category = {
		ID = name or categoryID,
		name = name,
		frame = frame,
	}
	settingsCategoryMap[name] = category
	settingsCategoryMap[categoryID] = category
	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory({
			name = name,
			frame = frame,
		})
	end
	return category
end

Settings.RegisterCanvasLayoutSubcategory = function(parentCategory, frame, name)
	if not parentCategory then return nil end
	settingsCategoryID = settingsCategoryID + 1
	local categoryID = settingsCategoryID
	local category = {
		ID = name or categoryID,
		name = name,
		frame = frame,
		parentID = parentCategory.ID,
	}
	settingsCategoryMap[name] = category
	settingsCategoryMap[categoryID] = category
	return category
end

if not Settings.RegisterAddOnCategory then
	Settings.RegisterAddOnCategory = function(category)
		if category and category.frame and InterfaceOptions_AddCategory then
			InterfaceOptions_AddCategory({
				name = category.name or category.ID,
				frame = category.frame,
			})
		end
	end
end

-----------------------------------------------------------------------
-- GetMaxLevelForExpansionLevel shim
-----------------------------------------------------------------------
if not GetMaxLevelForExpansionLevel then
	GetMaxLevelForExpansionLevel = function(expansionLevel)
		local maxLevels = {
			[0] = 60,  -- Classic
			[1] = 70,  -- TBC
			[2] = 80,  -- WotLK
		}
		return maxLevels[expansionLevel] or 80
	end
end

-----------------------------------------------------------------------
-- GetMaxPlayerLevel shim
-----------------------------------------------------------------------
if not GetMaxPlayerLevel then
	GetMaxPlayerLevel = function()
		return 80
	end
end

-----------------------------------------------------------------------
-- GetExpansionLevel shim
-----------------------------------------------------------------------
if not GetExpansionLevel then
	GetExpansionLevel = function()
		return 2 -- WotLK
	end
end

-----------------------------------------------------------------------
-- GetQuestProgressBarPercent shim
-----------------------------------------------------------------------
if not GetQuestProgressBarPercent then
	GetQuestProgressBarPercent = function(questID)
		return 0
	end
end

-----------------------------------------------------------------------
-- GetTaxiMapID shim
-----------------------------------------------------------------------
if not GetTaxiMapID then
	GetTaxiMapID = function()
		return C_Map.GetBestMapForUnit("player") or 0
	end
end

-----------------------------------------------------------------------
-- UnitPosition shim
-- Retail returns y, x, z, instanceID. In 3.3.5a this doesn't exist.
-- HereBeDragons upvalues this at load time so it must be a callable
-- global. Return nils so HBD falls back to C_Map-based positioning.
-----------------------------------------------------------------------
if not UnitPosition then
	UnitPosition = function(unit)
		return nil, nil, nil, nil
	end
end

-----------------------------------------------------------------------
-- Ambiguate shim
-- Strips the realm name from "Player-Realm" if same realm.
-- In 3.3.5a there are no cross-realm names so just return as-is.
-----------------------------------------------------------------------
if not Ambiguate then
	Ambiguate = function(fullName, context)
		if not fullName then return fullName end
		local name = fullName:match("^([^%-]+)")
		return name or fullName
	end
end

-----------------------------------------------------------------------
-- Dismount shim
-----------------------------------------------------------------------
if not Dismount then
	Dismount = function()
		-- 3.3.5a uses the macro command
	end
end

-----------------------------------------------------------------------
-- hooksecurefunc safety wrapper
-- Some files try to hooksecurefunc on C_QuestLog methods.
-- Our shimmed tables are regular Lua tables so hooksecurefunc
-- might fail. We wrap it to be safe.
-----------------------------------------------------------------------
local _original_hooksecurefunc = hooksecurefunc
hooksecurefunc = function(tableOrName, nameOrFunc, funcOrNil)
	local ok, err = pcall(_original_hooksecurefunc, tableOrName, nameOrFunc, funcOrNil)
	if not ok then
		-- Fallback: manually wrap the function
		if type(tableOrName) == "table" and type(nameOrFunc) == "string" and type(funcOrNil) == "function" then
			local orig = tableOrName[nameOrFunc]
			if orig then
				tableOrName[nameOrFunc] = function(...)
					local results = { orig(...) }
					pcall(funcOrNil, ...)
					return unpack(results)
				end
			end
		elseif type(tableOrName) == "string" and type(nameOrFunc) == "function" then
			local orig = _G[tableOrName]
			if orig then
				_G[tableOrName] = function(...)
					local results = { orig(...) }
					pcall(nameOrFunc, ...)
					return unpack(results)
				end
			end
		end
	end
end

-----------------------------------------------------------------------
-- Tooltip scanning helper (LibGratuity already handles this but just in case)
-----------------------------------------------------------------------
if not TooltipUtil then
	TooltipUtil = {
		GetDisplayedItem = function(tooltip)
			if tooltip.GetItem then
				return tooltip:GetItem()
			end
			return nil
		end,
	}
end

-----------------------------------------------------------------------
-- StaticPopupDialogs safety
-----------------------------------------------------------------------
if not StaticPopupDialogs then
	StaticPopupDialogs = {}
end

-----------------------------------------------------------------------
-- C_EventUtils namespace
-----------------------------------------------------------------------
if not C_EventUtils then
	C_EventUtils = {}
	C_EventUtils.IsEventValid = function(eventName)
		return false
	end
end

-----------------------------------------------------------------------
-- SOUNDKIT table
-- Retail uses SOUNDKIT.MAP_PING etc. In 3.3.5a these are just sound
-- file IDs. MAP_PING = 3175 was the classic ping sound.
-----------------------------------------------------------------------
if not SOUNDKIT then
	SOUNDKIT = setmetatable({}, { __index = function(t, k) return 0 end })
	SOUNDKIT.MAP_PING = 3175
	SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON = 856
	SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF = 857
	SOUNDKIT.GS_TITLE_OPTION_OK = 798
	SOUNDKIT.GS_TITLE_OPTION_EXIT = 799
end

-----------------------------------------------------------------------
-- SINGLE_DAMAGE_TEMPLATE
-- Used in Core_enUS.lua for item tooltip pattern matching.
-- In Retail this is a Blizzard global string.
-----------------------------------------------------------------------
SINGLE_DAMAGE_TEMPLATE = "%s Damage"

-----------------------------------------------------------------------
-- SPELL_SCHOOLn_CAP shims
-- Retail global strings for spell school names, used by Core_enUS.lua
-- and other localization files to build item tooltip match patterns.
-----------------------------------------------------------------------
if not SPELL_SCHOOL1_CAP then SPELL_SCHOOL1_CAP = "Holy"   end
if not SPELL_SCHOOL2_CAP then SPELL_SCHOOL2_CAP = "Fire"   end
if not SPELL_SCHOOL3_CAP then SPELL_SCHOOL3_CAP = "Nature" end
if not SPELL_SCHOOL4_CAP then SPELL_SCHOOL4_CAP = "Frost"  end
if not SPELL_SCHOOL5_CAP then SPELL_SCHOOL5_CAP = "Shadow" end
if not SPELL_SCHOOL6_CAP then SPELL_SCHOOL6_CAP = "Arcane" end

-----------------------------------------------------------------------
-- STAT_SPELLDAMAGE fallback
-----------------------------------------------------------------------
if not STAT_SPELLDAMAGE then
	STAT_SPELLDAMAGE = "Spell Damage"
end

-----------------------------------------------------------------------
-- GetClassInfo wrapper
-- In 3.3.5a, GetClassInfo(i) returns only (className, classTag).
-- Retail returns (className, classTag, classID). The addon calls
-- GetClassInfo(i) and expects 3 returns.
-----------------------------------------------------------------------
if not GetClassInfo then
	-- WotLK 3.3.5a does not have GetClassInfo. Provide a full implementation
	-- using the static list of WotLK playable classes.
	local _wotlkClasses = {
		[1]  = {"Warrior",    "WARRIOR"},
		[2]  = {"Paladin",    "PALADIN"},
		[3]  = {"Hunter",     "HUNTER"},
		[4]  = {"Rogue",      "ROGUE"},
		[5]  = {"Priest",     "PRIEST"},
		[6]  = {"Death Knight","DEATHKNIGHT"},
		[7]  = {"Shaman",     "SHAMAN"},
		[8]  = {"Mage",       "MAGE"},
		[9]  = {"Warlock",    "WARLOCK"},
		[11] = {"Druid",      "DRUID"},
	}
	GetClassInfo = function(classIndex)
		local info = _wotlkClasses[classIndex]
		if info then
			return info[1], info[2], classIndex
		end
		return nil, nil, nil
	end
else
	-- GetClassInfo exists but in 3.3.5a returns only (className, classTag).
	-- Wrap it to also return classIndex as the third value, which XPlore expects.
	local _origGetClassInfo = GetClassInfo
	local _classInfoOk = pcall(function()
		local a, b, c = _origGetClassInfo(1)
		if c == nil then error("needs wrap") end
	end)
	if not _classInfoOk then
		GetClassInfo = function(classIndex)
			local name, tag = _origGetClassInfo(classIndex)
			return name, tag, classIndex
		end
	end
end

-----------------------------------------------------------------------
-- Retail-only stat global strings used by Item-DataTables.lua
-----------------------------------------------------------------------
if not STAT_AVOIDANCE then STAT_AVOIDANCE = "Avoidance" end
if not STAT_HASTE then STAT_HASTE = "Haste" end
if not STAT_STURDINESS then STAT_STURDINESS = "Indestructible" end
if not STAT_LIFESTEAL then STAT_LIFESTEAL = "Leech" end
if not STAT_SPEED then STAT_SPEED = "Speed" end
if not STAT_VERSATILITY then STAT_VERSATILITY = "Versatility" end
if not STAT_MASTERY then STAT_MASTERY = "Mastery" end
if not EMPTY_SOCKET_DOMINATION then EMPTY_SOCKET_DOMINATION = "Domination Socket" end

-----------------------------------------------------------------------
-- INVSLOT constants for Item-DataTables.lua
-----------------------------------------------------------------------
if not INVSLOT_MAINHAND then INVSLOT_MAINHAND = 16 end
if not INVSLOT_OFFHAND then INVSLOT_OFFHAND = 17 end
if not INVSLOT_HEAD then INVSLOT_HEAD = 1 end
if not INVSLOT_NECK then INVSLOT_NECK = 2 end
if not INVSLOT_SHOULDER then INVSLOT_SHOULDER = 3 end
if not INVSLOT_BACK then INVSLOT_BACK = 15 end
if not INVSLOT_CHEST then INVSLOT_CHEST = 5 end
if not INVSLOT_WRIST then INVSLOT_WRIST = 9 end
if not INVSLOT_HAND then INVSLOT_HAND = 10 end
if not INVSLOT_WAIST then INVSLOT_WAIST = 6 end
if not INVSLOT_LEGS then INVSLOT_LEGS = 7 end
if not INVSLOT_FEET then INVSLOT_FEET = 8 end
if not INVSLOT_FINGER1 then INVSLOT_FINGER1 = 11 end
if not INVSLOT_TRINKET1 then INVSLOT_TRINKET1 = 13 end

-----------------------------------------------------------------------
-- C_TradeSkillUI stub
-- Retail API for professions. In 3.3.5a we use the old tradeskill API.
-----------------------------------------------------------------------
if not C_TradeSkillUI then
	C_TradeSkillUI = {}
	C_TradeSkillUI.GetCategoryInfo = function() return nil end
	C_TradeSkillUI.IsTradeSkillReady = function() return false end
	C_TradeSkillUI.IsTradeSkillGuild = function() return false end
	C_TradeSkillUI.IsTradeSkillLinked = function() return false end
	C_TradeSkillUI.GetAllRecipeIDs = function() return {} end
	C_TradeSkillUI.GetRecipeInfo = function() return nil end
	C_TradeSkillUI.GetRecipeSchematic = function() return {} end
	C_TradeSkillUI.GetRecipeItemLink = function() return "" end
	C_TradeSkillUI.GetCraftableCount = function() return 0 end
	C_TradeSkillUI.GetRecipeSourceText = function() return "" end
	C_TradeSkillUI.GetRecipeQualityItemIDs = function() return nil end
	C_TradeSkillUI.OpenTradeSkill = function() end
	C_TradeSkillUI.CraftRecipe = function() end
end

-----------------------------------------------------------------------
-- GetProfessions / GetProfessionInfo stubs for 3.3.5a
-- 3.3.5a uses GetNumSkillLines / GetSkillLineInfo instead.
-----------------------------------------------------------------------
if not GetProfessions then
	GetProfessions = function()
		return nil, nil, nil, nil, nil, nil
	end
end

if not GetProfessionInfo then
	GetProfessionInfo = function(index)
		return "Unknown", "Interface\\Icons\\INV_Misc_QuestionMark", 0, 0, 0, 0, 0, 0, 0, 0, "Unknown"
	end
end

-----------------------------------------------------------------------
-- GetCurrentRegion / GetCurrentRegionName
-- Not present in 3.3.5a. AceDB-3.0 uses these at file scope.
-----------------------------------------------------------------------
if not GetCurrentRegion then
	GetCurrentRegion = function() return 1 end
end
if not GetCurrentRegionName then
	GetCurrentRegionName = function() return "US" end
end

-----------------------------------------------------------------------
-- Mixin / CreateFromMixins
-- Retail helpers for mixing tables. Used by HBD-Pins, AceGUI, etc.
-----------------------------------------------------------------------
if not Mixin then
	Mixin = function(obj, ...)
		for i = 1, select("#", ...) do
			local mixin = select(i, ...)
			if mixin then
				for k, v in pairs(mixin) do
					obj[k] = v
				end
			end
		end
		return obj
	end
end
if not CreateFromMixins then
	CreateFromMixins = function(...)
		return Mixin({}, ...)
	end
end

-----------------------------------------------------------------------
-- Ambiguate
-- Retail function to shorten "Name-Realm" → "Name" on local realm.
-----------------------------------------------------------------------
if not Ambiguate then
	Ambiguate = function(fullName, context)
		if not fullName then return "" end
		local name = fullName:match("^([^%-]+)")
		return name or fullName
	end
end

-----------------------------------------------------------------------
-- CreateFramePool
-- Minimal stub for frame pooling used by HereBeDragons-Pins.
-----------------------------------------------------------------------
if not CreateFramePool then
	CreateFramePool = function(frameType, parent, template, resetFunc)
		local pool = {}
		pool._type = frameType or "Frame"
		pool._parent = parent or UIParent
		pool._frames = {}
		pool._used = {}
		pool.Acquire = function(self)
			local frame = tremove(self._frames)
			if not frame then
				frame = CreateFrame(self._type, nil, self._parent)
			end
			self._used[frame] = true
			return frame
		end
		pool.Release = function(self, frame)
			self._used[frame] = nil
			frame:Hide()
			frame:ClearAllPoints()
			tinsert(self._frames, frame)
		end
		pool.ReleaseAll = function(self)
			for f in pairs(self._used) do
				f:Hide()
				f:ClearAllPoints()
				tinsert(self._frames, f)
			end
			wipe(self._used)
		end
		pool.EnumerateActive = function(self)
			return pairs(self._used)
		end
		return pool
	end
end

-----------------------------------------------------------------------
-- Enum.UIMapType (Retail constants used by HereBeDragons)
-----------------------------------------------------------------------
if not Enum then Enum = {} end
if not Enum.UIMapType then
	Enum.UIMapType = {
		Cosmic = 0,
		World = 1,
		Continent = 2,
		Zone = 3,
		Dungeon = 4,
		Micro = 5,
		Orphan = 6,
	}
end

-----------------------------------------------------------------------
-- MapCanvasDataProviderMixin / MapCanvasPinMixin
-- Minimal stubs for HereBeDragons-Pins world map system.
-----------------------------------------------------------------------
if not MapCanvasDataProviderMixin then
	MapCanvasDataProviderMixin = {}
	MapCanvasDataProviderMixin.GetMap = function(self) return self._map end
	MapCanvasDataProviderMixin.SetMap = function(self, map) self._map = map end
	MapCanvasDataProviderMixin.RemoveAllData = function(self) end
	MapCanvasDataProviderMixin.RefreshAllData = function(self) end
	MapCanvasDataProviderMixin.OnMapChanged = function(self) end
	MapCanvasDataProviderMixin.OnAdded = function(self, map) self._map = map end
	MapCanvasDataProviderMixin.OnRemoved = function(self) self._map = nil end
end

if not MapCanvasPinMixin then
	MapCanvasPinMixin = {}
	MapCanvasPinMixin.OnLoad = function(self) end
	MapCanvasPinMixin.OnAcquired = function(self) end
	MapCanvasPinMixin.OnReleased = function(self) end
	MapCanvasPinMixin.SetPosition = function(self, x, y) self._x, self._y = x, y end
	MapCanvasPinMixin.UseFrameLevelType = function(self, levelType) end
	MapCanvasPinMixin.SetScalingLimits = function(self, ...) end
	MapCanvasPinMixin.SetPassThroughButtons = function(self, ...) end
end

-----------------------------------------------------------------------
-- WorldMapFrame stubs for HereBeDragons-Pins
-- In 3.3.5a WorldMapFrame exists but doesn't have canvas API.
-----------------------------------------------------------------------
if WorldMapFrame then
	if not WorldMapFrame.GetCanvas then
		WorldMapFrame.GetCanvas = function(self) return nil end
	end
	if not WorldMapFrame.pinPools then
		WorldMapFrame.pinPools = {}
	end
	if not WorldMapFrame.AddDataProvider then
		WorldMapFrame.AddDataProvider = function(self, provider) end
	end
	if not WorldMapFrame.RemoveAllPinsByTemplate then
		WorldMapFrame.RemoveAllPinsByTemplate = function(self, template) end
	end
	if not WorldMapFrame.EnumeratePinsByTemplate then
		WorldMapFrame.EnumeratePinsByTemplate = function(self, template)
			return pairs({})
		end
	end
	if not WorldMapFrame.RemovePin then
		WorldMapFrame.RemovePin = function(self, pin) end
	end
	if not WorldMapFrame.AcquirePin then
		WorldMapFrame.AcquirePin = function(self, ...) end
	end
	if not WorldMapFrame.GetMapID then
		WorldMapFrame.GetMapID = function(self) return 0 end
	end
end

-----------------------------------------------------------------------
-- C_Minimap stub
-----------------------------------------------------------------------
if not C_Minimap then
	C_Minimap = {}
	C_Minimap.GetViewRadius = function() return 200 end
end

-----------------------------------------------------------------------
-- C_Housing stub (if not already present)
-----------------------------------------------------------------------
if not C_Housing then
	C_Housing = {}
	C_Housing.IsHousingModeEnabled = function() return false end
end

-----------------------------------------------------------------------
-- SetPropagateKeyboardInput guard
-- This is a frame method that doesn't exist in 3.3.5a. We patch it
-- globally on the frame metatable if available.
-----------------------------------------------------------------------
do
	local frameMeta = getmetatable(CreateFrame("Frame"))
	if frameMeta and frameMeta.__index and not frameMeta.__index.SetPropagateKeyboardInput then
		frameMeta.__index.SetPropagateKeyboardInput = function(self, propagate) end
	end
end

-----------------------------------------------------------------------
-- C_Map namespace shims for 3.3.5a
-- Robustly add missing methods without clobbering existing ones
-----------------------------------------------------------------------
if not C_Map then C_Map = {} end
C_Map._mapInfoCache = C_Map._mapInfoCache or {}
C_Map._mapChildrenCache = C_Map._mapChildrenCache or {}

-- Force overwrite C_Map methods to ensure they use our WOTLK-specific logic
-- instead of poor Retrofit versions.
C_Map.GetBestMapForUnit = function(unit)
	if unit == "player" then
		if GetCurrentMapAreaID then 
			local id = GetCurrentMapAreaID()
			if id and id > 0 then return id end
		end
	end
	return 0
end

C_Map.GetPlayerMapPosition = function(uiMapID, unit)
	local x, y = GetPlayerMapPosition(unit or "player")
	if not x or not y or (x == 0 and y == 0) then return nil end
	return CreateVector2D(x, y)
end

C_Map.GetMapGroupID = function(uiMapID) return nil end
C_Map.GetMapGroupMembersInfo = function(groupID) return nil end

if not C_Map.GetMapInfo then
	C_Map.GetMapInfo = function(uiMapID)
		if not uiMapID then return nil end
		return C_Map._mapInfoCache[uiMapID] or { 
			mapID = uiMapID, 
			name = "Unknown Zone", 
			mapType = (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3, 
			parentMapID = 0 
		}
	end
end

if not C_Map.GetWorldPosFromMapPos then
	C_Map.GetWorldPosFromMapPos = function(uiMapID, mapPos)
		if not mapPos then return nil, nil end
		-- Returns instanceID, Vector2D
		return 0, CreateVector2D(mapPos.x, mapPos.y)
	end
end

if not C_Map.GetMapPosFromWorldPos then
	C_Map.GetMapPosFromWorldPos = function(uiMapID, worldPos, instanceID)
		if not worldPos then return nil end
		return CreateVector2D(worldPos.x, worldPos.y)
	end
end

if not C_Map.GetMapChildrenInfo then
	C_Map.GetMapChildrenInfo = function(uiMapID) return {} end
end

if not C_Map.GetMapLevels then
	C_Map.GetMapLevels = function(uiMapID) return {} end
end

-----------------------------------------------------------------------
-- UnitPosition stub (not available in 3.3.5a)
-- HereBeDragons expects (x, y, orderID, instanceCount/ID)
-----------------------------------------------------------------------
if not UnitPosition then
	UnitPosition = function(unit)
		if unit == "player" then
			local x, y = GetPlayerMapPosition("player")
			if not x or not y or (x == 0 and y == 0) then
				-- If current map position is 0, we're likely in a city/cave
				-- Return continents index as instanceID
				local instanceID = GetCurrentMapContinent() or 0
				return 0, 0, 0, instanceID
			end
			local instanceID = GetCurrentMapContinent() or 0
			-- Standard Retail returns (y, x, ...)
			return y, x, 0, instanceID
		end
		return nil, nil, nil, nil
	end
end

-----------------------------------------------------------------------
-- LARGE_NUMBER_SEPERATOR and DECIMAL_SEPERATOR shims
-----------------------------------------------------------------------
if not LARGE_NUMBER_SEPERATOR then LARGE_NUMBER_SEPERATOR = "," end
if not DECIMAL_SEPERATOR then DECIMAL_SEPERATOR = "." end

-----------------------------------------------------------------------
-- TooltipDataProcessor and TooltipDataType shims
-----------------------------------------------------------------------
if not Enum.TooltipDataType then
	Enum.TooltipDataType = {
		Item = 0,
		Spell = 1,
		Unit = 2,
		Corpse = 3,
		Object = 4,
	}
end

if not TooltipDataProcessor then
	TooltipDataProcessor = {
		AddTooltipPostCall = function() end, -- No-op stub for modern XP hooks
	}
end

-----------------------------------------------------------------------
-- Compat version registration
-----------------------------------------------------------------------
if DEFAULT_CHAT_FRAME then
	-- Silent load confirmation, no spam
end

-----------------------------------------------------------------------
-- Robust UI.SkinData shim
-----------------------------------------------------------------------
if type(XP) ~= "table" then XP = {} end
if not XP.UI then XP.UI = {} end
XP.UI.SkinData = function(property, ...)
	if not XP.CurrentSkinStyle or not XP.CurrentSkinStyle.GetProp then
		return {} -- Return empty table to prevent unpack crashes
	end
	local res = XP.CurrentSkinStyle:GetProp(property, ...)
	if res == nil then return {} end
	return res
end

-- MapCanvasDataProviderMixin safety for HBD on 3.3.5a
if MapCanvasDataProviderMixin then
	local oldGetMap = MapCanvasDataProviderMixin.GetMap
	MapCanvasDataProviderMixin.GetMap = function(self)
		return (oldGetMap and oldGetMap(self)) or WorldMapFrame
	end
end

--------------------------------------------------------------------
-- ConvertSecondsToUnits
-- Retail function to convert seconds to days/hours/minutes/seconds
--------------------------------------------------------------------
if not ConvertSecondsToUnits then
	ConvertSecondsToUnits = function(seconds)
		local s = seconds or 0
		local days = math.floor(s / 86400)
		s = s % 86400
		local hours = math.floor(s / 3600)
		s = s % 3600
		local minutes = math.floor(s / 60)
		local sec = s % 60
		return { days = days, hours = hours, minutes = minutes, seconds = sec }
	end
end

--------------------------------------------------------------------
-- C_DateAndTime
-- Retail API for date/time functions. Not available in 3.3.5a.
--------------------------------------------------------------------
if not C_DateAndTime then
	C_DateAndTime = {}
	
	-- GetSecondsUntilWeeklyReset returns seconds until Tuesday 06:00 server time
	C_DateAndTime.GetSecondsUntilWeeklyReset = function()
		-- Approximate: assume weekly reset is Tuesday 06:00
		-- This is a rough approximation for WotLK 3.3.5a
		local now = time()
		local resetDay = 2 -- Tuesday
		local resetHour = 6 -- 06:00 server time
		local t = date("*t", now)
		local daysUntilReset = (resetDay - t.wday) % 7
		if daysUntilReset == 0 and t.hour >= resetHour then
			daysUntilReset = 7
		end
		local resetTime = time({
			year = t.year, month = t.month, day = t.day + daysUntilReset,
			hour = resetHour, min = 0, sec = 0
		})
		return resetTime - now
	end
	
	C_DateAndTime.GetSecondsUntilDailyReset = function()
		-- Approximate: assume daily reset is 05:00 server time
		local now = time()
		local resetHour = 5 -- 05:00 server time
		local t = date("*t", now)
		local daysUntilReset = 0
		if t.hour >= resetHour then
			daysUntilReset = 1
		end
		local resetTime = time({
			year = t.year, month = t.month, day = t.day + daysUntilReset,
			hour = resetHour, min = 0, sec = 0
		})
		return resetTime - now
	end
	
	C_DateAndTime.GetCurrentCalendarTime = function()
		-- Returns calendar time object with year, month, day, monthDay, hour, minute, weekday, wday
		local t = date("*t", time())
		return {
			year = t.year,
			month = t.month,
			day = t.day,
			monthDay = t.day,
			hour = t.hour,
			minute = t.min,
			weekday = t.wday,
			wday = t.wday,
		}
	end
	
	C_DateAndTime.GetCalendarTimeFromEpoch = function(epoch)
		-- epoch is in microseconds, convert to calendar time
		local t = date("*t", epoch / 1000000)
		return {
			year = t.year,
			month = t.month,
			day = t.day,
			monthDay = t.day,
			hour = t.hour,
			minute = t.min,
			weekday = t.wday,
			wday = t.wday,
		}
	end
	
	C_DateAndTime.AdjustTimeByDays = function(calendartime, offset)
		-- Add/remove days from a calendar time object
		local epoch = time({
			year = calendartime.year,
			month = calendartime.month,
			day = calendartime.day,
			hour = calendartime.hour or 0,
			min = calendartime.minute or 0,
			sec = 0
		})
		local newEpoch = epoch + (offset * 86400)
		local t = date("*t", newEpoch)
		return {
			year = t.year,
			month = t.month,
			day = t.day,
			monthDay = t.day,
			hour = t.hour,
			minute = t.min,
			weekday = t.wday,
			wday = t.wday,
		}
	end
	
	C_DateAndTime.GetQuartereenStartTime = function()
		return 0
	end
	
	C_DateAndTime.GetServerTimeLocal = function()
		return time()
	end
end

--------------------------------------------------------------------
-- C_Calendar
-- Retail Calendar API wrapper. In WotLK, Calendar functions exist as global "Calendar"
--------------------------------------------------------------------
if not C_Calendar then
	C_Calendar = {}
	
	C_Calendar.GetNumDayEvents = function(_, day)
		if not Calendar or not Calendar.GetNumDayEvents then return 0 end
		local t = date("*t", time())
		return Calendar.GetNumDayEvents(t.month, day, t.year)
	end
	
	C_Calendar.GetDayEvent = function(_, day, eventIdx)
		if not Calendar or not Calendar.GetDayEvent then return nil end
		local t = date("*t", time())
		return Calendar.GetDayEvent(t.month, day, t.year, eventIdx)
	end
	
	C_Calendar.GetHolidayInfo = function(_, day, eventIdx)
		local event = C_Calendar.GetDayEvent(_, day, eventIdx)
		local status, result = pcall(function()
            if event["end"] then
                local date = C_Calendar.GetDate()
                if event["end"].year < date.year or (event["end"].year == date.year and (event["end"].month < date.month or (event["end"].month == date.month and event["end"].monthDay < date.monthDay))) then
                    return nil
                end
            end
            return event
        end)
        if not event then return nil end
		return {
			name = event.title or event.text,
			description = event.description or "",
			startTime = event.startTime or event["start"],
			endTime = event.endTime or event["end"],
		}
	end
end

--------------------------------------------------------------------
-- IsFrameLockActive
-- Retail function to check if UI frame lock is active (combat lock)
--------------------------------------------------------------------
if not IsFrameLockActive then
	IsFrameLockActive = function()
		return false
	end
end

--------------------------------------------------------------------
-- ContainerIDToInventoryID
-- Retail function to map container slot to inventory slot
--------------------------------------------------------------------
if not ContainerIDToInventoryID then
	ContainerIDToInventoryID = function(containerID)
		return containerID + 1
	end
end

--------------------------------------------------------------------
-- Enum.QuestTagType
-- Retail enum for quest tag types
--------------------------------------------------------------------
if not Enum.QuestTagType then
	Enum.QuestTagType = {
		None = 0,
		Normal = 1,
		Group = 2,
		PvP = 3,
		Raid = 4,
		Dungeon = 5,
		Heroic = 6,
		Elite = 7,
		Daily = 8,
		Weekly = 9,
		Lfg = 10,
		Scenario = 11,
		GuildGroup = 12,
		Kalisdal = 13,
		Invasion = 14,
		Profession = 15,
		PetBattle = 16,
		FactionAssault = 17,
		Islands = 18,
		CovenantCalling = 19,
	}
end

--------------------------------------------------------------------
-- C_QuestLog.GetQuestTagInfo
-- Retail function to get quest tag info
--------------------------------------------------------------------
if C_QuestLog and not C_QuestLog.GetQuestTagInfo then
	C_QuestLog.GetQuestTagInfo = function(questID)
		return nil
	end
end

--------------------------------------------------------------------
-- C_PetJournal
-- Retail pet journal API - stubbed for WotLK 3.3.5a where it's not available
--------------------------------------------------------------------
if not C_PetJournal then
	C_PetJournal = {}
end

-- Always add missing functions to C_PetJournal
if C_PetJournal and not C_PetJournal.IsFilterChecked then
	C_PetJournal.IsFilterChecked = function(filter)
		return false
	end
end

if C_PetJournal and not C_PetJournal.IsPetTypeChecked then
	C_PetJournal.IsPetTypeChecked = function(petType)
		return true
	end
end

if C_PetJournal and not C_PetJournal.GetNumPetTypes then
	C_PetJournal.GetNumPetTypes = function()
		return 10
	end
end

if C_PetJournal and not C_PetJournal.GetPetInfoBySpeciesID then
	C_PetJournal.GetPetInfoBySpeciesID = function(speciesID)
		return nil
	end
end

if C_PetJournal and not C_PetJournal.SetFilter then
	C_PetJournal.SetFilter = function(filter, value)
	end
end

if C_PetJournal and not C_PetJournal.ClearFanFilter then
	C_PetJournal.ClearFanFilter = function()
	end
end

if C_PetJournal and not C_PetJournal.GetPetStats then
	C_PetJournal.GetPetStats = function(petID)
		return nil
	end
end

if C_PetJournal and not C_PetJournal.PetIsCapturable then
	C_PetJournal.PetIsCapturable = function(petID)
		return false
	end
end

if C_PetJournal and not C_PetJournal.PetIsTradable then
	C_PetJournal.PetIsTradable = function(petID)
		return false
	end
end

if C_PetJournal and not C_PetJournal.GetNumPets then
	C_PetJournal.GetNumPets = function()
		return 0
	end
end

if C_PetJournal and not C_PetJournal.GetPetIDByIndex then
	C_PetJournal.GetPetIDByIndex = function(index)
		return nil
	end
end

--------------------------------------------------------------------
-- LE_PET_JOURNAL_FILTER constants
-- Used by C_PetJournal filter functions
--------------------------------------------------------------------
if not LE_PET_JOURNAL_FILTER_COLLECTED then
	LE_PET_JOURNAL_FILTER_COLLECTED = 1
end
if not LE_PET_JOURNAL_FILTER_NOT_COLLECTED then
	LE_PET_JOURNAL_FILTER_NOT_COLLECTED = 2
end

-----------------------------------------------------------------------
-- AceConfigDialog-3.0:AddToBlizOptions Legacy Shim for WotLK
-- Modern versions of AceConfigDialog only support the Retail "Settings" API.
-- This shim provides the legacy InterfaceOptions_AddCategory bridge for 3.3.5.
-----------------------------------------------------------------------
local LibStub_G = _G.LibStub
if LibStub_G then
	local MAJOR = "AceConfigDialog-3.0"
	local AceConfigDialog = LibStub_G:GetLibrary(MAJOR, true)
	if AceConfigDialog and not AceConfigDialog.AddToBlizOptions then
		AceConfigDialog.AddToBlizOptions = function(self, appName, name, parent, ...)
			if not appName or not name then
				error("Usage: AceConfigDialog:AddToBlizOptions(appName, name, [parent], [...])", 2)
			end

			-- Check if AceConfigRegistry has this app
			local reg = LibStub_G("AceConfigRegistry-3.0", true)
			if not reg or not reg:GetOptionsTable(appName) then
				error(appName .. " is not registered with AceConfigRegistry-3.0", 2)
			end

			-- Create a Blizzard Options compatible frame
			local frame = CreateFrame("Frame", appName .. "BlizOptions", UIParent)
			frame.name = name
			frame.parent = parent
			
			-- Callback for when Blizzard shows the frame
			frame.okay = function() self:Close(appName) end
			frame.cancel = function() self:Close(appName) end
			frame.default = function() end
			frame.refresh = function() self:Open(appName, frame) end

			InterfaceOptions_AddCategory(frame)
			
			-- Store it so we can reference it
			self.BlizOptions = self.BlizOptions or {}
			self.BlizOptions[appName] = frame
			
			return frame
		end
	end
end

