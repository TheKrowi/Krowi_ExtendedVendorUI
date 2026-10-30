# Spec: Bulk purchase calls the deprecated GetInventorySlotInfo
Intent: [intent.md](intent.md). Status: accepted

## Requirements
1. On Retail and Forever, Bulk Purchase reads the bag slots through `C_PaperDollInfo.GetInventorySlotInfo`, so it works without `loadDeprecationFallbacks`.
2. On Mists, Anniversary and Era it keeps the global, which is all they have.
3. "You can fit" shows the same number as before on every client.

## Root cause
`Gui/BulkPurchase/BulkPurchaseMixin.lua:54-57` (`HasBagEquippedInSlot`) calls the global `GetInventorySlotInfo`. On Retail 12.1.5 and Forever 1.60.1 the global is only `Deprecated_12_x`'s alias, `GetInventorySlotInfo = C_PaperDollInfo.GetInventorySlotInfo`, defined only while the `loadDeprecationFallbacks` CVar is on (live `Deprecated_PaperDoll.lua:4-8`). The new API takes the same slot name and returns the same `invSlot, slotTexture, checkRelic` (live and forever `PaperDollInfoDocumentation.lua`). The Classic API docs have no `C_PaperDollInfo.GetInventorySlotInfo`.

## Design
A file-local `GetInventorySlotInfo_ = C_PaperDollInfo and C_PaperDollInfo.GetInventorySlotInfo or GetInventorySlotInfo` next to the file's other API locals; nothing is written into `C_PaperDollInfo`.

## Options considered
Only this one: it is the pattern of `docs/work/2026-10-14-deprecated-api/`.

## Areas of concern
- **Taint and secret values:** the new API has `SecretArguments = "AllowedWhenUntainted"`; the slot name is a constant string built by the addon, not a secret, so a tainted caller passes it as before.
- **Clients:** as in the requirements.
- **Blizzard API changes:** this is one. `Find-DeprecatedApi.ps1` (live and forever, 2026-10-29) still names line 15, the Classic fallback in the local, which runs only where `C_PaperDollInfo` lacks the function.
- **Other addons, saved variables, localization, libraries, player-facing text:** none; no changelog line, since players see no change.

## Verification
Each client: shift-click a cheap stack item with Bulk Purchase on, check "You can fit" with free bag space and with full bags, then `Read-GameErrors.ps1`.

## Decision
Krowi, 2026-10-29: no open question, built without a gate ("tackle the things you know so far").