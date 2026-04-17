-- $Id: LibStub.lua 103 2014-10-16 03:02:50Z mikk $
-- LibStub is a simple versioning stub meant for use in Libraries.  http://www.wowace.com/addons/libstub/ for more info
-- LibStub is hereby placed in the Public Domain
-- Credits: Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke
local LIBSTUB_MAJOR, LIBSTUB_MINOR = "LibStub", 8  -- NEVER MAKE THIS AN SVN REVISION! IT NEEDS TO BE USABLE IN ALL REPOS!
local LibStub = _G[LIBSTUB_MAJOR]

-- Check to see is this version of the stub is obsolete
if not LibStub or LibStub.minor < LIBSTUB_MINOR then
	LibStub = LibStub or {libs = {}, minors = {} }
	_G[LIBSTUB_MAJOR] = LibStub
	LibStub.minor = LIBSTUB_MINOR

	-- LibStub:NewLibrary(major, minor)
	-- major (string) - the major version of the library
	-- minor (string or number ) - the minor version of the library
	--
	-- returns nil if a newer or same version of the lib is already present
	-- returns empty library object or old library object if upgrade is needed
	function LibStub:NewLibrary(major, minor)
		assert(type(major) == "string", "Bad argument #2 to `NewLibrary' (string expected)")
		minor = assert(tonumber(string.match(minor, "%d+")), "Minor version must either be a number or contain a number.")

		local oldminor = self.minors[major]
		if oldminor and oldminor >= minor then return nil end
		self.minors[major], self.libs[major] = minor, self.libs[major] or {}
		return self.libs[major], oldminor
	end

	-- LibStub:GetLibrary(major, [silent])
	-- major (string) - the major version of the library
	-- silent (boolean) - if true, library is optional, silently return nil if its not found
	--
	-- throws an error if the library can not be found (except silent is set)
	-- returns the library object if found
	function LibStub:GetLibrary(major, silent)
		if not self.libs[major] and not silent then
			error(("Cannot find a library instance of %q."):format(tostring(major)), 2)
		end
		return self.libs[major], self.minors[major]
	end

	-- LibStub:IterateLibraries()
	--
	-- Returns an iterator for the currently registered libraries
	function LibStub:IterateLibraries()
		return pairs(self.libs)
	end

	-- LibStub:AddLib(name, major, lib, minor)
	-- Allows embedding a library table under a different major name in LibStub's registry
	-- Used by libraries that need to expose themselves under multiple major names
	function LibStub:AddLib(name, major, lib, minor)
		assert(type(name) == "string", "Bad argument #2 to `AddLib' (string expected)")
		assert(type(major) == "string", "Bad argument #3 to `AddLib' (string expected)")
		assert(type(lib) == "table", "Bad argument #4 to `AddLib' (table expected)")
		self.libs[major], self.minors[major] = lib, minor or 0
	end

	setmetatable(LibStub, { __call = LibStub.GetLibrary })
end
