---
name: code-review
description: "Use when reviewing a PR, branch, or diff where team conventions and past decisions matter. For PRs with an Unblocked risk label, use risk-triage."
---

Before reading the diff, learn how this team builds the areas it touches. Get the diff from `git diff`, `gh pr diff <N>`, or context_get_urls on a PR link.

For each area the diff touches, call context_research with effort medium: the conventions, similar recent PRs, decisions and constraints, and existing helpers that should be reused. Unattended, run `unblocked context-research --query "..." --effort medium` per area, and `unblocked context-search-prs --query "..."` for related PRs.

Report what a reviewer with that context would catch: departures from team patterns, reinvented helpers, conflicts with past decisions or in-flight work, and risks the history points to. Leave style to linters. Check any finding you are unsure of with one context_research call at effort medium, and keep it only if the context supports it.

Each finding names file:line, says what to change, and links the PR, decision, or doc behind it. Order findings by severity. If the diff is fine, say so in one line.

Unattended, print the report rather than posting it unless the caller asked you to post. Take the default on any fork, state the choice in the report, and list the forks at the end for review.
