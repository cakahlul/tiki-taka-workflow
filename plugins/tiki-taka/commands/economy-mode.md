---
description: Run the Execution Phase in economy mode — sequential lanes, shared context read once as a batch digest, review scaled to risk. Lowest total token cost; strictly slower than the parallel default.
---

# Economy Mode

Call the skill `tiki-taka:economy-mode` and follow it for this batch's Execution Phase, in place of the
parallel dispatch rules in `/tiki-taka:dev-workflow`.

Everything else from `dev-workflow` still applies unchanged: the setup gate, worktree discipline
(`<repo>/.worktrees/<task-id>/`), dependency contracts, retry ceilings, CLEAN → commit → push → Done
ordering, story rollup, phase status, and the safety limits.

Tell the user up front that this mode is slower than the parallel default, and roughly why: sequential
lanes cannot overlap, so the batch takes about the sum of its task durations rather than the longest one.
It is chosen when total token cost matters more than finishing time.

If the user actually wants speed, use `/tiki-taka:dev-workflow` instead.
