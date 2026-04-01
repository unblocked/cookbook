---
name: headless-investigate-incident
description: >
  Headless incident investigation planning that formulates multiple hypotheses
  from organizational context. Use when an agent should autonomously plan an
  investigation for an alert, incident ticket, or symptom description —
  correlating the affected system's architecture, recent changes, and historical
  incidents to produce ranked hypotheses with parallel investigation tracks.
  Output is structured for AI agent consumption. Does not gather evidence or
  recommend fixes.
---

# Incident Investigation Planning

Autonomous investigation planning for headless execution. Apply this to the incident in the user's prompt. Produces ranked hypotheses and parallel investigation tracks grounded in organizational context. Does not gather evidence or implement fixes.

## Gotchas

- **Anchoring on the alert name.** Alert names describe symptoms, not causes. Investigate the system, not the alert string.
- **Single-hypothesis thinking.** Always produce 3+ hypotheses. The first plausible explanation is rarely the right one — satisfaction of search is the top failure mode in incident investigation.
- **Ignoring blast radius.** Before deep-diving, assess what else is affected. A single-service alert can mask a platform-wide issue.
- **Skipping duplicate check.** If someone is already investigating this, your plan should build on their work, not duplicate it.

## How This Works

1. **Parse the incident** via `link_resolver` (URL), `data_retrieval` (Jira ticket), `research_task` (Datadog/Sentry incident), or from the prompt. Extract: alert name, affected service(s), symptom description, severity, start time, error messages, impacted metrics.
2. **Check for related investigations** via `data_retrieval` (Jira tickets, Slack) and `research_task` (Datadog/Sentry incidents): all open incidents, active investigations, or recent postmortems for the affected service(s). Note findings to avoid duplicate work.
3. **Hydrate with organizational context** via `research_task`:
   - System understanding (`effort: medium`): "How does [affected service] work? Architecture, dependencies, upstream/downstream services, deployment pipeline, known failure modes, recent incidents."
   - Recent changes (`effort: medium`): "What changed in [affected service] and its dependencies in the last 48-72 hours? PRs merged, deployments, config changes, infrastructure changes, traffic pattern shifts."
4. **Formulate hypotheses** — 3-5 candidate root causes, each with:
   - Hypothesis statement
   - Supporting evidence from context
   - What evidence would confirm or rule it out
   - Investigation steps to test it
5. **Produce structured output** following the output format below.

## Output Format

Output is consumed by an AI agent, not a human. Optimize for token efficiency and actionability. No narrative prose.

```
INCIDENT
  service: [affected service(s)]
  severity: [SEV level]
  start_time: [timestamp]
  symptoms: [one-line description]
  error: [error message if any]

RELATED_INVESTIGATIONS
  - [ticket ID] | [status] | [summary] | [relevance to this incident]

HYPOTHESES
  1. [statement]
     likelihood: HIGH|MEDIUM|LOW
     evidence: [compact citations — PR#, dates, Slack refs]
     confirm_by: [what evidence would prove this]
     rule_out_by: [what evidence would disprove this]
     next_actions: [specific investigation steps]
  2. ...
  3. ...

PARALLEL_TRACKS
  track_1: [hypothesis IDs that can be investigated together]
    actions: [grouped investigation steps]
  track_2: ...

BLAST_RADIUS
  affected_services: [list]
  affected_users: [scope estimate]
  upstream_risk: [services that may be causing this]
  downstream_risk: [services that may be impacted]

ESCALATION_TRIGGERS
  - [condition] → [who to page]
```

## Abort Conditions

- **Can't fetch or parse the incident** — stop and report what was attempted.
- **No relevant context** for the affected service — produce minimal output noting what was searched and LOW confidence on all hypotheses.
- **Affected service is completely unclear** — report that the investigation needs more information before planning.

## Tool Selection

| Question | Tool | Why This Tool |
|---|---|---|
| System architecture, history, failure modes | `research_task` | Cross-source synthesis needed |
| Recent changes and deployments | `research_task` | Need to correlate PRs, deploys, and config across sources |
| All open Jira tickets for a service (exhaustive list) | `data_retrieval` | Need complete filtered list, not just top results |
| Datadog/Sentry incident data for a service | `research_task` | Direct Datadog/Sentry data requires cross-source investigation |
| PRs most related to the affected subsystem | `unblocked_context_engine` | Need relevance-ranked results, not all PRs in a range |
| Focused question about specific service behavior | `unblocked_context_engine` | One entity, one question |
| Fetch incident details from URL | `link_resolver` | Already have the URL |
