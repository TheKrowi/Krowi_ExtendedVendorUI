# Plan: Bulk purchase calls the deprecated GetInventorySlotInfo
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

## Files that change
- `Gui/BulkPurchase/BulkPurchaseMixin.lua`: the local `GetInventorySlotInfo_` and its use in `HasBagEquippedInSlot` (commit 9f7d12d).
- `CLAUDE.md`: the debt entry goes.

## Proof
The spec's Verification on Retail and one Classic client.