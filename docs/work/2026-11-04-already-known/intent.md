# Intent: Already Known's tint missing on the vendor grid
Author: Krowi (chat, 2026-11-04). Status: accepted (Krowi, 2026-11-04)

## Problem
With Extended Vendor UI enabled, Already Known (ahakola, 1.104 of 2026-10-14) no longer tints known items (recipes, pets, mounts, toys, decor) in the vendor window. No Lua error. Krowi noticed it this week; it worked before.

## Proposed outcome
Known items on the vendor grid show Already Known's tint (its color and monochrome setting) again, on every page, filter and search.

## Affected users and systems
- Every client both addons run on: Retail, Mists Classic, TBC Anniversary, Classic Era, WoW Forever (Already Known loads `AlreadyKnownClassic.lua` there).
- The merchant tab only; Already Known's auction house and guild bank tints are not involved.
- Not affected when Extended Vendor UI steps aside (EllesmereUI list mode, Forever's gamepad style): Blizzard's own slots show then.
- Already Known (MIT); its merchant code has no public API, only the global `AlreadyKnownSettings`.

## Constraints
- Taint rules as in `CLAUDE.md`: no Blizzard global or function is replaced or written, so the 22.2 behaviour that made Already Known work by accident does not come back.
- Already Known's author has asked that AI-made pull requests not be sent (ahakola/AlreadyKnown #20, 2026-06-21) and prefers to write fixes himself (#29).

## Open questions
- Who draws the tint on this addon's slots: Already Known, or a built-in plugin here? Answered in the spec's Decision: a built-in plugin.