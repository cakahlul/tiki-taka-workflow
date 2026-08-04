# Context budget

Single source of truth for how every tiki-taka agent spends context. Read this once per agent run,
before doing the role's own work.

Target: **60k tokens per subagent run.** Not a hard cap the runtime enforces — there is no per-agent
token limit in Claude Code or Codex. It is the number you plan against, and it holds only if you keep
tool RESULTS small. Instructions are cheap; tool output is what blows the budget.

## The rule that matters most

**A tool result stays in context forever.** You cannot un-read a file, un-run a test, or un-dump a
JIRA response. Every token you pull in is paid for on that call and on every call after it. So pull
in the smallest thing that answers the question — always.

Cheap → expensive, take the first that works:

1. A command that prints only the answer (`git diff --stat`, `rg -l`, `jq -r '.key'`).
2. A ranged/filtered read (`rg -n pattern file`, `Read` with `offset`/`limit`).
3. The whole file — only when you actually need the whole file.

**Being cheap is not the goal — being right cheaply is.** Skip a read because you already know what it
says, never because you hit a quota. If you are unsure whether you have enough to be correct, you do
not: read more. A wrong verdict, a missed caller, or a convention reported that isn't the real one
costs the workflow far more than the tokens you saved, because everything downstream inherits it.
`rg -n <symbol>` answers most "am I missing something?" questions for a few dozen tokens — reach for
it before either guessing or opening files.

## Commands: print the answer, not the transcript

- **Tests** — never let a full suite log land in context. Run quiet and keep the tail:
  `<test cmd> 2>&1 | tail -30`. On failure, re-run ONLY the failing test to get its detail. Quote the
  shortest decisive line, not the whole log.
- **Build/lint/typecheck** — same shape: `2>&1 | tail -30`.
- **Git** — `git diff --stat` first to see the shape; `git diff -- <path>` only for files you must
  actually read. Never bare `git log` without `-n`/`--oneline`.
- **Search** — `rg -l` (names only) or `rg -n -m5` (capped matches) before any content dump.
- **JSON/API** — always pipe through `jq` to the fields you need: `| jq -r '.issues[].key'`, never
  the raw response.

## MCP calls: the most expensive thing you can do

An MCP response is a full object — every field, link, avatar URL, and changelog entry — and it is
often 3-8k tokens for ONE call. Twenty calls is your whole budget with nothing to show for it.

- **Never call a metadata/schema endpoint speculatively** (issue-type metadata, field schemas, project
  configuration). Attempt the real operation first; read the error only if it fails. These endpoints
  return the largest payloads in the entire API.
- **Prefer a CLI or HTTP call you can pipe** over the equivalent MCP tool, when one is available and
  authorized — `curl ... | jq -r '.key'` costs a few hundred tokens where the MCP tool costs
  thousands. Use the MCP tool when it is the only access you have.
- **Batch** when the API supports it (bulk create) instead of one call per item.
- **Do not re-fetch** something you already have. Note the id/key/URL the first time and reuse it.

## Reading files and documents — the largest measured cost

On real runs, file reads dominate an agent's context: far more than tests, instructions, or tracker
calls. Two habits account for nearly all of it.

- **Read once, never twice.** Track what you have opened this run. A second read is a lookup — serve it
  with `rg -n '<symbol>' <file>` or a ranged `Read` around the spot, not another full open. Never
  re-read a file to "double-check" what a previous tool result or your own `Edit` already established.
- **Range-read anything large.** `wc -l` first; over ~300 lines, locate with `rg -n` then read only
  that range via `offset`/`limit`. Whole-file reads are for small files and files you will rewrite
  entirely. Barrel/`index` files and long integration tests are the classic traps — big, re-opened
  constantly, and rarely needed in full.
- For a large doc, pull the section you need, not the whole page.

Reading a repo checkout that lives outside the repo (a temp dir, the session scratchpad) also makes
every path session-unique, so nothing read in one lane can be reused in another. Keep worktrees inside
the repo.

## Revision passes

A revision pass is not a fresh start. When you are called again with reviewer feedback or a
correction:

- Do NOT re-read the task, TRD, or spec you already read on the first pass.
- Do NOT reload a skill you already applied.
- Read only what the specific feedback names.

## When the budget runs out

If you are approaching the budget and the job is genuinely not finished, **do not silently truncate
your work and present it as complete.** Finish the highest-value part, then stop and report:

- what you covered,
- what you did NOT cover, specifically,
- what it would take to finish.

An honest partial result the caller can act on beats a confident summary with an invisible hole in it.
Never invent a finding, a verdict, or a status you did not actually verify because you ran short.
