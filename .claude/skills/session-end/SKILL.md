---
name: session-end
description: End current session with appropriate memory capture for context continuity
constitution: CLAUDE.md
alignment:
  - Memory System / Session Protocol
  - Traceability System
  - Memory System / Learnings
---

# Session End Protocol

Ends the current session with appropriate memory capture. Designed for any exit scenario—clean completion, mid-work pause, or context reset.

## Constitutional Authority

This skill implements CLAUDE.md Session Protocol (End) with extensions for:
- Variable session types (project vs. ad-hoc)
- Urgency levels (quick reset vs. full capture)
- State preservation for seamless resumption

## Invocation

```
/session-end [mode]
```

Modes:
- **quick** — Minimal capture, fast context reset (default if no project)
- **full** — Complete memory capture with LOG.md, learnings, commit consideration
- **(no argument)** — Auto-detect based on session state

---

## Protocol by Mode

### Quick Mode

For context resets or sessions without significant work to preserve.

**Steps:**
1. Check for uncommitted changes (`git status`)
2. If dirty state exists, warn user and offer options
3. Output brief session summary to terminal (not persisted)
4. Done

**Output:**
```
## Session Summary (Quick)
- Duration: [approximate]
- Changes: [committed/uncommitted/none]
- Warning: [if dirty state]

Ready for context reset.
```

### Full Mode

For multi-session projects or significant work worth preserving.

**Steps:**
1. **Gather state**
   - `git status` — uncommitted changes
   - `git diff --stat` — scope of changes
   - Review work done this session

2. **Compose LOG.md entry**
   ```markdown
   ## Session [YYYY-MM-DD HH:MM] — [brief title]

   ### Accomplished
   - [What was done]

   ### Decisions
   - [Choice]: [Rationale]

   ### Learnings
   [If any discovered]

   #### [Title]
   - **Type:** Technical | Process | Pattern | Failure
   - **Context:** [When this applies]
   - **Insight:** [The actual learning]
   - **Evidence:** [file:line, measurement, observation]
   - **Propagate:** Yes/No

   ### State
   - Git: [clean | uncommitted changes in X files]
   - Verification: [status]

   ### Next
   - [What to do when resuming]
   ```

3. **Propagate learnings** (if any marked `Propagate: Yes`)
   - Read LEARNINGS.md
   - Check for duplicates
   - Append new learnings with source reference

4. **Commit decision**
   - If verified and complete → offer to commit with proper message format
   - If unverified or incomplete → do not commit, note in LOG.md

5. **Output session summary**

**Output:**
```
## Session Summary (Full)

### Accomplished
[List]

### Memory Captured
- LOG.md: [appended/created/skipped]
- LEARNINGS.md: [N learnings propagated/none]
- Commit: [created with hash/skipped - reason]

### Resume Instructions
[Specific next steps for whoever picks this up]

### Warnings
[Any dirty state, incomplete work, or blockers]
```

---

## Auto-Detection Logic

When invoked without mode argument:

```
Has active project (OBJECTIVE.md exists)?
├── Yes → Has significant work this session?
│   ├── Yes → Full mode
│   └── No → Ask user: "Minimal work detected. Quick or Full?"
└── No → Quick mode
```

"Significant work" indicators:
- Files modified (per `git status`)
- Tools used beyond exploration (Edit, Write, Bash with side effects)
- Decisions made that should be recorded

---

## Dirty State Handling

If uncommitted changes exist:

```
## Uncommitted Changes Detected

Files modified:
- [list]

Options:
1. **Commit** — Create checkpoint (requires verification)
2. **Stash** — Preserve for later (`git stash push -m "session-end [date]"`)
3. **Discard** — Abandon changes (`git checkout .`)
4. **Leave** — Keep dirty state, note in LOG.md for next session

Which option?
```

---

## No-Project Sessions

For ad-hoc work without OBJECTIVE.md/LOG.md:

**Quick mode** (default):
- Output summary to terminal
- Warn about uncommitted changes
- No persistence

**Full mode** (if requested):
- Offer to create minimal session record in LEARNINGS.md (if learnings exist)
- Or suggest creating a project if work should continue

---

## Integration

### With Hooks

If `SessionEnd` hook exists, it runs after this protocol completes.

### With Subagents

Subagents do NOT run session-end. Only orchestrator manages session memory.

### With Verification

If work was done but not verified:
- Full mode warns about unverified state
- Does not create commit
- Notes verification gap in LOG.md

---

## Examples

### Quick Context Reset
```
User: /session-end quick

Claude: ## Session Summary (Quick)
- Changes: none
- Ready for context reset.
```

### Full Mode with Learnings
```
User: /session-end full

Claude: ## Session Summary (Full)

### Accomplished
- Implemented constitutional CLAUDE.md revision
- Created LEARNINGS.md repository
- Updated all agents with constitutional headers

### Memory Captured
- LOG.md: Appended session entry
- LEARNINGS.md: 1 learning propagated (LP-001)
- Commit: Created (abc123f)

### Resume Instructions
- Run /project-start to orient
- Next task: Test session protocol on sample task

### Warnings
None
```

### Mid-Work Pause
```
User: /session-end

Claude: Uncommitted changes detected (3 files modified).
Work appears incomplete—verification not run.

Options:
1. Stash and record state in LOG.md (recommended)
2. Quick exit without persistence
3. Continue working

Which option?
```
