# Codex Runtime Compatibility Contract

Canonical workflow lives in `commands/`; this file carries only Codex-specific execution rules.

## Paths and setup

- `PLUGIN_ROOT` contains `.codex-plugin/`, `commands/`, `agents/`, `skills/`, and `context/`.
- Codex mutable setup lives at `WORKSPACE_ROOT/.tiki-taka/config/`, never in the installed plugin:
  `team-context.md` and `tool-providers.md`. Missing setup uses bundled templates for placeholder checks.
- Scratch lives at `WORKSPACE_ROOT/.tiki-taka/scratch/`. Never create scratch files in `LANE_WORKTREE`.
- Never read the mutable plugin copies as Codex config; those files belong to Claude Code.
- A Codex reference to `/tiki-taka:<name>` means the installed Codex skill, not a Claude slash command.
- Setup/reset may write workspace config only after their stated confirmation gates.
- Prove the active plugin only with the resolved `PLUGIN_ROOT/.codex-plugin/plugin.json` and the exact
  Tiki-Taka entry filtered from `codex plugin list`. Never recursively search the user home, plugin
  caches, or session history.

## Worker dispatch

Before first delegation, read `context/model-policy.md`. Resolve runtime, role tier, model, effort,
`fork_context: false`, budgets, capability scope, and fallback in the main thread. Do not pass the
policy, runtime, context-budget, or comms files to workers; pass only the compact prelude, role rules,
locations/sections, task, batch digest, and output contract.

Every spawn payload uses exactly one accepted content field: `message` or `items`, never both. If the
runtime schema is not already exposed, discover only exact collaboration-tool names and print
`matches.map(x => x.name)`; never serialize `ALL_TOOLS` collections or unrelated schemas/descriptions.
Before invoking a deferred collaboration tool, inspect that exact tool's declaration once and read its
required argument names. Never guess argument aliases or trial-call candidate schemas.
If collaboration is unavailable, report it; never silently degrade a required parallel stage to serial
execution.

Use the runtime's supported blocking wait/completion operation. Use its supported resume/send-input
operation for revisions. Do not invent a tool name. If resume is unavailable, send only a bounded
lane-state digest plus reviewer issues, create no fake claim of retained context, and record
`resume unavailable` in the run ledger. Workers never spawn workers; questions return as a structured
`NEEDS_INPUT` block for the main thread to ask and record.

Worker defaults: command/MCP output <=4,000 characters, report <=300 words. Executors get 40 model
completions/40 tool calls per pass; reviewers 24/24; other roles 20/20. Budget exhaustion returns
`BUDGET_EXCEEDED` with completed evidence and remaining work. These are hard only where the host exposes
limits; otherwise label them advisory in the ledger.
One outer tool response, including concatenated parallel results, stays <=10,000 characters. Filter or
summarize nested results to <=8,000 characters combined before wrapper overhead; never concatenate
several maximum-size results.

## Shared handoff and digest

At planning/execution boundary, write `.tiki-taka/scratch/execution-handoff.md` (<=800 words) with
approved artifacts, repositories, task DAG, commands, baseline, unresolved risks, and worker routing.
Do not paste planning transcripts. If host supports documented context reset/compaction, use it; if
not, give the user one exact fresh-session execution command and state that old history will replay.

Before every execution batch, write `.tiki-taka/scratch/batch-digest.md` (<=500 words) from existing
planning artifacts plus bounded main-thread inspection. Include only repository/stack, exact test/build/
lint commands, one `file:line` convention example, shared interfaces, baseline failures, runner
availability, and task DAG. Pass the same path to every executor and reviewer in parallel or economy
mode. Workers must not re-derive digest facts. One baseline per changed repository occurs before dispatch;
executors use focused tests, reviewers use affected tests, and one full suite gates settled integrations.

## DAG scheduler

For every canonical parallel stage, the main agent MUST run this event loop until no lane is active or
runnable. Keep state in `WORKSPACE_ROOT/.tiki-taka/scratch/lanes.json`, updated atomically with `jq`.
Each lane has `{task, stack, repository, status, executorAgentId, reviewerAgentId, passCount,
executorModel, executorEffort, reviewerModel, reviewerEffort, resumeStatus, digest, worktree}`.
Statuses: `WAITING`, `EXECUTING`, `REVIEWING`, `REVISING`, `CLEAN`, `STOPPED`.

**Ready queue:** `ready = unfinished tasks whose prerequisites are integrated`. Fill available runtime
capacity from `ready`; dependents wait for integrated prerequisites; queue dependents until prerequisites are integrated. Contract-first speculative
parallelism requires explicit user approval for that dependency and is not default.

**Fill loop:** launch all currently-ready independent tasks up to runtime capacity, consecutively before
waiting. Capture the exact non-empty ID returned by each first executor/reviewer spawn. Immediately after
each spawn wave, validate and atomically persist every returned ID plus lane status before any wait or
dependent dispatch. Never defer ID writes until workflow end; never guess, truncate, wildcard, or invent
an ID. On executor completion, record evidence and launch that lane's reviewer immediately. Keep executor
and reviewer contexts independent.

Before spawning two mutating lanes for one repository, require distinct non-empty worktree paths in lane
state. Never run them in one shared checkout, even when their expected files are disjoint; stop before
dispatch if isolation is missing.

**Completion handling:** wait once for a blocking completion event or completion wave. Do not poll. Remove
completed ID, update lane state, enqueue its next job, then run the fill loop **before any commentary**.
This completion handling is the first action after observing any completion.
Wait targets must be a non-empty array built only from exact persisted IDs. A missing or invalid ID stops
the affected lane; do not call wait and do not retry with guessed keys or IDs.
No periodic polling.
At most one status nudge after a genuine timeout; then stop the lane if it remains unresponsive.
Reviewer `NEEDS_REVISION` resumes the same executor with only issue list and digest; reviewer re-verification
resumes the same reviewer. A supported resume creates zero new contexts. One nudge is allowed only after
a genuine timeout; stop an unresponsive lane after that nudge. Maximum automatic execute-review cycles:
three; ask before another.

Never wait for a user prompt to refill capacity. Never impose global execute/review barriers. A clean lane
integrates, then unlocks dependents and refills. Main thread performs narrow tracker/phase transitions;
never dispatch a full executor only to set status. Preserve `CLEAN -> commit -> push -> Done`.

## Isolation and capability scope

- Two simultaneous mutating lanes in one repository require separate `<repo>/.worktrees/<task-id>/`
  worktrees. One mutating lane may use the prepared story branch after dirty-tree checks. Lanes in
  different repositories do not need worktrees for uniformity.
- Reuse dependency caches/links; never install dependencies once per lane when a safe cache works.
- Never claim repository-relative paths guarantee prompt-cache reuse; caching depends on runtime prefixes.
- Give each role only required tools, skills, and MCP/connectors. Local code-only workers do not initialize
  tracker/design connectors when role scoping is supported. If host injection cannot be disabled, state
  the limitation and exact supported user config; do not invent a plugin field.
- `project-scout` is read-only: no checkout, pull, stash, clean, reset, revert, or source/config writes.

## Accounting

At workflow start/end, write timestamps and a compact `.tiki-taka/scratch/token-ledger.json` containing
observed scheduler counts, worker IDs, roles, models, efforts, waits, nudges, fresh spawns, resumes, and
fallbacks. Include token/completion/tool-call fields only when the host directly exposes telemetry for
the current parent tree. Otherwise write those fields as `null` with `telemetryStatus` set to
`host-postrun-required`; never fabricate values or claim a cap passed.

Exact whole-tree aggregation happens after completion in the parent launcher or benchmark harness. Never
scan the user home, plugin caches, `.codex/sessions`, or historical logs from inside the active workflow
to discover its own log. Public-rate credits stay separate estimates, and a CLI `tokens used` footer is
never a whole-tree total.

## Safety

Inspect status before mutation. Preserve unrelated changes. Do not commit, push, publish, transition
external tickets, or modify external documents unless the invoked workflow and user authorize it.
Do not claim a hard runtime cap where host enforcement is absent.
