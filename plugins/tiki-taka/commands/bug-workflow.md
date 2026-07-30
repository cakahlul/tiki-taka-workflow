---
description: Run the Bug Fixing Workflow (project-scout repo/stack → bug-analyst severity + root cause → parallel fixing executor-review loop → commit → incident report if Critical/High).
---

# Bug Fixing Workflow

## Runtime and model routing

This command establishes `RUNTIME=claude`. Before calling any subagent, read
`${CLAUDE_PLUGIN_ROOT}/context/model-policy.md` and resolve that call's tier from the role/mode and
current risk. Pass the mapped Claude model and effort per invocation. Honor user overrides, strong
concurrency limits, escalation rules, and `inherit` fallback. Do not add static model choices to the
agent definitions.

## Setup gate (MUST run first)

**Fast path:** read the first line of `${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md`. If it is
`<!-- SETUP: complete -->`, setup is done — skip the field-by-field template diff below and proceed.
The marker is written by `/tiki-taka:setup-workflow` only when every field in both context files is
filled, so its presence is authoritative. Fall through to the full check only when the marker is absent.

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
Squad Members, Repository Mapping, and Feature Scope data — used by project-scout as the reference for
the affected repo/stack. Pass the Local Repo Roots to project-scout so it knows where to search. If
that file still contains the template placeholders (`<squad>`, `<repo>`, `<name>`,
`/absolute/path/...`), stop and tell the user to fill it in first.

Also read `${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md` (written by `/tiki-taka:setup-workflow`)
if it exists. When present, pass the **Tasks** provider to the executors/reviewers and the
**Designer** provider to the FE executors/reviewers so they DO NOT ask the user where things go. If a
provider's MCP/tool is "none (not connected)", still pass the destination but tell the agent to fall
back to a local `.md`. If the file is absent or still holds only template placeholders (`<...>`),
agents ask as usual (generic behavior).

## Minimal solution (MUST for all coding tasks)

For EVERY coding task — writing, adding, refactoring, fixing, reviewing, designing code, or choosing
a library/dependency — call the skill `tiki-taka:minimal-solution-check` first before working.
Do not wait for the user to say so. Skip for non-coding tasks. Goal: the most minimal solution that still
works (YAGNI, stdlib before custom code, native before dependency).

## Context budget

Read `${CLAUDE_PLUGIN_ROOT}/context/context-budget.md` once at the start; every agent you dispatch reads
it too. From the orchestration side: pass the bug report in full plus repo/file LOCATIONS rather than
pasted code, send revision dispatches with ONLY the reviewer's issue list, and relay agent reports
compressed down to what the next step needs. If an agent reports it ran out of room with work uncovered,
surface that to the user rather than re-dispatching the same oversized job.

---

When there is a bug/issue report, follow this flow in order.

1. Call the subagent `tiki-taka:project-scout` to determine the affected repo/project and stack. If the ticket already explicitly names the repo, this agent uses it directly without cross-checking again. If there is a question from this agent, ask the user and DO NOT continue before it is answered.
2. Call the subagent `tiki-taka:bug-analyst` to read the report (from an issue tracker such as JIRA, or manual), categorize the severity (Critical/High/Medium/Low), and do a root cause analysis in the affected repo's code to determine the fix location. If there is a question from this agent, ask the user and DO NOT continue before it is answered.
3. Run the fixing. Steps 1-2 (project-scout, bug-analyst) MUST be sequential as above — but
   once bug-analyst finishes, the fixing phase runs as a per-item pipeline, the same as the Execution
   Phase in the Development Workflow — each item flows execute → review → revise on its own without
   waiting at a shared barrier:
   - **Single-location case** (bug-analyst output is plain text, not JSON): directly call one
     executor for the relevant stack, nothing to parallelize.
   - **>1-location case** (bug-analyst outputs a JSON block `localId`/`dependsOnLocalIds`/`contract`):
     CALL ALL STACK EXECUTORS FOR EACH ITEM IN ONE MESSAGE, IN PARALLEL — including items that
     depend on one another (`dependsOnLocalIds` is non-empty). Each executor works against the `contract`
     that bug-analyst has already written, DO NOT wait for the actual result of its dependency item to finish
     first. The same-stack/same-service rule from the Development Workflow also applies: two items that
     are both backend but depend on one another are still called in parallel, not sequentially.
   - Each item (independent or contracted) runs the executor-reviewer loop in parallel with one
     another — follow the same loop as the Development Workflow (revise until `STATUS: CLEAN`,
     limit of 5 iterations per item).
   - If the executor finds the `contract` from bug-analyst insufficient/ambiguous during implementation, report it
     as an issue (not silently changing it) — the reviewer flags the dependency item that deviates from the
     contract as `NEEDS_REVISION`, not the dependent item that already matches the initial contract.
4. Commit changes per bug (per location item if multi-location), the commit message must reference the bug ticket number. Then **push to the story branch** (the branch the executor created in Branch setup, named after the story/bug ticket number; `git push -u origin <story-branch>` if no upstream yet). **After pushing, present a review summary to the user**: for each fix pushed, describe in detail what changed and highlight the key code — branch name, files touched, the notable functions/lines changed (with `file:line` references and short excerpts for the important parts), and what to pay attention to when reviewing. Write this user-facing walkthrough in full, not compressed.
5. **Status update (skip for local `.md` bugs or when no tracker tool is available).** The executor sets the ticket to **In Progress** itself at the start of its first pass. After the fix is CLEAN and committed/pushed, call the same-stack executor ONCE MORE with explicit confirmation `STATUS: CLEAN` + already committed — it moves the ticket to **Done**. Mandatory order: CLEAN → commit → push → Done. Then, if the ticket has a parent Story, fetch the Story's child issues: if EVERY child is Done, transition the Story to **Done** too; if any child is still open, leave it. Report each status change (or why skipped) to the user so they know what is done vs still in progress.
6. If this bug's severity is Critical or High, call the subagent `tiki-taka:incident-reporter` to create an incident report. If the severity is Medium/Low, skip this step.

### Additional principles

- Severity determines urgency, but does not change the review standard — the reviewer stays critical even if the bug is Critical and feels urgent.
- **Communication contract.** `Read` `context/comms-style.md` and follow it for how you dispatch subagents and relay results: machine-to-machine (dispatch prompts + agent notes) is caveman; user-facing (questions + the post-push walkthrough) is full prose.
- **Model routing source of truth.** Use only `context/model-policy.md`; do not maintain a second tier
  table inside this command.
