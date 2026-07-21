---
description: Run the Development Workflow (Planning Phase → parallel execute-review barrier Execution → Commit). PRD analysis, slicing, TRD, task breakdown, then parallel execution per stack.
---

# Development Workflow

## Setup gate (MUST run first)

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
- **PRD Slicing** provider → `prd-analyst`, `prd-slicer`
- **TRD** provider → `trd-writer`, `task-breaker`
- **Tasks** provider → `task-breaker`, executors, reviewers
- **Task Grouping** scheme → `task-breaker`
- **Designer** provider → `fe-web-executor`, `fe-web-reviewer`, `fe-mobile-executor`, `fe-mobile-reviewer`

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
4. Call the subagent `tiki-taka:task-breaker` to break the active-phase TRD into small tasks.

**Skip note**: for a very small task (1 file, minor fix, no ambiguous requirement), the user
may ask to skip the planning phase straight to execution. Confirm explicitly with the user first before
skipping — do not skip unilaterally.

### Execution Phase (PER ROUND: parallel execute barrier → parallel review barrier → repeat until CLEAN)

All tasks produced by `tiki-taka:task-breaker` in the active phase MUST be executed IN PARALLEL, including tasks that
depend on one another. DO NOT execute sequentially just because there is a dependency —
resolve the dependency through a contract, not through a waiting order.

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

Execution runs PER ROUND with two barriers: ALL executors run in parallel and must finish
first, only then do ALL reviewers run in parallel. Repeat the execute-review round until all tasks are
`STATUS: CLEAN`. Independent and contracted tasks alike join the same round — DO NOT let each
task run its own loop separately.

1. **Execute barrier**: CALL ALL ACTIVE-TASK EXECUTORS IN ONE MESSAGE, IN PARALLEL
   (`tiki-taka:be-executor` / `tiki-taka:fe-web-executor` / `tiki-taka:fe-mobile-executor`). Include the task, related TRD,
   and the dependency contract (if any) IN FULL only on the FIRST PASS. At the start of the FIRST
   PASS, if the task exists in an issue tracker (has an issue key/id) and a tool for that tracker is
   available, the executor MUST move the ticket status to
   **In Progress** before starting to code. WAIT FOR ALL executors to finish before continuing — do not
   start review before the execute round is complete.
2. **Review barrier**: after all executors finish, CALL ALL RELEVANT-STACK REVIEWERS IN ONE
   MESSAGE, IN PARALLEL (`tiki-taka:be-reviewer` / `tiki-taka:fe-web-reviewer` / `tiki-taka:fe-mobile-reviewer`). Wait for all reviewers to finish.
3. Collect the review results. A `STATUS: CLEAN` task drops out of the next round. A
   `STATUS: NEEDS_REVISION` task enters the next round — go back to step 1, but call the executor
   ONLY for the task that is still NEEDS_REVISION, sending ONLY the specific list of issues from the reviewer
   (DO NOT re-attach the full TRD/task/code unless the scope changes).
4. The reviewer on the revision round only re-verifies the points named as issues plus a quick regression
   scan around the changes — no need to fully re-review the parts that are already CLEAN.
5. After ALL tasks are `STATUS: CLEAN`, commit AND push each task first (see the Commit & Push section). Only after
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
7. Safety limit: 5 rounds without everything CLEAN, STOP and report to the user.

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
- For small/mechanical tasks (fix a typo, copy text, trivial config, rename), the executor and reviewer
  may be run with a lighter model (haiku) if that stack is marked as such by the
  user — the default remains sonnet for tasks that need architecture/security reasoning.
