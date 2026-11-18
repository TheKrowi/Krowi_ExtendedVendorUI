# Plan: Hide collected misses items whose tooltip says "Already Known"
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

## Files that change
- `Tests/Tests.lua`: `CheckKnown` fails for an item with a line matching an "already known" string ignoring case that `IsKnown` reads as not known, and notes the items matched through a line other than `ITEM_SPELL_KNOWN` exactly; `IsNestedKnown` uses the test's own matcher (`MatchKnownGlobal`), not `filters.IsKnownLine` as first planned (code review of 2026-11-18).
- `Filters.lua`: the set of lower-cased strings and `filters.IsKnownLine`; `filters.IsKnown` uses it.
- `_Packaging/Changelog.md`: a 24.4 entry, Fixed.

## Order of work
1. The test check first (its own string list, so it does not lean on the code under test).
2. The fix in `Filters.lua`.
3. Changelog.

## Risks
- A Blizzard global missing on a client (`ERR_COSMETIC_KNOWN` on Classic): only strings are added to the set.
- A wider match hiding an item that is not known: the strings all mean "already known"; the match is a whole line, not a substring.
- Taint: only reads of three globals at load; the taint reviewer checks it.

## Proof
- The syntax hook, `Find-DeprecatedApi.ps1`, `krowi:taint-reviewer`, `/code-review`.
- `/kevutest` on the five clients: Hide collected, Recipes and Other passes, and so does the new check.