---
description: Set up the workflow for your team — ask where PRD-slices / TRD / tasks go, which MCP/tools serve them, the project location + team assignment, and the design-tool provider. Writes the answers so the workflow agents stop asking and use your setup. Reset = clear the two files this writes.
---

# Setup Workflow

Configure this plugin for a specific team. You ask the user the questions below, verify MCP/tool
availability, and write the answers to two files. After setup, `/tiki-taka:dev-workflow` and
`/tiki-taka:bug-workflow` read these files and pass the providers to the relevant agents, so the
agents no longer ask the user where things go.

**Bootstrap from templates first:** these two files are gitignored, so a fresh clone ships only the
`.template.md` versions. Before writing, for each target: if it does NOT exist, copy the matching
template — `context/team-context.template.md` → `context/team-context.md`,
`context/tool-providers.template.md` → `context/tool-providers.md`.

**Files this writes:**
- `${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md` — provider + MCP info for PRD-slices, TRD, tasks, designer (bootstrapped from `tool-providers.template.md` if absent, then filled by this command).
- `${CLAUDE_PLUGIN_ROOT}/context/team-context.md` — project location + team assignment (bootstrapped from `team-context.template.md` if absent; fill Local Repo Roots + Squad Members).

**To reset the plugin back to generic**: clear `tool-providers.md` and reset `team-context.md` to
its template placeholders. No agent file is ever edited by this command, so the agents stay generic.

## Already set up? (re-run gate)

Before anything else, read `${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md`,
`${CLAUDE_PLUGIN_ROOT}/context/team-context.md`, and their templates. Compare each file to its
template **field by field**: a field is answered only if its value differs from the template
placeholder (any `<...>` token, or template literals like `/absolute/path/to/...`). Classify:

- **All fields still placeholder (or file absent)** → first-time setup; skip this gate, go to section 1.
- **Some answered, some still placeholder** → **instant mode**: skip the sections that are already
  answered; ask ONLY the sections whose fields are still placeholders, then rewrite only those parts.
  This is what a workflow command triggers when setup is partial. Do NOT re-ask answered sections.
- **All fields answered** → setup already ran fully; ask via `AskUserQuestion`: **Reset setup** or
  **Update setup**?
  - **Reset setup** → run the full flow from the start, all sections in order (as if first-time).
  - **Update setup** → do NOT re-ask everything. Show the updatable sections (via `AskUserQuestion`,
    `multiSelect: true`) so the user picks which to change:
    PRD Slicing / TRD / TRD template / Tasks / Team context / Designer / Scouting / Task grouping / Task-creation skill.
    Ask ONLY the picked sections' questions, then rewrite only those parts of `tool-providers.md`
    (and `team-context.md` if Team context picked). Leave unpicked sections untouched.

To map an unanswered file section back to a question: each `## Heading` in `tool-providers.md`
corresponds to the like-named section below; Local Repo Roots / Squad Members in `team-context.md`
correspond to the Team context section.

## How to ask

The sections below are concrete slot-filling questions (destinations, MCP names, paths) — ask them
with the `AskUserQuestion` tool. Do NOT write questions as plain output text. Batch related
questions in one call where it makes sense. Ask the sections in order.

**Before section 1**, ONLY if the user's setup intent is underspecified or they explicitly say
"interview me" / "grill me" (e.g. they don't know which tools their team uses, or what goes where):
call the skill `interview-me` (via the Skill tool) to draw out the real setup first, one question at
a time. If the user already knows their destinations/tools, skip it — go straight to section 1.

## MCP / tool check rule (applies to every "check MCP" step below)

When a section needs an MCP/tool checked:
1. Check whether the named MCP server (or a suitable alternative) is connected in this session — look
   at the available tools for a matching MCP prefix (e.g. `mcp__atlassian__*` for Confluence/JIRA,
   `mcp__figma__*` for Figma).
2. If connected → record it as available (note the tool prefix).
3. If NOT connected → emit a **warning** to the user: name what is missing and tell them to connect it
   through the current runtime's connector/MCP settings. On Claude Code, this may be claude.ai connector
   settings, `claude mcp`, or `/mcp`; on Codex, use Codex plugin/MCP settings or the current Codex
   surface's connector controls.
4. **A warning NEVER blocks.** Record the choice + "not connected (warned)" and move on. The user can
   still finish setup and run the workflow; the agents will fall back (e.g. write a local `.md`).

## Sections to ask

### 1. PRD slicing output → feeds `prd-analyst`, `prd-slicer`

Ask: "Where should the PRD-slicing result be stored?" Options: **Confluence** / **Other**.
- **Confluence** → check MCP `atlassian` (or similar). Warn if missing (rule above).
- **Other** → ask the user to name the tool/destination themselves (free text via "Other"), then ask
  a follow-up: "Is there already an MCP/tool for it?" If yes → ask them to name the MCP/tool and
  check whether it is actually connected (warn if not). If no → warn.

Record: destination + MCP tool prefix (or "none / not connected").

### 2. TRD output → feeds `trd-writer`, `task-breaker`

Same question and same MCP-check flow as section 1 (Confluence / Other).

Record: destination + MCP tool prefix (or "none / not connected").

### 2b. TRD template → feeds `trd-writer`

Ask: "Do you already have a TRD template?" Options: **Yes, I have one** / **No, let the system generate one**.
- **Yes** → ask the user to provide/attach the TRD template file(s) — per stack (Backend / FE Web / Mobile)
  if they keep separate ones, or a single template. Record its content to embed into the `## TRD Template`
  section with Status: provided.
- **No** → tell the user `trd-writer` will generate a sensible TRD structure itself. Record Status:
  system-generated.

Record: TRD template status (provided | system-generated) + content (or "system-generated").

### 3. Task output → feeds `task-breaker`, executors, reviewers

Ask: "Where should the broken-down tasks be stored?" Options: **JIRA** / **Other**.
- **JIRA** → check MCP `atlassian` (or similar). Warn if missing.
- **Other** → same free-text + follow-up MCP-check flow as section 1.

Record: destination + MCP tool prefix (or "none / not connected").

### 4. Team context → writes to `team-context.md`

Ask: "Where do your local project repos live (absolute path)?" — accept one or more paths.
Then ask: "Do you want to provide team assignment info?" (yes/no).
- If **yes** → ask for team members: each member's name and role (Mobile / Backend / Web / QA / etc.).
  Ask enough to fill the Squad Members table.
- If **no** → skip; leave Squad Members as-is / minimal.

Write the repo paths into the **Local Repo Roots** section and members into the **Squad Members**
section of `team-context.md`. Do not invent Feature Scope / Repository Mapping — only fill what the
user gave; leave the rest for them to edit if they want.

### 5. Designer tool provider → feeds `prd-analyst`, `trd-writer`, `fe-web-executor`, `fe-web-reviewer`, `fe-mobile-executor`, `fe-mobile-reviewer`

Ask: "Which design tool do you use?" Options: **Figma** / **Other**.
- **Figma** → check MCP `figma` (or similar). Warn if missing.
- **Other** → same free-text + follow-up MCP-check flow as section 1.

Record: design tool + MCP tool prefix (or "none / not connected").

### 6. Scouting tools → feeds `project-scout`

Ask: "Is there a tool or MCP for scouting projects (docs/wiki source, code-search MCP, etc.)?"
Options: **Yes** / **No**.
- **Yes** → ask the user to name the tool/MCP, then check whether it is actually connected (same
  MCP-check flow as section 1 — warn if not).
- **No** → skip; project-scout falls back to searching the repo roots directly.

Record: scouting tool/MCP + prefix (or "none").

### 7. Task grouping / hierarchy → feeds `task-breaker`

Ask: "Do you need task grouping/hierarchy? (commonly used on platforms like JIRA)" Options: **Yes** / **No**.
- **No** → tasks are created flat, no parent. Record: "flat (no parent)".
- **Yes** → ask a follow-up: "How should tasks be grouped?" with these options:
  - **Task → subtask** — each broken-down task becomes a subtask under one parent Task.
  - **Epic → task** — tasks are grouped as children directly under an Epic.
  - **Epic → story → subtask** — one Story per PRD user story under an Epic, with subtasks under each Story.
  - **Story → subtask** — tasks become subtasks under a parent Story (no Epic).

Record: grouping scheme (or "flat (no parent)").

### 8. Task-creation skill → feeds `task-breaker`

Ask: "Is there a skill for creating tasks on your chosen platform (JIRA/Trello/etc.)?" Options: **Yes** / **No**.
- **Yes** → ask the user to name the skill. Record the skill name.
- **No** → skip; task-breaker creates tasks directly via the MCP/tool from section 3.

Record: task-creation skill name (or "none").

## Write `tool-providers.md`

**Completion marker.** The first line of `tool-providers.md` is `<!-- SETUP: complete -->` — but write
it ONLY when setup is fully done: every field in BOTH `tool-providers.md` and `team-context.md` is
answered (no `<...>` placeholders left in either file). The workflow commands' setup gate reads this
marker as a fast path to skip the field-by-field template diff. So:
- **Full first-time setup finishing with all sections answered** → write the marker.
- **Instant mode / partial** → if any field in either file is still a placeholder after this run, do NOT
  write the marker (or remove it if present). Add it only once the last placeholder is filled.
- **Reset** → the marker is cleared along with the file (see `/tiki-taka:reset-workflow`).

After all sections answered, write `${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md` in this shape
(fill real values; keep the headings — the workflow commands key off them):

```markdown
<!-- SETUP: complete -->
# Tool Providers

> Written by `/tiki-taka:setup-workflow`. To reset the plugin to generic, clear this file back to
> the template placeholders below.

## PRD Slicing
- Destination: <Confluence | Other: name>
- MCP/Tool: <mcp__atlassian__* | name | none (not connected)>
- Fed to: prd-analyst, prd-slicer

## TRD
- Destination: <Confluence | Other: name>
- MCP/Tool: <mcp__atlassian__* | name | none (not connected)>
- Fed to: trd-writer, task-breaker

## TRD Template
- Status: <provided (user supplied a template) | system-generated (no template; system creates one)>
- Fed to: trd-writer
- Templates (per stack): <paste/attach the user's TRD template per stack here, or leave blank if system-generated>

## Tasks
- Destination: <JIRA | Other: name>
- MCP/Tool: <mcp__atlassian__* | name | none (not connected)>
- Fed to: task-breaker, executors, reviewers

## Designer
- Tool: <Figma | Other: name>
- MCP/Tool: <mcp__figma__* | name | none (not connected)>
- Fed to: prd-analyst, trd-writer, fe-web-executor, fe-web-reviewer, fe-mobile-executor, fe-mobile-reviewer

## Scouting
- Tool/MCP: <name + mcp prefix | none>
- Fed to: project-scout

## Task Grouping
- Scheme: <flat (no parent) | Task → subtask | Epic → task | Epic → story → subtask | Story → subtask>
- Fed to: task-breaker

## Task Creation Skill
- Skill: <name | none>
- Fed to: task-breaker
```

## Finish

Report a short summary to the user: each section's destination + whether its MCP is connected, and
list any warnings raised. Remind them: warnings don't block — the workflow still runs, agents fall
back to a local `.md` where a tool is missing.

**Connector capability reminder.** `context/tool-providers.md` records the selected provider; actual
availability comes from the current runtime/session. The shipped agent frontmatter does not enumerate
provider-specific MCP prefixes, so do not claim that Atlassian or Figma is always available or tell the
user to edit shared agent files just to configure a provider. Check the current runtime's tools during
setup, warn when the configured provider is absent, and preserve the local `.md` fallback. Codex maps
provider capability names through `context/codex-runtime.md`; Claude Code uses its own MCP/tool policy.
