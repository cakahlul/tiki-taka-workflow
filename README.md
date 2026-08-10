# tiki-taka

A runtime-neutral PRD-to-ship development workflow orchestrator for any software team. It runs a
critical-thinking planning pipeline (challenge the PRD, slice by technical dependency, write a TRD,
break into tasks) and a DAG-based execute→review loop that runs ready independent tasks concurrently.
It supports **Claude Code and Codex** from the same workflow source. Use the runtime-specific entry
point for your tool; the large orchestration workflows do not auto-trigger for ordinary coding
requests.

Team-agnostic: nothing is hardcoded to a specific squad, and it works with whatever issue
tracker / wiki you use (JIRA, Linear, GitHub Issues, Confluence, Notion, or plain `.md` files).
The agent and skill `.md` files are model-agnostic — usable by any coding assistant that reads
markdown agents/skills, not only Claude.

<p align="center">
  <img src="assets/tiki-taka-tactic.png" alt="Tiki-taka dev workflow drawn as a coach's tactic board" width="100%">
  <br>
  <em>
    The workflow as a coach's tactic board. <strong>Build-up (planning):</strong> the setup gate
    passes to <code>prd-analyst</code> + <code>project-scout</code> in parallel, up through
    <code>prd-slicer</code> / <code>trd-writer</code> to the <code>task-breaker</code> playmaker.
    <strong>Attack (execution):</strong> through-balls to three parallel task lanes, each
    <code>executor → reviewer</code>; Task&nbsp;B shows the dashed revision loop back-pass.
    <strong>Finish:</strong> every lane arrives at <code>clean → commit → push → done</code> and
    shoots — the ball never stops on the slowest player.
  </em>
</p>

## Usage

The same workflows are available in both runtimes. Use the entry point for the tool you are running:

| Workflow | Function | Claude Code | Codex |
| --- | --- | --- | --- |
| Setup | Configure team context, providers, repositories, and design tools. | `/tiki-taka:setup-workflow` | `setup-workflow` |
| Reset | Restore generic configuration. | `/tiki-taka:reset-workflow` | `reset-workflow` |
| PRD analysis | Analyze a PRD against production code and optionally slice rollout phases. | `/tiki-taka:prd-analyze` | `prd-analyze` |
| Development | Plan and execute ready independent tasks through the execute→review loop. | `/tiki-taka:dev-workflow` | `dev-workflow` |
| Economy mode | Run the execution phase sequentially with the same review and safety gates. | `/tiki-taka:economy-mode` | `economy-mode` |
| Bug workflow | Investigate root cause, fix through reviewed lanes, and report incidents when needed. | `/tiki-taka:bug-workflow` | `bug-workflow` |
| EM review | Audit PRD compliance and offer to trigger execution-only work. | `/tiki-taka:em-review` | `em-review` |

### Claude Code

Run the slash command from the table in a Claude Code session.

### Codex

Invoke the corresponding plugin skill by name in a Codex session. The adapters share the same
workflow definitions, so stages do not have two independent copies that can drift.

`dev-workflow` and `bug-workflow` read `context/team-context.md` (Local Repo Roots, Squad Members,
Repository Mapping, Feature Scope) at the start; each runtime adapter resolves that path to its own
configuration location.

## Branch, push & status conventions

Both workflows follow the same git and tracker discipline so you always know what shipped and where:

- **Branch = Story ticket number.** Before touching code, each executor branches off the repo's
  **default branch** (detected per repo — `main` or `master`). The branch is named after the parent
  **Story** ticket (e.g. `SLS-12345`), so all tasks under one story share one branch. If the story
  branch already exists (another task's executor created it), the executor checks it out instead of
  recreating. No parent Story (flat grouping) or a local `.md` task → falls back to the task's own key.
- **Push, not just commit.** After a task is `STATUS: CLEAN` and committed, its commits are **pushed**
  to the story branch (`-u` on first push).
- **Review summary.** After pushing, the workflow presents a detailed, user-facing walkthrough:
  branch name, files touched, the notable functions/components/endpoints changed (with `file:line`
  references and short code excerpts) — so you can review the work.
- **Status updates.** Main thread performs narrow **In Progress**/**Done** transitions after lane gates;
  no full executor is spawned only for status. Mandatory order: CLEAN → commit → push → Done. When every child of a
  parent Story is Done, the Story is transitioned to **Done** too. Each status change is reported to
  you so it is clear what is finished vs still in progress. Skipped for local `.md` tasks or when no
  tracker tool is connected.

## Setup — configure your team first

Run the setup entry point for your runtime and answer the prompts; it writes your answers to the
runtime's configuration files so the workflow agents use your setup instead of asking. Alternatively,
edit the templates by hand — they ship with placeholders for repo paths, feature scope, members, and
repository mapping. The workflow refuses to run while the placeholders are still in place. Nothing in
the plugin is hardcoded to a specific team. Undo with the reset entry point for your runtime.

Optional integrations: agents can read/write PRDs, TRDs, tasks, and incident reports through
whatever issue-tracker or wiki tool is connected in your session (an MCP server, CLI, or API for
JIRA/Linear/GitHub Issues/Confluence/Notion, etc.). If none is connected, the agents fall back to
local `.md` files and tell you — the workflow still runs.

## Installation

The examples below install from GitHub. The Bitbucket mirror remains available if your team already
uses it.

### Claude Code

Register the GitHub repository as a marketplace, then install the plugin. The marketplace name is
`tiki-taka-workflow` (the `name` in `.claude-plugin/marketplace.json`).

```bash
claude plugin marketplace add git@github.com:cakahlul/tiki-taka-workflow.git
claude plugin install tiki-taka@tiki-taka-workflow
```

HTTPS works too: `https://github.com/cakahlul/tiki-taka-workflow.git`.
Pull later updates with `claude plugin marketplace update tiki-taka-workflow`.

> `setup-workflow` writes `context/team-context.md` + `tool-providers.md` into the installed copy;
> a `marketplace update` may overwrite them, so rerun `/tiki-taka:setup-workflow` after updating.

After install, run `/tiki-taka:setup-workflow` to configure the plugin for your team.

### Codex

Register the GitHub repository as a Codex marketplace, install the plugin, then start a new Codex
thread so the newly installed skills are discovered:

```bash
codex plugin marketplace add git@github.com:cakahlul/tiki-taka-workflow.git
codex plugin add tiki-taka@tiki-taka-workflow
```

For local development from a checkout of this repository:

```bash
codex plugin marketplace add /absolute/path/to/tiki-taka-workflow
codex plugin add tiki-taka@tiki-taka-workflow
```

In the new thread, invoke `setup-workflow` or say “Set up Tiki-Taka for this workspace.” Codex stores
mutable configuration in the target workspace under `.tiki-taka/config/`; it does not edit the
installed plugin cache. Scratch planning artifacts live under `.tiki-taka/scratch/`. Keep `.tiki-taka/`
out of source control when it contains private team configuration or temporary planning data.

Claude Code and Codex configuration are separate. Claude Code uses the installed plugin's
`context/team-context.md` and `context/tool-providers.md`; Codex uses workspace
`.tiki-taka/config/team-context.md` and `.tiki-taka/config/tool-providers.md`. Run setup once per
runtime. Codex never uses Claude's mutable provider files.

The runtime compatibility layer maps provider capabilities to the tools and connectors available in
the current session. Tracker/wiki integrations remain optional and retain the local Markdown fallback
when the configured provider is unavailable.

## Runtime-aware model routing

Tiki-Taka determines runtime from its entry point rather than asking an agent to guess:

- Claude slash command → `RUNTIME=claude`
- Codex workflow skill → `RUNTIME=codex`

Delegated agents use shared tiers. Claude maps `economy`/`balanced`/`strong` to Haiku low, Sonnet medium,
and Opus high. Codex maps them to `gpt-5.6-luna` low/medium and `gpt-5.6-terra` high. Sol is explicit
worker override only. Main-session model/effort does not override workers. Unsupported overrides fall
back once with `fork_context: false` and record the fallback.

Mechanical scouting, publishing, and incident prose default to `economy`; normal planning, coding,
debugging, and first-pass review use `balanced`; EM compliance review, confirmed high-risk work, and
the second revision cycle onward use `strong`. At most two strong agents run concurrently by default.
An explicit user model or effort choice always wins.

The policy lives in `plugins/tiki-taka/context/model-policy.md`; model names are not duplicated across
agent definitions. Codex workers always use `fork_context: false`, one spawn content field, scoped tools,
shared batch digest, bounded reports, and persistent executor/reviewer IDs when resume is supported.

Execution writes `.tiki-taka/scratch/batch-digest.md`, `.tiki-taka/scratch/execution-handoff.md`,
`.tiki-taka/scratch/lanes.json`, and `.tiki-taka/scratch/token-ledger.json`. Parallel mode remains
default; economy changes scheduling only. The ledger always records observed scheduler counts; token
fields are measured only when current-tree telemetry is exposed, otherwise they remain null for post-run
aggregation. Public-rate estimates stay explicitly labeled.

## 15 Subagents

**Planning:** prd-analyst, prd-slicer, project-scout, trd-writer, task-breaker, technical-writer
**Execution:** be-executor, be-reviewer, fe-web-executor, fe-web-reviewer, fe-mobile-executor,
fe-mobile-reviewer
**Bug:** bug-analyst, incident-reporter (repo/stack resolution reuses project-scout)
**Audit:** em in review mode (PRD-compliance auditor, driven by `/tiki-taka:em-review`)

## Bundled skills (18 support skills + 7 Codex workflow adapters)

Bundled support skills and adapters (missing external references are not required by normal workflow):

`minimal-solution-check`, `test-driven-development`,
`incremental-implementation`, `debugging-and-error-recovery`, `api-and-interface-design`,
`source-driven-development`, `code-review-and-quality`, `code-simplification`,
`security-and-hardening`, `performance-optimization`, `planning-and-task-breakdown`,
`spec-driven-development`, `interview-me`, `idea-refine`,
`frontend-ui-engineering`, `doubt-driven-development`, `executor-workflow`, `reviewer-workflow`.

## Notes

- **Explicit orchestration**: use the native entry point for your runtime — Claude Code slash commands
  or Codex workflow skills. Support skills may still be model-invoked when their descriptions match.
- Team data is not hardcoded — each runtime fills its own `team-context.md` during Setup.
- **Minimality is built in**: agents lean on the bundled `minimal-solution-check` skill, so no external
  plugin is required. If you also install a dedicated laziness plugin like `ponytail`, it layers on top and
  makes the minimality bias stronger — but it stays fully optional.
