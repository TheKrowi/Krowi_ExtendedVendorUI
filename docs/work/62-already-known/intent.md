# Intent: Hide collected for everything the game calls Already known, on every client
Author: Krowi (chat, 2026-11-04), from a report that Already Known's tint no longer shows on the vendor grid; #62 (ndev88, 2025-08-05) asks for Already known filtering on Classic. Status: done (2026-11-04; accepted by Krowi that day: "1, 2, 4 seem a logic standalone extension of existing systems, 3 is a new feature")

## Problem
- Hide collected knows "collected" per category, and the item's Already known tooltip line only for recipes and illusions. An item outside the categories that the game marks Already known (a spell book, an item that teaches a spell) cannot be hidden.
- On Mists Classic, TBC Anniversary and Classic Era the Recipes filter and its Hide collected options do not exist (`Filters.lua:620-734`, `Gui/FilterButton/FilterButtonMixin.lua:198-263`): those clients have no `C_TooltipInfo` item getters, which the recipe check reads.
- The recipe and illusion checks take an Already known line anywhere in the tooltip (`Filters.lua:600-607, 670-677`). Already Known trusts it only near the end (`lines - i <= 3`); whether a recipe's tooltip can carry its crafted item's Already known line, and so hide a recipe the character does not know, is not known yet.

## Proposed outcome
1. One Already known check for the filters, used by Recipes, Illusions and a new catch-all Hide collected entry for items in no category, on Retail and Forever.
2. The same check on Mists, Anniversary and Era, through a tooltip the addon owns, which brings the Recipes filter, Hide collected Recipes, Recipes my other characters know and the catch-all to those clients.
3. Already Known's tint on the grid is not part of this item: it is the separate feature in `docs/work/2026-11-04-highlight-known/`. No plugin and no copy of Already Known's code.

## Affected users and systems
- Every client; the filter menu (Only show, Custom, Hide collected), `KrowiEVU_Filters` (a new `HideCollected` key, the recipe record on the Classic clients).
- Players of Already Known see no change from this item.

## Constraints
- Taint rules as in `CLAUDE.md`; `Filters.lua` and the filter menu are taint-sensitive.
- No CVar, no Blizzard frame written; the tooltip used on Classic is the addon's own.