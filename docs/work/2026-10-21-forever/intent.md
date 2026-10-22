# Intent: Extended Vendor UI on WoW Forever
Author: Krowi (maintainer). Source: idea. Status: accepted

## Problem
WoW Forever (1.60.x, the `_classic_beta_` install) does not load the addon: the TOC had no 1.60 interface number, so the client lists it as out of date. With the number added (16001, on this branch) the addon loads and breaks. Forever reports itself as project 18 (Camelot) with a 1.x build, so Krowi_Util's flags say "Classic Era, not Retail" and the addon takes its Classic path, while Forever runs Retail's interface, Retail's merchant frame included. That path errors as the addon loads (`Gui/MerchantFrame.lua:61`, a Classic-only frame) and again on every item slot (`GetMerchantItemInfo`, not loaded on Forever).

## Proposed outcome
On Forever the vendor window works as on Retail: the grid of rows and columns, paging, the search box, the token banner, bulk purchase and the custom filters that have content there (pets, mounts, toys, appearances, sets, illusions, recipes, armor and weapon types), with no Lua errors. Skin addons are out of scope.

## Affected users and systems
- Clients: Forever is added. Retail, Mists Classic, TBC Anniversary and Classic Era keep their current behaviour.
- Libraries: Krowi_Util (the client flags, one shared table for every Krowi addon in the session) and Krowi_Menu (its own project check picks Blizzard's menus or UIDropDownMenu).
- This addon's 42 `IsMainline` branches, the Housing filter and option, Bulk Purchase (`IsClassicEra`), `/kevutest` and the release gate (it already maps 1.60 to Forever).
- Forever's gamepad interface style, which Retail does not have.

## Constraints
- The repo's taint rules hold unchanged.
- No flag changes its value on Retail, Mists, Anniversary or Era, and no existing Krowi_Util flag or Krowi_Menu behaviour changes for other addons on any client (Krowi, 2026-10-21 and 2026-10-22).
- A Krowi_Util flag means the same thing to every Krowi addon that reads it.
- ElvUI, GW2_UI, EllesmereUI and CanIMogIt are not supported on Forever in this item.

## Open questions
1. How the code tells the clients apart: keep Krowi_Util's flags as they are, or deviate (Krowi, 2026-10-21: settle this before any library or addon code changes). Settled 2026-10-21: the spec's option A.
2. Gamepad interface style: hide Blizzard's page-turn indicators only, or also make the grid reachable by gamepad.