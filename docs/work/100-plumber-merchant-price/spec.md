# Spec: Plumber's Merchant Price hides the token banner
Intent: [intent.md](intent.md). Status: accepted

## Requirements
1. When Plumber's Merchant Price hides the token banner, the first vendor window of the session shows a notice window and prints a chat line. Both say that Plumber's Merchant Price hides the banner and that turning it off in Plumber's settings brings it back.
2. "Hides the banner" means all three of: Plumber is loaded, `PlumberDB.MerchantPrice` is true, and `MerchantMoneyInset`'s parent is not `MerchantFrame`. Without Plumber, with Merchant Price off, or with a later Plumber that leaves the bar in place, nothing shows.
3. Once a session: after the notice showed, no later vendor shows it again. A vendor opened while the banner is not hidden shows nothing, and the next vendor checks again.
4. With WoW Forever's gamepad interface style on (switched on after load), only the chat line is printed.
5. The token banner and its code do not change.
6. `/kevutest` checks that the banner is visible on the merchant tab. When Plumber's Merchant Price hides it, the check records that and passes only if the notice was shown this session.
7. On Retail and WoW Forever, the Plugins options page has a Plumber entry: Loaded, and the same explanation.
8. The notice and the Plugins entry read in Chinese on zhCN clients; every other locale shows English.

## Root cause
Plumber 1.9.6 d, `Modules/MerchantPrice.lua` (identical to [GitHub `2f7186c`](https://github.com/Peterodox/Plumber/blob/2f7186cc7e2914ed73809d0486ee250b5231a236/Modules/MerchantPrice.lua)):
- `InvisibleContainer:HideObjects` moves `MerchantMoneyInset`, `MerchantMoneyBg`, `MerchantExtraCurrencyInset`, `MerchantExtraCurrencyBg` and `MerchantMoneyFrame` into a hidden frame (L79-L100), at module enable (L656). The token banner is a child of `MerchantMoneyInset` (`Gui/TokenBanner/TokenBanner.lua:52`), so it is hidden too.
- Plumber's own coin box (`FULLSCREEN` strata, bottom right of `MerchantFrame`, L496-L500 and `Modules/Shared/SharedWidgets.lua` `SetFrameOwner`) collects the costs from the shown `MerchantItem1..MERCHANT_ITEMS_PER_PAGE` (L397-L402). Since 23.0 the merchant tab shows `KrowiEVU_MerchantItem<N>` (`Gui/MerchantItemsContainer.lua:44`) and Blizzard's `MerchantItem1-10` are hidden, so no cost is found and the box shows only the money frame (L473-L477).
- 22.2 named its slots `MerchantItem<N>` and set `MERCHANT_ITEMS_PER_PAGE` (22.2 `Gui/MerchantItemsContainer.lua:75`, `:91`), so Plumber's box listed the costs of the page. That is why 22.2 "worked", and why its per-item prices were sometimes wrong (Plumber #533).
- The module loads only on Retail and WoW Forever (Plumber `Plumber.toc:62`, `[AllowLoadGameType standard, camelot]`) and is off by default (`Initialization.lua:312`). Its checkbox applies at once (`Modules/ControlCenter/SettingsPanel.lua:388`): turning it off moves the frames back (`RestoreObjects`, L123-L147) without a reload.
- Why `/kevutest` never saw it: Plumber is disabled on every Retail character of Krowi's account (`AddOns.txt`), though its saved variable has Merchant Price on. The test lists Plumber in its run header when it is loaded, and no run did.

**Reproduction (before the build):** enable Plumber on one Retail character, `/reload`, open a vendor that charges more than gold, and run `/kevutest`.

**Recorded 2026-10-25,** on 24.1 plus only the new test check (`5058751`). Retail 12.1.5 (70575), Plumber 1.9.6 d, vendor Wah'du. Every one of the list's 22 items costs Mythical Soul Fragment (×66 in all).
- `/kevutest` run of 09:53:53 (49 passed, 8 failed, 2 skipped): "FAIL token banner not visible" on all 8 merchant-tab steps, and no other failure.
- The cost check still passed on every step: the banner drew the right token, only invisibly.
- BugGrabber: no error from the addon.
- Screenshot `WoWScrnShot_102526_095354.jpg`: the bottom bar shows only Plumber's "1,768,164g 32s 89c", with no token banner and no Mythical Soul Fragment.

## Design
- `Krowi_ExtendedVendorUI.lua`:
  - The notice window moves out of the not-loaded branch into `ShowNotice(text)`, defined above it and kept as `addon.ShowNotice`. The text and height are set at each show, and the frame is renamed `KrowiEVU_Notice` (nothing else references the name). `addon.ShowNotLoadedNotice` uses it, unchanged in behaviour.
  - `IsForeverGamepadStyleOn` is also kept as `addon.IsForeverGamepadStyleOn`, for the plugin.
- `Plugins/Plumber.lua` (new, in `Plugins/Files.xml`), like the other plugins:
  - It returns at its top unless `addon.Util.IsModern`, because Merchant Price exists only on Retail and Forever.
  - It registers as `Plumber`. `InjectOptions` adds the Plugins page entry (`AddPluginTable`, Loaded from `C_AddOns.IsAddOnLoaded('Plumber')`).
  - `plumber:IsHidingTokenBanner()` checks requirement 2: `C_AddOns.IsAddOnLoaded('Plumber')`, `type(PlumberDB) == 'table' and PlumberDB.MerchantPrice == true`, `MerchantMoneyInset:GetParent() ~= MerchantFrame`.
  - `Load` (boot, so never while the addon steps aside) registers `MERCHANT_SHOW` through the plugin event API (`KrowiEVU.PluginsApi:RegisterEvent`). `OnEvent` returns once `NoticeShown` is set (once a session). Otherwise it runs the check and keeps the result as `HidingAtVendorOpen`. When it is true, it sets `NoticeShown`, prints the text, and shows the window unless `addon.IsForeverGamepadStyleOn()`.
  - The notice window closes with its own handlers on both buttons. The template's X button would call `HideUIPanel`, which refuses in combat. The Okay button uses `UIPanelButtonNoTooltipTemplate`, whose `OnLeave` doesn't hide the shared tooltip. Both come from the taint review of 2026-10-25.
  - Plumber moves the frames at its module enable (login), so the check is valid at `MERCHANT_SHOW`.
- `Localization/enUS.lua`: three strings, appended below the marker.
  - `Plugin_Plumber_Name` = "Plumber".
  - `Plugin_Plumber_Desc`, for the Plugins page: what Merchant Price does to the banner, that a notice says so once a session, and how to turn it off. "There are no options."
  - `Plugin_Plumber_MerchantPriceHidesTokenBanner`, for both the window and the chat line. It names the addon, as the Forever line does:
    > Plumber's Merchant Price hides the token banner of Extended Vendor UI, so the vendor window shows only your gold. To see the costs of the listed items again, turn off Merchant Price in Plumber's settings.
- `Localization/zhCN.lua`: drafts of the three, put on CurseForge with `krowi:localization` and imported, so the file stays the CurseForge export (as in 24.1).
- `Tests/Tests.lua`, `CheckTokenBanner`:
  - It checks `KrowiEVU_TokenBanner:IsVisible()`.
  - When the banner is not visible and `KrowiEVU.PluginsApi.Plugins.Plumber:IsHidingTokenBanner()` is true, it records an INFO line on each step. Once a run, it also records a PASS or FAIL on `NoticeShown`. That check is only an INFO when `HidingAtVendorOpen` is false, which means Merchant Price came on after the vendor opened and the notice is due at the next vendor (code review of 2026-10-25).
  - Otherwise, a hidden banner is a FAIL. The existing cost check stays.
- `_Packaging/Changelog.md`: a 24.2 entry, under Added: "A notice when Plumber's Merchant Price hides the token banner, with how to get it back (Retail, WoW Forever)".

## Options considered
1. **Notice window and chat line once a session (Krowi, 2026-10-25).** The player sees why the banner is gone and how to get it back, without the addon changing its banner.
2. Chat line only, as Forever's reload line. Easy to miss in a busy chat. Not chosen.
3. Move the banner out of `MerchantMoneyInset` so Plumber cannot hide it. Plumber's gold-only box would still sit on top of it in the same corner, and Krowi decided the addon does not work around Plumber. Not chosen.
4. Hide or feed Plumber's box from this addon. That touches another addon's private frames. Not chosen.
5. **Also an entry for Plumber on the Plugins options page** with the same explanation (Loaded, plus the description). It keeps the explanation findable after the notice is closed. Chosen with 1 (Krowi, 2026-10-25).
6. A Plumber line in the description's compatibility list. Not chosen (Krowi, 2026-10-25): the in-game notice and the Plugins entry say it.

## Areas of concern
- **Taint and secret values:** reads only: `MerchantMoneyInset:GetParent()` is a method call on a Blizzard frame, and `PlumberDB` is another addon's saved variable. The window and the event frame are the addon's own, created like the existing notice. Nothing Blizzard owns is written. No secret-value API. `krowi:taint-reviewer` runs on the diff, since the code runs at every vendor open.
- **Clients:** the check is behavioural, so it can only fire where Merchant Price runs (Retail, Forever). On Mists, Anniversary and Era, Plumber's module never loads and `MerchantMoneyInset` keeps its parent, so the check is false. Forever's gamepad style gets the chat line only. On Forever, when the addon steps aside (gamepad style on at load), this code is never reached (it sits after the not-loaded `return`).
- **Blizzard API:** `C_AddOns.IsAddOnLoaded` is already used on every client. `MerchantMoneyInset` exists on every client and is already re-anchored by `Gui/MerchantFrame.lua`. Nothing is deprecated.
- **Other addons:** Plumber 1.9.6 d. If Plumber fixes #533 by leaving the bar alone, the parent check stops the notice by itself. EllesmereUI only restyles `MerchantMoneyInset` (`EllesmereUIBlizzardSkin_WindowPacks.lua:7927-7933`) and ElvUI's skin does not move it, so they do not trigger the check.
- **Saved variables:** none. The notice comes back each session while Merchant Price hides the banner, as the other notices do.
- **Localization:** three new enUS strings, with zhCN drafts that are not by a native speaker. All of them go onto CurseForge's localization page. The other locales fall back to enUS.
- **Embedded libraries:** none.
- **Player-facing text:** the notice and chat line, the Plugins page entry, and the changelog line. `_Packaging/Description.md` does not change.

## Verification
- **Permanent test:** `/kevutest`'s banner visibility check (requirement 6).
- **Before the build:** the reproduction above, with a screenshot.
- **Retail, after the build:**
  - With Plumber disabled: `/kevutest` passes with the banner visible, and no notice shows.
  - With Plumber enabled (Merchant Price on): at the first vendor, the notice window and the chat line show once. `/kevutest` records the banner as hidden by Plumber, and the notice check passes. A second vendor shows no notice.
  - With Merchant Price turned off in Plumber's settings: the banner is back without a reload. After a `/reload`, no notice shows.
- **Mists, Anniversary, Era:** one `/kevutest` pass each, with the banner visible and no notice.
- **Forever:** one run if its realm is up.
- `Read-GameErrors.ps1` after each, `krowi:taint-reviewer` and `/code-review` on the diff.

## Decision
Krowi, 2026-10-25:
- The addon does not change its banner or work around Plumber.
- A notice window and a chat line at the first vendor of the session while Plumber's Merchant Price hides the banner, with the chat line only in Forever's gamepad style (option 1).
- Also a Plumber entry on the Plugins options page (option 5).
- A zhCN draft, with the strings on CurseForge.
- No change to the description.
- The findings and the player workaround are posted on Plumber [#533](https://github.com/Peterodox/Plumber/issues/533#issuecomment-6395438882).
