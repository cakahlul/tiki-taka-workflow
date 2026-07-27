---
name: dev-workflow
description: Run the complete Tiki-Taka PRD-to-ship development workflow in Codex, including planning or execution-only mode. Use when the user explicitly asks for Tiki-Taka development workflow, not for ordinary coding requests.
---

# Tiki-Taka Development Workflow for Codex

1. Resolve `PLUGIN_ROOT` from this file's directory (`skills/dev-workflow/`) by ascending two
   directories to the plugin root.
2. Read `PLUGIN_ROOT/context/codex-runtime.md` completely.
3. Read `PLUGIN_ROOT/commands/dev-workflow.md` completely; it is the canonical workflow source and
   must not be summarized before execution.
4. Execute the canonical workflow with the compatibility contract applied.
5. For every named agent call, read the corresponding `PLUGIN_ROOT/agents/<name>.md` completely and
   pass its role instructions and relevant context to the delegated agent. The canonical workflow's
   explicit parallel stages authorize bounded Codex subagent delegation.
6. Preserve Planning, Execution-only, per-task executor-review-revision lanes, CLEAN gates, Q&A log,
   publication stages, commits, pushes, tracker updates, and final review summary exactly unless the
   user explicitly narrows the workflow.

Do not modify the Claude command or agent files while running this skill.
