# Plan: The arrows in the hide-options-button text never show
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

## Files that change
- `Gui/OptionsButton/OptionsButtonMixin.lua`: line 2 takes `addonName`, line 50 builds the media path from it (commit 3cd3e2a).
- `_Packaging/Changelog.md`: one Fixed line under 24.2.
- `CLAUDE.md`: the debt entry goes.

## Proof
The spec's Verification.