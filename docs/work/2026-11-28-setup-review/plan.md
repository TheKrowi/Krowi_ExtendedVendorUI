# Plan: Act on the Claude Code setup review of 2026-11-28
Spec: [spec.md](spec.md). Status: done 2026-11-28

## Files that change
- `CLAUDE.md`: the two line references; the Drawing a slot, Paging, Filters, `Gui/` and Public API bullets and the `/kevutest` coverage paragraph cut to their first sentence plus "Details: `.claude/rules/<file>`"; the `raw/` and `wiki/` bullet in Git and release removed.
- `.claude/rules/filters.md`, `gui.md`, `plugins.md`, `testing.md` (new): `paths:` frontmatter, a `#` title, the moved text verbatim. 4 spaces, CRLF on disk, no final newline, like the repo's other files.
- `.claude/settings.json`: a `deny` array with the two `wow-ui-source` rules, after `allow`.
- `.github/pull_request_template.md` (new).
- `raw/`, `wiki/`: deleted with `git rm -r`.

## Order of work
1. Save the old `CLAUDE.md` to the scratchpad (the baseline for the no-fact-lost check).
2. Line references in `CLAUDE.md`.
3. Write the four rules from the old text, then cut `CLAUDE.md` down: Edit tool only, never a shell rewrite.
4. `settings.json` deny rules.
5. PR template.
6. `git rm -r raw wiki` and the `CLAUDE.md` bullet about them.
7. Checks (Proof), `Get-ChangeClass.ps1`, `/code-review` on the diff.
8. Status `done` on the work files, commit by explicit path, push, PR against `main`.

## Risks
- A sentence lost or garbled in the move: the sentence check in Proof compares against the baseline from step 1.
- A rule's frontmatter malformed, so it loads at launch or never: the frontmatter copies Krowi_AchievementFilter's form (`paths:` list of quoted globs); checked after the merge with a fresh session reading `Filters.lua`.
- `settings.json` invalid JSON breaks every session in the repo: parse it with `ConvertFrom-Json` before committing.
- Endings: the post-edit hook keeps git's endings; `git diff --stat` and the bare-LF count check them.

## Proof
- `ConvertFrom-Json` on `.claude/settings.json` succeeds and lists two deny rules.
- The sentence check: 0 sentences of the old `CLAUDE.md` missing from the new `CLAUDE.md` plus the rules.
- `(Get-Item CLAUDE.md).Length` about 21 KB or less.
- `Select-String` prints the code lines that `Krowi_ExtendedVendorUI.lua:108-146` and `BulkPurchaseMixin.lua:187` name.
- `Get-ChangeClass.ps1` says `harness`; no shipped file in the diff. Built: `Deploy.ps1 -WhatIf` from the worktree listed 38 bundled-lib copies, which are this worktree's CRLF checkout against the main checkout's LF files, not this change (`git diff main -- Libs` empty), so the shipped-file check replaced it.
- After the merge: an Edit under `wow-ui-source` refused by permission.