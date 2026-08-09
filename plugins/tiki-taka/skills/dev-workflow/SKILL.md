---
name: dev-workflow
description: Run the complete Tiki-Taka PRD-to-ship development workflow in Codex, including planning or execution-only mode. Use when the user explicitly asks for Tiki-Taka development workflow, not for ordinary coding requests.
---

# Tiki-Taka Development Workflow for Codex

1. Resolve `PLUGIN_ROOT` from this file's directory (`skills/dev-workflow/`) by ascending two
   directories to the plugin root.
2. Read `PLUGIN_ROOT/context/codex-runtime.md` completely.
3. Read `PLUGIN_ROOT/context/model-policy.md` completely and establish `RUNTIME=codex`.
4. Read `PLUGIN_ROOT/commands/dev-workflow.md` completely; it is the canonical workflow source and
   must not be summarized before execution.
5. Execute the canonical workflow with the compatibility contract and model policy applied.
6. For every named agent call, resolve model/effort immediately, pass `fork_context: false`, one
   accepted spawn field (`message` or `items`), role instructions, scoped locations, digest, and budgets.
   Read each role definition completely before delegation.
7. Preserve planning, execution-only, Q&A, independent review, CLEAN gates, DAG-ready parallelism,
   commits, pushes, and final review summary. Main performs narrow status transitions; never spawn a
   status-only executor or duplicate publisher.

**Scheduler invariant:** after any delegated job completes, process completion and refill every free slot
from ready/reviewer/revision queues before commentary, status replies, integration, or unrelated work.
Never wait for the user to notice or request reuse of an idle slot. Dependents wait for integrated
prerequisites; revisions resume stored lane IDs. Read exact collaboration declarations before first use,
persist exact non-empty spawn IDs before waiting, and never trial guessed keys or IDs. No periodic polling.
