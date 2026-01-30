---
name: project-management
description: Detailed guidance for multi-session project management with OBJECTIVE.md and LOG.md
constitution: CLAUDE.md
alignment:
  - Memory System / Projects
  - Traceability System
  - Memory System / Learnings
  - Verification System
---

# Project Management Guide

This skill provides detailed protocols for managing multi-session projects using the two-file structure, aligned with the constitutional requirements of CLAUDE.md.

## Constitutional Authority

This skill derives from CLAUDE.md. Key alignments:
- **Memory System** — OBJECTIVE.md + LOG.md structure
- **Traceability System** — Three-layer stack (Git + LOG.md + OBJECTIVE.md)
- **Learnings** — Capture and propagation via LEARNINGS.md
- **Verification** — Tiered verification before checkpoints

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

Root-level (alongside CLAUDE.md):
```
LEARNINGS.md        # Global learnings repository
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
- **Learnings** — non-obvious insights (with propagation flag)
- **What's next** — immediate next steps

**Append-only.** Never edit previous entries.

### LEARNINGS.md

Global repository at project root. Contains:
- **Technical Patterns** — code patterns, library behaviors
- **Process Patterns** — workflow improvements
- **Failure Patterns** — what didn't work and why

Plan agents MUST read before recommending approaches.

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
3. Read LEARNINGS.md for applicable learnings
4. Run `git status` — understand working tree state
5. Confirm working level with user if hierarchy exists

### Ending a Session
1. Append to LOG.md:
```markdown
## Session [date/identifier]

### Accomplished
- [What was done]

### Decisions
- [Choice]: [Rationale]

### Learnings

#### [Title]
- **Type:** Technical | Process | Pattern | Failure
- **Context:** [When this applies]
- **Insight:** [The actual learning]
- **Evidence:** [file:line, measurement, observation]
- **Propagate:** Yes/No

### Next
- [Immediate next steps]
```

2. Propagate learnings marked `Propagate: Yes` to LEARNINGS.md
3. Commit if implementation is verified and complete

### Git Integration

**Commit when:**
- Implementation is verified and complete
- User explicitly requests
- Before attempting risky refactors

**Commit message format:**
```
[type]: [summary]

[Details if needed]

Session: [LOG.md session identifier]
Co-Authored-By: Claude <noreply@anthropic.com>
```

**NEVER commit:**
- Broken or unverified code
- "Progress" without working state

**For recovery:**
- `git stash` before attempting alternative approaches
- `git checkout .` to abandon failed attempts cleanly

---

## Traceability

### Three-Layer Stack

| Layer | Purpose | Granularity |
|-------|---------|-------------|
| Git | Code state checkpoints | Atomic, recoverable |
| LOG.md | Decision history + learnings | Session-level |
| OBJECTIVE.md | Contract for what we're building | Stable reference |

### Checkpoint Requirements

Every verified implementation creates a checkpoint:
1. **Git commit** — With session link in message
2. **LOG.md entry** — Documents what, why, learnings
3. **Verification record** — Per tier requirements

### Rollback Protocol

When rollback needed:
1. Identify target checkpoint (commit hash)
2. `git reset --hard [commit]` or `git revert`
3. Add LOG.md entry documenting rollback with rationale
4. Re-plan if significant

---

## Learnings Integration

### Capture

During implementation, note:
- Non-obvious behaviors discovered
- Patterns that worked well
- Approaches that failed
- Insights that would apply elsewhere

### LOG.md Format

```markdown
### Learnings

#### [Title]
- **Type:** Technical | Process | Pattern | Failure
- **Context:** [When this applies]
- **Insight:** [The actual learning]
- **Evidence:** [file:line, measurement, observation]
- **Propagate:** Yes/No
```

### Propagation

At session end:
1. Review learnings marked `Propagate: Yes`
2. Check LEARNINGS.md for duplicates
3. Add new learnings with source reference
4. Assign ID (LP-###, PP-###, or FP-###)

### LEARNINGS.md Structure

```markdown
## Technical Patterns
### [LP-001] Title
- **Source:** [project, session]
- **Context:** [When this applies]
- **Insight:** [The learning]
- **Applicability:** [Where to use it]

## Process Patterns
### [PP-001] Title
...

## Failure Patterns
### [FP-001] Title
- **Source:** [project, session]
- **Context:** [When this applies]
- **Insight:** [What failed and why]
- **Avoidance:** [How to prevent]
```

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
- **Propagate** learnings to root LEARNINGS.md

### Escalation Triggers

Escalate to user when:
- Work requires crossing sibling boundaries
- Undeclared dependencies discovered
- Scope needs to change
- Decision affects architecture
- 2 approaches have failed (per Failure Protocol)
- Learning suggests objective modification

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

## Verification Integration

### Before Checkpoint

Verify per tier:
- **Trivial:** `git diff` + inspection note
- **Standard:** Automated checks + criteria verification
- **Critical:** Full record + user review

### Verification Record in LOG.md

Include verification summary in session entry:
```markdown
### Verification
- Tier: Standard
- Build: `cargo check` -> pass
- Tests: `cargo test` -> 15/15 passed
- Criteria: [list with evidence]
- Scope: surgical (2 files, 45 lines)
```

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
3. Capture failure as learning in LOG.md
4. Escalate to user with options

### Termination
A project objective is complete when:
- All success criteria are verified
- `git diff` confirms only expected changes
- LOG.md documents the completion with learnings
- Commit created with proper message format
- Learnings propagated to LEARNINGS.md
- No open sub-objectives remain
