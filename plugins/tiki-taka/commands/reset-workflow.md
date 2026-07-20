---
description: Reset the plugin back to generic — undo /tiki-taka:setup-workflow. Restores team-context.md to its blank template and deletes tool-providers.md, so no team-specific data remains. No agent files are touched (they were never edited).
---

# Reset Workflow

Undo `/tiki-taka:setup-workflow`. Return the plugin to its generic, un-configured state.

Setup only writes two files, so reset only touches those two — agent files are never edited, so
there is nothing team-specific left in them.

## Steps

1. **Confirm with the user first** (this discards their team config). Use `AskUserQuestion`: "Reset
   the workflow to generic? This clears your repo roots, team members, and tool-provider setup."
   Options: **Yes, reset** / **Cancel**. If Cancel → stop, do nothing.

2. On confirm, run:

   ```bash
   cp "${CLAUDE_PLUGIN_ROOT}/context/team-context.template.md" "${CLAUDE_PLUGIN_ROOT}/context/team-context.md"
   cp "${CLAUDE_PLUGIN_ROOT}/context/tool-providers.template.md" "${CLAUDE_PLUGIN_ROOT}/context/tool-providers.md"
   ```

   Both restore their file to the blank template (placeholders back in place). The workflow commands
   treat a placeholder-only `tool-providers.md` as "not configured" → generic behavior (agents ask
   the user).

3. Report done: plugin is generic again. Run `/tiki-taka:setup-workflow` to configure a team.
