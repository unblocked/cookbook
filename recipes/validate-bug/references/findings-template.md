# Findings Template

Adapt this structure to the investigation. Not every section applies to every bug.

## Validation Result

**Status:** Confirmed / Likely / Not Reproducible / Insufficient Information

## Summary

One paragraph: what was investigated, what was found, and the confidence level.

## Timeline

Chronological events leading to the bug. Include dates, PR numbers, deployments, and their sources.

## Root Cause Analysis

- **Most likely cause** — with evidence and citations
- **Alternative hypotheses** — what was considered and why it was ruled out
- **Related prior incidents** — if any were found, how they were resolved

## Recommended Next Steps

- Fix direction (describe the approach, not the implementation)
- Reproduction steps refined from investigation
- What to monitor to confirm the fix works
- Regression protection to add

## Context for the Fixer

Relevant code paths, team patterns for this area, and constraints discovered during investigation. Give the fixer a head start.
