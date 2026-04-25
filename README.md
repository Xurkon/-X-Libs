# !X-Libs

<div align="center">

![!X-Libs Banner](https://raw.githubusercontent.com/Xurkon/-X-Libs/main/.github/banner.svg)

**The ultimate shared library hub for World of Warcraft addons**

*A curated collection of battle-tested libraries — Ace3, oUF, and 80+ dependencies — bundled into one self-contained addon*

[![Lua 5.1+](https://img.shields.io/badge/Lua-5.1%2B-blue?style=flat-square)](https://www.lua.org/)
[![WoW 3.3.5a+](https://img.shields.io/badge/WoW-3.3.5a%2B-green?style=flat-square)](https://warcraft.fandom.com/wiki/World_of_Warcraft)
[![Retail Ready](https://img.shields.io/badge/Retail-Ready-purple?style=flat-square)](https://warcraft.fandom.com/wiki/World_of_Warcraft:_Shadowlands)
[![License](https://img.shields.io/badge/License-MIT-orange?style=flat-square)](#license)

</div>

---

## Why !X-Libs?

Most WoW addons ship with their own copies of Ace3, LibStub, and other dependencies. This means:

- **Duplicate libraries** — the same code loaded 10 times in your addon list
- **Version conflicts** — addon A needs AceDB 3.0, addon B needs AceDB 3.1
- **Memory bloat** — hundreds of KBs wasted across redundant library copies

**!X-Libs solves this.** Load it once, use it everywhere. All addons in your `AddOns` folder automatically use the same shared library instances — no more conflicts, no more bloat.

```
┌─────────────────────────────────────────────────────────┐
│                    WITHOUT !X-Libs                       │
├─────────────────────────────────────────────────────────┤
│  ElvUI_Enhanced    → Ace3 + LibStub + 6 other libs     │
│  Questie-X         → Ace3 + LibStub + 9 other libs     │
│  PE-ElvUI          → Ace3 + LibStub + 6 other libs     │
│  Bartender4        → Ace3 + LibStub + 4 other libs     │
│                                                         │
│  Total: ~25 duplicate library loads                    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    WITH !X-Libs                         │
├─────────────────────────────────────────────────────────┤
│  !X-Libs           → ALL libraries (loaded once)       │
│  ElvUI_Enhanced    → uses !X-Libs                      │
│  Questie-X         → uses !X-Libs                      │
│  PE-ElvUI          → uses !X-Libs                      │
│  Bartender4        → uses !X-Libs                      │
│                                                         │
│  Total: 1 library load, everything shares              │
└─────────────────────────────────────────────────────────┘
```

---

## What's Included

### Ace3 Framework
| Library | Version | Description |
|---------|---------|-------------|
| AceAddon-3.0 | 3.3.1 | Addon framework with module support |
| AceConsole-3.0 | 3.3.1 | Chat command handling |
| AceDB-3.0 | 3.3.1 | Profile &SavedVariables management |
| AceDBOptions-3.0 | 3.3.1 | Default options UI for profiles |
| AceEvent-3.0 | 3.3.1 | Event handling & dispatching |
| AceHook-3.0 | 3.3.1 | Secure hooking framework |
| AceTimer-3.0 | 3.3.1 | Scheduled callback timers |
| AceBucket-3.0 | 3.3.1 | Throttled event batching |
| AceSerializer-3.0 | 3.3.1 | Table serialization |
| AceComm-3.0 | 3.3.1 | Chat channel communication |
| AceTab-3.0 | 3.3.1 | Tab-completion framework |
| AceConfig-3.0 | 3.3.1 | Configuration system |
| AceGUI-3.0 | 3.3.1 | GUI widget toolkit |

### oUF Framework
| Library | Description |
|---------|-------------|
| oUF | Unified Unit Frame framework |
| oUF_Plugins | Common unit frame plugins (auras, indicators, etc.) |

### Data Libraries
| Library | Description |
|---------|-------------|
| LibStub | Library registry / version negotiation |
| CallbackHandler-1.0 | Event callback management |
| LibBabble-3.0 + modules | Localization (factions, zones, creatures...) |
| LibTourist-3.0 | Zone & continent information |
| LibCandyBar-3.0 | Cooldown timer bars |
| LibDataBroker-1.1 | Data broker plugin interface |
| LibDBIcon-1.0 | Broker minimap icons |
| LibSink-2.0 | Output routing (chat, MSBT, etc.) |
| LibQTip-1.0 | Tooltip generation |
| LibItemSearch-1.2 | Item search & filtering |
| LibSpellRange-1.0 | Spell range checking |
| LibRangeCheck-2.0 | Distance-based range checking |
| LibTaxi-1.0 | Taxi node information |

### UI & Graphics
| Library | Description |
|---------|-------------|
| LibSimpleSticky | Frame dragging & snapping |
| LibWindow-1.1 | Window persistence |
| LibCustomGlow-1.0 | Custom glow effects |
| LibAnim | Animation utilities |
| Masque | Button skinning engine |
| LibGraph-2.0 | Graphing library |
| ArkDewdrop | Dropdown menu system |
| LibAboutPanel | About panel mixin |

### Compatibility
| Library | Description |
|---------|-------------|
| Compat-335.lua | Wrath 3.3.5 compatibility shims |
| Compat-Lua.lua | Lua version compatibility |
| TaintLess | Taint prevention utilities |
| HereBeDragons | World coordinate API |
| Astrolabe | Map & minimap library |
| LibDispel | Dispel/buff type detection |

*(80+ libraries total — see `Libs.xml` for the complete list)*

---

## Installation

### Option 1 — Standalone (Recommended)
1. Download the latest `!X-Libs.zip` from [Releases](https://github.com/Xurkon/-X-Libs/releases)
2. Extract into `World of Warcraft/_retail_/Interface/AddOns/!X-Libs/`
3. **All other addons** that support !X-Libs will automatically use its libraries

### Option 2 — Embedded
For addons that bundle their own copy of these libraries, delete the embedded copies and let them use !X-Libs instead.

---

## Compatibility

| WoW Version | Status |
|-------------|--------|
| Retail (Shadowlands / Dragonflight) | ✅ Full |
| Wrath of the Lich King 3.3.5a | ✅ Full |
| The Burning Crusade Classic | ✅ Full |
| Classic Era | ✅ Full |

All libraries are designed for **Lua 5.1+** and make zero assumptions about the WoW API beyond what the minimum supported version provides.

---

## Features

- **Zero configuration** — just load and it works
- **Standalone** — no other addons required
- **Self-contained** — all libraries in one folder, one TOC
- **Battle-tested** — used in production on active private servers
- **Version-safe** — LibStub's built-in version negotiation prevents conflicts
- **WotLK compatible** — ships with `Compat-335.lua` for Wrath-specific API gaps

---

## Supported Addons

These addons are verified to work with !X-Libs:

- **Questie-X** — Modern quest tracker for Retail/WotLK
- **PE-ElvUI** — Enhanced UI plugin suite
- **ElvUI_Enhanced** — UI enhancement modules
- **ElvUI_AddOnSkins** — Addon skinning for ElvUI

*More addons are compatible — if your addon uses Ace3 or LibStub, it can use !X-Libs.*

---

## License

All original code in this repository is **MIT Licensed**.

Individual libraries retain their original licenses. See each library's respective folder for details.

---

<div align="center">

**!X-Libs** — *One addon to load them all*

[GitHub](https://github.com/Xurkon/-X-Libs) · [Issues](https://github.com/Xurkon/-X-Libs/issues)

</div>
