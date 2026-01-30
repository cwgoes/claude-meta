---
name: project-start
description: Get oriented on an existing project - understand structure, objective, state, delta, and establish working level
constitution: CLAUDE.md
alignment:
  - Memory System / Projects
  - Memory System / Session Protocol
---

# /project-start

Get oriented on an existing project. **Requires project name.**

## Invocation

```
/project-start <project-name>
/project-start --list
```

- `<project-name>` — Name or path of project to start (e.g., `allir`, `pedersen-solidity-benchmark`)
- `--list` — List available projects with their status

## Project Resolution

Projects are located by searching:
1. `projects/<name>/OBJECTIVE.md`
2. `<name>/OBJECTIVE.md`
3. Direct path if contains `/`

If project not found, list available projects and ask user to specify.

## Protocol

1. **Resolve project** — Find OBJECTIVE.md using resolution rules above
2. **Read OBJECTIVE.md** — Understand what we're building and success criteria
3. **Read LOG.md** — Understand prior work and decisions
4. **Read LEARNINGS.md** — Check for applicable learnings (workspace-level)
5. **Run `git status`** — Understand working tree state (uncommitted changes, dirty state)
6. **Build objective trace** — Map current level to root
7. **Assess state** — Determine what's complete, in-progress, blocked
8. **Compute delta** — What remains to reach success criteria
9. **Confirm working level** — If hierarchy exists, confirm which level to work at
10. **Set active project** — Note the active project for session context

## Output Format (--list)

```
## Available Projects

| Project | Last Session | Status |
|---------|--------------|--------|
| [name] | [date or "none"] | [active/stale/new] |

Use: /project-start <name>
```

## Output Format (project selected)

```
## Project: [name]
Path: [relative path to project]

## Objective Trace
Root: [root objective]
  └── [parent if any]
        └── **Current** ← working here

## Git State
- Branch: [current branch]
- Status: [clean | uncommitted changes | dirty]
- Uncommitted files: [list if any]

## Applicable Learnings
[From LEARNINGS.md]
- [Learning ID]: [relevance]

## Success Criteria
- [ ] [criterion 1]
- [x] [criterion 2 - completed]
...

## Current State
- Completed: [summary of done work]
- In Progress: [active work]
- Blocked: [blockers if any]

## Delta (What Remains)
1. [next step]
2. [subsequent steps]

## Context Budget
OBJECTIVE.md: [X KB] | LOG.md: [Y KB] | Total: [Z KB] / ~80KB limit

## Recommendations
[Any observations: scope creep, constraint violations, suggested approach]
```

## Failure Protocol

If project not found:
1. List available projects
2. Ask user to specify correct name or path
3. Suggest `/project-create` if they want a new project

If project files malformed:
1. Report what was found/not found
2. Identify specific issues
3. Suggest fixes
