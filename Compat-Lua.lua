-- Compat-Lua.lua
-- Lua 5.1 to 5.4+ compatibility shim for X-Plore
-- MUST be loaded FIRST before any addon code that uses setfenv/getfenv/loadstring
--
-- WoW versions and their Lua versions:
-- - Classic/Era: Lua 5.1 (has native setfenv/getfenv/loadstring)
-- - TBC Classic: Lua 5.1
-- - WotLK: Lua 5.1  
-- - Cataclysm: Lua 5.1
-- - Mists: Lua 5.1
-- - Warlords: Lua 5.3
-- - Legion+: Lua 5.3 or 5.4
--
-- Global Platform Flags (Early Definition)
local _, _, _, tocversion = GetBuildInfo()
local tocInt = tonumber(tocversion) or 0
XP_IsRetail = (tocInt >= 100000)
XP_IsWOTLK = (tocInt >= 30000 and tocInt < 40000) or (tocInt == 30300)
XP_IsVanilla = (tocInt < 20000)
XP_IsTBC = (tocInt >= 20000 and tocInt < 30000)
XP_IsCATA = (tocInt >= 40000 and tocInt < 50000)
XP_IsMOP = (tocInt >= 50000 and tocInt < 60000)

-- CRITICAL: Create missing C_* namespaces and Enum BEFORE any library code runs
-- These MUST be global since libraries (AceComm, LibRover, etc.) are loaded immediately
-- when included via XML, before any further TOC processing occurs.

-- Enum (Retail-only global) - create immediately for all versions
-- Populate Enum tables that code checks with "if Enum and Enum.XXX"
_G.Enum = _G.Enum or {}

-- Enum.UIMapType - commonly used in map code
if not _G.Enum.UIMapType then
	_G.Enum.UIMapType = {
		Cosmic = 0,
		World = 1,
		Continent = 2,
		Zone = 3,
		Dungeon = 4,
		Micro = 5,
		Orphan = 6,
	}
end

-- Enum.QuestFrequency - used by quest code
if not _G.Enum.QuestFrequency then
	_G.Enum.QuestFrequency = {
		Default = 0,
		Daily = 1,
		Weekly = 2,
	}
end

-- Enum.ItemQuality - commonly checked in item code
if not _G.Enum.ItemQuality then
	_G.Enum.ItemQuality = {
		Poor = 0,
		Common = 1,
		Uncommon = 2,
		Rare = 3,
		Epic = 4,
		Legendary = 5,
		Heirloom = 7,
	}
end

-- Universal Polyfills: APIs missing from older versions but expected by modern libs.
-- These MUST be global.

-- tInvert - commonly used utility for inverting table keys/values
if not tInvert then
	function tInvert(tbl)
		local inverted = {}
		for k, v in pairs(tbl) do
			inverted[v] = k
		end
		return inverted
	end
end

-- securecallfunction - Retail API for secure execution, often no-op'd in Classic
if not securecallfunction then
	_G.securecallfunction = function(f, ...)
		return f(...)
	end
end

-- Ambiguate - used for cross-realm player names, not needed in 3.3.5a but often called
if not Ambiguate then
	_G.Ambiguate = function(fullName, context)
		return fullName -- No cross-realm support in 3.3.5a usually
	end
end

-- GetCurrentRegion / GetCurrentRegionName - used by AceDB-3.0
if not GetCurrentRegion then
	_G.GetCurrentRegion = function() return 1 end -- Default to US (1)
end
if not GetCurrentRegionName then
	_G.GetCurrentRegionName = function() return "US" end
end

-- C_CVar - used by LibDispel and others for registry access
if not C_CVar then
	_G.C_CVar = {
		GetCVar = function(name) return GetCVar(name) end,
		SetCVar = function(name, value) return SetCVar(name, value) end,
		RegisterCVar = function(name, value) return true end, -- No-op registration
	}
end

-- C_QuestLog - used by LibTaxi-1.0 and others
if not _G.C_QuestLog then
	_G.C_QuestLog = {
		IsQuestFlaggedCompleted = function(questID)
			if not questID then return false end
			local completedQuests = {}
			GetQuestsCompleted(completedQuests)
			return completedQuests[questID] or false
		end,
		GetQuestTagInfo = function(questID) return nil end,
		GetQuestLogIndexForQuestID = function(questID) return nil end,
	}
end

-- C_SpellBook - used by LibDispel and others
if not _G.C_SpellBook then
	_G.C_SpellBook = {
		IsSpellInSpellBook = function(spellID) return IsSpellKnown(spellID) or IsPlayerSpell(spellID) end,
		IsSpellKnown = function(spellID) return IsSpellKnown(spellID) or IsPlayerSpell(spellID) end,
	}
end

-- ElvUI Proxy Hardening
-- Satisfy early dependencies for addons checking "if ElvUI then" or "unpack(ElvUI)"
if not _G.ElvUI then
	local mt = { __index = function(t, k) return t end }
	local dummy = setmetatable({}, mt)
	_G.ElvUI = { [1] = dummy, [3] = dummy, [5] = dummy, dummy = true }
end

-- RegisterAddonMessagePrefix - used by AceComm-3.0
if not RegisterAddonMessagePrefix then
	_G.RegisterAddonMessagePrefix = function(prefix)
		return true -- 3.3.5a handles prefixes differently or doesn't require explicit registration
	end
end

-- CreateFromMixins - Retail API for object composition, used by HereBeDragons and modern Ace3
if not CreateFromMixins then
	_G.CreateFromMixins = function(...)
		local mixin = {}
		for i = 1, select("#", ...) do
			local object = select(i, ...)
			for k, v in pairs(object) do
				mixin[k] = v
			end
		end
		return mixin
	end
end

-- Enum and C_Garrison shims for LibRover
if not _G.Enum then _G.Enum = {} end
_G.Enum.GarrisonType = _G.Enum.GarrisonType or { Type_6_0 = 2, Type_6_0_Garrison = 2, Type_7_0 = 3, Type_8_0 = 4 }

if not _G.C_Garrison then
	_G.C_Garrison = {
		GetGarrisonInfo = function() return 0 end,
		HasGarrison = function() return false end,
	}
end

-- IsSpellKnownOrOverridesKnown - used by modern LibDispel
if not IsSpellKnownOrOverridesKnown then
	_G.IsSpellKnownOrOverridesKnown = function(spellID)
		return IsSpellKnown(spellID) or IsPlayerSpell(spellID)
	end
end

-- CreateVector2D - Retail API for 2D vectors, used by HereBeDragons and LibRover
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

-- Retail Namespace Shims
-- These prevent "attempt to index global 'C_Xxx' (a nil value)" in modern libs
_G.C_Map = _G.C_Map or {}
_G.C_Housing = _G.C_Housing or {}
_G.C_BattleNet = _G.C_BattleNet or {}
_G.C_ChatInfo = _G.C_ChatInfo or {}
_G.C_Spell = _G.C_Spell or {}
_G.C_Timer = _G.C_Timer or {}

-- Populate with minimal no-ops required by libs
_G.C_Map.GetMapInfo = function(mapID) return nil end
_G.C_Map.GetMapArtLayers = function(mapID) return {} end
_G.C_Map.GetMapLevels = function(mapID) return 0 end
_G.C_Map.GetMapChildrenInfo = function(mapID) return {} end
_G.C_Housing.GetVisitCooldownInfo = function() return 0 end
_G.C_BattleNet.SendGameData = function() return true end

-- C_ChatInfo Extensions - used by AceComm-3.0
_G.C_ChatInfo.RegisterAddonMessagePrefix = _G.RegisterAddonMessagePrefix or function() end
_G.C_ChatInfo.SendAddonMessage = _G.SendAddonMessage or function() end

-- C_Spell Extensions - used by LibRover-1.0
_G.C_Spell.GetSpellInfo = function(spellID)
	if GetSpellInfo then
		local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(spellID)
		return { name = name, iconID = icon, spellID = spellID }
	end
	return { name = "Unknown", spellID = spellID }
end
_G.C_Spell.GetSpellCooldown = function(spellID)
	if GetSpellCooldown then
		return GetSpellCooldown(spellID)
	end
	return 0, 0, 0
end
_G.C_Spell.IsSpellKnown = function(spellID)
	if IsSpellKnown then return IsSpellKnown(spellID) end
	if IsPlayerSpell then return IsPlayerSpell(spellID) end
	return false
end

-- C_Timer Extensions - used by NickTag-1.0 and modern libs
if not _G.C_Timer.After then
	_G.C_Timer.After = function(duration, callback)
		local timer = CreateFrame("Frame")
		timer.elapsed = 0
		timer:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = self.elapsed + elapsed
			if self.elapsed >= duration then
				self:SetScript("OnUpdate", nil)
				callback()
			end
		end)
	end
end

if not _G.C_Timer.NewTicker then
	_G.C_Timer.NewTicker = function(duration, callback, iterations)
		local ticker = CreateFrame("Frame")
		ticker.elapsed = 0
		ticker.iterations = iterations or 0
		ticker.count = 0
		ticker:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = self.elapsed + elapsed
			if self.elapsed >= duration then
				self.elapsed = 0
				self.count = self.count + 1
				callback(self)
				if self.iterations > 0 and self.count >= self.iterations then
					self:SetScript("OnUpdate", nil)
					self._cancelled = true
				end
			end
		end)
		ticker.Cancel = function(self)
			self:SetScript("OnUpdate", nil)
			self._cancelled = true
		end
		return ticker
	end
end

if not _G.C_ChatInfo.SendAddonMessageLogged then _G.C_ChatInfo.SendAddonMessageLogged = function() return false end end
if not _G.C_Map.GetMapInfo then _G.C_Map.GetMapInfo = function() return nil end end
if not _G.C_Map.GetWorldPosFromMapPos then _G.C_Map.GetWorldPosFromMapPos = function() return nil, nil end end
if not _G.C_Map.GetMapWorldSize then _G.C_Map.GetMapWorldSize = function() return nil, nil end end

-- CreateFramePool - Retail API for frame pooling, used by HereBeDragons-Pins
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

-- NOTE: Do NOT create empty stub namespaces for C_ChatInfo, C_Item, C_Spell, etc.
-- Retail code often checks "if C_ChatInfo then C_ChatInfo.SomeMethod()" and expects 
-- the method to actually exist. Creating an empty table makes the if-pass but the 
-- method is nil, causing crashes. The Retail libs have their own guards for these.
-- Only add stubs where ALL functions are properly implemented.

-- C_AddOns - these functions are safe to stub as they're simple wrappers
_G.C_AddOns = _G.C_AddOns or {}
if not _G.C_AddOns.GetAddOnMetadata then _G.C_AddOns.GetAddOnMetadata = GetAddOnMetadata end
if not _G.C_AddOns.GetAddOnInfo then _G.C_AddOns.GetAddOnInfo = GetAddOnInfo end
if not _G.C_AddOns.GetNumAddOns then _G.C_AddOns.GetNumAddOns = GetNumAddOns end
if not _G.C_AddOns.IsAddOnLoaded then _G.C_AddOns.IsAddOnLoaded = IsAddOnLoaded end

-- Functions removed in Lua 5.2+:
-- - loadstring -> replaced by load() with env parameter
-- - setfenv -> replaced by _ENV upvalue closure pattern
-- - getfenv -> replaced by _ENV upvalue access
--
-- This shim provides universal compatibility by:
-- 1. Providing loadstring that wraps load() with proper environment handling
-- 2. Providing setfenv/getfenv that work within Lua limitations
-- 3. Adding XPLoadString() helper for direct environment loading
-- 4. Global Addon Table registry to fix string indexing errors

-- Early Initialization for Global XP Data
local name, XP = ...
if name and type(XP) == "table" then
    _G[name.."_Data"] = XP
    -- If XP global is not set, set it now to allow early module access
    if not _G.XP then _G.XP = XP end
else
    XP = _G.XP
end

-- Ensure XP is a valid table before proceeding
if type(XP) ~= "table" then XP = {} end

-- Global Aliases for Localization (Proxy for early access)
local function LocalizationProxy(...)
    return setmetatable({}, {
        __index = function(t,k) return k end,
        __call = function(t,...) return t end
    })
end

_G.XPlore_L = _G.XPlore_L or LocalizationProxy
_G.XPloreViewer_L = _G.XPloreViewer_L or LocalizationProxy

-- Use a dynamic proxy for XP.L/LS that resolves to the real table when available
XP.L = setmetatable({}, {
    __index = function(t,k)
        if _G.XPlore_L and _G.XPlore_L ~= LocalizationProxy then
            local real = _G.XPlore_L("Main")
            if real then return real[k] end
        end
        return k
    end
})
XP.LS = setmetatable({}, {
    __index = function(t,k)
        if _G.XPlore_L and _G.XPlore_L ~= LocalizationProxy then
            local real = _G.XPlore_L("G_string")
            if real then return real[k] end
        end
        return k
    end
})

XP.startups = XP.startups or {}
XP._MailboxData = XP._MailboxData or ""
XP._NPCData = XP._NPCData or ""
XP.UI = XP.UI or {}
XP.UI.SkinData = XP.UI.SkinData or function() return {} end
XP.Skins = XP.Skins or {}
XP.Modules = XP.Modules or {}
XP.Guides = XP.Guides or {}
XP.Professions = XP.Professions or {}
XP.db = XP.db or { char = { checks = {} }, profile = {} }

-- Detect expansion version
local version, build, date, tocversion = GetBuildInfo()
tocversion = tonumber(tocversion)

_G.XP_IsRetail = (tocversion >= 100000)
_G.XP_IsWOTLK = (tocversion >= 30000 and tocversion < 40000) or (tocversion == 30300)
_G.XP_IsCATA = (tocversion >= 40000 and tocversion < 50000)
_G.XP_IsMOP = (tocversion >= 50000 and tocversion < 60000)
_G.XP_IsVanilla = (tocversion < 20000)
_G.XP_IsTBC = (tocversion >= 20000 and tocversion < 30000)

local _G = _G

------------------------------------------------------------------
-- Detect Lua version
------------------------------------------------------------------
local _LUA_VERSION = 5.1
if _VERSION then
    if _VERSION:match("5%.4") then
        _LUA_VERSION = 5.4
    elseif _VERSION:match("5%.3") then
        _LUA_VERSION = 5.3
    elseif _VERSION:match("5%.2") then
        _LUA_VERSION = 5.2
    end
end
_G._LUA_VERSION = _LUA_VERSION

------------------------------------------------------------------
-- Environment registry for setfenv/getfenv compatibility
-- In Lua 5.2+, we cannot change a function's environment after creation
-- So we track them in a registry and provide getfenv access
------------------------------------------------------------------
local _envRegistry = {}
local _envCounter = 0

------------------------------------------------------------------
-- XPLoadString: Universal loadstring replacement that supports environment
-- Works correctly across all Lua versions (5.1 through 5.4+)
--
-- Usage: local fun, err = XPLoadString(code, environment)
--   or:  local fun, err = XPLoadString(code)  -- uses _G as env
--
-- Returns: function, error message (standard Lua pattern)
--
-- This is the PREFERRED function to use for dynamic code loading
------------------------------------------------------------------
local function XPLoadString(code, env)
    if not code or code == "" then
        return nil, "empty string"
    end
    
    env = env or _G
    
    if _LUA_VERSION >= 5.2 then
        -- Lua 5.2+: Use load() with environment parameter
        -- load(code, chunkname, mode, env)
        -- mode "t" means text mode (not binary)
        local fn, err = load(code, nil, "t", env)
        return fn, err
    else
        -- Lua 5.1: Use loadstring, then setfenv
        local fn, err = loadstring(code)
        if fn and env then
            setfenv(fn, env)
        end
        return fn, err
    end
end
_G.XPLoadString = XPLoadString

------------------------------------------------------------------
-- loadstring compatibility shim
-- In Lua 5.2+, loadstring is removed. We wrap load() to provide
-- the same interface for code that hasn't been updated yet.
--
-- NOTE: This shim does NOT support environment. Code using
-- setfenv after loadstring will NOT work correctly in Lua 5.2+.
-- Use XPLoadString(code, env) instead for proper environment support.
------------------------------------------------------------------
if _LUA_VERSION >= 5.2 then
    local _origLoad = load
    
    _G.loadstring = function(code, chunkname)
        if not code or code == "" then
            return nil, "empty string"
        end
        
        -- Use load without explicit environment
        -- This creates a function with _G as _ENV
        return _origLoad(code, chunkname, "t")
    end
end

------------------------------------------------------------------
-- setfenv compatibility
-- 
-- LUA 5.1: Native setfenv works normally
--
-- LUA 5.2+: This is problematic because in Lua 5.2+, functions
-- capture their _ENV at creation time and it cannot be changed.
--
-- Our shim attempts to:
-- 1. Find if the function has an _ENV upvalue
-- 2. Replace it via debug.upvaluejoin if possible
-- 3. Otherwise, store in registry for getfenv to find
--
-- This shim is NOT perfect - it cannot truly emulate Lua 5.1's
-- setfenv behavior for all cases. Code using setfenv after
-- function creation will have limited functionality in Lua 5.2+.
--
-- RECOMMENDATION: Use XPLoadString(code, env) instead.
------------------------------------------------------------------
if not _G.setfenv then
    _G.setfenv = function(f, env)
        if type(f) ~= "function" then
            return f
        end
        
        -- Lua 5.2+ implementation
        if _LUA_VERSION >= 5.2 and debug and debug.upvalueinfo then
            -- Find _ENV upvalue index
            local upvIndex = 1
            local found = false
            
            while true do
                local name = debug.upvalueinfo(f, upvIndex)
                if not name then break end
                if name == "_ENV" then
                    found = true
                    break
                end
                upvIndex = upvIndex + 1
            end
            
            if found then
                -- Try to replace _ENV via upvaluejoin
                -- We create a wrapper that returns our env
                local wrapper
                _envCounter = _envCounter + 1
                local sentinel = setmetatable({}, {
                    __index = function() return env end,
                    __newindex = function() end
                })
                
                -- Attempt to inject via upvaluejoin
                local ok = pcall(function()
                    debug.upvaluejoin(f, upvIndex, (function() return sentinel end), 1)
                end)
                
                if ok then
                    return f
                end
            end
        end
        
        -- Fallback: Store in registry for getfenv
        _envRegistry[f] = env
        return f
    end
end

------------------------------------------------------------------
-- getfenv compatibility
--
-- LUA 5.1: Native getfenv works normally
--
-- LUA 5.2+: Attempts to retrieve _ENV from upvalues or registry
------------------------------------------------------------------
if not _G.getfenv then
    _G.getfenv = function(f)
        if f == 0 or f == nil then
            return _G
        end
        
        if type(f) == "number" then
            -- Stack level - try to get function from stack
            local info = debug and debug.getinfo and debug.getinfo(f, "u")
            if info and info.func then
                f = info.func
            else
                return _G
            end
        end
        
        if type(f) ~= "function" then
            return _G
        end
        
        -- Lua 5.2+ implementation
        if _LUA_VERSION >= 5.2 and debug and debug.upvalueinfo then
            local upvIndex = 1
            while true do
                local name = debug.upvalueinfo(f, upvIndex)
                if not name then break end
                if name == "_ENV" then
                    -- We found _ENV upvalue, try to get its value
                    -- This is tricky - we can't directly get upvalue values
                    -- without calling the function
                    break
                end
                upvIndex = upvIndex + 1
            end
        end
        
        -- Check registry
        local env = _envRegistry[f]
        if env then
            return env
        end
        
        return _G
    end
end

------------------------------------------------------------------
-- Ensure unpack is available
------------------------------------------------------------------
if not _G.unpack then
    _G.unpack = table.unpack
end

------------------------------------------------------------------
-- Ensure select is available
------------------------------------------------------------------
if not _G.select then
    _G.select = function(index, ...)
        local args = {...}
        if index == "#" then
            return #args
        elseif index < 0 then
            return args[#args + index + 1]
        else
            return args[index]
        end
    end
end

------------------------------------------------------------------
-- Return compatibility info
------------------------------------------------------------------
return {
    lua_version = _LUA_VERSION,
    has_loadstring = _G.loadstring ~= nil,
    has_setfenv = _G.setfenv ~= nil,
    has_getfenv = _G.getfenv ~= nil,
    XPLoadString = XPLoadString,
}
