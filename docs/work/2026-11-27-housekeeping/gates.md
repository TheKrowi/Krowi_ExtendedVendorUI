# Gates: 2026-11-27-housekeeping
Class: harness

| Date | Gate | Question | Recommended | Answer | Outcome |
|---|---|---|---|---|---|
| 2026-11-27 | intent | Housekeeping from the status page: mark shipped folders done, drop the Forever exception | Do it | "let's do housekeeping now. clean up work folders, forever is released so should pass before releases" | took |
| 2026-11-27 | scope | Which folders: the nine shipped in 24.2; tlh-slot-limit and tutorial-buy-arrow stay open | Nine shipped only | (taken without asking: the two open ones are known debt, not done) | auto |
| 2026-11-27 | design | Drop the expired `$untested` entry and keep the empty table, as `chore/2026-11-05-forever-gate` did (cherry-picked) | Keep the table | (taken without asking: the 2026-11-05 commit's design) | auto |
| 2026-11-27 | scope | Open the PR; delete `chore/2026-11-05-forever-gate` after the merge; old branches `cata-classic-test`, `cata-classic-test-2`, `shopping-list`; spike `krowi-options` | Open; delete after merge; ask on the old branches and the spike | "1 yes, 2 ok, 3 delete, 4 drop it" | took |
| 2026-11-27 | merge | PR #132 | Merge | "merge" | took |
