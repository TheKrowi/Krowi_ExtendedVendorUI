# Intent: Filter the vendor without replacing Blizzard's merchant API
Author: Krowi (maintainer). Source: idea, from the 2026-10-15 taint review and the 2026-10-16/18 exploration of other addons on the merchant window. Status: accepted

## Problem
Nothing is reported broken by players, and no taint error has been reproduced in game. But Extended Vendor UI filters the vendor by replacing ten of Blizzard's merchant API functions and the items-per-page constant, so that Blizzard's own merchant window pages through the filtered list. That design:

- runs addon code inside every Blizzard merchant refresh, hover, click and purchase popup, so all of Blizzard's merchant code runs tainted;
- hands the filter to every other addon that reads the vendor. While a filter, a search or a Hide collected box hides items, Auctionator's tooltip prices belong to another item or are missing; Zygor's auto-buy, TSM's vendor buy tab, Auctionator's vendor price cache, Simulationcraft's `/simc merchant` and Wowhead_Looter see only part of the vendor; dragging a merchant item onto Pawn's compare slot shows the wrong item. Which addons see the filter depends on load order;
- has to follow Blizzard's API moves: 11.0.5's move to `C_MerchantFrame.GetItemInfo` needed a new wrapper, `C_MerchantFrame.IsMerchantItemRefundable` was never wrapped, and a future `C_MerchantFrame.GetNumItems` would stop the filter without an error;
- causes bugs players can hit today: on Retail the non-refundable prompt checks the wrong item under a filter; on Classic the token banner's gold total is wrong under a filter; with Bulk Purchase on, a shift-click with chat open links the item twice and a ctrl-click dresses up twice; on Retail under the `MerchantFilterDisabled` game rule the grid keeps stale rows.

The CanIMogIt plugin no longer runs: it looks for `MerchantFrame_CIMIOnClick`, which current CanIMogIt does not have, so CanIMogIt's icons are not refreshed after a filter or search change. Slots added by raising Rows or Columns get no CanIMogIt icon and no ElvUI skin until `/reload`.

## Proposed outcome
Extended Vendor UI shows the filtered vendor in its own item grid and leaves Blizzard's merchant functions and constants alone. A player who uses only Extended Vendor UI sees and does exactly what they do today, on every client: the same grid, look, paging, filters, search, token banner, Bulk Purchase, tooltips, cursors, purchase confirmations, buyback tab and options. The bugs above go away. Other addons see the vendor's real list again. CanIMogIt icons and the ElvUI skin keep working on every slot, and get better where they fall short today. Players who use GW2_UI's or EllesmereUI's merchant skin, or EllesmereUI's merchant item levels, keep them on Extended Vendor UI's slots: Extended Vendor UI brings its own plugins for them.

## Affected users and systems
- Players on the four clients the TOC lists (`## Interface: 120105, 50504, 20506, 11509`): Retail 12.1.5, Mists Classic 5.5.4, TBC Anniversary 2.5.6, Classic Era 1.15.9.
- The merchant window: the merchant tab's item grid, page buttons, page text and mouse-wheel paging; the buyback tab's layout; the filter button and search box; the token banner; Bulk Purchase; the options button's Direction, Rows, Columns and Housing Quantity entries.
- Saved variables, read as today: `KrowiEVU_Options` (`NumRows`, `NumColumns`, `Direction`, `RememberFilter`, `RememberSearch`, `RememberSearchBetweenVendors`, `BulkPurchase`) and `KrowiEVU_Filters` (the filter profile and the root `LastFilter`).
- The built-in CanIMogIt and ElvUI plugins. Krowi_Vendorer, which reads `KrowiEVU_MerchantItemsContainer` and calls its `HideAll()`. The public `KrowiEVU.PluginsApi`.
- Other addons on Krowi's clients that touch the merchant window: Auctionator, Pawn, TSM, Zygor, Simulationcraft, AllTheThings, Plumber, EllesmereUI and GW2_UI on Retail; Wowhead_Looter, ElvUI, GW2_UI and Zygor on Mists Classic; ElvUI on Classic Era.

## Constraints
- A player with only Extended Vendor UI sees no difference on any client, apart from the bugs above going away.
- CanIMogIt and ElvUI stay supported at least as well as today.
- No replaced Blizzard global or `C_*` function, no new field on a Blizzard frame or table, and no Blizzard refresh started from addon code (`WowAddons.md`, taint).
- Purchase safety stays Blizzard's: every confirmation Blizzard shows today (extended cost, non-refundable, high price, limited currency) still shows, including when an item is dragged to a bag or a character slot.
- Saved variables keep their shape; no migration.
- Krowi_Vendorer and the public API keep working.
- One release carries the redesign and the GW2_UI and EllesmereUI plugins; no release in between.

## Open questions
The draft's two questions (what happens to other addons' additions on Blizzard's `MerchantItemN` buttons, and a documented way for other addons to decorate Extended Vendor UI's slots) were answered at the design gate (spec.md, Decision).

Open: how to serve Plumber's merchant prices, whose code Extended Vendor UI cannot reach. Decided before the release.