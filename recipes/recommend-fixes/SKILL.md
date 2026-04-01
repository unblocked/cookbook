---
name: recommend-fixes
description: >
  Fix recommendation that validates against historical patterns and produces
  ranked remediation options for an incident. Use when an incident has a
  confirmed or suspected root cause and needs fix recommendations — researching
  how similar issues were fixed before, validating against historical regressions,
  and producing tiered recommendations (mitigation, root cause fix, prevention)
  with enough context for remediation PRs. Presents recommendations to the user.
  Does not implement the fix.
---

# Incident Fix Recommendations

Produce ranked fix recommendations for the incident in the user's prompt. Validates each recommendation against historical patterns and prior fixes. Presents tiered recommendations (mitigation, root cause, prevention) with PR context. Does not implement the fix.

## Gotchas

- **Recommending fixes without understanding root cause.** A fix that addresses symptoms will need to be applied again. Distinguish mitigation (stop the bleeding) from remediation (fix the cause).
- **Ignoring what was tried before.** If a similar fix was applied in a past incident and caused a regression, recommending it again is worse than no recommendation.
- **Skipping rollback planning.** Every production fix can make things worse. Each recommendation needs a rollback path.
- **One-size-fits-all recommendations.** Scaling a service, changing config, and deploying a code fix have very different risk profiles, blast radii, and time-to-effect. Rank by urgency and risk.

## How This Works

1. **Parse the incident** via `link_resolver` (URL), `data_retrieval` (Jira ticket), `research_task` (Datadog/Sentry incident), or from the prompt. Extract: root cause (confirmed or suspected), affected service(s), severity, current impact, what's been tried so far.
2. **Research fix patterns** via `research_task`:
   - Historical fixes (`effort: medium`): "How has [root cause type] been fixed before in [affected service] or similar services? Past remediation PRs, rollback procedures, hotfix patterns. Were there regressions or side effects from past fixes?"
   - Team patterns (`effort: medium`): "What are the team's patterns for [type of fix — scaling, config, code, rollback]? Deployment and testing requirements for production changes? Change management process? Feature flags or kill switches available?"
   - If specific code needs changing: use `unblocked_context_engine` to understand conventions, tests, and constraints for that code.
3. **Validate each candidate fix** — check against historical patterns:
   - Has this been applied before? What happened?
   - Known side effects or regressions?
   - Does it address root cause or just symptoms?
4. **Rank and structure recommendations** in three tiers:
   - **Immediate mitigation** — reduce impact now (rollback, scale, feature flag, config)
   - **Root cause fix** — address the underlying issue (code change, architecture fix)
   - **Prevention** — stop recurrence (monitoring, tests, guardrails, runbook updates)
5. **Report recommendations** using `references/fix-template.md`. Present to the user.

## Tool Selection

| Question | Tool | Why This Tool |
|---|---|---|
| Historical fixes and remediation patterns | `research_task` | Cross-source synthesis across past PRs, incidents, and postmortems |
| Team deployment and testing patterns | `research_task` | Need conventions from multiple sources (docs, PRs, Slack) |
| Conventions and constraints for specific code | `unblocked_context_engine` | One entity, focused question about how to change it |
| Prior occurrences of this error | `failure_debugging` | Error-specific history and past fixes |
| Fetch incident details from URL | `link_resolver` | Already have the URL |
| All past Jira tickets for a service (exhaustive list) | `data_retrieval` | Need complete filtered list for pattern matching |
| Datadog/Sentry incident data for a service | `research_task` | Direct Datadog/Sentry data requires cross-source investigation |
