# Spec: Act on the Claude Code setup review of 2026-11-28
Intent: [intent.md](intent.md). Status: accepted

## Requirements
1. Every `file:line` reference in `CLAUDE.md` to the repo's own files points at the code it names.
2. Claude Code refuses an Edit or Write under `wow-ui-source`; reads stay allowed.
3. `CLAUDE.md` loads about 21 KB instead of 33 KB: the six blocks that move measure 13.4 KB (Filters 4.0, the `/kevutest` coverage 4.1, Public API 2.9, `Gui/` 0.9, Drawing a slot 0.9, Paging 0.6), less the first sentence and pointer each keeps. The moved text lives in `.claude/rules/*.md` with `paths:` frontmatter, verbatim, and `CLAUDE.md` names each rule file where its text was.
4. A pull request opened on GitHub starts from a template that asks for what Krowi checks: Conventional Commits title, a changelog line, the clients tested.
5. `raw/` and `wiki/` are gone from the tree, or kept, as Krowi decides.

## Root cause
1. Code moved under the references: the boot handler is now lines 108-146 of [Krowi_ExtendedVendorUI.lua](../../../Krowi_ExtendedVendorUI.lua) (`git log -L 101,133` names f23127f and 84d957e of 2026-10-22, the Forever gamepad step-aside, and 0722f6a of 2026-11-18, the fresh-install grid); the Classic Era test is line 187 of [BulkPurchaseMixin.lua](../../../Gui/BulkPurchase/BulkPurchaseMixin.lua). The other references hold, checked 2026-11-28: `Gui/MerchantItemsContainer.lua:18`, `Api/Api.lua:8`, and in `wow-ui-source` live `Blizzard_TutorialTutorials.lua:2397`, `ContainerFrame.lua:1349-1356`, `PaperDollFrame.lua:1626-1629`, `MerchantFrame.lua:275-403`, classic_anniversary TBC `MerchantFrame.lua:196-321`, forever `MerchantFrame.lua:471-474` and `:1184-1187`, `SmartNavigation.lua:1688-1690`.
2. [settings.json:14-17](../../../.claude/settings.json) lists `../wow-ui-source/` in `additionalDirectories`, which grants writes; there is no `deny`.
3. `CLAUDE.md` sections by size (2026-11-28): Architecture 11.2 KB, Clients and loading 5.2 KB, Testing in game 4.8 KB (one line), Taint 3.8 KB, Code style 2.1 KB, Git and release 2.1 KB, the rest under 1.3 KB each. The docs (memory.md): `.claude/rules/*.md` with `paths:` loads only when a matching file is read or edited.
4. No `.github/` folder exists.
5. `CLAUDE.md`, Git and release: "`raw/` and `wiki/` hold LLM-wiki notes from 2026-06-03 ... They are stale ... trust the code over them."

## Design
1. `CLAUDE.md`: `Krowi_ExtendedVendorUI.lua:108-146`, `BulkPurchaseMixin.lua:187`.
2. `.claude/settings.json`: `"deny": ["Edit(//e/World of Warcraft Addon Development/wow-ui-source/**)", "Write(//e/World of Warcraft Addon Development/wow-ui-source/**)"]`, the form Krowi_AchievementFilter uses (permissions.md: a Windows path `E:\x` is written `//e/x`).
3. Four path rules, each section moved verbatim; in `CLAUDE.md` each bullet keeps its first sentence and ends with "Details: `.claude/rules/<file>`":
   - `filters.md` (`Filters.lua`, `Gui/FilterButton/**`, `Gui/SearchBox/**`, `Options/**`, `Tests/**`): the Filters bullet of Architecture.
   - `gui.md` (`Gui/**`, `Plugins/**`, `Tests/**`): Drawing a slot, Paging and the `Gui/` bullet.
   - `plugins.md` (`Api/**`, `Plugins/**`, `Tests/**`): the Public API bullet.
   - `testing.md` (`Tests/**`, `.claude/tools/**`, `.claude/release-gate.ps1`): what `/kevutest` covers. `CLAUDE.md` keeps how to run and read a run.

   Clients and loading, Taint, Localization, Code style and Git and release stay: they apply to any change. `Tests/**` is in every rule because the test routine reads every area.
4. `.github/pull_request_template.md`, about ten lines: what and why, `Closes #`, Conventional Commits title, a `_Packaging/Changelog.md` line in players' words, the clients tested (Retail, Mists, Anniversary, Era, Forever), and that Krowi runs `/kevutest` before a release.
5. Per Krowi's answer: `git rm -r raw wiki` and the `CLAUDE.md` sentence about them removed, or no change.

## Options considered
- **Item 3, four path rules (recommended)** against **one `details.md` rule on `**/*.lua`**: that loads on the first Lua file read, so it saves little. Against **no split**: about 33 KB on every turn, a one-line locale fix included. Against **trimming text**: it loses facts the review did not judge stale. The split's cost: a session that answers from `CLAUDE.md` without opening the code loses the detail. The status page and issue #141 of 2026-11-28 drew on the Filters bullet (`filters.IsKnown`, the Classic scan tooltip) without reading `Filters.lua`. Whether a Grep hit in a file loads its path rule is not stated in the docs read (memory.md says "read or edited"), so the pointer line in `CLAUDE.md` is the guard, not the rule's loading.
- **Smallest change** against all of it: items 1, 2 and 4 only, no split and no deletion.
- **Item 5, delete (recommended)**: `CLAUDE.md` already says to trust the code over them, and git history keeps them. Against **keep**: they cost nothing unless a search finds them.
- **Item 4, a template (recommended)**: ten outside PRs since 2024, cheap. Against **none**: Krowi asks for the changelog line by hand.

## Areas of concern
- Taint and secret values; clients; Blizzard API changes; other addons; saved variables; localization; embedded libraries; player-facing text: none, nothing that ships or deploys changes (`Deploy.ps1:61` leaves out `.claude`, `.github`, `raw`, `wiki` and `docs`).
- Harness: an existing line of `settings.json` changes and the instruction files move, so the class is `harness`. Risk: a fact a session needs before it reads a file sits in a rule and is missed; the first sentences kept in `CLAUDE.md`, with the rule's name, guard it.
- Project settings load from the main checkout, so the deny rules take effect after the merge.

## Verification
- `Select-String` on `CLAUDE.md` for every `` `<repo file>:<line>` `` reference, each line printed and matched by eye.
- No fact lost: every sentence of the old `CLAUDE.md` is found in the new `CLAUDE.md` or in a rule (a script splits the old text into sentences and searches the new files); each moved block is in exactly one rule, and only its first sentence is also in `CLAUDE.md`.
- Pointers into the moved sections: none outside past work folders (`git grep`, repo and kit, 2026-11-28); those stay as history.
- Size of the new `CLAUDE.md` in bytes.
- `Get-ChangeClass.ps1` says `harness`.
- After the merge: an Edit under `wow-ui-source` with an `old_string` that does not exist is refused by permission, not with "string not found".

## Decision
Krowi, 2026-11-28: all five items in one PR; `CLAUDE.md` split into the four path rules; `raw/` and `wiki/` deleted ([gates.md](gates.md)).