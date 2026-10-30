# Spec: Bulk Purchase's room in the bags
Author: Claude, from `/kevutest` on Retail (2026-10-29, run 10 at Alice Fischer). Status: done

## Problem (intent folded in: found by the test, no player report)
Bulk Purchase's "You can fit", which caps Max, is too high on Retail and WoW Forever with a reagent bag and too low on the Classic clients when the bags hold the item already. Buying the maximum on Retail then ends with Inventory is full for the purchases past the real room; on Classic Max stops short of what fits.

Reproduction, `/kevutest` run 10 on Retail: bags `0: 0 free; 1: 30; 2: 19; 3: 7; 4: 1; 5: 13 free, type 0, slot 35 with a bag`, and "room for 70 of item 184058 (stack 1)", a PvP medallion; 57 fit, since bag 5 is the reagent bag.

The same run showed that 24.2's earlier changelog line "Bulk Purchase no longer gives an error with a reagent bag equipped" was wrong: the old `GetInventorySlotInfo('Bag4Slot')` returned nil without an error, and with bag type 0 the code never reached it. That line is replaced.

## Root cause
- `Gui/BulkPurchase/BulkPurchaseMixin.lua`, `GetFreeBagSpace`: a bag of type 0 always counts. The reagent bag reports type 0 from `C_Container.GetContainerNumFreeSlots` (seen in game), while Blizzard tells it apart only by its index (live `Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua:86-88`, `ContainerFrame_IsReagentBag(id)` is `id == 5`; Forever the same at 104-106; `Enum.BagIndex.ReagentBag` 5 in both). It takes crafting reagents only: `C_Item.GetItemInfo`'s 17th return `isCraftingReagent` (live and Forever `ItemDocumentation.lua`).
- The Classic branch of the partial-stack loop read `C_Container.GetContainerItemInfo` as multiple returns; on classic, classic_anniversary and classic_era it returns a `ContainerItemInfo` table (their `ContainerDocumentation.lua:165-167`), so `slotItemID` was always nil.

## Requirements
1. On Retail and Forever, bag 5 counts toward the room only for an item that is a crafting reagent; an item without data yet counts as none (too little room rather than failed purchases).
2. On every client, the room includes what still fits on the stacks of the item already in a counted bag.
3. `/kevutest`'s `all` step checks the room against its own count from the bags, for the first item and, on Retail and Forever, the vendor's first crafting reagent.

## Decision
Krowi, 2026-10-29: fix it tonight, in 24.2, before the remaining clients' runs.

## Areas of concern
- Taint and secret values: `C_Item.GetItemInfo` and the container APIs declare no secret returns; the room is only read by the addon's own frame. `krowi:taint-reviewer` on the diff.
- Clients: the bag 5 rule runs only where `IsModern` (the loop stops at bag 4 elsewhere); the table form on every client.
- Saved variables, localization, libraries, other addons: none.
