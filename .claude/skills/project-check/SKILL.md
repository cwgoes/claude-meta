---
name: project-check
description: Perform a comprehensive project consistency and completeness check
constitution: CLAUDE.md
alignment:
  - Memory System / Projects
  - Verification System
  - Traceability System
  - Memory System / Learnings
---

# /project-check

Comprehensive project consistency and completeness verification.

## Invocation

```
/project-check [project-name]
```

If no project name provided, checks the currently active project or prompts for selection.

## Verification Checklist

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
| **Constitutional** | Derived documents have proper headers |
| **Traceability** | Commits link to LOG sessions |
| **Learnings** | Propagation-worthy learnings captured |

## Protocol

1. **Explore** — Use explore agent to gather project structure
2. **Run `git status`** — Check for uncommitted work
3. **Check `git log`** — Verify commit message format
4. **Read LEARNINGS.md** — Check for propagated learnings
5. **Verify** — Check each item in the checklist
6. **Reflect** — Apply triple reflection on findings
7. **Report** — Present findings with specific issues and recommendations

## Output Format

```
## Project Health: [HEALTHY | ISSUES | CRITICAL]

## Git State
- Branch: [current branch]
- Status: [clean | uncommitted changes]
- Last commit: [hash and message]
- Commit format compliance: [Yes/No]

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
| Constitutional | Pass/Fail | [details] |
| Traceability | Pass/Fail | [details] |
| Learnings | Pass/Warning/N/A | [details] |

## Traceability Audit
- Commits with session links: [N/M]
- Orphan commits (no session link): [list if any]
- LOG sessions without commits: [list if any]

## Learnings Audit
- Learnings in LOG.md marked Propagate: Yes: [count]
- Learnings in LEARNINGS.md: [count]
- Unpropagated learnings: [list if any]

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

## Escalation Triggers

Escalate to user when:
- Context budget exceeded (requires decomposition)
- Depth limit exceeded (requires restructuring)
- Significant drift detected (requires objective reassessment)
- Circular dependencies found
- Uncommitted changes from unknown source
- Constitutional violations in derived documents
- Traceability broken (commits without session links)

## Related Skills

- `/project-start` — Orient on a project before checking
- `/project-create` — Create a new project with proper structure
- `/session-end` — End session with appropriate memory capture
