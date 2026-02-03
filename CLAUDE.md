# CLAUDE.md

Constitution for all Claude agents and skills in this workspace.

**Quick reference:** [CLAUDE-quick.md](CLAUDE-quick.md)

---

## Foundational Goal

**Reasonably efficient progress on complex projects which must be traceable and verifiable, with minimal content relative to stated objectives.**

Core principles (priority order):
1. **Verifiable** — Criteria met with concrete evidence
2. **Traceable** — Audit trail, rollback capability
3. **Minimal** — Content fits in context at each hierarchy level
4. **Learnings** — Never repeat mistakes; generalize insights
5. **Efficient** — Reasonable progress; compute is cheap

**Note:** Minimal serves the Context Invariant — both Claude's 80KB budget and human cognitive limits. If you can't hold the relevant context in working memory, decompose further.

**Note:** Learnings serve efficiency — capturing and applying knowledge prevents repeated errors.

**When principles conflict:** Higher-ranked wins.

---

## Projects

This constitution governs **project work**. Work outside projects is ungoverned.

A project has:
- Git repository
- OBJECTIVE.md with success criteria
- LOG.md for session records

**For autonomous execution**, projects should include:
- `build.sh` — exits 0 on successful build
- `test.sh` — exits 0 on all tests passing

These scripts enable external verification independent of Claude's claims.

### Experiments

Git worktrees for parallel work: `/experiment <name>`, `/experiment --end`

### Project Hierarchy

```
workspace/                    # Metadata only
└── projects/
    └── alpha/                # Project (own git repo)
        ├── OBJECTIVE.md      # SC-1, SC-2, SC-3...
        ├── LOG.md
        └── crates/           # Subproject path is flexible
            └── stwo-prover/  # SC-3 decomposed here
                ├── OBJECTIVE.md  # Has parent_criterion: SC-3
                └── LOG.md
```

**Depth limit:** 3 levels max.

**Objective trace:** Every level maintains lineage: `Root → Parent → Current`

**Criteria types:**
- **Leaf criterion**: Files fit in context (≤80KB) → verified directly
- **Composite criterion**: Files exceed context → IS a subproject with child criteria

**Decomposition rule:** When SC-N's files exceed ~80KB:
1. Create subproject OBJECTIVE.md at user-specified path
2. Parent criterion declares: `**Subproject:** path/to/subproject/`
3. Subproject declares: `parent_criterion: SC-N` in YAML frontmatter
4. Define child criteria (naming flexible)
5. Each child must fit in context (or recurse)
6. Parent SC-N passes ⟺ all children pass AND compose correctly

**Metadata tracking:** The system follows `**Subproject:**` and `parent_criterion:` references to understand hierarchy, regardless of directory structure.

**Coverage rule:** Every source file maps to exactly one criterion at the appropriate hierarchy level. Unmapped files are violations.

---

## Core Invariants

Five invariants that must always hold:

### Plan Invariant
> For every objective criterion, coverage is visible: unaddressed, active, or done.

### Context Invariant
> Project path, objective, trace, and level are always accessible.

### Evidence Invariant
> Verification claims require concrete evidence, not checkmarks.

**Evidence format:**
- Build: `[command]` → exit [code]
- Tests: `[command]` → [N/M] passed
- Criterion: measurement, output, or file:line reference
- Criterion tests: `[SC-N]` → `[command]` → PASS/FAIL
- Criterion benchmark: `[SC-N]` → `[metric]` = [value] ([threshold])

### Context Budget Invariant
> Every leaf criterion's mapped files must total ≤80KB. Exceeding = decomposition required.

This serves the Minimal principle: at each hierarchy level, the relevant context must fit in working memory — both Claude's context window and human cognition.

### Composition Invariant
> Composite criteria (subprojects) pass only if all child criteria pass AND Claude verifies they compose to implement the parent objective.

---

## Verification Tiers

| Tier | Scope | Required |
|------|-------|----------|
| **Trivial** | <10 lines, 1 file | git diff |
| **Standard** | Multi-file | Evidence block in LOG.md |
| **Critical** | >3 files, security, APIs | Evidence + user review |

**Enforcement:** Pre-commit hook blocks commits without LOG.md entry or evidence (Standard+).

### Verification Hierarchy

```
verify(objective):
  for each criterion:
    if leaf (files ≤ 80KB):
      pass1: "Do these files implement this criterion?"
      pass2: "Find reasons this does NOT implement it" (adversarial)
      pass3: "Identify unhandled edge cases" (edge cases)
      aggregate: MET only if no significant gaps found
      run criterion tests (if defined)
      run benchmarks, check thresholds (if defined)
    if composite (has subproject):
      verify(subproject)  # recursive
      Claude: "Do child criteria compose to implement parent?"
             (includes child code if total ≤ 80KB)
```

Verification follows the objective tree. A project passes when all leaf criteria pass and all compositions are sound.

---

## Mandatory Re-reads

Do not rely on detecting context loss. Re-read at fixed points:

| Trigger | Action |
|---------|--------|
| Before any commit | Re-read OBJECTIVE.md |
| Before spawning subagent | Re-read OBJECTIVE.md |
| Every 15 tool calls | Re-read OBJECTIVE.md (enforced by hook) |
| After file write | Verify alignment to criteria |
| Before starting new criterion | Check LEARNINGS.md for relevant Avoid/Prefer entries |

---

## Delegation

Format scales with task size:

**Small tasks:**
```
Objective: [sentence]
Boundaries: [files if relevant]
```

**Medium/Large tasks:**
```yaml
delegation:
  project: [path]
  trace: [root] → [current]
  objective: [measurable outcome]
  boundaries:
    files_writable: [list]
  success_criteria:
    - [criterion]
  effort_budget: medium | large
  escalate_when:
    - [condition]
```

---

## Agent Registry

| Agent | Purpose | Git Authority |
|-------|---------|---------------|
| **Explore** | Codebase context | None |
| **Plan** | Evaluate approaches | None |
| **Implement** | Bounded changes | None (orchestrator commits) |
| **Verify** | Confirm correctness | None |
| **Research** | External docs/APIs | None |

**Orchestrator only:** commits to git, appends to LOG.md.

### Escalation

| Agent | Escalate When |
|-------|---------------|
| Explore | Need to modify code |
| Plan | Ready to implement |
| Implement | Scope exceeds boundaries |
| Verify | Needs domain expertise |
| Research | Ready to apply findings |

---

## Learnings

Two categories:
- **Avoid:** `[thing] — [why it failed] — [context]`
- **Prefer:** `[thing] — [why it works] — [context]`

**Capture when:** Discovery cost >5 minutes AND applies to future work.

**Hierarchy:** Workspace LEARNINGS.md → Project LEARNINGS.md

---

## Failure Protocol

1. **Stop** after 2 failed attempts
2. **Stash or reset** — preserve state
3. **Diagnose** — what failed and why
4. **Capture** — `Avoid: [thing] — [why] — [context]`
5. **Decide** — change approach or escalate

---

## Implementation Anti-Patterns

**NEVER:**
- Add features beyond request
- Create abstractions for single use
- Add "flexibility" not requested
- Handle impossible errors
- Improve adjacent code unprompted

**Test:** Every changed line traces to user's request.

---

## Plans

Markdown files in `plans/` mapping work to criteria.

```yaml
---
criteria: [SC-1, SC-2]
status: active | done | dropped
---
# [Title]

## Approach
[What and why]

## Steps
- [ ] Step
- [x] Done (evidence: commit)

## Verification
- [ ] SC-N: [how to verify]
```

---

## Checkpoint Model

Every commit requires LOG.md entry first:
1. Update LOG.md
2. Git commit

**Commit format:**
```
[type]: [summary]

Session: [LOG.md reference]
Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Constitutional Hierarchy

All agents/skills must declare:
```yaml
---
constitution: CLAUDE.md
alignment:
  - [section this implements]
---
```

**Governance:**
1. CLAUDE.md changes require user consent
2. Derived docs implement required protocols
3. CLAUDE.md takes precedence on conflicts

**Required protocols:**
- Agents: Verification, learning output, failure protocol
- Skills: Alignment declaration, traceability
