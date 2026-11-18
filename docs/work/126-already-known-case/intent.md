# Intent: Hide collected misses items whose tooltip says "Already Known"
Author: jrowles (reporter). Source: GitHub issue #126. Status: done

## Problem
Hide collected (Recipes, Illusions, Other) hides an item only when one of its tooltip lines is exactly `ITEM_SPELL_KNOWN`, "Already known" in English. Some items show "Already Known" with a capital K instead, so they are not taken for known and stay in the list. The reporter found both comparisons false: the filter's (`Filters.lua`, `filters.IsKnown`) and `/kevutest`'s (`Tests/Tests.lua`, `IsNestedKnown`). Client, locale and item are not given.

## Proposed outcome
An item the game marks as already known is hidden by Hide collected however Blizzard capitalises the line. The reporter proposes comparing both strings in lower case.

## Affected users and systems
Players with Hide collected Recipes, Illusions or Other on, on every client (Retail and Forever read `C_TooltipInfo`, the Classic clients the addon's hidden scan tooltip). No saved variables, options or other addons change.

## Constraints
No change to which items count as known other than the capitalisation; the nested (crafted item) lines of a recipe still do not count. `Filters.lua` is taint-sensitive.

## Open questions
Which Blizzard string the "Already Known" line is, and on which items it shows.