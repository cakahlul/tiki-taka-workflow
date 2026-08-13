---
name: prd-review
description: Run Tiki-Taka's standalone PRD clarity and development-readiness review against all PRD content, attachments, related PRDs, and current production code.
---

# Tiki-Taka PRD Review for Codex

1. Resolve `PLUGIN_ROOT` from this file's directory (`skills/prd-review/`) by ascending two directories.
2. Read `PLUGIN_ROOT/context/codex-runtime.md` completely.
3. Read `PLUGIN_ROOT/context/model-policy.md` completely and establish `RUNTIME=codex`.
4. Read `PLUGIN_ROOT/commands/prd-review.md` completely; it is the canonical workflow source.
5. Execute the canonical workflow with the compatibility contract and model policy applied.
6. Resolve each call's model tier, then read `PLUGIN_ROOT/agents/prd-reviewer.md` and
   `PLUGIN_ROOT/agents/project-scout.md` completely before delegating. The canonical parallel review/scout
   stage authorizes bounded Codex delegation.
7. Preserve the mandatory related-PRD question, explicit service/repository gate, full attachment-access
   gate, current-production scouting, score/readiness rubric, confidence per result, and feedback.

Do not modify Claude command or agent files while running this skill.
