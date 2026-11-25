# Plan: Highlight known items on the vendor grid
Spec: [spec.md](spec.md). Status: accepted (Krowi, 2026-11-25); building

## Files that change
1. `Filters.lua` (tabs): `defaults.profile.MarkCollected = { Enabled = nil }`, where nil means "follow Already Known": on while it is loaded. `filters.IsCollected(itemId)`: the category's own `Is<Category>Collected`, in `Validate`'s order, else `filters.IsKnown` for an item in no category. `filters:IsMarkCollectedOn()`: the saved value, or `C_AddOns.IsAddOnLoaded('AlreadyKnown')` while it is nil. `filters:GetMarkLook()`: Already Known's `r, g, b, monochrome` from `AlreadyKnownSettings` while it is loaded and has them, else the addon's own (`0, 1, 0`, gray off).
2. `Gui/MerchantItemSlot.lua` (4 spaces): `MarkCollected(slot, itemId)` after `Tint` in `DrawMainline` and `DrawClassic`, with the `merchantItemID` both already read. Look A (tint): the four `SetItemButton*VertexColor` calls as Already Known makes them (name frame and slot at the color, icon and normal texture at 90 %), plus `SetItemButtonDesaturated` when gray is on. Look B (gray): Blizzard's own known-heirloom look, `SetItemButtonDesaturated(itemButton, true)` and the 0.5 gray tint of `Tint`'s first branch. The look is a temporary file-local switch, set from a temporary radio pair in the filter menu, removed after the `look` gate.
3. `Gui/FilterButton/FilterButtonMixin.lua` (tabs): after the Hide collected section's last checkbox, `mb:CreateCustomCheckbox(menu, addon.L['Mark collected items'], isChecked = filters:IsMarkCollectedOn(), onClick = write the opposite as an explicit boolean, then `addon.Filters:SetFilter(addon.Filters:GetFilter())` as the Gear quality radio does, which redraws the page)`. The temporary look radios go right under it.
4. `Localization/*.lua`: `Mark collected items` below the `AUTOGENTOKEN` marker in `enUS.lua` (`= true`) and translated in `deDE`, `frFR`, `itIT`, `ruRU`, `zhCN`.
5. `Tests/Tests.lua` (4 spaces): `CheckMarkCollected()`, a step after the Hide collected Recipes and Other step: option on, for each shown slot, marked exactly when `filters.IsCollected` says so (read from the slot's icon desaturation and name frame color against the look), with the count of marked slots noted; option off, no slot marked; the saved value (nil included) put back in `Restore`.
6. `_Packaging/Changelog.md`: a new `## 24.5` section, `### Added`: "Option Mark collected items in the filter menu: known items stay in the list, marked (on by default with Already Known, in its color)".
7. `CLAUDE.md`: the option in Architecture's Filters paragraph; drop nothing from Known debt (this item was not listed there).

## Order of work
1. Reproduce: Retail with Already Known ticked on Krowi's character, a vendor with known items: no tint on the grid (screenshot). Already Known is not installed in any client now: Krowi installs it, or I copy its 1.107 release zip from CurseForge into Retail's AddOns (a third-party addon in Krowi's client; I ask before doing that).
2. `Filters.lua` check and setting, then the slot mark with both looks, then the menu checkbox and look radios, then the locale strings.
3. Syntax hook on each file, `Find-DeprecatedApi.ps1`, `krowi:taint-reviewer` on the diff (draw path and filter menu are taint-sensitive).
4. Deploy to Retail only, `/reload`, a vendor with known items: **look gate** (Krowi toggles both looks, with and without Already Known). Krowi's choice is built in and the radios removed.
5. `/kevutest` step, then the full `/kevutest` on all five clients, and Retail again under ElvUI if Krowi runs the skin series.
6. Changelog, `CLAUDE.md`, PR.

## Risks
- `IsCollected` runs per drawn slot on every draw (up to 28 slots, more with a large grid); the tooltip read for items in no category is the cost. Hide collected Other already does the same per item over the whole list, so a page is cheaper; the build time `/kevutest` notes shows whether it is not.
- An item whose data arrives late is marked only on the next draw: the existing `GET_ITEM_INFO_RECEIVED` path redraws, as for quality.
- A Classic transmog check (`C_TransmogCollection.PlayerHasTransmog`) may not exist on every Classic client; `IsTransmogCollected` is already called by Hide collected there, so the same guard holds, but `IsCollected` must not call a category check `Validate` never reaches on that client.
- Skins (ElvUI, GW2_UI, EllesmereUI) may hide the slot textures the tint colors; the icon tint and gray stay. Checked at the look gate if Krowi has them on.

## Departures during the build
- The look became a setting after the look gate (spec, Decision): `MarkCollected.Look` and `Color`, `filters.MarkLooks`, `filters:GetMarkColor` (nil for Gray) instead of `GetMarkLook`; the filter menu got a Collected items title with the checkbox and three look radios; `Options/General.lua` got a Collected items tab (checkbox, look, color swatch). The temporary look radios and the preview switch used for the screenshots are gone.
- `/kevutest`'s step turns every Hide collected option off first (Krowi keeps them all on but Other, so nothing collected would be in the list), checks with look Color, then checks with the option off; the saved `HideCollected` and `MarkCollected` go back in `RestoreOptions`.
- itIT gained `Hide collected` ("Nascondi collezionati"), which the new description names.

## Proof
`/kevutest`'s new step passing on all five clients, the look approved on Retail, `Read-GameErrors.ps1` clean after each run, the taint reviewer's verdict in the PR.