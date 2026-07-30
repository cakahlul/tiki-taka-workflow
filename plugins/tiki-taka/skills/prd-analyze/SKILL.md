---
name: prd-analyze
description: Run Tiki-Taka PRD analysis and project scouting in Codex, with optional handoff to rollout slicing. Use when the user explicitly asks for Tiki-Taka PRD analysis.
---

# Tiki-Taka PRD Analyze for Codex

1. Resolve `PLUGIN_ROOT` from this file's directory (`skills/prd-analyze/`) by ascending two
   directories to the plugin root.
2. Read `PLUGIN_ROOT/context/codex-runtime.md` completely.
3. Read `PLUGIN_ROOT/context/model-policy.md` completely and establish `RUNTIME=codex`.
4. Read `PLUGIN_ROOT/commands/prd-analyze.md` completely; it is the canonical workflow source.
5. Execute the canonical workflow with the compatibility contract and model policy applied.
6. Resolve each call's model tier, then read every called agent definition under
   `PLUGIN_ROOT/agents/` completely before executing or
   delegating it. The canonical parallel analyst/scout stage authorizes bounded Codex delegation.
7. Preserve critical PRD challenge, clarification logging, production-gap analysis, publication, and
   the optional continuation choice.

Do not modify the Claude command or agent files while running this skill.
