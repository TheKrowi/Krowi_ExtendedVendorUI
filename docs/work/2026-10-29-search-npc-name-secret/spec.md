# Spec: The search box reads the vendor's name without a secret-value probe
Intent: [intent.md](intent.md). Status: accepted

## Requirements
1. Opening a vendor never gives a Lua error from the search box's `MerchantFrame` `OnShow` hook, on any client, whether the vendor's name can be read or not.
2. Where the name can be read, Remember search behaves as today: off clears the search; on with between vendors on keeps it; on with between vendors off keeps it for the same vendor and clears it for another.
3. Where the name is secret, the vendor counts as a different vendor: with Remember search on and between vendors off, the search is cleared. The next vendor after it also counts as a different vendor.
4. A secret value is never kept in `previousUnitName`.
5. Classic clients, which have no secret values, behave exactly as today.

## Root cause
`Gui/SearchBox/SearchBoxMixin.lua:49-66`: the hook keeps `UnitName('npc')` in `previousUnitName` and, with Remember search on and between vendors off, compares it with the next vendor's name (line 60). On Retail and Forever `UnitName` is `SecretWhenUnitNameIdentityRestricted` (live and forever `Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`): "regular unit identity secrecy rules" (`SecretPredicatesDocumentation.lua`), that is a unit that is not player-controlled or in the group, while an addon restriction is on (`Enum.AddOnRestrictionType`: Combat, Encounter, ChallengeMode, PvPMatch, Map, Chat). A vendor NPC is never player-controlled, so the name is secret at a vendor opened under such a restriction: a vendor mount (Traveler's Tundra Mammoth, Grand Expedition Yak, the Brutosaurs) or Jeeves or Reaves in a raid, a Mythic+ dungeon or a PvP instance, or a vendor inside a scenario or delve where the map restriction applies. Comparing a secret value errors, also later, when the kept secret is compared with the next vendor's readable name. Blizzard's own `MerchantFrame:SetTitle(UnitName("npc"))` (live `Mainline/MerchantFrame.lua:268`) is fine because `SetTitle` accepts secrets.

No other key helps: `UnitGUID`, `UnitFullName`, `UnitNameUnmodified` and `UnitCreatureID` are `SecretWhenUnitIdentityRestricted` too. `Filters.lua:514` reads `UnitName('player')`, which is player-controlled and never secret. `Tests/Tests.lua:88` already probes.

Reproduction: not reported yet. It needs a vendor under a restriction (see Verification).

## Design
In the hook, probe the name the way `Filters.lua:535` probes tooltip text: `if issecretvalue and issecretvalue(currentNpcName) then currentNpcName = nil end`. The same-vendor test (line 59-60) also needs `currentNpcName ~= nil`, so two vendors in a row with a secret name do not count as the same vendor through `nil == nil`. Everything else in the hook stays as it is; `previousUnitName` then only ever holds a readable name or nil.

## Options considered
1. **Recommended: a secret name counts as another vendor.** At a vendor in a restricted place, the search is cleared, as for any new vendor; the next vendor clears it as well. Nobody keeps a search they did not mean to.
2. **A secret name counts as the same vendor.** The search is kept at every restricted vendor. Two different vendors in one raid would then share a search, which Remember search between vendors off is meant to prevent.
3. **Compare another key** (`UnitGUID`, the vendor's item list). `UnitGUID` is restricted the same way; comparing item lists is costly and still guesses. Not chosen.

## Areas of concern
- **Taint and secret values:** read only, no Blizzard write. The probe is the fix. `issecretvalue` is nil on Classic, guarded with `issecretvalue and`.
- **Clients:** Retail and Forever have the flag (live and forever docs agree). Mists, Anniversary and Era have no secret values; the code path is the same with the probe skipped.
- **Blizzard API changes:** none.
- **Other addons, plugins and skins:** none; the hook touches only the addon's search box.
- **Saved variables:** none; `previousUnitName` lives only in memory.
- **Localization:** none.
- **Embedded libraries:** none.
- **Player-facing text:** a changelog line under Fixed: "Opening a vendor in a raid, dungeon or PvP match no longer gives an error with Remember search on".

## Verification
- `krowi:taint-reviewer` on the diff; Lua 5.1 syntax hook.
- In game, Retail, a normal vendor (regression): Remember search on, between vendors off. Search, close, reopen the same vendor: the search stays. Open another vendor: it is cleared. Remember search between vendors on: it stays. Remember search off: it is cleared.
- In game, Retail, a restricted vendor (the fix): the vendor in the Labyrinth (easy to repeat), or a vendor mount in a raid, with Remember search on and between vendors off. Open it twice, then a normal vendor outside; `Read-GameErrors.ps1` shows no new row. First, `/run print(issecretvalue(UnitName('npc')))` at that vendor confirms the name is secret there.
- One Classic client: the regression steps above.

## Decision
Krowi, 2026-10-29: option 1, a secret name counts as another vendor. The restricted case is tested at the vendor in the Labyrinth, or with a vendor mount in a raid.