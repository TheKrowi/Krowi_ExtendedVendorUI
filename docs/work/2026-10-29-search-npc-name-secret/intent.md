# Intent: The search box reads the vendor's name without a secret-value probe
Author: Krowi (maintainer), from the known-debt list in `CLAUDE.md`. Source: known debt (found 2026-10-15, rechecked 2026-10-29). Status: draft

## Problem
When the vendor window opens, the search box's `MerchantFrame` `OnShow` hook (`Gui/SearchBox/SearchBoxMixin.lua:49-66`) reads `UnitName('npc')`, keeps it, and with Remember search on and Remember search between vendors off compares it with the previous vendor's name (line 60) to decide whether to keep the search. On Retail 12.x `UnitName` is `SecretWhenUnitNameIdentityRestricted` (live `UnitDocumentation.lua`). Where that restriction is on, the name is a secret value and the comparison errors. No player has reported it yet.

## Proposed outcome
Opening a vendor never gives a Lua error, wherever the player stands. Remember search keeps working as it does now wherever the name can be read.

## Affected users and systems
- Clients: Retail; WoW Forever if its `UnitName` carries the same flag. Classic clients have no secret values.
- Options: Remember search and Remember search between vendors (both off by default, `Options/Defaults.lua:15-16`), so only players who turned on Remember search alone hit the comparison.
- Places: wherever a vendor can be opened under a unit-name restriction (to be found, see below).

## Constraints
- Read only: the probe must not write anything Blizzard owns.
- No change on Classic. `issecretvalue` may be nil there.
- The Remember search behaviour stays the same wherever the name is readable.

## Open questions
- With a secret name, keep the search (treat it as the same vendor) or clear it (treat it as another)?
- Is there a key that is never secret, such as `UnitGUID('npc')`, that could replace the name?

## Exploration steps
1. Read the flags of `UnitName`, `UnitGUID` and `UnitFullName` in live's and Forever's `Blizzard_APIDocumentationGenerated/UnitDocumentation.lua`, and the `Enum.AddOnRestrictionType` values, to learn which restriction makes the name secret.
2. List where a vendor can be opened under such a restriction: a summoned vendor (Jeeves, Reaves, a repair mount) in a Mythic+ dungeon, a raid encounter or a PvP instance, and vendors inside scenarios or delves.
3. In game at such a vendor (read only): `/run print(issecretvalue(UnitName('npc')), C_RestrictedActions.IsAddOnRestrictionActive(Enum.AddOnRestrictionType.<X>))`. Then reproduce with Remember search on and between vendors off: open the vendor and check `Read-GameErrors.ps1`.
4. Check the other reads: `Tests/Tests.lua:88` already probes with `issecretvalue`; `Filters.lua:514` reads `UnitName('player')`, so check whether `player` can be restricted.
5. Write the spec with the keep-or-clear options, then run `krowi:taint-reviewer` on the change.