---
name: em-review
description: Run Tiki-Taka's on-demand PRD-compliance engineering review in Codex. Use only when the user explicitly requests a Tiki-Taka EM review or PRD-compliance audit.
---

# Tiki-Taka EM Review for Codex

1. Resolve `PLUGIN_ROOT` from this file's directory (`skills/em-review/`) by ascending two
   directories to the plugin root.
2. Read `PLUGIN_ROOT/context/codex-runtime.md` completely.
3. Read `PLUGIN_ROOT/context/model-policy.md` completely, establish `RUNTIME=codex`, and select the
   `strong` tier for `em` review mode unless the user explicitly overrides it.
4. Read `PLUGIN_ROOT/commands/em-review.md` completely; it is the canonical workflow source.
5. Execute the canonical workflow with the compatibility contract and model policy applied.
6. Read `PLUGIN_ROOT/agents/em.md` completely before executing or delegating it in `review` mode.
7. Preserve raw-PRD authority, symbol tracing, per-story verdicts, automatic gap-task emission when
   authorized and supported, and the optional execution-only handoff.

Do not modify the Claude command or agent files while running this skill.
