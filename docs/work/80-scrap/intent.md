# Intent: Scrap's button outside the window at a repair vendor
Author: phant (#80, 2026-04-05; also Scrap #301 by Starlynk1, 2026-02-09). Status: accepted (Krowi, 2026-10-29: "plan a test run tonight")

## Problem
On TBC Anniversary with Scrap (12.0.0, 12.0.1), at a vendor that repairs, Scrap's button sits outside the vendor window, left of the repair buttons (#80's screenshot), and with guild repair the repair-all button is stretched (Scrap #301's screenshot). Reported on 21.3.

## Proposed outcome
Scrap's button sits inside the window next to the repair buttons, and the repair buttons keep their size.

## Affected users and systems
- Clients without Blizzard's Sell All Junk button: Mists Classic, TBC Anniversary, Classic Era. Retail and Forever are not affected.
- Vendors that repair; with and without guild repair.
- Scrap (all rights reserved; only its public module and method are used).

## Constraints
Taint rules as in `CLAUDE.md`: Blizzard's buttons get method calls only, as the layout already does.
