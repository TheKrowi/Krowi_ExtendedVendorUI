# Spec: Extended Vendor UI on WoW Forever
Intent: [intent.md](intent.md). Status: done

## Requirements
1. The TOC lists Forever's interface number, 16001 (done on this branch).
2. On Forever the addon runs the code it runs on Retail for everything Blizzard draws the same way: merchant frame layout, slot drawing, paging, the filter, options and search widgets, the token banner and Bulk Purchase.
3. On Forever the filter and options dropdowns use Blizzard's menus, as on Retail.
4. What has no content on Forever is not built there: the Housing filter, the Housing Quantity option and the housing catalog searcher at boot.
5. Bulk Purchase on Forever counts extended costs as on Retail.
6. With Forever's gamepad interface style on at load, the addon loads nothing: Blizzard's vendor window stays, and the chat says why at the first vendor of the session. Switched on later, the next vendor says to reload. No Blizzard paging control shows over the grid or pages Blizzard's hidden list.
7. Every existing Krowi_Util flag keeps its name, how it is computed and its value on every client, Forever included; Krowi_Util only gains `IsForever` and `IsModern`. Krowi_Menu behaves on every client as it does now for a consumer that does not ask for more. On Retail, Mists Classic, TBC Anniversary and Classic Era `/kevutest` passes as before.
8. `/kevutest` runs on Forever without failed checks and no Lua error from this addon.

## Root cause
- Forever's project id is 18: `Blizzard_ProjectConstants\Camelot\ProjectConstants.lua:1-2` (wow-ui-source `forever`, 1.60.1.70450) sets `WOW_PROJECT_CAMELOT = 18; WOW_PROJECT_ID = WOW_PROJECT_CAMELOT`. Its build is 1.60.1.
- Krowi_Util derives its flags from those (`Libs/Krowi_Util/Krowi_Util.lua:16-26`): `IsClassicEra = majorVersion == '1'` is true and `IsMainline = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE` is false.
- Forever's game type, camelot, is in Blizzard's mainline family. `Blizzard_UIPanels_Game.toc:110,113` loads `[Family]\MerchantFrame.lua` and `.xml`, Retail's, whose per-item code is the same as live's (the diff touches only gamepad and footer code). Blizzard's menus, Settings, StaticPopup and color picker are the Retail ones too.
- So the addon takes its Classic path against a Retail merchant frame:
  - `Gui/MerchantFrame.lua:61` errors at load: `MerchantFrameBtnCornerLeft` exists in no Forever file.
  - `Gui/MerchantItemSlot.lua` would draw every slot with `GetMerchantItemInfo`, whose only caller on Forever is `Vanilla\MerchantFrame.lua`, a file camelot does not load.
- Krowi_Menu checks `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE` itself (`Krowi_Menu.lua:228`, `Krowi_MenuUtil.lua:40`, `Krowi_MenuBuilder.lua:275`), so it would build UIDropDownMenu menus. If only the addon moved to its Retail path, the dropdowns would open empty.
- Reproduction (Forever 1.60.1 with this branch at b65d78c, one session on 2026-10-22, `Read-GameErrors.ps1 -Client Forever`):
  - `Gui/MerchantFrame.lua:61`: attempt to index global `MerchantFrameBtnCornerLeft` (a nil value), once, at load. The rest of the file never runs, so `SetMerchantFrameSize` (line 69) is never defined.
  - `Gui/MerchantFrame.lua:40`: attempt to index global `MerchantRepairText` (a nil value), x8, in the `MerchantFrame_UpdateRepairButtons` post-hook.
  - `Gui/MerchantItemsContainer.lua:188` (x5) and `Gui/TokenBanner/TokenBanner.lua:100` (x1): attempt to call a nil value, `addon.Gui.MerchantFrame.SetMerchantFrameSize()`.
  - `Gui/MerchantItemSlot.lua:270`: attempt to call a nil value, `GetMerchantItemInfo`, x4, from the `MerchantFrame_UpdateMerchantInfo` post-hook.
  - Screenshot `H:\World of Warcraft\_classic_beta_\Screenshots\WoWScrnShot_102226_192008.jpg` (gamepad interface style on): Blizzard's own ten items and no grid, with Blizzard's gamepad page-turn arrows either side of "Page 1 of 2".

## Design
How the code tells clients apart is the decision of this stage (Krowi, 2026-10-21); the library and addon changes wait for it.

What each client says about itself (wow-ui-source per branch; `[Game]` is the name the client substitutes in TOC file paths):

| Client | Build | `WOW_PROJECT_ID` | Game type | Interface it runs | Krowi_Util flags true today |
|---|---|---|---|---|---|
| Retail | 12.1.5 | 1 | Standard | Retail | IsMainline, IsMidnight |
| Mists Classic | 5.5.4 | 19 | Mists | Classic | IsMistsClassic, IsClassicWithAchievements |
| Titan Reforged (China, not in this TOC) | 3.80.2 | 11 | Wrath | Classic | IsWrathClassic, IsClassicWithAchievements |
| TBC Anniversary | 2.5.6 | 5 | TBC | Classic | IsBCCClassic |
| Classic Era | 1.15.9 | 2 | Vanilla | Classic | IsClassicEra |
| Forever | 1.60.1 | 18 | Camelot | Retail | IsClassicEra |

Every branch asks one of two things: "which interface does this client run" (Blizzard's frames, templates, menus) or "which client is this" (what content exists). `IsMainline` answers both today; Forever is the first client where the answers differ.

Ways to decide:
- **Build major** (`GetBuildInfo`), the source of today's version flags. It breaks when Blizzard reuses a major for a new client: Forever 1.60 next to Era 1.15, Titan 3.80 after Wrath Classic.
- **Project id** (`WOW_PROJECT_ID`), the source of today's `IsMainline`. It is one id per live client and is set by Blizzard's own code before any addon loads. The addons on this machine that support Forever use it: ElvUI's oUF (`isForever = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT`, `isRetail = ... MAINLINE and not isForever`, `isModern = isRetail or isForever`, `ElvUI_Libraries\Game\Shared\oUF\init.lua:28-31`), LibSpecialization (`wowID == 18`), LibDispel, LibActionButton and the AceGUI color picker in the Ace3 that ElvUI bundles. Of the `WOW_PROJECT_*` names only `MAINLINE` and `CLASSIC` exist on every client: `CAMELOT` exists only on Forever, and `MISTS_CLASSIC` and the other Classic names do not exist on Retail. So a library compares against the numbers.
- **TOC game type** (`[Game]`, `[AllowLoadGameType]`). The client itself picks the file: BigWigs loads `Init_[Game].lua` (Init_Standard, Init_Camelot, Init_Vanilla, ...); BugSack loads `forever.lua [AllowLoadGameType camelot]`. It works only in an addon's own TOC, not in the `Files.xml` that loads embedded libraries, so it cannot set Krowi_Util's flags; this repo has one TOC without conditionals.
- **Feature detection** (`if MenuUtil then`, Krowi_WorldMapButtons' `WorldMapTrackingPinButtonMixin ~= nil`). It is exact for one feature but says nothing about the client, and an API can exist without content (`C_HousingCatalog` is documented on Forever, yet no housing UI loads for camelot).
- **`C_GameRules.GetActiveGameMode`** tells only Standard from Plunderstorm. Game rules (`IsGameRuleActive`, e.g. `HousingDashboardDisabled` in Forever's micro menu) are per-feature switches, a form of feature detection.

Chosen (see Decision): Krowi_Util adds two flags below `IsMainline` and changes nothing else.

```lua
lib.IsForever = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT -- WoW Forever; WOW_PROJECT_CAMELOT exists only there, so this is false elsewhere
lib.IsModern = lib.IsMainline or lib.IsForever -- runs Retail's interface: Retail and Forever
```

- Every existing flag stays as it is, how it is computed included. Forever's 1.x build keeps `IsClassicEra` true there, so code that means Classic Era alone tests `IsForever` first.
- `IsForever` and `IsModern` stay nil in a session where no loaded addon ships the new minor, which only matters to code that reads them.
- `lib.IsX =` lines keep the form Krowi_AchievementFilter's `util-flags` check parses.
- Krowi_Menu: this addon gets Blizzard's menus on Forever without changing what Krowi_Menu does there for consumers that do not ask for it (requirement 7); the plan says how.
- This addon reads `IsModern` where it branches on Blizzard's interface and `IsMainline` where it branches on Retail-only content (Housing); Bulk Purchase's extended-cost check stops reading `IsClassicEra`. The plan classifies each of the 42 `IsMainline` sites and the `IsClassicEra` one.
- Gamepad (open question 2), proposal for the next gate: hide `MerchantPageTurnIndicatorLeft/Right` with the other Blizzard paging controls on the merchant tab; moving through the grid with a gamepad is a separate feature.

## Options considered
All three look the same to a player on every client: on Forever the window works as on Retail without housing, and nothing changes elsewhere. They differ in what the next client or the next Krowi addon on Forever costs.

- **A. Project id for every client flag, plus `IsForever` and `IsModern` (recommended).** It uses one source for "which client", the one Blizzard and the Forever-ready libraries use, and keeps the two questions apart. Costs: a Krowi_Util release (minor 4 to 5), a Krowi_Menu release, and in this addon about 40 `IsMainline` reads renamed to `IsModern`.
- **B. Keep the build-major flags; make `IsMainline` true on Forever too, add `IsForever`, take Forever out of `IsClassicEra`.** Krowi_WorldMapButtons already does this with its own flags. This addon then changes only Housing and nothing else. Costs: `IsMainline` stops meaning Retail for every Krowi addon. Krowi_AchievementFilter reads it 44 times, partly to pick Retail data; it does not claim Forever, so no player sees a difference today, but each read needs checking the day it does. The next reused build major is again a fix.
- **C. Leave Krowi_Util alone; this addon sets its own `addon.IsModern` and handles `IsClassicEra` locally.** There is no Krowi_Util release (Krowi_Menu still needs one). Costs: `IsClassicEra` stays wrong on Forever for every reader, and the next Krowi addon on Forever repeats the work.

## Areas of concern
- Taint and secret values: the flags are plain booleans computed at load; no Blizzard global, frame or function is touched. Taint review of 2026-10-22: Retail, the Classic clients and Forever with mouse and keyboard are clean. In Forever's gamepad interface style, Blizzard's gamepad navigation (`Blizzard_GamepadSmartNavigation`) collects every button in the vendor window, the addon's slots too, reads `buttonContext` (a `MerchantItemTemplate` key value, so set by the addon's `CreateFrame`) and `count` on them (`SmartNavigation.lua:1688-1690`, `MerchantFrame.lua:1184-1187`) and rebuilds the gamepad bindings tainted: `ADDON_ACTION_BLOCKED` in combat, also after the window closes. Returning from Buyback selects the top-left button while Blizzard's own slots still show (`MerchantFrame.lua:471-474`), so Buy can act on Blizzard's hidden first slot. No field-level fix exists, since any value the addon writes there is tainted too; hence requirement 6. The later addon branches sit in taint-sensitive files (`Gui/MerchantFrame.lua`, `Gui/MerchantItemSlot.lua`, `Gui/Paging/`): `krowi:taint-reviewer` runs on them, on the Classic and the Retail branch.
- Clients: the table above. Retail, Mists, Anniversary and Era keep every value; Titan is not in this TOC and keeps its values too.
- Blizzard API changes: `WOW_PROJECT_CAMELOT` exists only on Forever (`Blizzard_ProjectConstants\Camelot\ProjectConstants.lua:1`); on every other client it is nil and `WOW_PROJECT_ID` is a number, so `IsForever` is false there. `Find-DeprecatedApi.ps1 -Branch forever` runs on the changed files.
- Other addons, plugins and skins: Krowi_Util_2 is one LibStub table per session, written by its highest minor, so a flag's value reaches every Krowi addon loaded beside this one, including those that embed older copies (Brokers 2.0, Vendorer 2.2). Skins are out of scope on Forever.
- Saved variables and migrations: none.
- Localization: none.
- Embedded libraries: Krowi_Util (`Krowi_Util.lua`, Krowi_Util_2 minor 4 to 5) and Krowi_Menu (the minor of each changed file), developed and released in `Krowi_Libraries`, then moved into this addon by the release preflight.
- Data snapshots: none in this repo.
- Player-facing text: a changelog line under the next version, e.g. "WoW Forever support".

## Verification
- Permanent test: `/kevutest` writes Krowi_Util's client flags into each run's header and checks them against the client's project id, so the release gate's run per client proves requirement 7, and Forever's run proves the Forever values.
- `/kevutest` on Forever without failed checks (requirement 8), with a check that Blizzard's paging controls stay hidden when the gamepad interface style is on, and a note when it is off.
- `Read-GameErrors.ps1 -Client Forever` shows no error from this addon after the `/reload`; the reproduction above is gone.
- `/kevutest` on Retail, Mists, Anniversary and Era as the release gate requires.
- `Find-DeprecatedApi.ps1 -Branch forever`, `krowi:taint-reviewer`, `/code-review`.

## Decision
Option A, by Krowi on 2026-10-21: "A, but make sure we keep the backwards compatibility for at least a year". Read as requirement 7: until 2027-10-21 at the earliest no existing Krowi_Util flag is removed, renamed or changes its value on any client, Forever included, and Krowi_Menu keeps its current behaviour for consumers that do not ask for more; Forever's new behaviour comes only through additions (`IsForever`, `IsModern`, and whatever Krowi_Menu adds). So `IsClassicEra` stays true on Forever until then. The gamepad scope (open question 2) is decided at the plan gate.

Narrowed by Krowi on 2026-10-22, after the flags were laid out side by side: "only add new flags, old unchanged". Krowi_Util gains `IsForever` and `IsModern`; every existing flag keeps how it is computed (build major, or project id for `IsMainline`) and its value, with no later cleanup planned. Moving the existing flags to the project id would have changed no value on any live client; it is not done.

Code review of PR #98 (2026-10-22): on Forever Blizzard's own merchant filter is most likely off (`Enum.GameRule.MerchantFilterDisabled`; its window shows no filter dropdown, forever `MerchantFrame.lua:193-197`), while the addon's menu still offers the class/spec and Binds when equipped filters and passes them to `SetMerchantFilter`. Krowi, 2026-10-22: leave as is.