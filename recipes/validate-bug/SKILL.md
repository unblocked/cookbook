---
name: validate-bug
description: "Use when triaging a bug report: is it real, what likely caused it, has it happened before. Investigates and reports; doesn't fix."
---

Start from the report. Fetch it with context_get_urls or `unblocked context-search-issues --query "<ID>"`, and note the symptom, expected behavior, component, repro steps, error text, and when it started.

Run two context_research calls at effort medium (`unblocked context-research --query "..." --effort medium` unattended). Ask what changed in the component around when the symptom started (PRs, deploys, config, dependencies). Then ask whether this or something like it was reported before and how it was resolved. If there is an error message, add an effort medium call on the exact text.

Lay out a timeline: last known good, what changed, first symptom. Then test two or three causes against the code itself, since reports often name the wrong component.

Put the verdict on the first line: Confirmed, Likely, Not reproducible, or Insufficient information. Follow it with the timeline, each hypothesis with the evidence for and against, and links. End with the next step for whoever fixes it.

Unattended, take the default on any fork, state the choice in the report, and list the forks at the end for review.
