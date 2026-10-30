# Plan: Bulk purchase calls the deprecated GetInventorySlotInfo
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

## Files that change
- `Gui/BulkPurchase/BulkPurchaseMixin.lua`: the local `GetInventorySlotInfo_` and its use in `HasBagEquippedInSlot` (commit 9f7d12d).
- `CLAUDE.md`: the debt entry goes.

## Proof
The spec's Verification on Retail and one Classic client. On Retail, also once with a reagent bag equipped: the taint review of 2026-10-29 found that bag 5 asks for `Bag4Slot`, while the reagent bag's slot is `ReagentBag0Slot`. That predates this change (the old global was the same function).

## Where the build departed
The reagent bag finding is fixed here too (Krowi, 2026-10-29: "tackle the things you know so far"). `HasBagEquippedInSlot` now asks Blizzard's own mapping, `C_Container.ContainerIDToInventoryID(bag)`, which every client's API docs list (`ContainerDocumentation.lua:20` in live, forever, classic, classic_anniversary and classic_era) and Blizzard's bag code uses (live `Mainline/ContainerFrame.lua:91`). It returns `ReagentBag0Slot`'s id for bag 5, so `GetInventorySlotInfo` is no longer needed at all and the local `GetInventorySlotInfo_` is gone. `/kevutest`'s `all` step now notes every bag's type and slot, what the old `Bag4Slot` lookup returns, and works out Bulk Purchase's room for the vendor's first item without buying; tonight's run with a reagent bag equipped shows whether the old lookup errored, which decides the changelog line's wording.