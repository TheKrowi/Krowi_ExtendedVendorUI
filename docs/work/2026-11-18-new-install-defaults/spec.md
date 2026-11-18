# Spec: A bigger first grid and a glowing gear for new players
Intent: [intent.md](intent.md). Status: accepted

## Requirements
1. When `KrowiEVU_Options` is nil at `ADDON_LOADED` (no saved settings on the account), the profile gets `NumRows = 7`, `NumColumns = 4` and `HighlightOptionsButton = true` before the slots are created.
2. Otherwise nothing changes: the defaults stay 5 × 2 and `HighlightOptionsButton = false`, also for a new or reset profile.
3. While `HighlightOptionsButton` is true, a glow pulses around the gear; the first mouse-down on the gear sets it false and hides the glow for good (all characters share the Default profile).
4. `/kevutest` checks the glow shown and pulsing with the setting on, gone with the setting cleared after the click handler, and puts the setting back.

## Design
- `Krowi_ExtendedVendorUI.lua`: `freshInstall = KrowiEVU_Options == nil` before `addon.Options:Load`, then the three writes. AceDB saves `profileKeys` for every character, so an existing install never has a nil table.
- `Options/Defaults.lua`: `HighlightOptionsButton = false`.
- `Gui/OptionsButton/OptionsButtonMixin.lua`: `UpdateHighlight` creates, on first need, an OVERLAY texture (`Interface\Buttons\UI-ActionButton-Border`, ADD blend, 1.8 × the button) with a bouncing Alpha animation (0.25 to 1, 0.8 s); `ClearHighlight` is hooked on `OnMouseDown` with `HookScript` on the addon's own button. `OptionsButton:Load` calls `UpdateHighlight`.
- `Tests/Tests.lua`: step `gear-highlight` after `arrow`.

## Options considered
- Grid: written on a fresh install (chosen) / the default changed to 4×7 with existing profiles pinned to 5×2 by a migration (saved-data class, the repo's first migration).
- Who: new installs only (chosen) / everyone once.
- Look: pulsing glow (chosen) / glow plus a tooltip (a new string in six locales). Blizzard's help tip and glow templates were not offered: they would run Blizzard code from the addon.

## Areas of concern
- Taint: only the addon's own button gets a texture, an animation and a `HookScript`; no Blizzard frame, function or template is touched. Reviewed by `krowi:taint-reviewer`.
- Clients: all five; `UI-ActionButton-Border`, `SetFromAlpha`/`SetToAlpha` and `BOUNCE` looping exist on every client the TOC lists. Classic's button is 18 × 22, the modern one Blizzard's icon dropdown button.
- Blizzard API changes: none.
- Other addons, plugins and skins: ElvUI and GW2_UI skin the gear; the glow sits on OVERLAY above their skin (look check).
- Saved variables: one new profile key with a default; no migration.
- Localization: no new text.
- Embedded libraries: none.
- Player-facing text: two changelog lines.

## Verification
- Syntax hook, `Find-DeprecatedApi.ps1`, `krowi:taint-reviewer`, `/code-review`.
- Look check on Retail with the account's `KrowiEVU_Options` taken out of the saved-variables file (backed up, put back after): 4 × 7 grid and the glow on the first vendor, gone after a click on the gear, still gone after `/reload`.
- `/kevutest` on all five clients: `gear-highlight` passes.

## Decision
Krowi, 2026-11-18: "Write it on a fresh install", "New installs only", "Pulsing glow". 4x7 read as 4 columns × 7 rows, to be confirmed at the look check.