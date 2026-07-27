---
description: On-demand PRD-compliance audit (Engineering Manager review). Cross-checks the raw PRD against the persisted Analysis, then symbol-traces each active-phase user story's acceptance criteria to reachable code (L1). Auto-emits a gap-task for every partial/missing story, then OFFERS to trigger dev-workflow Execution-only. Separate from dev/bug-workflow — does not block them.
---

# EM Review (PRD-compliance audit)

On-demand. Runs OUTSIDE dev-workflow and bug-workflow — nobody is forced to pay this execution time. Use
it when you want to verify that what the PRD promised actually shipped, before or after a release.

## Setup gate (MUST run first)

**Fast path:** read the first line of `${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md`. If it is
`<!-- SETUP: complete -->`, setup is done — skip the field-by-field diff and proceed. The marker is
written by `/tiki-taka:setup-workflow` only when every field in both context files is filled, so its
presence is authoritative. Fall through to the full check only when the marker is absent.

Otherwise verify setup is **complete**, not just present. Read `${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md`
and `${CLAUDE_PLUGIN_ROOT}/context/team-context.md` and their templates. A field is **answered** only if
its value differs from the template placeholder (any `<...>` token or literals like
`/absolute/path/to/...`). Outcome:

- **File absent, OR every field still placeholder** → not set up. STOP, call no agent. Tell the user to
  run `/tiki-taka:setup-workflow`, then run it for them (full flow).
- **Some answered, some placeholder** → partial. Run `/tiki-taka:setup-workflow` in **instant mode**:
  ask ONLY the placeholder sections. Then continue.
- **All answered** → proceed.

**Before starting**, read `${CLAUDE_PLUGIN_ROOT}/context/team-context.md` for Local Repo Roots (pass them
to em so it knows where to trace code) and `${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md` for:
- **PRD Slicing** provider → raw PRD source AND where the Analysis & Rollout Plan was published.
- **Tasks** provider → where em emits gap-tasks.

Pass these so em does NOT re-ask the user. If a provider is "none (not connected)", pass the
destination but tell it to fall back to local `.md`.

## Minimal solution (MUST for all coding tasks)

For EVERY coding task, call the skill `tiki-taka:minimal-solution-check` first. Skip for the pure-audit
part (this command is mostly analysis); it applies to any gap-task execution triggered at the end.

---

### 1. Run the audit

Call `tiki-taka:em` in **`review` mode**. Tell it: the feature/PRD, the Local Repo Roots, and the scope
— **active phase by default**; pass a different phase or "whole PRD" only if the user asked. Relay any of its
questions (`AskUserQuestion`) to the user and wait.

em cross-checks raw PRD ↔ Analysis (analysis gaps), symbol-traces each user story's AC to
reachable non-stub code (execution gaps), assigns ✅/⚠️/❌ per story, and **auto-emits a gap-task for every
⚠️ and ❌**.

### 2. Present the verdict report (full prose, user-facing)

Show the user a readable report: per user story its ✅ MET / ⚠️ PARTIAL / ❌ MISSING verdict, the AC→symbol
`file:line` evidence, whether each gap is an analysis gap (lost before code) or execution gap (never
built), and the gap-tasks that were emitted (id/key + title + stack). Note if the analysis fallback was
used. This is human-facing — write it in full, not compressed.

### 3. Offer to trigger Execution-only (ACC gate)

The gap-tasks are already created; running an executor writes code, so ask first via `AskUserQuestion`
whether to fix the gaps now.

- **Yes** → run `/tiki-taka:dev-workflow` at its **Execution-only entry point** (skip Planning — the
  gap-tasks are already fully described), feeding it the emitted gap-tasks. Each flows through its stack's
  execute → review → commit → push pipeline as usual.
- **No** → stop. The verdict report + emitted gap-tasks are the deliverable; note they can be executed
  later via dev-workflow whenever the user wants.

### General principles

- SPEC-centric, not code-centric — em-review audits *whether the promise was kept*, the reviewers audit
  *whether the code is correct*. Don't duplicate the reviewers.
- AVOID ASSUMPTIONS. Ambiguous → ask via `AskUserQuestion`, never plain-text questions.
- **Communication contract.** `Read` `context/comms-style.md`: dispatch prompts + agent notes are caveman;
  the verdict report + questions to the user are full prose.
