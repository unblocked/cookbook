# Cookbook

Recipes that compose [Unblocked skills](https://github.com/unblocked/skills) for specific scenarios. Each recipe is a fully functional skill meant to be **forked and customized** for your environment before production use.

## How to Use

1. Browse the recipes below
2. Copy the recipe directory into your project's `.claude/skills/` (or your agent's skill folder)
3. Adjust the workflow to fit your team's tools, conventions, and constraints
4. Update any reference file paths to match your project structure
5. Iterate on the gotchas section as you discover new failure modes

## Available Recipes

### Interactive (human-in-the-loop)

Designed for interactive sessions where a human reviews findings and approves decisions. Use progressive disclosure via `references/` files for detailed templates and guidance.

| Recipe | Description |
|--------|-------------|
| [code-review](recipes/code-review/) | Code review that gathers org context before analyzing a diff — presents findings for discussion |
| [plan](recipes/plan/) | Planning that produces a validated, self-contained implementation plan — presented for user approval |
| [enrich-ticket](recipes/enrich-ticket/) | Enriches an issue from any tracker with related PRs, code paths, and historical context |
| [validate-bug](recipes/validate-bug/) | Validates a bug report by correlating symptoms with recent changes and verifying against code |
| [investigate-incident](recipes/investigate-incident/) | Plans an incident investigation with ranked hypotheses and parallel investigation tracks |
| [gather-evidence](recipes/gather-evidence/) | Gathers and correlates evidence from code, infrastructure, and organizational sources |
| [recommend-fixes](recipes/recommend-fixes/) | Produces ranked fix recommendations validated against historical patterns |

### Headless (no human-in-the-loop)

Designed for autonomous execution — CI/CD, `claude -p`, sub-agents, scheduled tasks. All context is inlined in a single `SKILL.md` (no `references/` dependencies). Autonomous decision-making at review gates with abort conditions.

| Recipe | Description |
|--------|-------------|
| [headless-workflow](recipes/headless-workflow/) | Autonomous coding workflow — `context_research` hydration, autonomous review gates, no user checkpoints |
| [headless-code-review](recipes/headless-code-review/) | Autonomous code review — findings grounded in team patterns, structured report output |
| [headless-plan](recipes/headless-plan/) | Autonomous planning — validated, self-contained implementation plan without writing code |
| [headless-enrich-ticket](recipes/headless-enrich-ticket/) | Autonomous ticket enrichment — related PRs, code paths, and historical context |
| [headless-validate-bug](recipes/headless-validate-bug/) | Autonomous bug validation — correlates symptoms with recent changes, verifies against code |
| [headless-investigate-incident](recipes/headless-investigate-incident/) | Autonomous incident investigation — ranked hypotheses, agent-optimized output |
| [headless-gather-evidence](recipes/headless-gather-evidence/) | Autonomous evidence gathering — correlation timeline, agent-optimized output |
| [headless-recommend-fixes](recipes/headless-recommend-fixes/) | Autonomous fix recommendations — tiered fixes validated against history, agent-optimized output |

## Running Headless

### Prerequisites

- Claude Code CLI installed (`claude --version` to verify)
- Unblocked MCP server configured (provides `context_research`, `context_get_urls`, etc.)
- API key or authentication set up for non-interactive use

### 1. Install Unblocked

```bash
curl -fsSL https://getunblocked.com/install-mcp.sh | bash
```

### 2. Copy the recipe into your project

```bash
cp -r recipes/headless-workflow /path/to/your-project/.claude/skills/headless-workflow
```

### 3. Run with `-p` (print mode)

Claude auto-discovers skills from `.claude/skills/` and follows the workflow:

```bash
claude -p "Implement rate limiting for the API" \
  --allowedTools "Bash,Read,Edit,Write,Grep,Glob" \
  --output-format json
```

### 4. CI/CD and Docker (bare mode)

In `--bare` mode, auto-discovery is disabled for faster, reproducible runs. Load the skill and MCP config explicitly:

```bash
claude --bare -p "Implement rate limiting for the API" \
  --allowedTools "Bash,Read,Edit,Write,Grep,Glob" \
  --mcp-config ./mcp.json \
  --append-system-prompt-file .claude/skills/headless-workflow/SKILL.md
```

Create an `mcp.json` pointing to the Unblocked MCP server:

```json
{
  "mcpServers": {
    "unblocked": {
      "type": "http",
      "url": "https://getunblocked.com/api/mcpsse"
    }
  }
}
```

### Key flags

| Flag | Purpose |
|------|---------|
| `-p` | Run non-interactively (print mode) |
| `--bare` | Skip auto-discovery for faster, reproducible runs |
| `--allowedTools` | Pre-approve tools so the agent doesn't prompt for permission |
| `--mcp-config` | Load MCP servers explicitly (required in bare mode) |
| `--append-system-prompt-file` | Load the skill content explicitly (required in bare mode) |
| `--output-format json` | Get structured output with session metadata |
| `--max-turns N` | Limit agent turns to cap compute cost |
| `--max-budget-usd N` | Set a dollar spend limit |
