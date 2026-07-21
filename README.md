# tiki-taka

A PRD-to-ship development workflow orchestrator for any software team. It runs a critical-thinking
planning pipeline (challenge the PRD, slice by technical dependency, write a TRD, break into tasks)
and a parallel execute→review barrier loop with contract-first dependency handling — as a
**command-only plugin** that runs ONLY when you call its slash command, with no auto-trigger.

Team-agnostic: nothing is hardcoded to a specific squad, and it works with whatever issue
tracker / wiki you use (JIRA, Linear, GitHub Issues, Confluence, Notion, or plain `.md` files).
The agent and skill `.md` files are model-agnostic — usable by any coding assistant that reads
markdown agents/skills, not only Claude.

## Commands

| Command                     | Function                                                                                                                                                                                                         |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/tiki-taka:setup-workflow`   | Configure the plugin for your team: asks where PRD-slices / TRD / tasks go, which MCP/tools serve them, project location + team assignment, and design-tool provider. Writes the answers so the workflow agents stop asking. |
| `/tiki-taka:reset-workflow`   | Reset the plugin back to generic — undo `setup-workflow`. Restores `context/team-context.md` to its blank template and deletes `tool-providers.md`. No agent files are touched.                                    |
| `/tiki-taka:dev-workflow`   | Development Workflow: Planning Phase (prd-analyst + project-scout → prd-slicer → trd-writer → task-breaker) → Execution Phase (parallel execute barrier → parallel review barrier, repeat until CLEAN) → Commit & Push → review summary → status update. |
| `/tiki-taka:bug-workflow`   | Bug Fixing Workflow: project-scout (repo/stack) → bug-analyst (severity + root cause) → parallel fixing executor-review loop → commit & push → review summary → status update → incident-reporter (if Critical/High).                                        |

`dev-workflow` and `bug-workflow` read `context/team-context.md` (Local Repo Roots, Squad Members,
Repository Mapping, Feature Scope) at the start.

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
- **Status updates.** Executors move the ticket to **In Progress** at the start, and to **Done**
  after CLEAN + commit + push (mandatory order: CLEAN → commit → push → Done). When every child of a
  parent Story is Done, the Story is transitioned to **Done** too. Each status change is reported to
  you so it is clear what is finished vs still in progress. Skipped for local `.md` tasks or when no
  tracker tool is connected.

## Setup — configure your team first

Run `/tiki-taka:setup-workflow` and answer the prompts; it writes your answers to
`context/team-context.md` and `context/tool-providers.md` so the workflow agents use your setup
instead of asking. Alternatively, edit `context/team-context.md` by hand — it ships as a **template
with placeholders**: the absolute paths where your repos live, feature scope, members, and repository
mapping. The workflow commands refuse to run while the placeholders are still in place. Nothing in the
plugin is hardcoded to a specific team. Undo with `/tiki-taka:reset-workflow`.

Optional integrations: agents can read/write PRDs, TRDs, tasks, and incident reports through
whatever issue-tracker or wiki tool is connected in your session (an MCP server, CLI, or API for
JIRA/Linear/GitHub Issues/Confluence/Notion, etc.), and drive the browser via a browser-automation
MCP (Playwright / Chrome DevTools). If none is connected, the agents fall back to local `.md` files
and tell you — the workflow still runs.

## Installation

**Install from Bitbucket (recommended):** register the repo as a marketplace by its Git URL, then
install. The marketplace name is `tiki-taka-workflow` (the `name` in `.claude-plugin/marketplace.json`).

```bash
claude plugin marketplace add git@bitbucket.org:tunaiku/tiki-taka-workflow.git
claude plugin install tiki-taka@tiki-taka-workflow
```

SSH URL needs your Bitbucket SSH key set up; HTTPS works too
(`https://bitbucket.org/tunaiku/tiki-taka-workflow.git`, prompts for an app password on a private repo).
Pull later updates with `claude plugin marketplace update tiki-taka-workflow`.

> `setup-workflow` writes `context/team-context.md` + `tool-providers.md` into the installed copy;
> a `marketplace update` may overwrite them, so rerun `/tiki-taka:setup-workflow` after updating.

After install, run `/tiki-taka:setup-workflow` to configure the plugin for your team.

## 13 Subagents

**Planning:** prd-analyst, prd-slicer, project-scout, trd-writer, task-breaker
**Execution:** be-executor, be-reviewer, fe-web-executor, fe-web-reviewer, fe-mobile-executor,
fe-mobile-reviewer
**Bug:** bug-analyst, incident-reporter (repo/stack resolution reuses project-scout)

## Bundled skills (17)

Self-contained — every skill referenced by an agent is bundled along, no need to install another plugin:

`minimal-solution-check`, `test-driven-development`,
`incremental-implementation`, `debugging-and-error-recovery`, `api-and-interface-design`,
`source-driven-development`, `code-review-and-quality`, `code-simplification`,
`security-and-hardening`, `performance-optimization`, `planning-and-task-breakdown`,
`spec-driven-development`, `interview-me`, `idea-refine`, `browser-testing-with-devtools`,
`frontend-ui-engineering`, `doubt-driven-development`.

## Notes

- **Command-only**: the orchestration entry point is only via `/tiki-taka:*`. Skills may be model-invoked
  (called by Claude itself when the context fits) — that is exactly their nature as support.
- Team data is not hardcoded — it lives entirely in `context/team-context.md`, which you fill in (see Setup).
- **Minimality is built in**: agents lean on the bundled `minimal-solution-check` skill, so no external
  plugin is required. If you also install a dedicated laziness plugin like `ponytail`, it layers on top and
  makes the minimality bias stronger — but it stays fully optional.
