---
name: session-end
description: End current session with appropriate memory capture for context continuity
constitution: CLAUDE.md
alignment:
  - Work Modes
  - Learnings
  - Checkpoint Model
  - Plans
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

   Scan the session for:
   - Things that failed or caused problems → **Avoid**
   - Things that worked well or solved problems → **Prefer**

   **Capture when:** Discovery cost >5 minutes AND applies to future work.

   **Present candidates to user:**
   ```
   ## Learning Candidates Detected

   - Avoid: [thing] — [why it failed] — [context]
   - Prefer: [thing] — [why it works] — [context]

   Propagate to LEARNINGS.md? [Y/n]
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
   - Avoid: [thing] — [why] — [context]
   - Prefer: [thing] — [why] — [context]

   ### State
   - Git: [clean | uncommitted changes in X files]
   - Verification: [status]

   ### Next
   - [What to do when resuming]
   ```

4. **Propagate learnings** (if user approved)
   - Read LEARNINGS.md
   - Check for duplicates
   - Append new learnings (format per CLAUDE.md):
     ```markdown
     Avoid: [thing] — [why it failed] — [context]
     Prefer: [thing] — [why it works] — [context]
     ```

5. **Commit decision**
   - If verified and complete → offer to commit with proper message format
   - If unverified or incomplete → do not commit, note in LOG.md

6. **Output session summary**

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
1. **Commit** — LOG.md entry + commit (entry can be brief for incremental progress)
2. **Stash** — Preserve for later (`git stash push -m "session-end [date]"`)
3. **Discard** — Abandon changes (`git checkout .`)
4. **Leave** — Keep dirty state, note in LOG.md for next session

Which option?
```

Per CLAUDE.md Checkpoint Model: always create LOG.md entry before committing. Entry can be brief for incremental progress.

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

Context state is managed automatically by hooks — no manual file management needed.

**How it works:**
- State is stored at `.claude/sessions/<session_id>/context-state.json`
- The `PostToolUse` hook captures state when OBJECTIVE.md is read
- The `PreCompact` hook saves state before context compression
- The `SessionStart` hook restores context after compression

**Session isolation:** Each Claude Code window has a unique session ID. Multiple windows can work on different projects without state conflicts.

**Statusline:** Automatically reflects the current session's project state.

### With Plan State

If an active plan exists, check consistency:

**1. Compare plan to session work:**
- Read active plan file
- Check if steps were completed based on LOG.md entries
- Prompt to update plan if work was done

**Output (if plan exists):**
```
## Plan State

Plan: plans/2026-02-03-cache.md
Status: active
Criteria: SC-1, SC-2

Session completed work on step 3.
Update plan to mark step complete? [Y/n]
```

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
