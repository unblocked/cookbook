---
name: plan
description: >
  Context-aware planning workflow that gathers organizational context and
  produces a validated implementation plan without writing code. Use when
  planning a change for handoff to another agent, a teammate, or future work.
  Hydrates with research_task, drafts a plan with inlined context, validates
  against team patterns, and presents to the user for approval.
---

# Context-Aware Planning

Produce a validated, self-contained implementation plan — no code is written. Apply this to the planning task in the user's prompt. The plan embeds all discovered context inline so whoever consumes it can act without further research.

## Gotchas

- **Vague plans that can't be reviewed.** "Add a middleware" is not a plan. Name files, reference patterns, cite decisions.
- **Referencing context instead of inlining it.** The consumer may not have Unblocked access. Embed quotes, code snippets, and convention examples directly.
- **Skipping validation.** Always validate the plan against Unblocked before presenting it. This catches pattern mismatches and rejected approaches.
- **Under-gathering context.** The plan is the only output — it needs to carry all the context.

## How This Works

1. **Hydrate deeply** — the plan must be self-contained, so gather more than usual:
   - `research_task` (`effort: medium`): "How does [feature area] work? What conventions, naming patterns, and utilities should be reused?"
   - `research_task` (`effort: medium`): "What decisions about [area]? Has this been tried before? Recent PRs, rejected approaches, active migrations?"
   - `research_task` (`effort: medium`): "Team patterns for [error handling / testing / config] in [area]? Known gotchas or constraints? Include code examples."
2. **Draft the plan** with inline context — paste code snippets, quote PR descriptions. See `references/plan-template.md` for structure and completeness checklist.
   - **Instead of:** "Follow the team's error handling pattern"
   - **Write:** "Wrap service calls in try/catch, log with `logger.error({ err, context })`. Example from `src/api/users.ts:45-60`: [paste code]"
3. **Validate against Unblocked** using targeted `unblocked_context_engine` queries — does this align with existing patterns? Has this been tried before? What could go wrong?
4. Present findings and the revised plan to the user for approval. Verify against the completeness checklist in `references/plan-template.md`.

## Tool Selection

| Question | Tool |
|---|---|
| Broad investigation (3+ unknowns, multi-source) | `research_task` |
| Validate a specific plan element | `unblocked_context_engine` |
| Recent PRs/issues in area | `data_retrieval` |
| Specific PR/issue details | `link_resolver` |
