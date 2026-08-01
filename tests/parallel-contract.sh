#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

grep -q 'MUST run this event loop' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'never silently degrade' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'Fill loop:' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'Completion handling:' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'before any commentary' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"

for file in \
  "$ROOT/plugins/tiki-taka/context/codex-runtime.md" \
  "$ROOT/plugins/tiki-taka/commands/dev-workflow.md" \
  "$ROOT/plugins/tiki-taka/skills/executor-workflow/SKILL.md" \
  "$ROOT/plugins/tiki-taka/skills/reviewer-workflow/SKILL.md"
do
  grep -q 'LANE_WORKTREE' "$file"
done

grep -q '"version": "1.8.1"' "$ROOT/plugins/tiki-taka/.codex-plugin/plugin.json"
grep -q '"version": "1.8.1"' "$ROOT/plugins/tiki-taka/.claude-plugin/plugin.json"
