# Cookbook

Recipes for agent skills that give your coding agent the context your team already has: the PRs, decisions, tickets, threads, and incidents behind the code. Each one is a single `SKILL.md` on the open [Agent Skills](https://agentskills.io) spec, so the same file works in Claude Code, Codex, Devin, Factory, Grok Build, or your own harness. They are short on purpose. They say when to reach for Unblocked and what good output looks like, and leave the rest to the model.

| Skill | Use it when |
|---|---|
| [ask-unblocked](recipes/ask-unblocked/) | A question needs the team's history, not just the code |
| [code-review](recipes/code-review/) | Reviewing a diff where conventions and past decisions matter |
| [plan](recipes/plan/) | Planning a change before any code is written |
| [enrich-ticket](recipes/enrich-ticket/) | A ticket needs context before someone picks it up |
| [validate-bug](recipes/validate-bug/) | Deciding whether a bug report is real and what caused it |
| [investigate-incident](recipes/investigate-incident/) | An alert needs ranked hypotheses and an investigation plan |
| [gather-evidence](recipes/gather-evidence/) | An incident needs a sourced timeline tested against hypotheses |
| [recommend-fixes](recipes/recommend-fixes/) | An incident has a root cause and needs fixes checked against history |
| [risk-triage](recipes/risk-triage/) | A PR carries an Unblocked risk label and needs de-risking |

Every skill runs both interactively and unattended. Unattended, it takes the default at each fork, says which default it took, and lists the forks at the end for a human to review.

## Use a recipe

These are recipes, not a package. Each one shows a working pattern for one job, and it is meant to be copied into your project and changed to fit how your team works before you rely on it.

1. Copy the recipe folder from `recipes/` into the directory your agent reads skills from:

| Agent | Project skills directory |
|---|---|
| Claude Code | `.claude/skills/` |
| Codex, Devin, Factory | `.agents/skills/` |
| Grok Build | `.grok/skills/` |

2. Edit the copy to match your environment: your tracker and incident tools, the queries that find your team's conventions, where output should go (a ticket comment, a PR review, a file), and what your agent may do unattended.
3. Run it on a few real tasks, and add what you learn to the skill.

## Connect Unblocked

Interactive sessions use the Unblocked MCP server (`context_research`, `context_get_urls`). Install the CLI and MCP config, and sign in through the browser:

```bash
curl -fsSL https://getunblocked.com/install-mcp.sh | bash
```

Unattended runs (CI, `claude -p`, Devin, background agents) call the CLI, which prints JSON on stdout:

```bash
export UNBLOCKED_API_TOKEN=...   # or UNBLOCKED_API_TOKEN_FILE=/run/secrets/unblocked-token
unblocked context-research --query "How does checkout retry failed payments?" --effort medium
```

For a remote MCP client without the CLI, send your token as a header:

```json
{
  "mcpServers": {
    "unblocked": {
      "type": "http",
      "url": "https://getunblocked.com/api/mcpsse",
      "headers": { "Authorization": "Bearer ${UNBLOCKED_API_TOKEN}" }
    }
  }
}
```

The same calls are available over REST at `POST https://getunblocked.com/api/v1/context/research` and its siblings, if your plan includes the Context API. See the [Unblocked docs](https://docs.getunblocked.com) for tokens and setup per agent.

## License

MIT. See [LICENSE](LICENSE). Copy, change, and redistribute the recipes freely.
