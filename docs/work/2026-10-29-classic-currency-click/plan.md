# Plan: Clicking a currency in the token banner errors on Classic
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

## Files that change
- `Gui/TokenBanner/TokenMixin.lua`: `OnClick` calls a local `ToggleCurrencyTab`: `ToggleTokenFrame` on Retail and Forever; on Classic `ToggleCharacter('TokenFrame')` where Blizzard's `CHARACTERFRAME_SUBFRAMES` has it and there are currencies (Mists), else `ToggleCharacter('PVPFrame')` where that is a tab (Anniversary), else nothing (Era) (commit 18c6a96).
- `_Packaging/Changelog.md`: one Fixed line under 24.2.
- `CLAUDE.md`: the debt entry goes.

## Proof
- Mists: at a vendor charging a currency, click it: the Currency tab opens; again: it closes; shift-click links it. `Read-GameErrors.ps1 -Client Classic`: no new row.
- Anniversary: at an honor or arena vendor, see whether the banner shows those points as currencies; if so, a click opens the PvP tab.
- Era: no currency in the banner, or a click does nothing.
- Retail: the click still opens the Currency tab.

## Taint review (2026-10-29)
No taint or secret-value finding. One low finding, fixed: in combat, Blizzard refuses `ShowUIPanel`/`HideUIPanel` from addon code after `ToggleCharacter` has already switched the tab, and prints "Interface action failed because of an AddOn"; Retail's `ToggleTokenFrame` had the same. `ToggleCurrencyTab` now returns in combat on every client. The tainted tab state is written into CLAUDE.md's taint section.

## Where the build departed
Built without a separate plan stage (Krowi, 2026-10-29). The reproduction before the fix was not recorded in game; the error follows from the code (the method is nil on every Classic character frame).