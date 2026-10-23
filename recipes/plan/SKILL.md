---
name: plan
description: "Use when asked to plan, scope, or design a non-trivial change before code is written. Produces a plan grounded in how this team builds, not code."
---

Before drafting, ask Unblocked what the team already knows about this area: how it works, what was decided, what was tried and rejected, and what is in flight. Interactively, call context_research with effort high. Unattended, run `unblocked context-research --query "..." --effort high` and read the JSON on stdout. Fetch linked tickets, PRs, and docs with context_get_urls (`unblocked context-get-urls --urls <url>`).

Write the plan for someone without Unblocked access: name the files, quote the conventions and decisions it relies on, and link each one.

Before finishing, name the plan's riskiest assumption and test it with one context_research call at effort medium. Where the plan departs from a team decision, say so in the plan and give the reason.

The plan is done when every step names a file and every convention it depends on is quoted with a link. If Unblocked returned nothing relevant, open the plan with that sentence.

Unattended, take the default on any fork, state the choice in the plan, and list the forks at the end for review.
