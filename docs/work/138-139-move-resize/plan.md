# Plan: Move the vendor window, and resize it by dragging in whole columns and rows
Spec: [spec.md](spec.md). Status: done (accepted by Krowi, 2026-11-28)

## Results (2026-11-28)
- `/kevutest`, final Snap build (`f3c1fe5`), no FAIL and no Lua error from this addon on any client: Retail 172 passed (BlizzMove loaded, so its step-aside ran), Mists 149, Anniversary 184, Era 150, Forever 150 (no other mover).
- After the code review fixes (`4037241`, window mover only, no client branch), Retail again: 172 passed, 0 failed. The other clients run again in the release gate.
- `krowi:taint-reviewer`: no taint or secret-value findings. Two low guards (`StartMoving` and the reapply test step while protected in combat) and the cursor-item drag were fixed in `f557f5f`.
- `/code-review` (medium): five findings, all fixed in `4037241`: Reset after a drag, profile change, 4 px click threshold, the Remember description, and one restyled `Tests.lua` line.
- `Find-DeprecatedApi.ps1`: only `GetMerchantCurrencies` in `Tests.lua:321`, which was already there and is not part of this change.

## Files that change
| File | Change |
|---|---|
| `Options/Defaults.lua` | `Window = { Movable = true, RememberPosition = false }` in `profile`. `Window.Position` (`{ X, Y }`, top-left offset from `UIParent`'s top-left) is written only while remembered, with no default. |
| `Gui/WindowMover.lua` (new, 4 spaces) | `addon.Gui.WindowMover`: the session position, `IsMovedByOtherAddon()` (BlizzMove through `BlizzMoveAPI:IsFrameDisabled('BlizzMove', 'MerchantFrame')`; MoveAny while loaded, see below), `CanDrag()`, `SetPosition(x, y)`, `Apply()`, `Reset()`, `GetBlizzardPoint()`. Hooks (as built): `HookScript('OnMouseDown' / 'OnMouseUp' / 'OnHide' / 'OnShow')` on `MerchantFrame`, no `RegisterForDrag` (spec, Dragging), `hooksecurefunc('UpdateUIPanelPositions', ...)`, `hooksecurefunc('UpdateScaleForFitForOpenPanels', ...)`. |
| `Gui/ResizeGrip.lua` (new, 4 spaces) | `KrowiEVU_MerchantResizeGrip`, a `Button` child of `MerchantFrame` with the size-grabber textures in the bottom-right corner. `OnMouseDown`, `OnUpdate` and `OnMouseUp` of its own; `GetMaxGrid()`; Snap and Outline (`KrowiEVU_MerchantResizeOutline`, an own frame with a border) behind a temporary switch, `/kevugrip snap|outline` (session only, removed after the look gate). As built: Snap only, since Krowi chose it at the look gate (2026-11-28); the outline and `/kevugrip` are gone. |
| `Gui/MerchantFrame.lua` (tabs) | `merchantFrame.ResizeTo(columns, rows)`, which clamps, writes `NumColumns`/`NumRows` and runs `addon.Gui.OptionsButton.UpdateView()` when a value changed. The grip shown in `UpdateMerchantInfoLayout`, hidden in the `MerchantFrame_UpdateBuybackInfo` post-hook. |
| `Gui/Files.xml` | `WindowMover.lua` and `ResizeGrip.lua` after `MerchantFrame.lua`. |
| `Options/General.lua` | A Window tab with the Movable group: Make Window Movable (toggle, `disabled` while another addon moves the window, which its description then says), Remember Window Position (toggle; off resets, as KAF), Reset Position (execute). `RefreshOptions` also re-applies the position after a profile change. |
| `Localization/*.lua` (6) | New strings below the marker in `enUS.lua`, translations in deDE, frFR, itIT, ruRU and zhCN. |
| `Tests/Tests.lua` | New steps and checks (Proof). Position, Rows and Columns saved at the start and put back in `Restore`. |
| `_Packaging/Changelog.md` | A new top entry `## 24.7`, without a date, with `### Added`: the movable window (#138) and the corner grip (#139). |
| `CLAUDE.md` | Architecture (window mover, grip), Taint-sensitive areas (the new hooks and what they touch), the `KrowiEVU_Options.Window` keys. |

## Order of work
1. Defaults, then `WindowMover.lua`: position math, `Apply`, `Reset` and the panel-manager post-hooks, with no drag yet. Deploy to Retail and check by `/run` that a set position survives opening the character window and bags beside the vendor, and Buyback.
2. Drag hooks and the BlizzMove and MoveAny step-aside.
3. Options page Window tab and the locale strings.
4. `ResizeTo` and `GetMaxGrid`, then the grip with both variants behind `/kevugrip`.
5. `/kevutest` steps.
6. Look gate on Retail (Krowi drags, toggles Snap and Outline, BlizzMove on and off). Then remove the switch and the variant Krowi drops, unless it becomes a setting.
7. Changelog, `CLAUDE.md`, `krowi:taint-reviewer`, `/code-review`, full `/kevutest` on all five clients.

## Details
- **Position math** (as KAF `Gui/MovableFrames.lua:54-55` and GW2_UI `Core/API/utils.lua:1530`): `X = MerchantFrame:GetLeft()` and `Y = MerchantFrame:GetTop() - UIParent:GetTop() / MerchantFrame:GetScale()`. Applied as `SetPoint('TOPLEFT', UIParent, 'TOPLEFT', X, Y)`. The clamp keeps `X` between `-(width - 40)` and `UIParent:GetWidth() - 40`, and `Y` between `-(UIParent:GetHeight() - 20)` and `0`, so a grip of the title strip is always on screen (requirement 7).
- **Apply** runs only while `MerchantFrame:IsShown()` and a position is set. It first records Blizzard's point (`GetPoint(1)` as the panel manager just set it, only when that point is relative to `UIParent` and differs from the addon's), then `ClearAllPoints` and `SetPoint`. A re-entry flag guards against `OnShow` and the post-hook in the same frame.
- **Reset** clears the session and saved position. While the window is shown it sets the recorded Blizzard point back. Without one (the window was never placed by Blizzard this session), the window goes back at the next layout.
- **Drag** (as built): `OnMouseDown` calls `StartMoving()` only when `CanDrag()` (Make Window Movable on and no other mover; both tabs). `OnMouseUp` calls `StopMovingOrSizing()` and `SetUserPlaced(false)`, then stores the position when the window moved by at least 1 px. With BlizzMove or MoveAny, `OnMouseUp` only stores where the other addon left the window. `OnHide` stops a move cut short by closing the window.
- **MoveAny** (spec, Design: BlizzMove): its `MAFRAMES` list includes `MerchantFrame` (`moveframes.lua:3`), moved while its Move Frames setting is on, which is the default (`moveframes.lua:317`, `settings.lua:736`). That setting is in its private namespace, so the addon treats MoveAny being loaded (`C_AddOns.IsAddOnLoaded('MoveAny')`, with `IsAddOnLoaded` as the Classic fallback through Krowi_Util where needed) as moving the window, the same as BlizzMove.
- **Grip steps**: the column step is `OffsetX + ItemWidth` and the row step `OffsetMerchantInfoY + ItemHeight`. The cursor comes from `GetCursorPosition() / UIParent:GetEffectiveScale()`. The count is `start + floor(delta / step + 0.5)`. `GetMaxGrid()` gives the largest columns and rows whose window, through `SetMerchantFrameSize`'s formula, still ends inside `UIParent` from the current left and top, capped at 99. The grip sits above the money inset's corner (`SetFrameLevel` one above the inset) and is hidden during combat only if a check shows it must be; `MerchantFrame` is not protected.
- **Outline**: a border frame anchored to `MerchantFrame`'s top-left, sized by the same formula, shown while dragging. `ResizeTo` runs once on release.
- **Snap**: `ResizeTo` runs whenever the step count changes.
- **Taint notes for the reviewer**: every call on `MerchantFrame` is in the spec's list. No `SetScript` on a Blizzard frame. `hooksecurefunc` targets only the two globals.

## Risks
- **Hook order with BlizzMove.** Both post-hook `OnShow` and `SetPoint`. With BlizzMove, `Apply` still sets the remembered spot, and BlizzMove's `SetPoint` hook may then pin its own (the same spot within a session). Proof: the look gate with BlizzMove on, and a `/reload` with Remember on.
- **`RegisterForDrag` on `MerchantFrame`** could change how BlizzMove's `OnMouseDown` drag behaves. Proof: the same look gate, and leaving drag unregistered while another mover handles the window if it interferes.
- **A skin's backdrop over the corner** (ElvUI on Classic and Era, GW2_UI) could hide the grip. Proof: `/kevutest` screenshots under each skin setup the release gate already runs.
- **The first open after a reload with Remember on** goes through `ShowUIPanel`, then `SetUIPanel`, then the global, so the post-hook covers it. The `OnShow` hook covers anything else. Proof: the opened step with a saved position.
- **A profile reset or copy** changes `Window`. `RefreshOptions` re-applies, and with no position the window goes back at the next layout.
- **Peers in this repo**: two other sessions are busy here, so `Tests.lua`, the locale files and the changelog may conflict at merge. Before deploying, check `ListAgents` and the deployed build's origin.

## Proof
- `/kevutest` new steps:
  - **window-move**: `SetPosition` to a spot 100 px right and down of Blizzard's, `Apply`. Check `MerchantFrame:GetLeft()`/`GetTop()` against the spot (1 px tolerance), `IsProtected()` false, and whether BlizzMove or MoveAny is noted.
  - **window-reapply**: `ClearAllPoints` and `SetPoint` to Blizzard's recorded point, as the panel manager would, then the post-hook's own function. Check the window is back at the spot.
  - **window-clamp**: a spot far off screen. Check the clamped top-left stays within the bounds.
  - **window-reset**: `Reset`. Check the window is at Blizzard's recorded point and no position is stored.
  - **grip-grow** and **grip-shrink**: `ResizeTo(columns + 1, rows + 1)` and back. Check `NumColumns`/`NumRows`, `MerchantFrame:GetSize()` against the formula, the slot count shown, and the top-left unchanged.
  - **grip-max**: `ResizeTo(99, 99)`. Check it is clamped to `GetMaxGrid()` and the window fits inside `UIParent`, then put the grid back.
  - **grip-buyback**: inside the existing Buyback check, the grip hidden.
  - Every step is screenshotted with its banner. `Restore` puts back the position (session and saved), Remember, Rows and Columns.
- By hand at the look gate (Retail first, then a Classic client): drag the window, open the character window and bags beside it, switch to Buyback and back, reopen at another vendor, `/reload` with Remember on and off, Reset. Drag the grip both ways in Snap and Outline. Repeat with BlizzMove on (Krowi on Frostmane) and with the vendor window disabled in BlizzMove.
- `Read-GameErrors.ps1` after each `/reload`. `Find-DeprecatedApi.ps1`. `krowi:taint-reviewer` and `/code-review` on the branch. Full `/kevutest` on Retail, Mists, Anniversary, Forever and Era.
