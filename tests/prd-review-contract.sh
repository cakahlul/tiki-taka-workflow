#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PLUGIN="$ROOT/plugins/tiki-taka"
COMMAND="$PLUGIN/commands/prd-review.md"
AGENT="$PLUGIN/agents/prd-reviewer.md"
SKILL="$PLUGIN/skills/prd-review/SKILL.md"

test ! -e "$PLUGIN/commands/prd-analyze.md"
test ! -e "$PLUGIN/skills/prd-analyze/SKILL.md"
test -f "$COMMAND"
test -f "$AGENT"
test -f "$SKILL"

grep -q 'prd-reviewer.*project-scout' "$COMMAND"
grep -q 'ALWAYS use `AskUserQuestion`' "$COMMAND"
grep -q 'current production' "$COMMAND"
grep -q 'confidence percentage (0–100%)' "$COMMAND"
grep -q 'score >=90' "$COMMAND"
grep -q 'Never finalize or score a partial PRD' "$AGENT"
grep -q 'names every affected service/repository' "$AGENT"
grep -q 'every image, Figma page, diagram, file, or linked attachment' "$AGENT"
grep -q 'FEEDBACK_SUGGESTIONS' "$AGENT"

grep -q 'prd-analyst' "$PLUGIN/commands/dev-workflow.md"
grep -q 'prd-analyst' "$PLUGIN/agents/prd-analyst.md"

printf '%s\n' 'prd-review contract: PASS'
