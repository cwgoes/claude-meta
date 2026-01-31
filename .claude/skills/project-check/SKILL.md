---
name: project-check
description: Comprehensive project audit to detect and rectify inconsistencies
constitution: CLAUDE.md
alignment:
  - Work Modes
  - Memory System / Projects
  - Memory System / Repository Model
  - Verification System / Verification Depth
  - Traceability System
  - Memory System / Learnings
  - Context Persistence / Context Invariants
  - Context Persistence / State Externalization
---

# /project-check

Comprehensive audit to detect and rectify project inconsistencies. **Run when explicitly desired, not routinely.**

## Invocation

```
/project-check [project-name]
```

If no project name provided, checks the currently active project or prompts for selection.

## Purpose

Unlike `/project-start` (lightweight orientation), this skill performs deep verification:
- Structural integrity
- Constitutional compliance
- Traceability consistency
- Drift detection
- Learnings propagation

Use when:
- Resuming after extended break
- Before major milestones
- When something feels wrong
- Periodic health checks

## Verification Checklist

| Check | Description |
|-------|-------------|
| **Work Mode** | Confirmed Project mode (own repo, not workspace) |
| **Structure** | OBJECTIVE.md and LOG.md exist and are well-formed |
| **Repository Model** | Project is own git repo (one project = one repository) |
| **Context Budget** | Combined size ≤ 10% (~80KB), up to 20% for dense projects |
| **Depth** | Hierarchy ≤ 3 levels |
| **Objective Trace** | Every level connects to root |
| **Success Criteria** | Each objective has verifiable criteria |
| **Boundaries** | File/module boundaries are defined |
| **LOG Integrity** | Append-only structure maintained |
| **Submodules** | If any, pinned to commits (not branches) |
| **Drift** | Work in LOG aligns with OBJECTIVE |
| **Git State** | Working tree clean or changes accounted for |
| **Traceability** | Checkpoint model followed |
| **Learnings** | Propagation-worthy learnings captured |
| **Context State** | `<project>/context-state.json` exists and is current |
| **State Accuracy** | Context state matches OBJECTIVE.md content |
| **Verification Compliance** | Standard+ commits have verification records |
| **Plan Learnings** | Plan sessions reference LEARNINGS.md |
| **Autonomous Format** | AUTONOMOUS-LOG.md valid (if exists) |

## Protocol

1. **Resolve project** — Find and validate project path
2. **Run `git status`** — Check for uncommitted work
3. **Check `git log`** — Audit commit message formats and tier compliance
4. **Read LEARNINGS.md** — Check for propagation gaps
5. **Verify each checklist item** — Systematic pass/fail/warning
6. **Analyze drift** — Compare OBJECTIVE.md vs LOG.md work
7. **Audit verification compliance** — Check Standard+ commits have records
8. **Audit plan learnings** — Check plans reference LEARNINGS.md
9. **Audit autonomous format** — If AUTONOMOUS-LOG.md exists, validate
10. **Report findings** — Issues with severity and remediation

## Output Format

```
## Project Health: [HEALTHY | ISSUES | CRITICAL]

## Summary
[1-2 sentence overall assessment]

## Checklist

| Check | Status | Notes |
|-------|--------|-------|
| Work Mode | Pass/Fail | [own repo, not workspace] |
| Structure | Pass/Fail | [details] |
| Repository Model | Pass/Fail | [is own git repo?] |
| Context Budget | Pass/Warning/Fail | [X KB / 80KB] |
| Depth | Pass/Fail | [current depth] |
| Objective Trace | Pass/Fail | [details] |
| Success Criteria | Pass/Fail | [details] |
| Boundaries | Pass/Fail | [details] |
| LOG Integrity | Pass/Fail | [details] |
| Submodules | Pass/Fail/N/A | [pinned to commits?] |
| Drift | Pass/Warning/Fail | [details] |
| Git State | Pass/Warning | [details] |
| Traceability | Pass/Fail | [details] |
| Learnings | Pass/Warning/N/A | [details] |

## Traceability Audit
- Full checkpoints (with Session: link): [count]
- Lightweight checkpoints (no Session: link): [count]
- LOG sessions: [count]
- Unlinked LOG sessions: [list if any]

## Learnings Audit
- Learnings marked Propagate: Yes in LOG.md: [count]
- Learnings in LEARNINGS.md: [count]
- Unpropagated learnings: [list if any]

## Failure Learning Quality Audit
For Failure-type learnings (FP-NNN), verify quality criteria:

| Learning | Reasoning | Counterfactual | Generalized | Pattern Class |
|----------|-----------|----------------|-------------|---------------|
| [FP-NNN] | ✓/✗       | ✓/✗            | ✓/✗         | ✓/✗           |

- Failure learnings meeting all criteria: [N/M]
- Missing fields: [list specific gaps]
- Quality compliance: [%]
- Recommendation: [none | generalize before propagating | add missing fields]

## Drift Analysis
[Comparison of stated objectives vs. actual work logged]
- Objective focus: [what OBJECTIVE.md says]
- Actual work: [what LOG.md shows]
- Alignment: [aligned | minor drift | significant drift]

## Context State Audit
- context-state.json exists: [yes/no]
- Timestamp: [age since last update]
- Project matches: [yes/no]
- Objective matches OBJECTIVE.md: [yes/no]
- Status accurate: [yes/no]
- Recommendation: [none | update state | refresh context]

## Verification Compliance Audit

Audit whether verification protocols are being followed.

**Method:**
1. Get commits since last session: `git log --oneline --since="[last LOG.md session date]"`
2. For each commit, estimate tier from diff size
3. Check LOG.md for corresponding verification records

**Output:**
```
- Commits since last session: [N]
- Estimated Standard+ tier commits: [N]
- Commits with verification record in LOG.md: [N]
- Compliance rate: [N/M = %]
- Missing verification (Standard+ without record):
  - [commit hash]: [summary] — [estimated tier]
  - ...
```

**Interpretation:**
| Compliance | Status |
|------------|--------|
| 100% | Pass |
| 75-99% | Warning — minor gaps |
| <75% | Fail — systematic skip |

## Plan Agent Audit

Check whether Plan agents consulted LEARNINGS.md.

**Method:**
1. Search LOG.md for plan-related entries (approach selection, trade-off analysis)
2. Check if "Applicable Learnings" or LEARNINGS.md reference exists
3. Flag plans without learnings consultation

**Output:**
```
- Planning sessions in LOG.md: [N]
- Plans citing LEARNINGS.md: [N]
- Plans without learnings reference:
  - Session [date]: [plan topic]
  - ...
- Compliance rate: [%]
```

## Autonomous Audit

If AUTONOMOUS-LOG.md exists, validate format and completeness.

**Checks:**
| Check | Expected |
|-------|----------|
| File exists | If autonomous mode was used |
| Run header present | Configuration section with branch, budget, session ID |
| Checkpoints numbered | Sequential checkpoint-NNN |
| Checkpoint format valid | Context, Choice/Finding/Problem, Rationale, Confidence, Files, Tag |
| Termination recorded | Reason, Elapsed, Summary, Unresolved, For Review |
| Tags exist | `git tag` includes checkpoint-NNN for each logged checkpoint |

**Output:**
```
- AUTONOMOUS-LOG.md exists: [yes/no/N/A]
- Runs logged: [N]
- Last run: [date] — [status]
- Checkpoints: [N]
- Tags matching checkpoints: [N/M]
- Format valid: [yes/no]
- Issues:
  - [issue description]
```

## Issues
1. [Issue] — [severity: low/medium/high] — [remediation]
2. ...

## Recommendations
1. [Priority 1 action]
2. [Priority 2 action]
```

## Escalation Triggers

Escalate to user when:
- Work Mode violation (OBJECTIVE.md in workspace repo)
- Context budget exceeded (requires decomposition)
- Depth limit exceeded (requires restructuring)
- Significant drift detected (requires objective reassessment)
- Circular dependencies found
- Constitutional violations in derived documents

## Remediation

For common issues, offer to fix:
- **Unpropagated learnings** → Offer to propagate to LEARNINGS.md
- **Missing boundaries** → Suggest boundary definitions
- **LOG integrity** → Identify malformed entries
- **Checkpoint gaps** → Note commits needing session links

Do not auto-fix without user consent.
