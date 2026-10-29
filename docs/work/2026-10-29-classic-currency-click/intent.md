# Intent: Clicking a currency in the token banner errors on Classic
Author: Krowi (maintainer), from the known-debt list in `CLAUDE.md`. Source: known debt (found 2026-10-15, rechecked 2026-10-29). Status: draft

## Problem
Clicking a currency in the token banner opens the Currency tab (GitHub #77). The click calls `CharacterFrame:ToggleTokenFrame()` (`Gui/TokenBanner/TokenMixin.lua:139`), which only Retail and WoW Forever have (`CharacterFrameMixin:ToggleTokenFrame`, live `CharacterFrame.lua:67`, forever `CharacterFrame.lua:60`). On Mists Classic, TBC Anniversary and Classic Era the method is nil, so the click gives a Lua error and nothing opens. All three Classic clients do have a Currency tab, opened with `ToggleCharacter("TokenFrame")` (`CharacterFrame.lua:60` and `Blizzard_TokenUI.lua` in the classic, classic_anniversary and classic_era sources).

## Proposed outcome
Clicking a currency in the token banner opens the Currency tab on every client, without an error. Shift-click still links it in chat.

## Affected users and systems
- Clients: Mists Classic, TBC Anniversary and Classic Era. Retail and Forever stay as they are.
- Window: the token banner at the bottom of the vendor window, currency entries only (`self.IsCurrency`); item costs have no click action.

## Constraints
- Retail and Forever keep `ToggleTokenFrame`.
- Opening the character window from addon code must not taint anything protected; check what happens in combat.

## Open questions
- On a client where the Currency tab can be empty or hidden (Era), should the click do nothing?

## Exploration steps
1. Reproduce on each Classic client at a vendor that charges a currency (Mists: a Honor or Justice vendor; Anniversary: an honor vendor; Era: check whether any vendor charges a currency at all). Click the currency, then run `Read-GameErrors.ps1 -Client <client>`.
2. Read `ToggleCharacter` and `TokenFrame` in each Classic branch of `wow-ui-source`: whether the tab exists in Era and Anniversary, and what `ToggleCharacter` does when the tab is hidden.
3. Compare with Retail: does `ToggleTokenFrame` from addon code open the window in combat? The Classic path should behave the same.
4. Write the spec (branch on `addon.Util.IsModern`), run `krowi:taint-reviewer`, and check every client in game.