# Overview and Architecture

> Sources: Krowi-Frostmane EU, 2026-02-20
> Raw: [Krowi's Extended Vendor UI — Codebase Analysis](../../raw/krowi-extended-vendor-ui/krowi-extended-vendor-ui-codebase.md)

## Overview

Krowi's Extended Vendor UI (KEVU) is a World of Warcraft addon that replaces and extends the default Blizzard merchant frame. It supports all active WoW versions simultaneously (Mainline/Midnight, Cataclysm Classic, Wrath Classic, TBC Classic, Vanilla Classic) from a single codebase. The addon adds configurable grid layouts, item filtering by category, real-time search, a custom currency/token display banner, and a plugin system for third-party addon integration.

## Addon Metadata

| Field | Value |
|---|---|
| Internal prefix | KrowiEVU / KEVU |
| Current version | 21.3 (2026-02-20) |
| Author | Krowi-Frostmane EU |
| CurseForge ID | 872787 |
| Wago ID | mNwQwWKo |
| LoadWith | Blizzard_MerchantFrame |
| SavedVariables | KrowiEVU_Options, KrowiEVU_Filters, KrowiEVU_Debug |
| Icon | inv_misc_bag_24_netherweave_imbued |

Interface version targets: 120001 (Mainline), 110207 (Cataclysm), 50503 (Wrath), 20505 (TBC), 11508 (Vanilla).

## File Load Order

The TOC loads in this sequence:

1. `Libs\Files.xml` — All library dependencies
2. `Api\Files.xml` — Public API and plugin registration
3. `Plugins\Files.xml` — Plugin implementations (CanIMogIt, ElvUI)
4. `Localization\Files.xml` — Language strings
5. `Krowi_ExtendedVendorUI.lua` — Main entry point and initialization
6. `Options\Files.xml` — AceConfig options panel
7. `Libs\Krowi_Util\Icon.lua` — Minimap icon utility (from Krowi_Util lib)
8. `Icon.lua` — Minimap icon wiring
9. `Filters.lua` — Filter system
10. `Gui\Files.xml` — All GUI components

## Initialization Sequence

`Krowi_ExtendedVendorUI.lua` registers for `ADDON_LOADED`. When fired for this addon:

1. Detect WoW version via `GetBuildInfo()` (sets `addon.IsClassicWrath`, `addon.IsDragonfly` flags)
2. `addon.Options.Load()` — initializes AceDB, registers AceConfig trees
3. `addon.PluginsApi.InjectPluginOptions()` — lets each registered plugin inject option entries
4. `addon.PluginsApi.LoadPlugins()` — calls Load() on each plugin
5. `MerchantItemsContainer.LoadMaxNumItemSlots()` — pre-allocates all possible item slot frames
6. `FilterButton.Load()`, `SearchBox.Load()`, `OptionsButton.Load()`, `TokenBanner.Load()` — initialize UI components
7. `addon.Icon.Load()` — registers minimap icon
8. `addon.Api.Load()` — exposes public global `KrowiEVU_MerchantItemsContainer`
9. Pre-loads `HousingCatalogSearcher` on mainline to avoid first-open stutter

A `MerchantFrame_SetFilter` polyfill is injected on Classic versions that lack the native API.

## Core Architecture

```
KrowiEVU_Options (AceDB)
    └── addon.db.profile.*         -- all saved settings and filters

addon.PluginsApi                   -- plugin registry and lifecycle
    ├── RegisterPlugin()
    ├── InjectPluginOptions()
    └── LoadPlugins()

addon.Gui
    ├── MerchantFrame              -- frame resizing + API overrides
    ├── MerchantItemsContainer     -- grid layout engine
    ├── FilterButton               -- category filter dropdown
    ├── SearchBox                  -- text search control
    ├── OptionsButton              -- settings dropdown
    └── TokenBanner                -- currency display bar

addon.CachedItemIndices[]          -- maps display slot → true merchant index
```

The filtered display model is central: `addon.CachedItemIndices` is rebuilt on every filter change, and all Blizzard merchant APIs (`GetMerchantNumItems`, `BuyMerchantItem`, `GetMerchantItemInfo`, etc.) are overridden to remap display indices through this cache.

## Version Support Strategy

Conditional checks on `addon.IsClassicWrath`, `addon.IsDragonfly`, and similar flags gate features per version:
- Housing filter: mainline only
- Warglaives weapon type: excluded on Classic/TBC/Mists
- Housing Quantity menu: hidden on Classic versions
- Class/spec filter entries: mainline only
- Modern vs. classic widget creation paths throughout all GUI components

## Library Dependencies

| Library | Purpose |
|---|---|
| AceDB-3.0 | Saved variable management, profile system |
| AceConfig-3.0 / AceConfigDialog-3.0 | Options panel UI |
| AceConfigDropdown-3.0 | Dropdown widgets |
| AceDBOptions-3.0 | Profile management tab |
| AceGUI-3.0 | Base widget library |
| LibDBIcon-1.0 | Minimap icon button |
| Krowi_Util | Colors, Constants, Credits, Strings, MetaData, Icon utilities |
| Krowi_Menu | Custom dropdown menu system (MenuBuilder, MenuItem, MenuUtil) |
| Krowi_PopupDialog | Popup dialog for custom numeric input |
| Krowi_Currency | Currency display utilities for token banner |

## See Also

- [Filtering System](filtering-system.md)
- [GUI Components](gui-components.md)
- [Token Banner](token-banner.md)
- [Plugin System](plugin-system.md)
- [Options and Configuration](options-and-configuration.md)
