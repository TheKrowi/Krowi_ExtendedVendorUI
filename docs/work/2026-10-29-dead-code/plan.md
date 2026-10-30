# Plan: Remove dead code and a stale editor global
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

## Files that change
- `Krowi_ExtendedVendorUI.lua`: the Version data section goes.
- `Filters.lua`: `RefreshFilters` and its callbacks go.
- `Gui/TokenBanner/TokenBanner.xml`, `Options/Files.xml`: the two script lines go; the two files are deleted.
- `.vscode/settings.json`: only the `MerchantFrame_SetFilter` line is committed; the Ketho extension's own additions in the working copy stay out of the commit.
- `CLAUDE.md`: the two debt entries go.

## Proof
Tonight's `/kevutest` runs: no Lua error from this addon on Retail and a Classic client.
