# Spec: Hide collected never hides illusions
Intent: [intent.md](intent.md). Status: accepted (Krowi, 2026-10-29: "tackle the things you know so far"); the in-game proof is pending

## Requirements
1. With Hide collected, Illusions on, an illusion the account has is left out of the list, under Only show Illusions, Custom and All (Retail, Forever).
2. An illusion whose tooltip cannot be read, or reads as secret, stays in the list.
3. `/kevutest` checks it at a vendor with illusions and notes the tooltip lines it read.

## Root cause
`filters.IsIllusionCollected` (`Filters.lua:456-464` before the fix) looked for `Enum.TooltipDataLineType.RestrictedSpellKnown`, which neither client defines, so it compared with nil and never matched.

## Findings (UI source, live 12.1.5 and forever 1.60.1, identical for this)
- No API maps an item to its illusion. `C_TransmogCollection.GetIllusions()` and `GetIllusionInfo(sourceID)` return `isCollected` (live `TransmogItemsDocumentation.lua:446-493`, `TransmogIllusionInfo` `:1220-1230`), but `TransmogIllusionInfo` has no item or spell id, and no Blizzard code reads a `LearnTransmogIllusion` (40) tooltip line.
- Blizzard's tooltip shows Already known (`ITEM_SPELL_KNOWN`) on an item whose spell the player has; the recipe filter already reads that line (`filters.IsRecipeCollected`), and `/kevutest`'s recipe checks pass with it.

## Design
`IsIllusionCollected` reads the item's tooltip like `IsRecipeCollected`: true when a line's text is `ITEM_SPELL_KNOWN`, false when the tooltip is missing or a line is secret. `IsIllusion` (every consumable of type Other) stays as it is: tightening it to items with a `LearnTransmogIllusion` line would change what the Illusions filter shows, and whether Blizzard sends that line type is unproven. `/kevutest`'s illusions step dumps the line types, which settles that for a later change.

Options considered:
1. **Recommended, built: the Already known line.** Same mechanism as the recipes. Locale-independent (a Blizzard global string).
2. Match the item name against `GetIllusionStrings` names. Locale and naming dependent; used only as the test's cross-check.

## Areas of concern
- Taint and secret values: a read-only tooltip query, secret text probed as in `IsRecipeCollected`. No Blizzard frame involved.
- Clients: Retail and Forever only (the Illusions filter's `IsModern` branch); Classic keeps its stubs.
- Side effect: under All, Hide collected, Illusions now also hides a consumable of type Other that is no illusion but shows Already known. Before, it hid nothing. Such an item is known to the player, so hiding it fits the option.
- Cost: one tooltip table per such item per list rebuild, as for recipes.
- Saved variables, localization, libraries: none. Player text: a changelog line, and illusions back in `_Packaging/Description.md`'s Hide Collected list once the game proves it.

## Verification
`/kevutest` at a vendor that sells illusions (Retail), with at least one illusion the account has and one it lacks: the illusions step passes, the tooltip agrees with the collection where the names match, and its notes show the Already known line on the collected one.
