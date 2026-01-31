---
name: project-start
description: Get oriented on an existing project - understand structure, objective, state, delta, and establish working level
constitution: CLAUDE.md
alignment:
  - Work Modes
  - Memory System / Projects
  - Memory System / Repository Model
  - Memory System / Session Protocol
  - Context Persistence / Context Invariants
  - Context Persistence / State Externalization
---

# /project-start

Get oriented on an existing project. **Requires project name.**

## Invocation

```
/project-start <project-name>
/project-start --list
```

- `<project-name>` — Name or path of project to start
- `--list` — List available projects with their status

## Work Mode Detection

Per CLAUDE.md Work Modes, determine current mode based on structure:

| Structure Found | Mode |
|-----------------|------|
| No OBJECTIVE.md | Ad-hoc (suggest project creation if continuing prior work) |
| Own git repository with OBJECTIVE.md | Project |

**Mode indicators in output:** Always show detected mode and any upgrade recommendations.

**Note:** The workspace repo is metadata-only (constitution, configuration). All tracked work requires a project repo.

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
5. **Read context-state.json** — If exists, display prior session info (see Context State below)
6. **Run `git status` from project directory** — Each project is its own git repo per Repository Model
7. **Check submodules** — If project uses submodules, note their status
8. **Build objective trace** — Map current level to root
9. **Assess state** — Determine what's complete, in-progress, blocked
10. **Compute delta** — What remains to reach success criteria
11. **Confirm working level** — If hierarchy exists, confirm which level to work at
12. **Set active project** — Note the active project for session context
13. **Write context-state.json** — Create or update with status "active" (see Context State below)
14. **Cross-session pattern detection** — Scan LOG.md for recurring patterns (see below)

## Cross-Session Pattern Detection

After reading LOG.md, scan for recurring patterns:

**Detection Rules:**
| Pattern | Trigger | Warning |
|---------|---------|---------|
| **Repeated pattern class** | 2+ failures in same class within last 5 sessions | Systemic gap in that reasoning area |
| **Scope creep** | 3+ sessions where actual work exceeded stated scope | Planning/scoping process issue |
| **Stalled items** | Same "Next" item appears in 3+ consecutive sessions | Blocked work or avoidance |
| **Failure clustering** | 3+ failures in single session | Approach may be fundamentally flawed |

**Output (if pattern detected):**
```
## ⚠️ Pattern Warning

[Pattern type]: [Description]
- Occurrences: [list sessions/entries]
- Suggested action: [what to do about it]

Consider: [Prompt for reflection on systemic issue]
```

**Example:**
```
## ⚠️ Pattern Warning

Repeated Pattern Class: Ecosystem Overconfidence
- Occurrences: FP-001 (2026-01-30), Session 2026-01-28 (undocumented)
- Suggested action: Before adopting new libraries/features, add explicit "stability verification" step

Consider: Is there a systemic gap in researching technology maturity before adoption?
```

If no patterns detected, omit this section (don't output "no warnings").

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
Mode: Project

## Objective Trace
Root: [root objective]
  └── [parent if any]
        └── **Current** ← working here

## Git State
- Repository: [project repo path]
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

## Context State

Manages `<project-path>/context-state.json` for statusline display and session continuity.

### On Project Start

1. **Check for existing file:**
   ```bash
   cat <project-path>/context-state.json 2>/dev/null
   ```

2. **If exists — read and display:**
   ```
   Prior Session: [timestamp from file]
   Status: [status from file]
   Last Objective: [objective from file]
   ```
   Then update timestamp and status to "active".

3. **If missing — create:**
   - Extract objective summary: first heading or sentence from OBJECTIVE.md
   - Build trace from objective hierarchy
   - Set status to "active"

4. **Write context-state.json:**
   ```json
   {
     "timestamp": "[ISO 8601 now]",
     "project": "[project path]",
     "objective": "[1-line summary from OBJECTIVE.md]",
     "trace": ["root objective", "parent if any", "current"],
     "level": "project | subproject",
     "status": "active"
   }
   ```

### File Location

`<project-path>/context-state.json` — at project root alongside OBJECTIVE.md and LOG.md.

**Per-project state:** Each project maintains its own context-state.json. The statusline displays whichever project's state was most recently updated.

**Multiple windows:** Different Claude Code windows can work on different projects. Each window updates its project's context-state.json independently.

**Self-check:** If you cannot populate these fields from working memory after completing the protocol, re-read the project files. Context loss at session start indicates a problem.

## Failure Protocol

If project not found:
1. List available projects
2. Ask user to specify correct name or path
3. Suggest `/project-create` if they want a new project

If project files malformed:
1. Report what was found/not found
2. Identify specific issues
3. Suggest fixes
