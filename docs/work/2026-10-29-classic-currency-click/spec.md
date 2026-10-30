# Spec: Clicking a currency in the token banner errors on Classic
Intent: [intent.md](intent.md). Status: accepted

## Requirements
1. Clicking a currency in the token banner never gives a Lua error, on any client.
2. Retail and WoW Forever behave as today: the click opens (or closes) the Currency tab.
3. Mists Classic: the click opens the character window on the Currency tab, and closes it when that tab is already open, as on Retail; with no currencies at all it does nothing, as Retail's `ToggleTokenFrame` does.
4. TBC Anniversary: the click opens the character window on the PvP tab, where honor and arena points show.
5. Classic Era: the click does nothing.
6. Shift-click still links the currency in chat on every client.

## Root cause
`Gui/TokenBanner/TokenMixin.lua:138-140` calls `CharacterFrame:ToggleTokenFrame()`. Only the Mainline character frame has it: `CharacterFrameMixin:ToggleTokenFrame` (live `Blizzard_UIPanels_Game/Mainline/CharacterFrame.lua:67`, forever `:60`), which returns when `C_CurrencyInfo.GetCurrencyListSize() <= 0` and otherwise calls `ToggleCharacter("TokenFrame")`. The Classic clients load another character frame per game type (`Blizzard_CharacterFrame.toc` in the classic, classic_anniversary and classic_era sources), and none of them has `ToggleTokenFrame`, so the method is nil:
- **Mists** (game type mists) loads `Cata/CharacterFrame.lua`. `CHARACTERFRAME_SUBFRAMES` includes `TokenFrame`, and `ToggleCharacter("TokenFrame")` opens the Currency tab (`Blizzard_TokenUI_Mists.toc`).
- **Anniversary** (tbc) loads `TBC/CharacterFrame.lua`: the tabs are Character, Pet, Reputation, Skills and PvP (`TBC/CharacterFrame.xml`, `CHARACTERFRAME_SUBFRAMES` with `PVPFrame`). No TBC file refers to `TokenFrame`, so there is no Currency tab; honor and arena points show on the PvP tab.
- **Era** (vanilla) loads `Vanilla/CharacterFrame.lua`: Character, Pet, Reputation, Skills and Honor; no currency view, and no Era vendor is known to charge a currency.

Reproduction: to record before the fix, on Mists at a vendor that charges a currency: click it, then `Read-GameErrors.ps1 -Client Classic`.

## Design
Keep the Retail and Forever branch (`addon.Util.IsModern`). On Classic, open the tab Blizzard's own tab button would open, through `ToggleCharacter`, which every Classic character frame has: `TokenFrame` where it is one of the character window's subframes (Mists, after the same currency-count check Retail makes), `PVPFrame` on Anniversary, nothing on Era. Testing for the subframe with Blizzard's `CHARACTERFRAME_SUBFRAMES` (read only) rather than by client flag keeps a future Classic client with a Currency tab working without a change.

## Options considered
1. **Recommended: Mists opens the Currency tab, Anniversary the PvP tab, Era nothing.** What a player sees: on Mists the click works as on Retail; on Anniversary the click on honor or arena points opens the PvP tab with those totals; on Era nothing happens, as today minus the error.
2. **Mists opens the Currency tab; Anniversary and Era do nothing.** Smaller; the Anniversary click no longer errors but does nothing.
3. **No click action on any Classic client.** Removes the error only; Mists players lose a working Currency tab link they could have.

## Areas of concern
- **Taint and secret values:** `ToggleCharacter` from addon code ends in `ShowUIPanel`/`HideUIPanel` on `CharacterFrame`, as Retail's `ToggleTokenFrame` already does from this click; in combat Blizzard refuses it (`CheckProtectedFunctionsAllowed`) and nothing happens. Nothing Blizzard owns is written; `CHARACTERFRAME_SUBFRAMES` is only read. `krowi:taint-reviewer` on the diff, Classic branches included.
- **Clients:** Retail and Forever unchanged; Mists, Anniversary and Era as above.
- **Blizzard API changes:** none. `GetCurrencyListSize` is the Classic global (`Cata/Blizzard_TokenUI.lua:65`); use `C_CurrencyInfo.GetCurrencyListSize` where it exists.
- **Other addons, plugins and skins:** none; ElvUI and GW2_UI skin the character window but do not change `ToggleCharacter`.
- **Saved variables, localization, embedded libraries:** none.
- **Player-facing text:** changelog under Fixed: "Clicking a currency in the token banner no longer gives an error and opens the Currency tab (Mists Classic) or the PvP tab (TBC Anniversary)".

## Verification
- In game, Mists: the reproduction above, then after the fix the click opens the Currency tab, a second click closes it, shift-click links it; `Read-GameErrors.ps1` shows no new row.
- In game, Anniversary: at an honor or arena vendor, check first which costs the banner marks as a currency (if honor and arena points are not, the click path never runs there); then the click opens the PvP tab.
- In game, Era: open a vendor and confirm the banner shows no currency, or that a click does nothing.
- Retail: the click still opens the Currency tab.
- `krowi:taint-reviewer` on the diff; Lua 5.1 syntax hook.

## Decision
Krowi, 2026-10-29: option 1. Mists opens the Currency tab, Anniversary the PvP tab, Era nothing.