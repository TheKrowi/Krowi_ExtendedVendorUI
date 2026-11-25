# Intent: Highlight known items on the vendor grid
Author: Krowi (chat, 2026-11-04 and 2026-11-25), from sijil82's CurseForge comment of 2026-10-29: "The latest version seems to not play nice with Already Known (https://www.curseforge.com/wow/addons/alreadyknown) - that addon stops working when this one is enabled. It worked fine up until this week I think. No idea why though, there's no errors being thrown." (no reply yet). Source: idea, CurseForge comment. Status: accepted (Krowi, 2026-11-25)
Caused by: 23.0's addon-owned grid (`docs/work/2026-10-18-addon-owned-grid/`), not a pull request of its own.

## Problem
Already Known (ahakola) tints known items on vendors through a `MerchantFrame_UpdateMerchantInfo` post-hook on Blizzard's `MerchantItem1-10` (`AlreadyKnown.lua:461-481` on Retail, `AlreadyKnownClassic.lua:574-592` on the Classic clients and WoW Forever, 1.107). It only tints and never hides: name frame and slot in its color (green by default), the icon at 90 % of it, and gray with its monochrome setting. Up to 22.2 that reached this addon's grid because the addon used Blizzard's slot names, `MERCHANT_ITEMS_PER_PAGE` and a replaced `GetMerchantItemLink` (22.2 `Gui/MerchantItemsContainer.lua:75, 91`, `Gui/MerchantFrame.lua:185-210`). Since 23.0 (2026-10-21) the grid is `KrowiEVU_MerchantItem<N>` and Blizzard's slots are hidden, so its tint lands on hidden buttons: no tint and no error, on every client. Already Known had no commits from 2026-10-15 to 2026-11-16, so the change is this addon's.

Players who want known items out of the list already have Hide collected. What sijil82 lost is the other view: the whole list, with what they already have marked.

## Proposed outcome
An option of this addon marks known items in place on the grid, with or without Already Known, so players see the whole list with known items marked. Already Known stays useful for the auction house and guild bank, and does not conflict: its vendor tint lands on Blizzard's hidden slots.

## Affected users and systems
Players of every client (Retail, Mists, TBC Anniversary, WoW Forever, Classic Era), Already Known's players first. The merchant tab's item slots (`Gui/MerchantItemSlot.lua`), the filter menu or options page for the switch, `KrowiEVU_Filters` or `KrowiEVU_Options` for the setting, every locale file. Other addons on the same slots: Can I Mog It and Transmog Loot Helper overlays, the ElvUI, GW2_UI and EllesmereUI skins.

## Constraints
No taint: color only the addon's own slots, read Already Known's settings at most, never call into it. Blizzard's own colors (red for unusable, gray for sold out) keep working for unknown items. Hide collected keeps working as it does.

## Open questions
- Which items count as known: every collected item by its category's own check (as Hide collected does), or only the Already known tooltip line.
- How a known item looks (tint color, gray icon), and whether Already Known's own color and gray setting are followed when it is loaded.
- Where the switch sits, and its default.
- Recipes another character knows (the recipe record): marked too, in a second color, or not.