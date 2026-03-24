---
name: headless-code-review
description: >
  Headless code review that gathers organizational context before analyzing a
  diff. Use when an agent performs a PR or branch review autonomously — in CI/CD,
  as a sub-agent, or via `claude -p`. Hydrates the reviewer with team conventions,
  prior art, and related PRs via research_task, then categorizes findings as
  pattern mismatches, reinvented wheels, convention drift, or missing context.
---

# Context-Aware Review

Autonomous code review for headless execution. Apply this to the review task in the user's prompt. Gather organizational context *before* analyzing the diff so findings are grounded in how the team actually works.

## Gotchas

- **Reviewing without hydrating first.** Never flag something without checking context. A pattern that looks wrong may be the team's established approach.
- **Flagging linter-level issues.** Focus on what only a context-aware reviewer can catch — pattern mismatches, reinvented wheels, missing context. Leave style to automated tools.
- **One broad research query for a multi-area PR.** If the diff touches auth and billing, run separate `research_task` calls for each area.
- **Opinions without citations.** Every finding must reference a specific PR, decision, or convention from the research results. "This looks wrong" is not a finding.

## How This Review Works

1. Get the diff — from a PR URL (`link_resolver`), ticket ID (`data_retrieval`), local branch (`git diff`), or the prompt
2. **Hydrate context before reading the diff** — run one `research_task` (`effort: medium`) per area touched: "What conventions and patterns does the team follow for [area]? How have similar changes been structured in recent PRs? What decisions or constraints apply? Are there established utilities that should be reused?"
3. Analyze the diff against hydrated context
4. Categorize and validate findings (see categories below). Validate uncertain findings with a targeted `unblocked_context_engine` query before including them.
5. Produce a structured report

### Finding Categories (ordered by priority)

1. **Pattern Mismatch** — PR uses approach X, team has established pattern Y. Validate: "Does the team use [X or Y] for [this]?"
2. **Reinvented Wheel** — PR creates something that already exists. Validate: "Does a utility for [X] already exist?"
3. **Convention Drift** — Code works but doesn't match team style.
4. **Missing Context** — PR doesn't account for a related system, change, or constraint.
5. **Risk** — Change could cause issues based on historical patterns or known edge cases.

### Report Structure

- **Summary** with recommendation: Approve / Request Changes / Needs Discussion
- **Findings** grouped by category with citations
- **What the PR Does Well** — confirms good instincts
- **Context for the Author** — what they might not have known

## Abort Conditions

- **No diff available** — stop and report.
- **No relevant context** for any area touched — report findings without context grounding and note low confidence.

## Tool Selection

| Question | Tool |
|---|---|
| Broad investigation of an area | `research_task` |
| Validate a specific pattern | `unblocked_context_engine` |
| Recent PRs in same area | `data_retrieval` |
| Fetch a PR/issue by URL | `link_resolver` |
