# Intent: An item level range for vendor gear
Author: Dubhe (CurseForge, 2026-05-09, filed by Krowi as #107), scoped by Krowi (chat, 2026-11-27: "add a min max item level range"). Source: GitHub issue #107; also #56. Status: accepted (Krowi, 2026-11-27: "Build, keep #56 open")

## Problem
The filters cannot narrow vendor gear by item level. Dubhe asked for an item level filter on the Transmog (Appearances) filter (#107; Krowi's question which of two needs they mean, posted 2026-10-24, is still unanswered). #56 (Unplayed, 2025-04-14) asks to hide items a player can no longer get, such as the Fated weapons at the Castle Nathria weapon vendors: they cost the same Abominable Anima Spherule as the normal ones (item 183893, still listed on every difficulty of Sun King's Salvation in the Adventure Guide, checked 2026-11-27), but the Fated item levels of that token no longer drop. The game marks nothing as no longer obtainable, so the addon cannot tell those rows apart today.

## Proposed outcome
A minimum and a maximum item level for weapons and armor at every vendor, under every filter, next to the other Gear options. Gear below the minimum or above the maximum is hidden. A minimum answers #107's first reading (only gear from a level up); a maximum lets a player hide the Fated rows at a Nathria weapon vendor.

## Affected users and systems
Players who use the Gear options; the filter menu's Gear section; `KrowiEVU_Filters` (two new Gear fields, off by default); the list the grid, token banner, paging and sorting work from. Clients: Retail, WoW Forever and Mists Classic show item levels; Classic Era and TBC Anniversary do not show them to players.

## Constraints
No taint: menu entries through Krowi_Menu and the number input through Krowi_PopupDialog, as the options button's custom rows and columns already do; no Blizzard frame or function touched. Off by default, so nothing changes for a player who does not set it. Items whose data has not arrived stay in the list, as with the other Gear options.

## Open questions
- Where the player sets the values: the filter menu with a number popup, the options page, or both.
- Which clients get the option.
- Whether the minimum offers the character's equipped item level as a preset.
- Whether #107 waits for Dubhe's answer, and whether #56 closes with this.
