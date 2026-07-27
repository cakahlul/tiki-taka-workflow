---
name: setup-workflow
description: Configure Tiki-Taka for the current Codex workspace. Use only when the user explicitly asks to set up, configure, initialize, or repair Tiki-Taka workflow configuration.
---

# Tiki-Taka Setup Workflow for Codex

1. Resolve `PLUGIN_ROOT` from this file's directory (`skills/setup-workflow/`) by ascending two
   directories to the plugin root.
2. Read `PLUGIN_ROOT/context/codex-runtime.md` completely.
3. Read `PLUGIN_ROOT/commands/setup-workflow.md` completely; it is the canonical workflow source.
4. Execute that workflow with the Codex compatibility contract applied. In particular, write mutable
   configuration to `WORKSPACE_ROOT/.tiki-taka/config/`, never to the installed plugin.
5. Preserve full and instant modes, template completeness validation, and the final setup marker.

Do not modify the Claude command or agent files while running this skill.
