# Intent: Act on the Claude Code setup review of 2026-11-28
Author: Krowi (maintainer). Source: idea; a read-only review of the repo's Claude Code setup against the docs of 2.1.332, in the session of 2026-11-28, which Krowi handed over with "you own the repo and take action on the review". Status: done 2026-11-28

## Problem
The review found the setup sound, with a few defects that cost context or could mislead a session:
1. Two line references in `CLAUDE.md` are stale: `Krowi_ExtendedVendorUI.lua:101-133` (the boot now runs from line 108) and `Gui/BulkPurchase/BulkPurchaseMixin.lua:179` (the `IsForever` test is now line 187).
2. `wow-ui-source` is read-only by convention, but `additionalDirectories` makes it writable and no rule protects it (Krowi_AchievementFilter added deny rules for this on 2026-11-27).
3. `CLAUDE.md` is 33 KB and loads in every session, on top of the workspace's 34 KB. About 13 KB of it (the filter details, slot drawing and paging, the plugins, the `/kevutest` coverage) matters only when that area's files are touched.
4. The repo has no pull request template, though about ten outside pull requests came in since 2024 (#34 to #97).
5. `raw/` and `wiki/` hold notes from 2026-06-03 that `CLAUDE.md` already calls stale (version 21.3); searches still find them.

## Proposed outcome
Each defect is fixed or deliberately kept, sessions load less context by default without losing any fact, and nothing a session relies on gets weaker.

## Affected users and systems
Claude Code sessions in this repo and its worktrees; outside contributors opening pull requests. Players: none (`Deploy.ps1` and the addon manager's zip leave out `.claude`, `.github`, `docs`, `raw` and `wiki`).

## Constraints
- No fact in `CLAUDE.md` is lost: moved text moves verbatim, and `CLAUDE.md` names where it went.
- Claude cannot add its own allow rules; the review's `Read-GameTests.ps1` allow rule is Krowi's to add through `/permissions`, outside this change.
- Out of scope, reported instead: the workspace `CLAUDE.md` (the kit's `WowAddons.md`) and Krowi's user settings.

## Open questions
Which findings Krowi takes; whether `raw/` and `wiki/` go; which sections of `CLAUDE.md` move to path rules.