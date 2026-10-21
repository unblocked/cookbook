# Checking a PR out by hand

`scripts/risk-triage.sh` does all of this for you. Use these steps only when triaging inside an agent session without the script.

Work in a scratch worktree outside the repository, and leave the user's branch where it is. A worktree under the repo root shows up as untracked in `git status` and can get committed or picked up by tooling.

```bash
WT="${TMPDIR:-/tmp}/risk-triage/<N>"
git fetch --force origin "pull/<N>/head:refs/heads/risk-triage/<N>"
git worktree add "$WT" "risk-triage/<N>"
cd "$WT"
BASE=$(git merge-base origin/main HEAD)
git diff "$BASE"
```

Substitute the repository's real default branch for `main`.

Diff against the merge base, not `origin/main`. The tip of main includes everything the base branch gained since the PR branched, which can turn an 11-file review into a 581-file one.

Fetch the PR head into its own ref as above. On a multi-ref fetch, `FETCH_HEAD` resolves to the first ref (often the base branch), so checking it out silently analyses the wrong code. Confirm before reading anything: `git rev-parse HEAD` must equal `gh pr view <N> --json headRefOid --jq .headRefOid`.

Then run `git -C <original checkout> status --short`. If the worktree appears there as untracked, it is inside the repo: remove it with `git worktree remove --force <path> && git worktree prune` and recreate it under the temp directory.

Write `NOTES.md` at the root of the worktree. If you cannot write it, print the notes in your reply and say so.

Clean up afterwards with `git worktree remove --force "$WT" && git worktree prune` and `git branch -D risk-triage/<N>`, then confirm the original checkout is clean.
