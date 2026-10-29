# Intent: Hide collected never hides illusions
Author: Krowi (maintainer), from the known-debt list in `CLAUDE.md`. Source: known debt (found 2026-10-21, rechecked 2026-10-29). Status: draft

## Problem
With Hide collected on for Illusions, illusions the account already has still show. `filters.IsIllusionCollected` (`Filters.lua:465-473`) looks for a tooltip line of type `Enum.TooltipDataLineType.RestrictedSpellKnown`. That type exists in neither live's nor Forever's UI source: live's `TooltipDataLineType` (`TooltipInfoSharedDocumentation.lua`) has `LearnTransmogIllusion` (40) but no `RestrictedSpellKnown`. The check compares with nil and is never true. `_Packaging/Description.md` leaves illusions out of its Hide Collected list until this works (Krowi, 2026-10-24).

## Proposed outcome
With Hide collected on for Illusions, the vendor list leaves out illusions the account already has. The description lists illusions again.

## Affected users and systems
- Clients: Retail and WoW Forever (the Illusions filter runs only there).
- Filter: Illusions under Only show and Custom, option `HideCollected.Illusions` in `KrowiEVU_Filters`.
- Vendors that sell illusions (the Trading Post, faction and expansion illusion vendors).

## Constraints
- Tooltip data can turn secret under restrictions: probe before reading, and keep the item when unsure.
- A check per item on every list rebuild must stay cheap.

## Open questions
- Tooltip line or collection API? The collection API is the cleaner source, if an item maps to its illusion.

## Exploration steps
1. In game at an illusion vendor, for one illusion the account has and one it lacks, dump `C_TooltipInfo.GetItemByID(id).lines` (each line's `type` and `leftText`) and see which line says it is known.
2. Check the collection route: `C_TransmogCollection.GetIllusions()` returns `visualID, sourceID, icon, isCollected, isUsable, isHideVisual` (live `TransmogItemsDocumentation.lua`). Find how an item maps to its illusion: `C_Item.GetItemSpell`, `GetIllusionInfo` or `GetIllusionStrings`, or the data on the `LearnTransmogIllusion` tooltip line.
3. Check the same APIs in Forever's generated docs.
4. Decide in the spec, then extend `/kevutest`'s Hide collected check under All with an illusion vendor, as it does for placed decor.
5. Put illusions back into `_Packaging/Description.md`'s Hide Collected list once it works.