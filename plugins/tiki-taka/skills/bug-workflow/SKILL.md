---
name: bug-workflow
description: Run the complete Tiki-Taka bug investigation and fixing workflow in Codex. Use when the user explicitly asks for the Tiki-Taka bug workflow, not for an ordinary bug fix.
---

# Tiki-Taka Bug Workflow for Codex

1. Resolve `PLUGIN_ROOT` from this file's directory (`skills/bug-workflow/`) by ascending two
   directories to the plugin root.
2. Read `PLUGIN_ROOT/context/codex-runtime.md` completely.
3. Read `PLUGIN_ROOT/commands/bug-workflow.md` completely; it is the canonical workflow source.
4. Execute the canonical workflow with the compatibility contract applied.
5. For every named agent call, read the corresponding `PLUGIN_ROOT/agents/<name>.md` completely and
   pass its role instructions and relevant context to the delegated agent. Canonical parallel fix
   lanes authorize bounded Codex subagent delegation.
6. Preserve severity classification, root-cause analysis, executor-review-revision gates, commit and
   push ordering, tracker updates, review summary, and Critical/High incident-report behavior.

Do not modify the Claude command or agent files while running this skill.
