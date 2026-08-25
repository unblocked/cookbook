---
name: risk-triage
description: >
  Triage pull requests that Unblocked's risk assessment has labelled
  "risk: medium" or higher. Reads the PR diff, works out what actually
  makes the change risky, applies the safe fixes locally, and presents a
  reviewable diff plus notes — without writing anything back to the PR
  until a human approves. TRIGGER when: the user asks to triage, review,
  or de-risk a risky PR; asks "what risky PRs are open", "why is PR N
  high risk", "reduce the risk on PR N"; a PR carries a `risk:` label
  and the user wants to act on it. DO NOT TRIGGER when: the user wants a
  general code review with no risk label involved; they only want to read
  a PR's contents (use context_get_urls); they are asking why a change
  was made historically (use context_search_prs).
---

# Unblocked Risk Triage

Unblocked's risk assessment labels open pull requests and posts a comment explaining
its reasoning. This skill turns that label into a diff a human can review.

## What you need

**Required:** the GitHub CLI (`gh`), authenticated against the repo · `git` · an agent CLI
that can edit files.

**Optional but recommended:** [Hunk](https://www.hunk.dev) (`npm i -g hunkdiff` or
`brew install hunk`), an MIT-licensed terminal diff reviewer. Without it the triage still
works end to end — you get the diff and the notes grouped per file through `delta`,
`git diff --color`, or plain `git diff`. With it, the notes render *inline above the hunk
each one annotates*, the assessment's reasoning and the agent's sit together on the same
lines, and you can write notes back that the next agent run reads. The recipe detects
which case you're in and adapts.

Risk assessment itself is part of Unblocked Code Review; enable it by adding
`.unblocked/risk-policies.yaml` to your repository —
[docs](https://docs.getunblocked.com/code-review/risk-assessment).

The flow is deliberately staged, with a person in the middle:

```
triage   →  fixes applied locally, diff + notes produced   (nothing written to the PR)
review   →  the engineer reads the annotated diff
approve  →  only then does anything go back to GitHub
```

## The labels

| Label | Treat as |
|---|---|
| `risk: lowest`, `risk: low` | No action |
| `risk: medium` | Triage |
| `risk: high`, `risk: highest` | Triage, and lead with it |

The label lands a few minutes after the PR opens and can change as new commits land.

## Finding labelled PRs

Comma-separated label values are OR'd by GitHub search:

```bash
gh pr list --state open --search 'label:"risk: medium","risk: high","risk: highest" -is:draft'
```

> Repeating `--label` instead (`--label "risk: high" --label "risk: medium"`) **ANDs**
> them and always returns zero results. Use `--search`.

Read the assessment's own reasoning before you start:

```bash
gh pr view <N> --json comments --jq '[.comments[] | select(.author.login=="unblocked") | .body] | last'
```

## Checking the PR out

Work in a scratch worktree. Never switch the user's branch.

**The worktree must live outside the repository working tree.** Putting it under the repo
root leaves an untracked directory in `git status` and risks it being committed or picked
up by tooling. Use a path under the system temp directory:

```bash
WT="${TMPDIR:-/tmp}/risk-triage/<N>"
git fetch --force origin "pull/<N>/head:refs/heads/risk-triage/<N>"
git worktree add "$WT" "risk-triage/<N>"
cd "$WT"
BASE=$(git merge-base origin/main HEAD)   # the branch point, NOT the tip of main
git diff "$BASE"
```

> **Always diff against the merge base.** `git diff origin/main` includes everything the
> base branch gained since this PR branched — on a branch a few days old that turns an
> 11-file review into a 581-file one. `git merge-base origin/main HEAD` is the branch
> point; diffing against it shows the PR's own changes plus anything you apply on top.
> Substitute the repository's real default branch for `main`.

Then immediately check that you got the location right — this is easy to get wrong:

```bash
git -C <the-original-checkout> status --short
```

If your worktree directory shows up there as untracked, you created it inside the repo.
Remove it (`git worktree remove --force <path> && git worktree prune`) and recreate it
under `${TMPDIR:-/tmp}` before going any further.

Write `NOTES.md` at the root of that worktree. Do not invent a location outside it, and do
not write into the user's home or Downloads directory. If you cannot write the file, print
the notes in your reply instead and say so.

> Do **not** fetch several refs at once and then check out `FETCH_HEAD`. On a multi-ref
> fetch the `FETCH_HEAD` revision resolves to the *first* ref — the base branch — so you
> silently analyse the wrong code. Verify before reading anything:
> `git rev-parse HEAD` must equal `gh pr view <N> --json headRefOid --jq .headRefOid`.

Clean up afterwards with `git worktree remove --force "$WT" && git worktree prune` and
`git branch -D risk-triage/<N>`. Confirm `git status` in the original checkout is clean.

## Judging the risk

Re-derive the risk yourself. The rationale is produced by heuristics that pattern-match
on paths and change shapes, so it is often directionally wrong — it flags things that are
safe and misses the thing that isn't. Verify every claim against the code before repeating
it, and say plainly where you disagree.

What genuinely raises risk, in any language:

- **Schema changes that aren't purely additive** — dropping or retyping a column, adding a
  non-null column without a default, anything that rewrites a large table or holds a long
  lock. Adding a nullable column is additive and rollback-safe; say so rather than
  inheriting a "destructive migration" claim.
- **Reachability from production traffic.** A change under a service directory only matters
  if something on a live path calls it. Trace the callers. Admin-only, batch-only, or
  dead code is a different risk class than the request path.
- **New failure modes on write paths** — I/O added inside an existing transaction or
  argument list, where a failure now aborts work that used to succeed.
- **New behaviour the tests don't exercise.** A touched test file is not coverage. Check
  that an assertion actually fails if the new branch breaks.
- **Irreversibility.** If reverting the deploy doesn't undo it, that's the headline risk
  regardless of diff size.
- **Silent failure.** Changes where a mistake yields wrong output rather than an error are
  worse than changes that crash. Look for lookups that return a default on a miss.
- **Behavioural changes not behind a feature flag**, where the repo's conventions expect one.

## Feed what you learn back into the risk policy

The label comes from `.unblocked/risk-policies.yaml` in the repository. Every matching
policy sets a minimum score and the highest match sets the floor, so you can always work
out which policy produced a label.

When your reading of the code and a policy floor diverge, that is usually the policy being
coarse rather than the label being wrong. Say so, and propose the fix: name the policy,
quote its current `criteria`, and give the replacement wording that would separate this
change from the one the policy is actually aimed at.

Keep it to a criteria edit the team can review as a small PR. Do not modify
`risk-policies.yaml` yourself — propose the change in your notes and let a human land it.

## Applying changes

Apply only what you are confident in, directly in the worktree. Keep edits minimal,
mechanical and self-contained: add the missing test, guard the unguarded call, make the
schema change additive. Match the surrounding style.

Do not refactor, do not reformat untouched lines, and do not change what the PR is trying
to do. Anything invasive, or that needs a decision the author has to make, goes in the
notes rather than the diff. A small diff plus a clear note beats a large speculative diff.

## Verification is the author's job

**You cannot know how this repository builds or tests.** Do not guess a build command, and
do not run one unless the user has given you the exact command to use.

Detect the likely command and *report* it instead of running it:

| Present in repo | Likely command |
|---|---|
| `package.json` | `npm test` / the `scripts.test` entry |
| `Cargo.toml` | `cargo test` |
| `go.mod` | `go test ./...` |
| `pyproject.toml`, `tox.ini` | `pytest` |
| `build.gradle`, `build.gradle.kts` | `./gradlew test` (scope to the changed module) |
| `pom.xml` | `mvn test` |
| `Makefile` with a `test:` target | `make test` |

Then state it outright in the notes, near the top so it can't be missed:

> **Unverified.** I did not build or run these changes. Run `<command>` before merging.

Never imply a change is tested when you have not run anything. If the user tells you their
build doesn't work locally, that is fine — say the diff is unverified and move on. It does
not block the triage.

## Presenting the diff

The diff is the deliverable, so it has to be readable. **Before you present anything, run
this** — do not skip it and do not assume the answer:

```bash
command -v hunk && echo HUNK || echo NO_HUNK
```

- **`HUNK`** — check for a live session first. It beats the sidecar whenever the engineer
  is actually at their terminal:

  ```bash
  hunk session list
  ```

  **Session exists** — push the notes into the view they are already looking at:

  ```bash
  cat notes.json | hunk session comment apply --repo "$WT" --stdin --focus
  ```

  Then tell them to press **`a`** if no notes appear. Agent notes are **hidden by
  default** (`hunk.view.toggleAgentNotes`), which looks exactly like a failure to write
  them.

  **No session** — the sidecar takes a **different schema**, and given the wrong one it
  renders zero notes and reports no error. Write `agent-context.json` one directory above
  the worktree:

  ```json
  {"version":1,"files":[
    {"path":"src/a.kt","annotations":[
      {"newRange":[42,42],"author":"triage agent",
       "summary":"One sentence: what this is.",
       "rationale":"The why — what breaks without it."}]}]}
  ```

  `path` and `summary` are required; ranges are 1-based inclusive `[start,end]` integer
  tuples. Then tell them to run
  `hunk diff <merge-base> --agent-context ../agent-context.json --agent-notes`.

  The **session** payload below is a different shape — do not confuse them:

  ```json
  {"comments":[
    {"filePath":"src/a.kt","newLine":42,
     "author":"triage agent",
     "summary":"One sentence: what this is.",
     "rationale":"The why — what breaks without it."}
  ]}
  ```

  Every entry needs `filePath`, `summary`, and **exactly one** of `newLine`, `oldLine`,
  `hunk`, or `hunkNumber`. `rationale` and `author` are optional.

  **Set `author` so the two voices stay separate.** Use `"Unblocked risk assessment"` for
  notes that restate what the assessment claimed, anchored to the lines it actually named,
  and `"triage agent"` for your own. Mark a finding the code has already fixed as
  `(marked outdated)` and name the commit, so the reviewer skips it instead of
  re-litigating it. Where you disagree, put your rebuttal in a `triage agent` note next to
  the assessment's — that pairing is the most useful thing on the screen. Do not invent other field names — a
  different shape is rejected. Write one entry per applied change *and* one per thing you
  chose not to change.

  Two things that silently produce an empty or useless review:

  - **Leave your edits unstaged.** `hunk diff` — like `git diff` — compares the working
    tree against the index. If you `git add` your changes it shows nothing at all. Never
    stage. If you need untracked files to appear, use `git add -N` (intent-to-add only).
  - **Keep `notes.json` out of the worktree.** An untracked file inside it becomes a `+N`
    entry in the very diff it is annotating, and can end up being the only file shown.

  Anchor every `newLine` to a line you actually added or changed — a note on an unchanged
  line has no hunk to attach to. Sanity-check before handing over the command:

  ```bash
  git diff --stat        # must list the files you edited; empty means you staged them
  ```

  Write the file before you mention the command. If you did not write it, do not mention
  it. Never run `hunk diff` or `hunk show` yourself — they are interactive TUIs and will hang
  you until you are killed. `references/review-rendering.md` has the live-session commands
  (`hunk session comment/navigate/highlight`) if you can read it; if you cannot, the shape
  above is all you need.
- **`NO_HUNK`** — read `references/review-rendering.md` for the fallback ordering
  (`delta`, then `git diff --color`, then plain). Mention once that Hunk would render
  these notes inline (`npm i -g hunkdiff`); do not install it yourself.

Either way: never dump a raw unified diff with the notes detached from it, and tie every
note to a `file:line`.

## Notes format

```markdown
# Risk triage — PR #<N>

**Unverified.** I did not build or run these changes. Run `<command>` before merging.

## What actually carries risk
## Changes I applied
## Changes I did not apply
## Irreducible risk and rollout
```

Cite `file:line` throughout. Be short and concrete. If the label is a false positive, say
so plainly — a confident, evidenced "this is mislabelled, and here's why" is more useful
than hedging.

## Rules

- **Never write to the PR without explicit approval.** Not a comment, not a review, not a
  push. Produce the diff and the notes, then ask.
- **Never push to a branch you don't own.** When the user approves code going back, open a
  *follow-up* PR targeting the contributor's branch instead of pushing to it.
- Suggest changes that make the change genuinely safer, never changes that only move the
  label.
