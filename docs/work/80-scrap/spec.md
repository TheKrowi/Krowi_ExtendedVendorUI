# Spec: Scrap's button outside the window at a repair vendor
Intent: [intent.md](intent.md). Status: accepted (Krowi, 2026-10-29)

## Requirements
1. Mists, Anniversary and Era with Scrap: at a repair vendor Scrap's button is inside the vendor window, right of the last repair button.
2. With guild repair, `MerchantRepairAllButton` has one anchor, this addon's.
3. At a vendor without repair, Scrap's own placement stays (left of the buyback item, inside the window).
4. Retail and Forever: unchanged.
5. `/kevutest` checks 1 and 2 and notes what Scrap had done before.

## Root cause (reproduced by the two reporters' screenshots; code as of 2026-10-29)
- Scrap 12.1.3 (`addons/merchant/button.lua`, current on GitHub): without `MerchantSellAllJunkButton` (absent from every Classic client's `MerchantFrame.xml`), `UpdatePosition` runs from its own `MerchantFrame_UpdateRepairButtons` post-hook and on `MERCHANT_SHOW`. At a repair vendor it sets `SetPoint('RIGHT', MerchantRepairItemButton, 'LEFT', off, 0)`; with guild repair it also calls `MerchantRepairAllButton:SetPoint('BOTTOMRIGHT', MerchantFrame, 'BOTTOMLEFT', 120, 35)` without clearing.
- This addon (`Gui/MerchantFrame.lua:29-44`, unchanged on Classic since 20.0) anchors `MerchantRepairAllButton` `LEFT` at 52 in its buttons inset and `MerchantRepairItemButton` left of it, so the repair-item button sits at the inset's left edge and Scrap's button lands left of the window. Scrap's second anchor plus this addon's `LEFT` anchor stretch the repair-all button.
- Scrap's merchant code is the load-on-demand addon `Scrap_Merchant`, which Scrap loads in its own `MERCHANT_SHOW` handler (`addons/main/main.lua:40-43`), so its `MerchantFrame_UpdateRepairButtons` post-hook is added after this addon's and runs after it, undoing it.

## Design
`Plugins/Scrap.lua` (returns at its top on Retail and Forever): when `Scrap_Merchant` loads (`ADDON_LOADED`, or at once if it already has), `hooksecurefunc(Scrap.Merchant, 'UpdatePosition', Place)`. `Scrap` is the global WildAddon's `NewAddon` creates, `Scrap.Merchant` the module (`WildAddon-1.1.lua` `newobject`). Scrap calls `self:UpdatePosition()`, so the hook runs after every placement. `Place` runs this addon's `UpdateRepairButtons` again (clears the second anchor) and, at a repair vendor, anchors Scrap's button `LEFT` of the last repair button's `RIGHT` + 8; at a vendor without repair it only clears its own `LEFT` anchor from an earlier vendor, which would otherwise stretch the button against Scrap's `RIGHT` one. Space: the inset is 185 wide; repair-item 8-44, repair-all 52-88, guild 96-128 (32 wide on Classic), Scrap 136-169 at Scrap's 0.9 scale.

## Areas of concern
- Taint: only method calls on Blizzard's repair buttons (as the existing layout) and on Scrap's own frame; the hook is on Scrap's table, not Blizzard's. Not protected frames.
- Clients: Mists, Anniversary, Era. Scrap's TOC claims every flavour; its Retail and Forever path is untouched.
- Other addons: ElvUI calls `addon.Gui.MerchantFrame.UpdateRepairButtons` too; running it once more is harmless.
- Localization: two plugin strings in `enUS.lua` (name, description), as every plugin has. Saved variables, libraries: none.
- Player text: a changelog Fixed line.

## Verification
Tonight, Anniversary (and Mists if Scrap is installed there), Scrap ticked: `/kevutest` at a repair vendor with more than one page, and with guild repair if a character has it; the Scrap checks pass and the notes show Scrap's anchor before the plugin. A vendor without repair: Scrap's button inside the window.
