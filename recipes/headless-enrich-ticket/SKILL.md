---
name: headless-enrich-ticket
description: >
  Headless ticket enrichment that gathers organizational context and attaches
  findings to an issue before work begins. Use when an agent should autonomously
  enrich a Jira, Linear, GitHub, or any issue tracker ticket with related PRs,
  code paths, historical context, and prior attempts. Two modes: engineering
  (code-focused) and support (user/product-focused). Does not solve the ticket —
  only enriches it so whoever picks it up starts with full context.
---

# Ticket Enrichment

Autonomous ticket enrichment for headless execution. Apply this to the ticket in the user's prompt. Produces a structured enrichment document — does not solve the ticket.

## Gotchas

- **Solving the ticket instead of enriching it.** The output is context, not a fix.
- **Context without citations.** Every piece of context must reference its source — a PR number, Slack thread, decision, or doc.
- **Assuming engineering mode.** Read the ticket first. User-reported behavior or product questions need support mode.
- **Enriching without the ticket contents.** Always fetch or parse the full ticket first. The ticket text drives what to research.

## How This Works

1. **Get the ticket** via `context_get_urls` (URL), `context_search_issues` or `context_research` (ticket ID like `PROJ-123`), or from the prompt. Extract summary, affected system, severity, reporter, labels, and linked items.
2. **Classify mode** from ticket content — **engineering** (code change, bug, feature, technical task) or **support** (user-reported behavior, product question, escalation). If the prompt specifies a mode, use that.
3. **Gather context** via `context_research`:
   - Common (`effort: medium`): "How does [affected system] work, what decisions have been made, and has this been reported or attempted before? Include recent PRs, related issues, constraints."
   - Engineering add-on (`effort: medium`): "Code paths for [affected functionality]? Team patterns for [area]? Prior attempts? File paths, utilities, entry points."
   - Support add-on (`effort: medium`): "Expected user-facing behavior for [feature]? Known limitations? Similar reports and resolutions? Workarounds?"
   - If the ticket has an error message, run a targeted `context_research` (`effort: low`) anchored on the error text.
4. **Synthesize** the enrichment document matching the classified mode.

### Engineering Enrichment

- **Affected systems** — components, services, code paths with file references
- **Relevant code** — key files, entry points, utilities
- **Related work** — PRs, tickets, decisions with summaries
- **Historical context** — prior attempts, rejected approaches, constraints
- **Suggested direction** — based on team patterns, just orientation

### Support Enrichment

- **Product behavior** — how the feature works, known limitations
- **User impact** — scope, workarounds
- **Related incidents** — similar reports and resolutions
- **Resolution history** — how the team has handled this before
- **Ownership** — which team, domain experts

## Abort Conditions

- **Can't fetch or parse the ticket** — stop and report.
- **No relevant context** — produce minimal enrichment noting low confidence and what was searched.

## Tool Selection

| Question | Preferred tool | Fallback |
|---|---|---|
| Broad investigation of affected area | `context_research` (`effort: medium`) | — |
| Focused question about a system | `context_research` (`effort: low`) | — |
| Fetch ticket by URL | `context_get_urls` | — |
| Fetch ticket by ID or query | `context_search_issues` (CLI) | `context_research` with `"Prefer issue tracker results"` instruction |
| Debug an error from the ticket | `context_research` (`effort: low`) anchored on the error text | — |

Fine-grained tools (`context_search_issues`, `context_search_prs`, `context_search_code`, etc.) are available in the Unblocked CLI. On MCP, fall back to `context_research` with a steering `instruction`.
