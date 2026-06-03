# GUI Components

> Sources: Krowi-Frostmane EU, 2026-02-20
> Raw: [Krowi's Extended Vendor UI — Codebase Analysis](../../raw/krowi-extended-vendor-ui/krowi-extended-vendor-ui-codebase.md)

## Overview

The GUI layer (under `Gui/`) comprises five independent components mounted onto or adjacent to the Blizzard `MerchantFrame`. Each component uses a Load/Mixin pattern: a `.lua` file handles creation and positioning, a `Mixin.lua` file implements behavior, and optionally an `.xml` file defines the frame template. Modern (mainline) and Classic widget paths are split inside each component via version flags.

## MerchantFrame (Gui/MerchantFrame.lua)

Hooks and extends the Blizzard merchant frame itself.

### Layout Modifications
- Repositions `MerchantMoneyInset` to make room for the token banner.
- Creates three new inset frames:
  - `KrowiEVU_ButtonsInset` — houses the filter/search/options controls
  - `KrowiEVU_BuybackInset` — shown when buyback tab is active
  - `KrowiEVU_EmptyInset` — fills remaining space
- Updates repair button positions (`MerchantRepairItemButton`, `MerchantRepairAllButton`) after resizing.
- Hooks `MerchantFrame_UpdateMerchantInfo` and `MerchantFrame_UpdateBuybackInfo` to resize the full frame based on the configured NumRows × NumColumns and toggle visibility of all custom elements.

### Filtered Merchant API Overrides
KEVU replaces the following Blizzard globals so all downstream code uses filtered display indices transparently:

| Overridden API | Behavior |
|---|---|
| GetMerchantNumItems | Returns `#addon.CachedItemIndices` |
| GetMerchantItemInfo(i) | Remaps `i` → `CachedItemIndices[i]` |
| BuyMerchantItem(i, ...) | Remaps index before purchase |
| PickupMerchantItem(i) | Remaps index |
| GetMerchantItemLink(i) | Remaps index |
| GetMerchantItemCostInfo(i) | Remaps index |
| GetMerchantItemMaxStack(i) | Remaps index |
| C_MerchantFrame.GetItemInfo(i) | Remaps index (modern API) |

## MerchantItemsContainer (Gui/MerchantItemsContainer.lua)

Manages the grid of item slot frames.

### Layout Constants
| Constant | Value |
|---|---|
| FirstOffsetX | 11 |
| FirstOffsetY | -69 |
| OffsetX (column gap) | 12 |
| OffsetMerchantInfoY | 8 |
| OffsetBuybackInfoY | 15 |

### Key Functions
| Function | Purpose |
|---|---|
| LoadMaxNumItemSlots() | Pre-allocates slot frames up to 99×10 maximum |
| DrawItemSlots(n, offsetX, offsetY) | Core grid layout; places n frames in rows-first or columns-first order |
| PrepareMerchantInfo() | Sets row/col counts from options, calls DrawForMerchantInfo |
| PrepareBuybackInfo() | Simplified single-column layout for buyback tab |
| DrawForMerchantInfo() | Calls DrawItemSlots with MerchantInfo Y offset |
| DrawForBuybackInfo() | Calls DrawItemSlots with BuybackInfo Y offset |

The custom `ItemSlotOnEnter` tooltip override passes the correct real merchant index (via `CachedItemIndices`) to avoid showing wrong tooltip data for filtered display positions.

## FilterButton (Gui/FilterButton/)

A dropdown button at the top-right of the merchant frame (Modern: offset -9, -32; Classic: -12, -31 from top-right anchor).

### Menu Structure (FilterButtonMixin)

The menu is built with `Krowi_Menu/MenuBuilder` and regenerated on each open:

**Default filters (Blizzard compatibility)**
- Class-specific loot filters + spec filters (mainline only; populated dynamically from `GetNumClasses` / `GetNumSpecializationsForClassID`)
- Bind on Equip
- All

**Search** (separator above)

**Only show**
- Pets / Mounts / Toys
- Appearances → submenu:
  - Armor: Generic, Cloth, Leather, Mail, Plate, Cosmetic, Shield
  - Weapons: OneHAxe, TwoHAxe, Bow, … (20+ types; Warglaives excluded on relevant Classic versions)
- Appearance Sets / Illusions / Recipes
- Housing (mainline only)

**Custom filters**
- Per armor-type checkboxes
- Per weapon-type checkboxes

### Menu Callbacks
- `OnCheckboxSelect(key)` — toggles `CustomFilters[key]`, triggers `MerchantFrame_Update`
- `OnRadioSelect(filterID)` — calls `MerchantFrame_SetFilter(filterID)`
- `OnAllSelect()` — resets to All filter
- `KeyEqualsText(key, text)` — predicate used for radio button state comparison

## SearchBox (Gui/SearchBox/)

An edit box positioned left of the filter button (Modern offset: -6, 1; Classic: -10, 1).

### Behavior (SearchBoxMixin)
- `OnTextChanged`: Switches active filter to `SEARCH` (111) and calls `MerchantFrame_Update` with the current text.
- `OnEditFocusGained`: Saves the previously active filter so it can be restored when search is cleared.
- Hooks `MerchantFrame_SetFilter`: Clears the search box text whenever a non-SEARCH filter is applied externally.

### Search Persistence Logic
Three modes controlled by two options:

| RememberSearchBetweenVendors | RememberSearch | Behavior |
|---|---|---|
| true | any | Search persists across all vendor visits |
| false | true | Search clears only when the NPC changes |
| false | false | Search clears on every vendor visit |

NPC identity is tracked by remembering the last vendor GUID or name.

### Positioning API
`SetPointOffset(x, y)` / `ResetPointOffset()` / `SetPointOffsetXY(x, y)` allow other components (e.g., OptionsButton) to reposition the search box when they show/hide.

## OptionsButton (Gui/OptionsButton/)

A dropdown button positioned right of the search box (Modern: -11, 0; Classic: -14, 0). Shown/hidden based on the `ShowOptionsButton` option.

### Menu Structure (OptionsButtonMixin)
- **Direction** (radio): Rows first / Columns first
- **Rows** (radio + custom): Presets 1, 2, 5, 10; custom dialog accepts 1–99
- **Columns** (radio + custom): Presets 2, 5, 10; custom dialog accepts 1–99
- **Checkboxes**: RememberFilter, RememberSearch, RememberSearchBetweenVendors
- **Housing Quantity** (mainline only, radio + custom): Presets 1, 2, 5, 10; custom 1–999
- **Transmog toggles** (mainline, if applicable): armor/weapon type submenus mirroring the filter button checkboxes
- **Plugin sections**: Injected dynamically by registered plugins

Custom numeric values display as "Custom (x)" in the menu label. All changes call `UpdateView()` which refreshes the item grid and token banner.

## See Also

- [Filtering System](filtering-system.md)
- [Token Banner](token-banner.md)
- [Plugin System](plugin-system.md)
- [Overview and Architecture](overview-and-architecture.md)
