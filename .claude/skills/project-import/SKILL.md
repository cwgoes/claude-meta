---
name: project-import
description: Import an existing codebase into the project management framework by inferring objectives and creating standard structure
constitution: CLAUDE.md
alignment:
  - Work Modes
  - Project Hierarchy
  - Core Invariants
  - Checkpoint Model
---

# /project-import

Import an existing codebase into the project management framework by analyzing it and creating the standard project structure (OBJECTIVE.md, LOG.md).

## Invocation

```
/project-import <source-path> [--name <project-name>]
/project-import <source-path> --name <name> --copy    # Copy instead of move
/project-import <source-path> --name <name> --link    # Symlink instead of move
```

- `<source-path>` — Path to existing project (absolute or relative to workspace)
- `--name <name>` — Project name (defaults to directory name)
- `--copy` — Copy source to projects/ (preserves original)
- `--link` — Symlink source into projects/ (keeps original location)
- Default: Move source into projects/

## When to Use

Use `/project-import` when:
- You have an existing codebase that should be tracked as a project
- The codebase has no OBJECTIVE.md or LOG.md
- You want Claude to help infer the project's purpose from its code

Use `/project-create` instead when:
- Starting a completely new project from scratch
- You already know the full objective and success criteria

## Protocol

### Phase 1: Discovery

1. **Validate source path** — Ensure it exists and is a directory
2. **Check for existing project structure** — If OBJECTIVE.md exists, abort with suggestion to use `/project-start`
3. **Read project documentation** (if exists):
   - README.md, README.rst, README.txt, README
   - docs/, doc/, documentation/
   - CONTRIBUTING.md, ARCHITECTURE.md
4. **Analyze project structure**:
   - List top-level directories and files
   - Identify language/framework (package.json, Cargo.toml, pyproject.toml, go.mod, etc.)
   - Count source files, tests, etc.
5. **Read configuration files** to understand:
   - Dependencies (package.json, Cargo.toml, requirements.txt, etc.)
   - Build configuration
   - Test configuration
6. **Sample source files** — Read 3-5 key files to understand purpose
7. **Check git status**:
   - Is it a git repo? What branch?
   - Any remotes configured?
   - Clean or dirty working tree?

### Phase 2: Inference

Based on discovery, infer:

| Element | Source Signals |
|---------|----------------|
| **Objective** | README description, package description, main entry point |
| **Success Criteria** | Tests (what they verify), build targets, CI configuration |
| **Technology Stack** | Config files, dependencies, file extensions |
| **Boundaries** | Directory structure, module organization |
| **Current State** | Git history, test coverage, documentation completeness |

### Phase 3: Clarification

Present findings and ask user to clarify or confirm:

```
## Inferred Project Summary

**Name:** [detected or suggested]
**Path:** [source path] → projects/[name]/

**Technology Stack:**
- Language: [detected]
- Framework: [detected]
- Build tool: [detected]

**Inferred Objective:**
[Best guess from README/code analysis]

**Inferred Success Criteria:**
Based on existing tests and structure:
- [ ] SC-1: [inferred criterion]
- [ ] SC-2: [inferred criterion]

**Questions:**

1. **Objective accuracy** — Is the inferred objective correct?
   - [ ] Yes, proceed
   - [ ] Modify: [textarea]

2. **Success criteria** — What makes this project "done"?
   - [ ] Inferred criteria are correct
   - [ ] Add/modify: [textarea]

3. **Current state** — What's the completion status?
   - [ ] Fresh start (0% complete)
   - [ ] Partially complete: [describe]
   - [ ] Feature-complete, needs polish
   - [ ] Other: [describe]

4. **Import method:**
   - [ ] Move into projects/ (default)
   - [ ] Copy (preserve original)
   - [ ] Symlink (keep original location)
```

Use `AskUserQuestion` for critical ambiguities. If confident (>80%) in inferences, present them as defaults that user can accept or modify.

### Phase 4: Structure Creation

1. **Determine target path** — `projects/<name>/`
2. **Handle existing git**:
   - If source is a git repo: preserve it (move/copy/link includes .git)
   - If not a git repo: `git init` after import
3. **Import files**:
   - Move: `mv <source> projects/<name>/`
   - Copy: `cp -r <source> projects/<name>/`
   - Link: `ln -s <absolute-source> projects/<name>`
4. **Write OBJECTIVE.md** — Using confirmed/modified inferences (triggers automatic state capture)
5. **Write LOG.md** — With import session entry
6. **Create/update .gitignore** — Add standard ignores if missing
7. **Create initial commit** — If git was initialized (not for existing repos with history)

### Phase 5: Verification

Verify the imported project meets framework requirements:

- [ ] Directory exists at `projects/<name>/`
- [ ] OBJECTIVE.md present with success criteria
- [ ] LOG.md present with import session
- [ ] Git repository (existing or new)
- [ ] Context budget: OBJECTIVE.md + LOG.md < 80KB
- [ ] No conflicting project at target path

## OBJECTIVE.md Template (Import)

```markdown
---
constitution: ../CLAUDE.md
alignment:
  - verification/standard-tier
  - traceability/checkpoint-model
  - memory/projects
imported_from: [original path]
import_date: [YYYY-MM-DD]
---

# [Project Name]

## Objective

[Inferred/confirmed objective statement]

## Success Criteria

### SC-1: [Inferred/confirmed criterion - leaf]
**Status:** [Pending/In Progress/Done]
**Files:**
- `[path]` — [role/purpose]
**Verification:** [command or manual check]

### SC-2: [Inferred/confirmed criterion - leaf]
**Status:** [status]
**Files:**
- `[path]` — [role/purpose]
**Verification:** [command or manual check]

### SC-3: [Inferred/confirmed criterion - composite if files >80KB]
**Status:** [status]
**Subproject:** `[path/to/subproject]/`
**Interface:**
- **Inputs:** [what parent provides]
- **Outputs:** [what subproject delivers]

## Infrastructure
*Files supporting multiple criteria or project-wide concerns.*
- `[path]` — [purpose]

## Technology Stack

- **Language:** [detected]
- **Framework:** [detected]
- **Build:** [detected]
- **Tests:** [detected]

## Current State

Imported on [date] from `[original path]`.

**Pre-import status:**
- [summary of what existed before import]

**Known issues:**
- [any detected issues or TODOs]

## Dependencies

[From package.json/Cargo.toml/etc.]

## Key Resources

- [README.md if exists]
- [other docs]
```

## LOG.md Template (Import)

```markdown
# [Project Name] Development Log

Decision history and session summaries.

---

## Session [YYYY-MM-DD] — Project Import

### Context

Imported existing codebase from `[original path]` into project management framework.

### Pre-Import State

| Aspect | State |
|--------|-------|
| Git | [existing repo / no repo] |
| Tests | [X passing / N total] |
| Documentation | [present / sparse / missing] |
| Build | [working / broken / unknown] |

### Discovery Summary

[Key findings from analyzing the codebase]

### Inferences Made

| Element | Inference | Confidence | User Confirmed |
|---------|-----------|------------|----------------|
| Objective | [what] | [High/Medium/Low] | [Yes/Modified] |
| Success criteria | [what] | [confidence] | [confirmation] |

### Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Import method | [move/copy/link] | [why] |
| Project name | [name] | [why if not default] |

### Learnings

[Any non-obvious insights discovered during import analysis]

### State

- Git: [clean | existing history preserved]
- Verification: Import complete

### Next

1. [First recommended action based on project state]
2. [Second action]
```

## Output Format

```
## Imported: [project-name]

**Source:** [original path]
**Target:** projects/[name]/
**Method:** [moved | copied | linked]

## Discovery Summary

| Aspect | Finding |
|--------|---------|
| Language | [detected] |
| Framework | [detected] |
| Size | [X files, Y KB] |
| Tests | [X files, Y tests] |
| Documentation | [present/sparse/missing] |

## Inferences

| Element | Value | Confidence |
|---------|-------|------------|
| Objective | [1-line summary] | [High/Medium/Low] |
| Success criteria | [count] defined | [confidence] |
| Current state | [estimate]% complete | [confidence] |

## Files Created

- OBJECTIVE.md ([X KB])
- LOG.md ([Y KB])

## Git Status

- Repository: [preserved existing | initialized new]
- Branch: [branch name]
- Commit: [hash if new commit made]
- Remote: [URL | none]

## Verification

- [x] Directory structure valid
- [x] OBJECTIVE.md with success criteria
- [x] LOG.md with import session
- [x] Git repository present
- [x] Context budget: All leaf criteria ≤80KB
- [x] Criteria classified: [N leaf, M composite]

## Recommendations

1. Review OBJECTIVE.md and refine success criteria
2. [Project-specific recommendation based on state]
3. Run `/project-start [name]` to begin working

## Next Steps

Use `/project-start [name]` to orient and begin work.
```

## Failure Protocol

**Source not found:**
1. Report the path that was tried
2. Suggest checking the path or using tab completion

**Already a managed project:**
1. If OBJECTIVE.md exists, report "Already a managed project"
2. Suggest `/project-start <name>` instead
3. If user wants to re-import, suggest moving/renaming existing files first

**Target path conflict:**
1. If `projects/<name>/` already exists, report conflict
2. Suggest alternative name or confirm overwrite

**Cannot infer objective:**
1. If insufficient information to infer purpose, report what was found
2. Ask user to describe the project's purpose directly
3. Fall back to minimal OBJECTIVE.md with user-provided info

**Git issues:**
1. If source has uncommitted changes, warn user
2. Suggest committing or stashing before import
3. Proceed only with user confirmation

## Clarification Strategy

**Ask explicitly when:**
- Objective cannot be inferred with >50% confidence
- Multiple conflicting signals about purpose
- Critical files (README, main entry) are missing
- Success criteria cannot be derived from tests/docs

**Use defaults when:**
- README clearly describes purpose
- Tests define clear acceptance criteria
- Standard project structure (well-known framework)
- Single obvious purpose from code analysis

**Confidence scoring:**

| Signal | Confidence Boost |
|--------|-----------------|
| Clear README with description | +30% |
| Package description field | +20% |
| Comprehensive test suite | +25% |
| CI configuration | +15% |
| Architecture/design docs | +20% |
| Single clear main entry point | +15% |
| Standard framework structure | +15% |

If total confidence < 50%, trigger explicit clarification phase.
