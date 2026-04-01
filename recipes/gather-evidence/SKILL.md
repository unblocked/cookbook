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

1. **Parse the incident** via `link_resolver` (URL), `data_retrieval` (Jira ticket), `research_task` (Datadog/Sentry incident), or from the prompt. Extract: affected service(s), symptom description, start time, error messages, severity, and any hypotheses to test.
2. **Gather cross-system evidence** via `research_task`:
   - Code and infrastructure evidence (`effort: medium`): "What code paths handle [affected functionality] in [service]? Recent changes to error handling, retry logic, configuration, resource limits? Deployment configs (k8s, terraform, helm)? What do the code changes in recent PRs actually do?"
   - Organizational evidence (`effort: medium`): "Recent Slack discussions, deployment announcements, or on-call notes mentioning [affected service] or [symptom]? Related incidents, Jira tickets, or escalations? Who has been working in this area?"
   - If error messages present: use `failure_debugging` to check for prior occurrences and known resolutions.
   - If specific code is implicated: use `unblocked_context_engine` for focused investigation.
3. **Build correlation timeline** — chronological events from all sources: last known good state → changes (code, config, infra, traffic) → first symptom → escalation. Each event dated and sourced.
4. **Synthesize findings** — translate evidence into plain-language findings. For each finding: what was found, what it means, how confident we are, and what source it came from.
5. **Report evidence** using `references/evidence-template.md`. Present to the user.

## Tool Selection

| Question | Tool | Why This Tool |
|---|---|---|
| Code paths, recent changes, infrastructure context | `research_task` | Cross-source synthesis across code, PRs, and config |
| Slack discussions, deployment announcements, related work | `research_task` | Cross-source synthesis across organizational signals |
| Focused question about a specific code path | `unblocked_context_engine` | One entity, one question — need most relevant context |
| Prior occurrences of an error message | `failure_debugging` | Error-specific history and past fixes |
| Fetch incident details from URL | `link_resolver` | Already have the URL |
| All Jira tickets matching a filter (e.g., open tickets for service) | `data_retrieval` | Need exhaustive list, not just top results |
| Datadog/Sentry incident data for a service | `research_task` | Direct Datadog/Sentry data requires cross-source investigation |
