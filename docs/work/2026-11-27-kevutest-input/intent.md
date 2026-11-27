# Intent: /kevutest asks the kit for its clicks and hovers
Author: Krowi (chat, 2026-11-27: "2 first", after "ok to all" on making `/kevutest` ask the kit for its clicks). Source: idea, from the 107 runs. Status: done (accepted by Krowi, 2026-11-27)

## Problem
`/kevutest` ends with five steps that wait 30 s each for a person: click a currency in the token banner, hover the repair-all button, hover an item, click Buyback, click Merchant. The routine never tells the kit's marker addon (`KrowiGameInput`) what it needs, and never says the run is done, so:
- a kit-driven run (`Send-GameInput.ps1 -Command '/kevutest'`, then `-WaitForDone`) skips those steps, and `-WaitForDone` waits until its 15-minute timeout although the run ended long before (twice on Retail on 2026-11-27; Krowi closed the client the second time, seeing nothing happen);
- every release-gate run on five clients needs Krowi at the PC for the last steps.

The workspace standard since 2026-11-05 (`WowAddons.md`, Closing the loop with the game, item 6) is that a run asks the kit for the hovers, clicks and keys it needs and tells it when it is done, and that a whole run is one repo command.

## Proposed outcome
A run started by the kit does every step by itself, ends with the marker's "done", and the kit reloads and prints the results; Krowi only opens the vendor (or Claude right-clicks it). A run Krowi types by hand, without the kit, behaves as today.

## Affected users and systems
Krowi and Claude only: `Tests/Tests.lua` (shipped, but `/kevutest` does nothing for players unless typed), `.claude/tools/`, `CLAUDE.md`'s testing section. Every client the TOC lists (the merchant tabs and token banner exist on all of them). No saved variable, option or player-facing text changes.

## Constraints
- The routine itself never moves the mouse or clicks: it only asks the kit's marker, and the kit decides under its own guard (clicks only in a kit-started client).
- No CVar, no taint on Blizzard frames beyond what the run already does (the clicks are real clicks).
- Without `KrowiGameInput` loaded, nothing changes.

## Open questions
- Whether the one repo command (`Run-GameTests.ps1`) comes in the same change.
