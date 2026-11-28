# Intent: Move the vendor window, and resize it by dragging in whole columns and rows
Author: Krowi (issues #138 and #139, 2026-11-27), from shadowgrind's CurseForge comment of 2026-11-26: "Great Addon! Could you add an option to make the Frame moveable (perhaps also resizeable)?" Source: GitHub issues #138 and #139. Status: accepted (Krowi, 2026-11-28: moving with Krowi_AchievementFilter's settings and behaviour; resizing as written; one work item)

## Problem
The vendor window is Blizzard's `MerchantFrame`, a UI panel (`UIPanelWindows["MerchantFrame"] = { area = "left", pushable = 0 }`, live and forever `Mainline/UIPanelWindows.lua:18`, the Classic clients `Classic/UIPanelWindows.lua:17`). Blizzard's panel manager puts it at the left edge of the screen every time it opens and again whenever another panel opens or closes beside it. Players cannot move it. With this addon the window grows with Rows and Columns (7 x 4 on a fresh install, up to 99 x 99), so a large grid covers much of the screen and a player cannot put it where it suits their layout.

Its size is set only through Rows and Columns in the gear menu (`Gui/OptionsButton/OptionsButtonMixin.lua:133-191`): presets or a typed number. A player cannot size the window by eye.

## Proposed outcome
- #138: the player drags the vendor window to a place of their choice. It opens there on every vendor, and stays there when other windows open or close beside it, until the player resets it to Blizzard's place.
- #139: the player drags a grip in the window's corner. The window grows or shrinks in whole columns and rows, and the new size is the same setting as Rows and Columns in the gear menu.

## Affected users and systems
Players of every client (Retail, Mists Classic, TBC Anniversary, WoW Forever, Classic Era). The merchant tab of the vendor window (`Gui/MerchantFrame.lua`, `Gui/MerchantItemsContainer.lua`); the Buyback tab keeps Blizzard's size. `KrowiEVU_Options` (the saved position; `NumRows` and `NumColumns`, which the grip writes). The gear menu and the options page (a reset, any switch). Every locale file. Other addons: BlizzMove (moves `MerchantFrame` on every client by default) and MoveAny; the ElvUI, GW2_UI and EllesmereUI skins of the window; Can I Mog It and Transmog Loot Helper overlays on the slots (Transmog Loot Helper reaches only 99 slots).

## Constraints
No taint: `MerchantFrame` gets only method calls and post-hooks, no field or `UIPanelWindows` entry is written, and the panel manager (a forbidden frame) is never driven from addon code. The window keeps working as a UI panel: Escape closes it, and other panels still open beside it. The page controls, token banner, repair buttons and Bulk Purchase keep their places inside the window. The gear menu's Rows and Columns keep working. Every client.

## Open questions
- One work item and pull request for both issues, or two.
- How the window is moved (title bar or anywhere on the window), whether that is on by default or behind a switch, and where the reset is.
- Whether the position is shared by all characters (the addon's options are account-wide today) or per character.
- What happens beside BlizzMove or MoveAny.
- Whether the grid redraws at every column or row while the grip is dragged, or only when the mouse is released (an outline meanwhile).
- The smallest and largest size the grip allows, and which page the player is on afterwards.
