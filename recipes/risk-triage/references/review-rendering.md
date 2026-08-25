# Presenting the triage diff

The diff is the deliverable. If the engineer has to reconstruct which note goes with which
hunk, the triage has failed regardless of how good the analysis was.

Detect what the machine actually has. Don't assume.

## Preferred: Hunk

[Hunk](https://www.hunk.dev) (MIT) is a terminal diff reviewer that renders agent notes
**inline, directly above the hunk each one annotates**, instead of leaving them in a
separate document.

```bash
command -v hunk || echo "not installed — 'npm i -g hunkdiff' or 'brew install hunk'"
```

Offer it if it's missing. Don't install it silently.

> **Never run `hunk diff` or `hunk show` yourself.** They are interactive TUIs. A
> non-interactive agent that runs one will hang until it is killed. They are the *user's*
> commands. You drive Hunk through `hunk session *` and the `--agent-context` sidecar.

When Hunk is installed, load its own skill for the authoritative CLI — it ships one and it
stays current with the binary:

```bash
hunk skill path        # prints the SKILL.md path; read that file
```

### Live session mode — prefer this

If the engineer already has `hunk diff` open, push notes into the view they are looking
at rather than handing them a file. Check with `hunk session list` first.

`hunk session get --repo "$WT"` reports the file and hunk their cursor is on — so when
they ask "why this one?" you answer against that exact hunk, `highlight add` the
expression you are describing, and `navigate` them onward. That is the point of live mode.

It also reports `Agent notes visible: yes|no`. Notes are **hidden by default** — if it
says `no`, tell them to press **`a`**. An invisible note looks exactly like a missing one.

`hunk session reload --repo "$WT" -- diff <merge-base>` swaps what the session shows
without them touching anything — needed when a note must anchor to a file your own edits
never touched.

If the engineer already has `hunk diff` open on the worktree, drive their view directly:

```bash
hunk session list                                  # is there a session at all?
hunk session review --repo . --json                # file and hunk structure
hunk session comment add --repo . --file F --new-line 42 --summary "…" --rationale "…"
hunk session navigate --repo . --file F --hunk 2   # 1-based; moves their viewport
hunk session highlight add --repo . --file F --new-line 42 --start 6 --end 19 --tone warning
```

Batch several notes in one call:

```bash
printf '%s\n' '{"comments":[{"filePath":"F","newLine":42,"summary":"…"}]}' \
  | hunk session comment apply --repo . --stdin
```

This is what makes review conversational: they move through hunks, and when they ask "why
this one?" or "fix it differently", you answer against the exact hunk they're looking at,
highlight the expression you're talking about, and navigate them onward. If there's no live
session, don't guess — ask them to open one, or fall back to the sidecar.

Note: `comment add` accepts only `--old-line` or `--new-line`; the `hunk` / `hunkNumber`
targets exist for `comment apply` payloads. You may clear your own notes but cannot create
or edit the human's.

### Sidecar mode — when no session is open

Write the notes **outside the worktree**, or the file becomes a `+N` entry in the very
diff it annotates. Pass `--agent-notes` or they render hidden.

The engineer isn't watching yet, so write the notes to a file and hand them one command:

```bash
# you write this file
cat > notes.json <<'JSON'
{
  "comments": [
    {
      "filePath": "src/analytics/ActiveUsersService.kt",
      "newLine": 560,
      "summary": "Guards the silent-zero path.",
      "rationale": "If the SQL origin and the code's period grid drift, every lookup misses and reads as zero rather than erroring — no exception, no log."
    }
  ]
}
JSON

# they run this
hunk diff <merge-base> --agent-context ../agent-context.json --agent-notes
```

> The sidecar and the live session take **different schemas**. The sidecar wants
> `{version,files:[{path,annotations:[{summary,newRange:[s,e]}]}]}`; `session comment
> apply` wants `{comments:[{filePath,summary,newLine}]}`. Feed either one the other's
> shape and you get zero notes and no error message.

Each session comment needs `filePath`, `summary`, and **exactly one** location: `newLine`,
`oldLine`, `hunk`, or `hunkNumber`. `rationale` is optional and is where the "why" belongs
— keep `summary` a short sentence, since it's the fallback text and what `comment list`
shows.

## What to annotate

Set `author` on every entry: `"Unblocked risk assessment"` for notes restating what the
assessment claimed, anchored to the lines it actually named, and `"triage agent"` for your
own. Placing your rebuttal beside the claim it answers is the most useful thing on screen.

One note per change you applied, and **one per thing you deliberately did not change**.
The second kind is where most of the value is and the part a plain diff always loses.
Anchor each to the line it concerns, not to the top of the file.

## Fallbacks

Whichever exists, in order:

1. **`delta`** — `git diff | delta`
2. **`git diff --color=always`** into the user's pager
3. **Plain `git diff`**, restructured — never one wall of diff followed by a separate wall
   of notes.

With any fallback, group by file and put each note immediately beside the change:

```markdown
### src/analytics/ActiveUsersService.kt:560

Guards the silent-zero path — if the SQL origin and the code's period grid drift, every
lookup misses and reads as zero rather than erroring.

```diff
-    append("(date_bin('", periodDays, " days', ", createdAt,
+    append("(date_bin('$periodDays days', ", createdAt,
```
```

## What to show first

Lead with the shortest thing that tells the engineer whether to keep reading:

1. One line — is the label right, wrong, or right for the wrong reason?
2. The unverified warning, if you could not run the tests.
3. Files touched, with insertion and deletion counts.
4. Then the annotated diff.

Do not open with the risk rationale you were given. They have already seen it on the PR.
What they want from you is whether it holds up.
