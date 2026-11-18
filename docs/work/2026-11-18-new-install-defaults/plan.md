# Plan: A bigger first grid and a glowing gear for new players
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

The plan gate (`ask` for a feature) was not asked on its own: the build followed the design answers, as Krowi's "together with the fix ... after this, the pc is free and you can run your tests" read as a go. Said in the PR.

## Files that change
`Krowi_ExtendedVendorUI.lua`, `Options/Defaults.lua`, `Gui/OptionsButton/OptionsButton.lua`, `Gui/OptionsButton/OptionsButtonMixin.lua`, `Tests/Tests.lua`, `_Packaging/Changelog.md`, `CLAUDE.md` (Testing in game).

## Order of work
1. Code and the `/kevutest` step (stacked on `fix/126-already-known-case`, so one deploy carries the 24.4 work).
2. Taint review, deploy to Retail, look check on a simulated fresh install.
3. After Krowi approves the look: `/kevutest` on the five clients.

## Risks
- A fresh-install check that misfires for an existing player: AceDB always saves `profileKeys`, so only a missing table counts.
- Taking `KrowiEVU_Options` out for the look check: the file is backed up and the block put back once the client has quit.

## Proof
`/kevutest` `gear-highlight` PASS on every client; the look check screenshots.