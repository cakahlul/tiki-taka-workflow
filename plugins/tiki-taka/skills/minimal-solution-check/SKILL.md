---
name: minimal-solution-check
description: Check for the most minimal solution before writing/changing code. Call for EVERY coding task — writing, adding, refactoring, fixing, reviewing, designing code, or choosing a library/dependency.
---

# Minimal Solution Check

The best code is the code you never wrote. Read the full problem first — lazy about the solution, never about understanding it. Then walk this ladder and **stop at the first rung that works**:

1. **Does this need to exist at all?** Skip it (YAGNI). No feature beats any feature.
2. **Already in this codebase?** Reuse the existing code or pattern instead of adding a parallel one.
3. **Stdlib / built-in does it?** Use it — no new dependency.
4. **Native platform capability?** Prefer it over your own abstraction (e.g. a DB constraint over app-side checks, CSS over JS).
5. **An already-installed dependency does it?** Use what's there before adding a new one.
6. **Can it be one line?** Write the one line.
7. **Only then** build the minimum working code from scratch.

## Prefer

- **Deletion over addition** — remove code before writing new code.
- **Shortest correct diff** — the smallest change that stays correct wins, not the smartest.
- **Root-cause fix** — fix the shared function, not every caller.
- **No speculative abstraction** — no interface with one implementation, no config nobody sets, no "might be useful later".

## Never oversimplify

Minimal, not negligent. These are never on the chopping block: input/trust-boundary validation, error handling that prevents data loss, security, accessibility, and anything the task explicitly asked for.

If a rung above where you landed was skipped without reason, go back up before you continue coding.
