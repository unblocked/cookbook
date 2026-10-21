# Presenting the triage diff

The diff is the deliverable. If the engineer has to work out which note goes with which hunk, the triage has failed however good the analysis was. Detect what the machine has with `command -v hunk`.

## Hunk

[Hunk](https://www.hunk.dev) (MIT) is a terminal diff reviewer that renders agent notes inline, above the hunk each one annotates. If it is missing, mention once that `npm i -g hunkdiff` or `brew install hunk` would render notes inline, and leave installing it to the user. When it is installed, `hunk skill path` prints the path of Hunk's own SKILL.md, which stays current with the binary.

`hunk diff` and `hunk show` are interactive TUIs and will hang an agent until it is killed. They are the user's commands. You drive Hunk through `hunk session *` and the `--agent-context` sidecar.

### Live session

Check `hunk session list` first. If the engineer has a session open on the worktree, push notes into the view they are looking at:

```bash
hunk session comment apply --repo "$WT" --stdin --focus < notes.json
```

The session payload is `{"comments":[{"filePath":"src/a.kt","newLine":42,"author":"triage agent","summary":"One sentence.","rationale":"What breaks without it."}]}`. Each entry needs `filePath`, `summary`, and exactly one of `newLine`, `oldLine`, `hunk`, or `hunkNumber`.

Agent notes are hidden by default. `hunk session get --repo "$WT"` reports `Agent notes visible: yes|no`; if no, tell them to press `a`. It also reports the file and hunk under their cursor, so when they ask "why this one?" you can answer against that hunk, `hunk session highlight add` the expression, and `hunk session navigate` them onward. `hunk session reload --repo "$WT" -- diff <merge-base>` changes what the session shows without them touching anything. `comment add` accepts only `--old-line` or `--new-line`.

### Sidecar, when no session is open

The sidecar takes a different schema. Given the session shape it renders zero notes and reports no error.

```json
{"version":1,"files":[{"path":"src/a.kt","annotations":[{"newRange":[42,42],"author":"triage agent","summary":"One sentence.","rationale":"What breaks without it."}]}]}
```

Ranges are 1-based inclusive. Write the file one directory above the worktree, since a file inside it becomes a `+N` entry in the diff it annotates. Write it before you mention the command, then hand them `hunk diff <merge-base> --agent-context ../agent-context.json --agent-notes`.

### Two ways to get an empty review

Staged edits. `hunk diff`, like `git diff`, compares the working tree with the index, so staged changes show nothing. Leave edits unstaged, and use `git add -N` if untracked files need to appear. `git diff --stat` must list the files you edited.

Notes on unchanged lines. A note needs a hunk to attach to, so anchor each `newLine` to a line you added or changed.

## What to annotate

Set `author` on every entry: "Unblocked risk assessment" for notes restating what the assessment claimed, anchored to the lines it named, and "triage agent" for your own. A rebuttal placed beside the claim it answers is the most useful thing on screen. Mark a claim the code already fixes as outdated and name the commit.

Write one note per change you applied and one per thing you deliberately left alone. The second kind is where most of the value is, and a plain diff always loses it.

## Fallbacks

In order: `git diff | delta`, then `git diff --color=always` in the user's pager, then plain `git diff`. With any of them, group by file and put each note directly above its change, headed `file:line`, rather than one wall of diff followed by a wall of notes.

## What to show first

1. One line: is the label right, wrong, or right for the wrong reason?
2. The unverified warning, if you did not run the tests.
3. Files touched, with insertion and deletion counts.
4. The annotated diff.

Skip restating the assessment's rationale; they have already read it on the PR.
