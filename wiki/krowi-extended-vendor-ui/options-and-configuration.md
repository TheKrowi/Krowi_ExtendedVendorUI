# Options and Configuration

> Sources: Krowi-Frostmane EU, 2026-02-20
> Raw: [Krowi's Extended Vendor UI — Codebase Analysis](../../raw/krowi-extended-vendor-ui/krowi-extended-vendor-ui-codebase.md)

## Overview

KEVU uses AceDB-3.0 for persistent storage across two saved variables: `KrowiEVU_Options` for all settings and `KrowiEVU_Filters` for filter state. The full AceConfig options panel is opened via the minimap icon or the addon compartment button, and a quick-access OptionsButton dropdown on the merchant frame exposes the most common settings in-context.

## Saved Variables

| Variable | Contents |
|---|---|
| `KrowiEVU_Options` | All addon settings (layout, display, token banner options) |
| `KrowiEVU_Filters` | Active filter preferences and custom filter checkboxes |
| `KrowiEVU_Debug` | Debug flags (internal use) |

## AceDB Profile Defaults (Options/Defaults.lua)

### Layout & Display
| Key | Default | Description |
|---|---|---|
| NumRows | 5 | Number of rows in the item grid |
| NumColumns | 2 | Number of columns in the item grid |
| Direction | 'Rows' | Grid fill direction: 'Rows' (row-major) or 'Columns' (column-major) |
| ShowOptionsButton | true | Show the quick-options dropdown on the merchant frame |
| ShowHideOption | true | Show the "Hide Options Button" entry in the options dropdown |

### Minimap Icon
| Key | Default | Description |
|---|---|---|
| ShowMinimapIcon | false | Show the minimap icon |
| Minimap | {hide: true} | LibDBIcon-1.0 minimap position data |

### Behavior
| Key | Default | Description |
|---|---|---|
| RememberFilter | false | Restore the last used filter when visiting a vendor |
| RememberSearch | false | Keep search text when revisiting same vendor |
| RememberSearchBetweenVendors | false | Keep search text across all vendors |

### Token Banner
| Key | Default | Description |
|---|---|---|
| MoneyLabel | false | Append Gold/Silver/Copper labels |
| MoneyAbbreviate | false | Abbreviate large money values |
| ThousandsSeparator | false | Insert commas in large numbers |
| MoneyGoldOnly | false | Show only gold denomination |
| MoneyColored | false | Color gold/silver/copper differently |
| CurrencyAbbreviate | false | Abbreviate currency amounts |
| Format | 'Both' | Token display: 'Need', 'Have', or 'Both' |

## AceConfig Options Panel (Options/)

The full options panel is registered under the addon name and opened via `AceConfigDialog:Open(addonName)`. It is organized into four tabs:

### General Tab (Options/General.lua)
Three groups:
1. **Info** — Displays current Version, Build, Author, and links to Discord, CurseForge, and Wago.
2. **Icon** — Toggle `ShowMinimapIcon` (calls `addon.Icon.Show()` / `Hide()`).
3. **Options Button** — Toggle `ShowOptionsButton`, a button to open the full options panel from the merchant frame, and `ShowHideOption`.

Registers a callback on AceDB profile change/copy/reset to refresh the UI state displayed in this tab.

### Plugins Tab (Options/Plugins.lua)
An `args` container populated at runtime by each plugin's `InjectOptions()` call. Empty by default; shows registered plugins (CanIMogIt, ElvUI) with their descriptions.

### Credits Tab (Options/Credits.lua)
Dynamically generated from `addon.Util.Credits` data. Three subsections:
- **Special Thanks**
- **Donations**
- **Localizations** (lists localization contributors per locale)

Populated via `PostLoad` callback using `AutoOrderPlusPlus` for stable ordering.

### Profiles Tab (Options/Profiles.lua)
Integrates `AceDBOptions-3.0` for standard profile management: create, copy, delete, and reset profiles. Also injects filter-database options (from `KrowiEVU_Filters`) into this tab.

## Quick-Access OptionsButton

The merchant frame OptionsButton dropdown provides the most commonly changed settings without opening the full panel. See [GUI Components](gui-components.md) for the full menu structure.

## Minimap Icon & Addon Compartment (Icon.lua)

Configured via `LibDBIcon-1.0`. Tooltip shows left-click and right-click instructions (via `addon.L` strings).

- **Left-click**: Opens the options popup dialog (`Krowi_PopupDialog`)
- **Right-click**: Opens the full AceConfig options panel

The same actions are registered for the Blizzard addon compartment button via `KrowiEVU_OnAddonCompartmentClick`.

## Localization (Localization/)

All user-visible strings live in `addon.L`. English strings are defined in `enUS.lua` (~90+ entries). Other locales: `deDE`, `frFR`, `itIT`, `ruRU`, `zhCN`.

`Shared.lua` maps Blizzard game constants to KEVU locale keys at runtime so strings like "All", "Bind on Equip", and "Appearances" stay localized in sync with the game client.

## See Also

- [Overview and Architecture](overview-and-architecture.md)
- [Plugin System](plugin-system.md) — Plugin options injection
- [Token Banner](token-banner.md) — Token banner formatting options
- [Filtering System](filtering-system.md) — Filter-profile AceDB storage
