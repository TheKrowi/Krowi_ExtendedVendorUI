# Token Banner

> Sources: Krowi-Frostmane EU, 2026-02-20
> Raw: [Krowi's Extended Vendor UI — Codebase Analysis](../../raw/krowi-extended-vendor-ui/krowi-extended-vendor-ui-codebase.md)

## Overview

The Token Banner (`Gui/TokenBanner/`) replaces Blizzard's default currency display on the merchant frame with a custom, configurable row of token frames. It shows all currencies and items required to buy merchant goods, including gold, alongside how much the player currently has. The component was introduced in version 19.0 (2026-01-02) and expanded through 21.2 (token click interaction) and 21.1 (display mode option).

## Architecture

Four files work together:

| File | Role |
|---|---|
| TokenBanner.lua | Frame setup, pool management, layout engine, update loop |
| TokenBannerMixin.lua | Mixin for the banner container frame |
| TokenMixin.lua | Mixin for individual token frames |

## Layout

The banner is anchored inside `MerchantMoneyInset`. On load, all default Blizzard currency/money frames are hidden:
- `MerchantMoneyFrame`
- `MerchantExtraCurrencyInset` and all its children

A pre-allocated pool of 5 token frames is created at startup. Additional frames are created on demand if a vendor requires more than 5 distinct currencies.

Tokens flow **right-to-left** within a line. When the next token would overflow the banner width, a new line is started below the current one.

## Token Types

Each token frame (TokenMixin) handles one of three data sources:

| Type | API Used | Description |
|---|---|---|
| Gold | Native gold functions | Player's gold; costs in copper |
| Currency | `C_CurrencyInfo.GetCurrencyInfo(id)` | WoW tracked currencies (honor, valor, etc.) |
| Item | `C_Item` | Items used as currency (e.g., specific reagents) |

## Display Modes

Controlled by the `Format` option (set in OptionsButton → Token Banner submenu):

| Mode | Display |
|---|---|
| `'Need'` | Shows only the total required amount |
| `'Have'` | Shows only the player's current amount |
| `'Both'` | Shows "Have / Need" |

## Token Frame Behavior (TokenMixin)

Each token tracks:
- **Need**: Total quantity of this currency/item required by all visible merchant items
- **Have**: Player's current amount

Rendering:
- Icon: 14×14 texture fetched from the currency/item info
- Text: Formatted according to the `Format` option, with optional abbreviation (controlled by `CurrencyAbbreviate`)

**OnEnter tooltip**: Shows current amount vs. needed amount with descriptive label.

**OnClick**:
- For currencies: Toggles the currency window (`ToggleCharacter("CurrencyFrame")`)
- For items: Invokes `HandleModifiedItemClick(link)` allowing chat linking, shift-click looting, etc.

## Calculation Functions

`TokenBanner.lua` computes totals by iterating all visible merchant items (using the filtered `CachedItemIndices`):

| Function | Computes |
|---|---|
| CalculateGoldCount() | Total gold cost across all visible items |
| CalculateCurrencyCounts() | Per-currencyID sum of costs |
| CalculateItemCounts() | Per-itemID sum of costs |

The **Update** function is the main refresh entry point. It is triggered after `MerchantFrame_UpdateMerchantInfo` and `MerchantFrame_UpdateBuybackInfo`. Execution order: Gold → Currencies → Items → HideRemainingTokens.

## Formatting Options (AceDB Defaults)

| Option | Default | Description |
|---|---|---|
| MoneyLabel | false | Show "Gold"/"Silver"/"Copper" labels |
| MoneyAbbreviate | false | Abbreviate large gold values |
| ThousandsSeparator | false | Insert thousands separators |
| MoneyGoldOnly | false | Show only the gold denomination |
| MoneyColored | false | Color gold/silver/copper values |
| CurrencyAbbreviate | false | Abbreviate currency amounts |
| Format | 'Both' | Need / Have / Both |

## Version History

| Version | Change |
|---|---|
| 19.0 | Token Banner introduced |
| 19.1 | ElvUI skinning support; frame size fix on buyback tab |
| 20.0 | Migrated to `C_MerchantFrame.GetItemInfo` |
| 21.1 | Format option (Need/Have/Both) added |
| 21.2 | Token click opens currency window; items can be linked in chat |

## See Also

- [GUI Components](gui-components.md) — OptionsButton menu injects token banner settings
- [Options and Configuration](options-and-configuration.md) — Default values
- [Overview and Architecture](overview-and-architecture.md)
