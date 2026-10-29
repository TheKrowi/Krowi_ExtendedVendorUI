# Spec: Tooltips on the repair buttons with nothing to repair
Issue #32 (filliph, 2024-07-25). Status: accepted (Krowi, 2026-10-29: "#32 want"). Intent folded in: an unambiguous request.

## Problem
With nothing to repair the repair-all buttons (own money, guild money) are disabled and show no tooltip, so a player cannot tell them apart (filliph, 2024-07-26 and 2026-06-05). Blizzard's own window behaves the same.

## Requirements
1. Every client: hovering a disabled repair-all button shows Repair All Items and Nothing to repair; the guild one shows Repair all items with guild money and Nothing to repair.
2. With something to repair, Blizzard's own tooltip (cost, guild funds) is unchanged.
3. `/kevutest` checks the buttons' setting and, in a mouse step at a vendor that repairs, the tooltip.

## Root cause
A disabled button runs no `OnEnter`/`OnLeave` unless `SetMotionScriptsWhileDisabled(true)` (Blizzard sets it on hundreds of its own buttons on every client). And Blizzard's `OnEnter` for both buttons writes text only when `canRepair and repairAllCost > 0` (live `Mainline/MerchantFrame.xml:240-252`, `338-371`; TBC `MerchantFrame.xml:215-222`, `295-...`). The repair-one-item button is never disabled and always says Repair an Item.

## Design
`Gui/MerchantFrame.lua`, after the repair layout: `SetMotionScriptsWhileDisabled(true)` on `MerchantRepairAllButton` and `MerchantGuildBankRepairButton`, and a `HookScript('OnEnter')` post-hook that, only while the button is disabled, sets the tooltip text and shows it. Blizzard's `OnLeave` (`GameTooltip_Hide`) then also runs while disabled.

## Areas of concern
- Taint: a method call and a `HookScript` post-hook on Blizzard's unprotected buttons (both within the repo's rules); the hook writes `GameTooltip` from addon code on hover, as the token banner and slots already do.
- Clients: all five; the buttons and `REPAIR_ALL_ITEMS` exist everywhere.
- Other addons: ElvUI and Scrap move these buttons, not their scripts.
- Localization: two new strings, Nothing to repair and Repair all items with guild money.
- Player text: a changelog line.

## Verification
`/kevutest` at a vendor that repairs: the `all` step's check and the `repair` mouse step (hover the hammer) on Retail and a Classic client, once with nothing to repair.
