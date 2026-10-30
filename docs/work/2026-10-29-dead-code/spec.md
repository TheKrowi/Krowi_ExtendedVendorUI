# Spec: Remove dead code and a stale editor global
Intent: [intent.md](intent.md). Status: accepted (Krowi, 2026-10-29: "tackle the things you know so far")

## Requirements
1. `addon.IsWrathClassic`, `addon.IsDragonflightRetail` and the version locals that only fed them are gone from `Krowi_ExtendedVendorUI.lua`.
2. `filters:RefreshFilters` and its three AceDB callbacks are gone from `Filters.lua`.
3. `Gui/TokenBanner/TokenBannerMixin.lua` and `Options/Options.lua` are deleted and no longer loaded.
4. `.vscode/settings.json` no longer lists `MerchantFrame_SetFilter`.
5. Nothing changes for players on any client.

## Findings
- No file reads `addon.IsWrathClassic` or `addon.IsDragonflightRetail`; `Tests/Tests.lua:52-57` reads Krowi_Util's flags. Other addons cannot read the private `addon` table.
- `RefreshFilters`: every reader of the filter profile reads `addon.Filters.db.profile.<key>` or `self.db.profile.<key>` at the moment it filters (`Filters.lua`, `Gui/FilterButton/FilterButtonMixin.lua`, `Gui/OptionsButton/OptionsButtonMixin.lua`, `Tests/Tests.lua`); nothing keeps a profile subtable. A profile change, copy or reset therefore takes effect on the next list rebuild without a refresh. The commented-out body refers to `addon.Tabs`, which no longer exists. Removing the method without the callbacks would make AceDB's `RegisterCallback` fail, so both go.
- `TokenBannerMixin.lua` holds only `local _, addon = ...`; `Options/Options.lua` only `local _, addon = ...` and `local options = addon.Options`.

## Areas of concern
Taint: none (only removals; no Blizzard frame involved). Clients: all, same code. Saved variables, localization, libraries, player text: none.

## Verification
`/kevutest` on Retail and one Classic client: no Lua error from this addon (its last step), and the window as before.
