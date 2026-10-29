# Spec: The arrows in the hide-options-button text never show
Intent: [intent.md](intent.md). Status: accepted

## Requirements
1. The confirmation for hiding the options button shows an arrow texture between the steps of the path, on every client.
2. No text changes.

## Root cause
`Gui/OptionsButton/OptionsButtonMixin.lua:50` builds the `{arrow}` texture (`ReplaceVarsWithMenu`, `:51-63`, used at `:195`) from `Interface\AddOns\Krowi_MerchantFrameExtended\Media\`, the addon's old folder name. The texture ships as `Media\ui-backarrow.tga` in `Krowi_ExtendedVendorUI`. `K_ReplaceVarsWithMenu` has no other caller.

## Design
Take the folder name from the file's varargs (`local addonName, addon = ...`) and build the path from it, so a future rename cannot break it again.

## Options considered
Only this one; hard-coding the new folder name would repeat the bug at the next rename.

## Areas of concern
- **Taint and secret values:** none; a string in the addon's own popup text.
- **Clients:** every client; the Media folder ships everywhere.
- **Localization:** the enUS, deDE, itIT and ruRU strings use `{arrow}`; frFR's translation leaves out the path and zhCN writes the arrows as text, so both are unaffected.
- **Other addons, saved variables, libraries:** none.
- **Player-facing text:** changelog under Fixed: "The message for hiding the options button shows its arrows again".

## Verification
Retail and one Classic client: options button menu, Hide, screenshot of the popup with the arrows, then Cancel.

## Decision
Krowi, 2026-10-29: no open question, built without a gate ("tackle the things you know so far").