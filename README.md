# !X-Libs

**A universal shared-library framework for World of Warcraft addons — running every version from Classic to Dragonflight.**

*One addon. 80+ battle-tested libraries. Zero vendor lock-in.*

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
    └── …80+ total libraries
        └── ElvUI_Enhanced (uses shared libs)
        └── Questie-X (uses shared libs)
        └── PE-ElvUI (uses shared libs)
        └── Any addon using Ace3/LibStub
```

---

## 80+ curated libraries

**Core Framework** — AceAddon-3.0 · AceConsole-3.0 · AceDB-3.0 · AceDBOptions-3.0 · AceEvent-3.0 · AceHook-3.0 · AceTimer-3.0 · AceBucket-3.0 · AceSerializer-3.0 · AceComm-3.0 · AceTab-3.0 · AceConfig-3.0 · AceConfigDialog-3.0 · AceGUI-3.0 · AceGUI-3.0-SharedMediaWidgets

**Unit Frames** — oUF · oUF_Plugins

**Library Infrastructure** — LibStub · CallbackHandler-1.0 · LibSerialize · LibCompress · LibDeflate · LibBase64-1.0

**UI Primitives** — LibQTip-1.0 · LibWindow-1.1 · LibSimpleSticky · LibCustomGlow-1.0 · LibAnim · Masque · ArkDewdrop · DewdropLib · UIDropDownFork · LibAboutPanel · LibBetterBlizzOptions-1.0 · LibDFramework-1.0

**Data & Broker** — LibDBIcon-1.0 · LibDataBroker-1.1 · LibSink-2.0 · LibItemSearch-1.2

**Localization** — AceLocale-3.0 · LibBabble-3.0 (Boss · CreatureType · Faction · Inventory · SubZone · Zone) · LibTourist-3.0 · LibTranslit

**Information** — LibSpellRange-1.0 · LibRangeCheck-2.0 · LibTaxi-1.0 · LibCandyBar-3.0 · LibGraph-2.0 · LibBossIDs-1.0 · LibGroupTalents-1.0 · LibCamera-1.0 · LibRover-1.0 · LibS2kMisc-1.0 · LibS2kFactionalItems-1.0 · LibHash-1.0 · LibTextTable-1.0 · LibTutorial-1.0 · LibCandyBar-3.0

**World & Map** — HereBeDragons · Astrolabe · HBDragons.lua · Krowi_WorldMapButtons

**Compatibility** — Compat-335.lua · Compat-Lua.lua · TaintLess · LibDispel · EasyFork.lua · LibCompat-1.0 · LibAuraInfo-1.0 · NickTag-1.0 · LibElvUIPlugin-1.0 · LibActionButton-1.0 · LibBetterBlizzOptions-1.0

**Media** — LibSharedMedia-3.0 · UTF8

*(full list in `Libs.xml`)*

---

## Version compatibility

| Client | Lua | Status |
|--------|-----|--------|
| Retail (Dragonflight / Warband) | 5.1+ | ✓ Full |
| Wrath of the Lich King 3.3.5a | 5.1 | ✓ Full |
| The Burning Crusade Classic | 5.1 | ✓ Full |
| Classic Era | 5.1 | ✓ Full |
| Lua 5.0 (Classic era baseline) | 5.0 | ✓ Full |

Every library probes for APIs at runtime and provides graceful fallbacks. The `Compat-335.lua` shim fills WoW 3.3.5a-specific gaps; `Compat-Lua.lua` handles Lua version differences. No hard API assumptions, no silent crashes on unsupported versions.

---

## Installation

**Standalone (recommended)**
1. Download `!X-Libs.zip` from → [Releases](https://github.com/Xurkon/-X-Libs/releases)
2. Extract into `World of Warcraft/Interface/AddOns/!X-Libs/`
3. Load WoW — all supporting addons automatically detect and use it

**Embedded fallback**
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
