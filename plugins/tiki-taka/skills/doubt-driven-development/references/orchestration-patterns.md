# Orchestration Patterns

Main thread owns orchestration. Worker roles do not spawn workers. Use smallest pattern that preserves
correctness.

## Direct invocation

One role, one artifact, one report. Default for one perspective. Examples: a stack reviewer with
`code-review-and-quality`, a security pass with `security-and-hardening`, or a test pass with
`test-driven-development`.

## Parallel ready lanes

Run multiple lanes only when currently independent and repository mutation is isolated. Main keeps one
merge/integration point and one reviewer per code lane. Use a DAG:

```text
ready = unfinished tasks whose prerequisites are integrated
fill capacity from ready
executor -> independent reviewer
clean -> integrate -> unlock dependents
```

Do not force unresolved dependencies into parallel execution. Contract-first speculation requires explicit
user approval. Tiki-Taka's `dev-workflow` and `bug-workflow` are canonical implementations.

## Sequential user-driven pipeline

Use when each stage depends on prior output or human approval. Planning gate, execution handoff, then
execution. Do not add a router worker that paraphrases every stage.

## Research isolation

Use read-only `project-scout` or the host's built-in read-only explorer for large discovery, returning a
bounded digest. Main writes scratch artifacts. Do not mutate branches, config, or source during scouting.

## Runtime rules

- Claude plugin agents support the repository's declared `name`, `description`, `tools`,
  `disallowedTools`, and `maxTurns` fields. Max turns are per-role: executor 40, reviewer 24, other roles
  20 (analyst/EM 30).
- Codex workers receive `codex-agent-prelude.md`, `fork_context: false`, resolved model/effort, scoped
  capabilities, one of `message` or `items`, digest, and output budgets.
- Store separate executor/reviewer IDs. Resume same role for revision when runtime supports it; otherwise
  send bounded digest + issue list and record `resume unavailable`.
- Wait for blocking completion events. No periodic polling; one timeout nudge, then stop.
- Tool discovery returns exact matching names only. Never serialize `ALL_TOOLS` schemas or descriptions.
- Public-rate credits are estimates. Do not claim parallel is 2x or economy is half without measured data.

## Anti-patterns

- Router worker deciding which worker to call.
- Worker calling another worker.
- Global execute/review barriers when lanes are independent.
- Dependent lane built against speculative stubs by default.
- Full test suite, scout, status executor, or publisher repeated per task.
- Long tutorials injected into every worker when a concise role contract suffices.
