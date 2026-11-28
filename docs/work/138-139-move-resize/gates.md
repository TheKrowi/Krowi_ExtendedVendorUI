# Gates: 138-139-move-resize
Class: feature

| Date | Gate | Question | Recommended | Answer | Outcome |
|---|---|---|---|---|---|
| 2026-11-28 | intent | Drag the vendor window to a place of one's own (opens there until reset); a corner grip sizes it in whole columns and rows, writing Rows and Columns; every client | Yes, as written | "#138 check kaf how making the window movable works, i want the same settings and behavior, #139 ok" | amended |
| 2026-11-28 | scope | #138 and #139 as one work item and PR, or two? | One item, one PR | "One item, one PR (Recommended)" | took |
| 2026-11-28 | design | Move defaults: KAF's code (Movable on, Remember off), KAF's OPTIONS.md (both on), or Movable off? | As KAF's code | "As KAF's code (Recommended)" | took |
| 2026-11-28 | design | With BlizzMove moving the vendor window: step aside with the Movable settings greyed, or both addons move it? | Step aside for BlizzMove | "How does kaf handle it?" | other |
| 2026-11-28 | design | BlizzMove (asked again after KAF's silent skip was explained): settings greyed with a line, or silent as KAF? | Step aside, settings greyed | "blizzmove makes it movable, that setting can be greyed out but remember position should still work" | amended |
| 2026-11-28 | design | Grip redraw while dragging: Snap, Outline, or both behind a switch to pick in game? | Both, you pick in game | "Both, you pick in game (Recommended)" | took |
| 2026-11-28 | plan | plan.md: WindowMover.lua and ResizeGrip.lua, Window tab with KAF's settings, MoveAny treated as BlizzMove, seven /kevutest steps, changelog 24.7; Retail look check first | Go | "Go (Recommended)" | took |
