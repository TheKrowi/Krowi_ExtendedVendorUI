# Spec: Already Known's tint missing on the vendor grid
Intent: [intent.md](intent.md). Status: accepted (Krowi, 2026-11-04)

## Requirements
1. With Already Known on, every grid slot whose item Already Known counts as known shows its tint: name frame, slot, icon and border in `AlreadyKnownSettings` r, g, b, and the icon desaturated when its monochrome setting is on. Every client both addons run on.
2. Unknown items and empty slots carry no tint, and the tint follows page, filter, search, sort and grid size changes.
3. No Blizzard function, global or frame field is replaced or written.
4. Without Already Known nothing changes.
5. With Already Known on, `/kevutest` notes which slots carry its tint.

## Root cause (code as of 2026-11-04)
- Already Known 1.104 (`AlreadyKnown.lua:454-474`, `AlreadyKnownClassic.lua:550-570`, ahakola/AlreadyKnown at 58b2d706) post-hooks `MerchantFrame_UpdateMerchantInfo` and loops `i = 1, MERCHANT_ITEMS_PER_PAGE` over `_G["MerchantItem"..i]`, tinting each for `GetMerchantItemLink((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i)`. Its check `_checkIfKnown` is file-local; only `AlreadyKnownSettings` is global.
- Up to 22.2 this addon created `MerchantItem11..N` under Blizzard's names, set `MERCHANT_ITEMS_PER_PAGE` to rows × columns (22.2 `Gui/MerchantItemsContainer.lua:75, 91`) and replaced `GetMerchantItemLink` and `GetMerchantNumItems` with filtered versions (22.2 `Gui/MerchantFrame.lua:185-210`). Already Known's loop therefore landed on the grid with the filtered items: it worked by accident of that design.
- 23.0 (2026-10-21) draws its own `KrowiEVU_MerchantItem<N>` (`Gui/MerchantItemsContainer.lua:44`), hides Blizzard's `MerchantItem1-10` and replaces nothing. Already Known now tints hidden buttons: no error and no tint. Each draw also resets the slot colors (`Gui/MerchantItemSlot.lua:124-148`), so a tint has to come after it, which is what the public `OnItemSlotUpdated(slot, index)` is for (`Gui/MerchantItemsContainer.lua:171`, documented at the top of `Api/PluginsApi.lua`).
- Reproduction: from the code; Already Known is not installed on any local client. Before any fix, a screenshot at a vendor with a known recipe on Retail and Anniversary, Already Known on, records the missing tint.

## Options considered
**A (recommended): Already Known draws on the grid itself.** Krowi asks its author in an issue on ahakola/AlreadyKnown, short and in Krowi's own words: since 23.0 the vendor items are `KrowiEVU_MerchantItem<N>`, and `KrowiEVU.PluginsApi:RegisterPlugin(name, plugin)` with `plugin:OnItemSlotUpdated(slot, index)` runs after each slot is drawn, with the vendor's real index (`nil` for an empty slot); Transmog Loot Helper works this way since 12.1.5-02. The author writes the code, as he prefers (#29). This repo changes no code now; once Already Known ships it, `/kevutest` gets its note (requirement 5) and the description's Compatibility list gets a line. One copy of Already Known's rules, always current, on all five clients. Players wait for Already Known's release, and it depends on the author (he answered #29 within two days).

**B: a built-in `Plugins/AlreadyKnown.lua` with a copy of Already Known's check** (MIT, credited), tinting in `OnItemSlotUpdated` from `AlreadyKnownSettings`. It needs both of its versions: Retail's `_checkIfKnown` with its quest, special and container item tables (`AlreadyKnown.lua:72-337`) and the Classic and Forever one with its scanning tooltip and Warlock grimoires (`AlreadyKnownClassic.lua`), about 450 lines. Fixed with this addon's next release, but the copy falls behind whenever Already Known changes its rules (decor in 2026-01, Forever in 2026-09), and then the grid and Blizzard's other windows disagree about what is known.

**C: B now, A later**, with the plugin stepping aside once Already Known registers itself. Most work, and both copies exist until the plugin is removed; only worth it if the fix must come before Already Known can ship.

Rejected: giving Already Known Blizzard's names and API back (`MerchantItemN`, `MERCHANT_ITEMS_PER_PAGE`, a replaced `GetMerchantItemLink`): that is the taint 23.0 removed. Rejected for this item: tinting from this addon's own Hide collected checks (`Filters.lua:450-766`): different rules from Already Known's and mostly Retail and Forever only; it could be offered separately as a native option.

## Areas of concern
- Taint and secret values: A and B write vertex colors and desaturation on the addon's own slots from a plugin method, which this addon calls in a `pcall` from its own draw; no Blizzard frame or global is touched. B would add `C_TooltipInfo.GetHyperlink` on Retail and an addon-owned scanning `GameTooltip` on the Classic clients, and would have to guard against secret tooltip text.
- Clients: Retail, Mists, Anniversary and Era run Already Known's two files as described; Forever runs its Classic file.
- Other addons on the slots: ElvUI's and GW2_UI's skins strip or recolor the name frame and slot textures, so with them the tint shows mainly on the icon, as it did on Blizzard's slots. CanIMogIt and Transmog Loot Helper draw overlays, not colors.
- Saved variables: none written; B reads `AlreadyKnownSettings`. Libraries: none.
- Localization: B adds a plugin name and description to `enUS.lua`, as every plugin has; A none.
- Player text: A, a Compatibility line in `_Packaging/Description.md`; B, a changelog Fixed line.

## Verification
Krowi installs Already Known on Retail and Anniversary. Before: the screenshots above. After (A: Already Known's release; B: a deploy): the tint on a known item on page 1, after a page change, a filter and a search; the `/kevutest` note lists the tinted slots; `Read-GameErrors.ps1` shows nothing new.

## Decision
Option B, a built-in plugin with a copy of Already Known's check (Krowi, 2026-11-04), over the recommended A. The copy's drift is the accepted cost: when Already Known changes its rules, the plugin follows by hand.