---
name: economy-mode
description: Optional sequential execution with shared digest, persistent lane roles, and normal review/safety gates.
---

# Economy Mode

Use only when user values lower coordination overhead over wall-clock throughput. Sequential scheduling
is slower and is not itself a token discount. Parallel remains default; shared digest, baseline, prompt,
wait, and resume savings apply to both modes.

1. Main writes `.tiki-taka/scratch/batch-digest.md` <=500 words and
   `.tiki-taka/scratch/execution-handoff.md` <=800 words. Include repository/stack, commands, one
   convention `file:line`, shared interfaces, one baseline per repository, runners, risks, and DAG.
2. Process dependency-ready tasks in order. A dependent task starts only after prerequisite integration;
   update digest with real interfaces. No speculative stubs unless user explicitly approves.
3. Each task still gets an independent executor and reviewer. Store separate
   `executorAgentId`/`reviewerAgentId`, model, effort, pass count, status, digest, and resume state in
   `lanes.json`. Resume same executor for issues and same reviewer for re-verification; if unavailable,
   record `resume unavailable` and send bounded digest + issue list.
4. One repository baseline occurs before dispatch; executors run focused tests; reviewers run affected
   tests; one full repository suite gates settled integrations. Sensitive paths, migrations, and
   Critical/High tasks receive full review. Low-risk mechanical tasks may use focused review, never skip
   test gate or acceptance checks.
5. Use conditional worktrees from `dev-workflow`: two mutating same-repo lanes need separate worktrees;
   one lane may use prepared story branch; different repositories need no uniform worktree. Reuse caches.
6. Budgets: executor 40/40 completions/tool calls, reviewer 24/24, other roles 20/20. Report
   `BUDGET_EXCEEDED` with evidence if reached. Reports <=300 words; tool output <=4,000 characters.
   Maximum three automatic execute-review cycles. Blocking waits only; no polling; one timeout nudge,
   then stop.
7. Main performs narrow tracker/phase status transitions. Preserve `CLEAN -> commit -> push -> Done`.
   Mark start/end and write `.tiki-taka/scratch/token-ledger.json`. Report measured totals and labeled
   public-rate estimates; do not promise a percentage saving.
