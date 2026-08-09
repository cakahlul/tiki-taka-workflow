#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PLUGIN="$ROOT/plugins/tiki-taka"
POLICY="$PLUGIN/context/model-policy.md"
RUNTIME="$PLUGIN/context/codex-runtime.md"
PRELUDE="$PLUGIN/context/codex-agent-prelude.md"
DEV="$PLUGIN/commands/dev-workflow.md"
EXEC="$PLUGIN/skills/executor-workflow/SKILL.md"
REVIEW="$PLUGIN/skills/reviewer-workflow/SKILL.md"

grep -q '`economy`.*gpt-5.6-luna.*low' "$POLICY"
grep -q '`balanced`.*gpt-5.6-luna.*medium' "$POLICY"
grep -q '`strong`.*gpt-5.6-terra.*high' "$POLICY"
grep -q 'Sol is never an automatic default' "$POLICY"
grep -q 'including inherit/fallback' "$POLICY"
grep -q 'Main-session model/effort is not a worker override' "$POLICY"
grep -q 'exactly one accepted content field' "$RUNTIME"
grep -q 'message OR items, never both' "$POLICY"
grep -q 'fork_context: false' "$POLICY"

grep -q 'executorAgentId' "$RUNTIME"
grep -q 'reviewerAgentId' "$RUNTIME"
grep -q 'resume unavailable' "$RUNTIME"
grep -q 'SendMessage' "$DEV"
grep -q 'supported resume/send-input' "$DEV"
grep -q 'No status-only executor' "$DEV"
grep -q 'ready = unfinished tasks whose prerequisites are integrated' "$DEV"
grep -q 'dependents wait for integrated prerequisites' "$RUNTIME"
! grep -q 'including tasks that depend on one another' "$DEV"
! grep -q 'call the same-stack executor ONCE MORE' "$DEV"

grep -q 'batch-digest.md' "$DEV"
grep -q 'execution-handoff.md' "$DEV"
grep -q 'one baseline per changed repository' "$DEV"
grep -q 'one full repository suite' "$DEV"
grep -q 'at most three automatic execute-review cycles' "$DEV"
grep -q 'No periodic polling' "$RUNTIME"
grep -q 'one status nudge' "$RUNTIME"
grep -q 'BUDGET_EXCEEDED' "$RUNTIME"
grep -q 'NEEDS_INPUT' "$PRELUDE"
grep -q 'ALL_TOOLS' "$RUNTIME"
grep -q 'never serialize `ALL_TOOLS` collections' "$RUNTIME"
grep -q "Never guess argument aliases" "$RUNTIME"
grep -q 'Wait targets must be a non-empty array' "$RUNTIME"
grep -q 'never guess, truncate, wildcard, or invent' "$RUNTIME"
grep -q 'Never recursively search the user home' "$RUNTIME"
grep -q 'host-postrun-required' "$RUNTIME"
grep -q 'never fabricate cap compliance' "$DEV"
grep -q 'combined outer tool result stays <=10,000 characters' "$DEV"
grep -q 'concatenated parallel results' "$RUNTIME"
grep -q 'distinct non-empty worktree paths' "$RUNTIME"
grep -q 'disjoint expected files do not' "$DEV"
! rg -n 'scripts/summarize_codex_tree\.sh|\.codex/sessions.*discover' "$PLUGIN/context" "$PLUGIN/commands" >/dev/null
grep -q 'Local code-only workers' "$RUNTIME"

test "$(grep -l 'maxTurns: 40' "$PLUGIN"/agents/*-executor.md | wc -l | tr -d ' ')" -eq 3
test "$(grep -l 'maxTurns: 24' "$PLUGIN"/agents/*-reviewer.md | wc -l | tr -d ' ')" -eq 3
for f in em prd-analyst bug-analyst; do grep -q 'maxTurns: 30' "$PLUGIN/agents/$f.md"; done
for f in project-scout prd-slicer trd-writer task-breaker technical-writer incident-reporter; do
  grep -q 'maxTurns: 20' "$PLUGIN/agents/$f.md"
done
for f in be-executor be-reviewer fe-web-executor fe-web-reviewer fe-mobile-executor fe-mobile-reviewer; do
  grep -q '^disallowedTools: mcp__\*$' "$PLUGIN/agents/$f.md"
done
! rg -n 'AskUserQuestion|ask via|ask the user' "$PLUGIN/agents" >/dev/null

test "$(wc -w < "$DEV")" -le 3000
test "$(wc -w < "$RUNTIME")" -le 1400
test "$(wc -w < "$EXEC")" -le 1200
test "$(wc -w < "$REVIEW")" -le 1000

backend_executor_words=$((
  $(wc -w < "$DEV") +
  $(wc -w < "$RUNTIME") +
  $(wc -w < "$PRELUDE") +
  $(wc -w < "$EXEC") +
  $(wc -w < "$PLUGIN/agents/be-executor.md")
))
backend_reviewer_words=$((
  $(wc -w < "$DEV") +
  $(wc -w < "$RUNTIME") +
  $(wc -w < "$PRELUDE") +
  $(wc -w < "$REVIEW") +
  $(wc -w < "$PLUGIN/agents/be-reviewer.md")
))
printf 'backend executor hot path: %s words\n' "$backend_executor_words"
printf 'backend reviewer hot path: %s words\n' "$backend_reviewer_words"
test "$backend_executor_words" -le 7500
test "$backend_reviewer_words" -le 4500

for stale in \
  'frameworks.md' 'refinement-criteria.md' 'examples.md' 'context-engineering' \
  'deprecation-and-migration' 'git-workflow-and-versioning' 'documentation-and-adrs' \
  'observability-and-instrumentation' 'shipping-and-launch' '/ship'
do
  if rg -n -F "$stale" "$PLUGIN"/skills "$PLUGIN"/agents "$PLUGIN"/commands >/dev/null; then
    echo "stale bundled reference: $stale" >&2
    exit 1
  fi
done

while IFS= read -r file; do
        refs=$(grep -oE '\]\([^)]+' "$file" | sed 's/^](//') || refs=''
  for ref in $refs; do
    case "$ref" in
      ''|'#'*|'http://'*|'https://'*|'mailto:'*) continue ;;
    esac
    target=${ref%%#*}
    test -e "$(dirname "$file")/$target" || {
      echo "missing Markdown reference: $file -> $ref" >&2
      exit 1
    }
  done
done <<EOF
$(find "$PLUGIN" -type f -name '*.md' -print)
EOF

printf '%s\n' 'token-cost contract: PASS'
