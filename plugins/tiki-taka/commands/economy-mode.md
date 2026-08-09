---
description: Run the optional sequential Execution Phase with shared digest, persistent reviewers, and the same safety gates.
---

# Economy Mode

Call `tiki-taka:economy-mode` for this batch's Execution Phase, in place of parallel scheduling.

Everything else from `dev-workflow` applies: setup, one baseline per repository, dependency DAG, digest,
conditional worktrees, persistent executor/reviewer IDs, retry ceilings, `CLEAN -> commit -> push -> Done`,
story/phase status, output budgets, waits, and accounting.

Tell user this mode is slower because lanes do not overlap. It is opt-in when wall-clock time matters less
than avoiding concurrent coordination overhead. Shared digest savings also apply to parallel mode; do not
claim a fixed token percentage.

If the user actually wants speed, use `/tiki-taka:dev-workflow` instead.
