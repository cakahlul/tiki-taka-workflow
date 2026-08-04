---
name: reviewer-workflow
description: Shared process for every stack reviewer (be-reviewer, fe-web-reviewer, fe-mobile-reviewer) — skill-loading discipline, test-gate-first ordering, severity taxonomy, output template, and review-lessons write-back. Call this FIRST, before doing any stack-specific review, on every reviewer pass.
---

# Reviewer Workflow

This is the process every reviewer agent follows regardless of stack. It says nothing about what to look for in the code — that's the agent's own persona and stack-specific standards. This skill is only the operational shell around the review.

If the main orchestrator supplies `LANE_WORKTREE`, change to that exact path before reading the diff
or running tests, verify it is the task's isolated git worktree, and remain there for the whole review.
Never review the shared/root checkout for an isolated lane.

## 0. Context budget

`Read` `context/context-budget.md` first and follow it for every command and file read in this review.
The two things that blow a reviewer's budget are **test logs** and **whole-file reads** — both are
handled explicitly below. Target 60k for the whole review pass.

## 0b. Batch digest

If the dispatch includes a **batch digest** (`.tiki-taka/scratch/batch-digest.md`, economy mode), it is
authoritative for stack/commands/conventions/contract signatures and the batch's test baseline — use it
instead of re-deriving them, and use its baseline as the gate comparison when the executor's own
baseline is missing. If a **focused review** was requested for a low-risk task, still run the test gate
and check every acceptance criterion; narrow only the wider architecture/performance sweep, and say in
your report that the review was focused. Sensitive-path work (§1) is never focused-only.

## 1. Skill-loading discipline

Skills are expensive to load and this agent runs on every review pass — be deliberate.

- **First pass on a task**: call `code-review-and-quality` once as your review framework (five axes: correctness, readability, architecture, security, performance + severity labels). Adopt its adversarial discipline — treat every claim in the executor's report, and your own first read, as unproven until a fresh-context check confirms it. "Looks correct" is not correct.
- **Revision passes** (task already reviewed once): do NOT reload `code-review-and-quality` or any framework skill — you already hold the framework. Re-verify only the specific issues you flagged, plus a quick regression scan around the changes.
- **Conditional deep-dive skills** — load ONLY when the trigger actually fires, and only on the pass where you first need them:
  - `security-and-hardening` — if the code touches user input, authn/authz, storage/transmission of sensitive data, or external service integration.

    **Sensitive-path override — not a judgement call.** Load it regardless of how the diff looks if any
    changed path or symbol matches: `auth`, `token`, `session`, `password`, `pin`, `otp`, `kyc`, `kyb`,
    `transfer`, `payment`, `biller`, `balance`, `saldo`, `mutasi`, `limit`, `approval`, `beneficiary`,
    `rekening`, `account`, `loan`, `slik`, `brankas`, `rbac`, `permission`, `role`.
    Check with one cheap command before deciding — `git diff --stat <base>...HEAD` is already in hand:
    `git diff --name-only <base>...HEAD | rg -i 'auth|token|session|password|pin|otp|kyc|kyb|transfer|payment|biller|balance|saldo|mutasi|limit|approval|beneficiary|rekening|account|loan|slik|brankas|rbac|permission|role'`
    A hit means load the skill even if the change "looks trivial" — a one-line edit to a limit check or
    an authz guard is exactly the diff where a skipped security pass costs the most. When a path
    matches, the override applies on revision passes too: re-verify the security-relevant lines rather
    than trusting the first pass, since these are the lines a partial fix most often leaves half-done.
  - `performance-optimization` — only if the task/TRD has a stated performance requirement OR you have concrete evidence of a regression. A hunch is not evidence.
  - `code-simplification` — only if the code works but is genuinely hard to read/maintain (deep nesting, long functions, unclear names, duplication, over-abstraction) AND you intend to raise it as a `NEEDS_REVISION` issue. Do not load it to bless already-clean code. This also covers code that's technically correct but over-built for what the task asked — speculative abstraction, unused flexibility, a config option nobody sets: that's a legitimate finding, not something to let slide because "more flexible is safer."
- Do not load `doubt-driven-development` — the adversarial discipline above is the whole of what you need for a single-diff review; that skill's orchestration reference is for multi-agent design.

## 2. Test suite gate — run FIRST, before reading any code

The executor works TDD, so a test suite always exists. Run it (the project's test command; infer from the build/dependency file or project-context.md if unsure). Compare the result against the executor's reported **baseline** (the pre-existing failures it recorded before touching code).

**Never let a full suite log into context — it is the single biggest waste in this workflow.** Run it
so only the summary survives: `<test cmd> 2>&1 | tail -30`. That gives you pass/fail counts and the
failing test names, which is all the gate needs. Only when a test is newly red do you re-run THAT test
alone for its detail, and quote the shortest decisive lines (assertion + location) in your report — never
paste a whole log or stack trace dump.

- A test that is red but was ALREADY red in the baseline is inherited, not the executor's fault — do NOT fail the executor for it (note it as a pre-existing issue).
- STOP with `STATUS: NEEDS_REVISION` only if a test is red that was green in the baseline (a NEW failure) — write those failing test names + output as the issue and do not proceed to code review.
- If the executor gave no baseline (e.g. skipped it) and the suite is red, treat every failure as new.

**Retry ceiling — the gate is a measurement, not a project to fix.** Run the suite at most **twice**;
a runner that never produces a green run gets **one** retry, then counts as unavailable. Never
reinstall dependencies, clear caches, or try flag combinations to coax it into working — that is the
executor's environment blocker to report, not yours to grind. If the gate cannot run, say so
explicitly, review the diff on its merits, and mark the test evidence as unavailable in your report
rather than either blocking on it or implying tests passed.

Only when there are no new failures do you continue to the code review.

## 3. Review order

Read the related task first — understand what is supposed to be done. Read the TRD only for the
sections the task points at, not end to end: the task is the contract you review against, the TRD is
reference material behind it.

**Start from the DIFF, widen where it's blind.** `git diff --stat <base>...HEAD` for the shape, then
`git diff <base>...HEAD -- <path>` per file. A diff shows what changed, not what the change BROKE — so
widen in these cases rather than reviewing the hunk alone:

- **A signature, exported symbol, schema, or shared constant changed** → check the call sites:
  `rg -n <symbol>` across the repo. A caller the executor forgot to update never appears in the diff.
  This is the single most common real bug a diff-only review misses.
- **The diff is a large share of the file, or the file is new** → read the file; you are reviewing the
  whole thing anyway.
- **The hunk's correctness depends on state you cannot see** (what the rest of the class does, whether
  a guard already exists above, how the function is invoked) → read the surrounding range, or the file
  if it's small.
- **Deleted code** → confirm nothing still references it (`rg -n`).

Otherwise the hunk plus a few lines of context is enough. Read ranges (`offset`/`limit`) over whole
files when the file is large. The point is not to read less than the review needs — it is to not read
every touched file end to end out of habit.

**Never read the same file twice in one review.** Measured on real runs, repeat reads of a handful of
files — barrel/`index` files and long integration-test files above all — are the single largest context
cost in a review pass. When you need one more detail from a file you already opened, use
`rg -n '<symbol>' <file>` or a ranged `Read` around that spot; do not reopen it. Check size with
`wc -l` before opening anything unfamiliar, and range-read anything over ~300 lines. This does not
license reviewing less: widen per the rules above whenever correctness needs it — just reach for `rg`
and ranges instead of another full-file read.

Then review tests before implementation code: tests reveal intent and coverage. Check whether the tests actually verify the intended behavior, not just that they pass — a suite that's green but tests the wrong behavior, or omits required cases, is still an `Important` issue.

Compare the executor's work against the task and TRD explicitly.

## 4. Severity taxonomy

- **Critical** — must fix before merge: breaks functionality, security hole, data loss/exposure risk, crash risk.
- **Important** — must fix: missing tests, wrong abstraction, poor error handling, pattern inconsistency with the rest of the codebase.
- **Suggestion** — optional: naming, style, minor optimization.

Critical and Important issues MUST include a specific, actionable fix recommendation (file, location, what's wrong, why, how to fix).

## 5. Status decision

- `STATUS: CLEAN` (verdict APPROVE) — only if there are NO Critical or Important issues.
- `STATUS: NEEDS_REVISION` (verdict REQUEST CHANGES) — if there is at least one Critical or Important issue.

Never approve while a Critical issue is still open. Do not invent issues to look thorough, and do not wave something through just because it's been revised several times — the standard is the same at every iteration. If unsure about something, say so and suggest investigation rather than guessing.

## 6. Output template

```markdown
## Review Summary

**Verdict:** APPROVE | REQUEST CHANGES
**Overview:** [1-2 sentence summary of the change + overall assessment]

### Critical Issues
- [file:line] [description + fix recommendation]

### Important Issues
- [file:line] [description + fix recommendation]

### Suggestions
- [file:line] [description]

### Verification Story
- Test suite run first (gate): [command used, baseline pre-existing failures vs new failures — only NEW failures block]
- Tests reviewed: [yes/no, do they assert the right behavior + cover required cases]
- Security checked: [yes/no, observations]

STATUS: CLEAN | NEEDS_REVISION
```

An empty section (e.g. no Critical) may be written as "None" — do not delete it.

## 7. Review-lessons write-back

If you find a mistake pattern that could recur in other tasks (not a one-off typo/mistake specific to this task) — e.g. a security, performance, or architectural-consistency pattern — RECORD it concisely to `.claude/knowledge/review-lessons.md` at the repo root (create the file if it doesn't exist). Write: the mistake category, a short description, and the correct way. Do this both when the status is `NEEDS_REVISION` and when it's `CLEAN`.

## 8. Comms style

Before writing any report/note back to the main thread or another subagent, `Read` `context/comms-style.md` and follow it: machine-to-machine handoffs use caveman (compress delivery, keep code/names/IDs/status/errors verbatim); user-facing text stays full prose.
