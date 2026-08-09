#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

grep -q 'MUST run this event loop' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'never silently degrade' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'Fill loop:' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'Completion handling:' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'before any commentary' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'first action after observing any completion' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'Never wait for a user prompt to refill capacity' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'Scheduler invariant' "$ROOT/plugins/tiki-taka/skills/dev-workflow/SKILL.md"
grep -q 'Never read the mutable plugin copies as Codex config' "$ROOT/plugins/tiki-taka/context/codex-runtime.md"
grep -q 'Bare `context/<name>`' "$ROOT/plugins/tiki-taka/context/codex-agent-prelude.md"
grep -q 'cwd-relative' "$ROOT/plugins/tiki-taka/context/codex-agent-prelude.md"
grep -q 'never create scratch files inside' "$ROOT/plugins/tiki-taka/context/codex-agent-prelude.md"
grep -q 'fork_context: false' "$ROOT/plugins/tiki-taka/context/model-policy.md"
grep -q "current runtime's connector/MCP settings" "$ROOT/plugins/tiki-taka/commands/setup-workflow.md"
grep -q 'does not enumerate' "$ROOT/plugins/tiki-taka/commands/setup-workflow.md"

for file in \
  "$ROOT/plugins/tiki-taka/context/codex-runtime.md" \
  "$ROOT/plugins/tiki-taka/commands/dev-workflow.md" \
  "$ROOT/plugins/tiki-taka/skills/executor-workflow/SKILL.md" \
  "$ROOT/plugins/tiki-taka/skills/reviewer-workflow/SKILL.md"
do
  grep -q 'LANE_WORKTREE' "$file"
done

CODEX_VERSION=$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' "$ROOT/plugins/tiki-taka/.codex-plugin/plugin.json" | head -1)
CLAUDE_VERSION=$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' "$ROOT/plugins/tiki-taka/.claude-plugin/plugin.json" | head -1)
test -n "$CODEX_VERSION"
test "$CODEX_VERSION" = "$CLAUDE_VERSION"
