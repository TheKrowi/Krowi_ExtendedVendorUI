# Spec: Stop reading deprecated Blizzard globals
Intent: [intent.md](intent.md). Status: done

## Requirements
1. `Find-DeprecatedApi.ps1` reports no use outside `Libs/` for `-Branch live`, `classic`, `classic_anniversary` and `classic_era`.
2. The bulk purchase window and the Retail merchant filter menu behave as before on every client: each replacement is the function the old name resolved to.

## Root cause
Not a failure yet; the mechanism that would cause one:
- `Gui/BulkPurchase/BulkPurchaseMixin.lua:7-11` pick `C_Container.X` / `C_Item.X` when the namespace exists, else the old global (`GetContainerNumFreeSlots`, `GetContainerNumSlots`, `GetContainerItemInfo`, `GetItemFamily`, `GetItemCount`). Every client the TOC lists has the namespace functions (`Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua` and `ItemDocumentation.lua` in `wow-ui-source` `live` 12.1.5, `classic` 5.5.4, `classic_anniversary` 2.5.6, `classic_era` 1.15.9), so the fallbacks never run. `GetItemFamily` and `GetItemCount` survive only as aliases in `Blizzard_DeprecatedItemScript` on Classic, which Retail deleted in 12.1.5.
- `Gui/FilterButton/FilterButtonMixin.lua:150` calls `GetSpecializationInfo`, under `addon.Util.IsMainline` (line 3, so Retail only). On live it is `GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo;` in `Blizzard_DeprecatedSpecialization/Deprecated_Specialization_Standard.lua:13`, loaded only while the `loadDeprecationFallbacks` CVar is on.

Reproduction: `Find-DeprecatedApi.ps1` on `dev` at `43a7ccb`: `GetItemFamily` and `GetItemCount` (lines 10, 11) removed on live, deprecated on Classic; `GetSpecializationInfo` (line 150) deprecated.

## Design
- Lines 7-11 assign the namespace functions directly (`local GetItemFamily_ = C_Item.GetItemFamily`, and so on), keeping the local names so no other line changes.
- Line 150 calls `C_SpecializationInfo.GetSpecializationInfo(i, nil, nil, nil, sex)`, the function the alias points to, with the same arguments.

## Options considered
1. **All five fallback lines and line 150 (recommended, chosen).** One consistent block; no old global left.
2. **Only the flagged lines (10, 11, 150).** Lines 7-9 would keep fallbacks to globals no supported client has had for years. Not chosen.

## Areas of concern
- Taint and secret values: none; the same C functions as before, no frame, hook or protected action changes. `C_SpecializationInfo.GetSpecializationInfo` and the container and item getters have no secret returns in the live docs.
- Clients: all four checked in their `wow-ui-source` branch (see Root cause); line 150 runs on Retail only.
- Blizzard API changes: this is one.
- Other addons and skins: none.
- Saved variables and migrations: none.
- Localization: none.
- Embedded libraries: none changed (`-IncludeLibs` shows only upstream AceGUI's deliberate `ChatEdit_InsertLink` fallback, if any).
- Player-facing text: none; nothing changes for players, so no changelog line.

## Verification
- `Find-DeprecatedApi.ps1` for the four branches: red before (above), clean after.
- Lua 5.1 syntax check on both files.
- In game, Retail: open a merchant, the filter menu's class submenu lists the specs; open the bulk purchase window on an item. `Read-GameErrors.ps1` with no new Extended Vendor UI error after a second `/reload`.

## Decision
Option 1, chosen by Krowi on 2026-10-14 ("All five lines").