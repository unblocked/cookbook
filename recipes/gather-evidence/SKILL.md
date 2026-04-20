---
name: gather-evidence
description: >
  Evidence gathering that correlates signals from code, infrastructure, and
  organizational sources for an incident. Use when an alert, incident, or
  symptom needs cross-system evidence collection — building a correlation
  timeline, evaluating hypotheses against evidence, and presenting findings
  in plain language. Presents the evidence report to the user. Does not
  plan the investigation or recommend fixes.
---

# Incident Evidence Gathering

Gather and correlate evidence for the incident in the user's prompt. Produces a correlation timeline and plain-language findings from code, infrastructure, and organizational sources. Presents the report to the user. Does not plan the investigation or implement fixes.

## Gotchas

- **Stopping at the first confirming signal.** Gather evidence for AND against each hypothesis. Confirmation bias is the top failure mode in incident investigation.
- **Presenting raw data instead of findings.** The output should explain what the evidence means, not dump log lines. The consumer may not have telemetry expertise.
- **Missing the timeline.** Without chronology, evidence is just a pile of facts. Always build a timeline: last known good → what changed → first symptom.
- **Ignoring organizational signals.** Code and infra aren't the only evidence. Slack discussions, deployment announcements, and on-call handoffs often contain the key insight.

## How This Works

1. **Parse the incident** via `context_get_urls` (URL), `context_search_issues` or `context_research` (Jira ticket), `context_research` (Datadog/Sentry incident), or from the prompt. Extract: affected service(s), symptom description, start time, error messages, severity, and any hypotheses to test.
2. **Gather cross-system evidence** via `context_research`:
   - Code and infrastructure evidence (`effort: medium`): "What code paths handle [affected functionality] in [service]? Recent changes to error handling, retry logic, configuration, resource limits? Deployment configs (k8s, terraform, helm)? What do the code changes in recent PRs actually do?"
   - Organizational evidence (`effort: medium`): "Recent Slack discussions, deployment announcements, or on-call notes mentioning [affected service] or [symptom]? Related incidents, Jira tickets, or escalations? Who has been working in this area?"
   - If error messages are present: run a targeted `context_research` (`effort: low`) anchored on the error text to surface prior occurrences and known resolutions.
   - If specific code is implicated: use `context_research` (`effort: low`) or `context_search_code` (CLI) for focused investigation.
3. **Build correlation timeline** — chronological events from all sources: last known good state → changes (code, config, infra, traffic) → first symptom → escalation. Each event dated and sourced.
4. **Synthesize findings** — translate evidence into plain-language findings. For each finding: what was found, what it means, how confident we are, and what source it came from.
5. **Report evidence** using `references/evidence-template.md`. Present to the user.

## Tool Selection

| Question | Preferred tool | Fallback / Why |
|---|---|---|
| Code paths, recent changes, infrastructure context | `context_research` (`effort: medium`) | Cross-source synthesis across code, PRs, and config |
| Slack discussions, deployment announcements, related work | `context_search_messages` (CLI) | `context_research` with `"Prefer Slack threads and team conversations"` instruction |
| Focused question about a specific code path | `context_search_code` (CLI) | `context_research` (`effort: low`) with `"Prefer code and implementation results"` instruction |
| Prior occurrences of an error message | `context_research` (`effort: low`) anchored on the error text | Error-specific history and past fixes |
| Fetch incident details from URL | `context_get_urls` | Already have the URL |
| All Jira tickets matching a filter (e.g., open tickets for service) | `context_search_issues` (CLI) | `context_research` with `"Prefer issue tracker results"` instruction |
| Datadog/Sentry incident data for a service | `context_research` (`effort: medium`) | Direct incident-platform data requires cross-source investigation |

Fine-grained tools (`context_search_code`, `context_search_messages`, `context_search_issues`, etc.) are available in the Unblocked CLI. On MCP, fall back to `context_research` with a steering `instruction` — see the `unblocked-tools-guide` skill for the full mapping.
