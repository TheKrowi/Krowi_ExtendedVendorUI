# Spec: Sort the vendor list
Intent: [intent.md](intent.md). Status: accepted

## Requirements
1. The filter menu has a Sort section after Gear: Vendor order (default), Name, Gold price, Token price, Quality (and the extra keys Krowi picks), as radio buttons, plus a Reverse order checkbox.
2. The sort applies to the list after filters, search and the Gear options, on every page; a change goes back to page 1.
3. Each key has a natural direction: name A to Z, prices cheapest first, quality best first. Reverse order flips it. Items without a value for the key go last in both directions. Ties keep the vendor's order.
4. Token price follows the token banner's order (see Root cause: that order has to be defined first).
5. The choice is remembered (Decision 4) and applies at every vendor.
6. `/kevutest` checks the order of the list for each key.

## Root cause and findings
- `filters:BuildList` (`Filters.lua:155-169`) collects the vendor's indices that pass the filter, in the vendor's order; `container:Update` places `indices[...]` page by page (`Gui/MerchantItemsContainer.lua:169`). Sorting that list after it is built changes only what each slot shows; each slot keeps the real index for clicks.
- **The token banner has no defined order today.** `tokenBanner:Update` (`Gui/TokenBanner/TokenBanner.lua:233-252`) draws gold, then `pairs(currencyCounts)`, then `pairs(itemCounts)`, keyed by strings such as `'currency:1792'`. `pairs` follows Lua's hash order, which no rule decides and which can differ between vendors with the same currencies. So "the same way the banner order is decided" needs the banner order decided first (Decision 1).
- `C_MerchantFrame.GetItemInfo` gives `name` (nil until the item's data has arrived on Retail), `price` (copper for the shown stack) and `stackCount`, but no quality (live `MerchantFrameDocumentation.lua`); quality comes from `C_Item.GetItemQualityByID`, which the Gear options already use on every client. Token costs come from `GetMerchantItemCostInfo`/`GetMerchantItemCostItem`, as the banner reads them.
- `strcmputf8i` (locale-aware, case-insensitive) exists on every client (Blizzard's AddOn list uses it in live, forever, classic, classic_anniversary and classic_era).

## Design
- `Filters.lua`: `filters:BuildList` sorts the list at its end when the sort is not Vendor order. Keys are computed once per item per rebuild (name, price, quality, token costs), then `table.sort` with the vendor index as the last key (Lua's sort is not stable).
- Token order (Decision 1, recommended): gold first, then each currency or cost item in the order it first appears in the vendor's full list (not the filtered one, so the banner does not reshuffle with a filter). One rule for every client: Blizzard's own currency row follows `C_MerchantFrame.GetMerchantCurrencies` on Retail and Forever (live `Mainline/MerchantFrame.lua:970`), but on every Classic client that code is commented out (`TBC/MerchantFrame.lua:832`, `Vanilla/MerchantFrame.lua:768`). The banner draws in that order, and the token price sort uses it.
- Token price compare (Decision 2, recommended): walk the tokens in that order; the first token that only one of the two items costs puts that item first; the first token both cost decides by amount. Result: items grouped by token, in banner order, cheapest first in each group; items with no token cost last.
- Menu: a Sort section at the end of `KrowiEVU_FilterButtonMixin:CreateMenu` (`Gui/FilterButton/FilterButtonMixin.lua:139-284`), built like the Gear section (`CreateCustomRadio`, then `SetFilter(GetFilter())` to rebuild and go to page 1).
- Saved: `Sort = { By = 'Vendor', Reverse = false }` in the `defaults` profile at the top of `Filters.lua`; AceDB fills it in for existing players, so no migration.

## Options considered
1. **Recommended: one Token price key over the banner order** (Decision 2). One menu entry; at a vendor with one token it is simply "cheapest first".
2. One entry per token the vendor uses ("Price: Honor", "Price: Arena points"). Clearer at mixed vendors, but the menu changes from vendor to vendor and is built while the window is open.

## Areas of concern
- **Taint and secret values:** the addon's own list and menu; no Blizzard state written. Merchant data is not secret.
- **Clients:** all five. Quality and token costs work everywhere; on Retail an item whose data has not arrived has no name or quality yet and goes last, then moves once `GET_ITEM_INFO_RECEIVED` redraws the list (that redraw exists).
- **Other addons, plugins, skins:** draw per slot, follow the new order. The token banner's order becomes fixed, which players will see as a change at multi-currency vendors.
- **Saved variables:** one new table with defaults; nothing removed.
- **Localization:** new strings (Sort, Vendor order, Gold price, Token price, Reverse order); Name and Quality can use Blizzard's `NAME` and `QUALITY` through `Shared.lua`. Ask Krowi whether they go onto the CurseForge page.
- **Player text:** a changelog Added line; `_Packaging/Description.md` gets a Sort bullet.
- **Cost:** keys once per item per rebuild, then n log n; rebuilds already run on bag and currency updates.

## Verification
- `/kevutest`: a step per key that sets it, checks each neighbouring pair of the list against the key (and the Reverse flip once), screenshots, and puts the sort back.
- By hand at a token vendor with two currencies (Retail) and an honor vendor (Anniversary): the banner and Token price agree on the order.

## Decision
Krowi, 2026-10-29 ("#55 recommended"):
1. Banner order: gold, then tokens in the order they first appear in the vendor's full list, on every client.
2. Token price: grouped by token in banner order, cheapest first in each group, items without a token cost last.
3. Gold price: the price shown on the slot (for the shown stack).
4. Remembered, applies at every vendor.
5. No extra keys for now (no recommendation was made); item level can come with #107 once its requester answers.
