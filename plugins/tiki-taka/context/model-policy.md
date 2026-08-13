# Runtime-Aware Model Routing

Use this policy only for delegated agents. The main conversation keeps the model selected by the
user/session. Never ask an agent to guess its runtime.

## Runtime identity

- A workflow entered through `commands/*.md` runs with `RUNTIME=claude`.
- A workflow entered through a Codex workflow `SKILL.md` runs with `RUNTIME=codex`.
- Pass `RUNTIME`, `MODEL_TIER`, resolved model/effort, `fork_context: false`, and pass budgets in
  every delegated-agent prompt.
- Main-session model/effort is not a worker override. Only explicit user text naming delegated workers
  overrides this policy.
- Sol is never an automatic default. It is an explicit worker override only.

## Tier mapping

| Tier | Claude Code | Codex | Intended use |
|---|---|---|---|
| `economy` | `model: haiku`, `effort: low` | `model: gpt-5.6-luna`, `reasoning_effort: low` | Mechanical, bounded, read-heavy, or prose work |
| `balanced` | `model: sonnet`, `effort: medium` | `model: gpt-5.6-luna`, `reasoning_effort: medium` | Normal planning, coding, debugging, and review |
| `strong` | `model: opus`, `effort: high` | `model: gpt-5.6-terra`, `reasoning_effort: high` | High-risk reasoning, audits, or repeated failure |
| `inherit` | `model: inherit` | use the runtime-supported inherited model/effort | Explicit worker inheritance only |

Use Claude's per-invocation `model` parameter instead of adding static `model` fields to agent
frontmatter. On Codex, pass the resolved model/effort for a selected tier; for explicit `inherit`, use
only the runtime-supported inherited values. Always pass `fork_context: false`, including inherit/fallback
paths. Use one accepted spawn payload form:
`message` OR `items`, never both. Spawn contracts use message OR items, never both. Pass a complete
bounded task prompt; never copy the parent chat.

If the requested model, alias, or effort is unavailable, retry once with `inherit`; do not stop the
workflow merely because routing is unsupported. Keep `fork_context: false` and record the fallback in
the final run ledger. If runtime accepts no resume/send-input operation, use a bounded lane-state
digest and record `resume unavailable`; do not imply context was retained.

## Default role tiers

| Agent or mode | Default tier | Escalate to `strong` when |
|---|---|---|
| `project-scout` | `economy` | Multiple plausible repos, architecture ambiguity, or cross-repo impact |
| `technical-writer` | `economy` | Never by default; use `balanced` only for conflicting source artifacts |
| `incident-reporter` | `economy` | The report requires unresolved technical reconstruction |
| `prd-analyst` | `balanced` | Contradictory requirements with material product or data risk |
| `prd-reviewer` | `balanced` | Contradictory requirements with material product, data, or cross-service risk |
| `prd-slicer` | `balanced` | Cross-system dependency ordering remains ambiguous |
| `trd-writer` | `balanced` | Security, migration, distributed consistency, or irreversible design |
| `task-breaker` | `balanced` | Cross-repo execution or unclear critical dependency graph |
| `em` in `estimate` mode | `balanced` | Major scope uncertainty remains after clarification |
| `em` in `review` mode | `strong` | Always |
| `bug-analyst` | `balanced` | Critical/High severity, security/concurrency/data-loss risk, or no root cause after the first pass |
| Any executor | `balanced` | Critical/High work, security/data migration, or the second revision pass onward |
| Any reviewer | `balanced` | Critical/High work, security/data migration, or the second review pass onward |

## Budget and escalation rules

1. Resolve the tier immediately before each agent call; do not permanently promote a role because a
   previous task was difficult.
2. Run at most two `strong` agents concurrently unless the user explicitly asks for more.
3. Do not use `strong` merely because a task is large. Escalate for reasoning risk, not token volume.
4. A `NEEDS_REVISION` verdict keeps the next executor/reviewer pass `balanced` once. Promote from the
   second revision cycle onward.
5. Never downgrade `em` review mode or work involving confirmed security, destructive migration,
   data loss, or Critical severity below `strong` unless the user explicitly overrides it.
6. Record only routing exceptions and fallbacks in the final summary; omit routine tier chatter.

## Worker budgets

- Executors: maximum 40 model completions and 40 tool calls per pass.
- Reviewers: maximum 24 model completions and 24 tool calls per pass.
- All other roles: maximum 20 model completions and 20 tool calls per pass.
- A role that reaches its budget returns `BUDGET_EXCEEDED` with completed evidence and remaining work.
- Default command/MCP output is <=4,000 characters; worker reports are <=300 words.
- Automatic execute-review cycles stop at three per task. Ask before another cycle.
- One blocking/event-driven wait per worker or completion wave; no periodic polling. At most one status
  nudge after a genuine timeout, then stop the lane if it remains unresponsive.
