# Spec: Move the vendor window, and resize it by dragging in whole columns and rows
Intent: [intent.md](intent.md). Status: accepted (Krowi, 2026-11-28)

## Requirements
Moving (#138), with Krowi_AchievementFilter's settings and behaviour (Krowi, 2026-11-28: "check kaf how making the window movable works, i want the same settings and behavior"):

1. An options page tab, Window, holds a group named Movable with three settings, as in KAF's Window > Movable (`Krowi_AchievementFilter/Options/Layout.lua:605-667`): Make Window Movable (on by default, as KAF's `window.movable`, `Settings/Declarations.lua:106`), Remember Window Position (off by default, as KAF's `window.rememberPosition.*`, lines 108-110) and Reset Position.
2. With Make Window Movable on, the player drags the vendor window with the left mouse button on its background (not on an item slot, button or tab), on both tabs. KAF's window moves the same way (`Gui/MovableFrames.lua:41-46`).
3. A moved window stays where the player left it while other windows open or close beside it, when the UI scale changes, on the switch between Merchant and Buyback, and at the next vendor.
4. With Remember Window Position off, the moved spot holds until `/reload` or logout (KAF keeps an unsaved position until the frame is placed again at load). With it on, the spot is saved in `KrowiEVU_Options` and the window opens there after a reload or relog, on every character (the options are one shared profile).
5. Reset Position puts the window back where Blizzard places it, at once when it is open, and forgets the moved spot. Turning Remember Window Position off resets too (KAF `Options/Layout.lua:296-305`).
6. With Make Window Movable off, the window cannot be dragged. A remembered spot still applies (KAF's `MakeStatic` keeps the last position, `Gui/MovableFrames.lua:3-16`).
7. A saved spot that would put the window's top edge off the screen (another resolution or UI scale) is moved back on screen when it is applied.
8. While BlizzMove handles `MerchantFrame` (it does on every client unless the player disabled that frame in BlizzMove), BlizzMove does the dragging. Make Window Movable is greyed out and its description says BlizzMove moves the window. Remember Window Position and Reset Position keep working: the spot the player dragged to with BlizzMove is remembered and applied at the next vendor and after a relog (Krowi, 2026-11-28: "blizzmove makes it movable, that setting can be greyed out but remember position should still work"). KAF steps aside from dragging the same way, without a word, when another addon already made its frame movable (`Gui/MovableFrames.lua:29`).

Resizing (#139):

9. On the merchant tab a grip sits in the window's bottom-right corner. Dragging it grows or shrinks the window in whole columns and rows, and the grid follows. The Buyback tab has no grip and keeps Blizzard's size.
10. The grip writes `NumRows` and `NumColumns`, the same settings as the gear menu's Rows and Columns, which show the new values afterwards.
11. Limits are the gear menu's: rows 1 to 99 and columns 2 to 99 (`Gui/OptionsButton/OptionsButtonMixin.lua:153-156, 186`). The grip also stops where the window would leave the screen.
12. The window's top-left corner stays put while the grip is dragged, both where Blizzard placed the window and where the player moved it.
13. After a resize the page follows the same rule as a change in the gear menu (`UpdateView`, `Gui/OptionsButton/OptionsButtonMixin.lua:10-14`).

Both:

14. No taint. `MerchantFrame` gets only method calls and post-hooks (`hooksecurefunc` on Blizzard globals, `HookScript`). No field on a Blizzard frame or table is written, and `UIPanelWindows` is not touched. The addon never calls the panel manager (`ShowUIPanel`, `UpdateUIPanelPositions`, `UpdateScaleForFitForOpenPanels`).
15. Every client: Retail, Mists, TBC Anniversary, WoW Forever and Classic Era.
16. Every new string is in all six locale files, with a changelog line for each issue.
17. `/kevutest` checks moving (place, reapply after a panel update, reset) and resizing (grow, shrink, clamp) through the addon's own functions, and puts the position, Rows and Columns back at the end.

## Design
### Why the window needs putting back
The vendor window is a UI panel (`UIPanelWindows["MerchantFrame"] = { area = "left", pushable = 0 }`; live and forever `Blizzard_UIParentPanelManager/Mainline/UIPanelWindows.lua:18`, classic, classic_anniversary and classic_era `Classic/UIPanelWindows.lua:17`). Blizzard opens it with `ShowUIPanel`. The panel manager, a forbidden frame, then runs `ClearAllPoints` and `SetPoint("TOPLEFT", "UIParent", ...)` on every left panel each time panels are laid out (live `Shared/UIParentPanelManager.lua:623-637`). That happens at every open and whenever another panel opens or closes. KAF never meets this: it shows the achievement window with a plain `Show`, so the panel manager does not know it is open (`Krowi_AchievementFilter/Gui/FramesForClosing.lua:10-12`). The vendor window is Blizzard's to open, so this addon puts a moved window back after each layout.

### Where the addon puts it back
Every layout that places panels after a show, hide or move goes through the global `UpdateUIPanelPositions`. `SetUIPanel` and `MoveUIPanel` call it by name with `securecall("UpdateUIPanelPositions", frame)` (live `Shared/UIParentPanelManager.lua:488, 515`; forever 494, 521; classic and classic_era 457, 484). Blizzard's other callers use the global too (live 1142, `CloseWindows`). A `hooksecurefunc('UpdateUIPanelPositions', ...)` post-hook therefore runs after the panel manager has placed the window. A second post-hook on `UpdateScaleForFitForOpenPanels` covers UI scale changes, which lay out through the delegate's own method (live 748-757). A `MerchantFrame:HookScript('OnShow', ...)` is the fallback for the open. The post-hook first notes where Blizzard put the window (its first point), for Reset, then sets `TOPLEFT` against `UIParent` at the moved spot.

What the hooks miss: on Retail and Forever, `RepairUIPanelState` (live 156-183) lays out through the delegate's own method when it finds a stale panel slot. When the `ShowUIPanel` that follows then fails (the player is dead, a full-screen panel is open), the window is back at Blizzard's place until the next layout. This is rare and harmless, and is accepted.

A post-hook on `MerchantFrame:SetPoint` would catch every case, and BlizzMove does that (AceHook `SecureHook(frame, "SetPoint")`, `BlizzMove.lua:1416`). It writes a `SetPoint` field onto Blizzard's frame, which this repo's rules forbid (`CLAUDE.md`, Taint-sensitive areas), so it is not used.

### Dragging
`MerchantFrame` is movable in Blizzard's XML on every client (`movable="true"`: live `Mainline/MerchantFrame.xml:91`, forever 94, the Classic clients `TBC`/`Vanilla/MerchantFrame.xml:88`), and mouse-enabled. The addon post-hooks `OnMouseDown` and `OnMouseUp` with `HookScript`, as KAF's windows move (KAF uses `SetScript`; this repo only hooks). On a left mouse-down, when moving is allowed, it calls `StartMoving()`. On mouse-up it calls `StopMovingOrSizing()`, then `SetUserPlaced(false)` so the client's layout cache does not take the window over (BlizzMove `BlizzMove.lua:912`, GW2_UI `Core/API/utils.lua:1528` and ElvUI `Install.lua:1526` do the same). It then stores the top-left corner as an offset from `UIParent`'s top-left. It stores a spot only when the window actually moved, so a plain click on the background changes nothing. Build departure from the first draft (`RegisterForDrag` with `OnDragStart`/`OnDragStop`): once a drag gesture starts, `OnMouseUp` may not fire, and BlizzMove stops its own move in `OnMouseUp` (`BlizzMove.lua:1394`), so a registered drag could leave BlizzMove's window stuck to the cursor. Item slots, buttons and tabs take their own clicks, so only the background moves the window.

The position lives in a session table and, with Remember Window Position on, also in `KrowiEVU_Options.profile.Window.Position` (`{ X, Y }`). It is nil while the window is at Blizzard's place. Applying clamps it so the top edge and at least the title strip stay on screen.

### BlizzMove
BlizzMove registers `MerchantFrame` for every game version (`Frames.lua:307-309`). It drags it from its own `OnMouseDown`/`OnMouseUp` hooks (`BlizzMove.lua:1393-1394`) and re-pins it from its `SetPoint` and `OnShow` hooks (`BlizzMove.lua:1162-1180, 1409, 1416`). By default it keeps a dragged spot for the session only (`savePosStrategy = "session"`, `BlizzMove.lua:1769`). `BlizzMoveAPI:IsFrameDisabled('BlizzMove', 'MerchantFrame')` (`BlizzMoveAPI.lua:114`) says whether BlizzMove handles the window, and the addon reads it at each drag and apply. Krowi's Retail character Krowi on Frostmane has BlizzMove enabled, so today the vendor window there already moves through BlizzMove.

While BlizzMove handles the window, the addon does not start a drag of its own, and Make Window Movable is greyed out. Its `OnDragStop` and a `HookScript('OnMouseUp')` still note where the window ended up after a BlizzMove drag. Remember Window Position and the apply after each layout then work as without BlizzMove. In a later session BlizzMove holds no dragged spot, so the addon's remembered spot is the one applied, and BlizzMove's `SetPoint` hook leaves an undragged frame alone (`BlizzMove.lua:1167-1172`). Within the session both hold the same spot, the one the player dragged to.

Known limit: after a BlizzMove drag in the same session, Reset Position puts the window at Blizzard's place, but BlizzMove's `SetPoint` hook pins it back to its own dragged spot. It resets after a reload, or with BlizzMove's own reset. Reset Position's description says so while BlizzMove handles the window.

MoveAny is not installed here. The build reads its released source and steps aside the same way if it moves `MerchantFrame`.

### The grip
A button of the addon's own, `KrowiEVU_MerchantResizeGrip`, child of `MerchantFrame`, sits in the bottom-right corner with the chat window's size-grabber textures (`Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up/-Down/-Highlight`, on every client). On mouse down it notes the cursor and the current Rows and Columns. An `OnUpdate` of its own turns the cursor's distance into whole steps: a column is `OffsetX + ItemWidth` and a row is `OffsetMerchantInfoY + ItemHeight` (`Gui/MerchantItemsContainer.lua:11-18`), the same steps `SetMerchantFrameSize` adds (`Gui/MerchantFrame.lua:87-102`). It clamps to requirement 11 and hands the result to one function, `merchantFrame.ResizeTo(columns, rows)`. That function writes `NumColumns` and `NumRows` and runs `UpdateView`, so the gear menu and the grip share one setting and one redraw path. `MerchantFrame` is never made resizable and `StartSizing` is not used.

`SetSize` keeps the top-left corner in place because the window is anchored by `TOPLEFT`, both by the panel manager and by the moved spot. The largest size is the one that still fits between the window's left and top edges and the screen's right and bottom edges.

How the grid redraws while dragging is the design question below. Snap redraws the grid at every new column or row. Outline shows a frame at the new size and redraws once on release. Each redraw can create slots (only beyond the most created so far) and closes Blizzard's stack split window when a slot changes item (Taint-sensitive areas, accepted in the 2026-10-21 review).

### Files
- `Gui/MerchantFrame.lua`: the drag hooks, the panel-manager post-hooks, apply, reset and `ResizeTo`, and the grip shown only on the merchant tab (`UpdateMerchantInfoLayout` and the buyback post-hook).
- A new `Gui/ResizeGrip.lua` (or inside `MerchantFrame.lua` if small), listed in `Gui/Files.xml`.
- `Options/General.lua` (the Window tab), `Options/Defaults.lua` (`Window = { Movable = true, RememberPosition = false }`).
- The six locale files, `_Packaging/Changelog.md`, `Tests/Tests.lua`, `CLAUDE.md` (architecture and taint notes).

## Options considered
Moving:
- **Post-hooks on the panel manager's globals, with KAF's settings (chosen).** It follows Krowi's direction and the repo's taint rules. The cost is the rare `RepairUIPanelState` gap.
- Hook `MerchantFrame:SetPoint`, as BlizzMove does. It catches every placement but writes a field on Blizzard's frame. Rejected.
- Show the window outside the panel manager, as KAF does with its window. The vendor window is opened by Blizzard's `MERCHANT_SHOW` handler, so the addon would have to hide and re-show it from addon code. That taints the open and breaks Escape and the panel slots. Rejected.
- Leave moving to BlizzMove and only document it. It is the smallest change, but players without BlizzMove keep asking, and Krowi asked for KAF's settings. Kept only as the step-aside when BlizzMove is there.

Redrawing while the grip is dragged (asked at the gate):
- **Both behind a temporary debug switch, Krowi picks in game (recommended).** Krowi judges feel only in the client.
- Snap: the grid redraws at each step. It feels direct, but there are many redraws during a fast drag.
- Outline: one redraw on release. It is calm, but the player sees the result only after letting go.

## Areas of concern
- **Taint and secret values:** see requirement 14. Calls on Blizzard frames: `RegisterForDrag`, `StartMoving`, `StopMovingOrSizing`, `SetUserPlaced`, `ClearAllPoints`, `SetPoint`, `SetSize` (as today) and `HookScript('OnDragStart' | 'OnDragStop' | 'OnShow')`. Post-hooks on the globals `UpdateUIPanelPositions` and `UpdateScaleForFitForOpenPanels`. The hooks run inside the panel manager's `securecall`, which returns the caller to its own state afterwards. `MerchantFrame` is not protected (a plain `ButtonFrameTemplate`, no secure template), so moving in combat is allowed. `/kevutest` checks `MerchantFrame:IsProtected()` on every client. Whether anything protected anchors to `MerchantFrame` is checked in the taint review. No secret values are read. `krowi:taint-reviewer` runs on the branch.
- **Clients:** the same panel manager file layout on all of them (`Shared/UIParentPanelManager.lua`). `UpdateScaleForFitForOpenPanels` exists on every client (live 1169, forever 1197, the Classic clients 1125). The Classic clients' `ButtonFrameTemplate` frame has the same corner for the grip. Each client runs `/kevutest`.
- **Blizzard API changes:** none removed. `RegisterForDrag`, `StartMoving` and `SetUserPlaced` are long-standing frame methods. `Find-DeprecatedApi.ps1` runs anyway.
- **Other addons, plugins and skins:** BlizzMove is stepped aside from (requirement 8). MoveAny is checked in the build. ElvUI (Classic, Era), GW2_UI and EllesmereUI skin the window but do not move it (their sources have no mover on `MerchantFrame`: GW2_UI's `MakeFrameMovable` covers other frames only). The grip sits above their backdrop, and the look gate shows it under each skin. Can I Mog It and Transmog Loot Helper follow the slots as they do with the gear menu, and Transmog Loot Helper's 99-slot limit stays known debt. Krowi_Vendorer is unaffected.
- **Saved variables and migrations:** new keys in `KrowiEVU_Options` (`Window.Movable`, `Window.RememberPosition`, `Window.Position`). AceDB defaults cover old saved files, so there is no migration. `NumRows` and `NumColumns` keep their meaning.
- **Localization:** the tab name, the group name, three setting names with descriptions, and the BlizzMove line, in enUS, deDE, frFR, itIT, ruRU and zhCN. KAF's existing translations of "Movable", "Reset position" and "Remember {frame} position" are reused where they fit. Setting names are Title Case and descriptions start with a verb.
- **Embedded libraries:** none changed.
- **Player-facing text:** the settings above and two changelog lines under `### Added`.

## Verification
- `/kevutest` new steps (driven by function calls, since the kit cannot drag):
  - Move: set a position through the addon's function, then check `MerchantFrame`'s top-left against it.
  - Reapply: run the addon's own reapply, as the post-hook would after a layout, and check again. The open itself is checked at the first draw when a position is saved.
  - Reset: check the window is back at the point Blizzard last gave it.
  - Clamp: an off-screen position comes back on screen.
  - Protection: `IsProtected()` is false.
  - BlizzMove: noted as present and handling, or absent.
  - Resize: `ResizeTo` one column and one row larger, then smaller, checking the window's size against `SetMerchantFrameSize`'s formula, the slots shown, the top-left unchanged, and a clamp at the screen edge.
  - Every step screenshotted. Position, Rows and Columns are put back at the end.
- By hand, at the look gate on Retail first: drag the window, open the character window and bags beside it, switch to Buyback and back, close and reopen at another vendor, `/reload` with Remember on and off, then Reset. Then drag the grip both ways in both redraw variants, without and with BlizzMove (BlizzMove enabled on Krowi on Frostmane; a run with it disabled in BlizzMove's settings).
- `Read-GameErrors.ps1` after each `/reload`, `krowi:taint-reviewer` and `/code-review` on the branch.
- Full `/kevutest` on all five clients after the look gate.

## Decision
Krowi, 2026-11-28:
- Intent: "#138 check kaf how making the window movable works, i want the same settings and behavior, #139 ok". Moving follows KAF's Window > Movable (requirements 1-8).
- Scope: one work item and one pull request for both issues.
- Defaults: as KAF's code, Make Window Movable on and Remember Window Position off.
- BlizzMove: after the question how KAF handles it (KAF skips a frame that is already movable, silently), "blizzmove makes it movable, that setting can be greyed out but remember position should still work" (requirement 8, Design: BlizzMove).
- Grip redraw: both Snap and Outline behind a temporary switch, and Krowi picks in game at the look gate. At the look gate on Retail: "Snap, look is fine".
