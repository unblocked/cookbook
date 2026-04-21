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

1. **Get the ticket** via `context_get_urls` (URL), `context_search_issues` or `context_research` (ticket ID like `PROJ-123`), or from the prompt. Extract summary, affected system, severity, reporter, labels, and linked items.
2. **Classify mode** from ticket content — **engineering** (code change, bug, feature, technical task) or **support** (user-reported behavior, product question, escalation). If the user specifies a mode, use that.
3. **Gather context** via `context_research`:
   - Common (`effort: medium`): "How does [affected system] work, what decisions have been made, and has this been reported or attempted before? Include recent PRs, related issues, constraints."
   - Engineering add-on (`effort: medium`): "Code paths for [affected functionality]? Team patterns for [area]? Prior attempts? File paths, utilities, entry points."
   - Support add-on (`effort: medium`): "Expected user-facing behavior for [feature]? Known limitations? Similar reports and resolutions? Workarounds?"
   - If the ticket has an error message, run a targeted `context_research` (`effort: low`) anchored on the error text: "What does the error message [exact text] indicate? Has it been seen before and how was it resolved?"
4. **Synthesize** using the appropriate template from `references/enrichment-templates.md`. Present to the user for review.

## Tool Selection

| Question | Preferred tool | Fallback |
|---|---|---|
| Broad investigation of affected area | `context_research` (`effort: medium`) | — |
| Focused question about a system | `context_research` (`effort: low`) | — |
| Fetch ticket by URL | `context_get_urls` | — |
| Fetch ticket by ID or query | `context_search_issues` (CLI) | `context_research` with `"Prefer issue tracker results"` instruction |
| Debug an error from the ticket | `context_research` (`effort: low`) anchored on the error text | — |

Fine-grained tools (`context_search_issues`, `context_search_prs`, `context_search_code`, etc.) are available in the Unblocked CLI. On MCP, fall back to `context_research` with a steering `instruction` — see the `unblocked-tools-guide` skill for the full mapping.
