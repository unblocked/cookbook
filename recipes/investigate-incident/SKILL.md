---
name: investigate-incident
description: >
  Incident investigation planning that formulates multiple hypotheses from
  organizational context. Use when an alert, incident ticket, or symptom
  description needs a structured investigation plan — correlating the affected
  system's architecture, recent changes, and historical incidents to produce
  ranked hypotheses with parallel investigation tracks. Presents the plan
  to the user. Does not gather evidence or recommend fixes.
---

# Incident Investigation Planning

Plan an investigation for the incident in the user's prompt. Produces ranked hypotheses and parallel investigation tracks grounded in organizational context. Presents the plan to the user. Does not gather evidence or implement fixes.

## Gotchas

- **Anchoring on the alert name.** Alert names describe symptoms, not causes. Investigate the system, not the alert string.
- **Single-hypothesis thinking.** Always produce 3+ hypotheses. The first plausible explanation is rarely the right one — satisfaction of search is the top failure mode in incident investigation.
- **Ignoring blast radius.** Before deep-diving, assess what else is affected. A single-service alert can mask a platform-wide issue.
- **Skipping duplicate check.** If someone is already investigating this, your plan should build on their work, not duplicate it.

## How This Works

1. **Parse the incident** via `link_resolver` (URL), `data_retrieval` (ticket ID), or from the prompt. Extract: alert name, affected service(s), symptom description, severity, start time, error messages, impacted metrics.
2. **Check for related investigations** via `data_retrieval`: all open incidents, active investigations, or recent postmortems for the affected service(s). Note findings to avoid duplicate work.
3. **Hydrate with organizational context** via `research_task`:
   - System understanding (`effort: medium`): "How does [affected service] work? Architecture, dependencies, upstream/downstream services, deployment pipeline, known failure modes, recent incidents."
   - Recent changes (`effort: medium`): "What changed in [affected service] and its dependencies in the last 48-72 hours? PRs merged, deployments, config changes, infrastructure changes, traffic pattern shifts."
4. **Formulate hypotheses** — 3-5 candidate root causes, each with:
   - Hypothesis statement
   - Supporting evidence from context
   - What evidence would confirm or rule it out
   - Investigation steps to test it
5. **Report the investigation plan** using `references/investigation-template.md`. Present to the user.

## Tool Selection

| Question | Tool | Why This Tool |
|---|---|---|
| System architecture, history, failure modes | `research_task` | Cross-source synthesis needed |
| Recent changes and deployments | `research_task` | Need to correlate PRs, deploys, and config across sources |
| All open incidents for a service (exhaustive list) | `data_retrieval` | Need complete filtered list, not just top results |
| PRs most related to the affected subsystem | `unblocked_context_engine` | Need relevance-ranked results, not all PRs in a range |
| Focused question about specific service behavior | `unblocked_context_engine` | One entity, one question |
| Fetch incident details from URL | `link_resolver` | Already have the URL |
