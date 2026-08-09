---
name: executor-workflow
description: Shared executor contract for branch safety, batch baseline, focused verification, revisions, budgets, and reports.
---

# Executor Workflow

Operational shell for backend, web, and mobile executors. Stack agent owns implementation quality;
this skill owns safe execution.

## Pass contract

1. If `LANE_WORKTREE` is supplied, verify it is the assigned worktree and stay there. Never checkout
   another branch or edit the shared checkout. Without it, one mutating lane may use the prepared story
   branch after clean-tree checks; parallel same-repository lanes require separate worktrees.
2. First pass only: inspect status, read task, read referenced TRD sections, and check existing review
   lessons. Revision pass: read only reviewer issues and lane digest; do not reread task/TRD or reload
   skills already used.
3. Use `.tiki-taka/scratch/batch-digest.md` when supplied. It is authoritative for stack, commands,
   conventions, interfaces, baseline, and runner availability. Do not rediscover those facts.
4. Do not run a per-task baseline when digest contains the repository baseline. Otherwise run one
   baseline before touching code and report inherited failures by test name.
5. For behavior changes or bug fixes, use TDD: reproduce/regression test first, then minimal fix. For
   multi-file work, use incremental slices. Preserve input validation, security, accessibility, and
   data-loss checks. Do not add abstractions without a third use or correctness need.
6. Run focused tests during implementation, then one affected-scope verification before reporting.
   Pipe test/build/lint output through `tail -30`; run narrowest useful target. Same command/target may
   fail at most three times; unavailable runners get at most two attempts. Stop and report environment
   blockers instead of grinding.
7. Do not perform tracker or phase status changes. Main thread owns narrow transitions. Do not mark work
   Done; reviewer owns `STATUS: CLEAN`, then main performs `CLEAN -> commit -> push -> Done`.

## Budgets and output

- Default pass: <=40 model completions and <=40 tool calls.
- Output: command/MCP result <=4,000 characters; final report <=300 words.
- On budget exhaustion return `BUDGET_EXCEEDED`, completed evidence, and remaining work.
- Never spawn a worker. Return questions as `NEEDS_INPUT` with at most four concise questions; main asks
  and resumes the stored executor.

## Revision

Reviewer sends only issue list plus digest. Fix only named issues. Resume this same executor through the
runtime-supported mechanism; do not present a fresh context as a continuation. If resume is unavailable,
main records `resume unavailable` and sends a bounded lane-state digest. Stop after the third automatic
execute-review cycle; further cycles require user approval.

## Report

Return changed paths, assumptions, baseline/current verification, focused evidence, acceptance coverage,
remaining risks, model/effort, pass number, and exact status. Use machine-readable status lines; executor
does not emit `STATUS: CLEAN`.
