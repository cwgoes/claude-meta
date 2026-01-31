---
name: autonomous-review
description: Review autonomous execution results and take action (approve, rollback, direct)
constitution: CLAUDE.md
alignment:
  - Autonomous Execution / Review Protocol
  - Traceability System
---

# Autonomous Review Skill

Reviews autonomous execution results and offers actions: approve, rollback, direct, or discard.

## Invocation

```
/autonomous-review <project> [--checkpoint <N>]
```

**Arguments:**
- `project`: Project name to review
- `--checkpoint`: Focus on specific checkpoint (optional)

## Protocol

### 1. Gather State

```bash
# Find autonomous branch
git -C projects/<project> branch -a | grep "auto/<project>"

# Read execution log
cat projects/<project>/AUTONOMOUS-LOG.md

# Get checkpoint list
git -C projects/<project> tag | grep "checkpoint-"

# Check current status
git -C projects/<project> log auto/<project>-* --oneline -10
```

### 2. Present Summary

```markdown
## Autonomous Execution Review: <project>

### Run Summary
- **Started:** [timestamp]
- **Elapsed:** [duration]
- **Status:** [Completed | Terminated | In Progress]
- **Branch:** `auto/<project>-<timestamp>`

### Checkpoints

| # | Time | Type | Summary |
|---|------|------|---------|
| 001 | HH:MM | Decision | [summary] |
| 002 | HH:MM | Discovery | [summary] |
| 003 | HH:MM | Milestone | [summary] |

### Termination
- **Reason:** [reason]
- **Unresolved:** [items]

### For Review
[Items flagged for human attention]

### Learnings Captured
[Learnings to propagate]
```

### 3. Offer Actions

```markdown
## Actions

1. **Approve** — Merge branch to main, propagate learnings
2. **Rollback** — Reset to specific checkpoint
3. **Direct** — Write DIRECTION.md, resume execution
4. **Discard** — Delete branch entirely

Which action? [1/2/3/4]
```

### Action: Approve

1. **Verify final state:**
   ```bash
   git -C projects/<project> diff main...auto/<project>-<timestamp> --stat
   ```

2. **Merge branch:**
   ```bash
   git -C projects/<project> checkout main
   git -C projects/<project> merge auto/<project>-<timestamp> --no-ff \
     -m "Merge autonomous run: <summary>"
   ```

3. **Propagate learnings:**
   - Extract learnings from AUTONOMOUS-LOG.md
   - Deduplicate against LEARNINGS.md
   - Append new learnings with source reference
   - For Failure-type learnings, ensure extended format:
     - Reasoning Error, Counterfactual, Generalized Lesson, Pattern Class
     - If missing, prompt for generalization before propagating

4. **Clean up:**
   ```bash
   git -C projects/<project> branch -d auto/<project>-<timestamp>
   git -C projects/<project> push origin --delete auto/<project>-<timestamp>
   # Optionally delete checkpoint tags
   ```

5. **Report:**
   ```markdown
   ## Approved and Merged

   - Commit: [hash]
   - Learnings propagated: [N]
   - Branch cleaned up: yes
   ```

### Action: Rollback

1. **Confirm checkpoint:**
   ```
   Rollback to checkpoint-NNN?

   Changes after this checkpoint will be discarded:
   - [list of commits]

   Confirm? [y/n]
   ```

2. **Execute rollback:**
   ```bash
   git -C projects/<project> checkout auto/<project>-<timestamp>
   git -C projects/<project> reset --hard checkpoint-NNN
   ```

3. **Report:**
   ```markdown
   ## Rolled Back to checkpoint-NNN

   Branch now at: [commit hash]
   Discarded: [N] commits

   Options:
   - /autonomous <project> --resume  # Continue from here
   - /autonomous-review <project>    # Review again
   ```

### Action: Direct

1. **Gather direction:**
   ```
   What guidance should be provided for the next run?

   Current state: [summary from last checkpoint]
   Unresolved: [from termination]

   Enter direction (or 'cancel'):
   ```

2. **Write DIRECTION.md:**
   ```markdown
   # Direction for Autonomous Execution

   ## Written: [timestamp]
   ## Applies From: checkpoint-NNN

   ### Guidance
   - [User's direction]

   ### Priority Override
   [If any]
   ```

3. **Report:**
   ```markdown
   ## Direction Saved

   Written to: projects/<project>/DIRECTION.md

   To resume: /autonomous <project> --resume
   ```

### Action: Discard

1. **Confirm discard:**
   ```
   Discard entire autonomous run?

   This will delete:
   - Branch: auto/<project>-<timestamp>
   - All checkpoint tags
   - Session output files

   AUTONOMOUS-LOG.md will be preserved for reference.

   Confirm? [y/n]
   ```

2. **Execute discard:**
   ```bash
   git -C projects/<project> checkout main
   git -C projects/<project> branch -D auto/<project>-<timestamp>
   git -C projects/<project> tag -d $(git tag | grep checkpoint-)
   rm projects/<project>/session-*.jsonl
   ```

3. **Report:**
   ```markdown
   ## Autonomous Run Discarded

   - Branch deleted
   - Tags deleted
   - Session files deleted
   - AUTONOMOUS-LOG.md preserved
   ```

## Checkpoint Detail View

When invoked with `--checkpoint N`:

```markdown
## Checkpoint NNN Detail

### Context
[Full context from log]

### Decision/Finding/Problem
[Full details]

### Rationale
[Full rationale]

### Files Modified
[Diff summary]

### Actions
1. View full diff
2. Rollback to this point
3. Return to summary
```

## Error Handling

| Error | Response |
|-------|----------|
| No autonomous branch | "No autonomous run found for `<project>`" |
| No AUTONOMOUS-LOG.md | "No execution log found — run may not have started" |
| Branch already merged | "This run was already approved and merged on [date]" |
| Multiple runs | List runs, ask which to review |
