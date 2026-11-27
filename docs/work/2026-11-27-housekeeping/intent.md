# Intent: Housekeeping after 24.5
Author: Krowi (chat, 2026-11-27), from the status page of that day. Source: idea. Status: accepted (Krowi, 2026-11-27: "let's do housekeeping now. clean up work folders, forever is released so should pass before releases")

## Problem
Nine work folders shipped in 24.2 (2026-10-30) still read "accepted" or "built; the in-game check is pending", so `Get-RepoState.ps1` and the status page count them as open work. The release gate still holds the WoW Forever exception of 2026-10-30 (`$untested` in `.claude/release-gate.ps1`), expired on 2026-11-05, and `CLAUDE.md` still tells the next session to run Forever and remove the entry. Its removal sat on `chore/2026-11-05-forever-gate` without a pull request.

## Proposed outcome
- The nine folders read done, with the release that shipped them: `2026-10-29-classic-currency-click`, `-dead-code`, `-illusions-hide-collected`, `-inventory-slot-info`, `-options-button-arrow`, `-search-npc-name-secret`, `32-repair-tooltips`, `55-sort`, `80-scrap`.
- WoW Forever passes `/kevutest` before every release like every other client: the gate's `$untested` table is empty (it stays for a future outage), and `CLAUDE.md` says so. The gate already failed without a Forever run since 2026-11-05; this removes the dead entry and its instructions, so nothing about a release changes.
- Not here: `2026-10-29-tlh-slot-limit` and `2026-10-29-tutorial-buy-arrow` stay open (known debt, not done).

## Affected users and systems
None for players: only `docs/work/`, `CLAUDE.md` and `.claude/release-gate.ps1` change, none of which ships.
