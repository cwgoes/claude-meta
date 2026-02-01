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

Projects are always in the `projects/` subdirectory (never workspace root).

Resolution:
1. `projects/<name>/OBJECTIVE.md` — standard location
2. `projects/<path>/OBJECTIVE.md` — if name contains `/` (subpath within projects/)

If project not found, list available projects and ask user to specify.

## Protocol

1. **Resolve project** — Find OBJECTIVE.md using resolution rules above
2. **Read OBJECTIVE.md** — Understand what we're building and success criteria (triggers automatic state capture via hook)
3. **Read LOG.md** — Understand prior work and decisions
4. **Read LEARNINGS.md** — Check for applicable learnings (workspace-level)
5. **Read analysis/INDEX.md** — If exists, note active analyses and topics for discovery
6. **Run `git status` from project directory** — Each project is its own git repo per Repository Model
7. **Check submodules** — If project uses submodules, note their status
8. **Build objective trace** — Map current level to root
9. **Assess state** — Determine what's complete, in-progress, blocked
10. **Compute delta** — What remains to reach success criteria
11. **Confirm working level** — If hierarchy exists, confirm which level to work at
12. **Cross-session pattern detection** — Scan LOG.md for recurring patterns (see below)

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

## Active Analyses
[From analysis/INDEX.md, if exists]
- A001: [Title] — [topics]
- A002: [Title] — [topics]

(Or: "No analysis/ directory")

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

## Context State (Automatic)

Context state is managed automatically by hooks — no manual file management needed.

**How it works:**
- When you read OBJECTIVE.md (step 2), the `PostToolUse` hook automatically captures project context
- State is stored at `.claude/sessions/<session_id>/context-state.json`
- Each Claude Code window has its own session ID, enabling parallel work without conflicts
- The statusline reads this state to display the current project

**Session isolation:** Multiple Claude Code windows can work on different projects simultaneously. Each session's state is keyed by its unique session ID.

**On context compression:**
- `PreCompact` hook saves state before compression
- `SessionStart` hook (after compact) outputs full context digest automatically
- No manual intervention needed — context is restored transparently

**Self-check:** If you cannot state the current objective after completing the protocol, re-read OBJECTIVE.md. This re-triggers state capture via the hook.

## Failure Protocol

If project not found:
1. List available projects
2. Ask user to specify correct name or path
3. Suggest `/project-create` if they want a new project

If project files malformed:
1. Report what was found/not found
2. Identify specific issues
3. Suggest fixes
