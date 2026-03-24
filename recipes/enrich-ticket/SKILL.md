---
name: enrich-ticket
description: >
  Ticket enrichment that gathers organizational context and produces findings
  to attach to an issue before work begins. Use when enriching a Jira, Linear,
  GitHub, or any issue tracker ticket with related PRs, code paths, historical
  context, and prior attempts. Two modes: engineering (code-focused) and support
  (user/product-focused). Does not solve the ticket — only enriches it.
---

# Ticket Enrichment

Gather organizational context for a ticket so whoever picks it up starts informed. Apply this to the ticket in the user's prompt. Does not solve the ticket — produces a structured enrichment document.

## Gotchas

- **Solving the ticket instead of enriching it.** The output is context, not a fix.
- **Context without citations.** Every piece of context must reference its source — a PR number, Slack thread, decision, or doc.
- **Assuming engineering mode.** Read the ticket first. User-reported behavior or product questions need support mode.
- **Enriching without the ticket contents.** Always fetch or parse the full ticket first. The ticket text drives what to research.

## How This Works

1. **Get the ticket** via `link_resolver` (URL), `data_retrieval` (ticket ID like `PROJ-123`), or from the prompt. Extract summary, affected system, severity, reporter, labels, and linked items.
2. **Classify mode** from ticket content — **engineering** (code change, bug, feature, technical task) or **support** (user-reported behavior, product question, escalation). If the user specifies a mode, use that.
3. **Gather context** via `research_task`:
   - Common (`effort: medium`): "How does [affected system] work, what decisions have been made, and has this been reported or attempted before? Include recent PRs, related issues, constraints."
   - Engineering add-on (`effort: medium`): "Code paths for [affected functionality]? Team patterns for [area]? Prior attempts? File paths, utilities, entry points."
   - Support add-on (`effort: medium`): "Expected user-facing behavior for [feature]? Known limitations? Similar reports and resolutions? Workarounds?"
   - If the ticket has an error message, also use `failure_debugging` with it.
4. **Synthesize** using the appropriate template from `references/enrichment-templates.md`. Present to the user for review.

## Tool Selection

| Question | Tool |
|---|---|
| Broad investigation of affected area | `research_task` |
| Focused question about a system | `unblocked_context_engine` |
| Fetch ticket by URL | `link_resolver` |
| Fetch ticket by ID or query | `data_retrieval` |
| Debug an error from the ticket | `failure_debugging` |
