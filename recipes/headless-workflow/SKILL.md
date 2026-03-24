---
name: headless-workflow
description: >
  Autonomous coding workflow for headless and background agent runs with no
  human in the loop. Use when running as a sub-agent, in CI/CD, via
  `claude --headless`, or any scheduled/background task where the agent must
  run to completion autonomously. Uses research_task for broad context
  hydration and dual review gates for quality without user checkpoints.
---

# Headless Workflow

Autonomous 7-phase coding workflow for headless execution. Apply this workflow to the task provided in the user's prompt. The agent runs to completion without user checkpoints, uses `research_task` for broad context hydration, and makes autonomous decisions at review gates.

## Gotchas

- **Skipping hydration because "the task is simple."** No human safety net means even trivial tasks need at least one `research_task` with `effort: low`. The cost is seconds; the cost of missing context in a headless run is a bad implementation with no one watching.
- **Using `research_task` for review gates.** Review gates (Phases 3 and 6) need precision — "does THIS plan match THIS pattern?" Use `unblocked_context_engine` for reviews. `research_task` is for broad discovery in Phase 1.
- **Infinite review loops.** Cap review iterations at 3. If the plan or code hasn't converged after 3 loops, proceed with best-effort and log the unresolved concerns. Headless agents that loop forever are worse than agents that ship imperfect code with documented caveats.
- **Not logging decisions.** Headless runs need audit trails. Log every review finding, every loop-back decision, and every abort. Without this, debugging a bad headless output is impossible.
- **Treating `research_task` results as ground truth.** Results reflect the default branch and organizational knowledge, not your workspace. Cross-reference key claims (file paths, function names, patterns) against local files before building on them.

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  1. HYDRATE        (research_task)                           │
│     │              Broad multi-source context                │
│     │              gathering in 2-3 calls                    │
│     ▼                                                        │
│  2. DRAFT PLAN     (Agent)                                   │
│     │              Design implementation with                │
│     │              inlined context                           │
│     ▼                                                        │
│  3. REVIEW PLAN    (Unblocked)                      ◄──┐     │
│     │              Precision queries against           │     │
│     │              org knowledge                       │     │
│     ▼                                                  │     │
│  4. REVISE PLAN    (Agent, autonomous)                 │     │
│     │              Major issues → loop (max 3)  ───────┘     │
│     │              Minor/none → proceed                      │
│     ▼                                                        │
│  5. GENERATE CODE  (Agent)                                   │
│     │              Implement the validated plan              │
│     ▼                                                        │
│  6. REVIEW CODE    (Unblocked)                      ◄──┐     │
│     │              Verify code against context,        │     │
│     │              patterns, conventions               │     │
│     ▼                                                  │     │
│  7. REVISE CODE    (Agent, autonomous)                 │     │
│     │              Issues → loop (max 3) ──────────────┘     │
│     │              Pass → done                               │
│     ▼                                                        │
│     DONE → structured completion output                      │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

Labels: **(research_task)** = broad multi-source investigation; **(Unblocked)** = targeted precision queries via `unblocked_context_engine`; **(Agent)** = the AI coding agent.

## Principles

- **Multiple specific queries > one broad query.** Even with `research_task`, write 2-3 focused queries rather than one sprawling one.
- **Two review gates, not one.** Both are mandatory even in headless mode. The plan review prevents writing wrong code. The code review catches execution gaps.
- **Plans must be specific enough to review.** Name files, reference patterns, cite decisions. Vague plans can't be meaningfully reviewed by either humans or tools.
- **Default to existing patterns.** When Unblocked shows the team does something a certain way, follow it. Consistency wins.
- **Loop back, don't patch forward.** If a review finds issues, fix them properly. Don't compensate in the next phase.
- **Run to completion.** No user checkpoints. The agent decides to loop or proceed at review gates based on the severity of findings.
- **Front-load context aggressively.** With no human to fill gaps mid-run, hydration must be thorough. Err on the side of over-gathering.
- **Abort explicitly when blind.** If hydration returns nothing relevant, stop and report rather than guessing. A clean abort is better than a confident wrong implementation.

## Scaling to Task Size

- **Trivial changes** (typo fix, rename, one-line config tweak): Run one `research_task` with `effort: low`, then skip to Phase 5. Always run Phase 6 before finishing.
- **Small changes** (add a helper, adjust logic in one file): Run Phase 1 with one `research_task` at `effort: medium`, then proceed through the rest.
- **Standard changes** (new feature, bug fix, refactor): Run the full workflow as written.
- **Large changes** (cross-cutting refactor, new subsystem): Run the full workflow, expect multiple review loops, and consider breaking the task into sub-tasks — running this workflow per sub-task.

**When in doubt, run the full workflow.** The cost of an extra `research_task` call is seconds; the cost of missing context in a headless run is a bad implementation with no one to catch it.

## Task-Specific Hydration

When the task falls into a specific category, shape Phase 1 research calls to cover these angles:

### Debugging a Bug
- What changed recently in the affected system (PRs, deployments, config changes)?
- Has this bug or similar symptoms been reported before, and how was it resolved?
- What is the original intent of the affected code, and what constraints aren't visible in the code itself?
- Before fixing, confirm: what the bug is, why it's happening, why the fix solves it, and what else the fix might affect.

### Implementing a Feature
- How have similar features been implemented? What patterns and utilities exist to reuse?
- What systems will this feature touch (API, database, services, UI)?
- Has this feature been attempted before? What happened? What alternatives were considered?
- Are there performance, security, or non-functional constraints?

### Exploring Unfamiliar Code
- What is the system's purpose, main components, and how do they interact?
- What are the entry points, core logic locations, and data flow?
- What conventions does the team follow in this area (naming, error handling, testing)?
- Why was it designed this way? What tech debt exists? What direction changes are in progress?

---

## Phase 1: Hydrate Context (research_task)

Before planning, gather broad context using `research_task`. This replaces the 4-6 individual `unblocked_context_engine` + `data_retrieval` calls in the interactive workflow with 2-3 focused research calls that cover more ground per query.

**Required research calls:**

1. **System understanding** (`effort: medium`): "Explain how [feature area] works in this codebase, including the architecture, conventions the team follows for [relevant pattern], and any existing utilities or modules that should be reused rather than reinvented."

2. **History and prior art** (`effort: medium`): "What decisions have been made about [related area]? Has the team tried [this kind of change] before, and what happened? Include recent PRs and issues related to [area being changed]."

3. **Risks and constraints** (`effort: low`, conditional — run for standard/large tasks): "What are the known gotchas, edge cases, or constraints in [area]? Are there active migrations or direction changes that could conflict with [planned change]?"

**Example** — "add rate limiting to the API":
```
research_task (effort: medium): "Explain how the API middleware pipeline works
in this codebase, including existing rate limiting or throttling mechanisms,
the patterns the team uses for middleware configuration, and any shared
utilities in the middleware layer that should be reused."

research_task (effort: medium): "What decisions have been made about API
authentication and middleware? Has rate limiting been attempted or discussed
before? Include recent PRs touching the API layer and any relevant Slack or
Jira discussions."
```

**Context sufficiency check** — before proceeding to Phase 2, verify you can answer:
1. What am I changing and what does it touch?
2. What patterns does the team use for this kind of change?
3. What was tried before and what were the outcomes?
4. What are the risks?

If any answer is "unknown," make a targeted follow-up: another `research_task` with `effort: low` for a multi-source gap, or a single `unblocked_context_engine` query for a focused gap.

**Collect and carry forward:**
- Existing modules to extend (not reinvent)
- Naming conventions and code style patterns
- Architectural patterns the team actually uses
- Related recent work that might conflict or coordinate
- Prior decisions and rejected approaches
- Known edge cases and gotchas

---

## Phase 2: Draft Plan (Agent)

Design the implementation **referencing specific findings from Phase 1**. The plan must reflect the team's actual patterns, not generic best practices.

**The plan should explicitly:**

- Name the existing modules, utilities, and patterns it will follow (from Phase 1)
- Call out how it aligns with prior team decisions discovered during hydration
- Note any area where the plan diverges from existing patterns and explain why
- Identify files that will be created or modified
- Describe the approach at enough detail that it can be critically reviewed
- **Inline discovered context** — paste relevant code snippets, quote PR descriptions, and show convention examples rather than just referencing them. Later phases shouldn't need to re-query for context that was already gathered.
- **Include a constraints section** — what the implementation must NOT do, based on rejected approaches and known gotchas from hydration

---

## Phase 3: Review Plan (Unblocked)

**CRITICAL GATE — Do not skip this phase.**

Before writing any code, submit the plan for critical review using targeted precision queries.

**Required queries (run all of these, referencing the specific plan):**

1. `unblocked_context_engine`: "We plan to [summarize approach]. Does this align with how [related system] works in this codebase? Are there existing patterns we should follow instead?"

2. `unblocked_context_engine`: "We plan to modify/create [specific files]. What do we need to know about these files and their dependencies? Are there conventions for how changes in this area are typically structured?"

3. `unblocked_context_engine`: "Has the team tried [planned approach] before? Were there any problems or rejected alternatives?"

4. `unblocked_context_engine`: "What could go wrong with [planned approach]? Are there edge cases, performance concerns, or integration issues we should consider?"

**What you're looking for:**

- **Pattern mismatches:** The plan uses approach X, but the team uses approach Y.
- **Missing context:** The plan doesn't account for a related system, a recent change, or a known constraint.
- **Rejected approaches:** The team tried this before and it didn't work.
- **Naming/convention violations:** The plan introduces names or structures that don't match the codebase.
- **Scope blindness:** The plan misses files or systems that need to change together.

**After reviewing, assess the findings and determine whether the plan needs revision and what specific changes are needed.**

---

## Phase 4: Revise Plan (Agent, Autonomous)

Incorporate all feedback from the plan review.

**For each piece of feedback from Phase 3:**
- State what was found
- State how the plan is being updated
- If you disagree with the feedback, explain why (but default to matching existing patterns)

**Autonomous loop decision:**
- **Major issues** (changed approach, different files, new dependencies): revise and **loop back to Phase 3**. Maximum 3 iterations.
- **Minor issues** (naming fixes, missing import, detail adjustment): revise and proceed to Phase 5.
- **No issues**: proceed to Phase 5.
- **After 3 iterations without convergence**: proceed with best-effort plan and log unresolved concerns in the completion output.

---

## Phase 5: Generate Code (Agent)

Implement the validated, reviewed plan.

**During codegen:**
- Follow the plan. Don't deviate from reviewed decisions without reason.
- If you encounter something unexpected that contradicts the plan, re-query Unblocked via `unblocked_context_engine` rather than guessing.
- If a build or runtime error occurs, use `failure_debugging` with the error message and surrounding context. Attempt the fix autonomously — surface known issues and past fixes.

---

## Phase 6: Review Code (Unblocked)

**CRITICAL GATE — Do not skip this phase.**

After codegen, verify the generated code against organizational context using targeted queries.

**Required queries (run all of these, referencing the actual code that was written):**

1. `unblocked_context_engine`: "We wrote [summarize what was generated — new files, modified files, key patterns used]. Does this match how the team typically implements [this kind of thing] in this codebase?"

2. `unblocked_context_engine`: "Looking at [specific pattern/approach in generated code], is this consistent with the conventions in [area of codebase]? Are there existing utilities or helpers we should be using instead?"

3. `unblocked_context_engine`: "What are the team's testing conventions for [area changed]? Do the changes we made follow those patterns?"

4. `unblocked_context_engine`: "Have there been issues in the past with [the approach taken in generated code] in this area of the codebase?"

**What you're looking for:**

- **Reinvented wheels:** The code creates something that already exists as a utility or shared module.
- **Convention drift:** The code works but doesn't match the team's style — wrong error handling, different naming, non-standard file organization.
- **Missing patterns:** The team has established patterns for this kind of change that the generated code doesn't follow.
- **Context gaps:** The code doesn't account for something Unblocked surfaces — a related system, a known edge case, a dependent service constraint.

**After reviewing, assess the findings and determine whether the code needs revision and what specific changes are needed.**

---

## Phase 7: Revise Code (Agent, Autonomous)

Fix all issues surfaced by the code review.

**For each issue from Phase 6:**
- State what was found
- State what is being changed
- Make the fix

**Autonomous loop decision:**
- **Significant issues** (new files, changed approach, different utilities): fix and **loop back to Phase 6**. Maximum 3 iterations.
- **Small fixes** (rename a variable, swap to an existing utility, add a missing import): fix and proceed to completion.
- **No issues**: proceed to completion.
- **After 3 iterations without convergence**: proceed with best-effort code and log unresolved concerns.

**Structured completion output:**
- What was built (files created/modified)
- What the plan review caught and changed
- What the code review caught and fixed
- Confidence level (high/medium/low based on context quality and review convergence)
- Remaining risks or follow-ups

---

## Abort Conditions

Stop and report rather than continuing blind:

- **No relevant hydration context** for the primary system being changed — the agent is flying blind.
- **3+ review loop iterations** without convergence — the plan or code can't satisfy the review.
- **Persistent build/test failures** after 2 fix attempts — something fundamental is wrong.

When aborting, log the reason, what was attempted, what context was gathered, and where the agent got stuck. A clean abort with good diagnostics is far more useful than a confident wrong implementation.

---

## Tool Selection

| Question | Tool |
|---|---|
| Broad investigation (3+ unknowns, multi-source) | `research_task` |
| How/why does X work? (focused, one entity) | `unblocked_context_engine` |
| What was decided about X? | `unblocked_context_engine` |
| Recent PRs/issues in area X | `data_retrieval` |
| Contents of a specific PR/issue URL | `link_resolver` |
| Debug a build/runtime failure | `failure_debugging` |
