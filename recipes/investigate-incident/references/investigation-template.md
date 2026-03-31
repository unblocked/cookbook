# Investigation Plan Template

Adapt this structure to the incident. Not every section applies to every investigation.

## Incident Summary

What is happening, severity level, and blast radius assessment. Which users, services, or systems are affected.

## Affected Systems

Services, dependencies, and ownership. Include upstream and downstream services that may be contributing or impacted.

## Related Investigations

Duplicate or related ongoing investigations, recent postmortems for this area. Build on existing work rather than duplicating it.

## Hypotheses

Ranked by likelihood. For each hypothesis:

- **Statement** — what you think happened
- **Likelihood** — HIGH / MEDIUM / LOW with reasoning
- **Supporting evidence** — what from the organizational context points to this
- **Confirming evidence** — what would prove this is the cause
- **Disconfirming evidence** — what would rule this out
- **Investigation steps** — specific actions to test this hypothesis

## Parallel Investigation Tracks

Group hypotheses that can be investigated simultaneously. Each track should be independent enough that multiple investigators (or agents) can work in parallel.

## Escalation Criteria

When to page additional teams, what conditions indicate the incident is broader than initially assessed, and what signals suggest the investigation is off track.
