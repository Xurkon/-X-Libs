--- **AceSerializer-3.0** can serialize any variable (except functions or userdata) into a string format,
-- that can be send over the addon comm channel. AceSerializer was designed to keep all data intact, especially
-- very large numbers or floating point numbers, and table structures. The only caveat currently is, that multiple
-- references to the same table will be send individually.
--
-- **AceSerializer-3.0** can be embeded into your addon, either explicitly by calling AceSerializer:Embed(MyAddon) or by
-- specifying it as an embeded library in your AceAddon. All functions will be available on your addon object
-- and can be accessed directly, without having to explicitly call AceSerializer itself.\
-- It is recommended to embed AceSerializer, otherwise you'll have to specify a custom `self` on all calls you
-- make into AceSerializer.
-- @class file
-- @name AceSerializer-3.0
-- @release $Id$
local MAJOR,MINOR = "AceSerializer-3.0", 99
local AceSerializer, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not AceSerializer then return end

-- Lua APIs
local strbyte, strchar, gsub, gmatch, format = string.byte, string.char, string.gsub, string.gmatch, string.format
local assert, error, pcall = assert, error, pcall
local type, tostring, tonumber = type, tostring, tonumber
local pairs, select, frexp = pairs, select, math.frexp
local tconcat = table.concat

-- quick copies of string representations of wonky numbers
local inf = math.huge

local serNaN  -- can't do this in 4.3, see ace3 ticket 268
local serInf, serInfMac = "1.#INF", "inf"
local serNegInf, serNegInfMac = "-1.#INF", "-inf"


-- Serialization functions

local function SerializeStringHelper(ch)	-- Used by SerializeValue for strings
	-- We use \126 ("~") as an escape character for all nonprints plus a few more
	local n = strbyte(ch)
	if n==30 then           -- v3 / ticket 115: catch a nonprint that ends up being "~^" when encoded... DOH
		return "\126\122"
	elseif n<=32 then 			-- nonprint + space
		return "\126"..strchar(n+64)
	elseif n==94 then		-- value separator
		return "\126\125"
	elseif n==126 then		-- our own escape character
		return "\126\124"
	elseif n==127 then		-- nonprint (DEL)
		return "\126\123"
	else
		assert(false)	-- can't be reached if caller uses a sane regex
	end
end

local function SerializeValue(v, res, nres)
	-- We use "^" as a value separator, followed by one byte for type indicator
	local t=type(v)

	if t=="string" then		-- ^S = string (escaped to remove nonprints, "^"s, etc)
		res[nres+1] = "^S"
		res[nres+2] = gsub(v,"[%c \94\126\127]", SerializeStringHelper)
		nres=nres+2

	elseif t=="number" then	-- ^N = number (just tostring()ed) or ^F (float components)
		local str = tostring(v)
		if tonumber(str)==v  --[[not in 4.3 or str==serNaN]] then
			-- translates just fine, transmit as-is
			res[nres+1] = "^N"
			res[nres+2] = str
			nres=nres+2
		elseif v == inf or v == -inf then
			res[nres+1] = "^N"
			res[nres+2] = v == inf and serInf or serNegInf
			nres=nres+2
		else
			local m,e = frexp(v)
			res[nres+1] = "^F"
			res[nres+2] = format("%.0f",m*2^53)	-- force mantissa to become integer (it's originally 0.5--0.9999)
			res[nres+3] = "^f"
			res[nres+4] = tostring(e-53)	-- adjust exponent to counteract mantissa manipulation
			nres=nres+4
		end

	elseif t=="table" then	-- ^T...^t = table (list of key,value pairs)
		nres=nres+1
		res[nres] = "^T"
		for key,value in pairs(v) do
			nres = SerializeValue(key, res, nres)
			nres = SerializeValue(value, res, nres)
		end
		nres=nres+1
		res[nres] = "^t"

	elseif t=="boolean" then	-- ^B = true, ^b = false
		nres=nres+1
		if v then
			res[nres] = "^B"	-- true
		else
			res[nres] = "^b"	-- false
		end

	elseif t=="nil" then		-- ^Z = nil (zero, "N" was taken :P)
		nres=nres+1
		res[nres] = "^Z"

	else
		error(MAJOR..": Cannot serialize a value of type '"..t.."'")	-- can't produce error on right level, this is wildly recursive
	end

	return nres
end



local serializeTbl = { "^1" }	-- "^1" = Hi, I'm data serialized by AceSerializer protocol rev 1

--- Serialize the data passed into the function.
-- Takes a list of values (strings, numbers, booleans, nils, tables)
-- and returns it in serialized form (a string).\
-- May throw errors on invalid data types.
-- @param ... List of values to serialize
-- @return The data in its serialized form (string)
function AceSerializer:Serialize(...)
	local nres = 1

	for i=1,select("#", ...) do
		local v = select(i, ...)
		nres = SerializeValue(v, serializeTbl, nres)
	end

	serializeTbl[nres+1] = "^^"	-- "^^" = End of serialized data

	return tconcat(serializeTbl, "", 1, nres+1)
end

-- Deserialization functions
local function DeserializeStringHelper(escape)
	if escape<"~\122" then
		return strchar(strbyte(escape,2,2)-64)
	elseif escape=="~\122" then	-- v3 / ticket 115: special case encode since 30+64=94 ("^") - OOPS.
		return "\030"
	elseif escape=="~\123" then
		return "\127"
	elseif escape=="~\124" then
		return "\126"
	elseif escape=="~\125" then
		return "\94"
	end
	error("DeserializeStringHelper got called for '"..escape.."'?!?")  -- can't be reached unless regex is screwed up
end

local function DeserializeNumberHelper(number)
	--[[ not in 4.3 if number == serNaN then
		return 0/0
	else]]if number == serNegInf or number == serNegInfMac then
		return -inf
	elseif number == serInf or number == serInfMac then
		return inf
	else
		return tonumber(number)
	end
end

-- DeserializeValue: worker function for :Deserialize()
-- It works in two modes:
--   Main (top-level) mode: Deserialize a list of values and return them all
--   Recursive (table) mode: Deserialize only a single value (_may_ of course be another table with lots of subvalues in it)
--
-- The function _always_ works recursively due to having to build a list of values to return
--
-- Callers are expected to pcall(DeserializeValue) to trap errors

local function DeserializeValue(iter,single,ctl,data)

	if not single then
		ctl,data = iter()
	end

	if not ctl then
		error("Supplied data misses AceSerializer terminator ('^^')")
	end

	if ctl=="^^" then
		-- ignore extraneous data
		return
	end

	local res

	if ctl=="^S" then
		res = gsub(data, "~.", DeserializeStringHelper)
	elseif ctl=="^N" then
		res = DeserializeNumberHelper(data)
		if not res then
			error("Invalid serialized number: '"..tostring(data).."'")
		end
	elseif ctl=="^F" then     -- ^F<mantissa>^f<exponent>
		local ctl2,e = iter()
		if ctl2~="^f" then
			error("Invalid serialized floating-point number, expected '^f', not '"..tostring(ctl2).."'")
		end
		local m=tonumber(data)
		e=tonumber(e)
		if not (m and e) then
			error("Invalid serialized floating-point number, expected mantissa and exponent, got '"..tostring(m).."' and '"..tostring(e).."'")
		end
		res = m*(2^e)
	elseif ctl=="^B" then	-- yeah yeah ignore data portion
		res = true
	elseif ctl=="^b" then   -- yeah yeah ignore data portion
		res = false
	elseif ctl=="^Z" then	-- yeah yeah ignore data portion
		res = nil
	elseif ctl=="^T" then
		-- ignore ^T's data, future extensibility?
		res = {}
		local k,v
		while true do
			ctl,data = iter()
			if ctl=="^t" then break end	-- ignore ^t's data
			k = DeserializeValue(iter,true,ctl,data)
			if k==nil then
				error("Invalid AceSerializer table format (no table end marker)")
			end
			ctl,data = iter()
			v = DeserializeValue(iter,true,ctl,data)
			if v==nil then
				error("Invalid AceSerializer table format (no table end marker)")
			end
			res[k]=v
		end
	else
		error("Invalid AceSerializer control code '"..ctl.."'")
	end

	if not single then
		return res,DeserializeValue(iter)
	else
		return res
	end
end

--- Deserializes the data into its original values.
-- Accepts serialized data, ignoring all control characters and whitespace.
-- @param str The serialized data (from :Serialize)
-- @return true followed by a list of values, OR false followed by an error message
function AceSerializer:Deserialize(str)
	str = gsub(str, "[%c ]", "")	-- ignore all control characters; nice for embedding in email and stuff

	local iter = gmatch(str, "(^.)([^^]*)")	-- Any ^x followed by string of non-^
	local ctl,data = iter()
	if not ctl or ctl~="^1" then
		-- we purposefully ignore the data portion of the start code, it can be used as an extension mechanism
		return false, "Supplied data is not AceSerializer data (rev 1)"
	end

	return pcall(DeserializeValue, iter)
end


------------------------------------------
-- Legacy Format Support (Questie-X and older addons)
-- Detects and deserializes the old v1 serialization format
------------------------------------------

local strfind, strsub, strjoin, strlen = string.find, string.sub, string.join, string.len
local math_max, math_min = math.max, math.min

-- Legacy SerializeValue (from Questie-X AceSerializer)
local function SerializeValueLegacy(v, res, n)
	-- nil
	if v == nil then
		res[n+1] = "n"
		return n+1
	end
	
	-- boolean
	if type(v) == "boolean" then
		res[n+1] = v and "t" or "f"
		return n+1
	end
	
	-- number
	if type(v) == "number" then
		local str = tostring(v)
		if strfind(str, "[^0-9%._]") then
			res[n+1] = str
		else
			res[n+1] = format("%.4f", v)
		end
		return n+1
	end
	
	-- string
	if type(v) == "string" then
		res[n+1] = format("%q", v)
		return n+1
	end
	
	-- table
	if type(v) == "table" then
		res[n+1] = "{"
		local n2 = n+2
		for k, val in pairs(v) do
			n2 = SerializeValueLegacy(k, res, n2)
			res[n2+1] = "="
			n2 = n2 + 2
			n2 = SerializeValueLegacy(val, res, n2)
			res[n2+1] = ","
			n2 = n2 + 1
		end
		res[n2] = "}"
		return n2
	end
	
	error(format("Cannot serialize a value of type %s", type(v)))
end

-- Legacy Deserialize
local function DeserializeLegacy(s)
	if type(s) ~= "string" then
		error("Usage: AceSerializer:Deserialize(str): str must be a string, got " .. type(s), 2)
	end
	
	local stack = {}
	local n = strlen(s)
	local pos = 1
	
	local function ReadValue()
		while pos <= n and strfind(strsub(s, pos, pos), "%s") do
			pos = pos + 1
		end
		
		if pos > n then error("Empty string") end
		
		local c = strsub(s, pos, pos)
		pos = pos + 1
		
		if c == "n" then
			return nil
		elseif c == "t" then
			return true
		elseif c == "f" then
			return false
		elseif c == "{" then
			local tbl = {}
			local numkey = 0
			local key
			while pos <= n do
				while pos <= n and strfind(strsub(s, pos, pos), "%s") do
					pos = pos + 1
				end
				if pos > n then error("Missing closing brace") end
				if strsub(s, pos, pos) == "}" then
					pos = pos + 1
					break
				end
				if strsub(s, pos, pos) ~= "[" then
					key = ReadValue()
				else
					pos = pos + 1
					key = ReadValue()
					if strsub(s, pos, pos) ~= "]" then error("Missing ]") end
					pos = pos + 1
				end
				while pos <= n and strfind(strsub(s, pos, pos), "[=%s]") do
					pos = pos + 1
				end
				local val = ReadValue()
				if key then
					tbl[key] = val
				else
					numkey = numkey + 1
					tbl[numkey] = val
				end
				while pos <= n and strfind(strsub(s, pos, pos), "[,%s]") do
					pos = pos + 1
				end
			end
			return tbl
		elseif c == "\"" then
			local i = pos
			repeat
				if i > n then error("Unterminated string") end
			until strfind(strsub(s, i, i), "[^\"]") or i == n
			local str = strsub(s, pos, i-1)
			pos = i + 1
			return str
		else
			local numstr = ""
			while pos <= n and strfind(strsub(s, pos, pos), "[0-9%.%-%+%]") do
				numstr = numstr .. strsub(s, pos, pos)
				pos = pos + 1
			end
			if numstr == "" then
				error("Invalid number at position " .. pos)
			end
			return tonumber(numstr)
		end
	end
	
	local value = ReadValue()
	while pos <= n and strfind(strsub(s, pos, pos), "%s") do
		pos = pos + 1
	end
	if pos <= n then
		error("Trailing characters after serialized table: " .. strsub(s, pos))
	end
	return value
end

-- Detect if string is legacy format (starts with table marker or simple types)
local function IsLegacyFormat(str)
	if not str or strlen(str) == 0 then return false end
	local first = strsub(str, 1, 1)
	-- Legacy format starts with: n (nil), t (true), f (false), " (string), or { (table)
	return first == "n" or first == "t" or first == "f" or first == "\"" or first == "{"
end

--- Deserializes data, supporting both new (^1) and legacy (Questie-X) formats.
-- @param str The serialized data
-- @return true followed by a list of values, OR false followed by an error message
function AceSerializer:Deserialize(str)
	if not str or type(str) ~= "string" then
		return false, "Invalid input: expected a string"
	end
	
	-- Strip whitespace for format detection
	local clean = gsub(str, "[%c ]", "")
	
	-- Check if it's the legacy format (Questie-X style)
	if IsLegacyFormat(clean) then
		local ok, res = pcall(DeserializeLegacy, clean)
		if ok then return true, res
		else return false, res
		end
	end
	
	-- New format detection
	local iter = gmatch(clean, "(^.)([^^]*)")
	local ctl,data = iter()
	if not ctl or ctl ~= "^1" then
		return false, "Supplied data is not AceSerializer data (rev 1)"
	end

	return pcall(DeserializeValue, iter)
end

-- Legacy serialization for compatibility
local function LegacySerialize(t)
	if type(t) ~= "table" then
		error("Usage: AceSerializer:Serialize(tbl): tbl must be a table, got " .. type(t), 2)
	end
	local s = {}
	SerializeValueLegacy(t, s, 0)
	return strjoin("", s)
end

------------------------------------------
-- Base64 Encoding for SerializeForPrint
------------------------------------------

local b64 = {
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	"abcdefghijklmnopqrstuvwxyz",
	"0123456789+/",
}

local function EncodeString(str)
	local encoded = ""
	for i = 1, strlen(str), 3 do
		local b1, b2, b3 = strbyte(str, i, i+2)
		if not b3 then
			b3 = 0
		end
		if not b2 then
			b2 = 0
		end
		local n = b1 * 256 + b2 * 256 + b3
		local e1, e2, e3, e4 = (n/4)%64, (n/4)%64, (n/4)%64, n%64
		encoded = encoded .. strsub(b64[1], e1, e1) .. strsub(b64[1], e2, e2) .. strsub(b64[3], e3, e3) .. strsub(b64[3], e4, e4)
	end
	return encoded
end

local function DecodeString(str)
	local decoded = ""
	str = gsub(str, "%s", "")
	local len = strlen(str)
	local i = 1
	while i <= len do
		local e1, e2, e3, e4 = strfind(str, "(.)(.)(.?)(.?)", i)
		if not e1 then error("Invalid string") end
		local n = (strfind(b64[1], e1) - 1) * 64 + (strfind(b64[1], e2) - 1)
		n = n * 64 + (strfind(b64[3], e3) - 1)
		n = n * 64 + (strfind(b64[3], e4) - 1)
		decoded = decoded .. strchar(n/256, n%256)
		if e4 == "=" then
			decoded = strsub(decoded, 1, -2)
		elseif e3 == "=" then
			decoded = strsub(decoded, 1, -3)
		end
		i = e4 + 1
	end
	return decoded
end

--- Serializes a value for print output (base64 encoded).
-- @param val The value to serialize
-- @return Base64 encoded string
function AceSerializer:SerializeForPrint(val)
	return EncodeString(LegacySerialize(val))
end

--- Deserializes a value from print output.
-- @param str Base64 encoded string
-- @return The deserialized value, or nil,error on failure
function AceSerializer:DeserializeFromPrint(str)
	local success, val = pcall(DeserializeLegacy, DecodeString(str))
	if success then
		return val
	end
	return nil, "Invalid serialization string"
end

------------------------------------------
-- Base library stuff
------------------------------------------

AceSerializer.internals = {	-- for test scripts
	SerializeValue = SerializeValue,
	SerializeStringHelper = SerializeStringHelper,
}

local mixins = {
	"Serialize",
	"Deserialize",
	"SerializeForPrint",
	"DeserializeFromPrint",
}

AceSerializer.embeds = AceSerializer.embeds or {}

function AceSerializer:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

-- Update embeds
for target, v in pairs(AceSerializer.embeds) do
	AceSerializer:Embed(target)
end