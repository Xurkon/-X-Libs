# !X-Libs

**A universal shared-library framework for World of Warcraft addons — running every version from Vanilla to Retail.**

*One addon. All major libraries. Zero vendor lock-in.*

---

## Why it exists

Every WoW addon needs the same building blocks — Ace3, LibStub, tooltip helpers, range checkers, serialization. The industry standard is to embed a copy inside every addon. Load 10 addons, load Ace3 ten times. Version conflicts, duplicate memory, and taint chains follow.

**!X-Libs breaks that pattern.** Load it once and every addon on your system shares the same library instances — no matter who wrote them, no matter what version of WoW you're running.

- Load once, use everywhere — ElvUI plugins, Questie, DBM, BigWigs, and any addon using Ace3 or LibStub
- Universal — works on **Retail, Wrath 3.3.5a, TBC Classic, and Classic Era** simultaneously
- Zero configuration — just load and go
- Battle-tested on active private servers

---

## What it does

```
WoW Client (any version)
└── !X-Libs
    ├── Ace3 (Addon framework: events, timers, hooks, DB, config)
    ├── oUF (Unit frame framework)
    ├── LibStub + CallbackHandler (Library registry)
    ├── LibQTip, LibWindow, LibSimpleSticky (UI primitives)
    ├── LibTourist, LibBabble, AceLocale (Localization)
    ├── LibSpellRange, LibRangeCheck, LibTaxi (Information)
    ├── LibSerialize, LibCompress, LibDeflate (Data)
    ├── LibSharedMedia, Masque (Media & skins)
    ├── HereBeDragons + Astrolabe (Map coordinates)
    ├── Compat-335.lua + Compat-Lua.lua (Version shims)
    └── …and many more
        └── ElvUI_Enhanced (uses shared libs)
        └── Questie-X (uses shared libs)
        └── PE-ElvUI (uses shared libs)
        └── Any addon using Ace3/LibStub
```

---

## Libraries

### Core Framework
| Library | Description |
|---------|-------------|
| AceAddon-3.0 | Addon framework with module support |
| AceConsole-3.0 | Chat command handling |
| AceDB-3.0 | Profile & SavedVariables management |
| AceDBOptions-3.0 | Default options UI for profiles |
| AceEvent-3.0 | Event handling & dispatching |
| AceHook-3.0 | Secure hooking framework |
| AceTimer-3.0 | Scheduled callback timers |
| AceBucket-3.0 | Throttled event batching |
| AceSerializer-3.0 | Table serialization |
| AceComm-3.0 | Chat channel communication |
| AceTab-3.0 | Tab-completion framework |
| AceConfig-3.0 | Configuration system |
| AceGUI-3.0 | GUI widget toolkit |

### Unit Frames
| Library | Description |
|---------|-------------|
| oUF | Unified unit frame framework |
| oUF_Plugins | Common plugins (auras, indicators, etc.) |

### Library Infrastructure
| Library | Description |
|---------|-------------|
| LibStub | Library registry & version negotiation |
| CallbackHandler-1.0 | Event callback management |

### UI Primitives
| Library | Description |
|---------|-------------|
| LibQTip-1.0 | Tooltip generation |
| LibWindow-1.1 | Window persistence |
| LibSimpleSticky | Frame dragging & snapping |
| LibCustomGlow-1.0 | Custom glow effects |
| Masque | Button skinning engine |
| ArkDewdrop | Dropdown menu system |
| UIDropDownFork | Dropdown menu fork |

### Data & Broker
| Library | Description |
|---------|-------------|
| LibSerialize | Table serialization |
| LibCompress | Compression |
| LibDeflate | Deflate compression |
| LibBase64-1.0 | Base64 encoding |
| LibDBIcon-1.0 | Minimap icon broker |
| LibDataBroker-1.1 | Addon data broker |
| LibSink-2.0 | Output routing |
| LibItemSearch-1.2 | Item search & filtering |

### Localization
| Library | Description |
|---------|-------------|
| AceLocale-3.0 | Locale management |
| LibBabble-3.0 | Boss, CreatureType, Faction, Inventory, SubZone, Zone |
| LibTourist-3.0 | Zone & continent information |

### Information
| Library | Description |
|---------|-------------|
| LibSpellRange-1.0 | Spell range checking |
| LibRangeCheck-2.0 | Distance-based range checking |
| LibTaxi-1.0 | Taxi node information |
| LibCandyBar-3.0 | Cooldown timer bars |
| LibGraph-2.0 | Graphing |
| LibBossIDs-1.0 | Boss ID registry |
| LibGroupTalents-1.0 | Talent information |

### World & Map
| Library | Description |
|---------|-------------|
| HereBeDragons | World coordinate API |
| Astrolabe | Map & minimap library |
| Krowi_WorldMapButtons | Map button management |

### Compatibility
| Library | Description |
|---------|-------------|
| Compat-335.lua | Wrath 3.3.5a API shims |
| Compat-Lua.lua | Lua version compatibility |
| TaintLess | Taint prevention |
| LibDispel | Dispel/buff type detection |
| EasyFork.lua | API compatibility fork |

### Media
| Library | Description |
|---------|-------------|
| LibSharedMedia-3.0 | Shared media (fonts, sounds, textures) |
| LibTranslit | Character transcription |
| UTF8 | UTF-8 string handling |

*(full list in `Libs.xml`)*

---

## Installation

1. Download `!X-Libs.zip` from → [Releases](https://github.com/Xurkon/-X-Libs/releases)
2. Extract into `\<WoW>\Interface\AddOns\!X-Libs\`
3. Load WoW — all supporting addons automatically detect and use it

Although !X-Libs is programmed to coexist with other library-providing addons, compatibility cannot be guaranteed when used alongside libraries from other addons. If you encounter issues, try removing conflicting embedded library copies.

Some addons bundle their own libs and refuse to load without them. Delete those embedded copies — if the addon uses Ace3 or LibStub, it will use !X-Libs transparently.

---

## Verified with

- **Questie-X** — quest tracker for Retail & Wrath
- **PE-ElvUI** — enhanced UI plugin suite
- **ElvUI_Enhanced** — module plugin ecosystem
- **ElvUI_AddOnSkins** — unified addon skinning

*Any addon using Ace3 or LibStub works out of the box.*

---

## License

MIT — individual library licenses are retained in their respective folders.

---

<div align="center">

**!X-Libs** — *The universal library layer for every WoW addon, on every version.*

[GitHub](https://github.com/Xurkon/-X-Libs) · [Issues](https://github.com/Xurkon/-X-Libs/issues)

</div>
