# Intent: The new-player tutorial points at a hidden vendor slot
Author: Krowi (maintainer), from the known-debt list in `CLAUDE.md`. Source: known debt (found 2026-10-15, rechecked 2026-10-29). Status: draft

## Problem
Retail's new-player tutorial shows an arrow "buy items from a vendor" anchored to Blizzard's `MerchantItem2` (live `Blizzard_NewPlayerExperience/Blizzard_TutorialTutorials.lua:2397`; Forever has the same line at 2448). Since 23.0, Blizzard's slots are hidden on the merchant tab and the addon's own slots show the items. The arrow then points at a hidden frame. With Direction Rows, the addon's slot 2 happens to sit in the same place; with Direction Columns, another item sits there. What the player actually sees is not known yet.

## Proposed outcome
A new player in the tutorial sees the arrow next to a vendor item they can buy, or the addon's behaviour here is accepted and written down as a known limit.

## Affected users and systems
- Clients: Retail; WoW Forever only if its game runs that tutorial.
- Players: new characters in the tutorial zone (Exile's Reach) with tutorials on, once, at the vendor step.
- Options: Direction (Rows or Columns), the grid size.

## Constraints
- The addon must not write into the tutorial or replace its functions. `MerchantItem2` may only get method calls (`Hide`, `Show`, `SetPoint`), per the taint rules in `CLAUDE.md`.
- Small reach: one tutorial step for new players.

## Open questions
- Is a fix worth it, or is this an accepted limit?

## Exploration steps
1. Read the tutorial class around live `Blizzard_TutorialTutorials.lua:2397`: when the pointer is added and removed, and how `AddPointerTutorial` (`NPE_TutorialPointerFrame`) handles an anchor frame that is hidden.
2. Reproduce on Retail with a new character on Krowi's own account in Exile's Reach up to the vendor step, with the addon on; take a screenshot with Direction Rows and with Columns.
3. Check whether Forever's game has the tutorial zone at all.
4. If a fix is wanted, write the options in the spec (for example, keep Blizzard's hidden `MerchantItem2` placed under the addon's slot 2 with `SetPoint` only) and run `krowi:taint-reviewer`.