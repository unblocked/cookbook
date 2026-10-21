---
name: recommend-fixes
description: "Use when an incident has a known or suspected root cause and needs fixes (mitigation, root cause, prevention), each checked against past fixes."
---

Start from the root cause, the affected services, current impact, and what has been tried. Call context_research with effort medium twice (`unblocked context-research --query "..." --effort medium` unattended). First, how this kind of failure was fixed here before, including fixes that regressed. Second, the team's rules for shipping production changes: deploy and test requirements, feature flags, kill switches, rollback procedure. For code you would change, `unblocked context-search-code --query "..."` finds its conventions and tests.

Give three tiers. First, mitigation that reduces impact now: rollback, scale, flag, config. Second, the fix for the root cause. Third, prevention: tests, alerts, guardrails, runbook. For each recommendation, give what to do, the risk and blast radius, time to take effect, the rollback path, and the past incident or PR that supports or warns against it. A fix that regressed before goes in with that history beside it, or not at all.

It is done when each tier has enough detail to open a PR or run the change.

Unattended, take the default on any fork, state the choice in the report, and list the forks at the end for review.
