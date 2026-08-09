---
description: Run read-only triage, then bounded DAG-based bug-fix execute-review lanes with persistent role contexts.
---

# Bug Fixing Workflow

`RUNTIME=claude`; Codex adapter maps this command through `context/codex-runtime.md`. Read model policy
once. Main-session model/effort is not a worker override. Resolve each role's model, effort,
`fork_context: false` (Codex), budgets, and scoped capabilities at dispatch. Sol is never automatic.

## Setup and triage

Run setup gate before any agent. Claude reads plugin `context/team-context.md` and
`tool-providers.md`; Codex reads workspace `.tiki-taka/config/`. Missing/placeholder setup stops with
setup guidance. Provider scope goes only to roles that need it.

For coding fixes, call `minimal-solution-check` first. Main owns questions: agents return
`NEEDS_INPUT` with up to four questions; main asks, records, resumes.

1. Call read-only `project-scout` unless report already provides an unambiguous repository/stack. Scout
   never checkout, pull, stash, clean, reset, revert, or write source/config.
2. Call `bug-analyst` after repo resolution. It reads the report, severity, root cause, shared callers,
   and emits either one fix lane or location records `{localId, dependsOnLocalIds, contract}`. Do not
   spawn a scout just to build shared context.
3. Main writes `.tiki-taka/scratch/batch-digest.md` <=500 words with repo/stack, commands, one convention
   `file:line`, shared interfaces, one baseline per repo, runner availability, and fix DAG. Write
   `.tiki-taka/scratch/execution-handoff.md` <=800 words for execution-only handoff. No transcript paste.

## Fix lanes

Independent ready lanes run concurrently up to runtime capacity. Dependent lanes wait until prerequisites
are integrated; contract-first speculation requires explicit user approval. State lives in
`.tiki-taka/scratch/lanes.json` with separate `executorAgentId`/`reviewerAgentId`, pass count, model,
effort, status, digest, worktree, and `resumeStatus`.

```text
ready = unfinished fixes whose prerequisites are integrated
fill free slots from ready
executor complete -> same-lane reviewer
NEEDS_REVISION -> resume same executor
CLEAN -> integrate -> unlock dependents -> refill
```

Capture IDs on first spawn. Claude revision uses `SendMessage` with stored agent ID/name. Codex uses only
the runtime-supported resume/send-input mechanism. If unavailable, bounded digest + issue list and
`resume unavailable`; no fresh-context claim. Keep executor/reviewer contexts independent. Spawn payload
uses exactly one of `message` or `items`, never both. Discover collaboration tools by exact names only;
never serialize `ALL_TOOLS` schemas.

No status-only executor or publisher worker. Main performs narrow `In Progress`/`Done`/Story transitions;
phase status uses mechanical update or stored publisher. Preserve `CLEAN -> commit -> push -> Done`.

One repository baseline before dispatch; executors focused tests; reviewers affected tests; one full suite
after integrations settle. Command/MCP result <=4,000 characters; report <=300 words. Executor budget
40 completions/40 tool calls; reviewer 24/24; other roles 20/20. On exhaustion return `BUDGET_EXCEEDED`.
Use blocking completion waits, no periodic polling, one nudge after genuine timeout, then stop lane.
Maximum three automatic execute-review cycles per fix; ask before another.

Two simultaneous mutating lanes in one repo require `<repo>/.worktrees/<task-id>/`; one lane may use
prepared story branch after dirty-tree checks; different repos need no worktree solely for uniformity.
Reuse dependency caches. Do not claim path placement guarantees prompt-cache reuse.

## Commit, incident, accounting

After reviewer `STATUS: CLEAN`, main commits/integrates/pushes promptly while other lanes run. Remove lane
worktree only after integration and push. Never commit/push or transition external tickets without workflow
and user authorization. If Critical/High, call `incident-reporter` only after all fix gates; otherwise skip.

Mark workflow start/end. Write `.tiki-taka/scratch/token-ledger.json` with parent/descendant IDs, roles,
models, efforts, input/cache fields, output/reasoning, completions, tool calls, waits, nudges,
compactions, fresh spawns, resumes, and fallbacks. Claude duplicate API records group by `message.id`
using maximum cumulative usage per field. Public-rate credits stay labeled estimates.

Final report: severity/root cause, changed lanes, tests, status/order, formulas, ledger summary, and
runtime limitations. Never claim exact savings without measurement. Do not commit or push.
