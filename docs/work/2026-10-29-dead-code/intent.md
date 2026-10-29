# Intent: Remove dead code and a stale editor global
Author: Krowi (maintainer), from the known-debt list in `CLAUDE.md`. Source: known debt (found 2026-10-15, rechecked 2026-10-29). Status: accepted

## Problem
Nothing is broken for players. The code carries pieces nothing uses, which cost reading time and mislead searches:
- `addon.IsWrathClassic` and `addon.IsDragonflightRetail` (`Krowi_ExtendedVendorUI.lua:7-8`): nothing reads them. The `IsWrathClassic` in `Tests/Tests.lua:52-57` is Krowi_Util's flag, not this one.
- `filters:RefreshFilters` (`Filters.lua:227-231`): its body is commented out, but `filters:Load` registers it for AceDB's `OnProfileChanged`, `OnProfileCopied` and `OnProfileReset` (lines 235-237).
- `Gui/TokenBanner/TokenBannerMixin.lua` (only `local _, addon = ...`, loaded by `TokenBanner.xml:4`) and `Options/Options.lua` (only two locals, loaded by `Options/Files.xml:3`).
- `.vscode/settings.json:152` still lists `MerchantFrame_SetFilter`, which no longer exists. The page-control globals (`KrowiEVU_MerchantPrevPageButton`, `KrowiEVU_MerchantNextPageButton`, `KrowiEVU_MerchantPageText`) are listed now (lines 1020-1022), so that part of the old debt entry is done.

## Proposed outcome
The pieces are gone, with no visible change on any client.

## Affected users and systems
- Code only: `Krowi_ExtendedVendorUI.lua`, `Filters.lua`, `Gui/TokenBanner/`, `Options/`, `.vscode/settings.json` (not shipped).

## Constraints
- The public API (`KrowiEVU`, `KrowiEVU_MerchantItemsContainer`) does not change.
- Lines that are not otherwise changed are not restyled.

## Open questions
- `RefreshFilters`: remove it with its callbacks, or should a profile change refresh the filters? Every character uses the shared `Default` profile, so a profile change is rare.

## Exploration steps
1. `Find-Symbol.ps1` for each symbol, and grep the other Krowi repos (Krowi_Vendorer reads this addon) and the built-in plugins for anything that reads them.
2. Read what a profile switch or reset does to the active filter today (Profiles page, `Options/Profiles.lua`) to settle `RefreshFilters`.
3. Remove the files from their `Files.xml`/`.xml` and delete them; deploy and `/reload` on one Retail and one Classic client, then `Read-GameErrors.ps1`.
4. Remove `MerchantFrame_SetFilter` from `.vscode/settings.json` by hand.