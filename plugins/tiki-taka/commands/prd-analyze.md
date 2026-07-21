---
description: Analyze a PRD and scout the project in parallel, then produce an analysis document — clarification Q&A plus the gap between the PRD and current production implementation. Optionally hand off to prd-slicer.
---

# PRD Analyze

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

- **File absent, OR every field still placeholder** → not set up. STOP, do not call any agent. Tell
  the user to run `/tiki-taka:setup-workflow`, then run it for them (full flow).
- **Some fields answered, some still placeholder** → partial setup. Run `/tiki-taka:setup-workflow`
  in **instant mode**: ask ONLY the sections whose fields are still placeholders. After the missing
  answers are written, continue.
- **All fields answered** → proceed.

**Before starting**, read `${CLAUDE_PLUGIN_ROOT}/context/team-context.md` for Local Repo Roots, Squad
Members, Repository Mapping, and Feature Scope — used by project-scout. Pass the Local Repo Roots to
project-scout so it knows where to search for the repo. Read
`${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md` too; when present, pass the provider to the agents
so they DO NOT ask the user where to put things:
- **PRD Slicing** provider → `prd-analyst`, `prd-slicer`
- **Scouting** provider → `project-scout`

If a provider's MCP/tool is "none (not connected)", still pass the destination but tell the agent to
fall back to a local `.md`. If the config is absent or still placeholder, the agents ask the user as
usual (generic behavior).

## Minimal solution (MUST for all coding tasks)

For EVERY coding task, call the skill `tiki-taka:minimal-solution-check` first before working. Skip
for non-coding tasks (this command is mostly analysis). Goal: the most minimal solution that still
works.

---

Goal of this command: produce a **PRD analysis document** containing the questions/insights from
analyzing the PRD — INCLUDING the gap between the PRD and the current production implementation —
plus every clarification asked of the user and its answer. Then offer slicing.

### 1. Analyze + scout, in parallel

Call `tiki-taka:prd-analyst` (read & analyze the PRD) AND `tiki-taka:project-scout` (dig up project
knowledge from the code that is in production now) — **CALL BOTH AT ONCE, in one message, in
parallel**. project-scout does not need the PRD analysis result, only the name of the
project/feature the user mentioned.

Tell project-scout explicitly to report the **current production implementation** of the area this
PRD touches (existing flows, endpoints, screens, data model, what already exists vs. what does not),
so the gap can be computed in step 3.

### 2. Answer clarifications

If EITHER agent asks a question (via `AskUserQuestion`), relay it and wait for the user's answer
before continuing. Wait for BOTH agents to finish — even if only one asked — before step 3.

Beyond the agents' own questions: after both finish, if analyzing the PRD against the production
state surfaces anything odd/ambiguous/contradictory (flow gaps, unhandled state, unrealistic
assumptions about user or app behavior, requirements that conflict with what production already
does), you MUST ask the user via `AskUserQuestion` — do not soften it into an assumption.

**Record every question and its answer verbatim** — they go into the document in step 3.

### 3. Produce the analysis document

Combine the prd-analyst analysis and the project-scout knowledge into one document with:

1. **Goals & requirements/user stories** — from prd-analyst.
2. **Current production implementation** — from project-scout: what exists today in the area the PRD
   touches.
3. **Gap analysis** — PRD requirements vs. current production: for each requirement, is it already
   implemented, partially implemented, or not yet? What must change (new endpoint/screen/schema,
   modified flow, migration)? Call out conflicts where the PRD contradicts current behavior.
4. **Related PRDs** — from prd-analyst (or "none found").
5. **Clarification Q&A** — every question asked of the user in step 2 and its answer, verbatim.

Write it to the PRD Slicing destination from `tool-providers.md` (wiki/doc tool if connected, else a
local `.md`). Report the location to the user.

### 4. Offer slicing

Ask the user via `AskUserQuestion` whether they want to slice this PRD into rollout phases now.

- **Yes** → call `tiki-taka:prd-slicer`, passing BOTH the prd-analyst analysis and the project-scout
  knowledge (the same inputs prd-slicer needs), so slicing reflects the actual technical condition,
  not assumptions. Relay any prd-slicer question to the user.
- **No** → stop. The analysis document is the deliverable; note that slicing can be run later via the
  full `/tiki-taka:dev-workflow`.

### General principles

- AVOID ASSUMPTIONS. Ambiguous → ask via `AskUserQuestion`, never plain-text questions in output.
- Do not create a TRD or make technical decisions here — this command is analysis + scouting + gap
  only.
