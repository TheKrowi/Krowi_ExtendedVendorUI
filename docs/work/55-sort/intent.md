# Intent: Sort the vendor list
Author: SmallStrayFox (#55, 2025-03-25), scoped by Krowi (maintainer) on 2026-10-29. Status: accepted

## Problem
The grid shows a vendor's items in the vendor's own order. At a token vendor (the reporter's case: Trials of Style) a player who wants to spend tokens on the cheapest items first has to scan every page for the prices.

## Proposed outcome
The filter menu gets a sort choice that orders the list (after filters and search) by name, gold price, token price, quality and possibly more, with the vendor's own order as the default. Krowi on token price: "which token first is decided the same way the banner order is decided".

## Affected users and systems
- Every client: the list, its pages and the filter menu; the token banner, whose order the token price sort follows.
- Saved variables: the sort choice in `KrowiEVU_Filters`.
- Other addons: plugins draw per slot, so they follow; Krowi_Vendorer reads the container, not its order.

## Constraints
- Clicks, purchases, Bulk Purchase, tooltips and Blizzard's confirmations keep using the vendor's real index (they do: each slot's button has `SetID(index)`).
- No Blizzard function, frame field or merchant API is replaced (taint rules in `CLAUDE.md`).

## Open questions
In spec.md, Decision.
