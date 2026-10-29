# Plan: Hide collected never hides illusions
Spec: [spec.md](spec.md). Status: built; the in-game check is pending

## Files that change
- `Filters.lua`: `filters.IsIllusionCollected` reads the Already known line.
- `Tests/Tests.lua`: step `illusions` (only where the vendor sells consumables of type Other): turns Hide collected, Illusions on under All, checks shown against collected, cross-checks with `C_TransmogCollection.GetIllusions` by name, notes the first four items' tooltip lines; the option goes back at the end.
- `_Packaging/Changelog.md`: one Fixed line under 24.2.
- `CLAUDE.md`: the debt entry goes.
- After the game proves it: `_Packaging/Description.md` lists illusions under Hide Collected again.

## Proof
The spec's verification. If the notes show no Already known line on a collected illusion, the fix is wrong: the changelog line goes and the debt entry comes back with what the notes show.
