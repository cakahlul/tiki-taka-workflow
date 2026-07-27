---
name: reset-workflow
description: Reset Tiki-Taka configuration in the current Codex workspace. Use only when the user explicitly asks to reset, clear, or remove Tiki-Taka setup.
---

# Tiki-Taka Reset Workflow for Codex

1. Resolve `PLUGIN_ROOT` from this file's directory (`skills/reset-workflow/`) by ascending two
   directories to the plugin root.
2. Read `PLUGIN_ROOT/context/codex-runtime.md` completely.
3. Read `PLUGIN_ROOT/commands/reset-workflow.md` completely; it is the canonical workflow source.
4. Execute the reset against `WORKSPACE_ROOT/.tiki-taka/config/` under the compatibility contract.
5. Obtain explicit confirmation before clearing configuration. Never reset the bundled plugin
   context or templates on Codex.

Do not modify the Claude command or agent files while running this skill.
