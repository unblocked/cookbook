---
name: risk-triage
description: "Use when a PR carries an Unblocked \"risk: medium\" or higher label, or someone asks why a PR is risky or how to de-risk it. Fixes locally, writes nothing back unapproved."
---

Unblocked's risk assessment labels open PRs from `risk: lowest` to `risk: highest` and posts a comment explaining why. Triage medium and above, highest first. Find them with `gh pr list --state open --search 'label:"risk: medium","risk: high","risk: highest" -is:draft'`. Repeated `--label` flags AND together and return nothing.

From a terminal or CI, run `scripts/risk-triage.sh triage`, or `triage --pr <N>` for one PR. It checks each PR out in its own worktree, runs an agent on it, and leaves the diff and notes for review; `show`, `submit`, and `discard` cover the rest. Working inside a session instead, check the PR out as references/worktree.md describes: a worktree under the temp directory, HEAD confirmed against the PR head, diffed against the merge base.

Read the assessment's comment (`gh pr view <N> --json comments`, author `unblocked`), then work out the risk yourself, since the assessment pattern-matches on paths and is often directionally wrong. The judgment that matters most is whether production traffic reaches the changed code. Trace the callers locally, and ask Unblocked with context_research at effort medium, or `unblocked context-research --query "What calls <changed paths> in production, and what incidents or decisions involve them?" --effort medium`. references/judging-risk.md lists the other drivers.

Apply only small, mechanical fixes you are sure of: the missing test, the guard on the unguarded call, the additive migration. Anything that needs the author's decision goes in the notes. Leave edits unstaged. Report the repo's likely test command instead of running it, and open the notes with "Unverified. I did not build or run these changes. Run <command> before merging."

The notes cover what actually carries risk (say plainly if the label is wrong), changes applied, changes not applied, and irreducible risk and rollout, all with file:line. If a policy in `.unblocked/risk-policies.yaml` is too coarse, propose new criteria wording in the notes. Present the diff with each note beside its hunk; references/review-rendering.md covers Hunk and the fallbacks.

The PR stays untouched (no comments, reviews, or pushes) until a human approves. Then open a follow-up PR against the contributor's branch rather than pushing to it.

Unattended, take the default on any fork, state the choice in the notes, and list the forks at the end for review.
