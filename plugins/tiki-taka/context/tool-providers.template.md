# Tool Providers

> **Written by `/tiki-taka:setup-workflow`.** This is the blank template — the plugin is generic
> while it looks like this. When the workflow commands read this file and find only placeholders
> (`<...>`), they treat it as "not configured"; workers return `NEEDS_INPUT` and the main thread asks where things go.
> `/tiki-taka:reset-workflow` restores this file to the template.

## PRD Slicing
- Destination: <Confluence | Other: name>
- MCP/Tool: <mcp__atlassian__* | name | none (not connected)>
- Fed to: prd-analyst, prd-slicer

## TRD
- Destination: <Confluence | Other: name>
- MCP/Tool: <mcp__atlassian__* | name | none (not connected)>
- Fed to: trd-writer, task-breaker

## TRD Template
- Status: <provided (user supplied a template) | system-generated (no template; system creates one)>
- Fed to: trd-writer
- Templates (per stack): <paste/attach the user's TRD template per stack here, or leave blank if system-generated>

## Tasks
- Destination: <JIRA | Other: name>
- MCP/Tool: <mcp__atlassian__* | name | none (not connected)>
- Fed to: task-breaker, executors, reviewers

## Designer
- Tool: <Figma | Other: name>
- MCP/Tool: <mcp__figma__* | name | none (not connected)>
- Fed to: prd-analyst, trd-writer, fe-web-executor, fe-web-reviewer, fe-mobile-executor, fe-mobile-reviewer

## Task Grouping
- Scheme: <flat (no parent) | Task → subtask | Epic → task | Epic → story → subtask | Story → subtask>
- Fed to: task-breaker

## Task Creation Skill
- Skill: <name | none>
- Fed to: task-breaker
