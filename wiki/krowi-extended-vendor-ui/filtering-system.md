# Filtering System

> Sources: Krowi-Frostmane EU, 2026-02-20
> Raw: [Krowi's Extended Vendor UI — Codebase Analysis](../../raw/krowi-extended-vendor-ui/krowi-extended-vendor-ui-codebase.md)

## Overview

The filtering system (`Filters.lua`) is the core logic layer that decides which merchant items are visible at any time. It defines 11 custom filter constants, item-type lookup tables, validation functions for each filter mode, and AceDB-backed persistence for per-profile filter preferences. The active filter is stored as a number, and `addon.CachedItemIndices` is rebuilt whenever the filter or search changes.

## Custom Filter Constants

Filter IDs 1–100 are Blizzard's built-in loot filters. KEVU adds:

| Constant | ID | Description |
|---|---|---|
| NEW_RANGE | 101 | Separator; begins KEVU range |
| PETS | 102 | Battle pets |
| MOUNTS | 103 | Mounts |
| TOYS | 104 | Toy Box items |
| TRANSMOG | 105 | Wearable appearances |
| RECIPES | 106 | Profession recipes |
| TRANSMOG_SETS | 107 | Ensemble/appearance sets |
| ILLUSIONS | 108 | Weapon enchant illusions |
| HOUSING | 109 | Housing catalog items (mainline only) |
| CUSTOM | 110 | User-configured armor/weapon type subset |
| SEARCH | 111 | Real-time name search |

## Item Type Lookup Tables

### Armor Types (7 entries)
Generic, Cloth, Leather, Mail, Plate, Cosmetic, Shield. Each maps to Blizzard `INVTYPE` constants and `subClassID` values used to classify items returned by `C_MerchantFrame.GetItemInfo`.

### Weapon Types (20+ entries)
OneHAxe, TwoHAxe, Bow, Gun, OneHMace, TwoHMace, Polearm, OneHSword, TwoHSword, Warglaives, Staff, Exotic, Exotic2, FistWeapon, Miscellaneous, Dagger, Thrown, Crossbow, Wand, Fishing_Pole. **Warglaives is excluded on Classic, TBC Classic, and Mists Classic.**

`ArmorTypesSorted` and `WeaponTypesSorted` provide stable iteration order for consistent menu rendering.

## Validation Functions

Each validation function takes a merchant item index and returns `true` if the item passes the filter.

| Function | Logic |
|---|---|
| ValidatePetsOnly | IsPet classification check |
| ValidateMountsOnly | IsMount classification check |
| ValidateToysOnly | IsToy classification check |
| ValidateTransmogOnly | IsTransmog + optionally HideCollected check + armor/weapon type custom filter |
| ValidateTransmogSetOnly | ITEM_CLASS_RECIPE with appearance-set subclass |
| ValidateIllusionOnly | Weapon enchant/illusion item type |
| ValidateRecipesOnly | ITEM_CLASS_RECIPE (excluding sets) |
| ValidateHousingOnly | C_Housing catalog item (mainline only) |
| ValidateCustom | OR-chain across enabled CustomFilter checkboxes |
| ValidateSearch | Item name contains search text (case-insensitive) |

Helper predicates `IsPet`, `IsMount`, `IsToy`, `IsTransmog` check item classification. Collected variants (`IsPetCollected`, `IsMountCollected`, `IsToyCollected`, `IsTransmogCollected`) additionally check the player's collection state for HideCollected logic.

## AceDB Storage

Filter state is stored in `KrowiEVU_Filters` (a separate AceDB from options). Profile structure:

```lua
HideCollected = {
  [PETS] = false,
  [MOUNTS] = false,
  [TOYS] = false,
  [TRANSMOG] = false,
  -- etc.
}
CustomFilters = {
  Armor = { Cloth = false, Leather = false, ... },
  Weapon = { Sword = false, Dagger = false, ... },
}
```

`RefreshFilters()` is registered as a callback on AceDB profile change, copy, and reset events so the merchant display updates immediately when switching profiles.

## Filter Application Flow

1. User selects a filter (radio) or toggles a checkbox in the filter menu.
2. `MerchantFrame_SetFilter(filterID)` is called (or polyfill on Classic).
3. KEVU intercepts all `GetMerchantNumItems` / `GetMerchantItemInfo` / `BuyMerchantItem` calls.
4. On each merchant frame update, the addon iterates all actual merchant items and builds `addon.CachedItemIndices[]` — only indices that pass the active validation function are included.
5. Display slots are mapped to real merchant indices through this cache, making filtering transparent to the rest of the Blizzard UI.

## See Also

- [Overview and Architecture](overview-and-architecture.md)
- [GUI Components](gui-components.md) — FilterButton and SearchBox that drive filter changes
