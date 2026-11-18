# Intent: A bigger first grid and a glowing gear for new players
Author: Krowi (maintainer), from the CurseForge comments on the WoW Forever release analysed in another session on 2026-11-18. Source: idea. Status: done

## Problem
A new player gets Blizzard's own 5 rows × 2 columns, so the addon looks like it does nothing, and does not find the gear (options button, left of the search box) where the grid size is set.

## Proposed outcome
Krowi, 2026-11-18: "new installs get a bigger default grid, 4x7, the gear gets a first-time highlight".

## Affected users and systems
New installs on all five clients. `KrowiEVU_Options` (profile `NumRows`, `NumColumns`, a new `HighlightOptionsButton`), the options button, boot (`Krowi_ExtendedVendorUI.lua`), `/kevutest`.

## Constraints
Existing players keep their grid and see no highlight. No taint: own texture and animation on the addon's own button.

## Open questions
None after the design gate.