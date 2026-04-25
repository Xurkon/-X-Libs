# X-Libs Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed
- **README overhaul**: Complete rewrite emphasizing !X-Libs as a universal library framework for all WoW versions (Retail, Wrath, TBC, Classic). Added version compatibility table, generic install path (`\<WoW>\Interface\AddOns\!X-Libs\`), library tables organized by category.
- **Banner removed**: `.github/banner.svg` removed from repo — assets belong in a separate assets repo.

### Removed
- **Dev/agent files**: `.kilo/` (agent worktree/session artifacts), `CLAUDE.md` (agent instructions), `fix_libs.py` (dev helper script), tracked `.kilo/package-lock.json`.
- **Tracked `.github/`**: Removed from index, directory deleted locally.

### Added
- **`.gitignore`**: Added from Questie-X pattern — ignores `.kilo/`, `.github/`, `node_modules/`, `*.py`, `*.ps1`, `*.log`, `*.zip`, `coords.lua`, `debug.lua`, `CLAUDE.md`, and other dev artifacts.

## [1.11] - 2026-04-19
### Fixed
- **AceLocale GetLocale API**: Fixed `GetLocale(application, locale, silent)` signature — `locale` was being silently dropped because the function only accepted `(application, silent)`. Now properly returns the locale-specific table from `AceLocale.apps[application][locale]` instead of the entire app table.
- **AceLocale NewLocale registration**: Fixed `registering = app` (entire app) to `registering = app[locale]` so proxy writes go to the correct locale table.
- **AceLocale early return path**: Fixed indentation of the early-return block so the `AceLocale-3.0-ElvUI` alias registration actually executes when a higher minor AceLocale already exists.
- **Compat-335 Timer Consolidation**: Removed the duplicate early `C_Timer` shim so the later full implementation is the single active compatibility layer, preventing partial timer initialization where `After` existed but `NewTimer`/`NewTicker` could still be missing.
- **Compat-335 Memory Pressure**: Reworked timer storage from ever-increasing numeric IDs to timer-object keys, which prevents the timer table from growing into a large sparse structure under heavy retry scheduling and resolves `memory allocation error: block too big` failures.
- **Compat-335 Timer Validation**: Hardened `C_Timer.After` and `C_Timer.NewTicker` to ignore non-function callbacks and clamp very small delays to a safe minimum, reducing zero-delay retry storms from addon compatibility shims.
- **Compat-335 Ticker Cancellation**: Fixed finite ticker shutdown so `NewTicker(..., iterations)` stops cleanly once the callback removes its timer instead of being re-armed by the same update tick.

## [1.10] - 2026-04-11
### Fixed
- **oUF Library Registration**: X-Libs now correctly registers `oUF` via `LibStub:AddLib("oUF", nil, ns.oUF, minor)` in `oUF/init.lua` `finalize.lua`. This ensures ElvUI and its plugins can locate oUF through `LibStub("oUF")` instead of relying on the global `_G.oUF`.
- **ElvUI oUF Integration Fix**: Changed `Engine.oUF = Engine[2]` (empty table) in ElvUI `Init.lua` to first check if `oUF` is already registered via `LibStub:GetLibrary("oUF", true)`, and fall back to `_G.oUF`. This allows X-Libs' oUF (with `oUF.Tags`, `oUF.colors`, and all elements) to be used by ElvUI instead of an empty table.

## [1.9] - 2026-04-05
### Added
- **Forced Library Seniority**: Escalated `MINOR` versioning to **1,000,000** for all core Ace3 and shared libraries to ensure absolute priority over bundled addon dependencies.
- **Robust API Shimming**: Refactored the `C_QuestLog` compatibility layer in `Compat-335.lua` to use a per-function conditional assignment pattern, ensuring shims remain active even if partial namespaces exist.
- **Fail-Safe Dispatchers**: Integrated `safecall` dispatcher patterns into `AceGUI-3.0`, `AceBucket-3.0`, and `AceTimer-3.0` to protect the initialization chain on legacy 3.3.5a clients.
- **Universal Hardening**: Standardized global namespace protection and error handling across the entire 80+ library suite.

## [1.8] - 2026-04-03

### AceGUI-3.0 & AceConfigDialog Comprehensive Replacement

- **Complete AceGUI-3.0 Library**: Replaced the entire AceGUI-3.0.lua and all 22 widget files with working versions from Questie-X. This comprehensive replacement fixes numerous missing methods and broken functionality that was causing multiple errors in Questie, ArkInventory, and other addons.

- **Complete AceConfigDialog-3.0 Replacement**: Replaced AceConfigDialog with Questie-X version 85 (from version 99) for full compatibility with the AceGUI-3.0 changes.

- **Complete AceConfigRegistry-3.0 Replacement**: Replaced AceConfigRegistry with Questie-X version 20 (from version 99) for full compatibility.

- **AceSerializer Dual-Format Support**: Added legacy format (Questie-X v1) deserialization as a fallback to maintain universal compatibility. The `Deserialize` function now auto-detects format (new `^1` format vs legacy `{` format) and routes accordingly. Also added `SerializeForPrint` and `DeserializeFromPrint` functions from Questie-X for base64 encoded serialization output.

- **Fixed Issues**: Layout crashes, SetUserData/GetUserData nil errors, Focus management functions, Widget counters, Case-insensitive layout names, RegisterAsWidget return values and userdata initialization, widget nil errors in callback chains, SetDefaultSize and AddToBlizOptions errors.

- **Universal BACKDROP_TEMPLATE Fallback**: Added consistent `BACKDROP_TEMPLATE` pattern to all widgets for proper Retail/Classic/WotLK/TBC compatibility:
  - `AceGUIContainer-Frame.lua`
  - `AceGUIContainer-TabGroup.lua`
  - `AceGUIContainer-DropDownGroup.lua`
  - `AceGUIContainer-InlineGroup.lua`
  - `AceGUIContainer-TreeGroup.lua`
  - `AceGUIWidget-DropDown.lua`
  - `AceGUIWidget-Keybinding.lua`
  - `AceGUIWidget-MultiLineEditBox.lua`
  - `AceGUIWidget-Slider.lua`

- **RULES.md Created**: Added development rules file documenting merge policies, universal compatibility requirements, and testing workflows.

## [1.7] - 2026-04-03

### AceGUI-3.0 Container Widget Constructor Fix

- **Container Widget Return Value Fix**: Changed all 9 container widget constructors from `return AceGUI:RegisterAsContainer(widget)` to the correct two-line pattern:
  ```lua
  AceGUI:RegisterAsContainer(widget)
  return widget
  ```
  The `RegisterAsContainer` function does not return a value - it modifies the widget in place. The old pattern caused "attempt to index local 'newObj' (a nil value)" errors in Questie-X, ArkInventory, Mapster, and other addons.
  
- **RegisterAsContainer Return Value**: Also fixed the core `AceGUI:RegisterAsContainer()` function to return the widget after registering, to match standard AceGUI behavior.
  
- **Missing Layouts Registered**: Added the "List", "Fill", and "Flow" layout handlers that were missing from `AceGUI-3.0.lua`. ArkInventory and other addons rely on `SetLayout("List")` which was erroring with "The Layout 'List' is not registered with AceGUI-3.0".
  
- **Fixed widgets**:
  - AceGUIContainer-BlizOptionsGroup.lua
  - AceGUIContainer-DropDownGroup.lua
  - AceGUIContainer-Frame.lua
  - AceGUIContainer-InlineGroup.lua
  - AceGUIContainer-ScrollFrame.lua
  - AceGUIContainer-SimpleGroup.lua
  - AceGUIContainer-TabGroup.lua
  - AceGUIContainer-TreeGroup.lua
  - AceGUIContainer-Window.lua

## [1.6] - 2026-04-02

### Ace3 & UI Framework Optimization (Phase 6)

- **AceGUI-3.0 Container Enhancements**:
  - **`SetDefaultSize(width, height)`**: Implemented this missing method in both `AceGUIContainer-Frame.lua` and `AceGUIContainer-Window.lua`. This resolves "nil index" crashes in `ArkInventory` and other modern addons expecting Retail-style AceGUI functionality.
  - **Frame Restoration**: Repaired corrupted `methods` and `Backdrop` tables in the `Frame` container to ensure structural integrity.
  - **Widget Constructor Nil Guard**: Added error handling when widget constructors return nil. This resolves "attempt to index local 'newObj' (a nil value)" crashes in Questie, ArkInventory, Mapster, and other addons that use `AceGUI:Create("Frame")`.
  - **Global AceGUI Reference**: Set `_G.AceGUI = AceGUI` after library creation to ensure widgets that reference `AceGUI` via `_G` get the correct (newest) library instance.
- **LibDBIcon-1.0 Hardening**:
  - **Initialization Safeguards**: Ensured `lib.objects`, `lib.radius`, `lib.notCreated`, and `lib.callbacks` are initialized immediately upon library creation. This prevents runtime errors during the library upgrade/load cycle (e.g., "for generator" table expected or nil index in `Register`).
- **AceAddon-3.0 Defensive Checks**:
  - Added safety guards to `InitializeAddon` and `EnableAddon` to prevent "self is nil" crashes during complex addon boot sequences (e.g., ElvUI, Mapster).
- **Global Compatibility Layer (`Compat-335.lua`)**:
  - **Syntax Repair**: Fixed multiple Lua syntax errors caused by reserved keywords (`event.end` → `event["end"]`) in `C_Calendar` and event handling logic.
  - **Consolidated `CreateFrame`**: Merged multiple conflicting `CreateFrame` shims into a single, robust implementation. It now handles both string and table template arguments and strips all Retail-only templates (`BackdropTemplate`, `DialogBorderOpaqueTemplate`, `TooltipBackdropTemplate`).
  - **Missing API Shims**:
    - **`C_Map` Namespace**: Implemented `C_Map.GetBestMapForUnit` and `C_Map.GetMapInfo` to satisfy `HereBeDragons-2.0` and `LibRover-1.0` requirements on the 3.3.5a client.
    - **`IsPlayerSpell`**: Added a global shim for `IsPlayerSpell` using `GetSpellInfo` check for `LibDispel` compatibility.
    - **`C_ChatInfo`**: Secured `RegisterAddonMessagePrefix` mapping for `AceComm-3.0` and `DetailsFramework`.

## [1.5] - 2026-04-02

### Library Stabilization & API Backporting

- **Universal API Polyfills**:
  - **`math.mod`**: Added a `math.fmod` polyfill to `LibDeflate.lua` for Lua 5.1+ compatibility.
  - **`CreateFromMixins` & MapCanvas**: Shimmed modern mixin patterns in `HereBeDragons-Pins-2.0.lua` to support legacy Retail-style map logic on 3.3.5a.
  - **`CreateTexturePool` & `CreateFramePool`**: Implemented universal object pooling in `LibCustomGlow-1.0.lua`.
  - **`WorldMapFrame:GetCanvas()`**: Added defensive shim for Retail-style canvas access on WotLK maps.
- **Critical Dependency Embedding**:
  - Embedded **`LibDataBroker-1.1`** into `LibDBIcon-1.0.lua` to resolve persistent "missing dependency" errors without modifying addon-level XML manifests.
  - Embedded **`DongleStub`** and **`AstrolabeMapMonitor`** into `Astrolabe.lua` to ensure self-contained initialization.
- **Namespace & Engine Hardening**:
  - **`C_QuestLog` & `C_SpellBook`**: Added global shims in `Compat-Lua.lua` to map modern query methods to legacy 3.3.5a equivalents.
  - **ElvUI Engine Proxy**: Hardened the `ElvUI` presence in `Compat-Lua.lua` and `LibElvUIPlugin-1.0.lua` using a recursive dummy metatable (`__index = function(t, k) return t end`). This prevents crashes in early-loading modules that attempt to unpack or index the engine before it's fully initialized.
- **Bug Fixes**:
  - **`LibTaxi-1.0`**: Resolved nil-index error on `C_QuestLog` in `data.lua`.
  - **`LibRover-1.0`**: Fixed initialization failure chain caused by missing `LibTaxi-1.0` dependency.

## [1.4] - 2026-04-02

### Critical Fixes & Hardening

- **Comprehensive Library Version Dominance (99 Strategy)**:
  - Systematically bumped the `MINOR` version of nearly all core libraries to **99** (or higher, e.g., **999** for `LibCandyBar-3.0`/`Astrolabe`, **99999** for `LibSink-2.0`/`LibTourist-3.0`).
  - **Bumped Libraries**: `LibElvUIPlugin-1.0`, `AceDB-3.0`, `AceDBOptions-3.0`, `AceGUI-3.0`, `AceLocale-3.0`, `AceTimer-3.0`, `AceComm-3.0`, `CallbackHandler-1.0`, `LibBabble-3.0`, `LibBabble-Zone-3.0`, `HereBeDragons-2.0`, `HereBeDragons-Pins-2.0`, `LibSharedMedia-3.0`, `LibDataBroker-1.1`, `LibDBIcon-1.0`, `LibCandyBar-3.0`, `LibSink-2.0`, `LibTourist-3.0`, `LibQTip-1.0`, and `Astrolabe`.
  - This guarantees `!X-Libs` dominance over all embedded copies in the environment, ensuring our 3.3.5a-optimized patches are always active.
- **LibElvUIPlugin-1.0 "Engine Proxy" Hardening**:
  - Implemented a defensive proxy layer for the `ElvUI` engine object (`E`).
  - Added dummy metatable protection for `E.db`, `E.global`, `E.private`, `E.Options`, and `E.Toolkit`.
  - When accessed before the main engine is ready, these fields now return a safe "proxy" table that accepts all indices, preventing `nil`-index crashes in early-loading plugins (e.g., `ElvUI_ExtraActionBars`, `ElvUI_DataTextColors`).
- **Universal Compatibility Layer Expansion**:
  - Added critical API shims to `Compat-Lua.lua` and `Compat-335.lua`:
    - `tInvert`: Resolves `Archivist` initialization errors.
    - `securecallfunction`: Hardened fallback for `CallbackHandler-1.0`.
    - `Ambiguate`: Universal visibility for name resolution.
    - `RegisterAddonMessagePrefix`: Stubbed for WotLK to prevent `AceComm-3.0` crashes.
    - `C_CVar`: Stubbed to resolve `LibDispel` compatibility issues.
    - `IsSpellKnownOrOverridesKnown`: Backported for modern library support.
- **AceLocale-3.0 Persistence Fix**:
  - Patched `NewLocale` to be lenient with the `silent` flag. Instead of erroring when a "silent" registration follows a "non-silent" one, it now automatically upgrades the app to use the silent metatable.
  - This specifically resolves the `ArkInventory` initialization crash.
- **AceTimer-3.0 Robustness**:
  - Added type-checking to the `OnUpdate` loop in the `C_Timer.After` polyfill to prevent comparison errors with corrupted timer data.

## [1.3] - 2026-04-02

### Initialization & Stability Hardening

- **Global Polyfill Visibility**: Refactored `Compat-335.lua` to use explicit `_G` assignments for critical polyfills (`securecallfunction`, `Ambiguate`, `table.wipe`, etc.). This ensures that libraries capturing these as locals during early boot (before the standard environment is fully populated) successfully resolve them.
- **LibElvUIPlugin-1.0 Race Condition Fix**:
  - Implemented a robust deferred registration system. Plugins that load before `ElvUI` or before `E.global` is initialized now automatically queue their registration until `ElvUI:Initialize` completes.
  - Added comprehensive nil-checks for `E.global.general` to prevent "attempt to index field 'global' (a nil value)" errors during early addon loading.
  - Enhanced `HookInitialize` to safely handle missing table objects and wait for the `ElvUI` addon to load if it's not yet present.
- **CallbackHandler-1.0 Resiliency**: Added a robust fallback chain for `securecallfunction` (`_G.securecallfunction` -> `_G.securecall` -> pass-through). This prevents "attempt to call upvalue 'securecallfunction' (a nil value)" crashes in scenarios where the compatibility layer hasn't initialized or the environment lacks the API.
- **Improved ElvUI Detection**: Updated detection logic to support `ElvUI` backports that may use non-standard naming or delayed table population.

## [1.2] - 2026-04-01

### Load Order Optimization

- **Folder Rename**: Renamed `X-Libs` → `!X-Libs` in source and installation to trigger early load order.
- **TOC Update**: Renamed `X-Libs.toc` → `!X-Libs.toc` to match new folder identity.
- **Dependency fix**: Ensures `LibStub` is globally available before `BugSack` and other addons initialize.
- **Embedded Load Order Protection**: Explicitly mapped `Compat-Lua.lua` and `Compat-335.lua` to the top of `Libs.xml`. This structural fix guarantees that compatibility polyfills deploy first universally, eliminating crash scenarios when external addons inject libraries directly via their own XML files.

### 3.3.5 compatibility (WotLK)

- **Core Namespace Polyfills**: Added missing global API shims to `Compat-335.lua`, including `table.wipe`, `Ambiguate`, `securecallfunction` (with robust standard `pcall` catching tracing to `geterrorhandler`), `GetCurrentRegion`, and `GetCurrentRegionName`. This addresses terminal UI crashes (e.g., `attempt to call upvalue 'securecallfunction'`, `attempt to index field 'global'/'db'`) effectively stabilizing `AceDB-3.0` & `CallbackHandler-1.0` load environments for embedding systems like `ElvUI` and `Mapster`.
- **XP_IsWOTLK Fix**: Updated detection logic in `Compat-Lua.lua` to use `tocversion` instead of build numbers for reliable expansion identification.
- **AceConfigDialog Shim**: Added `AddToBlizOptions` legacy bridge in `Compat-335.lua`. Fixes nil value crashes in addons (like Questie-X) attempting to register options panels on WotLK.
- **AceGUI Widgets**: Enhanced `BackdropTemplate` detection to use `BackdropTemplateMixin` for better cross-expansion stability.

### Library Patches

- **LibGraph-2.0**: Fixed a malformed string constant breaking framework registration logic (reverted `"LibGraph-2.0-Z"` declaration string to `"LibGraph-2.0"`).

## [1.1] - 2026-03-31

### Questie-X Integration

- Removed redundant library loads from Questie-X.toc (LibStub, embeds.xml, XXH_Lua_Lib)
- Stripped Questie-X\Compat\embeds.xml to only load Questie's own compat files
- Deleted Questie-X\Compat\Libs folder (redundant - now uses X-Libs)
- Added X-Libs as RequiredDeps in Questie-X.toc
- Fixed C_Timer.NewTicker check in QuestieCompat.lua (`if C_Timer and C_Timer.NewTicker`)

### Universal Library Backporting (2026-03-31)

#### AceGUI-3.0 BackdropTemplate Universal Fix

- **Problem**: Retail AceGUI uses BackdropTemplate which doesn't exist until MoP. CreateFrame fails on WotLK with "Couldn't find inherited node 'BackdropTemplate'".
- **Solution**: Moved BACKDROP_TEMPLATE declaration BEFORE CreateFrame upvalue capture in all widgets
- **Pattern**: `local BACKDROP_TEMPLATE = (XP_IsWOTLK or not _G.BackdropTemplate) and nil or "BackdropTemplate"`
- **Fixed widgets** (9 files):
  - AceGUIContainer-Frame.lua
  - AceGUIWidget-Slider.lua
  - AceGUIWidget-Keybinding.lua
  - AceGUIWidget-MultiLineEditBox.lua
  - AceGUIWidget-DropDown.lua
  - AceGUIContainer-TreeGroup.lua
  - AceGUIContainer-TabGroup.lua
  - AceGUIContainer-DropDownGroup.lua
  - AceGUIContainer-InlineGroup.lua

#### Ace Library Version Upgrade Fix (12 libraries)

- **Problem**: When LibStub:NewLibrary() returns nil (older version exists), library code would `return end` early without initializing required fields.
- **Solution**: Fetch existing library and continue initialization
- **Pattern**:

```lua
if not AceXxx then
    AceXxx = LibStub:GetLibrary(MAJOR, true)
    if not AceXxx then return end
end
```

- **Fixed libraries**: AceAddon-3.0, AceEvent-3.0, AceTimer-3.0, AceHook-3.0, AceDB-3.0, AceDBOptions-3.0, AceConsole-3.0, AceSerializer-3.0, AceBucket-3.0, AceComm-3.0, AceLocale-3.0, AceTab-3.0

#### AceConfigDialog Enhancement

- Initializes BlizOptions, BlizOptionsIDMap, OpenFrames, Status regardless of version
- Conditionally defines AddToBlizOptions only if missing (backward compatible)

#### Settings API Shim for WotLK

- **Problem**: Retail AceConfigDialog uses Settings.GetCategory, Settings.RegisterCanvasLayoutCategory, Settings.RegisterCanvasLayoutSubcategory which don't exist on WotLK.
- **Solution**: Added comprehensive Settings API shim in Compat-335.lua
- **Implemented**:
  - `Settings.GetCategory(categoryID)` - retrieves registered category by ID or name
  - `Settings.RegisterCanvasLayoutCategory(frame, name)` - creates category and registers via InterfaceOptions_AddCategory
  - `Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, name)` - creates subcategory (WotLK limitation: no hierarchy, returns flat category)
  - `Settings.RegisterAddOnCategory(category)` - enhanced to use category.name/ID for InterfaceOptions_AddCategory
  - Internal tracking via settingsCategoryMap for later retrieval

#### C_Timer.NewTicker Fix

- **Problem**: QuestieCompat checked `if C_Timer then` but C_Timer exists on WotLK without NewTicker
- **Fix**: Changed to `if C_Timer and C_Timer.NewTicker`

## [1.0] - 2026-03-30

### Added

#### Core Ace3 Libraries (Retail Latest - from WoWUIDev/Ace3 - Updated 2026-03-30)

| Library | Description |
| ------- | ----------- |
| LibStub | Library version negotiation |
| CallbackHandler-1.0 | Event callback management |
| AceAddon-3.0 | Addon framework |
| AceEvent-3.0 | Event registration and dispatch |
| AceTimer-3.0 | Timer scheduling (universal fallback for non-Retail) |
| AceDB-3.0 | Database with profile management |
| AceDBOptions-3.0 | Database options UI |
| AceConsole-3.0 | Slash command registration |
| AceSerializer-3.0 | Serialization |
| AceBucket-3.0 | Event bucketing |
| AceHook-3.0 | Secure hooking |
| AceLocale-3.0 | Localization |
| AceTab-3.0 | Tab completion |
| AceComm-3.0 | Communication with ChatThrottleLib |
| AceGUI-3.0 | GUI framework with all 24 widgets |
| AceConfig-3.0 | Configuration system |
| AceConfigCmd-3.0 | Config command handling |
| AceConfigDialog-3.0 | Config dialog UI |
| AceConfigRegistry-3.0 | Config registry |

#### Map & Navigation Libraries

| Library | Source | Description |
| ------- | ------ | ----------- |
| HereBeDragons | Nevcairiel (updated) | Map coordinates API - Added FixPhasedContinents(), GetDirectionToIcon(), GetDistanceToIcon() |
| Astrolabe | TomTom | Map library |
| LibTaxi-1.0 | X-Plore | Taxi node data |
| LibRover-1.0 | X-Plore | Pathfinding |
| LibTourist-3.0 | Cromulent | Zone information |

#### LibBabble Locale Libraries

| Library | Description |
| ------- | ----------- |
| LibBabble-3.0 | LibBabble base library |
| LibBabble-SubZone-3.0 | Sub-zone names |
| LibBabble-Faction-3.0 | Faction names |
| LibBabble-Zone-3.0 | Zone names |
| LibBabble-CreatureType-3.0 | Creature type names |
| LibBabble-Boss-3.0 | Boss names |
| LibBabble-Inventory-3.0 | Inventory item type names |
| LibAboutPanel | About panel UI |

#### UI & Visual Libraries

| Library | Source | Description |
| ------- | ------ | ----------- |
| LibCustomGlow-1.0 | WeakAuras | Custom glow effects |
| LibGetFrame-1.0 | WeakAuras | Frame utilities |
| LibRangeCheck-2.0 | WeakAuras | Range checking |
| LibSpellRange-1.0 | WeakAuras | Spell range checking |
| LibSharedMedia-3.0 | **SVN trunk (wowace-clone)** | Fonts, textures, sounds - v8.2.0 v3 |
| LibDBIcon-1.0 | Questie-X | Minimap icon |
| LibDataBroker-1.1 | Questie-X | Data broker |
| LibWindow-1.1 | Details | Window positioning |
| LibDualSpec-1.0 | Masque | Dual spec support |
| LibQTip-1.0 | ActionBarProfiles | Tooltip library |
| LibCandyBar-3.0 | RXPGuidesRETAIL | Cooldown bars |
| AceGUI-3.0-SharedMediaWidgets | Questie-X | SharedMedia widgets |
| UIDropDownFork | X-Plore | Dropdown menu (consolidated folder structure) |
| LibBetterBlizzOptions-1.0 | X-Plore | Blizzard options helper |
| LibGratuity-3.0 | X-Plore | Tooltip parsing |
| LibGraph-2.0 | X-Plore | Graph rendering |

#### Compression & Encoding

| Library | Source | Description |
| ------- | ------ | ----------- |
| LibDeflate | Questie-X | Compression |
| LibCompress | WeakAuras | Compression wrapper |
| LibSerialize | WeakAuras | Serialization |

#### Utility Libraries

| Library | Source | Description |
| ------- | ------ | ----------- |
| LibHash-1.0 | X-Plore | Hash functions |
| LibCamera-1.0 | ZygorGuidesViewerOLD | Camera utilities |
| LibTutorial-1.0 | ZygorGuidesViewerOLD | Tutorial system |
| LibBossIDs-1.0 | Details | Boss ID database |
| LibTranslit | Details | Character transliteration |
| LibTextTable-1.0 | _NPCScan | Text table parsing |
| LibCompat-1.0 | Leatrix_Plus | Compatibility utilities |
| LibDFramework-1.0 | Details | GUI framework with buttons, panels, dropdowns, tooltips |
| **ArkDewdrop** | ArkInventory | Dropdown menu system |
| LibS2kFactionalItems-1.0 | ActionBarProfiles | Fractional items |
| LibS2kMisc-1.0 | ActionBarProfiles | Miscellaneous |
| LibGroupTalents-1.0 | WeakAuras/Leatrix | Talent queries |
| NickTag-1.0 | Details | Nickname tags |
| UTF8 | Details | UTF8 string utilities |
| XXH_Lua_Lib | Questie-X | XXHash implementation |
| LibSink-2.0 | SilverDragon | Chat output |
| Archivist | WeakAuras | Data archiving |
| EasyFork.lua | X-Plore | Utility functions |

#### ElvUI Libraries

| Library | Description |
| ------- | ----------- |
| LibActionButton-1.0 | Action button library |
| LibAnim | Animation library |
| LibAuraInfo-1.0 | Aura info lookup |
| LibBase64-1.0 | Base64 encoding/decoding |
| LibChatAnims | Chat animations |
| LibElvUIPlugin-1.0 | ElvUI plugin framework |
| LibItemSearch-1.2 | Item search functionality |
| LibSimpleSticky | Frame sticky positioning |
| oUF | Unit frame framework |
| oUF_Plugins | oUF plugin utilities |

#### ElvUI Shared Libraries

| Library | Description |
| ------- | ----------- |
| LibAceConfigHelper | AceConfig helper utilities |
| LibDispel | Dispel/aura tracking |
| TaintLess | Taint prevention |

#### Other Libraries

| Library | Source | Description |
| ------- | ------ | ----------- |
| Krowi_WorldMapButtons | Questie-X | World map buttons |

#### Bundled Addons

| Addon | Source | Description |
| ------- | ------ | ----------- |
| **Masque** | SFX-WoW/Masque | Button skinning engine - Includes Core, Options, Skins (Blizzard, Classic, Modern, Dream, etc.), and Locales (10 languages). Uses X-Libs for dependencies. |

### Cleaned Up

- Removed all duplicate nested libraries from within library folders (LibStub, CallbackHandler-1.0 found inside other libraries)
- Libraries now properly reference root-level LibStub and CallbackHandler-1.0
- Cleaned: HereBeDragons, LibBabble-*, LibGraph-2.0, LibGratuity-3.0, LibTourist-3.0, LibTaxi-1.0, LibQTip-1.0, LibSpellRange-1.0, LibCompress, LibSerialize, LibCustomGlow-1.0, LibDualSpec-1.0, LibGroupTalents-1.0, LibDeflate, LibCompat-1.0/Libs, and more
- **UIDropDownFork**: Consolidated from separate file-folders into single folder with files inside
- **HBDragons.lua**: Removed as separate file - its functions (FixPhasedContinents, GetDirectionToIcon, GetDistanceToIcon) merged into HereBeDragons

### Compatibility Features

- **Universal API Detection**: Checks for Retail API first, falls back to legacy globals
- **AceTimer Fallback**: Uses `UIParent.OnUpdate` when `C_Timer.After` is unavailable
- **Version Stubs**: Compatibility layers for WotLK 3.3.5a (Compat-Lua.lua, Compat-335.lua)

### TOC Compatibility

- Interface: 110005 (Retail), 10002 (Retail 10.x), 40400 (WotLK), 30403 (TBC), 30300 (Classic), 11504 (Vanilla)

### Junction Points

This library is designed to be used via folder junctions to multiple WoW installations:
- `C:\Ebonhold\Ebonhold\Interface\AddOns\X-Libs`
- `C:\Ascension\Launcher\resources\ascension-live\Interface\AddOns\X-Libs`
- `C:\Valanior\Interface\AddOns\X-Libs`
- `C:\TurtleWoW\Interface\AddOns\X-Libs`
- `C:\MafWoW\Interface\AddOns\X-Libs`

### Known Issues

- Some libraries may have Retail-only features that require additional backporting
- AceTimer-3.0 fallback uses OnUpdate which is less efficient than C_Timer.After on Retail
- HereBeDragons uses C_Map/C_Minimap APIs (needs backporting for WotLK)

### Future Considerations

Potential additional libraries from WowAce:
- LibDialog-1.0 (static popup replacement)
- LibDurability (durability monitoring)
- LibChatAnims (chat animations)
- LibLatency (latency monitoring)
- LibDDI-1.0 (dropdown items)
- LibAboutPanel-2.0 (about panel)
- LibUIDropDownMenu (official dropdown)

---

**Note**: This library aims to be a comprehensive collection of commonly used WoW addon libraries, universalized for maximum compatibility across game versions.
