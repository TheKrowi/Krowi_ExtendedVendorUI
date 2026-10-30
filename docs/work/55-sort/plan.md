# Plan: Sort the vendor list
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

## Files that change
- `Filters.lua`: `Sort` in the profile defaults; `filters.SortKeys`, `filters:GetTokenOrder`, `filters:SortList` (called at the end of `BuildList`).
- `Gui/TokenBanner/TokenBanner.lua`: tokens drawn in `GetTokenOrder`'s order after gold, instead of `pairs`.
- `Gui/FilterButton/FilterButtonMixin.lua`: a Sort by section after Gear (radios and Reverse order).
- `Localization/enUS.lua`: Sort by, Reverse order, Sort_Vendor, Sort_GoldPrice, Sort_TokenPrice, Sort_Quality; `Localization/Shared.lua`: Sort_Name is Blizzard's `NAME` (used by Blizzard on every client; `QUALITY` is not, so Quality is the addon's own string).
- `Tests/Tests.lua`: steps sort by name, gold price (and reversed), token price, quality under All, each pair of the list checked from the merchant API (not the filter's comparison), and for token price the banner's order; the sort setting goes back at the end.
- `_Packaging/Changelog.md` (Added, Changed), `_Packaging/Description.md` (Sorting bullet), `CLAUDE.md`.

## Order
Stacked on #32's branch (on #80's, on #116), so tonight's one `/kevutest` pass per client covers it.

## Proof
- Offline, before the game: `Filters.lua`'s sort section run with Lua 5.1 against a fake vendor of 8 items (names with a lower-case and a missing one, gold-only, token-only, two currencies and a cost item, qualities with gaps): every key and its reverse came out as the spec says, token order `currency:2 item:900 currency:1`.
- Tonight: the sort steps pass on every client; at a vendor with two tokens the banner and the Token price groups agree.
