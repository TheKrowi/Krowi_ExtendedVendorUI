# Spec: Hide collected for everything the game calls Already known, on every client
Intent: [intent.md](intent.md). Status: accepted (Krowi, 2026-11-04)

## Requirements
1. One check, `filters.IsKnown(itemId)`, says whether the item's own tooltip carries Blizzard's Already known line (`ITEM_SPELL_KNOWN`), and whether the tooltip could be read at all. Retail and Forever read `C_TooltipInfo.GetItemByID`; Mists, Anniversary and Era, which have no `C_TooltipInfo` item getters (`wow-ui-source\classic_era\...\TooltipInfoDocumentation.lua` declares none), read a hidden `GameTooltip` the addon owns. The choice is by feature (`C_TooltipInfo.GetItemByID` present), not by client flag.
2. A secret line (12.x restrictions) or an item whose data is not cached gives "not known, not readable". For an uncached item the check asks for its data and the list is rebuilt when it arrives (`addon.Gui.MerchantItemSlot.WaitForItemInfo`, as the Name and Quality sorts do).
3. A line that belongs to an item shown inside the tooltip (the item a recipe makes) does not count. On Retail and Forever every line of `C_TooltipInfo`'s list is the item's own; on the Classic clients the reader stops at the first line below the item's name whose text starts with a line break, where the crafted item begins (see Current state).
4. `IsRecipeCollected` and `IsIllusionCollected` use the check; their behavior is unchanged apart from requirement 3.
5. A new Hide collected entry, `HideCollected.Other` in `KrowiEVU_Filters`, off by default: under All, Blizzard's own filters and Custom (its Other branch), an item in no category (not a pet, mount, toy, appearance, set, illusion, recipe or decor) that `IsKnown` marks is hidden. An item in a category follows only its category's option, as now.
6. Mists, Anniversary and Era get Recipes under Only show, Custom and Hide collected (Recipes and Recipes my other characters know), and the recipe record (`RecordRecipe`). A recipe there is an item of class Recipe; Retail's extra rule for consumables that teach (`ItemSpellTriggerLearn`) needs line types a scanned tooltip does not have.
7. Search, Gear, Sort and the server filter do not change.
8. `/kevutest` notes, at each vendor, the items with the Already known line per category and outside every category, and for each recipe where the line sits and which line types surround it (Retail and Forever); it checks that the new entry hides exactly the uncategorized known items, and runs its recipe checks on every client.

## Current state (code as of 2026-11-04)
- The recipe and illusion checks each read `C_TooltipInfo.GetItemByID` and take `ITEM_SPELL_KNOWN` on any line (`Filters.lua:595-609, 665-679`); both blocks, and the Pets and Sets ones, run only where `addon.Util.IsModern` (`Filters.lua:426, 538, 577, 620`), and the menu shows those entries only there (`Gui/FilterButton/FilterButtonMixin.lua:173-263`).
- `Validate` under All and Blizzard's filters hides an item only through its category's option (`Filters.lua:389-421`); `ValidateCustom` ends with `Custom.Other` for items in no category (`Filters.lua:856`).
- Retail and Forever: an item shown inside a tooltip is one `NestedBlock` line (`TooltipInfoSharedDocumentation.lua:53`) whose fields are `tooltipType` and `tooltipID` ([warcraft.wiki.gg, `Enum.TooltipDataLineType`](https://warcraft.wiki.gg/wiki/API_C_TooltipInfo.GetRecipeResultItem)): a reference to the nested tooltip, not its lines. Already Known's Retail file accepts the line only within three lines of the tooltip's end (`AlreadyKnown.lua` `_checkTooltipLine`, 1.104) and still tints known recipes, so a recipe's own line sits at its end there. A line anywhere in the list is the item's own; the current recipe and illusion checks are right.
- Classic clients: the scanned tooltip inlines the crafted item. Already Known #19 (TBC Anniversary 2.5.5, `/ak itemtest` of a known Recipe: Rage Potion): `Recipe: Rage Potion` / `Requires Alchemy (60)` / `Already known` / `Use: Teaches you how to make a Rage Potion.` / `\nRage Potion` / `Classes: Warrior` / `Requires Level 4` / `Use: Increases Rage by 20 to 40.`. The recipe's line comes before the crafted item, which starts with a line break; Already Known's Classic file takes the line anywhere.
- Reproduction: none in game; Krowi has no character with known recipes on the clients concerned (2026-11-04). The evidence above stands in for it; `/kevutest` checks the reader against the mount and toy collections instead (Verification).

## Design
- `filters.IsKnown(itemId)` near the Gear section of `Filters.lua`, every client: the reader per requirement 1, the line rule per requirement 3 once the evidence is in, `issecretvalue` per line as now. The scanning tooltip (`KrowiEVU_ScanTooltip`, owner `UIParent`, `ANCHOR_NONE`) is created on first use on the Classic clients only, without a template: `GameTooltipTemplate` would keep Blizzard's shared `ShoppingTooltip1` and `2` on it and hide and reset them from addon code in its `OnHide` (taint review of 2026-11-04); its lines come from `AddFontStrings` and the engine.
- `filters.IsOther(itemId)`: none of the category tests, the same fall-through `ValidateCustom` uses. `Validate` (All and Blizzard's filters) ends with `if HideCollected.Other and IsOther and IsKnown then return false`; `ValidateCustom` ends with `Custom.Other and not (HideCollected.Other and IsKnown)`.
- The Recipes block (`Filters.lua:620-734`) leaves `IsModern`: `IsRecipe` keeps its consumable rule where line types exist; `IsRecipeCollected` becomes `IsKnown`. The Illusions block keeps `IsModern` and uses `IsKnown`. The menu shows the Recipes entries and the new entry on every client.
- No caching of "not known", as today: a recipe learned with the window open shows as known at the next rebuild. The cost is one tooltip read per uncategorized item per rebuild while the new entry is on.

## Options considered
- **Label of the new entry:** "Other" (the existing string, translated in German, French, Russian and Chinese; Custom's last entry has the same name) (recommended), or a new string such as "Other known items" (clearer, English only until translated).
- **Recipes on the Classic clients:** all four entries (Only show, Custom, both Hide collected) (recommended: one block, one rule), or only the two Hide collected entries.
- **Already Known's hard-coded items** (WoD blueprints, Shadowlands soulshapes, Krokul Flute, recipe packs, Warlock grimoires): left out (recommended): the game does not mark them Already known, and copying them is the plugin route Krowi set aside.
- Rejected: Already Known's Retail line rule (`lines - i <= 3`): on Retail nothing nested reaches the list, and on the Classic clients the recipe's own line is not near the end.
- Out of scope: the Pets filter on Mists Classic (it has the pet journal); the highlight (`docs/work/2026-11-04-highlight-known/`); Already purchased (#62).

## Areas of concern
- Taint and secret values: `BuildList` runs from the `MerchantFrame_UpdateMerchantInfo` post-hook; `C_TooltipInfo` reads and an addon-owned tooltip touch no Blizzard frame. The scanning tooltip has no template, so no Blizzard script runs on it. Secret lines handled per requirement 2. `krowi:taint-reviewer` (2026-11-04): one finding, the template's shopping tooltips, fixed as above; Retail and Forever clean (`C_TooltipInfo.GetItemByID` runs no tooltip callbacks), no global written outside the addon's own.
- Clients: all five; Forever takes the `C_TooltipInfo` path; Era and Anniversary have class Recipe items at profession vendors.
- Blizzard API: `C_TooltipInfo.GetItemByID` (Retail, Forever), `GameTooltip:SetItemByID` or `SetHyperlink` (Classic); `Find-DeprecatedApi.ps1` on both branches.
- Saved variables: `HideCollected.Other` through AceDB defaults, no migration; the recipe record starts filling on the Classic clients.
- Localization: none with the recommended label; otherwise one string in `enUS.lua`.
- Libraries, data snapshots: none.
- Player text: changelog Added lines for the new entry and for Recipes on the Classic clients; `_Packaging/Description.md` lines 9, 20 and 28 (recipe filter "on Retail and WoW Forever").

## Verification
- The reader against the collections: at a vendor that sells mounts or toys, `IsKnown` must agree with `IsMountCollected` and `IsToyCollected` for each (Retail, Forever; mounts on Mists), which proves it without a known recipe.
- Every client: `/kevutest` at a recipe vendor, with Hide collected Recipes and the new entry on: a recipe or uncategorized item is hidden exactly when it reads as known; the notes show the first recipes' lines (on the Classic clients ending before the crafted item). Known recipes need a character that has learned one: optional, a cheap one learned on a test character covers the hiding path.
- `Read-GameErrors.ps1` clean on each client.

## Decision
- 2026-11-04 (Krowi): the first spec (a plugin with a copy of Already Known's check) was replaced the same day by this one; the tint became its own feature.
- 2026-11-04 (Krowi): the new entry is labelled "Other" (the existing string); the Classic clients get all four Recipes entries; Already Known's hard-coded items stay out.