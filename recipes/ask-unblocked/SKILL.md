---
name: ask-unblocked
description: "Use when a question needs the team's history, not just the code: why something exists, who decided, what happened, how systems connect."
---

Answer from the team's context first, then check it against the code. Call context_research with effort high and the question in the user's words. Unattended, run `unblocked context-research --query "..." --effort high` and read `summary` and `sources` from the JSON on stdout.

Fetch any link the user gives, and any source the answer leans on, with context_get_urls (`unblocked context-get-urls --urls <url>`). Follow the chain while it keeps paying off: a PR points to an issue, the issue to a thread, the thread to a design doc.

Lead with the direct answer in one or two sentences. Use a diagram for architecture, a table for tradeoffs, and a dated timeline for history or incidents. Cite every claim inline, list the sources at the end, and label anything you could not source as inference.

If nothing relevant comes back, say what you searched and where the answer probably lives.
