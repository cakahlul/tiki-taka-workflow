# Runtime-Aware Model Routing

Use this policy only for delegated agents. The main conversation keeps the model selected by the
user/session. Never ask an agent to guess its runtime.

## Runtime identity

- A workflow entered through `commands/*.md` runs with `RUNTIME=claude`.
- A workflow entered through a Codex workflow `SKILL.md` runs with `RUNTIME=codex`.
- Pass `RUNTIME`, `MODEL_TIER`, and the resolved model/effort in every delegated-agent prompt.
- An explicit user model or effort override wins over this file.

## Tier mapping

| Tier | Claude Code | Codex | Intended use |
|---|---|---|---|
| `economy` | `model: haiku`, `effort: low` | `model: gpt-5.6-terra`, `reasoning_effort: low` | Mechanical, bounded, read-heavy, or prose work |
| `balanced` | `model: sonnet`, `effort: medium` | `model: gpt-5.6-terra`, `reasoning_effort: medium` | Normal planning, coding, debugging, and review |
| `strong` | `model: opus`, `effort: high` | `model: gpt-5.6-sol`, `reasoning_effort: high` | High-risk reasoning, audits, or repeated failure |
| `inherit` | `model: inherit` | omit model override | User-selected session behavior |

Use Claude's per-invocation `model` parameter instead of adding static `model` fields to agent
frontmatter. On Codex, pass `model` and `reasoning_effort` when spawning the delegated agent.
When a Codex call overrides the model, use `fork_turns: none` and pass a complete bounded task prompt;
do not copy the entire parent conversation into the worker.

If the requested model, alias, or effort is unavailable, retry once with `inherit`; do not stop the
workflow merely because routing is unsupported. Report the fallback in the final workflow summary.

## Default role tiers

| Agent or mode | Default tier | Escalate to `strong` when |
|---|---|---|
| `project-scout` | `economy` | Multiple plausible repos, architecture ambiguity, or cross-repo impact |
| `technical-writer` | `economy` | Never by default; use `balanced` only for conflicting source artifacts |
| `incident-reporter` | `economy` | The report requires unresolved technical reconstruction |
| `prd-analyst` | `balanced` | Contradictory requirements with material product or data risk |
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
