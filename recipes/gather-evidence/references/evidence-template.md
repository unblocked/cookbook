# Evidence Report Template

Adapt this structure to the incident. Not every section applies to every investigation.

## Evidence Summary

What was gathered, from which sources, and overall confidence level. Note which sources returned useful signals and which were empty.

## Correlation Timeline

Chronological events leading to and following the incident. Each event includes:

- **Timestamp**
- **Event** — what happened
- **Source** — where this was found (PR number, Slack thread, deployment log, etc.)

Build from: last known good state → changes → first symptom → escalation.

## Key Findings

Plain-language explanation of what the evidence shows. For each finding:

- What was found
- What it means for the incident
- Confidence level (HIGH / MEDIUM / LOW)
- Source

Explain without assuming telemetry expertise. "The deployment at 14:32 changed the retry timeout from 30s to 5s" not "timeout_ms=5000 in the diff."

## Hypothesis Evaluation

If hypotheses were provided, evaluate each:

- **Hypothesis** — restate it
- **Evidence for** — with citations
- **Evidence against** — with citations
- **Updated likelihood** — HIGH / MEDIUM / LOW with reasoning

## Gaps

What evidence is still missing and where to look for it. Be specific: "Need Kafka consumer lag metrics from the monitoring dashboard for 14:00-15:00 UTC" not "Need more data."
