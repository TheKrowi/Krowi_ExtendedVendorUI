# Plan: Hide collected for everything the game calls Already known, on every client
Spec: [spec.md](spec.md). Status: accepted (Krowi, 2026-11-04)

## Files that change
- `Filters.lua` (tabs):
  - `defaults.profile.HideCollected.Other = false`.
  - `filters.GetTooltipLines(itemId)`: the item's tooltip as `{ text, type }` lines (type nil on the Classic clients), or nil when it cannot be read (data not cached: request it and `WaitForItemInfo`; a secret line). `C_TooltipInfo.GetItemByID` where it exists, otherwise `KrowiEVU_ScanTooltip`, created on first use.
  - `filters.IsKnown(itemId)`: `GetTooltipLines` plus the line rule from the evidence run; returns known, readable.
  - `filters.IsOther(itemId)`: no category test matches.
  - `Validate` (All and Blizzard's filters) and `ValidateCustom` end with the `HideCollected.Other` test.
  - The Recipes block leaves `IsModern`: on the Classic clients `IsRecipe` is class Recipe only; `IsRecipeCollected` returns `IsKnown`; the `MERCHANT_CLOSED` record frame and `RecordRecipe` run on every client. The Illusions block stays modern and uses `IsKnown`.
- `Gui/FilterButton/FilterButtonMixin.lua` (tabs): Recipes under Only show and Custom, Hide collected Recipes and Recipes my other characters know on every client; Hide collected "Other" (`L['Other']`) after Housing, every client.
- `Tests/Tests.lua`:
  - A new `known` step (filter All, Hide collected Recipes and Other on) with `CheckKnown`: a known recipe or a known uncategorized item is hidden and every other one shown (gear the Gear options hide excepted); other categories are not judged (their own options apply). For mounts and toys at the vendor, `IsKnown` against `IsMountCollected` and `IsToyCollected`. Notes: counts per kind, the first recipes' lines and every known uncategorized item's lines, capped like the illusion notes, and how long `BuildList` took.
  - `RestoreOptions` and the saved state cover `HideCollected.Recipes` and `HideCollected.Other`; `CheckRecipes` drops its `IsModern` gate; `DescribeTooltipLines` reads through `GetTooltipLines`, so it works on every client.
- `_Packaging/Changelog.md`: `## 24.3`, `### Added`: Hide collected, Other; Recipes on the Classic clients (#62). A `### Fixed` line too if the evidence shows recipes hidden for a crafted item's line.
- `_Packaging/Description.md`: line 20 (Hide collected list) and line 28 (recipe filter no longer Retail and Forever only). PR #122 changes lines 36-37 only.
- `CLAUDE.md`: Clients and loading ("The Pets, Sets, Illusions and Recipes filters run on Retail and Forever"), Filters paragraph (the check, the scanning tooltip, Hide collected Other), Testing paragraph (the `known` step).

## Order of work
1. ~~Evidence build~~: dropped (Krowi, 2026-11-04: no character with known recipes on those clients). The line rule comes from Already Known #19 and the `NestedBlock` reference (spec, Current state).
2. **The feature with its checks:** `GetTooltipLines`, `IsKnown`, `IsOther`, the validate tails, the Recipes and Illusions blocks, the defaults, the menu; `CheckKnown` with the reader-against-collections check. Deploy to every client; Krowi runs `/kevutest` on each at a recipe vendor, and on Retail also at a vendor selling mounts or toys the account has.
3. **Write-up and reviews:** changelog, description, `CLAUDE.md`; `Find-DeprecatedApi.ps1` (live and `-Branch classic`), `krowi:taint-reviewer`, `/code-review`.

## Risks
- Uncached items on the Classic clients would read as not known: `GetTooltipLines` returns nil for them and asks for the data, and the list rebuilds when it arrives, as the sorts do (taint review of 2026-10-29).
- Cost: a tooltip read per recipe and, with Other on, per uncategorized item at every rebuild; a scanning tooltip on the Classic clients is slower than `C_TooltipInfo`. The `known` step notes `BuildList`'s time; if a large recipe vendor stutters, cache "known" for the session (a known item stays known) and only re-read the rest.
- The scanning tooltip: built without a template, so no Blizzard script runs on it (the taint review found `GameTooltipTemplate` reaching the shared shopping tooltips); never anchored, never seen.
- Classic Recipes may also take Warlock grimoires (class Recipe, subclass Book) without an Already known line: they stay shown, as decided (spec, hard-coded items).
- Taint: `Filters.lua` and the filter menu are taint-sensitive; nothing new touches a Blizzard frame or global. `krowi:taint-reviewer` reviews the diff, Classic branch included.

## Proof
- The syntax hook on each edited file; `Find-DeprecatedApi.ps1` with no new hit on a path that runs on that client.
- Step 2's runs per client: the `known` step's checks PASS, the recipe checks run on the Classic clients, `BuildList`'s time noted, screenshots show the filter menu entries; `Read-GameErrors.ps1` shows nothing new.
- With every new option off, the other steps pass as before.