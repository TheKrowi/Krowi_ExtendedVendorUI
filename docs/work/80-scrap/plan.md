# Plan: Scrap's button outside the window at a repair vendor
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

## Files that change
- `Plugins/Scrap.lua` (new), `Plugins/Files.xml`.
- `Localization/enUS.lua`: `Plugin_Scrap_Name`, `Plugin_Scrap_Desc`.
- `Tests/Tests.lua`: `Scrap` in the recorded addons; `CheckScrap` in every merchant-tab check.
- `_Packaging/Changelog.md`, `CLAUDE.md`.

## Order
Stacked on #116 (branch `docs/2026-10-29-known-debt`), so tonight's one `/kevutest` pass per client covers 24.2 and this fix.

## Proof
The spec's verification. Before the fix is only proven by the reporters' screenshots and the code; the run's note shows what Scrap had set before the plugin moved it.
