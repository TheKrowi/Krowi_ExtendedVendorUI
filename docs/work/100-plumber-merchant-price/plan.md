# Plan: Plumber's Merchant Price hides the token banner
Spec: [spec.md](spec.md). Status: draft

## Files that change
- `Tests/Tests.lua`: `CheckTokenBanner` checks that the banner is visible, with the Plumber case (requirement 6).
- `Krowi_ExtendedVendorUI.lua`: the notice window becomes `ShowNotice(text)` above the not-loaded branch, kept as `addon.ShowNotice`. The frame is renamed `KrowiEVU_Notice`, and its text and height are set at each show. `addon.IsForeverGamepadStyleOn` is exported.
- `Plugins/Plumber.lua` (new): returns unless `IsModern`. It has the Plugins page entry, `IsHidingTokenBanner`, and a `MERCHANT_SHOW` frame made in `Load` that shows the notice once a session.
- `Plugins/Files.xml`: the new file, after `TransmogLootHelper.lua`.
- `Localization/enUS.lua`: `Plugin_Plumber_Desc`, `Plugin_Plumber_MerchantPriceHidesTokenBanner` and `Plugin_Plumber_Name`, appended at the end (below the marker).
- `Localization/zhCN.lua`: the three, from CurseForge after the upload (`krowi:localization`).
- `_Packaging/Changelog.md`: `## 24.2` with the Added line.
- `CLAUDE.md`: Plumber in the built-in plugins and the Merchant Price limit (write-back).

## Where the build departed
- **Taint review** (no taint path): the notice window's X and Okay buttons got the addon's own handlers. This fixes the EllesmereUI and Forever notices too.
- **Code review:**
  - The plugin uses the plugin event API instead of a private frame.
  - `/kevutest` checks the notice once a run, and not at a vendor that was open before Merchant Price came on.
  - The zhCN description says "after each login or UI reload".
- **Code review findings left as they are:**
  - Escape does not close the notice. It is the addon's own window, and making Escape close it would mean writing to Blizzard's `UISpecialFrames` or keyboard handling that is protected in combat.
  - Three similar once-a-session helpers stay separate.
  - Without Plumber, every vendor open still runs one `IsAddOnLoaded` check.

## Order of work
1. **Test first.** Add the visibility check to `Tests/Tests.lua` and deploy it alone to Retail.
2. **Reproduction (Krowi, in game).** Enable Plumber on one Retail character (its Merchant Price is already on), `/reload`, open a currency vendor and run `/kevutest`. Expected: the banner check FAILs with "not visible", no notice shows, and the screenshot shows Plumber's box with only gold. Record the run and the screenshot in the spec.
3. **Build:** the notice refactor in `Krowi_ExtendedVendorUI.lua`, then `Plugins/Plumber.lua`, `Plugins/Files.xml` and the enUS strings.
4. **Localization:** draft the zhCN text. With `krowi:localization`: export the three enUS strings and the zhCN drafts to CurseForge, then import, so `zhCN.lua` stays the export.
5. Add the changelog line.
6. **Checks:** the syntax hook (automatic), `Find-DeprecatedApi.ps1`, `krowi:taint-reviewer` on the diff, `/code-review`.
7. **In game:** deploy to every client and `/reload`, then the Proof steps below. Then `Read-GameErrors.ps1` per client.
8. `CLAUDE.md` write-back, work files to done, PR with `Closes #100`.

## Risks
- **A false FAIL in the new visibility check.** It runs only on merchant-tab steps (`CheckMerchantTab`), where the banner should always be visible. Step 2 shows it FAILs for the right reason, and the other clients' runs show it passes where nothing hides the banner.
- **Plumber's module changes during a session.** The check runs at every vendor until it fires, so a module turned on mid-session is caught at the next vendor. One turned off restores the bar, and the check stays false.
- **The notice window over the vendor window.** Same frame, strata and position as the EllesmereUI notice. The in-game step checks that it closes with Okay and leaves the vendor window usable.
- **Renaming the notice frame.** Nothing references `KrowiEVU_NotLoadedNotice` (grep). The EllesmereUI not-loaded notice still opens from the first vendor and from the addon compartment, which is checked once with EllesmereUI's list mode on.
- **Taint.** The new code reads a Blizzard frame's parent and another addon's saved variable, and writes only to the addon's own frames. `krowi:taint-reviewer` confirms.

## Proof
- Retail, Plumber on (Merchant Price on):
  - The first vendor shows the notice window and the chat line. Okay closes the window.
  - `/kevutest`: an INFO line "token banner hidden by Plumber's Merchant Price", then a PASS for "notice shown this session".
  - A second vendor shows no notice.
  - The Plugins options page has a Plumber entry with Loaded checked and the explanation.
- Retail, Merchant Price turned off in Plumber's settings: the banner is back without a reload. After `/reload`, no notice, and `/kevutest` passes the visibility check.
- Retail, Plumber disabled: no notice, the visibility check passes, and the Plugins entry shows Loaded unchecked.
- Mists, Anniversary, Era: `/kevutest` passes with the banner visible. No Plumber entry on the Plugins page.
- Forever, if its realm is up: same as Retail with Plumber disabled (Plumber is not installed there).
- A zhCN client is not available locally. The zhCN strings are checked in `zhCN.lua` after the import.
- `Read-GameErrors.ps1` per client: no new row and no bumped count.
