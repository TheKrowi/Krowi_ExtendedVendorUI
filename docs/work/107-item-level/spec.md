# Spec: An item level range for vendor gear
Intent: [intent.md](intent.md). Status: done (accepted by Krowi, 2026-11-27)

## Requirements
1. Two Gear options in `KrowiEVU_Filters`, `Gear.MinItemLevel` and `Gear.MaxItemLevel`, each 0 (off) by default.
2. With a minimum set, a weapon or armor piece whose item level is below it is not in the list; with a maximum set, one above it is not. Equal counts as inside. Under every filter, at every vendor, like the other Gear options; items that are not weapons or armor are never hidden by it.
3. The item level is the one the vendor sells: `C_Item.GetDetailedItemLevelInfo(GetMerchantItemLink(index))`, not the item id's base level. A row whose link or level is not known yet stays in the list.
4. The player sets each value from the filter menu's Gear section: a submenu per bound with Off, the current value when set, and Set custom, which opens Krowi_PopupDialog's number input (0 to 9999, 0 is off). Each bound works alone: a minimum without a maximum, or a maximum without a minimum (Krowi, 2026-11-27). Setting a minimum above the maximum moves the maximum up to it, and the other way round, so the range never empties the list by itself.
5. Changing a value redraws the list from page 1, as the other Gear options do.
6. Clients: the two submenus show on Retail, WoW Forever and Mists Classic, where the game shows item levels to the player. On Classic Era and TBC Anniversary they do not show, and `ValidateGear` ignores the two values there.
7. Every new text is in every locale file the repo ships.
8. `/kevutest`'s Gear step also sets a range from the vendor's own item levels and checks that no piece outside it is in the list; the run puts the values back.

## Design
- `Filters.lua`: the two defaults; `ValidateGear` reads the level only when a bound is set (its early return gains the two fields), after the weapons-and-armor test, from the vendor's link.
- `Gui/FilterButton/FilterButtonMixin.lua`: after Minimum quality, two submenus, Minimum item level and Maximum item level, built like the options button's custom rows (`Gui/OptionsButton/OptionsButtonMixin.lua:133-164`): an Off radio, a radio with the current value when set, a divider, Set custom. The callbacks write the value, apply requirement 4, and call `addon.Filters:SetFilter(addon.Filters:GetFilter())`.
- `Localization/*.lua`: Minimum item level, Maximum item level, Enter the minimum item level, Enter the maximum item level.
- `Tests/Tests.lua`: `CheckGear` adds the level test to `breaks`; the Gear step picks a range from the vendor's own weapon and armor levels (the lowest excluded, the highest excluded when there are three or more distinct levels) and notes it; the restore puts both fields back.

## Options considered
1. **Filter menu submenus with a number popup (recommended).** The pattern the options button already uses for rows, columns and housing quantity, so the player sets it where the other Gear options are, at the vendor.
2. **Options page sliders.** AceConfig `range` controls on a Gear group; one more place to look, away from the vendor, and Gear has no options page yet.
3. **Presets only.** Item levels differ per client and expansion, so no fixed preset list fits.
4. **Equipped item level as a preset for the minimum** (`GetAverageItemLevel`, Retail and Mists; not in Classic Era's or Anniversary's interface). Useful for "only upgrades"; left out unless asked, since #107's answer is still pending.

## Areas of concern
- **Taint and secret values:** no Blizzard frame, function or popup is touched; the menu is Krowi_Menu's, the popup Krowi_PopupDialog's own `KROWI_NUMERIC_INPUT`, already used by the options button. `GetDetailedItemLevelInfo` takes secret arguments only when untainted, but a merchant link is not secret. `ValidateGear` runs inside `BuildList`, already on the `MerchantFrame_UpdateMerchantInfo` post-hook path; one more API read there changes nothing. No taint review needed beyond the usual run for `Filters.lua` and the filter button (taint-sensitive per `CLAUDE.md`).
- **Clients:** `GetDetailedItemLevelInfo` and `GetMerchantItemLink` exist on every branch (`Blizzard_APIDocumentationGenerated/ItemDocumentation.lua` in live, forever, classic, classic_anniversary, classic_era). Era and Anniversary keep item levels in the data but never show them.
- **Blizzard API changes:** none; nothing deprecated (`Find-DeprecatedApi.ps1` after the build).
- **Other addons and plugins:** none; the slots and the list contract do not change.
- **Saved variables:** two fields with AceDB defaults; no migration, no version field.
- **Localization:** four strings in enUS, deDE, frFR, itIT, ruRU and zhCN.
- **Embedded libraries:** none change.
- **Player-facing text:** a changelog line under Added.

## Verification
- `/kevutest` on every client the option shows on: the Gear step with a range, at a vendor with gear of several item levels; on the other clients the step runs as before.
- In game on Retail first (the `look` gate): the Gear section with the two submenus, a value set through the popup, gear outside it gone.
- #56's case, if Krowi wants it: at a Castle Nathria weapon vendor in a covenant sanctum, a maximum below the Fated levels hides the Fated rows (proves requirement 3 against real Fated links).

## Decision
Krowi, 2026-11-27:
- Intent accepted; build now without waiting for Dubhe's answer; #56 stays open ("Build, keep #56 open").
- Option 1, the filter menu with the number box, with the note "an empty field is ignored so we can also only set a min or max ilvl if we want": each bound is optional (requirement 4). Krowi_PopupDialog leaves the value as it was when the box is accepted empty; Off or 0 turns a bound off.
- Retail, WoW Forever and Mists Classic only (requirement 6).
- No equipped item level preset for now (option 4).
