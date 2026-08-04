---
name: economy-mode
description: Run the Execution Phase for lowest TOTAL token cost instead of lowest wall-clock time — one lane at a time, shared project context read once and passed forward as a digest, review scaled to risk. Use when the user asks for the cheap/economy/sequential mode, or says total token cost matters more than speed.
---

# Economy Mode

The default Execution Phase optimizes **wall-clock time**: lanes run in parallel so the batch finishes
as fast as its slowest task. That costs tokens, and the cost is structural — each subagent has its own
context, so anything two lanes both need (contracts, conventions, the pattern in a neighbouring
component) is read and paid for once *per lane*.

Economy mode inverts the trade: **lowest total tokens, at the cost of wall-clock time.** Same tasks,
same acceptance criteria, same commit discipline — they just finish one after another, and shared
knowledge gets read once for the whole batch.

Do NOT use this mode when the user wants speed, or when a deadline depends on parallel throughput.
It is strictly slower. State that plainly when you switch into it.

## 1. One lane at a time

Run the batch strictly sequentially: task 1 executes → reviews → revises to CLEAN → commits → pushes,
and only then does task 2 start. Never fill a second worker slot.

- Keep the worktree discipline from `dev-workflow` (one lane per task, in `<repo>/.worktrees/<task-id>/`).
  Isolation is cheap here — only one exists at a time, and reusing installed dependencies (symlink /
  `--offline`) means lane setup costs almost nothing.
- Because lanes never overlap, dependency contracts stop being guesses: run dependency-ordered tasks in
  dependency order, and a later task reads the ACTUAL interface the earlier one shipped instead of
  working against a promised contract. Fewer contract-deviation revisions is itself a saving.
- Order the batch so foundational tasks (schemas, contracts, shared components) come first. Everything
  after them inherits real code instead of a promise.

## 2. The batch digest — read shared context ONCE

This is where the savings actually come from. Before dispatching the first executor, the orchestrator
writes `.tiki-taka/scratch/batch-digest.md` — the things every task in this batch would otherwise each
discover for itself:

- **Stack + commands**: test / build / lint / typecheck command, package manager, monorepo layout.
- **Conventions**: error shape, naming, layering, state management, how tests are structured — with ONE
  representative `file:line` example each, not a copy of the code.
- **Shared contracts**: the exported types/endpoints/schemas this batch's tasks depend on, by signature
  (`calculateDiscount(cart: Cart): { discount: number, reason: string }`), plus where they live.
- **Baseline test state**: pre-existing failures, recorded once for the batch.
- **Environment reality**: which runners actually work in this repo. If the E2E/visual runner does not
  run here, say so ONCE — do not let five executors each rediscover it (measured: one task burned 200k+
  context doing exactly that).

Rules that make the digest a saving rather than another document:

- **Keep it under ~500 words.** It is a lookup table, not a TRD. Signatures and paths, not prose.
- Pass it to every executor and reviewer in the batch, alongside their task. Tell them it is
  authoritative for stack/conventions/commands, so they do NOT re-derive it.
- Source it from what you already have — `project-context.md` from planning, plus the first task's
  findings. Do NOT spawn a scout agent just to build it.
- **Update it as the batch proceeds.** When task 1 ships an interface task 3 needs, append the real
  signature. When a convention turns out to be wrong, correct it. Later tasks then start from fact.
- If a digest claim turns out to be wrong mid-batch, fix the digest and say so — a stale digest
  propagates one mistake into every remaining task, which costs far more than it saved.

## 3. Scale review to risk, do not skip it

Sequential execution does not license weaker review. It does allow spending review effort where it
matters:

- **Full review** (the normal `reviewer-workflow` pass) for anything touching a sensitive path per
  `executor-workflow`'s whitelist (auth, token, session, pin, otp, kyc, transfer, payment, balance,
  limit, approval, permission, role, …), any schema/migration, or any Critical/High task. Never
  downgrade these — cheap mode is not a reason to ship an unreviewed authz change.
- **Focused review** for mechanical, low-risk work (config, copy, a pure-presentational component with
  no state, a rename): the reviewer runs the test gate, reads the diff, and checks the task's acceptance
  criteria — skipping the wider architecture/performance sweep. Say in the report that the review was
  focused and why.
- The test gate always runs. A task is never CLEAN on an unrun suite.

## 4. Reuse what the previous task already established

Each task after the first starts with knowledge the batch already paid for. Put it in the dispatch:

- The digest (§2), which by now includes real shipped interfaces.
- A one-line note of anything the previous task learned the hard way ("the vitest config needs
  `environment: jsdom` per-file", "`packages/ui` must be built before `apps/desktop` tests resolve").

Do NOT re-attach the TRD, the task list, or the previous task's diff. Locations and signatures only.

## 5. Report the trade honestly

At the end of the batch, tell the user: tasks completed, and that they ran sequentially for token cost
rather than in parallel. If a task was blocked or stopped at a ceiling, report it as usual — economy
mode never hides an incomplete result to look cheap.

Expect roughly **half** the total tokens of the same batch run in parallel, taking roughly the sum of
the task durations instead of the longest one. If measured numbers come out materially different from
that, say so rather than restating the estimate.
