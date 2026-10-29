# Intent: The arrows in the hide-options-button text never show
Author: Krowi (maintainer), from the known-debt list in `CLAUDE.md`. Source: known debt (found 2026-10-15, rechecked 2026-10-29). Status: draft

## Problem
Hiding the options button asks "Are you sure you want to hide the options button?" and says where to show it again: Game Menu, AddOns, Extended Vendor UI and so on, with an arrow texture between the steps (`{arrow}`, filled in by `ReplaceVarsWithMenu`, `Gui/OptionsButton/OptionsButtonMixin.lua:50-63`, used at line 195). The texture path is `Interface\AddOns\Krowi_MerchantFrameExtended\Media\ui-backarrow`, the addon's old folder name. The file ships as `Media\ui-backarrow.tga` in this addon's folder, so the arrows never show.

## Proposed outcome
The arrows show between the steps of that text on every client.

## Affected users and systems
- Every client.
- The confirmation popup from the options button's Hide entry. The zhCN translation writes the arrows as text (→) and is not affected.

## Constraints
- No other text changes. The localized strings keep their `{arrow}` placeholders.

## Open questions
None.

## Exploration steps
1. Find every use of `K_ReplaceVarsWithMenu` and `{arrow}` (the options pages and the locale files).
2. In game, open the options button menu, choose Hide and take a screenshot of the popup (cancel it) to see what shows now.
3. Build the path from the addon's folder name (`local addonName, addon = ...`) or a Krowi_Util media helper if there is one, check the screenshot again on one Retail and one Classic client.