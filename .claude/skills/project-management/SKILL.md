---
name: project-management
description: Detailed guidance for multi-session project management with OBJECTIVE.md and LOG.md
---

# Project Management Guide

This skill provides detailed protocols for managing multi-session projects using the two-file structure.

## When to Use Projects

**Use projects when:**
- Work spans multiple sessions
- Multiple agents work in parallel
- Objective requires decomposition

**Skip projects when:**
- Task completes in one session
- Scope is clear and bounded

For simple tasks: just do them. Don't pay overhead when memory isn't needed.

---

## File Structure

```
project-name/
├── OBJECTIVE.md    # What we're building (immutable)
└── LOG.md          # Append-only session log
```

### OBJECTIVE.md

The contract. Contains:
- **Objective hierarchy** — decomposed if complex
- **Success criteria** — verifiable conditions for "done"
- **Boundaries** — files/modules per sub-objective
- **Dependencies** — sequencing requirements

**Immutable without user consent.** Changes require explicit approval.

### LOG.md

The history. Each session appends:
- **Summary** — what was accomplished
- **Decisions** — choices made and why (enough to not revisit)
- **What's next** — immediate next steps

**Append-only.** Never edit previous entries.

---

## Constraints

### Context Budget
OBJECTIVE.md + LOG.md ≤ 10% of context (~50-80KB)

*Why:* Agent needs 90% for actual work. If exceeded, decompose into subprojects.

### Depth Limit
Maximum 3 levels.

*Why:* Verification requires checking all levels. Deeper hierarchies become intractable.

---

## Session Protocol

### Starting a Session
1. Read OBJECTIVE.md in full
2. Read LOG.md in full
3. Run `git status` — understand working tree state
4. Confirm working level with user if hierarchy exists

### Ending a Session
1. Append to LOG.md:
```markdown
## Session [date/identifier]

### Accomplished
- [What was done]

### Decisions
- [Choice]: [Rationale]

### Next
- [Immediate next steps]
```

2. Commit if implementation is verified and complete

### Git Integration

**Commit when:**
- Implementation is verified and complete
- User explicitly requests
- Before attempting risky refactors

**NEVER commit:**
- Broken or unverified code
- "Progress" without working state

**For recovery:**
- `git stash` before attempting alternative approaches
- `git checkout .` to abandon failed attempts cleanly

---

## Subprojects

When context budget exceeded or sub-objective warrants independent tracking:

```
parent/
├── OBJECTIVE.md      (references subproject, doesn't inline)
├── LOG.md
└── subprojects/
    └── X/
        ├── OBJECTIVE.md
        └── LOG.md
```

Parent contains references and interface specs. Each subproject is independently assignable.

---

## Scope Rules

At any level:
- **Read/write** within declared boundaries
- **Read only** subproject interfaces (delegate internals to sub-agents)
- **Read only** parent levels (modifications require user consent)
- **Append** to LOG.md on session completion

### Escalation Triggers

Escalate to user when:
- Work requires crossing sibling boundaries
- Undeclared dependencies discovered
- Scope needs to change
- Decision affects architecture
- 2 approaches have failed (per Failure Protocol)

---

## Objective Trace

Always maintain awareness of the lineage:

```
Root objective
  └── Parent objective
        └── Current objective ← you are here
```

Every action should serve this trace. If work doesn't connect, you may be drifting.

---

## Integration with Cognitive Architecture

### Parallel Implementation
When spawning parallel implement agents for a project:
1. Plan agent defines file boundaries per sub-task
2. Each implement agent receives its boundary in the specification
3. If boundaries unclear, use feature branches
4. Verify agent checks for conflicts after completion

### Failure Protocol
If stuck on a project objective:
1. Stop after 2 failed approaches
2. `git stash` or `git checkout .` to restore clean state
3. Log the failure in LOG.md with diagnosis
4. Escalate to user with options

### Termination
A project objective is complete when:
- All success criteria are verified
- `git diff` confirms only expected changes
- LOG.md documents the completion
- Commit created (if appropriate)
- No open sub-objectives remain
