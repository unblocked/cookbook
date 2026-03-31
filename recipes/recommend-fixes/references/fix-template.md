# Fix Recommendation Template

Adapt this structure to the incident. Not every section applies to every fix.

## Root Cause Summary

What is broken and why. Confirmed or suspected, with confidence level and supporting evidence.

## Fix Recommendations

Ranked by urgency. Organized in three tiers:

### Immediate Mitigation

What to do right now to reduce impact. Examples: rollback, scale up, toggle feature flag, config change.

For each mitigation:

- **Action** — what to do
- **Rationale** — why this helps
- **Historical validation** — has this been done before? What happened?
- **Risk** — what could go wrong
- **Rollback** — how to undo if it makes things worse

### Root Cause Fix

Code or configuration changes that address the underlying issue.

For each fix:

- **Action** — what to change and where (file paths, configs)
- **Rationale** — why this addresses root cause, not just symptoms
- **Historical validation** — similar fixes from past incidents, with outcomes
- **Risk assessment** — blast radius, side effects, dependencies affected
- **Rollback plan** — how to revert

### Prevention

What to add so this doesn't happen again.

- Monitoring and alerting gaps to close
- Tests to add (unit, integration, load)
- Guardrails (circuit breakers, rate limits, validation)
- Runbook updates

## PR Context

Enough detail for whoever (or whatever agent) implements the fix:

- **Code paths to modify** — files, functions, entry points
- **Team conventions** — patterns to follow for this area
- **Tests to add or update** — what the team expects for changes in this area
- **Deploy procedure** — how this type of change gets to production

## Post-Incident Items

Monitoring gaps, runbook updates, alert tuning, and any follow-up tickets to create.
