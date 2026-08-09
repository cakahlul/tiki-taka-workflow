---
description: Run planning, then a DAG-based parallel execute-review pipeline with persistent lane roles and bounded token cost.
---

# Development Workflow

`RUNTIME=claude` for this command. Codex adapters resolve the same document with
`RUNTIME=codex`. Read `context/model-policy.md` once in the main thread. Resolve model, effort,
`fork_context: false` (Codex), role budgets, and capability scope immediately before each delegation.
The main-session model/effort does not override workers unless the user explicitly names delegated
workers. Never use Sol as an automatic default.

## Setup and inputs

Run setup gate first. A complete Claude setup has `<!-- SETUP: complete -->` in
`context/tool-providers.md`; Codex uses workspace `.tiki-taka/config/`. If absent or placeholder-only,
stop and run setup. If partial, ask only missing sections. Read team context and provider config once.
Pass providers only to roles that need them. Local code-only roles receive no tracker/design connector
when scope is supported; if host injection cannot be disabled, state the exact limitation.

For coding work, run `minimal-solution-check` before implementation. Preserve security, data-loss,
migration, accessibility, and acceptance gates. Main thread keeps `context-budget.md`; workers get only
the compact runtime prelude, role rules, locations/sections, and task inputs.

Planning documents go to `.tiki-taka/scratch/`; `technical-writer` is one publisher. Reuse its stored
context between Stage A and Stage B; do not create a second publisher for phase status.

## Planning phase

1. Dispatch `prd-analyst` and read-only `project-scout` concurrently; they are independent. Scout never
   checks out, pulls, stashes, cleans, resets, reverts, or writes source/config. Relay any structured
   `NEEDS_INPUT` questions through the main thread; record answers in `qa-log.md`.
2. After both finish, dispatch `prd-slicer` with their locations. A PRD already supplies a
   specification; do not invoke `spec-driven-development` from slicer or TRD writer. Slicer writes
   rollout phases with `Status: NOT STARTED`, technical dependency order, and active phase.
3. Dispatch `em` in `estimate` mode only when the estimate will be used. It uses 30 max turns and
   20/20 completion/tool budgets. Skip otherwise and report that choice.
4. Dispatch `trd-writer` for active-phase per-stack TRDs. It writes scratch only, keeps task contracts
   and dependency signatures, and deletes unused template sections.
5. Resume the same `technical-writer` context for Stage A publication. Capture published locations.
6. Dispatch `task-breaker` with TRD locations and active phase. It reads configured `Task Creation Skill`
   and invokes it deliberately when non-empty; if unavailable, records the fallback and continues with
   bundled task rules. It creates location-based tasks with dependencies and objective acceptance criteria.
7. Resume the same publisher for Stage B: Analysis & Rollout Plan, task locations, and QA log. Keep
   scratch on publish failure. Record publisher ID/name for later phase-status updates.
8. Write `.tiki-taka/scratch/execution-handoff.md` (<=800 words): approved artifacts, repositories,
   task DAG, exact commands, one baseline per changed repository, unresolved risks, and worker routing.
   Do not paste planning transcripts. If host supports documented context reset/compaction, use it;
   otherwise give one exact fresh-session command and disclose history replay.

### Planning gate

Present rollout phases, active phase, epics/stories/tasks, locations, estimate choice, baseline, risks,
and open questions. Ask `Proceed` or `Revise`. Route revision to artifact owner, update QA log, reuse
publisher, and repeat. Do not dispatch executors before `Proceed`.

Choose execution mode at the gate when not already specified. `Parallel` is default: all currently-ready
independent tasks run concurrently within capacity. `Economy` is opt-in sequential scheduling; it shares
the same digest and gates but trades wall-clock time for potentially lower coordination overhead. Do not
claim a fixed percentage or that parallel costs 2x.

## Execution-only entry

Use for fully described named tasks, existing task-list subsets, or em-review gap tasks. Do not re-plan,
re-run task-breaker, or create publication workers. Read only named task sections and referenced TRD
sections. Write the same execution handoff and batch digest. Ask mode once only when no mode was given;
default to parallel.

## Batch digest and test policy

Before dispatching any execution batch, main writes `.tiki-taka/scratch/batch-digest.md` <=500 words:
repository/stack; exact test/build/lint commands; one convention `file:line` example; shared interfaces;
baseline failures; runner availability; DAG. Source from planning artifacts and bounded main inspection;
never spawn a scout just for it. Pass same digest to every executor and reviewer. Workers do not rederive
its facts. Run one baseline per changed repository before dispatch, focused tests during implementation,
affected-scope tests in reviewers, and one full repository suite after integrations settle.

## Execution: ready-queue state machine

Parallel remains default high-throughput path. Build a DAG from task dependencies. Never run a dependent
task concurrently merely because a contract can be guessed. Contract-first speculative parallelism needs
explicit user approval for that dependency.

Store `.tiki-taka/scratch/lanes.json`, atomically updated. Each lane records:

```json
{
  "task": "T-001",
  "status": "WAITING",
  "executorAgentId": null,
  "reviewerAgentId": null,
  "passCount": 0,
  "executorModel": "",
  "executorEffort": "",
  "reviewerModel": "",
  "reviewerEffort": "",
  "resumeStatus": "pending",
  "digest": ".tiki-taka/scratch/batch-digest.md",
  "worktree": ""
}
```

Use statuses `WAITING`, `EXECUTING`, `REVIEWING`, `REVISING`, `CLEAN`, `STOPPED`. State transition:

```text
ready = unfinished tasks whose prerequisites are integrated
fill free slots from ready
executor complete -> that lane reviewer
NEEDS_REVISION -> resume that lane executor
CLEAN -> integrate -> unlock dependents -> refill
```

At first executor/reviewer spawn capture separate IDs. Keep contexts independent. Claude revisions use
`SendMessage` with stored agent ID/name. Codex revisions use the runtime-supported resume/send-input
operation; never invent a tool name. If unavailable, send only digest + issue list and record
`resume unavailable`. A supported resume creates zero new contexts. Same publisher context is reused.
Read the exact collaboration-tool declaration before first use; never trial-call guessed argument names.
After each spawn wave, validate and persist every exact non-empty returned ID before waiting. Wait only on
a non-empty set of persisted IDs; never guess, truncate, wildcard, or invent an ID. A missing/invalid ID
stops that lane without a wait call.

Run at most three automatic execute-review cycles per task. After third non-clean verdict, stop lane and
ask before another. Executor budget: 40 model completions/40 tool calls; reviewer: 24/24; other roles:
20/20. `BUDGET_EXCEEDED` returns completed evidence and remaining work. These are hard only when runtime
enforces them; otherwise ledger marks advisory. Worker reports <=300 words; command/MCP output <=4,000
characters; any combined outer tool result stays <=10,000 characters. No worker spawns another worker. Worker questions return `NEEDS_INPUT` with at most four
questions; main asks, records, resumes.

Wait for blocking completion events or one completion wave. No periodic polling. One status nudge only
after genuine timeout, then stop unresponsive lane. Completion handling is first action after observing
any completion: update lane, enqueue next job, refill before any commentary, status call, integration, or
unrelated work. Never wait for a user prompt to refill capacity. No global execute or review barrier.

## Isolation, status, and shipping

Two simultaneous mutating lanes in one repository require separate `<repo>/.worktrees/<task-id>/`
worktrees. One mutating lane may use the prepared story branch after dirty-tree checks. Different
repositories need no worktree solely for uniformity. Pass assigned path as `LANE_WORKTREE`. Reuse dependency caches/links; do not install once
per lane when safe cache/link works. Do not claim path placement guarantees prompt-cache reuse.
Persist distinct non-empty paths before spawning same-repository lanes; disjoint expected files do not
waive isolation. Stop before dispatch when any required path is empty or duplicated.

Main performs narrow tracker transitions to `In Progress` and `Done`, plus Story rollup. No status-only executor.
Never call a full executor solely for status. Main performs mechanical phase status, or resumes stored publisher if
connector ownership requires it. Preserve `CLEAN -> commit -> push -> Done`; phase `DONE` requires every
active-phase task clean, committed, and pushed. Review summary is user-facing full prose.

On `CLEAN`, commit/integrate/push lane promptly; other active lanes continue. Integration conflict reopens
only affected lane, increments pass count, resumes executor, and re-reviews. Remove worktree only after
integrated and pushed. Do not commit/push/publish/transition external tickets unless workflow and user
authorize it.

## Accounting and final report

Write `workflow_start`/`workflow_end` timestamps and a compact `.tiki-taka/scratch/token-ledger.json` with
observed worker IDs, roles, models/efforts, waits, nudges, fresh spawns, resumes, and fallbacks. Include
token/completion/tool-call fields only when current-tree telemetry is directly exposed. Otherwise use
`null` and `telemetryStatus: host-postrun-required`; never fabricate cap compliance. Whole-tree parsing is
a post-run parent/harness task. The active workflow never searches user-home caches or session history
for its own log. Public-rate credits remain labeled estimates; never treat a CLI footer as tree total or
infer private weekly percentage.

Post-fix spawn formulas (N tasks, R revision cycles, E optional estimate): full planning = `6 + E`
fresh contexts (prd-analyst, project-scout, prd-slicer, trd-writer, task-breaker, one reused publisher);
execution-only with zero revisions = `2N`; additional fresh contexts per revision = `0` when resume is
supported, otherwise at most `2R` bounded fallbacks; tracker/phase status workers = `0`; maximum
automatic cycles = `3`. Report actual ledger counts beside these formulas.

Final response: root fixes; files; before/after formulas and word counts; static test results; ledger
summary; runtime limitations; benchmark result or safe skip reason. Do not claim exact savings before
measurement. Do not commit or push.
