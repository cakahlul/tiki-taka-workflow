---
name: bug-workflow
description: Run the complete Tiki-Taka bug investigation and fixing workflow in Codex. Use when the user explicitly asks for the Tiki-Taka bug workflow, not for an ordinary bug fix.
---

# Tiki-Taka Bug Workflow for Codex

1. Resolve `PLUGIN_ROOT` from this file's directory (`skills/bug-workflow/`) by ascending two
   directories to the plugin root.
2. Read `PLUGIN_ROOT/context/codex-runtime.md` completely.
3. Read `PLUGIN_ROOT/context/model-policy.md` completely and establish `RUNTIME=codex`.
4. Read `PLUGIN_ROOT/commands/bug-workflow.md` completely; it is the canonical workflow source.
5. Execute the canonical workflow with the compatibility contract and model policy applied.
6. For every named agent call, resolve model/effort immediately, pass `fork_context: false`, one spawn
   content field (`message` or `items`), role instructions, scoped locations, digest, and budgets.
   Read each role definition completely before delegation.
7. Preserve severity/root-cause analysis, DAG-ready fix lanes, independent review, persistent IDs,
   revision resumes, commit/push ordering, narrow main-thread status transitions, review summary, and
   Critical/High incident reporting. Never spawn a status-only executor.
