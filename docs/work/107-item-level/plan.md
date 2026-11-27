# Plan: An item level range for vendor gear
Spec: [spec.md](spec.md). Status: accepted (Krowi, 2026-11-27: "Go")

## Files that change
- `Filters.lua` (tabs): `defaults.profile.Gear` gains `MinItemLevel = 0` and `MaxItemLevel = 0`. `filters.ItemLevelShown = addon.Util.IsModern or addon.Util.IsMistsClassic` (the clients that show item levels; both flags exist in Krowi_Util 2.8, `Krowi_Util.lua:22`). `ValidateGear`: the early return also passes when both bounds are 0 or the client is not one of those; after the weapons-and-armor test, the level from `C_Item.GetDetailedItemLevelInfo(GetMerchantItemLink(index))`, nil kept, below the minimum or above the maximum hidden. A helper `filters:SetItemLevelBound(key, value)` writes one bound, moves the other when the range would be inverted (requirement 4), and redraws with `self:SetFilter(self:GetFilter())`.
- `Gui/FilterButton/FilterButtonMixin.lua` (tabs): after the Minimum quality submenu, when `filters.ItemLevelShown`, two submenus built by one local function: an Off radio (Blizzard's `OFF`; first built with `NONE` as Minimum quality uses, changed at the look gate), a radio with the current value when one is set, a divider, Set custom opening `LibStub('Krowi_PopupDialog_2').ShowNumericInput` (0 to 9999, default the current value) whose callback calls `SetItemLevelBound`.
- `Localization/enUS.lua`: `Minimum item level`, `Maximum item level`, `Enter the minimum item level` and `Enter the maximum item level` below the marker (the last two with " (0 for off):" in their English text, as the rows prompt shows its range). `deDE`, `frFR`, `itIT`, `ruRU`, `zhCN`: those four translated, plus the Gear section's older strings each one lacks (`Gear`, `Only usable items`, `Hide sub-optimal armor`, `Minimum quality`, `Set custom`, and for itIT `Custom`), so the whole Gear section is translated in every locale (WowAddons.md, Localization).
- `Tests/Tests.lua` (4 spaces): `CheckGear` adds the level test to `breaks` where the option applies and notes the levels it saw; a new step `gear-item-level` after `gear`: `RestoreOptions()`, then a range from the vendor's distinct weapon and armor levels (above the lowest; below the highest when there are three or more), noted in the step text, filter All; SKIP on Era and Anniversary and at a vendor without gear. Built departure: at a vendor whose gear has one level the minimum is set one above it, so every piece must go (Knight-Lord Bloodvalor's 63 pieces are all 289; Krowi has no Alliance-reachable vendor in Silvermoon with several levels at hand, 2026-11-27). `RestoreOptions` puts both new fields back.
- `_Packaging/Changelog.md`: a new `## 24.6` entry, `### Added`: "Gear options Minimum item level and Maximum item level in the filter menu, to show only weapons and armor in an item level range (Retail, WoW Forever, Mists Classic)". No date until release day.
- `CLAUDE.md`: the Filters paragraph names the item level range among the Gear options; the testing paragraph names the new step.

## Order of work
1. `Filters.lua` defaults, `ValidateGear`, `SetItemLevelBound`; syntax hook.
2. The test step and `CheckGear` (the permanent test), so the first in-game run proves requirements 2, 3 and 8.
3. The menu and the strings.
4. Changelog and `CLAUDE.md`.
5. `Find-DeprecatedApi.ps1`, `krowi:taint-reviewer` on the diff (`Filters.lua` and the filter button are taint-sensitive per `CLAUDE.md`).
6. Deploy to Retail, show Krowi the Gear section and a range in use (the `look` gate) before any full run; then `/kevutest` on Retail, Forever and Mists, and on Era and Anniversary to see the step SKIP and nothing else change.

## Risks
- **Uncached items:** `GetMerchantItemLink` or the level can be nil on the first build; such rows stay (as the other Gear checks), and Retail rebuilds when item data arrives. The test notes how many pieces had no level.
- **The level of a link versus what the tooltip shows** (upgrade tracks, scaling heirlooms): the filter uses `actualItemLevel`, the first return, which is the tooltip's number; the test's note lists a few levels to compare by eye.
- **An emptied list:** a range can hide every piece at a vendor; that is the player's choice, and Off sits at the top of each submenu.
- **The Mists flag:** `IsMistsClassic` is the 5.x build test; the Mists run shows the submenus.

## Proof
- Syntax hook clean; `Find-DeprecatedApi.ps1` nothing new; taint review with no new finding.
- Retail screenshot of the filter menu's Gear section with both submenus and a value set; the grid without the gear outside the range.
- `/kevutest` on all five clients with no failed check; `gear-item-level` PASS on Retail, Forever and Mists and SKIP on Era and Anniversary; `Read-GameErrors.ps1` with no new row.
