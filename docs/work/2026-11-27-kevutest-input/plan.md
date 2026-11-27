# Plan: /kevutest asks the kit for its clicks and hovers
Spec: [spec.md](spec.md). Status: done (accepted by Krowi, 2026-11-27: "Go")

## Files that change
- `Tests/Tests.lua` (4 spaces): a local `ClearInput()`; `ASK` table for the mouse steps (currency token, repair button, first item slot, the two tabs); `Wait` asks once after its merchant-tab shortcut; `Continue`, the timeout and `Stop` clear; the timeout's SKIP says why; `tests.Start` clears before the first step; `Stop` calls `Done()` last.
- `.claude/tools/Run-GameTests.ps1` (new): `-Client`, types `/kevutest`, `-WaitForDone`, `/reload`, `Read-GameTests.ps1 -Client <c> -Last 1`; stops with the kit's message when one refuses.
- `CLAUDE.md`, Testing in game: the run asks the kit for its mouse steps; `Run-GameTests.ps1` is the one command; "The routine never clicks or hovers by itself" stays true and says the kit does.

## Order of work
1. `Tests.lua`, syntax hook.
2. `Run-GameTests.ps1`.
3. `CLAUDE.md`.
4. Deploy to Retail; `Run-GameTests.ps1` at Knight-Lord Bloodvalor (Claude opens the vendor with a right-click), then read the screenshots of the five steps.

## Risks
- **A request served on a spot that moved:** the run asks after the window is drawn and the window does not move during the steps; the hooks still decide whether the step happened.
- **A tab click while the kit's guard refuses:** the kit retries every 5 s within the step's 30 s; the step then SKIPs with its reason.
- **`Done()` before the screenshots are written:** screenshots are written at once; saved variables need the `/reload` the script types.

## Proof
- Done: Retail, 2026-11-27 21:11, `Run-GameTests.ps1 -NoReload -Vendor 935,495` at Knight-Lord Bloodvalor with nobody at the PC: the kit right-clicked the vendor, clicked the currency, hovered the item, clicked Buyback and Merchant; 125 passed, 0 failed, 5 skipped (repair: he does not repair), exit 0, no Lua error. After the review fixes (f2bd33f), again at 21:25: 125 passed, 0 failed, exit 0. Built departure: `-Vendor` takes `935,495` as PowerShell passes it (two values), joined in the script.
- Syntax hook clean.
- Retail `Run-GameTests.ps1`: exit 0, the run's summary line with currency, tooltip, buyback and merchant PASS (repair SKIP: Knight-Lord Bloodvalor does not repair), no "not done within", the wait ending within about 2 minutes.
