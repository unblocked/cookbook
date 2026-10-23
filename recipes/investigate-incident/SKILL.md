---
name: investigate-incident
description: "Use when an alert or incident needs an investigation plan: ranked hypotheses from architecture, recent changes, past incidents. Then gather-evidence."
---

Pull the incident from its link with context_get_urls, or from the prompt: affected services, symptom, start time, severity, error text. Investigate the system, not the alert name.

Check whether someone is already on it with `unblocked context-search-messages --query "<service> incident"` and `unblocked context-search-issues --query "<service>"`, or context_research at effort medium. If they are, build on their work.

Call context_research with effort high twice (`unblocked context-research --query "..." --effort high` unattended). First, how the affected service works: dependencies, upstream and downstream, known failure modes, past incidents. Second, what changed in it and its dependencies in the last 72 hours.

Produce three to five ranked hypotheses. For each, give the supporting context with links, the evidence that would confirm or rule it out, and the first check to run. Note the blast radius: what else depends on the affected service.

The plan is done when two people could split the hypotheses and start without asking you anything.

Unattended, take the default on any fork, state the choice in the plan, and list the forks at the end for review.
