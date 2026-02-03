---
name: project-create
description: Start a new project - creates directory, defines objectives, and sets up full project structure
constitution: CLAUDE.md
alignment:
  - Work Modes
  - Core Invariants
  - Checkpoint Model
---

# /project-create

Initialize a new project with proper structure.

## Invocation

```
/project-create <project-name>
/project-create              # Will prompt for name
```

## Work Mode Integration

Per CLAUDE.md Work Modes:
- **Ad-hoc** work has no structure — this skill is not needed
- **Project** work requires own repository with OBJECTIVE.md + LOG.md — use this skill

When ad-hoc work needs to graduate (scope expands, decisions worth recording), use this skill to create a project.

**Workspace is metadata-only.** Projects are never created in the workspace repo.

## Prerequisites

Before creating, clarify with user:
1. **Objective** — What are we building?
2. **Success criteria** — How do we know it's done?
3. **Scope** — What's in/out of scope?

**Location:** Projects are always created in `projects/<name>/` (never workspace root).

## Protocol

1. **Gather requirements** — Use AskUserQuestion if unclear
2. **Plan structure** — Determine if hierarchy needed, estimate size
3. **Create directory** — At `projects/<name>/` (always in projects/ subdirectory)
4. **Initialize git** — ALWAYS (one project = one repository per Repository Model)
5. **Write OBJECTIVE.md** — With success criteria and boundaries (triggers automatic state capture via hook)
6. **Write LOG.md** — With initial session entry
7. **Create initial commit** — Checkpoint the project structure
8. **Verify** — Check structure meets constraints
9. **Note LEARNINGS.md** — Reference workspace-level learnings repository

**Subproject vs. New Project:**
- **New project** → `git init` (own repo) — independent lifecycle, distinct ownership
- **Subproject** → subdirectory or submodule within existing project repo

## OBJECTIVE.md Template

```markdown
# [Project Name]

## Objective
[Clear statement of what we're building]

## Success Criteria

### SC-1: [Verifiable criterion]
**Status:** Pending
**Files:**
- `[path]` — [role/purpose]
**Verification:** [command or manual check]

### SC-2: [Verifiable criterion]
**Status:** Pending
**Files:**
- `[path]` — [role/purpose]
**Verification:** [command or manual check]

### SC-3: [Verifiable criterion - composite example]
**Status:** Pending
**Subproject:** `crates/my-component/`
**Interface:**
- **Inputs:** [what parent provides]
- **Outputs:** [what subproject delivers]
- **Guarantees:** [invariants/requirements]

## Infrastructure
*Files supporting multiple criteria or project-wide concerns.*
- `[path]` — [purpose]

## Scope
**In scope:**
- [What's included]

**Out of scope:**
- [What's explicitly excluded]

## Dependencies
- [External dependencies]
- [Sequencing requirements]
```

## Criteria Types

**Leaf criterion** (files ≤80KB total):
```markdown
### SC-1: User authentication
**Status:** Pending
**Files:**
- `src/auth.ts` — OAuth flow
**Tests:** `npm test -- auth.test.ts` | `tests/auth.test.ts`
**Benchmark:** `npm run bench:auth` | latency_p99 < 50ms
**Verification:** `npm test -- --grep auth`
```

**Optional fields:**
- **Tests:** `command | test_files` — Criterion-specific test command and files
- **Benchmark:** `command | metric op threshold, ...` — Performance verification

**Composite criterion** (files >80KB, decomposed into subproject):
```markdown
### SC-3: Performant prover
**Status:** Pending
**Subproject:** `crates/prover/`
**Interface:**
- **Inputs:** Circuit constraints
- **Outputs:** Valid proof
- **Guarantees:** Soundness, ≥1MHz
```

Subproject OBJECTIVE.md must declare `parent_criterion: SC-3` in YAML frontmatter.

## LOG.md Template

```markdown
# Project Log

## Session 1 — [date]

### Accomplished
- Project initialized

### Decisions
- [Initial decisions with rationale]

### Learnings
[If any non-obvious insights during setup]

### Next
- [First implementation steps]
```

## Output Format

```
## Created: [project-name]/

## Files
- OBJECTIVE.md ([X KB])
- LOG.md ([Y KB])

## Git (Repository Model)
- Repository: initialized (own repo)
- Initial commit: [hash]
- Remote: [none | URL if configured]

## Structure
[Directory tree if hierarchy created]

## Learnings Integration
- Workspace LEARNINGS.md: [path]
- Project references workspace learnings: yes

## Verification
- [x] Structure valid
- [x] Git repository initialized
- [x] Context budget: All leaf criteria ≤80KB
- [x] Criteria classified: [N leaf, M composite]
- [x] Depth: [N] / 3 max
- [x] Success criteria defined
- [x] Boundaries specified

## Next Steps
1. [First recommended action]
2. [Second recommended action]
```

## State Externalization (Automatic)

Context state is managed automatically by hooks — no manual file management needed.

**How it works:**
- When OBJECTIVE.md is read (step 5), the `PostToolUse` hook automatically captures project context
- State is stored at `.claude/sessions/<session_id>/context-state.json`
- Each Claude Code window has its own session ID, enabling parallel work without conflicts

**Session isolation:** Multiple Claude Code windows can work on different projects simultaneously. Each session's state is keyed by its unique session ID.

## Failure Protocol

If creation blocked:
1. Report what's blocking (permissions, existing files, unclear requirements)
2. Suggest resolution
3. Do not create partial/malformed project structure
