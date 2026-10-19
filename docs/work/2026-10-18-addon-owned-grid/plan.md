# Plan: Filter the vendor without replacing Blizzard's merchant API
Spec: [spec.md](spec.md). Status: accepted

Non-routine (hooks on Blizzard frames, the taint-sensitive files in `CLAUDE.md`): approved by Krowi on 2026-10-19.

Skin plugins are built only for the clients the skinned addon's current release supports (Krowi, 2026-10-18): ElvUI on Retail, Mists, Anniversary and Era; GW2_UI on all four (12.1.0's `## Interface` lists 120105, 50504, 20506, 11509); EllesmereUI on Retail only; CanIMogIt wherever its functions exist. Plumber is outside this plan.

## Files that change
Phase 1 (branch `refactor/2026-10-18-addon-owned-grid`):
- `Filters.lua`: the Classic `GetMerchantFilter`/`SetMerchantFilter` globals go; `GetFilter`, `SetFilter` (on Retail also the real `SetMerchantFilter`, same value as 22.2; writes `LastFilter`), `SyncFilter`, `RegisterListener`, `BuildList` (the loop from `Gui/MerchantFrame.lua:205-218`).
- `Krowi_ExtendedVendorUI.lua`: `:45-51` (`MerchantFrame_SetFilter`) goes.
- `Gui/MerchantItemSlot.lua` (new): `GetItemInfo(index)` (Retail `C_MerchantFrame.GetItemInfo`, Classic a table from `GetMerchantItemInfo`'s full return list); `Draw(slot, index)` mirroring live `MerchantFrame.lua:275-403` and classic TBC `:196-321`; the alternate-currency copy; Retail quality with an addon frame for `GET_ITEM_INFO_RECEIVED`.
- `Gui/Paging/Paging.xml`, `Gui/Paging/Paging.lua` (new): page buttons copied from Blizzard's XML without its `OnClick`, the page text, Blizzard's paging rules, mouse wheel, closing the split window on page change.
- `Gui/MerchantItemsContainer.lua` (rewritten): slots `KrowiEVU_MerchantItem<N>` from Blizzard's `MerchantItemTemplate` (the spec's own template is not needed) with an own `OnClick`; `Update()`; the post-hooks; `MERCHANT_SHOW`; `HideAll()`.
- `Gui/MerchantFrame.lua`: `:132-268` and `:49-54` go; the merchant-info hook body becomes `UpdateMerchantInfoLayout()`; `SetMerchantFrameSize` reads the addon's page text.
- `Gui/Files.xml`: the new files, before the container.
- `Gui/FilterButton/FilterButtonMixin.lua`, `Gui/SearchBox/SearchBoxMixin.lua`: the filter API and listeners instead of `MerchantFrame_SetFilter` and its hooks.
- `Gui/OptionsButton/OptionsButtonMixin.lua:9-13`: redraws the grid instead of calling `MerchantFrame_Update`.
- `Gui/TokenBanner/TokenBanner.lua`: real indices; `RequestUpdate()`.
- `Gui/BulkPurchase/BulkPurchaseMixin.lua:13-29`: `MerchantItemSlot.GetItemInfo`.
- `Api/PluginsApi.lua`: `CallPlugins` (each call in `pcall`, errors to `geterrorhandler()`), documentation of `OnItemSlotCreated`, `OnItemSlotUpdated`, `OnItemSlotsUpdated`.
- `Plugins/CanIMogIt.lua`, `Plugins/ElvUI.lua`: as in the spec; ElvUI's `PointXY` no-ops are replaced by a buyback re-layout hook added on the first window open, after ElvUI's own.
- `CLAUDE.md`: Architecture, Taint-sensitive areas, Known debt. `_Packaging/Changelog.md`: a `## 22.3` entry (Krowi sets the number).
- Not changed: `.vscode/settings.json`, which has an uncommitted change in the main checkout.

Phase 2 (branch `feat/2026-10-18-merchant-skin-plugins`, from the phase 1 branch): `Plugins/GW2_UI.lua`, `Plugins/EllesmereUI.lua`, `Plugins/Files.xml`, plugin strings in `Localization/enUS.lua`, a changelog line. The four new strings (`Plugin_GW2UI_Name`, `_Desc`, `Plugin_EllesmereUI_Name`, `_Desc`) also go onto the CurseForge localization page (Krowi, 2026-10-19): after phase 2 is merged into `main`, through the addon manager's Export Localization for Base Namespace, enUS (it uploads the whole `enUS.lua` and deletes phrases missing from it), a step for Krowi since the addon manager is not driven outside the release skill.

## Order of work
1. Baseline: 22.2 (this worktree before any code change) deployed to Retail, Classic, Anniversary and Era on 2026-10-19; Krowi takes the steps under Proof, baseline; results go into `spec.md`, Reproduction. Code is written meanwhile and deployed only after the baseline is recorded (approved with this plan).
2. Phase 1 code in the order of the file list; the syntax hook on every edit.
3. Phase 1 static checks, `krowi:taint-reviewer`, in-game comparison on the four clients, PR into `main`.
4. Phase 2 code, checks, PR.
5. No release before both are merged and Plumber is settled.

## Where it stands (2026-10-19, end of session)
- Phase 1 and 2 are built and checked in game on Retail (Mirvedon), Mists (Bario Matalli) and Era against 22.2; Anniversary not checked (Krowi's choice). All four clients run the phase 2 build as it was before the last item below (commit `1b8b87f` on the phase 2 branch).
- Final reviews done: `krowi:taint-reviewer` on phase 1, phase 2 and the ElvUI v16 change (no high or medium findings); `/code-review` on the whole diff found six points, being fixed:
  1. Done, not yet deployed: `merchantItemsContainer:RequestUpdate()` queues addon-requested updates (filter change, `MERCHANT_SHOW`, item data) for the next frame and drops them when a Blizzard refresh updates first; the page is clamped to the last page when the list gets shorter (22.2 and Blizzard show an empty "Page 3 of 2"); the container calls a new plugin method `OnFirstDraw()` once, right before the first draw.
  2. To do: document `OnFirstDraw` in `Api/PluginsApi.lua`; move the ElvUI plugin's `OnFirstShow` into `OnFirstDraw`, drop its Retail `SkinModernItemSlot` (fully repeated by `ElvSkinItemSlot`) and use `isModern` instead of ElvUI's `engine.Modern` (missing before ElvUI v16).
  3. To do: CanIMogIt plugin also repaints the shown slots on CanIMogIt's own `OptionUpdate` and `ResetCache` messages, through `CanIMogIt:RegisterMessage` (CanIMogIt has its own message list, `core.lua:45-59`).
  4. To do on the phase 2 branch (rebase it first): GW2_UI and EllesmereUI plugins use `OnFirstDraw` instead of their `OnShow` hooks and forced updates; `Plugins/EllesmereUI.lua` `SkinTile` merges into `slotData[button]` instead of replacing it (it lost the item-level text created before the skin, which then stayed on screen).
  5. Then: spec requirement 12 and the changelog get the page clamp; syntax check, a short taint review of the changes, deploy Retail and Mists, a quick look by Krowi, set the work files to done, and ask Krowi before pushing the two branches and opening the PRs.

## Risks
- The drawing copy differs from Blizzard's: the baseline comparison per client catches it; each copy names its source lines.
- ElvUI's steps on the addon's page widgets must give today's combined anchors: screenshot comparison with ElvUI on (Mists, Era).
- ElvUI and GW2_UI initialise at `PLAYER_LOGIN`, after the addon's `ADDON_LOADED`: work that needs them waits for the first merchant window open.
- Krowi_Vendorer calls `MerchantFrame_UpdateMerchantInfo` on its own tabs: drawing runs only when `selectedTab == 1`, and `HideAll()` keeps hiding Blizzard's `MerchantItem1-12`.
- A redraw from a plugin error: `CallPlugins` isolates each call.

## Proof
Baseline (22.2), per client, at one vendor with more than one page and extended-cost items (Retail also: an item of 150 gold or more and a limited-currency item):
- Screenshots of the merchant tab at 5x2 with All, one Only show filter, Custom, a search and a Hide collected box; at 5x5 with All; the buyback tab.
- Reproductions: Auctionator's tooltip price under a filter (Retail); the token banner gold total under a filter (Classic); a shift-click with chat open and Bulk Purchase on; a CanIMogIt icon after a filter change (Retail).
- With CanIMogIt (Retail), ElvUI (Mists, Era), GW2_UI (Retail, and Classic once a current GW2_UI is installed there), EllesmereUI's skin and item levels (Retail).

After:
- The requirement 13 searches outside `Libs/` find nothing; `Find-DeprecatedApi.ps1` for the four branches finds nothing new; `krowi:taint-reviewer` and `/code-review` findings fixed or listed in the PR.
- In game, per client: requirements 1-12 and 15-17 (18-20 for phase 2) against the baseline; each confirmation reached and cancelled; Bulk Purchase on a cheap item; Krowi_Vendorer's tabs; `Read-GameErrors.ps1` after each `/reload` with no new Extended Vendor UI row.