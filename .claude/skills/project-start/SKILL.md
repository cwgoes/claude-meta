---
name: project-start
description: Get oriented on an existing project - understand structure, objective, state, delta, and establish working level
constitution: CLAUDE.md
alignment:
  - Work Modes
  - Core Invariants
  - Plans
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
5. **Scan plans/** — Check which criteria have active/done plans
6. **Run `git status` from project directory** — Each project is its own git repo per Repository Model
7. **Check submodules** — If project uses submodules, note their status
8. **Build objective trace** — Map current level to root
9. **Assess state** — Determine what's complete, in-progress, blocked
10. **Compute delta** — What remains to reach success criteria
11. **Assess criteria coverage** — Map each SC-N to plan status (see Plan State Assessment)
12. **Confirm working level** — If hierarchy exists, confirm which level to work at
13. **Cross-session pattern detection** — Scan LOG.md for recurring patterns (see below)
14. **Validate context state** — Verify hook captured state correctly (see Context State Validation)

## Cross-Session Pattern Detection

After reading LOG.md, scan for recurring patterns:

**Detection Rules:**
| Pattern | Trigger | Warning |
|---------|---------|---------|
| **Repeated Avoid** | Same Avoid entry appears in multiple sessions | Systemic issue not being addressed |
| **Stalled items** | Same "Next" item appears in 3+ consecutive sessions | Blocked work or avoidance |

**Output (if pattern detected):**
```
## ⚠️ Pattern Warning

[Pattern type]: [Description]
- Occurrences: [list sessions]
- Suggested action: [what to do about it]
```

If no patterns detected, omit this section.

## Output Format (--list)

```
## Available Projects

| Project | Last Session | Status |
|---------|--------------|--------|
| [name] | [date or "none"] | [active/stale/new] |

Use: /project-start <name>
```

## Plan State Assessment

Per the Plan Invariant (CLAUDE.md), assess criteria coverage:

1. **Parse OBJECTIVE.md** for all SC-N criteria
2. **Scan plans/** directory for plan files
3. **Map each criterion** to its status by checking plan `criteria:` frontmatter:

| Status | Symbol | Meaning |
|--------|--------|---------|
| unaddressed | ○ | No plan references this criterion |
| active | → | Plan with `status: active` addresses this |
| done | ✓ | Plan with `status: done` addresses this |

4. **Identify active plan** at this level (most recent with `status: active`)

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

## Criteria Coverage

| Criterion | Description | Status | Plan |
|-----------|-------------|--------|------|
| SC-1 | [description] | ✓ done | 2026-02-03-cache.md |
| SC-2 | [description] | → active | 2026-02-03-cache.md |
| SC-3 | [description] | ○ unaddressed | — |

**Coverage:** 2/3 addressed — 1 unaddressed

## Active Plan

**File:** plans/2026-02-03-cache-layer.md
**Criteria:** SC-1, SC-2

### Steps
- [x] Design interface
- [x] Core implementation
- [ ] Eviction policy ← current
- [ ] Tests

### Next Action
Continue: Eviction policy

(Or if no plan exists:)

## Plan State

No active plan.
**Unaddressed criteria:** SC-1, SC-2, SC-3

Use `/plan` to create implementation plan.

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

## Context State
✓ Validated — .claude/sessions/<session_id>/context-state.json

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

## Context State Validation

After completing the protocol, validate that context state was captured correctly:

**Validation Steps:**
1. **Check state file exists** at `.claude/sessions/<session_id>/context-state.json`
2. **Verify required fields** are present and non-empty:
   - `session_id` — matches current session
   - `timestamp` — recent (within last minute)
   - `project` — matches resolved project path
   - `project_name` — matches project name
   - `objective` — non-empty string
   - `trace` — array with at least one element
   - `level` — "project" or "subproject"
   - `status` — "active", "paused", or "completed"

3. **Cross-check consistency:**
   - `project` field matches the path resolved in step 1
   - `objective` field matches first line/title from OBJECTIVE.md
   - `trace` includes current objective

**On validation failure:**

If state file missing or invalid:
```
## ⚠️ Context State Warning

State file: [missing | invalid]
Issue: [specific problem]

Recovery: Re-reading OBJECTIVE.md to trigger state capture...
```

Then re-read OBJECTIVE.md to trigger the `PostToolUse` hook again. If still failing after retry:
```
## ❌ Context State Error

Hook may be misconfigured. Manual verification needed:
- Check `.claude/hooks/capture-project-context.sh` exists and is executable
- Check `.claude/settings.local.json` has PostToolUse hook registered for Read
- Run: cat .claude/sessions/<session_id>/context-state.json

Proceeding without validated context state.
```

**Output (on success):**

Add to the standard output:
```
## Context State
✓ Validated — .claude/sessions/<session_id>/context-state.json
```

**Output (on warning):**
```
## Context State
⚠️ [Issue] — [recovery action taken]
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
