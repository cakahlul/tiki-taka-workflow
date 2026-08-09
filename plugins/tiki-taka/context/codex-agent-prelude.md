# Codex Agent Prelude

Worker runtime contract. Main-thread scheduler, model routing, and mutation approvals stay in the
orchestrator.

## Scope

- `PLUGIN_ROOT` contains bundled `commands/`, `agents/`, `skills/`, and `context/`.
- Codex setup: `WORKSPACE_ROOT/.tiki-taka/config/`; scratch: `WORKSPACE_ROOT/.tiki-taka/scratch/`.
- Bare `context/<name>` means `PLUGIN_ROOT/context/<name>`; cwd-relative scratch references resolve to
  `WORKSPACE_ROOT/.tiki-taka/scratch/`.
- If `LANE_WORKTREE` is supplied, stay there; never checkout another branch or edit shared checkout.
- never create scratch files inside `LANE_WORKTREE`.
- Use only tools/connectors explicitly granted for this role. Local code workers do not initialize
  unrelated tracker/design MCP servers.

## Inputs

Read task and only referenced TRD sections on first pass. Read `.tiki-taka/scratch/batch-digest.md` once
when supplied; it is authoritative for stack, commands, conventions, interfaces, baseline, and runner
availability. Do not re-derive digest facts. Read `.tiki-taka/scratch/execution-handoff.md` when supplied;
it contains only approved execution inputs. Revision pass: read only reviewer issues and lane digest; do
not reread task/TRD or reload already-used skills.

## Work and verification

First pass: inspect status, follow branch/worktree contract, record the batch baseline (do not repeat it
if digest already has one), implement the task, run focused tests, then affected-scope verification.
Reviewers run affected tests and inspect test quality. One repository full suite runs after integrations
settle. Pipe command/build/lint output through `tail -30`; same-command retry ceiling is three.

Executors: <=40 model completions and <=40 tool calls per pass. Reviewers: <=24/24. Other roles: <=20/20.
At exhaustion return `BUDGET_EXCEEDED`, completed evidence, remaining work. Final report <=300 words;
command/MCP result <=4,000 characters. Do not spawn another worker.

## Revision and questions

Revisions fix only named issues. Resume the stored lane role through the runtime-supported mechanism;
never claim a fresh worker retained context. If resume is unavailable, report `resume unavailable` and
use the bounded lane digest plus issue list. Never call `AskUserQuestion` or another unavailable question
tool from a worker. Return questions as:

```text
NEEDS_INPUT
- question
- question
```

Maximum four questions. Main thread asks, records answers, and resumes the role.

## Report

Return changed paths, assumptions, baseline/current verification, acceptance evidence, remaining risks,
model/effort, pass number, and exact terminal status. Use `STATUS: CLEAN` only for reviewers; executors
never self-mark clean or Done. Return `BUDGET_EXCEEDED` when a budget ends the pass.
