---
name: ask-unblocked
description: >
  Answer any question about the codebase, team, or organization using Unblocked
  context. Use when the user asks a question that code alone can't answer — why
  something exists, who worked on it, what was decided, how systems connect, or
  what happened during an incident. Synthesizes context from PRs, docs, chat,
  issues, incidents, and code into a cited answer. Renders diagrams for
  architecture questions, tables for tradeoffs, and always cites sources.
---

# Ask Unblocked

Answer the user's question by researching organizational context — PRs, docs, chat, issues, incidents, code history. Produce a cited, well-formatted answer. Does not make code changes.

## Gotchas

- **Answering from code alone.** Code shows WHAT, not WHY. Always research organizational context first — the answer is usually in a PR description, Slack thread, or design doc.
- **Unsourced claims.** Every factual statement must trace to a source. If you can't cite it, qualify it as inference.
- **Shallow research.** One query is rarely enough. Follow threads: a PR references an issue, an issue references a Slack discussion, a discussion references a design doc. Chase the chain.
- **Dumping raw results.** Synthesize. The user asked a question — answer it, don't paste search results.

## How This Works

1. **Classify the question** to determine research strategy:
   - **Architecture / how it works** → research system design, dependencies, data flow. Render a **Mermaid diagram**.
   - **Tradeoffs / comparisons / optimizations** → research decisions, alternatives considered, constraints. Render a **table**.
   - **History / why / who / when** → research PRs, issues, discussions, decisions. Render a **timeline** or narrative.
   - **Incident / what happened** → research incidents, postmortems, changes. Render a **timeline**.
   - **How to / patterns** → research conventions, examples, team patterns. Render **code examples**.

2. **Primary research** via `context_research` (`effort: high`):
   - Formulate the query to maximize cross-source coverage. Include the specific system, feature, or concept from the user's question.
   - Example: "How does [system] work? Architecture, design decisions, dependencies, recent changes, and team discussions about it."

3. **Follow-up research** — based on primary results, drill into gaps:
   - If primary results reference specific URLs (PRs, docs, issues, Slack threads) → fetch full content via `context_get_urls`.
   - If a specific code area is implicated → use local tools (Read, Bash with grep/find) to examine current code.
   - If primary results are thin → run additional `context_research` queries (`effort: low`) with different angles or narrower scope.
   - If the question involves a specific URL the user provided → fetch it via `context_get_urls` first, then research surrounding context.

4. **Synthesize the answer** — structure depends on question type (see step 1). Always include:
   - Direct answer to the question up front.
   - Supporting detail with inline citations.
   - Appropriate visual (diagram, table, timeline, or code example).
   - Sources section at the end.

## Rendering Rules

1. **Citations**: Render links to source documents in markdown URL format: `[descriptive text](url)`. Inline citations where they support a claim, and collect all sources in the final section.
2. **Architecture / component questions**: Render a Mermaid diagram showing relationships, data flow, or system boundaries.
   ````
   ```mermaid
   graph TD
       A[Service A] --> B[Service B]
       B --> C[(Database)]
   ```
   ````
3. **Tradeoffs / comparisons / optimizations**: Render a markdown table with options as rows and evaluation criteria as columns.
4. **Timelines / history**: Render a markdown table with Date, Event, and Source columns, ordered chronologically.
5. **Code patterns**: Render code blocks with file paths as language annotations (e.g., `` ```typescript // src/auth/middleware.ts ```) and explain the pattern.

## Answer Structure

```
## [Direct answer — 1-2 sentences]

[Supporting detail with inline citations and appropriate visual]

---

### Sources
- [Source title or description](url)
- [Source title or description](url)
```

## Tool Selection

| Need | Tool | Notes |
|---|---|---|
| Broad question spanning multiple sources | `context_research` (`effort: high`) | Primary research tool — always start here |
| Narrow follow-up on one entity | `context_research` (`effort: low`) | Anchored on a specific file, service, or concept |
| Full content of a referenced URL | `context_get_urls` | PRs, docs, issues, Slack threads, design docs |
| Current state of code | Read, Bash (grep/find) | Verify context_research findings against live code |
| Focused code search across repos | `context_research` (`effort: medium`) with `"Prefer code results"` instruction | When the answer is in the implementation |

## Abort Conditions

- **Question is purely about current code state** (no organizational context needed) — answer directly from local tools, skip Unblocked.
- **No relevant results from any source** — say so clearly, state what was searched, suggest where the answer might live.
- **Question requires access the user hasn't granted** — report what's accessible and what isn't.
