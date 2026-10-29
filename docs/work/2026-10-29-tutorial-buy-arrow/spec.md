# Spec: The new-player tutorial points at a hidden vendor slot
Intent: [intent.md](intent.md). Status: draft

## Requirements
1. With Direction Rows (the default), the tutorial's buy arrow points at the addon's second item slot, and `/kevutest` checks it on every Retail and Forever run.
2. With Direction Columns, the behaviour follows the decision below.
3. The addon writes nothing into the tutorial and gives Blizzard's `MerchantItem2` only method calls (`ClearAllPoints`, `SetPoint`, `Hide`).

## Root cause
`Class_UseVendor:MerchantTabHelp` (live `Blizzard_NewPlayerExperience/Blizzard_TutorialTutorials.lua:2388-2405`, forever `:2448`) adds a pointer with `AddPointerTutorial(..., "LEFT", MerchantItem2, 0, 0)` each time the merchant tab shows, until the player buys something (`BAG_NEW_ITEMS_UPDATED`). `NPE_TutorialPointerFrame:Show` (`Blizzard_TutorialManager/Blizzard_TutorialPointerFrame.lua:47`) checks only that the anchor exists, not that it is visible, so the arrow shows next to wherever the hidden `MerchantItem2` sits.

Where that is:
- Blizzard's XML puts `MerchantItem1` at `TOPLEFT` 11, -69 of `MerchantFrame` and `MerchantItem2` 12 to the right of it (live `Mainline/MerchantFrame.xml:127-136`).
- The addon places its slots from the same origin and spacing (`Gui/MerchantItemsContainer.lua:9-11`, `PlaceItemSlot` at `:84-89`). With Rows, slot 2 is row 1, column 2 (`:101-109`), the exact spot of `MerchantItem2`; the grid always has at least 2 columns (the custom columns input starts at 2).
- With Columns, row 1, column 2 holds slot `NumRows + 1` (`:92-99`), so the arrow points at the first item of the second column, or at an empty spot when the vendor has no more than `NumRows` items. After a visit to Buyback, the buyback layout (`:249`, 6 rows by 2 columns in the same direction) leaves `MerchantItem2` at row 2, column 1, which is slot 2 with Columns, so from then on the arrow is right there too.

So with the default setting players see the arrow at the second item, as Blizzard intends. No player has reported it.

## Design
Option 1 (recommended): no change to the placement. Add a `/kevutest` check on the merchant tab, Retail and Forever, Direction Rows: `MerchantItem2`'s left and top match `KrowiEVU_MerchantItem2`'s within a pixel, named "the tutorial's buy arrow lands on slot 2". With Columns the check records an INFO line instead. Write the Columns case down in `CLAUDE.md` as a known limit and drop the debt entry.

## Options considered
1. **Recommended: leave the placement, guard it with `/kevutest`, accept the Columns case.** What a new player sees: with Rows, the arrow at the second item; with Columns, the arrow at the first item of the second column until they visit Buyback once. The test catches any later layout change that moves slot 2.
2. **Also keep Blizzard's hidden `MerchantItem2` on the addon's slot 2 in both directions.** After each merchant-tab layout, `MerchantItem2:ClearAllPoints()` and `SetPoint('TOPLEFT', KrowiEVU_MerchantItem2)`. What a new player sees: the arrow at the second item in both directions. Costs a write to a Blizzard frame's anchor on every layout, which the buyback layout already does; `/kevutest` checks it in both directions.
3. **Do nothing.** The arrow stays right with Rows, but nothing guards it.

## Areas of concern
- **Taint and secret values:** option 1 only reads frame positions in `/kevutest`. Option 2 adds method calls on `MerchantItem2` (allowed by the repo's rules; the buyback layout already makes them). Neither touches the tutorial.
- **Clients:** Retail and Forever have the tutorial file (Forever's game may not run Exile's Reach); the Classic clients have no such tutorial, so the check runs on `IsModern` only.
- **Other addons, plugins and skins:** ElvUI, GW2_UI and EllesmereUI skin the addon's slots, not their position; the check compares positions, not looks.
- **Saved variables, localization, embedded libraries:** none.
- **Player-facing text:** option 1, none; option 2, no changelog line needed (a new player would not notice a difference worth one).

## Verification
- `/kevutest` on Retail with Rows: the new check passes. Switch to Columns in the options and run again: option 1 records the INFO line; option 2 passes.
- No Exile's Reach run: the position check proves the same thing without a new character.

## Built ahead of the decision (2026-10-29)
The `/kevutest` check both options need is in the `all` step (`CheckTutorialArrow`): PASS or FAIL with Rows, an INFO line with Columns. Option 2 would only add the anchor and turn the Columns line into a check.

## Decision