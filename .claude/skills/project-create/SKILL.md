---
name: project-create
description: Start a new project - creates directory, defines objectives, and sets up full project structure
constitution: CLAUDE.md
alignment:
  - Memory System / Projects
  - Traceability System
---

# /project-create

Initialize a new project with proper structure.

## Invocation

```
/project-create <project-name>
/project-create              # Will prompt for name
```

## Prerequisites

Before creating, clarify with user:
1. **Objective** — What are we building?
2. **Success criteria** — How do we know it's done?
3. **Scope** — What's in/out of scope?
4. **Location** — Where should the project live?

## Protocol

1. **Gather requirements** — Use AskUserQuestion if unclear
2. **Plan structure** — Determine if hierarchy needed, estimate size
3. **Create directory** — At `projects/<name>/` (default) or specified location
4. **Initialize git** — If not already in a repo
5. **Write OBJECTIVE.md** — With success criteria and boundaries
6. **Write LOG.md** — With initial session entry
7. **Verify** — Check structure meets constraints
8. **Note LEARNINGS.md** — Reference root-level learnings repository

## OBJECTIVE.md Template

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

## Git
- Repository: [initialized | already exists]
- Initial commit: [yes | no]

## Structure
[Directory tree if hierarchy created]

## Learnings Integration
- Root LEARNINGS.md: [path]
- Project references global learnings: [yes/no]

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

## Failure Protocol

If creation blocked:
1. Report what's blocking (permissions, existing files, unclear requirements)
2. Suggest resolution
3. Do not create partial/malformed project structure
