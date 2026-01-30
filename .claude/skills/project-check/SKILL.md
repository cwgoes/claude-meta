---
name: project-check
description: Project lifecycle management aligned with cognitive architecture
subskills:
  - name: project-start
    description: Get oriented on an existing project - understand structure, objective, state, delta, and establish working level
  - name: project-check
    description: Perform a comprehensive project consistency and completeness check
  - name: project-create
    description: Start a new project - creates directory, defines objectives, and sets up full project structure
---

# Project Check Skill

Project lifecycle operations integrated with the cognitive architecture.

---

## /project-start

Get oriented on an existing project. Use at session start.

### Protocol

1. **Locate project** — Find OBJECTIVE.md in current or specified directory
2. **Read OBJECTIVE.md** — Understand what we're building and success criteria
3. **Read LOG.md** — Understand prior work and decisions
4. **Run `git status`** — Understand working tree state (uncommitted changes, dirty state)
5. **Build objective trace** — Map current level to root
6. **Assess state** — Determine what's complete, in-progress, blocked
7. **Compute delta** — What remains to reach success criteria
8. **Confirm working level** — If hierarchy exists, confirm which level to work at

### Output Format

```
## Project: [name]

## Objective Trace
Root: [root objective]
  └── [parent if any]
        └── **Current** ← working here

## Git State
- Branch: [current branch]
- Status: [clean | uncommitted changes | dirty]
- Uncommitted files: [list if any]

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

### Failure Protocol

If project files missing or malformed:
1. Report what was found/not found
2. Suggest `/project-create` if no project exists
3. Identify specific issues if files exist but are malformed

---

## /project-check

Comprehensive project consistency and completeness verification.

### Verification Checklist

| Check | Description |
|-------|-------------|
| **Structure** | OBJECTIVE.md and LOG.md exist and are well-formed |
| **Context Budget** | Combined size ≤ 10% of context (~80KB) |
| **Depth** | Hierarchy ≤ 3 levels |
| **Objective Trace** | Every level connects to root |
| **Success Criteria** | Each objective has verifiable criteria |
| **Boundaries** | File/module boundaries are defined |
| **LOG Integrity** | Append-only structure maintained |
| **Subprojects** | If any, properly referenced (not inlined) |
| **Dependencies** | Declared and resolvable |
| **Drift** | Work in LOG aligns with OBJECTIVE |
| **Git State** | Working tree clean or changes accounted for |

### Protocol

1. **Explore** — Use explore agent to gather project structure
2. **Run `git status`** — Check for uncommitted work
3. **Verify** — Check each item in the checklist
4. **Reflect** — Apply triple reflection on findings
5. **Report** — Present findings with specific issues and recommendations

### Output Format

```
## Project Health: [HEALTHY | ISSUES | CRITICAL]

## Git State
- Branch: [current branch]
- Status: [clean | uncommitted changes]
- Last commit: [hash and message]

## Checklist

| Check | Status | Notes |
|-------|--------|-------|
| Structure | Pass/Fail | [details] |
| Context Budget | Pass/Warning/Fail | [X KB / 80KB] |
| Depth | Pass/Fail | [current depth] |
| Objective Trace | Pass/Fail | [details] |
| Success Criteria | Pass/Fail | [details] |
| Boundaries | Pass/Fail | [details] |
| LOG Integrity | Pass/Fail | [details] |
| Subprojects | Pass/Fail/N/A | [details] |
| Dependencies | Pass/Fail | [details] |
| Drift | Pass/Warning/Fail | [details] |
| Git State | Pass/Warning | [details] |

## Issues (if any)
1. [Issue] — [why it matters] — [suggested fix]
2. ...

## Drift Analysis
[Comparison of stated objectives vs. actual work logged]

## Triple Reflection
- **Error avoidance**: What could cause project failure?
- **Success patterns**: What's working well?
- **Synthesis**: Key insight for project health

## Recommendations
- [Priority 1 action]
- [Priority 2 action]
```

### Escalation Triggers

Escalate to user when:
- Context budget exceeded (requires decomposition)
- Depth limit exceeded (requires restructuring)
- Significant drift detected (requires objective reassessment)
- Circular dependencies found
- Uncommitted changes from unknown source

---

## /project-create

Initialize a new project with proper structure.

### Prerequisites

Before creating, clarify with user:
1. **Objective** — What are we building?
2. **Success criteria** — How do we know it's done?
3. **Scope** — What's in/out of scope?
4. **Location** — Where should the project live?

### Protocol

1. **Gather requirements** — Use AskUserQuestion if unclear
2. **Plan structure** — Determine if hierarchy needed, estimate size
3. **Create directory** — At specified or sensible location
4. **Initialize git** — If not already in a repo
5. **Write OBJECTIVE.md** — With success criteria and boundaries
6. **Write LOG.md** — With initial session entry
7. **Verify** — Check structure meets constraints

### OBJECTIVE.md Template

```markdown
# [Project Name]

## Objective
[Clear statement of what we're building]

## Success Criteria
- [ ] [Verifiable criterion 1]
- [ ] [Verifiable criterion 2]
- [ ] [Verifiable criterion 3]

## Scope
**In scope:**
- [What's included]

**Out of scope:**
- [What's explicitly excluded]

## Boundaries
| Component | Files/Modules |
|-----------|---------------|
| [Component 1] | [paths] |
| [Component 2] | [paths] |

## Dependencies
- [External dependencies]
- [Sequencing requirements]

## Subprojects
[None, or references to subproject directories]
```

### LOG.md Template

```markdown
# Project Log

## Session 1 — [date]

### Accomplished
- Project initialized

### Decisions
- [Initial decisions with rationale]

### Next
- [First implementation steps]
```

### Output Format

```
## Created: [project-name]/

## Files
- OBJECTIVE.md ([X KB])
- LOG.md ([Y KB])

## Git
- Repository: [initialized | already exists]
- Initial commit: [yes | no]

## Structure
[Directory tree if hierarchy created]

## Verification
- [x] Structure valid
- [x] Context budget: [Z KB] / 80KB
- [x] Depth: [N] / 3 max
- [x] Success criteria defined
- [x] Boundaries specified

## Next Steps
1. [First recommended action]
2. [Second recommended action]
```

### Failure Protocol

If creation blocked:
1. Report what's blocking (permissions, existing files, unclear requirements)
2. Suggest resolution
3. Do not create partial/malformed project structure

---

## Session Protocol (from CLAUDE.md)

### Starting a Session

1. Read OBJECTIVE.md — establishes what success looks like
2. Read LOG.md — context on prior decisions
3. `git status` — understand working tree state
4. Confirm working level

### Ending a Session

1. Append to LOG.md: accomplishments, decisions, what's next
2. Commit if implementation is verified and complete

**Git commit criteria:**
- Implementation is verified and complete
- User explicitly requests
- Before attempting risky refactors

**NEVER commit:**
- Broken or unverified code
- "Progress" without working state

---

## Integration with Cognitive Architecture

### Mode Selection

| Operation | Primary Mode | Supporting Modes |
|-----------|--------------|------------------|
| project-start | Explore | — |
| project-check | Verify | Explore |
| project-create | Implement | Plan (if complex) |

### Parallel Viability

- **project-start**: Can run in parallel with other exploration
- **project-check**: Can parallelize sub-checks if project is large
- **project-create**: Sequential (creates foundational structure)

### Reflection Protocol

All operations should answer before completing:
1. Does this serve the user's goal (rapid, efficient progress)?
2. Is there unnecessary overhead being introduced?
3. Does the output enable immediate productive work?

### Termination Criteria

- **project-start**: Complete when working level is confirmed
- **project-check**: Complete when all checks pass or issues reported
- **project-create**: Complete when structure verified and ready for work
