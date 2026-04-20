---
name: code-review
description: >
  Context-aware code review that gathers organizational context before analyzing
  a diff. Use when reviewing a PR or branch where team conventions, prior art,
  and related changes matter. Hydrates the reviewer with team patterns via
  context_research, categorizes findings, and presents them for discussion.
---

# Context-Aware Review

Gather organizational context *before* analyzing the diff so findings are grounded in how the team actually works — not generic opinions. Apply this to the review task in the user's prompt.

## Gotchas

- **Reviewing without hydrating first.** Never flag something without checking context. A pattern that looks wrong may be the team's established approach.
- **Flagging linter-level issues.** Focus on what only a context-aware reviewer can catch — pattern mismatches, reinvented wheels, missing context. Leave style to automated tools.
- **One broad research query for a multi-area PR.** If the diff touches auth and billing, run separate `context_research` calls for each area.
- **Opinions without citations.** Every finding must reference a specific PR, decision, or convention from the research results.

## How This Review Works

1. Get the diff — from a PR URL (`context_get_urls`), ticket ID (`context_search_issues` or `context_research`), local branch (`git diff`), or the prompt
2. **Hydrate context before reading the diff** — run one `context_research` (`effort: medium`) per area touched: "What conventions and patterns does the team follow for [area]? How have similar changes been structured in recent PRs? What decisions or constraints apply? Are there established utilities that should be reused?"
3. Analyze the diff against hydrated context
4. Categorize findings — see `references/finding-categories.md` for definitions and priority order
5. Validate uncertain findings with a targeted `context_research` query (`effort: low`) before including them
6. Structure the report using `references/report-template.md` and present to the user

## Tool Selection

| Question | Preferred tool | Fallback |
|---|---|---|
| Broad investigation of an area | `context_research` (`effort: medium`) | — |
| Validate a specific pattern | `context_research` (`effort: low`) | — |
| Recent PRs in same area | `context_search_prs` (CLI) | `context_research` with `"Prefer PR descriptions and review discussions"` instruction |
| Fetch a PR/issue by URL | `context_get_urls` | — |

Fine-grained tools (`context_search_prs`, `context_search_issues`, `context_search_code`, etc.) are available in the Unblocked CLI. On MCP, fall back to `context_research` with a steering `instruction` — see the `unblocked-tools-guide` skill for the full mapping.
