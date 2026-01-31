---
name: autonomous
description: Launch autonomous execution for a project with time budget
constitution: CLAUDE.md
alignment:
  - Work Modes / Autonomous Mode
  - Autonomous Execution
---

# Autonomous Execution Skill

Launches unattended execution for a project with full traceability for async review.

## Invocation

```
/autonomous <project> [--budget <duration>] [--resume]
```

**Arguments:**
- `project`: Project name (must exist in `projects/` with OBJECTIVE.md)
- `--budget`: Time limit. Format: `30m`, `1h`, `2h`, `4h`. Default: `2h`
- `--resume`: Continue from last checkpoint instead of starting fresh

## Prerequisites

Before launching:
1. Project must exist with OBJECTIVE.md containing verifiable success criteria
2. Docker must be available (autonomous mode requires isolation)
3. Working tree should be clean (will warn if dirty)

## Protocol

### Fresh Run

1. **Validate project:**
   ```bash
   # Check project exists
   ls projects/<project>/OBJECTIVE.md

   # Check for dirty state
   git -C projects/<project> status --porcelain
   ```

2. **Extract configuration:**
   - Read OBJECTIVE.md for success criteria
   - Read DIRECTION.md if exists (for steering)
   - Generate session ID

3. **Build Docker command:**
   ```bash
   docker run --rm --network none \
     -v "$(pwd):/workspace" \
     -v "$HOME/.claude:/root/.claude:ro" \
     -e CLAUDE_PROJECT="<project>" \
     -e CLAUDE_BUDGET="<duration>" \
     -e CLAUDE_SESSION_ID="<session_id>" \
     claude-autonomous \
     -p "$(cat <<'EOF'
   You are operating in AUTONOMOUS MODE.

   Project: <project>
   Budget: <duration>
   Session ID: <session_id>

   Read projects/<project>/OBJECTIVE.md for success criteria.
   Read projects/<project>/DIRECTION.md if it exists for guidance.
   Read LEARNINGS.md for applicable patterns.

   Execute per .claude/agents/autonomous.md protocol.
   EOF
   )" --dangerously-skip-permissions --output-format stream-json
   ```

4. **Launch and report:**
   ```
   ## Autonomous Execution Launched

   - Project: <project>
   - Budget: <duration>
   - Branch: auto/<project>-<timestamp>
   - Session ID: <session_id>

   Monitor: tail -f projects/<project>/session-<timestamp>.jsonl
   Review:  /autonomous-review <project>
   ```

### Resume Run

1. **Find last session:**
   - Read AUTONOMOUS-LOG.md for last run configuration
   - Identify last checkpoint tag

2. **Check for DIRECTION.md:**
   - If exists and newer than last checkpoint, will be applied

3. **Launch with resume context:**
   - Same Docker command but with resume flag
   - Agent reads prior state and continues

## Docker Image

The skill expects `claude-autonomous` Docker image. Build with:

```bash
.claude/docker/build.sh
```

Or manually:
```bash
docker build -t claude-autonomous -f .claude/docker/autonomous.Dockerfile .
```

## Output

Autonomous execution produces:
- `projects/<project>/AUTONOMOUS-LOG.md` — Structured decision log
- `projects/<project>/session-<timestamp>.jsonl` — Full stream output
- Git branch `auto/<project>-<timestamp>` with checkpoint tags

## Examples

### Basic launch
```
/autonomous my-project
```
Launches with 2h default budget.

### Custom budget
```
/autonomous my-project --budget 4h
```
Launches with 4 hour budget.

### Resume after direction
```
# User reviews and adds DIRECTION.md
/autonomous my-project --resume
```
Continues from last checkpoint with new guidance.

## Error Handling

| Error | Response |
|-------|----------|
| Project not found | "Project `<name>` not found. Available: ..." |
| No OBJECTIVE.md | "Project requires OBJECTIVE.md with success criteria" |
| Docker unavailable | "Docker required for autonomous mode (isolation)" |
| Dirty working tree | Warning + offer to stash or abort |
| Already running | "Autonomous run already active for this project" |

## Integration

### With /autonomous-review
After autonomous execution completes or is interrupted, use `/autonomous-review` to:
- View checkpoint history
- Approve and merge
- Rollback to checkpoint
- Provide direction and resume

### With /session-end
Autonomous mode manages its own session lifecycle. Do not use `/session-end` for autonomous runs — use `/autonomous-review` instead.
