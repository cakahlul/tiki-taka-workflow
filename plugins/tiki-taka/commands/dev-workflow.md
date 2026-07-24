---
description: Run the Development Workflow (Planning Phase → per-task execute-review-revise pipeline Execution → Commit). PRD analysis, slicing, TRD, task breakdown, then parallel per-task execution — each task flows through review and commit on its own without waiting at a shared barrier.
---

# Development Workflow

## Setup gate (MUST run first)

**Fast path:** read the first line of `${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md`. If it is
`<!-- SETUP: complete -->`, setup is done — skip the field-by-field template diff below and proceed
straight to the "Before starting" read. This marker is written by `/tiki-taka:setup-workflow` only when
every field in both context files is filled, so its presence is authoritative. Only fall through to the
full check below when the marker is absent.

Before anything else, verify setup is **complete** — not just that the files exist. Read
`${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md` and `${CLAUDE_PLUGIN_ROOT}/context/team-context.md`,
and their templates (`tool-providers.template.md`, `team-context.template.md`).

Do NOT stop at "file exists". Compare each file against its template field by field: a field is
**answered** only if its value differs from the template placeholder (any `<...>` token, or the
template literals like `/absolute/path/to/...`). Gate outcome:

- **File absent, OR every field still placeholder** → not set up. STOP the workflow, do not call any
  agent. Tell the user to run `/tiki-taka:setup-workflow`, then run it for them (full flow).
- **Some fields answered, some still placeholder** → partial setup. Run `/tiki-taka:setup-workflow`
  in **instant mode**: ask ONLY the sections whose fields are still placeholders — do not re-ask
  answered ones. After the missing answers are written, continue this workflow.
- **All fields answered** → proceed.

This gate is non-negotiable and applies to every tiki-taka workflow command.

**Before starting**, read `${CLAUDE_PLUGIN_ROOT}/context/team-context.md` for Local Repo Roots,
Squad Members, Repository Mapping, and Feature Scope data — used by project-scout, trd-writer, and
task-breaker as the reference for project/repo/people. Pass the Local Repo Roots to project-scout so
it knows where to search for the repo. If that file still contains the template placeholders
(`<squad>`, `<repo>`, `<name>`, `/absolute/path/...`), stop and tell the user to fill it in first.

Also read `${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md` (written by `/tiki-taka:setup-workflow`)
if it exists, for where each artifact goes + which MCP/tool serves it. When present, pass the
provider to the relevant agents so they DO NOT ask the user where to put things:
- **PRD Slicing** provider → `prd-analyst` (as PRD *source*), `technical-writer` (as the Analysis & Rollout Plan *destination*)
- **TRD** provider → `technical-writer` (TRD *destination*); `task-breaker` links tasks to the published TRD
- **Tasks** provider → `task-breaker`, executors, reviewers
- **Task Grouping** scheme → `task-breaker`
- **Designer** provider → `prd-analyst`, `trd-writer`, `fe-web-executor`, `fe-web-reviewer`, `fe-mobile-executor`, `fe-mobile-reviewer`

**Planning docs flow through scratch, not straight to the destination.** Planning agents (`prd-analyst`,
`project-scout`, `prd-slicer`, `trd-writer`) write local working files under `.tiki-taka/scratch/`
instead of publishing. `technical-writer` is the SINGLE publisher — assembles scratch into finished docs
in one container per feature, and is the only agent that knows the destination tool (keeping the others
tool-agnostic). Pass it the **PRD Slicing** and **TRD** providers so it knows where to publish.

If a provider's MCP/tool is marked "none (not connected)", still pass the destination but tell the
agent to fall back to a local `.md`. If `tool-providers.md` is absent or still holds only template
placeholders (`<...>`), the agents ask the user as usual (generic behavior).

## Minimal solution (MUST for all coding tasks)

For EVERY coding task — writing, adding, refactoring, fixing, reviewing, designing code, or choosing
a library/dependency — call the skill `tiki-taka:minimal-solution-check` first before working.
Do not wait for the user to say so. Skip for non-coding tasks (prose, translation, general knowledge). Goal:
the most minimal solution that still works (YAGNI, stdlib before custom code, native before dependency).

---

When there is a development task, follow this flow in order. Do not skip a stage unless the user explicitly asks to jump ahead.

### Planning Phase

**PRD analysis principle**: `tiki-taka:prd-analyst` MUST NOT accept raw requirements without
being critical. Every requirement MUST be challenged, especially regarding:

- **Flow**: does the order of steps make sense from both the user's and the system's side? Are there missing steps,
  race conditions, or unhandled state (e.g. the user closes the app mid-process,
  the network drops, retry, etc.)?
- **General behavior of human & app**: are the assumptions about user behavior realistic (e.g. the user
  will not read instructions, the user can spam-click, the user uses multi-device/multi-session)? Are the
  assumptions about app/system behavior sensible (idempotency, concurrent requests, data edge cases)?

If there is a requirement that is odd/unreasonable in this area, you MUST ask the user via
`AskUserQuestion` — do not let it through silently, do not soften it into your own assumption.

1. Call the subagent `tiki-taka:prd-analyst` to read & analyze the PRD, AND the subagent `tiki-taka:project-scout`
   to dig into project knowledge — CALL BOTH AT ONCE (in parallel), because project-scout
   does not need the PRD analysis result, only the name of the project/feature the user mentioned. If there is a question
   from either agent, ask the user and DO NOT continue to the next stage before it is answered
   (wait for the answers to both agents before continuing, even if only one asked).
2. After BOTH prd-analyst and project-scout finish, call the subagent `tiki-taka:prd-slicer` to break the PRD into rollout
   phases (Phase 1: MVP, Phase 2, etc.), based on BOTH results from #1 — the prd-analyst analysis AND the
   project-scout project knowledge, so slicing reflects the actual technical condition, not assumptions. If there is a requirement that is ambiguous
   whether it belongs in the MVP or not, ask the user first.
3. Call the subagent `tiki-taka:trd-writer` to create the TRD **specifically for the currently active phase** (starting from
   Phase 1/MVP), based on the results of prd-slicer and project-scout from #1-#2. Project-scout does NOT
   need to be called again at this point — the result from #1 is sufficient unless there has been a significant change in project
   scope since then.
4. **Publish TRDs — `technical-writer` Stage A.** After `trd-writer`, call `tiki-taka:technical-writer`
   in `assemble` mode **Stage A**: it creates the feature's container and publishes each
   `.tiki-taka/scratch/trd-<stack>.md`, returning each TRD's published LOCATION. Do this BEFORE
   task-breaker so tasks can link to the TRD and write their task list back into it.
5. Call `tiki-taka:task-breaker` to break the active-phase TRD (from `.tiki-taka/scratch/`) into tasks.
   Pass it the published TRD locations from step 4. It asks which board/project every run — relay that.
6. **Publish Analysis & Rollout Plan — `technical-writer` Stage B.** After task-breaker, call
   `tiki-taka:technical-writer` in `assemble` mode **Stage B**: assembles `prd-analysis.md`,
   `project-context.md`, `qa-log.md`, `rollout-plan.md` into one "Analysis & Rollout Plan" in the SAME
   container, verifies all publishes, then deletes scratch. On failure it keeps scratch and reports where
   — surface that to the user.

**Q&A LOG (main thread's job, throughout Planning).** You alone see every `AskUserQuestion` answered
across all Planning agents. Maintain `.tiki-taka/scratch/qa-log.md`: each time any is answered (or you
ask one), append a VERBATIM row `# | Asked by | Category | Question | User answer`. Category =
`substantive` (requirements/scope/flow/design/slicing/board) or `operational` (e.g. PRD/tracker
location). Record EVERY question, both categories. technical-writer publishes this as section 3 in Stage B.

### Execution-only entry point (skip Planning)

Enter the workflow straight at the Execution Phase, skipping all of Planning, when the tasks are ALREADY
fully described — either:

- a very small task (1 file, minor fix, no ambiguous requirement) the user asks to jump ahead on
  (confirm explicitly first — do not skip unilaterally); or
- **gap-tasks emitted by `/tiki-taka:em-review`** — each already carries title, description, stack, and
  acceptance criteria (task-breaker format), so there is nothing left to plan.

When entering execution-only:
- Skip steps 1–6 of Planning entirely. There is no scratch, so `technical-writer`'s `assemble` mode is
  skipped too. The Q&A log is skipped.
- Take the given tasks as-is (do NOT re-run task-breaker) and start the Execution Phase at step 1 below.
- **Phase status**: these tasks already belong to an existing phase (em-review audits the active phase).
  Do NOT create a new phase. If a published rollout plan exists, flip that phase's status via
  `technical-writer` per the Execution Phase's phase-status rules; if none exists (planning was never
  persisted), skip phase status.
- Everything else in the Execution Phase (per-task execute → review → revise → commit → push → Done,
  contracts for dependent tasks, story rollup) applies unchanged.

### Execution Phase (PER-TASK PIPELINE: each task flows execute → review → revise on its own, no global barrier)

All tasks produced by `tiki-taka:task-breaker` in the active phase MUST be executed IN PARALLEL, including tasks that
depend on one another. DO NOT execute sequentially just because there is a dependency —
resolve the dependency through a contract, not through a waiting order.

**Pipeline, not barrier.** Each task flows through its own execute → review → revise-until-CLEAN chain
independently. A task's reviewer is called the moment THAT task's executor finishes — it does NOT wait
for the other tasks' executors. Task A can be CLEAN and committed while task B is still on its first
execute pass. This is the tiki-taka principle: the ball never stops on the slowest player. Do NOT hold a
finished task hostage to an unfinished one.

**Handling dependent tasks:**

1. Before execution, identify which tasks depend on each other. This also applies to tasks
   that are the same stack/same service/same project, not just across stacks — e.g. task C needs a
   new function/module/schema from task A, even though A and C are both backend tasks in the same
   project. Do not make "one project/one stack" a reason to execute A first then C.
2. For each dependency pair/chain, DEFINE the contract first up front (before the executor
   runs): the endpoint/function name, request/response shape, data type, error case, field name —
   just the interface, not the implementation. Write this contract briefly in the related task
   (a "Contract" section in the task `.md` or tracker ticket) so all related executors hold the same reference.
3. After the contract is written, CALL ALL EXECUTORS FOR THOSE TASKS IN ONE MESSAGE, IN PARALLEL —
   do not call them one by one in turns even though the tasks depend on each other. Each executor works
   against the agreed contract, not waiting for the actual result of another task.
4. If during implementation the contract turns out to be insufficient/ambiguous, the executor reports it as an issue at the end of
   its work (not silently changing it itself) — the contract is revised, and the affected task is notified of the
   change before it goes to review.
5. Each task's reviewer checks the implementation's conformance to the agreed contract, in addition
   to the original TRD/task. If task A (the dependency) turns out to implement a
   function/module/schema DIFFERENT from the agreed contract, and task C (the dependent) has
   already been worked on in parallel based on the initial contract, the reviewer MUST flag this as
   an issue in task A (`STATUS: NEEDS_REVISION`) — not blame task C, because C is correct
   per the promised contract.

**Same-stack/same-service example**: Task A = "create the function `calculateDiscount(cart)` in the
backend", Task C = "checkout endpoint that calls `calculateDiscount`". Both are backend, one
project. Before execution, define the contract `calculateDiscount(cart: Cart): { discount: number,
reason: string }`. Call be-executor for A and C at once in parallel — executor C directly
uses that signature (a temporary stub/mock is fine if it needs to run local tests), executor A
implements it per that same signature. Review both in parallel too; if reviewer A
finds that A actually returns the field `amount` instead of `discount`, that becomes an issue in A to align to the
contract — C does not need to change.

Kick off ALL tasks at once, then let each run its own execute → review → revise chain. Independent and
contracted tasks alike start together — but from there each task advances at its own pace, it does NOT
wait at a shared round boundary.

1. **Kick off — all executors in one message, in parallel**: CALL ALL ACTIVE-TASK EXECUTORS IN ONE
   MESSAGE (`tiki-taka:be-executor` / `tiki-taka:fe-web-executor` / `tiki-taka:fe-mobile-executor`). Include the task,
   related TRD, and the dependency contract (if any) IN FULL. At the start, if the task exists in an issue
   tracker (has an issue key/id) and a tool for that tracker is available, the executor MUST move the ticket
   status to **In Progress** before starting to code. Do NOT wait for all executors here — proceed to
   review each task the moment ITS executor returns.
2. **Review as each executor finishes** — the instant a task's executor returns, call THAT task's
   stack reviewer (`tiki-taka:be-reviewer` / `tiki-taka:fe-web-reviewer` / `tiki-taka:fe-mobile-reviewer`). Do not
   wait for the other tasks' executors. Multiple tasks that happen to finish together may have their
   reviewers called in one parallel message, but never delay a finished task to batch it with a slower one.
3. **Revise per task, in place**: if a task's reviewer returns `STATUS: NEEDS_REVISION`, immediately
   loop THAT task back through its own executor — sending ONLY the specific list of issues from the reviewer
   (DO NOT re-attach the full TRD/task/code unless the scope changes) — then its reviewer again, until
   `STATUS: CLEAN`. Each task's revise loop is independent; a task's NEEDS_REVISION does not stall any
   other task. A `STATUS: CLEAN` task proceeds straight to commit (step 5) without waiting for its peers.
4. The reviewer on a revision pass only re-verifies the points named as issues plus a quick regression
   scan around the changes — no need to fully re-review the parts that are already CLEAN.
   **Contract deviation across tasks**: if a task's reviewer finds that this task's dependency (task A)
   implemented a function/module/schema DIFFERENT from the agreed contract, flag it as an issue in task A
   (`STATUS: NEEDS_REVISION`) — not in the dependent task, which is correct per the promised contract. If a
   dependency task was ALREADY marked CLEAN when its contract deviation surfaces, reopen it: loop it back
   through its executor with the deviation as the issue, and re-review any already-CLEAN dependents whose
   correctness rested on the original contract.
5. As soon as a task is `STATUS: CLEAN`, commit AND push it (see the Commit & Push section). Do not wait
   for the other tasks to be CLEAN. Only after
   the task is committed and pushed, for each task that originated from an issue tracker (has an issue key/id) call the same-stack
   executor ONCE MORE with explicit confirmation `STATUS: CLEAN` + already committed & pushed —
   the executor moves the ticket to **Done**. Mandatory order: CLEAN → commit → push → Done. (The executor
   sets In Progress itself at the start of the first pass; Done only after CLEAN, commit, and push.) Report each
   status change to the user so they know what is done vs still in progress. Skip if the task is only a local `.md` file.
6. **Story rollup**: after moving tickets to Done, for each parent Story of those tickets, fetch its
   child issues from the tracker. If EVERY child is Done, transition the Story to **Done** too. If any
   child is still open (including tickets outside this workflow run), leave the Story as-is. Skip for
   tickets with no parent Story, local `.md` tasks, or when no tracker tool is available. Report each
   Story transition (or why it was skipped) to the user.
7. **Phase status (via technical-writer).** The rollout plan tracks each phase (NOT STARTED / IN PROGRESS
   / DONE). You DECIDE the transition; technical-writer APPLIES it (only it touches the published doc).
   One phase at a time → at most twice per phase, cheap.
   - **On kicking off the active phase's tasks (step 1)**: if not already `IN PROGRESS`, call
     `tiki-taka:technical-writer` in `set-phase-status` mode with feature, phase, `IN PROGRESS`.
   - **After the phase rollup shows EVERY active-phase task is CLEAN + committed + pushed**: call it with
     feature, phase, `DONE`.
   Report each change. Skip only if there's no published rollout plan (planning skipped).
8. Safety limit: per task, 5 execute→review iterations without reaching CLEAN → STOP that task and
   report it to the user. One stuck task does not block the others — the rest of the pipeline keeps
   running; report the stuck task alongside whatever else has already gone CLEAN and committed.

### Commit & Push

- Commit is done per task, not in bulk for many tasks at once.
- The commit message must reference the related task/ticket (e.g. the JIRA number if any) and its phase (e.g. "Phase 1/MVP").
- A commit is only done after that task has status CLEAN from the relevant reviewer.
- **Push to the story branch** after committing: `git push` the task's commits to its story branch (the branch the executors created in Branch setup, named after the story ticket number). If the branch has no upstream yet, `git push -u origin <story-branch>`.
- **After pushing, present a review summary to the user** so they can review the work: for each task pushed, describe in detail what changed and highlight the key code — the story branch name, files touched, the notable functions/components/endpoints added or changed (with `file:line` references and short code excerpts for the important parts), and anything the user should pay attention to when reviewing. This is a user-facing walkthrough — write it in full, not compressed.

### General principles

- All subagents (executor & reviewer) think on par with a senior software engineer: effective, efficient, and considering scalability.
- The reviewer must not merely approve — it must test the logic, security, and architecture critically.
- Do not assume anything not explicit in the PRD/TRD/task, including which requirement belongs in the MVP. If ambiguous, ask the user.
- **Communication contract.** `Read` `context/comms-style.md` and follow it for how you dispatch subagents and relay results: machine-to-machine (dispatch prompts + agent notes) is caveman; user-facing (questions + the post-push walkthrough) is full prose.
### Model & effort tiering (match the horse to the course — don't burn Opus reasoning on mechanical work)

Spawn each agent at the tier its job needs, not one-size-fits-all. Reasoning tokens (thinking) are
output-priced, so over-powering a mechanical agent is the quietest way to waste tokens. Defaults:

| Agent / pass | Model | Effort | Why |
|---|---|---|---|
| prd-analyst, trd-writer | Opus | high | Architecture + requirement reasoning — the hard thinking |
| project-scout | Sonnet | medium | Search/map the repo — mechanical, not deep design |
| prd-slicer, task-breaker | Sonnet | medium | Structural splitting from inputs already reasoned upstream |
| technical-writer | Sonnet | low/medium | Assemble/publish scratch into docs + flip a phase status field — mechanical, no design reasoning |
| executor — first pass, non-trivial | Opus/Sonnet | high | Real implementation + design decisions |
| executor — trivial task (typo, copy, config, rename) | Haiku | low | Auto-detect from task size; do NOT wait for the user to tag the stack |
| executor — revision pass | (same as first) | medium | Fixing a named list of issues, not re-architecting |
| reviewer — first pass | Sonnet | high | Critical review needs care, but not Opus-tier planning |
| reviewer — revision pass | Sonnet | low/medium | Re-verify only the flagged issues + a quick regression scan — framework already held |

These are defaults, not handcuffs: bump a tier when a "trivial" task turns out to touch security, money,
concurrency, or a load-bearing interface. When unsure whether a task is trivial, treat it as non-trivial.
If the user marks a whole stack as lighter/heavier, honor that over the table.
