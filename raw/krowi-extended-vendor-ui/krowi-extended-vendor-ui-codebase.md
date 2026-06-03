# Krowi's Extended Vendor UI — Codebase Analysis

> Source: e:\World of Warcraft Addon Development\Krowi_ExtendedVendorUI (local project)
> Collected: 2026-06-03
> Published: Unknown

## Addon Metadata (Krowi_ExtendedVendorUI.toc)

- **Interface versions:** 120001 (Mainline/Midnight), 110207 (Cataclysm Classic), 50503 (Wrath Classic), 20505 (TBC Classic), 11508 (Vanilla Classic)
- **Title:** Krowi's Extended Vendor UI
- **X-Prefix:** KrowiEVU / **X-Acronym:** KEVU
- **Version:** 21.3
- **Author:** Krowi-Frostmane EU
- **LoadWith:** Blizzard_MerchantFrame
- **SavedVariables:** KrowiEVU_Options, KrowiEVU_Filters, KrowiEVU_Debug
- **Notes:** Extends the size of your Merchant Frame.
- **AddonCompartment functions:** KrowiEVU_OnAddonCompartmentEnter/Leave/Click
- **IconTexture:** interface/icons/inv_misc_bag_24_netherweave_imbued
- **X-CurseForge-ID:** 872787 / **X-Wago-ID:** mNwQwWKo
- Load order: Libs → Api → Plugins → Localization → Krowi_ExtendedVendorUI.lua → Options → Icon → Filters → Gui

## Main Entry Point (Krowi_ExtendedVendorUI.lua)

Detects WoW version by parsing build info (GetBuildInfo). Checks for Wrath Classic (wowClassicWrath) and Dragonfly/Retail. Registers for ADDON_LOADED event. On load:
1. Loads options (addon.Options.Load)
2. Injects plugin options (addon.PluginsApi.InjectPluginOptions)
3. Loads all plugins (addon.PluginsApi.LoadPlugins)
4. Configures merchant item container slots (MerchantItemsContainer.LoadMaxNumItemSlots)
5. Initializes UI: FilterButton.Load, SearchBox.Load, OptionsButton.Load, TokenBanner.Load
6. Loads icon (addon.Icon.Load)
7. Exposes public API (addon.Api.Load)

Pre-loads HousingCatalogSearcher on mainline to prevent first-open lag. Provides a MerchantFrame_SetFilter polyfill for classic versions that lack it.

## Filtering System (Filters.lua)

### Custom Filter Constants
- NEW_RANGE (101), PETS (102), MOUNTS (103), TOYS (104), TRANSMOG (105), RECIPES (106), TRANSMOG_SETS (107), ILLUSIONS (108), HOUSING (109), CUSTOM (110), SEARCH (111)

### Armor Type Lookup
Seven armor types: Generic, Cloth, Leather, Mail, Plate, Cosmetic, Shield. Each maps to Blizzard's INVTYPE/subClassID.

### Weapon Type Lookup
20+ weapon types including: OneHAxe, TwoHAxe, Bow, Gun, OneHMace, TwoHMace, Polearm, OneHSword, TwoHSword, Warglaives, Staff, Exotic, Exotic2, FistWeapon, Miscellaneous, Dagger, Thrown, Crossbow, Wand, Fishing_Pole. Warglaives excluded on Classic/TBC/Mists.

### Sorted Indices
ArmorTypesSorted and WeaponTypesSorted maintain consistent UI ordering.

### AceDB Storage (Options.Defaults)
Filter profiles store: HideCollected booleans per filter type, CustomFilters (per armor/weapon type booleans).

### Validation Functions
- ValidatePetsOnly, ValidateMountsOnly, ValidateToysOnly — check item classification
- ValidateTransmogOnly(index) — validates item as transmog; respects HideCollected + armor/weapon type custom filter checkboxes
- ValidateTransmogSetOnly — checks ITEM_CLASS_RECIPE with special set subclass
- ValidateIllusionOnly — checks for weapon enchant/illusion type
- ValidateRecipesOnly — checks ITEM_CLASS_RECIPE
- ValidateHousingOnly — checks housing catalog item (mainline only, uses C_Housing)
- ValidateCustom — OR-chain across enabled custom filter types
- ValidateSearch(index, searchText) — matches item name contains searchText (case-insensitive)

Helper predicates: IsPet, IsMount, IsToy, IsTransmog, IsPetCollected, IsMountCollected, IsToyCollected, IsTransmogCollected.

RefreshFilters callback triggered on AceDB profile change/copy/reset.

## GUI — MerchantFrame (Gui/MerchantFrame.lua)

Hooks into the Blizzard MerchantFrame to resize and rearrange the layout:
- Repositions MerchantMoneyInset
- Creates KrowiEVU_ButtonsInset, KrowiEVU_BuybackInset, KrowiEVU_EmptyInset
- Updates repair button positions
- Hooks MerchantFrame_UpdateMerchantInfo and MerchantFrame_UpdateBuybackInfo to resize the frame based on rows/columns and toggle custom element visibility

### Filtered API Override
Maintains `addon.CachedItemIndices` — a list of actual merchant indices that pass the current filter. Overrides:
- GetMerchantNumItems → returns #CachedItemIndices
- GetMerchantItemInfo(index) → remaps to CachedItemIndices[index]
- BuyMerchantItem(index, ...) → remaps index
- PickupMerchantItem(index) → remaps index
- GetMerchantItemLink(index) → remaps index
- GetMerchantItemCostInfo(index) → remaps index
- GetMerchantItemMaxStack(index) → remaps index
- C_MerchantFrame.GetItemInfo(index) → remaps index

## GUI — MerchantItemsContainer (Gui/MerchantItemsContainer.lua)

Manages the item slot grid layout.

### Positioning Constants
- FirstOffsetX: 11, FirstOffsetY: -69
- OffsetX: 12 (gap between columns)
- OffsetMerchantInfoY: 8, OffsetBuybackInfoY: 15

### Configuration
- NumRows (default 5), NumColumns (default 2)
- Direction: 'Rows' (row-major) or 'Columns' (column-major)

### Dynamic Slot Pool
Creates MerchantItemTemplate frames on demand up to NumRows * NumColumns. Frames are reused across refreshes.

### Key Functions
- LoadMaxNumItemSlots(): Allocates maximum slots (99 rows × 10 columns max)
- DrawItemSlots(numSlots, offsetX, offsetY): Grid layout engine
- DrawForMerchantInfo(): Delegates to DrawItemSlots with MerchantInfo offsets
- DrawForBuybackInfo(): Delegates with BuybackInfo offsets
- PrepareMerchantInfo() / PrepareBuybackInfo(): Sets row/col counts and triggers draw
- Custom ItemSlotOnEnter: Overrides tooltip to show correct filtered item index

## GUI — FilterButton (Gui/FilterButton/)

### FilterButton.lua
Creates either a modern DropdownButton (mainline) or classic DropDownToggleButton. Positioned at top-right of MerchantFrame: Modern (-9, -32), Classic (-12, -31).

### FilterButtonMixin.lua
Generates the filter dropdown menu via Krowi_Menu/MenuBuilder:

**Default filters section:**
- Class/spec filters (mainline only, populated from GetNumClasses/GetNumSpecializationsForClassID)
- Bind on Equip
- All

**Search filter** (with divider above)

**Only show section:**
- Pets, Mounts, Toys
- Appearances (with Armor submenu: Generic/Cloth/Leather/Mail/Plate/Cosmetic/Shield; Weapon submenu: all 20+ types)
- Appearance Sets, Illusions, Recipes, Housing (mainline only)

**Custom filters section:**
- Per armor-type checkboxes (mapped to HideCollected + CustomFilters)
- Per weapon-type checkboxes

Menu callbacks: OnCheckboxSelect (toggles filter), OnRadioSelect (switches active filter), OnAllSelect (clears/resets to All), KeyEqualsText (radio comparison predicate).

## GUI — SearchBox (Gui/SearchBox/)

### SearchBox.lua
Creates a modern EditBox or classic styled editbox. Positioned left of the filter button: Modern (-6, 1), Classic (-10, 1). Provides SetPointOffset/ResetPointOffset/SetPointOffsetXY for dynamic repositioning.

### SearchBoxMixin.lua
Behavior:
- OnTextChanged: Switches filter to SEARCH and triggers MerchantFrame_Update
- OnEditFocusGained: Saves previous filter so it can be restored on clear
- Hooks MerchantFrame_SetFilter: Clears search box when a non-SEARCH filter is selected

**Search persistence logic:**
1. RememberSearchBetweenVendors=true → persist across all vendors
2. RememberSearch=true, RememberSearchBetweenVendors=false → clear only when NPC changes
3. Both false → clear on every vendor visit

## GUI — OptionsButton (Gui/OptionsButton/)

### OptionsButton.lua
Creates modern or classic dropdown. Positioned right of search box: Modern (-11, 0), Classic (-14, 0). Shown/hidden based on ShowOptionsButton option.

### OptionsButtonMixin.lua
Menu structure:
- **Direction submenu:** Rows first / Columns first (radio)
- **Rows submenu:** Presets 1/2/5/10 + custom dialog (1–99)
- **Columns submenu:** Presets 2/5/10 + custom dialog (1–99)
- **Checkboxes:** RememberFilter, RememberSearch, RememberSearchBetweenVendors
- **Housing Quantity submenu** (mainline only): Presets 1/2/5/10 + custom (1–999)
- **Transmog custom filter toggles** (if mainline: armor/weapon type checkboxes)
- **Plugin sections** injected dynamically by plugins

All changes call UpdateView (refreshes item layout + token banner). Custom numeric inputs use Krowi_PopupDialog library.

## GUI — TokenBanner (Gui/TokenBanner/)

### TokenBanner.lua
Replaces all Blizzard currency/money frames (MerchantMoneyFrame, MerchantExtraCurrencyInset, etc.) with custom token frames. Positioned in MerchantMoneyInset.

Pre-allocates a pool of 5 token frames. Implements right-to-left flow with line wrapping when tokens exceed banner width.

**Calculation functions:**
- CalculateGoldCount: Sums gold cost across all merchant items
- CalculateCurrencyCounts: Sums currency cost per currencyID
- CalculateItemCounts: Sums item cost per itemID

**Main Update loop:** Triggered after MerchantFrame updates. Calls Draw* functions in sequence: Gold first, then currencies, then items.

### TokenBannerMixin.lua
Manages the banner frame itself; coordinates token pool refresh and layout.

### TokenMixin.lua
Individual token display. Tracks Need (total) and Have (player's current).

**Token types:** Gold, Currency (C_CurrencyInfo.GetCurrencyInfo), Item (C_Item)

**Display modes (format option):**
- 'Need': Shows required amount only
- 'Have': Shows current amount only
- 'Both': Shows "Have / Need"

Icon: 14×14 texture. Tooltip on hover shows current vs. needed. Click: toggles currency window or links item in chat via HandleModifiedItemClick.

## API System (Api/)

### Api.lua
Exposes `addon.Gui.MerchantItemsContainer` as global `KrowiEVU_MerchantItemsContainer` for external addons (e.g., Vendorer).

### PluginsApi.lua
Plugin registration system:
- RegisterPlugin(pluginName, plugin): Adds plugin to Plugins table
- RegisterEvent(event): Creates shared event frame; routes OnEvent to all registered plugins
- LoadPluginLocalization(L): Calls plugin:LoadLocalization(L) on each plugin
- InjectPluginOptions(): Calls plugin:InjectOptions() on each
- LoadPlugins(): Calls plugin:Load() on each

Plugin interface methods (all optional): OnEvent, LoadLocalization, InjectOptions, Load.

### UtilApi.lua
Exposes addon.InjectOptions as KrowiEVU.UtilApi.InjectOptions.

## Options & Configuration (Options/)

### Defaults.lua
AceDB profile defaults:
- ShowMinimapIcon: false
- NumRows: 5, NumColumns: 2
- Direction: 'Rows'
- Minimap: {hide: true}
- ShowOptionsButton: true, ShowHideOption: true
- RememberFilter: false, RememberSearch: false, RememberSearchBetweenVendors: false
- TokenBanner: MoneyLabel, MoneyAbbreviate, ThousandsSeparator, MoneyGoldOnly, MoneyColored, CurrencyAbbreviate, Format

### General.lua
Three AceConfig option groups:
1. Info: Version (21.3), Build, Author, Discord/CurseForge/Wago links
2. Icon: Toggle minimap icon visibility
3. OptionsButton: Show/hide button, open options panel, ShowHideOption toggle

### Plugins.lua
Container for plugin-injected options (args table populated at runtime).

### Credits.lua
Dynamically populates SpecialThanks, Donations, Localizations sections from addon.Util.Credits.

### Profiles.lua
Integrates AceDBOptions-3.0 for profile management (copy/delete/new/reset) + filter database options.

## Localization (Localization/)

### Shared.lua
Maps Blizzard game constants to addon locale keys:
- Direction → HUD_EDIT_MODE_SETTING_BAGS_DIRECTION
- Appearances → WARDROBE + ITEMS
- All → ALL / All Specs → ALL_SPECS
- Bind on Equip → ITEM_BIND_ON_EQUIP
- Appearance Sets → WARDROBE + Ensembles/Arsenals/etc.

### enUS.lua
~90+ strings: filter names, menu labels, settings descriptions (with %s/%d placeholders), plugin descriptions, token banner options, help text. Stored in addon.L table.

### Other locales
deDE, frFR, itIT, ruRU, zhCN — community-contributed translations.

## Plugins (Plugins/)

### CanIMogIt.lua
Hooks MerchantFrame_SetFilter. After a filter change, waits 0.1s then calls MerchantFrame_CIMIOnClick to force CanIMogIt overlay refresh. Injects options entry. Registered via RegisterPlugin.

### ElvUI.lua
Full ElvUI skinning. Checks ElvUI loaded + skin enabled per component.

**Modern skinning:** Strips textures from merchant item buttons, creates transparent backdrops, repositions price/icon text, applies ElvUI styling.
**Classic skinning:** Same with classic frame offsets.
**Per-component hooks:** Filter button (HandleDropDownBox), Search box (HandleEditBox, height adjustment), Options button classic (HandleButton), Token banner (StripTextures + transparent backdrop), Repair buttons hook.
Disables quest icons; uses ElvUI textures instead. Hooks slot update functions to apply skins to newly created frames.

## Library Dependencies

- **AceDB-3.0** — Saved variable management, profiles
- **AceConfig-3.0 / AceConfigDialog-3.0 / AceConfigDropdown-3.0** — Options panel and dropdowns
- **AceDBOptions-3.0** — Profile management UI
- **AceGUI-3.0** — Base widget library
- **LibDBIcon-1.0** — Minimap button
- **Krowi_Util** — Utility functions, Credits, Colors, Constants, Strings, MetaData, Icon
- **Krowi_Menu / Krowi_MenuBuilder / Krowi_MenuItem / Krowi_MenuUtil** — Custom dropdown menu system
- **Krowi_PopupDialog** — Popup dialog for custom numeric input
- **Krowi_Currency** — Currency display utilities

## Version History Highlights (Changelog)

- **21.3** (2026-02-20): Fixed recipe filtering
- **21.2** (2026-02-13): Token click opens currency window, chat linking
- **21.1** (2026-02-08): Token banner display mode option (Need/Have/Both)
- **21.0** (2026-01-14): WoW 12.0.0 (Midnight) support + library rework
- **20.1** (2026-01-10): Sorted armor/weapon filter menus; TBC Classic support
- **20.0** (2026-01-09): Midnight support; C_MerchantFrame.GetItemInfo migration; polyfills for Classic
- **19.1** (2026-01-02): ElvUI skinning for Token Banner and merchant insets
- **19.0** (2026-01-02): Full ElvUI support; Token Banner introduced; Krowi_PopupDialog numeric input; custom row/column/housing qty inputs
- Earlier: Housing filter, Illusions filter, Transmog Sets filter, Search, Recipes, Profiles, CanIMogIt integration, multi-classic support
