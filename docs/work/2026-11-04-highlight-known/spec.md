# Spec: Highlight known items on the vendor grid
Intent: [intent.md](intent.md). Status: accepted (Krowi, 2026-11-25)

## Requirements
1. With the new option on, every item on the grid that counts as known (requirement 2) is marked; every other item looks exactly as it does today.
2. An item counts as known by its category's own check, the same one Hide collected uses (`Filters.lua`): pets (`IsPetCollected`), mounts, toys, appearances (`IsTransmogCollected`), appearance sets, illusions, recipes (`IsRecipeCollected`), housing decor (`IsHousingCollected`, with the Housing quantity setting) and, for items in no category, the Already known line (`filters.IsKnown`). The categories that do not exist on a client (pets, sets, illusions and housing on the Classic clients) count through the Already known line there, as Other does.
3. A known item's mark replaces Blizzard's colors on that slot (red for unusable, gray for sold out), as Already Known's did: it is drawn after `Tint` in `Gui/MerchantItemSlot.lua`. On the next draw of that slot with another item, or with the option off, the slot gets Blizzard's colors back.
4. Hide collected keeps working as it does: an item it hides is not shown, so it is never marked. The mark shows the collected items Hide collected leaves in the list.
5. An item whose data is not cached yet reads as not known and is marked once its data arrives and the page is drawn again (the existing `WaitForItemInfo` path); a secret tooltip line (12.x) reads as not known.
6. The option works the same on Retail, Mists Classic, TBC Anniversary, WoW Forever and Classic Era.
7. The option's name and description are in every locale file (`enUS`, `deDE`, `frFR`, `itIT`, `ruRU`, `zhCN`).
8. `/kevutest` checks it: with the option on, each slot on the page is marked exactly when the known check says so; with it off, no slot is.

## Design
- **Check:** a new `filters.IsCollected(itemId)` in `Filters.lua` returns the verdict of requirement 2: the category's own `Is<Category>Collected`, or `filters.IsKnown` for an item in no category. It reads only, sets nothing and does not look at the Hide collected switches.
- **Mark:** in `Gui/MerchantItemSlot.lua`, after `Tint` in `DrawMainline` and `DrawClassic`, `MarkCollected(slot, itemId)` colors the name frame, slot and icon with the mark color when the option is on and `IsCollected` is true, the same four `SetItemButton*VertexColor` calls Already Known makes, and grays the icon (`SetItemButtonDesaturated`) when the gray setting is on. Blizzard's draw already resets all four colors and the desaturation on every draw, so nothing has to undo a mark.
- **Look:** decided in game (`look` gate). Two looks go in behind a temporary debug switch: Already Known's (green name frame and slot, icon at 90 %, `0, 1, 0` by default) and a gray icon like Blizzard's own known heirlooms (`SetItemButtonDesaturated`, the slot untinted).
- **Already Known's settings:** when Already Known is loaded (`C_AddOns.IsAddOnLoaded('AlreadyKnown')`), the mark takes its color and monochrome setting from its global `AlreadyKnownSettings` (`r`, `g`, `b`, `monochrome`), read only, at each draw. Its players then see on this grid what they saw before 23.0, with no setup. Without it, the addon's own defaults.
- **Setting:** `KrowiEVU_Filters` profile `MarkCollected = { Enabled = <default>, ... }`, a new field with an AceDB default (no migration). The switch sits in the filter menu right after the Hide collected section, as one checkbox, since it is the counterpart of Hide collected and changes the list's look as the filters do; toggling it redraws the page.

## Options considered
Recommendation first.

1. **This addon marks known items itself, with its own check and Already Known's look when it is loaded** (chosen). Works for every player on every client, no dependency on another author, reuses the checks Hide collected already proves in `/kevutest`.
2. **A plugin that brings Already Known's own check to this grid.** Not possible: Already Known's check (`_checkIfKnown`, `AlreadyKnown.lua:212`) is a local; only its settings are global. A plugin could copy its look, not its verdict, which is option 1 limited to Already Known's players.
3. **Ask ahakola to draw on `KrowiEVU_MerchantItem<N>` through `KrowiEVU.PluginsApi`** (as Transmog Loot Helper's author did, #97). The only way to get exactly Already Known's verdict (it also marks quest-unlock items and a few special items, `AlreadyKnown.lua:221-240`), but it depends on another author and helps only Already Known's players. Can be offered to ahakola later, alongside option 1.
4. **Only the Already known line** (`filters.IsKnown`) as the check. Smaller, but misses what the line never says: collected appearances, owned decor, pets you own a copy of (Already Known marks "Collected (1/3)"), mounts and toys on clients where the line is missing.

## Areas of concern
- **Taint and secret values:** colors only on the addon's own slots (created from `MerchantItemTemplate` by addon code), through the same `SetItemButton*` helpers `Tint` already calls; no Blizzard frame, function or global is touched. Reading `AlreadyKnownSettings` is a read of another addon's table. The tooltip read (`filters.GetTooltipLines`) already treats secret lines as unreadable (requirement 5). Draw path is taint-sensitive per `CLAUDE.md`: `krowi:taint-reviewer` runs on the diff.
- **Clients:** all five; the checks that do not exist on Classic return false there and Other's Already known line covers them (requirement 2). Classic reads the hidden scan tooltip, already proven by Hide collected Other.
- **Blizzard API changes:** none new; every API is already called by `Filters.lua` and `MerchantItemSlot.lua`.
- **Other addons, plugins and skins:** Can I Mog It and Transmog Loot Helper draw their own icon overlays, which the vertex colors do not touch. ElvUI, GW2_UI and EllesmereUI restyle the slot textures; the mark must still show under each: checked at the `look` gate and in `/kevutest`'s skin runs. Already Known keeps tinting Blizzard's hidden slots, harmlessly.
- **Saved variables and migrations:** one new table in `KrowiEVU_Filters`' profile, with defaults; no migration.
- **Localization:** the option's name and description in all six locale files, translated, below the `AUTOGENTOKEN` marker.
- **Embedded libraries:** none.
- **Data snapshots:** none in this repo.
- **Player-facing text:** the option name, its description (if any) and a changelog line under `### Added`.

## Verification
- `/kevutest`: a new step after the Hide collected steps: option on, for each slot on the page, marked exactly when `IsCollected` says so (requirement 8), with the count noted; option off, no slot marked; the option put back at the end.
- In game, Retail first (`look` gate): a vendor with known and unknown items, both looks, with and without Already Known loaded, and under ElvUI. Then the full `/kevutest` on all five clients.
- `Read-GameErrors.ps1` after each run.

## Decision
Krowi, 2026-11-25, every question on the recommendation:
- Which items: everything collected, by each category's own check (requirement 2).
- Default: off, but on while Already Known is loaded, then in Already Known's color and gray-icon setting; a player's own tick or untick wins from then on.
- Switch: one checkbox in the filter menu, right after the Hide collected section.
- The look (Already Known's tint against a gray icon) is judged in game on Retail at the `look` gate.