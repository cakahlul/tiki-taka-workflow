# Codex Runtime Compatibility Contract

This file adapts the canonical Claude Code command and agent documents to Codex. The canonical
workflow remains under `commands/`; do not copy or paraphrase its stages into the adapter skill.

## Instruction precedence

1. Follow the active Codex system, developer, user, workspace, and skill instructions.
2. Follow this compatibility contract for runtime-specific behavior.
3. Follow the canonical command and agent documents for Tiki-Taka workflow semantics.

When a canonical document conflicts with a higher-priority safety or permission instruction, keep
the workflow intent but use the safe Codex behavior.

## Paths and persistent configuration

- `PLUGIN_ROOT` means the plugin directory containing `.codex-plugin/`, `commands/`, `agents/`,
  `skills/`, and `context/`.
- Interpret every `${CLAUDE_PLUGIN_ROOT}` reference as `PLUGIN_ROOT` when reading bundled templates,
  agents, skills, or other immutable resources.
- On Codex, mutable setup belongs to the user's current workspace, not the installed plugin:
  - `WORKSPACE_ROOT/.tiki-taka/config/team-context.md`
  - `WORKSPACE_ROOT/.tiki-taka/config/tool-providers.md`
- For canonical reads of `context/team-context.md` or `context/tool-providers.md`, prefer the
  workspace config above. Fall back to the legacy plugin copy only when the workspace file does not
  exist, so existing Claude installations remain usable.
- Setup writes workspace config by copying the bundled templates and filling the copies. Reset
  restores or removes only the workspace config after explicit user confirmation. Never overwrite
  the bundled templates.
- Scratch artifacts remain workspace-relative under `WORKSPACE_ROOT/.tiki-taka/scratch/`.
- Add `.tiki-taka/` to the target project's `.gitignore` only with user approval; otherwise leave the
  decision to the user and warn if scratch/config contains private data.

## Commands and user interaction

- A reference to `/tiki-taka:<name>` means run the installed skill named `<name>` on Codex.
- `AskUserQuestion` means use the user-input mechanism available in the current Codex surface. If no
  structured input tool is available, ask one concise plain-text question and wait.
- Preserve the canonical command's setup gates, sequencing, Q&A log, review barriers, stop
  conditions, and user-visible summaries.

## Agents and parallel work

- This adapter establishes `RUNTIME=codex`. Before the first delegated agent, read
  `PLUGIN_ROOT/context/model-policy.md` completely and apply its tier mapping, role defaults,
  escalation rules, concurrency cap, user overrides, and fallback behavior.

- A request to call `tiki-taka:<agent>` means:
  1. Read `PLUGIN_ROOT/agents/<agent>.md` completely.
  2. Translate its Claude tool names using the mapping below.
  3. Delegate it to a Codex subagent when collaboration is available. For a canonical parallel stage,
     delegation is mandatory rather than discretionary.
  4. Otherwise execute the role locally with the same isolation and output contract.
- The workflow skill explicitly authorizes bounded subagent delegation required by its canonical
  workflow. Do not delegate unrelated work.
- When spawning a role, pass `RUNTIME=codex`, the **already-resolved** model and reasoning effort,
  role instructions, exact inputs, expected output, repository path, and whether it may mutate files.
  Never assume a spawned agent has read the plugin resources.
- **The worker's runtime contract is `PLUGIN_ROOT/context/codex-agent-prelude.md` — that file and
  nothing more.** It carries paths, tool mapping, context budget, comms, and mutation safety in the
  form a worker actually needs. Do NOT also pass this file (`codex-runtime.md`), `context-budget.md`,
  `comms-style.md`, or `model-policy.md` to a spawned role: since `fork_turns: none` prompts are
  self-contained, every one of those is re-paid on every spawn, and their main-thread content
  (scheduler, tier tables, worktree setup) is content a worker never acts on.
- **Do not pass `model-policy.md` to a worker.** Tier resolution is the main thread's decision. Send
  the *outcome* (`model=<x>, reasoning_effort=<y>`), not the table used to derive it.
- Pass **locations, not payloads**: give the spawned role a document's path/URL plus the sections it
  needs, not the whole document pasted into the prompt. Since `fork_turns: none` prompts are
  self-contained, anything pasted is paid for by every role you paste it into. Revision spawns carry
  only the reviewer's issue list.
- Model-overridden Codex agents use `fork_turns: none` with a self-contained task prompt, avoiding a
  full conversation fork and its token cost.
- Parallelize only stages the canonical command marks independent. Preserve all dependency and
  reviewer barriers.

### Codex parallel scheduler

For every canonical parallel stage, the main agent MUST run this event loop until no lane is active or
runnable. Keeping a completed agent visible in the UI is not an excuse to leave its replacement idle.

1. Keep lane state in a FILE, not in the main context: `WORKSPACE_ROOT/.tiki-taka/scratch/lanes.json`,
   one record per task — `{task, stack, lane, agentId, passes}` where `lane` is one of `EXECUTING`,
   `REVIEWING`, `REVISING`, `CLEAN`, `STOPPED`. Read and update it with `jq` (write to a temp file and
   move it over, so a partial write cannot corrupt the ledger).

   Re-derive the queue from that file at each event instead of restating the whole board in context —
   in a long parallel run, narrating every lane transition costs more than the orchestration itself,
   and it can never be evicted. Keep in your head only what the next action needs: which slots are
   free, and which task the completion you just observed belongs to.
2. **Fill loop:** while a collaboration slot is free and `runnable` is non-empty, call `spawn_agent`
   immediately, record its ID in `active`, and repeat. Do not wait for one spawned agent before
   spawning the next. On the common four-slot Codex runtime, the main agent occupies one slot,
   leaving three workers; discover and use the actual available capacity rather than assuming it is
   unlimited.
3. **Wait loop:** if `active` is non-empty, call `wait_agent` for the next completion event. Do not
   return to the user, run unrelated tools, or start a long main-thread task while a runnable job and
   a free worker slot exist.
4. **Completion handling:** immediately remove the completed ID from `active`, update its lane, and
   enqueue its next job: executor success → reviewer; reviewer `NEEDS_REVISION` → same executor;
   reviewer `CLEAN` → integration/Done. This completion handling and fill loop are the main agent's
   **first action after observing any completion**; do not answer a status message first. Then run the
   fill loop again before any commentary,
   status report, commit/push, or other work. A reviewer/revision has priority over a never-started
   executor, but every remaining free slot is filled. Never wait for a user prompt to refill capacity.
5. Integration and user-facing summaries are lower priority than runnable delegated work. They may
   use the main thread only after the fill loop has no job for a free worker slot. Continue until every
   lane is CLEAN or STOPPED; never introduce a global execute barrier or review barrier.

Claude's phrase "all calls in one message" maps to consecutive Codex `spawn_agent` calls before the
first `wait_agent`, followed by the mandatory fill → wait → completion → fill loop above, not to
sequential local execution. If collaboration is unavailable or repeatedly refuses every spawn, stop
and report that parallel execution is unavailable; never silently degrade a multi-task parallel stage
to serial execution.

### Parallel mutation isolation

Codex agents share a filesystem and git checkout. Before dispatching parallel mutating tasks in the
same repository, the main agent MUST give every task lane its own git worktree and temporary task
branch, created from the intended story branch. Pass that path as `LANE_WORKTREE` to the executor and
reviewer. They operate only there and never checkout another branch.

**Location is fixed: `<repo-root>/.worktrees/<task-id>/`** via
`git worktree add <repo-root>/.worktrees/<task-id> -b <task-branch> <story-branch>`. Never place a lane
worktree in `/tmp` or any scratch directory outside the repo: it makes every lane's paths unique, so
identical files read in different lanes can never be reused, and it detaches the worktree from the
repo's git dir. If that path cannot be created, STOP and report — never fall back to a temp directory.

Always isolate: one worktree per task lane, including a single-task batch. A fresh worktree has no
installed dependencies — reuse the main checkout's (symlink `node_modules`, or install `--offline` from
a warm cache) rather than a full install per lane, and verify the lane can build before dispatching.
Tell the user each lane's path so they can inspect it, integrate + push promptly so finished work is
visible in the normal checkout, and `git worktree remove` the lane once its commit is integrated and
pushed — a stale registered worktree keeps its branch locked.

After a lane is CLEAN, commit in its worktree and integrate that commit into the story branch. This
short integration step may be serialized, but it MUST NOT pause executors or reviewers in other
worktrees. If integration conflicts, return only that lane to its executor against the latest story
branch and re-review the affected diff. Remove the temporary worktree/branch only after successful
integration and push. Never run parallel mutating agents in one shared checkout.

## Context budget

- A Codex agent does not inherit the parent's reads, so anything a role needs must be in its own prompt
  — which is exactly why it must be the SHORT version. Spawned roles get
  `PLUGIN_ROOT/context/codex-agent-prelude.md` (budget rules included). The main thread reads the full
  `context-budget.md` once for its own orchestration reads; it does not forward it to workers.
- The `tools:` and `disallowedTools:` frontmatter in `agents/*.md` is a Claude Code availability
  mechanism. On Codex it is not enforced by the runtime, so treat each agent's `tools:` line as the
  **declared capability set for that role**: give a spawned role access to those capabilities and no
  more, and do not hand it unrelated connectors. `disallowedTools: mcp__*` means that role gets no
  MCP/connector access at all — it works from the filesystem and the command runner only.
- The budget target (60k per agent run) is a planning number, not a runtime limit, on both runtimes.
  Tool RESULTS are what consume it: prefer `rg`/`git diff --stat`/`jq`-filtered output over reading
  whole files or dumping raw responses, per the budget file.
- When a spawned role reports it ran out of room with work uncovered, surface that upward verbatim.
  Never present a partial audit, review, or breakdown as complete.

## Tool mapping

- `Read`, `Grep`, and `Glob` mean use Codex filesystem inspection tools; prefer `rg`/`rg --files`.
- `Write` and `Edit` mean use the available patch/edit mechanism and preserve unrelated user changes.
- `Bash` means use the Codex command runner within its sandbox and approval rules.
- `Skill tool` means invoke/read the named installed skill according to Codex skill rules.
- `Agent tool` or Claude subagents mean Codex collaboration as described above.
- A hardcoded MCP name such as `mcp__atlassian__*` is a capability request, not a guaranteed tool
  identifier. Use the provider configured in `tool-providers.md` and the connector, MCP, CLI, or API
  actually available in the session. If unavailable, follow the canonical local-file fallback.
- `CLAUDE.md` means project steering instructions generally. On Codex, check `AGENTS.md` first, then
  consume relevant `CLAUDE.md` files as additional project knowledge when present.

## Safety and mutations

- Inspection or scouting must be read-only by default. Do not checkout another branch, pull, stash,
  clean, reset, or discard changes merely to inspect production/default-branch code. Prefer remote
  refs, `git show`, or a separate temporary worktree when an alternate revision is needed.
- Never execute canonical destructive suggestions such as `git checkout -- .` or `git clean -fd`
  without an explicit user request and the approvals required by Codex.
- Treat branch creation, commits, pushes, issue transitions, document publication, and external
  messages as mutations. Perform them only when the invoked workflow and user request authorize
  them, and request approval when the active environment requires it.
- Before modifying any repository, inspect its status and preserve unrelated user changes.
- A task may be marked Done only after the canonical CLEAN, commit, and push gates actually succeed.
  If push or tracker access is unavailable, report the precise incomplete state.

## Runtime wording

In user-facing output, say “Codex skill”, “Codex agent”, or “workflow” as appropriate. Do not tell a
Codex user to invoke Claude slash commands or claim that a Claude-only tool was called.
