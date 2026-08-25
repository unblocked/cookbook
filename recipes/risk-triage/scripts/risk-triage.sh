#!/usr/bin/env bash
# Triage pull requests labelled by Unblocked's risk assessment.
#
# `triage` never writes to GitHub. It leaves a real worktree, a diff, and notes on
# disk for a human to review. `submit` is the only command that writes back, and it
# asks for confirmation first.
#
#   risk-triage.sh triage                 find labelled PRs, apply fixes in a worktree
#   risk-triage.sh triage --pr 1234       triage one specific PR
#   risk-triage.sh watch                  poll for new ones (still never writes)
#   risk-triage.sh list                   what is waiting for review
#   risk-triage.sh show 1234              print the notes and the diff
#   risk-triage.sh submit 1234 --as pr    push a follow-up PR (asks first)
#   risk-triage.sh discard 1234           throw the triage away
#
# Must be run from inside a checkout of the repository you want to triage.
set -euo pipefail

STATE_DIR="${STATE_DIR:-$HOME/.risk-triage}"
THRESHOLD="${THRESHOLD:-medium}"
SINCE_HOURS="${SINCE_HOURS:-24}"
INTERVAL="${INTERVAL:-300}"
LIMIT="${LIMIT:-100}"
ENGINE="${ENGINE:-auto}"
BOT="${BOT:-unblocked}"

LEVELS=(lowest low medium high highest)

die() { echo "error: $*" >&2; exit 1; }
note() { echo "$*" >&2; }

usage() { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; }

rank() {
  local i
  for i in "${!LEVELS[@]}"; do [[ "${LEVELS[$i]}" == "$1" ]] && { echo "$i"; return 0; }; done
  return 1
}

# --- repo binding -----------------------------------------------------------
# The GitHub repo is always derived from the checkout we are standing in, so the
# PR we fetch and the PR we read metadata for can never diverge.
resolve_repo() {
  git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null) \
    || die "could not resolve the GitHub repo for this checkout (is 'gh' authenticated?)"
  BASE_BRANCH=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
  REMOTE=$(git remote 2>/dev/null | grep -qx origin && echo origin || git remote | head -1)
  [[ -n "$REMOTE" ]] || die "this checkout has no git remote"
}

triage_dir() { echo "$STATE_DIR/triage/$1"; }

# --- discovery --------------------------------------------------------------
build_search() {
  local min labels=() i
  min=$(rank "$THRESHOLD") || die "bad threshold '$THRESHOLD' (expected one of: ${LEVELS[*]})"
  for ((i = min; i < ${#LEVELS[@]}; i++)); do labels+=("\"risk: ${LEVELS[$i]}\""); done
  echo "-is:draft label:$(IFS=,; echo "${labels[*]}")"
}

# Highest label wins, so a PR carrying a stale lower label is not under-reported.
highest_level_jq() {
  cat <<'JQ'
  ([.labels[].name | select(startswith("risk: ")) | ltrimstr("risk: ")] as $l
   | ["highest","high","medium","low","lowest"] | map(select(. as $x | $l | index($x))) | first) // ""
JQ
}

find_prs() {
  local cutoff search count
  cutoff=$(date -u -v-"${SINCE_HOURS}"H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
        || date -u -d "${SINCE_HOURS} hours ago" +%Y-%m-%dT%H:%M:%SZ)
  search=$(build_search)

  local json
  json=$(gh pr list --repo "$REPO" --state open --limit "$LIMIT" --search "$search" \
           --json number,title,author,createdAt,labels,headRefName)

  count=$(jq 'length' <<<"$json")
  [[ "$count" -ge "$LIMIT" ]] && note "warning: hit the --limit of $LIMIT; older labelled PRs were not considered"

  jq -r --arg cutoff "$cutoff" "
    [.[] | select(.createdAt >= \$cutoff)]
    | .[] | [.number, $(highest_level_jq), .author.login, .headRefName, .title] | @tsv" <<<"$json"
}

# --- the agent --------------------------------------------------------------
resolve_engine() {
  if [[ "$ENGINE" == "auto" ]]; then
    if command -v claude >/dev/null 2>&1; then ENGINE=claude
    elif command -v codex >/dev/null 2>&1; then ENGINE=codex
    else die "need either 'claude' or 'codex' on PATH"; fi
  fi
  [[ "$ENGINE" == claude || "$ENGINE" == codex ]] || die "unknown engine '$ENGINE' (claude|codex)"
  command -v "$ENGINE" >/dev/null 2>&1 || die "'$ENGINE' is not on PATH"
}

agent_prompt() {
  local num="$1" level="$2" rationale="$3"
  cat <<EOF
PR #$num in $REPO was labelled "risk: $level" by Unblocked's automated risk assessment.

The assessment said:
$rationale

You are in a worktree checked out on this PR's head. The base branch is
'$BASE_BRANCH'. Read the diff with:

    BASE=\$(git merge-base $REMOTE/$BASE_BRANCH HEAD)
    git diff \$BASE

Diff against the merge base, never against $REMOTE/$BASE_BRANCH directly — the latter
includes everything the base branch has gained since this PR branched, which can turn an
11-file review into a 581-file one.

The rationale above comes from heuristics that pattern-match on paths and migration
syntax. It is often directionally wrong. Verify every claim against the actual code
before repeating it, and say plainly where you disagree.

Work out what genuinely makes this change risky: migrations that are not purely
additive, code actually reachable from production traffic, new failure modes on
write paths, new behaviour the tests do not exercise, changes that cannot be rolled
back, and behavioural changes not behind a feature flag.

Then do two things.

1. APPLY the risk-reducing changes you are confident in, directly in this worktree.
   Keep them minimal, mechanical and self-contained: add the missing test, guard the
   unguarded call, make the migration additive. Match the surrounding code style.
   Do NOT refactor, do NOT reformat untouched lines, and do NOT change the PR's
   intent. If a fix would be invasive or needs a decision the author has to make,
   leave the code alone and describe it in the notes instead.

2. Write your notes to NOTES.md in the root of this worktree, in this shape:

# Risk triage — PR #$num

## What actually carries risk
<your own read; state where you disagree with the assessment and why>

## Changes I applied
<one bullet per edit: file:line, what it does, which risk driver it removes.
 write "None." if you applied nothing>

## Changes I did not apply
<the invasive or judgement-call ones, with enough detail for the author to act>

## Irreducible risk and rollout
<what cannot be engineered away, and the rollout that handles it>

3. If your reading of the code and a matching risk policy diverge, add a note that
   proposes the policy fix: name the policy from .unblocked/risk-policies.yaml, quote its
   current criteria, and give replacement wording that separates this change from the one
   the policy is aimed at. Do not edit risk-policies.yaml yourself.

4. Write notes.json in the root of this worktree — the same findings, anchored to
   lines so a diff viewer can render them inline:

{"comments":[
  {"filePath":"<path from repo root>","newLine":<line in the NEW file>,
   "author":"triage agent",
   "summary":"<one sentence: what this is>",
   "rationale":"<why — what breaks without it>"}
]}

   Every entry needs filePath, summary, and exactly one of newLine / oldLine / hunk /
   hunkNumber. Do not invent other field names. One entry per change you applied AND one
   per thing you deliberately did not change. Anchor every newLine to a line you actually
   added or changed — a note on an unchanged line will not be rendered.

   Set author on every entry: "Unblocked risk assessment" for notes that restate what the
   assessment claimed, anchored to the lines it actually named, and "triage agent" for
   your own. Where a finding is already fixed, say so and name the commit. Where you
   disagree, put the rebuttal in a "triage agent" note beside the claim it answers.

Cite file:line throughout. Be short and concrete. If the label is a false positive,
say so plainly. Leave NOTES.md and notes.json untracked; do not git add them.
EOF
}

run_agent() {
  local wt="$1"
  case "$ENGINE" in
    claude)
      # The deny list is load-bearing. A linked worktree inherits the parent repo's
      # .claude/settings.local.json, which commonly allows Bash(git *) and Bash(gh pr *)
      # — enough for the agent to comment on or push to the PR. Deny beats allow.
      ( cd "$wt" && claude -p --permission-mode acceptEdits \
          --allowedTools 'Read,Grep,Glob,Edit,Write,Bash(git diff:*),Bash(git log:*),Bash(git show:*),Bash(git status:*)' \
          --disallowedTools 'Bash(gh:*),Bash(git push:*),Bash(git commit:*),Bash(git checkout:*),Bash(git switch:*),Bash(git branch:*),Bash(git reset:*),Bash(git remote:*),Bash(curl:*),Bash(wget:*),WebFetch,WebSearch' \
          >/dev/null )
      ;;
    codex)
      codex exec --sandbox workspace-write --cd "$wt" --skip-git-repo-check - >/dev/null
      ;;
  esac
}

# Keep only notes anchored to a line that actually appears in the review diff. A note on an
# unchanged line has no hunk to attach to and is silently discarded by the viewer.
validate_notes() {
  local src="$1" diff="$2" out="$3"
  python3 - "$src" "$diff" "$out" <<'PYEOF'
import json, re, sys
src, diff, out = sys.argv[1:4]
try:
    comments = json.load(open(src))["comments"]
except Exception as exc:
    print(f"    notes.json unreadable: {exc}", file=sys.stderr); sys.exit(1)

valid = set(); path = None; line = 0
for raw in open(diff, encoding="utf8", errors="replace"):
    if raw.startswith("+++ b/"): path = raw[6:].strip(); continue
    m = re.match(r"@@ -\d+(?:,\d+)? \+(\d+)", raw)
    if m: line = int(m.group(1)); continue
    if raw.startswith("+") and not raw.startswith("+++"): valid.add((path, line)); line += 1
    elif not raw.startswith("-") and path: line += 1

kept, dropped = [], []
for c in comments:
    loc = [k for k in ("newLine", "oldLine", "hunk", "hunkNumber") if k in c]
    if not (c.get("filePath") and c.get("summary") and len(loc) == 1):
        dropped.append((c.get("filePath", "?"), "malformed")); continue
    if "newLine" in c and (c["filePath"], c["newLine"]) not in valid:
        near = sorted(n for (f, n) in valid if f == c["filePath"])
        if not near:
            dropped.append((c["filePath"], "file not in diff")); continue
        c["newLine"] = min(near, key=lambda n: abs(n - c["newLine"]))
    kept.append(c)

for path_, why in dropped:
    print(f"    dropped note on {path_}: {why}", file=sys.stderr)
if not kept: sys.exit(1)
json.dump({"comments": kept}, open(out, "w"), indent=2)

# `hunk diff --agent-context` uses a DIFFERENT schema from `hunk session comment apply`:
# {files:[{path, annotations:[{summary, newRange:[s,e]}]}]}. Given the wrong shape it
# renders zero notes and reports no error, so emit the sidecar form separately.
import collections, os
byfile = collections.OrderedDict()
for c in kept:
    a = {"summary": c["summary"]}
    if c.get("rationale"): a["rationale"] = c["rationale"]
    if c.get("author"):    a["author"] = c["author"]
    if "newLine" in c:     a["newRange"] = [c["newLine"], c["newLine"]]
    elif "oldLine" in c:   a["oldRange"] = [c["oldLine"], c["oldLine"]]
    byfile.setdefault(c["filePath"], []).append(a)
json.dump({"version": 1,
           "files": [{"path": p_, "annotations": a_} for p_, a_ in byfile.items()]},
          open(os.path.join(os.path.dirname(out), "agent-context.json"), "w"), indent=2)
print(f"    {len(kept)} notes anchored" + (f", {len(dropped)} dropped" if dropped else ""), file=sys.stderr)
PYEOF
}

# --- triage -----------------------------------------------------------------
triage_one() {
  local num="$1" level="$2" author="$3" head_ref="$4" title="$5"
  [[ -n "$num" && "$num" =~ ^[0-9]+$ ]] || { note "skipping malformed PR number '$num'"; return 1; }
  [[ -n "$level" ]] || level=unknown

  local dir wt rationale
  dir=$(triage_dir "$num"); wt="$dir/worktree"

  echo "==> PR #$num [risk: $level] by $author — $title"

  rationale=$(gh pr view "$num" --repo "$REPO" --json comments \
    --jq "[.comments[] | select(.author.login==\"$BOT\") | .body] | last // \"(no assessment comment found)\"")

  # Clear any previous attempt, including a registration left behind by a crash.
  discard_one "$num" quiet
  mkdir -p "$dir"

  # Fetch the PR head into its own ref. A multi-ref fetch leaves the FETCH_HEAD
  # revision pointing at the FIRST ref fetched — the base branch — so checking out
  # FETCH_HEAD silently lands on main instead of the PR.
  git fetch --quiet "$REMOTE" "$BASE_BRANCH" \
    || { note "    could not fetch $BASE_BRANCH"; return 1; }
  git fetch --quiet --force "$REMOTE" "pull/$num/head:refs/heads/risk-triage/$num" \
    || { note "    could not fetch PR #$num"; return 1; }
  git worktree add --quiet "$wt" "risk-triage/$num" \
    || { note "    could not create worktree for PR #$num"; return 1; }

  # Refuse to hand the agent a worktree that is not actually on the PR head.
  local want got
  want=$(gh pr view "$num" --repo "$REPO" --json headRefOid --jq .headRefOid)
  got=$(git -C "$wt" rev-parse HEAD)
  [[ "$want" == "$got" ]] \
    || { note "    worktree is at $got but PR head is $want — aborting"; return 1; }

  agent_prompt "$num" "$level" "$rationale" | run_agent "$wt" \
    || { note "    agent failed on PR #$num"; return 1; }

  # NOTES.md is the agent's report; keep it out of the diff we show and submit.
  [[ -f "$wt/NOTES.md" ]] && mv "$wt/NOTES.md" "$dir/NOTES.md"
  # The sidecar must live outside the worktree, else it appears as an untracked +N file
  # in the very diff it is annotating.
  local base; base=$(cd "$wt" && git merge-base "$REMOTE/$BASE_BRANCH" HEAD)
  if [[ -f "$wt/notes.json" ]]; then
    ( cd "$wt" && git diff "$base" ) > "$dir/review.diff"
    if validate_notes "$wt/notes.json" "$dir/review.diff" "$dir/notes.json"; then
      rm -f "$wt/notes.json"
    else
      rm -f "$wt/notes.json"; note "    (agent produced no usable notes.json sidecar)"
    fi
  fi
  # Intent-to-add, NOT `git add -A`: staging makes `git diff` — and `hunk diff` — show
  # nothing, because both compare the working tree against the index. Leave the changes
  # unstaged so any diff viewer pointed at this worktree just works.
  ( cd "$wt" && git add -N -A -- ':!NOTES.md' && git diff ) > "$dir/changes.diff"

  { echo "repo=$REPO"; echo "level=$level"; echo "author=$author";
    echo "head_ref=$head_ref"; echo "base=$BASE_BRANCH"; echo "title=$title"; } > "$dir/meta"

  local added
  added=$(cd "$wt" && git diff --shortstat || true)
  if [[ -s "$dir/changes.diff" ]]; then
    echo "    diff:     $dir/changes.diff  (${added# })"
  else
    echo "    diff:     (no code changes — notes only)"
  fi
  echo "    notes:    $dir/NOTES.md"
  echo "    worktree: $wt"
  if command -v hunk >/dev/null 2>&1; then
    if [[ -f "$dir/notes.json" ]]; then
      # A live session beats the sidecar: the notes land in the view the engineer already
      # has open. Agent notes are hidden by default, hence --agent-notes on the fallback.
      if hunk session list 2>/dev/null | grep -qF "$wt"; then
        hunk session comment apply --repo "$wt" --stdin --focus < "$dir/notes.json" >/dev/null 2>&1 \
          && echo "    review:   pushed $(jq '.comments|length' "$dir/notes.json") notes into your open hunk session (press 'a' if hidden)" \
          || echo "    review:   cd $wt && hunk diff $base --agent-context $dir/agent-context.json --agent-notes"
      else
        echo "    review:   cd $wt && hunk diff $base --agent-context $dir/agent-context.json --agent-notes"
      fi
    else
      echo "    review:   cd $wt && hunk diff $base"
    fi
  fi
  echo "    review:   $(basename "$0") show $num     then: $(basename "$0") submit $num --as pr"
}

cmd_triage() {
  local replay=false only_pr=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --threshold) THRESHOLD="$2"; shift 2 ;;
      --since)     SINCE_HOURS="$2"; shift 2 ;;
      --limit)     LIMIT="$2"; shift 2 ;;
      --engine)    ENGINE="$2"; shift 2 ;;
      --pr)        only_pr="$2"; shift 2 ;;
      --replay)    replay=true; shift ;;
      *) die "unknown flag for triage: $1" ;;
    esac
  done
  # Validate before any subshell swallows the failure.
  rank "$THRESHOLD" >/dev/null || die "bad threshold '$THRESHOLD' (expected one of: ${LEVELS[*]})"
  [[ "$LIMIT" =~ ^[0-9]+$ ]] || die "--limit must be a number, got '$LIMIT'"
  [[ "$SINCE_HOURS" =~ ^[0-9]+$ ]] || die "--since must be a number of hours, got '$SINCE_HOURS'"
  [[ -z "$only_pr" || "$only_pr" =~ ^[0-9]+$ ]] || die "--pr must be a number, got '$only_pr'"

  resolve_repo; resolve_engine
  mkdir -p "$STATE_DIR/triage"; touch "$STATE_DIR/seen.txt"
  git worktree prune

  if [[ -n "$only_pr" ]]; then
    local row
    row=$(gh pr view "$only_pr" --repo "$REPO" --json number,title,author,labels,headRefName \
          --jq "[.number, $(highest_level_jq), .author.login, .headRefName, .title] | @tsv")
    IFS=$'\t' read -r num level author head_ref title <<<"$row"
    triage_one "$num" "$level" "$author" "$head_ref" "$title"
    return
  fi

  local found=0
  while IFS=$'\t' read -r num level author head_ref title; do
    [[ -n "$num" ]] || continue
    if [[ "$replay" == false ]] && grep -qx "$num" "$STATE_DIR/seen.txt"; then continue; fi
    found=1
    if triage_one "$num" "$level" "$author" "$head_ref" "$title"; then
      [[ "$replay" == false ]] && echo "$num" >> "$STATE_DIR/seen.txt"
    fi
  done < <(find_prs)
  [[ "$found" == 0 ]] && echo "nothing new at risk >= $THRESHOLD in the last ${SINCE_HOURS}h"
  return 0
}

cmd_watch() {
  resolve_repo
  echo "watching $REPO for risk >= $THRESHOLD every ${INTERVAL}s — triage only, never writes to GitHub"
  while true; do cmd_triage "$@" || true; sleep "$INTERVAL"; done
}

# --- review -----------------------------------------------------------------
cmd_list() {
  local dir num
  shopt -s nullglob
  local dirs=("$STATE_DIR"/triage/*/)
  [[ ${#dirs[@]} -eq 0 ]] && { echo "no triages awaiting review"; return 0; }
  printf '%-8s %-9s %-16s %s\n' PR RISK AUTHOR STATUS
  for dir in "${dirs[@]}"; do
    num=$(basename "$dir")
    local level author status
    level=$(sed -n 's/^level=//p' "$dir/meta" 2>/dev/null || echo "?")
    author=$(sed -n 's/^author=//p' "$dir/meta" 2>/dev/null || echo "?")
    if [[ -s "$dir/changes.diff" ]]; then status="diff ready"; else status="notes only"; fi
    printf '%-8s %-9s %-16s %s\n' "$num" "$level" "$author" "$status"
  done
}

cmd_show() {
  local num="${1:-}"; [[ -n "$num" ]] || die "usage: $(basename "$0") show <pr-number>"
  local dir; dir=$(triage_dir "$num")
  [[ -d "$dir" ]] || die "no triage for PR #$num — run: $(basename "$0") triage --pr $num"
  [[ -f "$dir/NOTES.md" ]] && cat "$dir/NOTES.md"
  echo
  if [[ -s "$dir/changes.diff" ]]; then
    echo "--- proposed diff -------------------------------------------------------"
    cat "$dir/changes.diff"
  else
    echo "(no code changes were applied — notes only)"
  fi
  echo
  echo "worktree: $dir/worktree"
}

# --- write-back (the only commands that touch GitHub) -----------------------
confirm() {
  local prompt="$1" reply
  [[ "$ASSUME_YES" == true ]] && return 0
  [[ -t 0 || -e /dev/tty ]] || die "refusing to write without a terminal to confirm on (pass --yes)"
  read -r -p "$prompt [y/N] " reply < /dev/tty
  [[ "$reply" == [yY] || "$reply" == [yY][eE][sS] ]]
}

cmd_submit() {
  local num="${1:-}"; shift || true
  [[ -n "$num" ]] || die "usage: $(basename "$0") submit <pr-number> --as comment|pr [--yes]"
  local as="" ; ASSUME_YES=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --as)  as="$2"; shift 2 ;;
      --yes) ASSUME_YES=true; shift ;;
      *) die "unknown flag for submit: $1" ;;
    esac
  done
  [[ "$as" == comment || "$as" == pr ]] || die "--as must be 'comment' or 'pr'"

  local dir; dir=$(triage_dir "$num")
  [[ -d "$dir" ]] || die "no triage for PR #$num"
  resolve_repo
  local level head_ref
  level=$(sed -n 's/^level=//p' "$dir/meta"); head_ref=$(sed -n 's/^head_ref=//p' "$dir/meta")

  echo "About to write to $REPO PR #$num (risk: $level)."
  echo "Review it first with: $(basename "$0") show $num"

  case "$as" in
    comment)
      confirm "Post the triage notes as a comment on #$num?" || { echo "aborted"; return 1; }
      { echo "## Risk triage (automated, \`risk: $level\`)"; echo
        cat "$dir/NOTES.md"
        if [[ -s "$dir/changes.diff" ]]; then
          echo; echo "<details><summary>Suggested diff</summary>"; echo
          echo '```diff'; cat "$dir/changes.diff"; echo '```'; echo "</details>"
        fi
      } | gh pr comment "$num" --repo "$REPO" --body-file -
      echo "commented on #$num"
      ;;
    pr)
      [[ -s "$dir/changes.diff" ]] || die "no code changes to submit for #$num (notes only — use --as comment)"
      local branch="risk-triage/$num"
      confirm "Push '$branch' and open a PR into '$head_ref'?" || { echo "aborted"; return 1; }
      ( cd "$dir/worktree"
        git add -A -- ':!NOTES.md'
        git -c user.name="$(git config user.name)" -c user.email="$(git config user.email)" \
            commit --quiet -m "Reduce risk on #$num" || true
        git push --quiet -u "$REMOTE" "$branch" --force-with-lease )
      gh pr create --repo "$REPO" --base "$head_ref" --head "$branch" \
        --title "Risk reduction for #$num" --body-file "$dir/NOTES.md"
      ;;
  esac
}

discard_one() {
  local num="$1" quiet="${2:-}"
  local dir; dir=$(triage_dir "$num")
  git worktree prune
  [[ -d "$dir/worktree" ]] && git worktree remove --force "$dir/worktree" >/dev/null 2>&1 || true
  git worktree prune
  git branch -D "risk-triage/$num" >/dev/null 2>&1 || true
  rm -rf "$dir"
  [[ "$quiet" == quiet ]] || echo "discarded triage for #$num"
}

cmd_discard() {
  local num="${1:-}"; [[ -n "$num" ]] || die "usage: $(basename "$0") discard <pr-number>"
  resolve_repo
  discard_one "$num"
}

# --- dispatch ---------------------------------------------------------------
ASSUME_YES=false
command -v gh >/dev/null 2>&1 || die "need the GitHub CLI ('gh') on PATH"
command -v jq >/dev/null 2>&1 || die "need 'jq' on PATH"

cmd="${1:-}"; shift || true
case "$cmd" in
  triage)  cmd_triage "$@" ;;
  watch)   cmd_watch "$@" ;;
  list)    cmd_list "$@" ;;
  show)    cmd_show "$@" ;;
  submit)  cmd_submit "$@" ;;
  discard) cmd_discard "$@" ;;
  ""|-h|--help|help) usage ;;
  *) die "unknown command '$cmd' (try --help)" ;;
esac
