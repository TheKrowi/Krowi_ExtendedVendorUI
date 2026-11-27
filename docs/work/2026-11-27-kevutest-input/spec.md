# Spec: /kevutest asks the kit for its clicks and hovers
Intent: [intent.md](intent.md). Status: done (accepted by Krowi, 2026-11-27)

## Requirements
1. With `KrowiGameInput` loaded, each mouse step asks the marker once when it starts waiting: currency, a left click on the first shown currency token of the banner; repair, a hover on `MerchantRepairAllButton`; tooltip, a hover on the first shown slot with an item; buyback, a left click on `MerchantFrameTab2`; merchant, a left click on `MerchantFrameTab1`.
2. The request is cleared (`KrowiGameInput.Clear()`) as soon as the step's own hook sees the action, when its 30 s run out, and when the run stops, so a `-WaitForDone` started again never repeats a click.
3. A run clears the marker when it starts and calls `KrowiGameInput.Done()` when it ends, whatever ended it (the last step, the vendor closing, combat, `/kevutest` again).
4. A step whose 30 s run out says why: the marker is not loaded, or it was asked and the action did not happen.
5. Without `KrowiGameInput`, the steps wait for a person exactly as before.
6. `.claude/tools/Run-GameTests.ps1 -Client <c>` is one run: it types `/kevutest` (which starts at once on an open vendor, or when one opens), waits for done with `-WaitForDone`, types `/reload` and prints the run with `Read-GameTests.ps1 -Last 1`.

## Design
`Wait(what)` in `Tests/Tests.lua` gains a table of askers, one per mouse step, each returning the region and the request; it calls `KrowiGameInput.ClickAt` or `HoverAt` on the region's centre. `Continue`, the timeout and `Stop` call a local `ClearInput()`. `tests.Start` clears before `RunStep(1)`; `Stop` ends with `KrowiGameInput.Done()`. The hooks that already notice the action (token `OnClick`, repair `OnEnter`, item slot `OnEnter` with its rest timer, the buyback and merchant post-hooks) stay the proof that the step happened, so a click by hand still counts. `Run-GameTests.ps1` follows Krowi_AchievementFilter's, reduced to this repo's single command.

## Options considered
1. **Ask the marker and add `Run-GameTests.ps1` (recommended):** one command per client for the release gate, as the workspace standard says.
2. **Ask the marker only:** the runs still take three kit commands and a reader; nothing else differs.
3. **Leave the steps to Krowi:** every release run needs Krowi at the PC for its last minute; the kit's wait always times out.

## Areas of concern
- Taint and secret values: the clicks are hardware clicks on Blizzard's tabs and the addon's token; the run already opens the character window from the token click. No new hook on Blizzard code; `HoverAt`/`ClickAt` only read regions' positions.
- Clients: `MerchantFrameTab1/2` exist on every client (live and forever `Mainline/MerchantFrame.xml:576,592`; classic `TBC` and `Vanilla` `MerchantFrame.xml:488,505`); the repair button and the token banner are the addon's frames on all of them. The currency step already skips on Era (no currency click there).
- Blizzard API changes, other addons, saved variables, localization, libraries: none (tests and tooling only; `KEEP_RUNS` and the run record unchanged).
- Player-facing text: none; the steps' texts stay.

## Verification
Retail, kit-started: `Run-GameTests.ps1` at a vendor; the five mouse steps PASS or SKIP for their own reason (no repair at the vendor), none "not done within 30 s"; `-WaitForDone` returns at the run's end. Then one run typed by hand without the kit wait, to see the steps still wait for a person. The other clients with the next release gate.

## Decision
Option 1, the marker asked and `Run-GameTests.ps1` added: Krowi, 2026-11-27 ("Yes, add it (Recommended)").
