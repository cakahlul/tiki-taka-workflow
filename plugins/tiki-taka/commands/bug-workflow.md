---
description: Run the Bug Fixing Workflow (project-scout repo/stack → bug-analyst severity + root cause → parallel fixing executor-review loop → commit → incident report if Critical/High).
---

# Bug Fixing Workflow

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

---

When there is a bug/issue report, follow this flow in order.

1. Call the subagent `tiki-taka:project-scout` to determine the affected repo/project and stack. If the ticket already explicitly names the repo, this agent uses it directly without cross-checking again. If there is a question from this agent, ask the user and DO NOT continue before it is answered.
2. Call the subagent `tiki-taka:bug-analyst` to read the report (from an issue tracker such as JIRA, or manual), categorize the severity (Critical/High/Medium/Low), and do a root cause analysis in the affected repo's code to determine the fix location. If there is a question from this agent, ask the user and DO NOT continue before it is answered.
3. Run the fixing. Steps 1-2 (project-scout, bug-analyst) MUST be sequential as above — but
   once bug-analyst finishes, the fixing phase MUST be PARALLEL, the same as the Execution Phase in the
   Development Workflow:
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
4. Commit changes per bug (per location item if multi-location), the commit message must reference the bug ticket number.
5. If this bug's severity is Critical or High, call the subagent `tiki-taka:incident-reporter` to create an incident report. If the severity is Medium/Low, skip this step.

### Additional principles

- Severity determines urgency, but does not change the review standard — the reviewer stays critical even if the bug is Critical and feels urgent.
