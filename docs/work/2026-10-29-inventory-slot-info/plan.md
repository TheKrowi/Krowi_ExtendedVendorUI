# Plan: Bulk purchase calls the deprecated GetInventorySlotInfo
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

## Files that change
- `Gui/BulkPurchase/BulkPurchaseMixin.lua`: the local `GetInventorySlotInfo_` and its use in `HasBagEquippedInSlot` (commit 9f7d12d).
- `CLAUDE.md`: the debt entry goes.

## Proof
The spec's Verification on Retail and one Classic client. On Retail, also once with a reagent bag equipped: the taint review of 2026-10-29 found that bag 5 asks for `Bag4Slot`, while the reagent bag's slot is `ReagentBag0Slot`. That predates this change (the old global was the same function) and is on the known-debt list.