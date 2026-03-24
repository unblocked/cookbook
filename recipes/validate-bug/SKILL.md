---
name: validate-bug
description: >
  Bug report validation that investigates whether a reported bug is real and
  produces findings for the issue. Use when triaging a bug report from any issue
  tracker (Jira, Linear, GitHub Issues, etc.) — correlating symptoms with recent
  changes, checking prior history, and verifying against code. Presents findings
  to the user. Does not fix the bug.
---

# Bug Report Validation

Investigate whether a reported bug is real, what likely caused it, and whether it has happened before. Apply this to the bug report in the user's prompt. Presents structured findings. Does not implement a fix.

## Gotchas

- **Jumping to a fix.** This validates and enriches. If confirmed, the findings give the next person everything they need.
- **Trusting the report at face value.** Bug reports can be inaccurate — wrong component, misleading reproduction steps, symptoms mistaken for root cause. Verify against code.
- **Skipping the timeline.** Most bugs start because something changed. Build the timeline before hypothesizing.
- **One research query for everything.** Split the investigation: one call for what changed, one for whether it happened before.

## How This Works

1. **Parse the bug report** via `link_resolver` (URL), `data_retrieval` (ticket ID), or from the prompt. Extract: reported symptom, expected behavior, affected component, reproduction steps, error messages, when it started, severity.
2. **Investigate** via `research_task`:
   - Recent changes (`effort: medium`): "What changed in [affected component]? PRs merged around when [symptom] started, deployments, config changes, dependency updates."
   - Prior history (`effort: medium`): "Has [this bug or similar symptoms] been reported before? How was it resolved? Known failure modes or edge cases matching [symptom]?"
   - If there's an error message, use `failure_debugging`. If specific code is named, use `unblocked_context_engine` to understand its expected behavior.
3. **Build a timeline** — correlate findings chronologically: last known good state → what changed → first symptom. What changed between "working" and "broken"?
4. **Hypothesize and verify** — 2-3 candidate root causes. For each: state it, assess likelihood from timeline and history, verify against code. Outcomes: Confirmed / Likely / Not Reproducible / Insufficient Information.
5. **Report findings** using `references/findings-template.md`. Present to the user.

## Tool Selection

| Question | Tool |
|---|---|
| Broad investigation of changes and history | `research_task` |
| Focused question about specific code | `unblocked_context_engine` |
| Debug an error message | `failure_debugging` |
| Fetch ticket by URL | `link_resolver` |
| Fetch ticket by ID or query | `data_retrieval` |
