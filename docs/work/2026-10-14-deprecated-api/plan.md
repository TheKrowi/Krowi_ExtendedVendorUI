# Plan: Stop reading deprecated Blizzard globals
Spec: [spec.md](spec.md). Status: accepted

## Files that change
- `Gui/BulkPurchase/BulkPurchaseMixin.lua` lines 7-11: drop the `C_X and ... or OldGlobal` guards, keep the local names and the column alignment.
- `Gui/FilterButton/FilterButtonMixin.lua` line 150: `C_SpecializationInfo.GetSpecializationInfo`.
- `.gitignore`: add `.claude/worktrees/`, so worktrees under the main checkout are never swept into a release commit (the main checkout excludes it locally in `.git/info/exclude` until this merges).

Routine plan: one-to-one replacements by the functions the old names resolve to; no frames, hooks, protected actions or saved variables change.

## Order of work
1. Reproduction: `Find-DeprecatedApi.ps1` on the four branches, recorded in `spec.md`.
2. The two code edits; Lua 5.1 syntax check.
3. `Find-DeprecatedApi.ps1` on the four branches: clean.
4. `.gitignore` line.
5. `/code-review` on the diff.
6. In game (Retail): `Deploy.ps1 -WhatIf`, deploy with Krowi's approval, `/reload`, merchant filter menu and bulk purchase window, second `/reload`, `Read-GameErrors.ps1`.
7. Work files to `done`, push, PR against `dev`.

## Risks
- A typo in a namespace function name turns a working call into nil: the scan after step 2 and the in-game check of both windows catch it.
- The main checkout has uncommitted TOC and settings changes: the worktree is off `dev`, and nothing here touches the main checkout's files.

## Proof
- `Find-DeprecatedApi.ps1 -Branch <b>` prints `No uses found.` for `live`, `classic`, `classic_anniversary`, `classic_era`.
- The class submenu lists the character's specs, the bulk purchase window shows the free-space and affordable counts, and `Read-GameErrors.ps1` shows no new Extended Vendor UI row.