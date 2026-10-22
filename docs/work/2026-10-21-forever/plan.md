# Plan: Extended Vendor UI on WoW Forever
Spec: [spec.md](spec.md). Status: draft

## Files that change
Krowi_Util (`Krowi_Libraries\Krowi_Util`, a branch of its own, released as 2.8):
- `Krowi_Util.lua`: `IsForever` and `IsModern` below `IsMainline`, as in the spec, and nothing else; `Krowi_Util_2` minor 4 to 5.
- `Krowi_Util.toc`: add 16001. `_Packaging/Changelog.md` (2.8: the two new flags, `IsClassicEra` still true on Forever, "Library version 4 → 5"), `_Packaging/Description.md` (the flags table, which also lacks `IsClassicEra`, `IsWrathClassic`, `IsCataClassic`), `CLAUDE.md` (flags, consumers' pins).

Krowi_Menu (`Krowi_Libraries\Krowi_Menu`, a branch of its own, released as 2.2):
- `Krowi_MenuBuilder.lua`: before the client split (line 275), keep the Retail methods as their own class; `New(config)` uses that class when `config.blizzardMenu` is true, on any client. Without the field nothing changes anywhere. MenuBuilder minor 1 to 2.
- `Krowi_Menu.toc` (the live numbers plus 16001), `_Packaging/Changelog.md`, `_Packaging/Description.md` (the new field), `CLAUDE.md`.

This addon (this branch):
- `Libs/Krowi_Util`, `Libs/Krowi_Menu`: the submodules at the two releases.
- `IsMainline` to `IsModern` where the branch is about Blizzard's interface (33 reads):
  - `Filters.lua` 121, 129, 141 (the merchant filter API), 232 Pets, 344 Sets, 383 Illusions, 418 Recipes (their APIs and Collections load on Forever).
  - `Krowi_ExtendedVendorUI.lua:15`: the EllesmereUI list-mode guard. It only reads EllesmereUI's settings, and EllesmereUI has Forever code.
  - `Gui/MerchantFrame.lua` 36, 60, 88, 109, 122.
  - `Gui/MerchantItemSlot.lua` 14, 84, 352.
  - `Gui/Paging/Paging.lua:54`, `Gui/SearchBox/SearchBox.lua:20`.
  - `Gui/FilterButton/FilterButton.lua:19`, `FilterButtonMixin.lua:4`, and `blizzardMenu = addon.Util.IsModern` in its builder config.
  - `Gui/OptionsButton/OptionsButton.lua:20`, `OptionsButtonMixin.lua` 36 and 213, and the same builder field.
  - `Gui/TokenBanner/TokenBanner.lua` 30, 45.
  - `Gui/BulkPurchase/BulkPurchaseMixin.lua` 17, 64, 76, 95, 149, 166, 227.
  - `Tests/Tests.lua:175`.
- `IsMainline` stays for Retail-only content and skins (9 reads): `Filters.lua:38` Warglaives (no Demon Hunters on Forever), `Filters.lua:466` and `Krowi_ExtendedVendorUI.lua:91` Housing, `OptionsButtonMixin.lua:145` Housing Quantity, `Plugins/EllesmereUI.lua:2`, `Tests/Tests.lua` 58 and 61 (EllesmereUI states), the comment at `Krowi_ExtendedVendorUI.lua:81`, `Plugins/ElvUI.lua:12`.
- `BulkPurchaseMixin.lua:178`: `if (addon.Util.IsForever or not addon.Util.IsClassicEra) and info.hasExtendedCost ...`.
- `Plugins/ElvUI.lua`, `Plugins/GW2_UI.lua`: do nothing on Forever (gate decision 2).
- `Gui/MerchantItemsContainer.lua`: the merchant-tab post-hook also hides `MerchantPageTurnIndicatorLeft` and `Right` where they exist (gate decision 1).
- `Tests/Tests.lua`:
  - The run header gets the Krowi_Util client flags.
  - A check compares the flags with what `WOW_PROJECT_ID` should give.
  - `CheckBlizzardHidden` also checks the page-turn indicators where they exist and the gamepad interface style is on.
- `.claude/tools/read-tests.lua`: prints the new header field.
- `_Packaging/Changelog.md`: "WoW Forever support" under the next version (23.1 unless Krowi says otherwise).
- `CLAUDE.md`: clients (five, `IsModern`), Forever's gamepad notes, the plugins on Forever.

## Order of work
1. Reproduction: recorded in the spec (2026-10-22).
2. Krowi_Util branch: flags and minor, docs. Krowi_Menu branch: the builder field and minor, docs. Both through a worktree of each library.
3. Here, the test first: point `Libs/Krowi_Util` and `Libs/Krowi_Menu` at those branches (fetch from the local library checkouts, as Krowi_Menu's CLAUDE.md describes), add the flag check to `/kevutest`, deploy to Retail and Forever. Retail stays green; Forever fails at load as recorded.
4. The addon edits above, in the order listed.
5. `Find-DeprecatedApi.ps1 -Branch forever`, `krowi:taint-reviewer` (MerchantFrame, MerchantItemSlot, Paging, the post-hook, Filters, BulkPurchase, Plugins; Classic and Retail branches), `/code-review`.
6. Deploy to all five clients; Krowi runs `/kevutest` on each, one gamepad pass on Forever, `/reload`; `Read-GameTests.ps1` and `Read-GameErrors.ps1` per client.
7. Krowi_Util 2.8 and Krowi_Menu 2.2 go through `krowi:release` on Krowi's go. Then the submodules here move to the release tags, the changelog line goes in, and the PR opens against `main`.

## Risks
- **Order of releases.** This addon's `main` must never read `IsModern` from a Krowi_Util without it. The PR carries the submodules at the released tags, and it is merged only after both library releases.
- **Shared libraries, older copies.** Another Krowi addon in the session with an older Krowi_Util or Krowi_Menu loses to this one's higher minors, and gains only the new fields. The flag check in `/kevutest` shows the values every run.
- **Builders made before the upgrade.** A Krowi_Menu builder made before a newer copy loads keeps its class (Krowi_Menu known debt). This addon makes its builders in the buttons' `OnLoad`, after every library has loaded.
- **Taint.** Hiding Blizzard's page-turn indicators is a `Hide` on a Blizzard frame from addon code, like the page buttons today. Forever's `MerchantPrevPageButton_OnClick` reads `MerchantPageTurnIndicatorLeft:IsShown()` (MF:606). The taint reviewer checks this.
- **Forever's gamepad style.** It re-shows Blizzard's page buttons when it switches back to mouse (`MerchantFrame_UninitializeGamepad`), until the next merchant update. That function is held in a closure, so `hooksecurefunc` cannot reach it.
- **This session.** It may only be able to write in this worktree. If the libraries' worktrees are out of reach, their edits go to a session or subagent started there.

## Proof
- `Read-GameErrors.ps1 -Client Forever`: the recorded load error is gone, no row and no bumped count from this addon after the `/reload`.
- `Read-GameTests.ps1 -Client <client>` for Retail, Classic, Anniversary, Era and Forever:
  - Every run completes without failed checks.
  - The flag check passes, with values Retail `IsMainline IsModern`, Mists `IsMistsClassic IsClassicWithAchievements`, Anniversary `IsBCCClassic`, Era `IsClassicEra`, Forever `IsForever IsModern IsClassicEra`.
  - The Forever gamepad pass shows no Blizzard paging control over the grid.
- The release gate (`.claude/release-gate.ps1`) reports READY for all five clients.

## Gate decisions
1. Gamepad interface style on Forever (intent, open question 2). Proposed: hide the page-turn indicators on every merchant update, and accept that switching input style with a vendor open shows Blizzard's page buttons until the next update. Moving through the grid with a gamepad is a separate item. Open: Krowi checks it in game first (2026-10-21). The switch is Options, Gameplay, Gamepad, first checkbox (`Blizzard_SettingsDefinitions_Shared\Gamepad.lua:276-290`, CVar `InputDeviceInterfaceStyle`, default off on PC).
2. Skin plugins on Forever. Decided by Krowi, 2026-10-21: ElvUI and GW2_UI do nothing there, so a Forever player with either sees an unskinned grid. Skins on Forever become their own item.
3. The plan as a whole: Krowi, 2026-10-21, "draft, end of day". No library or addon code before Krowi's go.