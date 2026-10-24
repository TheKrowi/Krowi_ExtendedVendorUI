# Spec: CurseForge feedback of March to October 2026
Intent: [intent.md](intent.md). Status: accepted

Each issue's analysis, with sources, is its first comment on GitHub; this file keeps the requirements, design and checks.

## #100 Token banner shows the wrong costs

**Requirements**
1. The banner shows one token per cost of the items in the list (gold, each currency, each item) and nothing else.
2. A token whose data cannot be read is not shown, leaves no gap, and never keeps text or an icon from an earlier use.
3. An error while drawing the banner does not stop its later updates.

**Root cause (to confirm in game).** `KrowiEVU_TokenMixin:Draw` returns early on missing data without hiding the token (`TokenMixin.lua:42-45`), so a reused token keeps an earlier vendor's text and icon. And the update runs through Krowi_Util's `DelayFunction` (`TokenBanner.lua:98`), whose slot is freed only after the callback returns, so one error freezes the banner for the session; `DrawToken` compares a `GetLeft()` that can be nil (`TokenBanner.lua:43`, logged on Era). Reproduction: the round 1 token banner check at the Neighborhood Tricky Treat Trader.

**Design.** `SetGold`, `SetCurrency` and `SetItem` clear the token's earlier data and return whether it can be drawn; the banner advances to the next token only for a drawable one. A currency's amount falls back from `GetCurrencyInfoFromLink` to its id where the client has `GetCurrencyIDFromLink`. `DrawToken` skips the wrap when a position is unknown. The banner keeps its own pending flag, cleared before the update runs, instead of `DelayFunction`, and skips the update while the vendor window is hidden. If round 1 shows another cause, this section is updated before the fix.

## #101 Transmog Loot Helper overlay

**Requirements.** 1. With TLH v12.1.5-02 or later, every shown slot with an item gets TLH's overlay after every draw. 2. The plugin's name and description show on the Plugins options page. 3. TLH never retries every frame because of this addon's slots. TLH's integration retries while the first slot's `hasItem` is nil (from login until the first vendor, and whenever a vendor opens with an empty list; taint review of 2026-10-24), so the addon's slots are created with `hasItem = false` and an empty slot sets `false` where Blizzard sets nil; Blizzard only tests it for truth on every client. The plugin also skips the call for an empty list. Reported to TLH's author on #97.

**Design.** Merge #97's commit (Slackluster, `3aa6195d78`) unchanged, then: the two strings in enUS, single quotes, and skip `UpdateOverlay` when the list is empty.

## #102 Placed decor counts as collected

**Requirements.** 1. Hide collected, Housing hides decor owned at least the chosen number of times, counting storage, placed and not yet redeemed. 2. No error when the `loadDeprecationFallbacks` CVar is off.

**Root cause.** `filters.IsHousingCollected` reads `entryInfo.quantity` (`Filters.lua:485`), which 12.0.5 replaced; the deprecation shim fills it with `totalNumStored` only (live `Deprecated_12_0_5.lua:85`).

**Design.** Compare `totalNumStored + totalNumPlaced + remainingRedeemable` (live `HousingCatalogUIDocumentation.lua:555-557`), and pass the item id alone to `GetCatalogEntryInfoByItem`.

## #103 Recipes other characters know (Retail, Forever)

**Requirements.** 1. A new Hide collected checkbox hides recipes another character on the account is recorded to know. 2. Each character records, per recipe item, whether it knows it, whenever a vendor shows that item, whatever the checkboxes. 3. Off by default.

**Design.** `KrowiEVU_Filters`'s AceDB `global.KnownRecipes["Name-Realm"][itemId] = true` (account-wide, untouched by profile reset or copy). `filters.IsRecipeCollected` records its tooltip result when the item's data is cached (true sets, false clears, so a dropped profession clears on the next visit); `BuildList` runs it once per recipe item per vendor visit (the set is cleared on `MERCHANT_CLOSED`) so recording does not depend on the checkboxes. Profile key `HideCollected.RecipesOtherCharacters`; the three recipe branches of `Validate`, `ValidateRecipesOnly` and `ValidateCustom` hide a recipe when (Recipes and this character knows it) or (the new key and another character is recorded to know it). Limits for the reply: only characters of this WoW account folder, learned from vendor visits, and another character's data arrives after it logs out or reloads.

## #104 Gold total

**Requirements.** A Gold total checkbox in the options button's Token Banner menu, on by default; off, the gold token shows only the gold the player has, whatever Token Format says.

**Design.** `TokenBanner.GoldTotal = true` in `Options/Defaults.lua`; `KrowiEVU_TokenMixin:Draw` uses `Have` for the gold token when it is off.

## #105 zhCN

**Requirements.** `zhCN.lua` has every string of `enUS.lua`, also on CurseForge.

**Design.** Draft the 22 missing translations and those of the strings this batch adds, put them on CurseForge as zhCN through `krowi:localization` and import them, so the file stays the CurseForge export. A native speaker is asked on #105 to check them.

## #106 Gear block (every client)

**Requirements.** A Gear section in the filter menu: Only usable items, Hide sub-optimal armor, Minimum quality (Off, Uncommon, Rare, Epic). They apply to weapons and armor under every filter, all off by default; an item whose data is not loaded yet is shown.

**Design.** Profile keys `Gear.UsableOnly`, `Gear.HideSubOptimalArmor`, `Gear.MinQuality` (0 is off) in `Filters.lua`'s defaults. `filters:BuildList` also asks `filters:ValidateGear(index, itemId)`:
- usable from the vendor's `isUsable` (`merchantItemSlot.GetItemInfo`);
- sub-optimal for cloth, leather and mail chest-to-feet pieces (not cloaks) below the best armor proficiency the character knows (`C_SpellBook.IsSpellKnown` of Plate Mail 750, Mail 8737, Leather 9077); no known proficiency turns the check off;
- quality from `C_Item.GetItemQualityByID`.

The quality submenu uses `CreateCustomRadio`, the checkboxes the filter button's own checkbox. Quality names come from Blizzard's `ITEM_QUALITYn_DESC`.

## #107 Item level for Appearances

Waits for the player's answer on #107. No code in this batch.

## #108 Hide currencies you have none of

**Requirements.** A Hide currencies you have none of checkbox in the Token Banner menu, off by default; on, a currency or item cost the player has 0 of gets no token.

**Design.** `TokenBanner.HideNone = false`; the token's `Set*` records the amount owned and the banner skips it when the option is on and the amount is 0.

## #109 Kirasztia

**Requirement.** Under any of the addon's filters the server sends at least the items it sends for All.

**Root cause (to confirm in game).** On Retail and Forever `filters:SetFilter` passes the addon's own ids (101 to 201) to the real `SetMerchantFilter` (`Filters.lua:127-131`); what the server does with them is undocumented. Reproduction: the round 1 server list check at Kirasztia.

**Design if reproduced.** Pass `LE_LOOT_FILTER_ALL` to the server for the addon's own ids; the addon's `Validate` already filters on the client.

## #110 EllesmereUI first draw

**Requirement.** The first draw after a reload, with EllesmereUI on, 10x4 by columns, has every slot filled and skinned.

**Design.** Round 1's first step checks it; a fix is designed only if it fails.

## Options considered
Per issue in its GitHub analysis. Not chosen: a Show gold checkbox that removes the token (#104; the window would show no gold at all), a recipe filter by profession or a kept Moxie list (#108), scanning profession windows (#103; recipe items do not map reliably to spells), stat checkboxes or a Pawn plugin (#106), our own TLH plugin (#101).

## Areas of concern
- **Taint and secret values:** no Blizzard function, global, constant or frame field is written. #109's change keeps calling the real `SetMerchantFilter` with a Blizzard id, as Blizzard's own dropdown does. The token banner and filters run in the same paths as today, which `CLAUDE.md` lists as taint-sensitive, so `krowi:taint-reviewer` runs on the diff. No secret-value API is added: `UnitName('player')` and `GetRealmName()` for the recipe record are the player's own.
- **Clients:** #100, #104, #106, #108 on every client (the Classic branches of `GetItemInfo` and costs); #102 Retail only (`IsMainline`); #103 Retail and Forever (`IsModern`); #101 is Retail and Forever because TLH is.
- **Blizzard API:** `quantity` (removed in 12.0.5) is no longer read. `C_SpellBook.IsSpellKnown`, `C_Item.GetItemQualityByID` and `C_Item.IsItemDataCachedByID` are in every client's generated docs; `C_CurrencyInfo.GetCurrencyIDFromLink` only on Retail and Forever, so it is guarded.
- **Other addons:** TLH (#101); Can I Mog It, ElvUI, GW2_UI and EllesmereUI see fewer or other items with the gear block on, through the same draw path as any filter.
- **Saved variables:** new keys with AceDB defaults, no migration; one new `global` table in `KrowiEVU_Filters`.
- **Localization:** new enUS strings below the marker; zhCN for all; the other locales fall back to enUS.
- **Libraries:** none changed (`DelayFunction` stays in Krowi_Util, unused by the banner).
- **Player-facing text:** changelog lines under 24.1.

## Verification
Permanent tests in `/kevutest` (`Tests/Tests.lua`), round 1 before the fixes, round 2 after:
- Token banner on every step: the shown tokens against the costs of the list, nothing stale, every currency of Blizzard's row while the whole vendor is listed (#100). Round 2 adds a step with Gold total off and Hide currencies you have none of on (#104, #108).
- Server list: under the addon's filters the server sends at least what it sends for All (#109).
- Housing under All: decor owned in any form is hidden while Hide collected, Housing is on (#102).
- TLH's overlay on every shown slot with an item (#101), like Can I Mog It's.
- A first step on the window as it opened (#110).
- Round 2 adds a gear step (each option on, no shown item breaks it) and notes the recipe record (#103, #106).

Runs on Retail at the Neighborhood Tricky Treat Trader, Kirasztia, a decor vendor, Lyrendal, and with EllesmereUI at 10x4 by columns; a pass on Mists Classic, Anniversary, Era and Forever at any vendor. `Read-GameErrors.ps1` after each round. `krowi:taint-reviewer` and `/code-review` on the diff.

## Decision
Krowi, 2026-10-24: one branch and one PR for the batch. #101 merge #97 into the batch; #103 learn from vendor visits; #104 Gold total checkbox; #105 Claude drafts the translations; #106 Gear block; #107 ask the player first; #108 Hide currencies you have none of. #100, #102, #109 and #110: fix where reproduced, no options.
