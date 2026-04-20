---
name: headless-validate-bug
description: >
  Headless bug report validation that investigates whether a reported bug is real
  and adds findings to the issue. Use when an agent should autonomously triage a
  bug report from any issue tracker (Jira, Linear, GitHub Issues, etc.) —
  correlating symptoms with recent changes, checking if it happened before,
  verifying against code, and posting structured findings back to the ticket.
  Does not fix the bug — validates and enriches the report.
---

# Bug Report Validation

Autonomous bug validation for headless execution. Apply this to the bug report in the user's prompt. Investigates whether the reported bug is real, what likely caused it, and whether it has happened before. Does not implement a fix.

## Gotchas

- **Jumping to a fix.** This validates and enriches. If confirmed, the findings give the next person everything they need.
- **Trusting the report at face value.** Bug reports can be inaccurate — wrong component, misleading reproduction steps, symptoms mistaken for root cause. Verify against code.
- **Skipping the timeline.** Most bugs start because something changed. Build the timeline before hypothesizing.
- **One research query for everything.** Split the investigation: one call for what changed, one for whether it happened before.

## How This Works

1. **Parse the bug report** via `context_get_urls` (URL), `context_search_issues` or `context_research` (ticket ID), or from the prompt. Extract: reported symptom, expected behavior, affected component, reproduction steps, error messages, when it started, severity.
2. **Investigate** via `context_research`:
   - Recent changes (`effort: medium`): "What changed in [affected component]? PRs merged around when [symptom] started, deployments, config changes, dependency updates."
   - Prior history (`effort: medium`): "Has [this bug or similar symptoms] been reported before? How was it resolved? Known failure modes or edge cases matching [symptom]?"
   - If there's an error message, run a targeted `context_research` (`effort: low`) anchored on the error text. If specific code is named, run a focused `context_research` (`effort: low`) or `context_search_code` (CLI) to understand its expected behavior.
3. **Build a timeline** — correlate findings chronologically: last known good state → what changed → first symptom. What changed between "working" and "broken"?
4. **Hypothesize and verify** — 2-3 candidate root causes. For each: state it, assess likelihood from timeline and history, verify against code. Outcomes: Confirmed / Likely / Not Reproducible / Insufficient Information.
5. **Produce findings report:**
   - **Validation result** — Confirmed / Likely / Not Reproducible / Insufficient Information
   - **Summary** — what was investigated, what was found, confidence level
   - **Timeline** — chronological events with dates, PR numbers, sources
   - **Root cause analysis** — most likely cause with evidence, alternatives ruled out, prior incidents
   - **Next steps** — fix direction, reproduction steps, what to monitor, regression protection
   - **Context for the fixer** — code paths, team patterns, constraints

## Abort Conditions

- **Can't fetch or parse the bug report** — stop and report.
- **No relevant context** for the affected component — produce minimal findings noting what was searched and low confidence.
- **Affected component is completely unclear** — report that triage needs more information.

## Tool Selection

| Question | Preferred tool | Fallback |
|---|---|---|
| Broad investigation of changes and history | `context_research` (`effort: medium`) | — |
| Focused question about specific code | `context_research` (`effort: low`), or `context_search_code` (CLI) | `context_research` with `"Prefer code and implementation results"` instruction |
| Debug an error message | `context_research` (`effort: low`) anchored on the error text | — |
| Fetch ticket by URL | `context_get_urls` | — |
| Fetch ticket by ID or query | `context_search_issues` (CLI) | `context_research` with `"Prefer issue tracker results"` instruction |

Fine-grained tools (`context_search_issues`, `context_search_code`, `context_search_prs`, etc.) are available in the Unblocked CLI. On MCP, fall back to `context_research` with a steering `instruction`.
