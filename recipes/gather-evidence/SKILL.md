---
name: gather-evidence
description: "Use when an incident needs evidence: a sourced timeline across code, infra, and team chat, tested against the hypotheses. Follows investigate-incident."
---

Start from the incident and any hypotheses already on the table. Call context_research with effort medium twice (`unblocked context-research --query "..." --effort medium` unattended). First, code and infrastructure: the code paths, recent changes to retries, limits, config, and deploy manifests, and what recent PRs actually changed. Second, the team's own signals: chat threads, deploy announcements, on-call notes, related tickets.

For chat on its own, use `unblocked context-search-messages --query "..."`. For code, use `unblocked context-search-code --query "..."`. Run one effort medium call on any exact error text to find earlier occurrences.

Build one timeline from every source: last known good, each change, first symptom, escalation. Give each entry a time and a link.

For each hypothesis, list the evidence for and against it, and look for the second kind as hard as the first. Write findings in plain language: what was found, what it means, how confident you are, and where it came from. Explain logs rather than pasting them.

Unattended, take the default on any fork, state the choice in the report, and list the forks at the end for review.
