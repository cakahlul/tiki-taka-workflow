---
description: Critically review a complete PRD and its attachments against current production code, score its development readiness, and give confidence-rated findings with actionable feedback.
---

# PRD Review

## Runtime and model routing

This command establishes `RUNTIME=claude`. Before calling any subagent, read
`${CLAUDE_PLUGIN_ROOT}/context/model-policy.md`. Resolve `prd-reviewer` and `project-scout` independently,
honor user overrides and fallbacks, and do not add static model choices to agent definitions.

## Setup gate (MUST run first)

Read `${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md` and
`${CLAUDE_PLUGIN_ROOT}/context/team-context.md`. If the first line of `tool-providers.md` is
`<!-- SETUP: complete -->`, proceed. Otherwise compare both files field-by-field with their templates:

- Missing files or all-placeholder fields: stop and run `/tiki-taka:setup-workflow` with the user.
- Partially configured fields: run `/tiki-taka:setup-workflow` in instant mode for missing fields only,
  then continue.
- Fully configured fields: proceed.

Read Local Repo Roots, Repository Mapping, and Feature Scope from `team-context.md`. Read these providers
from `tool-providers.md` and pass them to the workers:

- **PRD Slicing**: PRD and related-PRD source.
- **Designer**: Figma, image, flow, and UI/UX attachment access.
- **Scouting**: current-code discovery.

If a provider is not connected, use its configured local destination where possible. Never pretend an
unread source or attachment was reviewed.

## Required user context

Before dispatch, ALWAYS use `AskUserQuestion` to ask: **“Are there any related PRDs that should be used
as references for this review? Share their locations, or answer ‘none’.”** Record the answer verbatim and
pass it to `prd-reviewer`. This question is mandatory even when the submitted PRD links related documents.

Resolve the submitted PRD location from the invocation or **PRD Slicing** provider. If neither supplies
one, ask for it before dispatch.

## Context budget

Read `${CLAUDE_PLUGIN_ROOT}/context/context-budget.md` once in main. Pass locations, provider details,
repo roots, the related-PRD answer, and compact role instructions; do not paste whole documents.

## 1. Review PRD and scout current code in parallel

Call `tiki-taka:prd-reviewer` and read-only `tiki-taka:project-scout` concurrently.

Tell `prd-reviewer` to review the complete PRD, every attachment/reference, and the supplied related PRDs.
Tell `project-scout` explicitly to resolve the affected repositories and report the **current production
implementation** of every area the PRD touches: flows, endpoints, screens, schemas, integrations, existing
behavior, and missing behavior. Do not modify `project-scout` or broaden it beyond read-only scouting.

If either returns `NEEDS_INPUT`, wait for both, combine compatible questions, ask from main, record answers
verbatim, and resume the affected worker. In particular:

- If the PRD does not explicitly and unambiguously identify every affected service/repository,
  `prd-reviewer` must request that information. Do not infer it from likely code ownership.
- If any image, Figma page, diagram, file, or linked attachment cannot be read clearly, request an
  accessible export/upload, pasted content, or access. Do not finalize or score until it is reviewed.

## 2. Reconcile PRD with production

After both workers finish, compare the reviewer findings with project-scout's current-code report. Add a
review result for every material mismatch, undocumented migration, compatibility risk, reused behavior the
PRD contradicts, or affected component the PRD misses. Recalculate affected rubric dimensions and the final
score after adding those results. If reconciliation creates an ambiguity, ask the user and resolve it before
scoring. Never turn review feedback into technical design decisions.

## 3. Present result

Return one user-facing report:

1. **PRD Score (0–100)**: overall score, dimension breakdown, and `READY` or `NOT READY`.
2. **Review Results**: one row/item per finding with ID, PRD section/attachment, severity
   (`BLOCKER`, `HIGH`, `MEDIUM`, `LOW`, or `PASS`), concise result, evidence/current-code context, and a
   **confidence percentage (0–100%)**. Never omit confidence from a result.
3. **Feedback Suggestions**: actionable PRD wording, missing acceptance criteria, state/flow additions, or
   scope clarifications mapped to finding IDs.
4. **Coverage**: submitted PRD, every attachment/reference, related PRDs, and repositories inspected.

Use `prd-reviewer`'s rubric. `READY` requires score >=90, no unresolved `BLOCKER`/`HIGH`/`MEDIUM` result,
explicit affected services/repositories, complete attachment coverage, and enough testable detail for
development and acceptance without material interpretation. Otherwise return `NOT READY`.

This command ends with the report. Do not publish documents, slice rollout phases, create a TRD or tasks,
modify code, or invoke another workflow.

## General principles

- The submitted PRD is the review subject; related PRDs and production code are evidence, not authority to
  silently rewrite it.
- Review all content. Missing access means `NEEDS_INPUT`, never reduced confidence or an assumed score.
- Criticize requirements, omissions, contradictions, and ambiguity; do not invent product intent.
- Preserve each clarification question and answer verbatim in the final report.
- Worker outputs stay compact; main renders the complete user-facing report.
