# Intent: CurseForge feedback of March to October 2026
Author: players on CurseForge (project 872787), collected by Krowi (maintainer). Source: GitHub issues #100 to #110, each quoting one CurseForge comment. Status: accepted

## Problem
The CurseForge comments since March hold two regressions of 23.0, four older bugs and five requests. Each is a GitHub issue now, with its analysis as the first comment.

| Issue | Kind | What the player sees |
|---|---|---|
| #100 | bug, 23.0 | The token banner shows only gold, or at the Neighborhood Tricky Treat Trader a "coin" instead of the candy Blizzard's window shows (Retail). |
| #101 | bug, 23.0 | Transmog Loot Helper's collected overlay is gone from vendor items (Retail, Forever). |
| #102 | bug | Hide collected, Housing hides decor in storage but not decor that is placed (Retail). |
| #103 | request | Hide collected, Recipes should also count recipes the player's other characters know (Retail, Forever). |
| #104 | request | The gold total in the token banner cannot be turned off. |
| #105 | request | 22 strings have no zhCN translation, so Chinese players see English there. |
| #106 | request | Classic gear vendors have pages of gear; filter it down (secondary stats asked, see also #62). |
| #107 | request | An item level filter for Appearances; what the player needs is unclear. |
| #108 | request | At recipe vendors the token banner lists every profession's Artisan's Moxie, mostly at 0. |
| #109 | bug | Kirasztia (Emerald Dream) misses a legs and a chest piece with the addon on (reported on 22.0). |
| #110 | bug | With EllesmereUI, 10x4 by columns, slots are empty on the first vendor open (reported on 22.2). |

## Proposed outcome
- The token banner shows exactly the costs of the items in the list, on every vendor, and never a token from an earlier vendor.
- Transmog Loot Helper's overlay shows on the addon's slots and follows every page, filter, search and grid change.
- Placed decor counts as collected.
- Players can opt into hiding recipes their other characters know, hiding the gold total, hiding currencies they have none of, and a gear block (only usable items, no sub-optimal armor, a minimum quality).
- zhCN has all strings.
- #109 and #110 are reproduced or ruled out in game, and fixed where they reproduce.
- #107 waits for the player's answer.

## Affected users and systems
- Clients: Retail for #100 to #104, #108 to #110; WoW Forever for #101, #103; every client for #104 to #106, #108 and the token banner fix.
- Windows: the vendor tab's grid, token banner, filter menu and options menu.
- Saved variables: new profile keys in `KrowiEVU_Options.TokenBanner` and `KrowiEVU_Filters` (gear block, recipes), and an account-wide record of known recipes per character in `KrowiEVU_Filters`.
- Other addons: Transmog Loot Helper (its PR #97 and its own KEVU integration since v12.1.5-02), EllesmereUI, Can I Mog It.
- Localization: new strings in enUS, all of them and the 22 missing ones in zhCN; CurseForge's localization project.

## Constraints
- The taint rules of `CLAUDE.md`: no Blizzard function, global or frame field written; the purchase path unchanged.
- No new event that refreshes Blizzard's merchant frame; the server filter keeps Blizzard's own ids.
- Every option is off or keeps today's behaviour by default.
- Classic clients keep working where a feature is Retail only.

## Open questions
- #100: which of the two defects (stale tokens, a frozen update) the players hit; answered by the new `/kevutest` token banner check at the trader.
- #109: whether the server drops items for the addon's own filter ids; answered by the new server list check at Kirasztia.
- #110: whether 23.0 already fixed it; answered by the new first-draw step.
- #107: the player's need (asked on the issue).
