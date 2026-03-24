---
name: headless-plan
description: >
  Headless planning workflow that gathers organizational context and produces a
  validated implementation plan without writing code. Use when an agent needs to
  plan a change autonomously — for handoff to another agent, a cloud executor,
  or human review. Hydrates with research_task, drafts a plan with inlined
  context, and validates it against team patterns. No codegen phase.
---

# Context-Aware Planning

Autonomous planning for headless execution. Apply this to the planning task in the user's prompt. Produces a validated, self-contained implementation plan — no code is written. The consumer may not have Unblocked access, so all context is embedded inline.

## Gotchas

- **Vague plans that can't be reviewed.** "Add a middleware" is not a plan. Name files, reference patterns, cite decisions.
- **Referencing context instead of inlining it.** Embed quotes, code snippets, and convention examples directly in the plan.
- **Skipping validation.** Always validate the plan against Unblocked before finalizing. This catches pattern mismatches and rejected approaches.
- **Under-gathering context.** The plan is the only output — it needs to carry all the context.

## How This Works

1. **Hydrate deeply** — the plan must be self-contained, so gather more than usual:
   - `research_task` (`effort: medium`): "How does [feature area] work? What conventions, naming patterns, and utilities should be reused?"
   - `research_task` (`effort: medium`): "What decisions about [area]? Has this been tried before? Recent PRs, rejected approaches, active migrations?"
   - `research_task` (`effort: medium`): "Team patterns for [error handling / testing / config] in [area]? Known gotchas or constraints? Include code examples."
2. **Draft the plan** with inline context — paste code snippets, quote PR descriptions.
   - **Instead of:** "Follow the team's error handling pattern"
   - **Write:** "Wrap service calls in try/catch, log with `logger.error({ err, context })`. Example from `src/api/users.ts:45-60`: [paste code]"
3. **Validate against Unblocked** using targeted `unblocked_context_engine` queries — does this align with existing patterns? Has this been tried? What could go wrong? Loop up to 3 times if major issues are found.
4. Output the finalized plan.

### Plan Structure

1. **Task description** — what to implement and why
2. **Embedded conventions** — team patterns with code examples pasted inline
3. **Embedded prior art** — relevant PRs and decisions with key details
4. **File map** — exact files to create or modify, verified against the codebase
5. **Step-by-step approach** — specific enough for a context-blind agent to execute
6. **Constraints** — what NOT to do
7. **Verification steps** — how to confirm correctness

### Completeness Check

Before outputting: every convention shown with example, all relevant PRs summarized, file paths verified, constraints explicit, verification steps testable.

## Abort Conditions

- **No relevant context** for the primary system — stop and report.
- **3+ validation loops** without convergence — output best-effort plan with unresolved concerns noted.

## Tool Selection

| Question | Tool |
|---|---|
| Broad investigation (3+ unknowns, multi-source) | `research_task` |
| Validate a specific plan element | `unblocked_context_engine` |
| Recent PRs/issues in area | `data_retrieval` |
| Specific PR/issue details | `link_resolver` |
