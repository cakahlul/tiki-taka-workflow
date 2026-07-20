# Team & Project Context

> **FILL THIS IN.** This file is the single source of truth the workflow agents
> (`project-scout`, `bug-analyst`, `trd-writer`, `task-breaker`) read for team members,
> repositories, and where local repos live. Replace every placeholder below with your own
> squad's data before running `/tiki-taka:dev-workflow` or `/tiki-taka:bug-workflow`.
>
> Delete rows/sections you don't need. Keep the headings — agents key off them.

## Local Repo Roots

Directories where all local repos live. Agents search here (top level) to match a
project/feature name before asking you. List one path per line.

- `/absolute/path/to/your/projects`
- `/absolute/path/to/your/labs`

## Feature Scope

Which features belong to which squad/area. Used to route a PRD/bug to the right repo & people.

### <Squad A>

- <feature>
- <feature>

### <Squad B>

- <feature>
- <feature>

## Squad Members

### <Squad A>

| Role    | Name |
| ------- | ---- |
| Mobile  | <name> |
| Backend | <name> |
| Web     | <name> |

### <Squad B>

| Role    | Name |
| ------- | ---- |
| Mobile  | <name> |
| Backend | <name> |
| Web     | <name> |

## Repository Mapping

Map each repo to who/what owns it. `Responsibility` can name a squad, a person, or
"Depends on Feature Scope" when routing is feature-driven.

### Frontend / Client

| Repository | Responsibility |
| ---------- | -------------- |
| <repo> (Web)    | <owner / squad> |
| <repo> (Mobile) | <owner / squad> |

### Backend

| Repository | Responsibility |
| ---------- | -------------- |
| <repo> | <owner / squad> |

### Others

| Repository | Responsibility |
| ---------- | -------------- |
| <repo> | <owner> |
