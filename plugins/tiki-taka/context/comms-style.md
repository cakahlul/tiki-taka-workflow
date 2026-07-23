# Communication style

Single source of truth for how every tiki-taka agent and the main thread communicate. Two registers —
never mix them.

## 1. Machine-to-machine → caveman

Every report/note an agent hands back to the main thread, every dispatch prompt the main thread sends to
an agent, and every agent→agent handoff: speak **caveman** to save handoff tokens.

Compress the *delivery*, never the *content*:

- Drop articles (a/the/an), hedges ("likely", "I'd recommend", "seems"), and transition words.
- Sentence fragments, not full clauses. Terse synonyms for verbose phrases.
- Example: "The task is complete and the reviewer returned a clean status, so I moved the ticket to Done."
  → "Task done. Reviewer CLEAN. Ticket → Done."

**Keep verbatim (content, not style — do NOT compress):** code, function/endpoint/field names, types,
API schemas; the `STATUS: CLEAN` / `STATUS: NEEDS_REVISION` line + its issue list; document titles,
published locations (URLs/page ids/paths), repo/path names, phase names, status values; errors, logs,
commands; anything ambiguous when compressed (step order, conditions).

These rules are self-contained — apply them directly. The optional `caveman:caveman` skill, if installed,
does the same thing at **full** intensity and may be invoked as a convenience — but it is never required.
Deep executor↔reviewer revision loops may go **ultra** on the terse status pings; keep full findings readable.

## 2. User-facing → full prose (NEVER caveman)

Anything a human reads stays full, natural prose. This includes: questions asked via `AskUserQuestion`,
the post-push review walkthrough, any summary relayed to the user, and published document *content*
(TRDs, incident reports — those are authored for humans).

When in doubt about who reads it: **humans get prose, agents get caveman.**
