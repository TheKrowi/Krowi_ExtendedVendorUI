# Intent: Highlight known items on the vendor grid
Author: Krowi (chat, 2026-11-04). Status: draft (split from `docs/work/62-already-known/`; waits for it)

## Problem
Already Known (ahakola) tints known items on vendors through a `MerchantFrame_UpdateMerchantInfo` post-hook on Blizzard's `MerchantItem1-10` (`AlreadyKnown.lua:454-474`, 1.104). Up to 22.2 that reached this addon's grid because the addon used Blizzard's slot names, `MERCHANT_ITEMS_PER_PAGE` and a replaced `GetMerchantItemLink` (22.2 `Gui/MerchantItemsContainer.lua:75, 91`, `Gui/MerchantFrame.lua:185-210`). Since 23.0 the grid is `KrowiEVU_MerchantItem<N>` and Blizzard's slots are hidden, so its tint lands on hidden buttons: no tint, no error, on every client.

## Proposed outcome
An option of this addon marks known items in place, built on the Already known check of `docs/work/62-already-known/`, so players see the whole list with known items marked, with or without Already Known. Already Known stays useful for the auction house and guild bank, and does not conflict: its vendor tint lands on Blizzard's hidden slots.

## To explore
- Options: on or off (default, and whether on by default when Already Known is loaded so its players see no change), color, gray icon; possibly a second color for recipes another character knows (the recipe record has it).
- Where the tint goes: right after the slot's own colors in `Gui/MerchantItemSlot.lua` (`Tint`), not a plugin.
- Which kinds it marks: the Hide collected categories' own checks plus the uncategorized Already known items, or only the Already known line.
- `/kevutest`: with Already Known on, its verdict on Blizzard's hidden slots for vendor items 1-10 against this addon's, as a note of the differences.