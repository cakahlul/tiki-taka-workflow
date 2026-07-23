---
name: reviewer-workflow
description: Shared process for every stack reviewer (be-reviewer, fe-web-reviewer, fe-mobile-reviewer) — skill-loading discipline, test-gate-first ordering, severity taxonomy, output template, and review-lessons write-back. Call this FIRST, before doing any stack-specific review, on every reviewer pass.
---

# Reviewer Workflow

This is the process every reviewer agent follows regardless of stack. It says nothing about what to look for in the code — that's the agent's own persona and stack-specific standards. This skill is only the operational shell around the review.

## 1. Skill-loading discipline

Skills are expensive to load and this agent runs on every review pass — be deliberate.

- **First pass on a task**: call `code-review-and-quality` once as your review framework (five axes: correctness, readability, architecture, security, performance + severity labels). Adopt its adversarial discipline — treat every claim in the executor's report, and your own first read, as unproven until a fresh-context check confirms it. "Looks correct" is not correct.
- **Revision passes** (task already reviewed once): do NOT reload `code-review-and-quality` or any framework skill — you already hold the framework. Re-verify only the specific issues you flagged, plus a quick regression scan around the changes.
- **Conditional deep-dive skills** — load ONLY when the trigger actually fires, and only on the pass where you first need them:
  - `security-and-hardening` — only if the code touches user input, authn/authz, storage/transmission of sensitive data, or external service integration.
  - `performance-optimization` — only if the task/TRD has a stated performance requirement OR you have concrete evidence of a regression. A hunch is not evidence.
  - `code-simplification` — only if the code works but is genuinely hard to read/maintain (deep nesting, long functions, unclear names, duplication, over-abstraction) AND you intend to raise it as a `NEEDS_REVISION` issue. Do not load it to bless already-clean code. This also covers code that's technically correct but over-built for what the task asked — speculative abstraction, unused flexibility, a config option nobody sets: that's a legitimate finding, not something to let slide because "more flexible is safer."
- Do not load `doubt-driven-development` — the adversarial discipline above is the whole of what you need for a single-diff review; that skill's orchestration reference is for multi-agent design.

## 2. Test suite gate — run FIRST, before reading any code

The executor works TDD, so a test suite always exists. Run it (the project's test command; infer from the build/dependency file or project-context.md if unsure). Compare the result against the executor's reported **baseline** (the pre-existing failures it recorded before touching code).

- A test that is red but was ALREADY red in the baseline is inherited, not the executor's fault — do NOT fail the executor for it (note it as a pre-existing issue).
- STOP with `STATUS: NEEDS_REVISION` only if a test is red that was green in the baseline (a NEW failure) — write those failing test names + output as the issue and do not proceed to code review.
- If the executor gave no baseline (e.g. skipped it) and the suite is red, treat every failure as new.

Only when there are no new failures do you continue to the code review.

## 3. Review order

Read the related task/TRD first — understand what is supposed to be done. Then review tests before implementation code: tests reveal intent and coverage. Check whether the tests actually verify the intended behavior, not just that they pass — a suite that's green but tests the wrong behavior, or omits required cases, is still an `Important` issue.

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
