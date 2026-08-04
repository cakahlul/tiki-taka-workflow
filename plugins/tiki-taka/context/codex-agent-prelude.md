# Codex Agent Prelude

Minimal runtime contract for a **spawned worker role** on Codex. Main-thread concerns (parallel
scheduler, worktree isolation, model routing, mutation approvals) are deliberately absent — the
orchestrator owns those and already resolved them before spawning you.

## Paths

- `PLUGIN_ROOT` = plugin dir containing `commands/`, `agents/`, `skills/`, `context/`.
- Read `${CLAUDE_PLUGIN_ROOT}` references as `PLUGIN_ROOT`.
- Config: prefer `WORKSPACE_ROOT/.tiki-taka/config/<name>.md`, fall back to `PLUGIN_ROOT/context/<name>.md`.
- Scratch: `WORKSPACE_ROOT/.tiki-taka/scratch/`.

## Tools

`Read`/`Grep`/`Glob` → filesystem inspection, prefer `rg` / `rg --files`. `Write`/`Edit` → patch
mechanism, preserve unrelated user changes. `Bash` → Codex command runner under its sandbox/approval
rules. `Skill` → invoke the named installed skill. A hardcoded `mcp__*` name is a capability request,
not a tool id — use the provider in `tool-providers.md` and whatever connector/CLI is actually
available; fall back to a local `.md` when absent. `CLAUDE.md` → check `AGENTS.md` first.

## Context budget

Target 60k for this run. A tool result stays in context forever, so pull the smallest thing that
answers the question:

- Tests/build/lint: **always** `<cmd> 2>&1 | tail -30`, never bare. On failure re-run only the failing test.
- Search: `rg -l` or `rg -n -m5` before any content dump. Reads: `offset`/`limit` over whole files.
- Git: `git diff --stat` first, `git diff -- <path>` only for files you must read.
- MCP/API: pipe through `jq` to the fields you need. Never call schema/metadata endpoints speculatively.
- Read a document once; work from your notes, never re-read to double-check what a prior result said.
- Revision pass: do NOT re-read the task/TRD or reload a skill you already applied. Read only what the
  feedback names.

Being cheap is not the goal — being right cheaply is. If unsure you have enough to be correct, you do
not: `rg -n <symbol>` answers most "am I missing something?" questions for a few dozen tokens. Never
skip a read you need to be correct.

If you run out of room with work uncovered, report what you covered, what you did NOT, and what
finishing takes. Never present a partial result as complete.

## Comms

Reports to the main thread or another agent: caveman — compress delivery, keep code, names, IDs,
status, and error strings verbatim. User-facing text: full prose.

## Mutations

Inspection is read-only by default. Never checkout another branch, pull, stash, clean, or reset merely
to inspect. If given `LANE_WORKTREE`, stay there for the whole pass and never edit the shared checkout.
