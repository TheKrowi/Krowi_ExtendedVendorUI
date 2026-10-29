# Plan: The search box reads the vendor's name without a secret-value probe
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

## Files that change
- `Gui/SearchBox/SearchBoxMixin.lua`: the `OnShow` hook sets a secret name to nil, and the same-vendor test needs a name (commit b8d27d5).
- `_Packaging/Changelog.md`: one Fixed line under 24.2.
- `CLAUDE.md`: the debt entry goes.

## Proof
- Retail, Labyrinth vendor or a vendor mount in a raid, Remember search on and between vendors off: `/run print(issecretvalue(UnitName('npc')))` prints true; open it twice with a search typed, then a normal vendor; `Read-GameErrors.ps1` shows no new row.
- Retail, normal vendors: the four Remember search cases of the spec's Verification.
- One Classic client: the same four cases.

## Where the build departed
Built without a separate plan stage (Krowi, 2026-10-29: "no time to continue plans, tackle the things you know so far").