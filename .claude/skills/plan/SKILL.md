---
name: plan
description: Enter native plan mode with project context loading
constitution: CLAUDE.md
alignment:
  - Core Invariants / Plan Invariant
  - Plans
  - Learnings
---

# /plan

Enter native plan mode for the current project with context loading and criteria coverage awareness.

## The Plan Invariant

> For every objective criterion, its coverage is visible: unaddressed, active, or done.

## Invocation

```
/plan [description]
/plan --continue
```

- `[description]` — What to plan (optional, can elaborate in plan mode)
- `--continue` — Continue working on existing active plan

## Preconditions

**Must have active project.** If none:
```
Cannot enter plan mode: no active project.
Use /project-start <name> first.
```

## Protocol

### New Plan (`/plan [description]`)

1. **Verify project** — Check session state for active project
2. **Load context:**
   - Read OBJECTIVE.md → extract criteria (SC-N format)
   - Read LEARNINGS.md (workspace + project)
   - Scan `plans/` → understand current coverage
3. **Show coverage state:**
   ```
   ## Criteria Coverage

   | Criterion | Status | Plan |
   |-----------|--------|------|
   | SC-1 | ✓ done | 2026-02-03-cache.md |
   | SC-2 | → active | 2026-02-03-cache.md |
   | SC-3 | ○ unaddressed | — |

   **Unaddressed:** SC-3
   ```
4. **Enter plan mode:** Call `EnterPlanMode`
5. **Plan:** Explore codebase, evaluate approaches, produce plan
6. **Write plan file:** To `plans/<YYYY-MM-DD>-<slug>.md`
7. **Exit plan mode:** Call `ExitPlanMode` for user approval

### Continue Plan (`/plan --continue`)

1. **Find active plan:** Most recent plan with `status: active`
2. **If none:** Error — "No active plan. Use /plan to create one."
3. **Load plan context:** Read plan file, understand completed/pending steps
4. **Enter plan mode:** For continuation or revision

## Plan File Format

```yaml
---
criteria: [SC-1, SC-2]
status: active | done | dropped
---
# [Title]

## Approach
[What we're doing and why]

## Steps
- [ ] Step description
- [x] Completed step (evidence: commit hash)

## Verification
- [ ] SC-N: [How to verify]
```

## On User Approval

1. LOG.md entry:
   ```markdown
   ### Plan Created
   File: plans/2026-02-03-cache-layer.md
   Criteria: SC-1, SC-2
   ```

## On User Rejection

Plan file remains with `status: dropped` for audit trail.

## Output Format

After plan mode exits:

```markdown
## Plan Created

**File:** plans/2026-02-03-cache-layer.md
**Status:** active
**Criteria:** SC-1, SC-2

### Summary
[Brief description of approach]

### Steps
1. [Step]
2. [Step]

### Coverage After This Plan
| Criterion | Status |
|-----------|--------|
| SC-1 | → active |
| SC-2 | → active |
| SC-3 | ○ unaddressed |

### Next Action
Begin with step 1: [description]
```

## Coordination

Plans are documents. Git handles versioning and conflicts.

For parallel work on same project:
- Different criteria → different plans → no conflict
- Same criteria → coordinate or work sequentially
