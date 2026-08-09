---
name: reviewer-workflow
description: Shared reviewer contract for test gate, focused review, severity, revision reuse, budgets, and reports.
---

# Reviewer Workflow

Operational shell for backend, web, and mobile reviewers. Stack agent supplies domain checks; this skill
keeps reviews bounded and independent.

## Review order

1. If `LANE_WORKTREE` is supplied, verify it and remain there. Never review shared checkout for an
   isolated lane.
2. Read batch digest once when supplied. Treat its commands, conventions, interfaces, baseline, and
   runner availability as authoritative. Do not re-derive them.
3. Run affected-scope test gate first, piped through `tail -30`. Compare against batch/executor baseline;
   inherited failures do not block, new failures do. A red runner gets one retry, then is reported
   unavailable. Do not reinstall or poll.
4. Read task and referenced TRD sections, then inspect tests before implementation and diff before widening
   to callers. Check acceptance criteria, correctness, security, data loss, accessibility, and test quality.
5. First pass may load `code-review-and-quality` only when a deep review is explicitly requested or risk
   requires it. Automatic first-pass review uses this concise checklist; revision passes load no full
   tutorial and reverify only named issues plus quick regression.

## Verdict

- `Critical`: functionality, security, data-loss, or crash risk.
- `Important`: missing acceptance/test proof, wrong contract, error handling, or architectural defect.
- `Suggestion`: optional naming/style/performance note.
- `STATUS: CLEAN` only with no Critical or Important issue.
- `STATUS: NEEDS_REVISION` for any Critical/Important issue; include file, location, impact, and exact fix.

Never invent issues. Preserve reviewer/executor independence. If a dependency violates an agreed
contract, flag dependency lane; dependent lane is correct against the contract.

## Budgets and revision

- Default pass: <=24 model completions and <=24 tool calls.
- Command/MCP result <=4,000 characters; report <=300 words.
- At exhaustion return `BUDGET_EXCEEDED` with completed evidence and remaining checks.
- Resume stored reviewer for re-verification via runtime-supported mechanism. If unavailable, main records
  `resume unavailable` and sends only lane digest plus issue list.
- Return questions as `NEEDS_INPUT` with at most four concise questions; main asks and resumes.
- Automatic execute-review cycles stop at three per task; ask before another.

## Report

```text
## Review Summary
Verdict: APPROVE | REQUEST CHANGES
Critical Issues: None | [file:line] issue + fix
Important Issues: None | [file:line] issue + fix
Suggestions: None | [file:line] note
Verification: [affected test command, baseline delta, test-quality/security notes]
STATUS: CLEAN | NEEDS_REVISION
```

Write recurring generic lessons only when a real reusable pattern exists; keep each entry <=5 lines and
the file bounded. Do not perform tracker/phase status changes.
