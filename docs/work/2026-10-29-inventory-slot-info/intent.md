# Intent: Bulk purchase calls the deprecated GetInventorySlotInfo
Author: Krowi (maintainer), from the known-debt list in `CLAUDE.md`. Source: known debt (`Find-DeprecatedApi.ps1`, 2026-10-19 and 2026-10-22; rechecked 2026-10-29). Status: accepted

## Problem
The Bulk Purchase window counts the free bag space for an item. `HasBagEquippedInSlot` (`Gui/BulkPurchase/BulkPurchaseMixin.lua:54-57`) calls the global `GetInventorySlotInfo`. Retail 12.1.5 and Forever 1.60.1 deprecated it for `C_PaperDollInfo.GetInventorySlotInfo`. On both, the old global exists only while the `loadDeprecationFallbacks` CVar is on (`Deprecated_PaperDoll.lua:4-8`). When Blizzard removes the fallback, as 12.1.5 did for other globals (which broke Krowi's Vendorer), the Bulk Purchase window errors on Retail and Forever. The Classic clients have no `C_PaperDollInfo.GetInventorySlotInfo` (absent from the classic, classic_anniversary and classic_era API docs) and keep the global.

## Proposed outcome
Bulk Purchase keeps working on every client after Blizzard removes the old global, with no visible change.

## Affected users and systems
- Clients: Retail and WoW Forever (the new API); Mists, Anniversary and Era keep the global.
- Window: Bulk Purchase (shift-click on a vendor item with Bulk Purchase on), the "You can fit" count.

## Constraints
- Never assign into `C_PaperDollInfo` or any `C_*` namespace: a file-local function picks the API.
- The addon never sets the CVar.
- The same bag-space result on every client.

## Open questions
None.

## Exploration steps
1. Compare `C_PaperDollInfo.GetInventorySlotInfo` (live and forever `PaperDollInfoDocumentation.lua`) with the old global's returns, and read `Deprecated_PaperDoll.lua` for how the fallback maps them.
2. Read the default of `loadDeprecationFallbacks`. If a player can have it off today, the window already errors for them: in game, read it only (`/dump C_CVar.GetCVar('loadDeprecationFallbacks')`), never set it.
3. Run `Find-DeprecatedApi.ps1` for live, forever and classic for anything else deprecated since 2026-10-22.
4. Follow the pattern of `docs/work/2026-10-14-deprecated-api/` (done) for the shim.
5. Test on each client with a cheap stack item: shift-click, check "You can fit" with an empty and a full bag, then `Read-GameErrors.ps1`.