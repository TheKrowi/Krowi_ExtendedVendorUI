# Plan: CurseForge feedback of March to October 2026
Spec: [spec.md](spec.md). Status: done

## Files that change
- `Tests/Tests.lua`: round 1 checks (token banner, server list, placed decor, TLH overlay, first draw), round 2 steps (Gear, token banner options) and the recipe record note.
- `Gui/TokenBanner/TokenBanner.lua`, `TokenMixin.lua`: #100 (no stale or frozen tokens, costs keyed by id, `HideAllTokens` local), #104 and #108 (two options, two menu checkboxes).
- `Options/Defaults.lua`: `TokenBanner.GoldTotal`, `TokenBanner.HideNone`.
- `Filters.lua`: #102 (owned decor), #106 (`Gear` defaults, `PrepareGear`, `ValidateGear` in `BuildList`), #103 (`HideCollected.RecipesOtherCharacters`, `global.KnownRecipes`, `IsRecipeHidden`, `RecordRecipe`, a `MERCHANT_SHOW` frame), #109 if reproduced (`SetFilter`).
- `Gui/FilterButton/FilterButtonMixin.lua`: the Gear section and the recipes checkbox.
- `Plugins/TransmogLootHelper.lua`, `Plugins/Files.xml`: #97 merged, then the strings, quotes and the empty-list skip (#101).
- `Localization/enUS.lua`: 9 new strings; `Localization/zhCN.lua`: 22 missing translations (#105), later the 9 new ones.
- `_Packaging/Changelog.md`: a 24.1 entry.
- `CLAUDE.md`: architecture lines for the new options and the recipe record, the event list, the known-debt items this fixes.

## Order of work
1. Round 1 checks, committed and deployed alone to Retail and Mists Classic, so the reports are reproduced on 24.0's code. Done.
2. Fixes and features, one commit per issue, not deployed until round 1 is read. Done for #100 to #108; round 1 showed no change is needed for #109 and #110.
3. zhCN: the 22 strings drafted, uploaded to CurseForge, imported; the 9 new strings exported to CurseForge on Krowi's go, with their zhCN. Done.
4. Round 2: deployed to every client; `/kevutest` passed on Retail (Alice Fischer, Lyrendal, Hesta Forlath, then Alice Fischer after the review fixes), Mists, Anniversary and Era. WoW Forever was not tested: its realm was down. Done.
5. `krowi:taint-reviewer` (no finding), `/code-review` (fixed in `517d249`), the menu placement Krowi asked for, `CLAUDE.md` write-back, PR. Done.

## Risks
- The gear and recipe checks run per vendor item on every list build. Guarded: the gear check returns at once with every option off; the recipe record runs once per item per visit, only with the item's data loaded.
- The recipe record now reads tooltip text on every vendor visit, not only with a recipe option on: guarded with `issecretvalue`.
- `C_SpellBook.IsSpellKnown` may not count armor proficiencies (passives); then Hide sub-optimal armor does nothing, and round 2 notes the detected armor.
- New saved-variable keys come with AceDB defaults; the recipe record is a new `global` table, created on first use; no migration.
- #109's fix changes what the server is asked for on Retail and Forever; only after round 1 shows the drop.

## Proof
- `/kevutest` on Retail at the Neighborhood Tricky Treat Trader, Kirasztia, a decor vendor with placed decor, Lyrendal, and with EllesmereUI at 10x4 by columns; one run each on Mists Classic, Anniversary, Era and Forever. Expected: every check passes in round 2, and round 1 shows the failures that the fixes remove.
- `Read-GameErrors.ps1` per client after the runs: no new row, no bumped count.
- `krowi:taint-reviewer`: no blocking finding; `/code-review`: findings fixed or listed in the PR.
