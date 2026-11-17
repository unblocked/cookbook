---
name: unblocked-insights
description: "Use to evaluate where Unblocked helped in past coding-agent sessions. Takes a rough time range (default: today), analyzes local transcripts, and writes an evidence-based HTML impact report."
argument-hint: "[time range, e.g. \"last 3 days\"]"
disable-model-invocation: true
---

Analyze how Unblocked changed—or failed to change—the work recorded in local conversation transcripts. Produce a candid report on whether and how it changed the outcome, and at what cost.

"Unblocked had little or no effect on this work" is a valid and useful conclusion. Report positive, neutral, and negative effects with the same care.

## 1. Determine the scope

Respect any scope the user gave (date range, project, repository, topic); otherwise use today's transcripts. Run a lightweight triage pass: read only enough of each session to rate it. Leave Unblocked calls and outcomes for the analysis step.

### Triage estimated ambient context need

Estimated ambient context need is how much the session depended on institutional context from outside the checkout, independent of any particular tool. Rate each session:

- **High:** decision-critical information likely lives outside the checkout—team conventions, PR or issue history, rejected attempts, cross-repository behavior, customer or production context, incidents.
- **Medium:** local evidence can probably answer the task, but institutional context could validate intent, expose precedent, or prevent a wrong turn.
- **Low:** code, explicit requirements, or live runtime state tell the complete story.
- **Unclear:** not enough information to judge.

Also assign one category: planning/design, onboarding/research, implementation/refactor, review/security, debugging/environment, testing/build, or quick operational work. The category informs the rating of how much ambient context is needed, but doesn't decide it.

Note feature or workstream groupings among High and Medium sessions where the work clearly belongs together.

## 2. Ask the user what to analyze

List **every session found** in a compact table: one-line title / goal, date, category, estimated ambient context need.

Below it, in at most two sentences, give the scope used with counts per rating, and note that whichever sessions the user will choose to analyse will be read in depth—more or larger sessions cost more tokens and time.

Then ask the user to choose, using the harness's structured choice tool when available. Offer two or three of these options, recommended first:

- **Analyze one feature/workstream:** the most coherent High/Medium group, with its session count.
- **Analyze only `<session>`:** a strong individual High/Medium candidate.
- **Analyze all `<N>` High-need sessions:** recommend only when the set is small (five or fewer) and coherent.
- **Choose session(s):** free selection by name or identifier.

Analyze **only the selected sessions**.

## 3. Analysis

Follow the evidence across the conversation, Unblocked calls and results, plans, implementation, tests, and the final code when available. Look for:

- **Influence:** what Unblocked surfaced that the developer was unlikely to find from the code in front of them, and what it changed. Trace chains like `Unblocked evidence → new question or conflict → decision → outcome`.
- **Incremental value and provenance:** what came from Unblocked (and which source type—PR description, review comment, issue, Slack, doc) versus local search, the user, other tools, or general knowledge. Give the likely counterfactual without exaggerating it.
- **Hindsight:** check each impact finding against final code, merge history, or later sessions. 
- **Failures and limits:** call errors, timeouts, auth problems, unanswered questions, misleading context, and what the agent did instead.
- **Missed opportunities:** moments where Unblocked wasn't called but plausibly would have helped. If an Unblocked MCP server is available now, read its tool descriptions to learn which sources are connected. Name the source type that might have helped; stay tentative about what it would have returned.
- **Unnecessary calls:** calls where local sources already had the answer, or the result added only latency or noise.
- **Source overlap:** other MCP servers that reach the same underlying sources as Unblocked. For calls to those servers, judge whether the question would have suited Unblocked better (open-ended, cross-source, or historical questions where synthesis helps).

Focus on the few findings that truly shaped the work.

### Attribution

Unblocked supplies context; the agent and developer decide what to do with it. Attribute in both directions: an agent's misuse of accurate evidence is not an Unblocked failure, and an outcome the agent would plausibly have reached anyway is not an Unblocked success. Label inferences as inferences.

Label each finding:

- **Changed decision:** altered a plan or implementation.
- **Reduced risk:** prevented a plausible wrong turn.
- **Corroborated:** confirmed a choice already being made.
- **Accelerated navigation:** located relevant code or history faster.
- **Background only:** no visible effect.
- **Unused:** returned but not used.
- **Slowed down:** added noise or detours without changing the outcome.
- **Misled:** pushed the work in a wrong or costlier direction.

Mark each with a **Hindsight** marker (if there is enough evidence found to conclude one): **Held up**, **Partly held up**, **Stale**, **Wrong**, **Misleading**, **Irrelevant**, **Unusable**, or **Agent misread accurate evidence**. An honest partial answer or correctly labelled negative finding counts as **Held up**.

For each analyzed session, record:

- **Estimated ambient context need:** the triage rating.
- **Returned-context value:** decisive, useful, unused, misleading, or unavailable (not called or failed).
- **Context effect:** helped, hurt, mixed, or none.
- **Outcome driver:** context, agent behavior, or both; note environment failures separately.

## 4. Create the HTML report

Write a self-contained HTML file with embedded CSS and no external runtime dependencies. Write for a reader who wasn't in the sessions and doesn't know the codebase: say what each piece of work was trying to achieve, keep the top readable on its own, and push detail into collapsible sections. State each finding once.

Structure:

- **Title:** **Unblocked session impact**, as both `<title>` and visible heading.
- **Executive assessment** that stands on its own.
- **Method note** (one line): generated by the `unblocked-insights` skill published by Unblocked, which sessions were analyzed, and how they were selected.
- Collapsed `<details>`: **All sessions found and their estimated ambient context need**—every session with identifier or date, goal, category, rating, and a short rationale.

Then these sections, in order:

1. **Statistics.** Two separate counts: **sessions found** by rating, and **sessions analyzed**. All other statistics cover only analyzed sessions. Include breakdowns of impact labels and Hindsight markers where useful.
2. **Available context sources.** MCP servers available in the analyzed sessions and call counts for each, including Unblocked; zero for available-but-unused. Say so if availability is inferred from calls. Mark which servers overlap with Unblocked's sources, if you have that information.
3. **Impact.** Findings ranked by leverage, each with its label, the Unblocked evidence and source type, the decision chain, incremental value, and Hindsight marker with a one-line basis.
4. **Failures and limits.**
5. **Missed and unnecessary calls.**
6. **Recommendations.** Evidence-based advice on how this developer should use and verify Unblocked in similar work, including where *not* to call it.

Optionally end with one free-form section for an overall theme or caveat that doesn't fit above.

Style the report lightly in Unblocked's visual identity:

- **Fonts:** DM Sans for text; DM Mono for eyebrows, labels, numbers, and stats. Fall back to system sans-serif and monospace stacks so the file still renders offline.
- **Accent colors:** `#675BD5` (periwinkle dark) for links, rules, table headers, and stat figures on white; `#ADA3FF` (periwinkle light) for secondary chart series and accents on dark backgrounds.
- **Neutrals:** background `#FFFFFF`, subtle background `#F8F7FC`, text `#17142B`, secondary text `#4A4664`, muted text `#7E7A96`, borders `#E4E1EF` / `#EFEDF7`.
- **Red** `#E70000` sparingly, only for wrong or harmful findings.
- Build charts in HTML/CSS or inline SVG with these tokens. Do not draw or imitate the Unblocked logo.


Tell the user where the report was written, the net verdict, the strongest positive finding, and the most important caveat or negative finding. Open the report in the browser.
