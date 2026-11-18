# Spec: Hide collected misses items whose tooltip says "Already Known"
Intent: [intent.md](intent.md). Status: done

## Requirements
1. `filters.IsKnown` counts a tooltip line (outside the lines of the item a recipe makes) as Already known when its text, ignoring case, is one of Blizzard's "already known" strings that exist on the client: `ITEM_SPELL_KNOWN` and `ERR_COSMETIC_KNOWN` (Retail). Not `USED` (see Decision).
2. Everything else stays: the nested lines still do not count, an unreadable tooltip still reads as not known, a missing global (`ERR_COSMETIC_KNOWN` on the Classic clients) is skipped, a line without text is skipped.
3. `/kevutest`'s Hide collected, Recipes and Other step compares the nested lines (`IsNestedKnown`) the same way, through its own list, and fails when an item it judges has a line that matches one of those strings ignoring case but `IsKnown` says not known; it notes each item matched through a line other than `ITEM_SPELL_KNOWN` exactly, with the string it matched.

## Root cause
`Filters.lua:529` (`filters.IsKnown`) and `Tests/Tests.lua:544` (`IsNestedKnown`) compare a line's text with `ITEM_SPELL_KNOWN` exactly. The game has more than one string for it. GlobalStrings.db2 (`.claude/tools/Find-GlobalString.ps1 -Terms 'Already known'`, 2026-11-18):

| Client | Tag | Text |
|---|---|---|
| Retail 12.1.5.70783 | `ITEM_SPELL_KNOWN` | Already known |
| Retail | `ERR_COSMETIC_KNOWN` | Already Known |
| Retail | `USED` | Already Known |
| Retail | `JOURNEYS_KNOWN_ITEM` | Already Known (drawn only by Blizzard_Journeys' own Lua, never in item tooltip data) |
| Classic 5.5.4.70631 | `ITEM_SPELL_KNOWN` | Already known |
| Classic | `USED` | Already Known |

The tooltip line text comes from the client engine (`C_TooltipInfo` on Retail and Forever, the scan tooltip's font strings on the Classic clients), which picks the string; no FrameXML builds item tooltips, so which item gets which string is only visible in game. The reporter's item and client are not known. Every `/kevutest` run of 2026-11-04/05 on the five clients (enUS) saw only "Already known" on the items it noted.

`USED` is the trainer filter's label (live `Blizzard_TrainerUI/Mainline/Blizzard_TrainerUI.lua:88`), not a tooltip string seen anywhere. The other languages could not be checked: the local wow.tools.local returns the English text for every `-Locale`.

Reproduction: the new `/kevutest` check (requirement 3) fails before the fix at any vendor that sells an item with an "Already Known" line; none is known yet.

## Design
In `Filters.lua`, above `filters.IsKnown`: a set of the lower-cased strings, built once at load from the globals that exist (`type(text) == 'string'`), and `filters.IsKnownLine(text)`, true when `text` is a string whose lower case is in the set. `IsKnown` calls it in place of the exact compare. `string.lower` only folds ASCII in Lua 5.1, so a line and a constant with the same non-ASCII letters in different case (Cyrillic, German umlauts) still differ; the set's exact entries still match, so no language does worse than today. Secret text never reaches it today (`GetTooltipLines` returns nil on a secret line); since `IsKnownLine` is a helper on `filters`, it still turns a secret string away itself (taint review of 2026-11-18). A length check skips most lines before a lower-cased copy is made (code review of 2026-11-18).

`Tests/Tests.lua`: `IsNestedKnown` and the requirement 3 check use the test's own `MatchKnownGlobal` over the same two globals.

## Options considered
1. **`ITEM_SPELL_KNOWN` and `ERR_COSMETIC_KNOWN`, ignoring case (chosen).** Fixes the capitalised line in English; in other languages the cosmetic string counts too, whatever its wording. An error text for a known cosmetic, so a translation never means anything looser.
2. **The reporter's fix: `ITEM_SPELL_KNOWN` ignoring case.** Fixes English; in another language it fixes the line only where Blizzard's other string differs from `ITEM_SPELL_KNOWN` by case alone.
3. **All three, `USED` too (first chosen, then dropped).** `USED` is the trainer filter's label: translated as a looser word ("Learned", "Used"), a tooltip line that is exactly that word would hide an unknown item and record a recipe as known in `KnownRecipes`.

## Areas of concern
- Taint and secret values: no Blizzard frame, function or global is touched; two globals are read at load. Secret lines are already turned away before the comparison.
- Clients: all five; `ERR_COSMETIC_KNOWN` is absent on the Classic clients and skipped.
- Blizzard API changes: none.
- Other addons, plugins and skins: none.
- Saved variables and migrations: none.
- Localization: no new string; the Blizzard globals are already localized.
- Embedded libraries: none.
- Player-facing text: one changelog line.

## Verification
- Syntax hook on both files; `Find-DeprecatedApi.ps1`; `krowi:taint-reviewer` (`Filters.lua` is taint-sensitive); `/code-review`.
- `/kevutest` on each client at the vendors in the test-characters memory: Hide collected, Recipes and Other passes and the new check passes; at a vendor with an "Already Known" item, that item is noted with its string and hidden.

## Decision
First option 3, every "already known" string ignoring case (Krowi, 2026-11-18: "All strings, any case"), asked with the claim that it works in every language, which could not be checked. Asked again with the `USED` risk from the taint and code reviews: option 1 (Krowi, 2026-11-18: "Drop USED"). No comment on the issue asking the reporter for the item (Krowi, 2026-11-18: "No comment").