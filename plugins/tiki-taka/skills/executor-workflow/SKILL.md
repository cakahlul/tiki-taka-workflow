---
name: executor-workflow
description: Shared process for every stack executor (be-executor, fe-web-executor, fe-mobile-executor) — branch setup, baseline test snapshot, revision-pass discipline, tracker status updates, and report format. Call this FIRST, before doing any stack-specific work, on every executor pass.
---

# Executor Workflow

This is the process every executor agent follows regardless of stack. It says nothing about how to write good code — that's the agent's own persona and stack-specific standards. This skill is only the operational shell around that work.

## 1. Review lessons check

Before starting, check whether `.claude/knowledge/review-lessons.md` exists at the repo root. If it does, read it — it's a list of mistake patterns reviewers have previously found in this project. Make sure your current work does not repeat them.

## 2. Branch setup — first pass only, not revisions

Branch = the **Story ticket number** (one branch per story, shared by its tasks). Story key: parent Story key if this task has one (epic→story→subtask), else the task's own key (flat grouping / local `.md`).

- Checkout the repo default (`main`/`master`, via `git remote show origin`), pull.
- If the story branch already exists (local or origin), checkout + pull it; else create it off default.
- Do this BEFORE any code.

On a revision pass (after the reviewer returns `NEEDS_REVISION`) you are already on the story branch — stay, do not re-branch or touch default.

## 3. Baseline test snapshot — first pass only, right after branch setup, before touching code

Run the test suite once and record which tests are ALREADY failing on a clean checkout (inherited/pre-existing failures, not yours). Decide the scope yourself: full suite if fast, or a scoped run (modules/packages your task touches, or typecheck+lint/build) if the full suite is heavy — state which you chose.

Report this baseline (the pre-existing failing test names, or "baseline green") in your final report, so the reviewer only holds you accountable for tests that go red RELATIVE to this baseline, not ones already broken before you started.

Skip on a revision pass.

## 4. Read the task and TRD in full

Do not assume requirements that aren't stated. If something is ambiguous, note the assumption you made in your final report.

## 5. Revision-pass discipline

If this is a revision based on reviewer feedback, fix ONLY the points mentioned. Do not rewrite parts that were already declared clean unless directly affected.

On a revision pass, do NOT reload conditional skills you already applied on the first pass unless a reviewer issue specifically requires that skill's guidance — reloading a full skill to re-fix a couple of flagged lines is wasted context.

## 5b. Universal coding-skill triggers

These three apply to every stack, on top of whatever stack-specific triggers the agent's own persona lists:

- **Multi-file / lots of code at once / task too big for one go** → call `incremental-implementation` first (thin vertical slice: implement one piece, test, verify, commit, next). Skip for a truly minimal single-file change.
- **Implements logic / fixes a bug / changes behavior** → call `test-driven-development` first (RED-GREEN-REFACTOR: failing test first, then code; bug fix = Prove-It, reproduce with a failing test before fixing). Skip only for pure config/docs/static-asset changes with no behavioral impact.
- **Unexpected error during work** (failing test, broken build, runtime error/crash, behavior mismatch) → STOP adding features, call `debugging-and-error-recovery` first (reproduce, localize, reduce, fix root cause not symptom, guard with a regression test, verify). Don't guess a fix without reproducing.

## 6. Tracker status update

Applies ONLY if the task comes from the issue tracker configured in `context/tool-providers.md` → `## Tasks` (e.g. JIRA, Linear, GitHub Issues — it has an issue key/id) AND a tool for that tracker is available in this session. If the task is just a local `.md` file, or no tracker tool is available, skip this section.

- **At the start of each work pass**: before starting to code, move the task to **In Progress**. Skip if it is already In Progress or further along.
- **Moving to Done**: DO NOT set Done on your own judgment — clean status is the reviewer's decision. Move to **Done** ONLY if you are called with explicit confirmation that the reviewer has returned `STATUS: CLEAN` for this task.
- If the status update fails (different permission/workflow), report it as a note in your final report — do not do it silently.

## 7. Final report

State what you did, files touched, assumptions made, the baseline vs current test result, and anything the reviewer needs to pay attention to. Do not mark your own work as clean or done — that is the reviewer's decision, not yours.

## 8. Comms style

Before writing any report/note back to the main thread or another subagent, `Read` `context/comms-style.md` and follow it: machine-to-machine handoffs use caveman (compress delivery, keep code/names/IDs/status/errors verbatim); user-facing text stays full prose.
