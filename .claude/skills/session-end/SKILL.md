---
name: session-end
description: End current session with appropriate memory capture for context continuity
constitution: CLAUDE.md
alignment:
  - Work Modes
  - Memory System / Session Protocol
  - Memory System / Repository Model
  - Traceability System
  - Memory System / Learnings
  - Context Persistence / State Externalization
---

# Session End Protocol

Ends the current session with appropriate memory capture. Designed for any exit scenario—clean completion, mid-work pause, or context reset.

## Constitutional Authority

This skill implements CLAUDE.md Session Protocol (End) with extensions for:
- Work mode awareness (Ad-hoc vs Project)
- Variable session types (project vs. ad-hoc)
- Urgency levels (quick reset vs. full capture)
- State preservation for seamless resumption

## Invocation

```
/session-end [mode]
```

Modes:
- **quick** — Minimal capture, fast context reset (default for Ad-hoc work)
- **full** — Complete memory capture with LOG.md, learnings, commit consideration
- **(no argument)** — Auto-detect based on work mode and session state

---

## Protocol by Mode

### Quick Mode

For context resets or sessions without significant work to preserve.

**Steps:**
1. Check for uncommitted changes (`git status` in project directory — each project is its own repo)
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

2. **Extract learning candidates** (ACTIVE — do not skip)

   Scan the session for learning candidates:

   | Signal | Learning Type |
   |--------|---------------|
   | Error encountered and resolved | Failure |
   | Non-obvious solution discovered | Technical |
   | Workflow improvement made | Process |
   | Pattern worth reusing | Pattern |

   **Apply capture criteria** (must meet ≥2):
   - Reusable: applies to ≥2 other tasks you can name
   - Non-documented: not obvious from official docs
   - Cost-saving: rediscovery would take >5 minutes
   - Failure-derived: learned from something that didn't work

   **Present candidates to user:**
   ```
   ## Learning Candidates Detected

   ### [Candidate 1]
   - **Type:** [Technical|Process|Pattern|Failure]
   - **Context:** [when this applies]
   - **Insight:** [the learning]
   - **Meets criteria:** [which 2+ criteria]
   - **Propagate to LEARNINGS.md?** [Y/n]
   ```

   If no candidates detected, state: "No learning candidates identified this session."

3. **Compose LOG.md entry**
   ```markdown
   ## Session [YYYY-MM-DD HH:MM] — [brief title]

   ### Accomplished
   - [What was done]

   ### Decisions
   - [Choice]: [Rationale]

   ### Learnings
   [From step 2 — include approved candidates]

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

4. **Propagate learnings** (if any marked `Propagate: Yes`)
   - Read LEARNINGS.md
   - Check for duplicates
   - Determine next ID (LP-NNN for Technical, PP-NNN for Process, FP-NNN for Failure)
   - Append new learnings with source reference:
     ```markdown
     ### [ID] [Title]
     - **Source:** [project, session date]
     - **Context:** [When this applies]
     - **Insight:** [The learning]
     - **Applicability:** [Where to use it]
     ```
   - Update Propagation Log table

5. **Update context-state.json**
   - Read current `<project-path>/context-state.json`
   - Update:
     - `timestamp`: current time
     - `status`: "completed" if success criteria met, else "paused"
   - Write updated file

6. **Commit decision**
   - If verified and complete → offer to commit with proper message format
   - If unverified or incomplete → do not commit, note in LOG.md

7. **Output session summary**

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

When invoked without mode argument, determine based on Work Mode:

```
Detect current Work Mode:
├── Ad-hoc (no OBJECTIVE.md) → Quick mode (but check for graduation triggers)
└── Project (own repo with OBJECTIVE.md) → Full mode

For Project mode, check significant work:
├── Significant work → Full mode
└── Minimal work → Ask user: "Minimal work detected. Quick or Full?"
```

**Work Mode detection:**
| Structure | Mode |
|-----------|------|
| No OBJECTIVE.md | Ad-hoc |
| Own git repo with OBJECTIVE.md | Project |

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
1. **Full checkpoint** — Commit + LOG.md entry (for significant work/decisions)
2. **Lightweight checkpoint** — Commit only, no LOG.md (for incremental progress)
3. **Stash** — Preserve for later (`git stash push -m "session-end [date]"`)
4. **Discard** — Abandon changes (`git checkout .`)
5. **Leave** — Keep dirty state, note in LOG.md for next session

Which option?
```

Per CLAUDE.md Checkpoint Model: use lightweight for incremental saves, full for session boundaries or decisions worth recording.

---

## Ad-hoc Work Mode Sessions

For ad-hoc work without OBJECTIVE.md/LOG.md (per Work Modes):

**Quick mode** (default for Ad-hoc):
- Output summary to terminal
- Warn about uncommitted changes
- No persistence

**Full mode** (if requested):
- Offer to create minimal session record in LEARNINGS.md (if learnings exist)
- Or suggest creating a project via `/project-create` if work should continue

**Graduation prompt:**
If significant work detected in Ad-hoc mode:
```
Significant work detected in Ad-hoc mode.
Recommend: /project-create <name> to preserve context for future sessions.
Continue with Quick mode? [Y/n]
```

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

### With State Externalization

Update each active project's `<project-path>/context-state.json` on session end:

**Full mode:**
1. Read current context-state.json
2. Update fields:
   ```json
   {
     "timestamp": "[ISO 8601 now]",
     "status": "completed" | "paused"
   }
   ```
   - Use "completed" if all success criteria in OBJECTIVE.md are met
   - Use "paused" otherwise
3. Write updated file

**Quick mode:**
1. If context-state.json exists, update:
   - `timestamp`: current time
   - `status`: "paused"
2. If missing, skip (quick mode doesn't create state)

**Multi-project sessions:** If multiple projects were active, update each project's context-state.json appropriately based on work done in that project.

**Verification:** After writing, the statusline should reflect the updated status on next refresh.

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
