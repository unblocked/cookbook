---
name: headless-gather-evidence
description: >
  Headless evidence gathering that correlates signals from code, infrastructure,
  and organizational sources for an incident. Use when an agent should
  autonomously gather cross-system evidence — building a correlation timeline,
  evaluating hypotheses against evidence, and synthesizing findings. Output is
  structured for AI agent consumption. Does not plan the investigation or
  recommend fixes.
---

# Incident Evidence Gathering

Autonomous evidence gathering for headless execution. Apply this to the incident in the user's prompt. Gathers and correlates evidence from code, infrastructure, and organizational sources. Does not plan the investigation or implement fixes.

## Gotchas

- **Stopping at the first confirming signal.** Gather evidence for AND against each hypothesis. Confirmation bias is the top failure mode in incident investigation.
- **Presenting raw data instead of findings.** The output should state what the evidence means. Translate telemetry into plain findings.
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
4. **Evaluate hypotheses** (if provided) — for each hypothesis, list evidence for and against with updated likelihood.
5. **Produce structured output** following the output format below.

## Output Format

Output is consumed by an AI agent, not a human. Optimize for token efficiency and actionability. No narrative prose.

```
EVIDENCE_SOURCES
  searched: [list of source types queried]
  yielded_results: [list of source types that returned useful signals]
  empty: [list of source types with no relevant results]

TIMELINE
  [timestamp] | [event] | [source: PR#/Slack/deploy/ticket]
  [timestamp] | [event] | [source]
  ...

EVIDENCE_ITEMS
  1. source: [where found]
     finding: [what it means, not raw data]
     timestamp: [when]
     confidence: HIGH|MEDIUM|LOW
     hypothesis_relevance: [which hypothesis this supports/contradicts, if applicable]
  2. ...

HYPOTHESIS_EVALUATION (if hypotheses provided)
  hypothesis_1: [restate]
    evidence_for: [compact citations]
    evidence_against: [compact citations]
    updated_likelihood: HIGH|MEDIUM|LOW
    next_action: [what to do with this hypothesis now]
  hypothesis_2: ...

KEY_FINDING
  root_cause_signal: [one-line best assessment of what happened]
  confidence: HIGH|MEDIUM|LOW
  supporting_evidence: [top 3 evidence items by relevance]

GAPS
  - [what's missing] → [where to look for it]
```

## Abort Conditions

- **Can't fetch or parse the incident** — stop and report what was attempted.
- **No relevant evidence** from any source — produce minimal output noting what was searched and LOW confidence.
- **Affected service is completely unclear** — report that evidence gathering needs a clearer scope.

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

Fine-grained tools (`context_search_code`, `context_search_messages`, `context_search_issues`, etc.) are available in the Unblocked CLI. On MCP, fall back to `context_research` with a steering `instruction`.
