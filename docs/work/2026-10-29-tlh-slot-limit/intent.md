# Intent: Transmog Loot Helper's icons stop after the 99th slot
Author: Krowi (maintainer), from the known-debt list in `CLAUDE.md`. Source: known debt (found 2026-10-24 on GitHub #97, rechecked 2026-10-29). Status: draft

## Problem
Transmog Loot Helper (TLH) draws its collection icons on the addon's slots itself since its 12.1.5-02 (its `integrations/Krowi_ExtendedVendorUI.lua` and `app:MerchantOverlay`). That code reaches only the first 99 slots, so with a larger grid the items after slot 99 get no TLH icon. The grid can be up to 99 by 99; the presets already pass 99 slots at 10 columns by 10 rows. It was reported to TLH's author on #97. TLH is not installed on the Retail client today, so its current release is unchecked.

## Proposed outcome
With TLH on, every item in the grid shows TLH's icon, whatever the grid size. The fix belongs to TLH; the addon helps only if TLH's public API allows it.

## Affected users and systems
- Clients: Retail and WoW Forever (TLH's clients).
- Players with TLH and a grid of more than 99 slots.
- `Plugins/TransmogLootHelper.lua`, which calls TLH's public `UpdateOverlay` after each draw.

## Constraints
- The plugin method signatures in `Api/PluginsApi.lua` stay as they are.
- No copy of TLH's code in this repo.

## Open questions
- Has TLH changed its loop since 12.1.5-02?

## Exploration steps
1. Get TLH's newest release and read its Krowi integration for the slot loop bound.
2. If it still stops at 99: check whether TLH's `UpdateOverlay` takes a slot, so `Plugins/TransmogLootHelper.lua` could pass every slot itself.
3. With Krowi's go, follow up on #97 with the finding (a GitHub write).
4. In game: install TLH on Retail, set the grid to 10 columns by 12 rows, run `/kevutest` and check its TLH evidence on page 1.