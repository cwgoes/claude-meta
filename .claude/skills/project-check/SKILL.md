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

## Protocol

1. **Resolve project** — Find and validate project path
2. **Run `git status`** — Check for uncommitted work
3. **Check `git log`** — Audit commit message formats
4. **Read LEARNINGS.md** — Check for propagation gaps
5. **Verify each checklist item** — Systematic pass/fail/warning
6. **Analyze drift** — Compare OBJECTIVE.md vs LOG.md work
7. **Report findings** — Issues with severity and remediation

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
