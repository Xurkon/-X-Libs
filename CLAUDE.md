# !X-Libs Development Rules

## Core Principles

1. **Universal Compatibility**: All code must work on ALL WoW versions (Retail, WotLK, TBC, Classic) with Lua 5.0+
2. **Merge Code, Never Replace**: When fixing library issues, pull specific functions/sections from working implementations rather than wholesale replacement
3. **Backward Compatibility**: Libraries must work with both old and new addon versions

## Code Exploration Policy

**Always use jCodemunch-MCP tools** for code navigation. Never fall back to Read, Grep, Glob, or Bash for code exploration.

### Required Tools
- `jcodemunch_resolve_repo` / `jcodemunch_index_folder` — confirm project is indexed
- `jcodemunch_suggest_queries` — when repo is unfamiliar
- `jcodemunch_search_symbols` — find symbols by name
- `jcodemunch_search_text` — find strings, comments, config values
- `jcodemunch_get_symbol_importance` — find most architecturally important symbols

### Reading Code
- before opening any file → `get_file_outline` first
- one symbol → `get_symbol`; multiple → `get_symbols`
- symbol + its imports → `get_context_bundle`

## Library-Specific Guidelines

### AceGUI-3.0
- Use `BACKDROP_TEMPLATE` fallback pattern: `local BACKDROP_TEMPLATE = (BackdropTemplateMixin and "BackdropTemplate") or nil`
- All widgets must have proper `RegisterAsContainer` / `RegisterAsWidget` return patterns
- Include `SetDefaultSize` method on Frame/Window containers

### AceConfig-3.0 / AceConfigDialog-3.0
- Always include `Open`, `Close`, `CloseAll`, `SetDefaultSize`, `AddToBlizOptions` functions
- Support both old (InterfaceOptions) and new (Settings API) Blizzard options panels
- Widget callbacks must handle nil widget gracefully

### AceSerializer-3.0
- Support dual deserialization format: new `^1` format and legacy `{` format
- Include `SerializeForPrint` and `DeserializeFromPrint` for base64 encoded output

### ArkInventory Compatibility
- `BagID_Internal` must return `nil` for unknown bag IDs (not error)
- All tooltip functions must have nil checks

## Windows PowerShell First

Use PowerShell for all Windows operations by default.

### Directory Operations
```powershell
New-Item -ItemType Directory -Path "path\to\dir"
Remove-Item -Recurse -Force "path\to\dir"
Copy-Item -Recurse "source" "dest"
Move-Item "source" "dest"
```

### File Operations
```powershell
Get-Content "path\to\file.txt"
Set-Content -Path "path\to\file.txt" -Value "content"
Add-Content -Path "path\to\file.txt" -Value "content"
```

### Search & Filter
```powershell
Get-ChildItem -Path "dir" -Filter "*.lua" -Recurse
Select-String -Path "*.lua" -Pattern "pattern"
```

## When to Use Alternatives

- **Git operations** → use `git` command (works in bash or PowerShell)
- **Network/Downloads** → use `curl.exe` via PowerShell
- **Package managers** → npm, pip, choco as needed

## Testing Workflow

1. Junction `C:\Users\kance\Documents\GitHub\Questie-X` to `C:\Ebonhold\...\AddOns\Questie-X` for testing
2. Test with only !X-Libs providing libraries (no embedded libs)
3. Verify Questie loads without errors
4. Verify options panel displays correctly
5. Verify ArkInventory compatibility

## Changelog Requirements

All changes must be documented in `CHANGELOG.md`:
- Version number and date
- Specific files changed
- Bug fixes with error messages if applicable
- New features or compatibility improvements
