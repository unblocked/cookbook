---
name: enrich-ticket
description: "Use when a Jira, Linear, or GitHub ticket needs context before someone picks it up: related PRs, code paths, prior attempts. Enriches, doesn't solve."
---

Read the whole ticket first, because its text drives every query. Fetch it with context_get_urls (`unblocked context-get-urls --urls <url>`), or for an ID like PROJ-123 use `unblocked context-search-issues --query "PROJ-123"` or context_research.

Call context_research with effort medium (`unblocked context-research --query "..." --effort medium` unattended): how the affected system works, what was decided, whether this was reported or attempted before, and which PRs and issues relate. For an engineering ticket, also ask for code paths, entry points, and helpers. For a user-reported or support ticket, ask for expected behavior, known limitations, and workarounds. If the ticket quotes an error, run one effort medium call on the exact text.

Write a comment ready to paste on the ticket: a two-line summary, where to start (files and entry points), relevant history (prior attempts, decisions, related tickets and PRs), and open questions for the reporter, with a link for every claim. Stop at context and leave the fix to whoever picks it up.

It is done when someone new to the area could start work from it without searching.

Unattended, take the default on any fork, state the choice in the comment, and list the forks at the end for review.
