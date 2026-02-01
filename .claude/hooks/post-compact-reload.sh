#!/bin/bash
# Constitutional post-compact context reload hook
# Outputs context digest after compression, keyed by session ID
#
# Per CLAUDE.md Context Persistence:
#   - Context invariants: project path, objective, trace, level, recent decisions
#   - SessionStart fires after compact with source="compact"
#   - This hook outputs digest directly (not just reminders to read files)
#
# Session isolation: Uses session_id from hook input to support
# multiple Claude Code windows working on different projects.

WORKSPACE_DIR="$CLAUDE_PROJECT_DIR"
SESSIONS_DIR="$WORKSPACE_DIR/.claude/sessions"

# Read hook input from stdin
INPUT=$(cat)

# Extract session_id and source from JSON input
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"' 2>/dev/null)

# Only run full reload on compact events
if [ "$SOURCE" != "compact" ]; then
    exit 0
fi

# Require session_id
if [ -z "$SESSION_ID" ]; then
    echo "=== Context Reload Failed ==="
    echo "No session_id available. Use /project-start <name> to establish context."
    exit 0
fi

SESSION_DIR="$SESSIONS_DIR/$SESSION_ID"
STATE_FILE="$SESSION_DIR/context-state.json"

# No state for this session
if [ ! -f "$STATE_FILE" ]; then
    echo "=== Context Restored (No Prior State) ==="
    echo "Session: ${SESSION_ID:0:8}..."
    echo "No project was active before compression."
    echo "Use /project-start <name> to select a project."
    exit 0
fi

# Read session state
STATE=$(cat "$STATE_FILE" 2>/dev/null)
PROJECT_PATH=$(echo "$STATE" | jq -r '.project // empty' 2>/dev/null)
STATUS=$(echo "$STATE" | jq -r '.status // "unknown"' 2>/dev/null)

# Check if a project was actually selected
if [ -z "$PROJECT_PATH" ] || [ "$STATUS" = "no_project_selected" ]; then
    echo "=== Context Restored (No Active Project) ==="
    echo "Session: ${SESSION_ID:0:8}..."
    echo "Use /project-start <name> to select a project."
    exit 0
fi

# Resolve project directory
if [[ "$PROJECT_PATH" == /* ]]; then
    PROJECT_DIR="$PROJECT_PATH"
else
    PROJECT_DIR="$WORKSPACE_DIR/$PROJECT_PATH"
fi

PROJECT_NAME=$(basename "$PROJECT_DIR")

# Verify project exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "=== Context Restore Warning ==="
    echo "Project path no longer exists: $PROJECT_PATH"
    echo "Use /project-start <name> to select a project."
    exit 0
fi

echo "=============================================="
echo "=== CONTEXT RESTORED AFTER COMPRESSION ==="
echo "=============================================="
echo ""

# --- 1. Project Identity ---
echo "## Active Project: $PROJECT_NAME"
echo "Path: $PROJECT_DIR"
echo "Session: ${SESSION_ID:0:8}..."
echo ""

# --- 2. Objective Trace (from session state) ---
OBJECTIVE=$(echo "$STATE" | jq -r '.objective // "unknown"' 2>/dev/null)
TRACE=$(echo "$STATE" | jq -r '.trace // [] | join(" -> ")' 2>/dev/null)
LEVEL=$(echo "$STATE" | jq -r '.level // "project"' 2>/dev/null)
PROJ_STATUS=$(echo "$STATE" | jq -r '.status // "active"' 2>/dev/null)

echo "## Context State"
echo "Objective: $OBJECTIVE"
if [ -n "$TRACE" ] && [ "$TRACE" != "" ]; then
    echo "Trace: $TRACE"
fi
echo "Level: $LEVEL | Status: $PROJ_STATUS"
echo ""

# --- 3. Success Criteria (from OBJECTIVE.md) ---
OBJECTIVE_FILE="$PROJECT_DIR/OBJECTIVE.md"
if [ -f "$OBJECTIVE_FILE" ]; then
    echo "## Success Criteria (from OBJECTIVE.md)"
    # Extract success criteria section if it exists
    if grep -q "## Success Criteria" "$OBJECTIVE_FILE" 2>/dev/null; then
        # Get lines from "## Success Criteria" until next "##" or end
        sed -n '/## Success Criteria/,/^## /p' "$OBJECTIVE_FILE" | head -20 | grep -v "^## " | grep -v "^$" | head -10
    else
        # Fallback: show first meaningful lines
        grep -v "^#" "$OBJECTIVE_FILE" | grep -v "^$" | head -5
    fi
    echo ""
fi

# --- 4. Recent Decisions & Next Steps (from LOG.md) ---
LOG_FILE="$PROJECT_DIR/LOG.md"
if [ -f "$LOG_FILE" ]; then
    echo "## Recent Context (from LOG.md)"

    # Find the last session header
    LAST_SESSION=$(grep -n "^## Session" "$LOG_FILE" | tail -1 | cut -d: -f1)

    if [ -n "$LAST_SESSION" ]; then
        # Extract last session content (up to 30 lines)
        TOTAL_LINES=$(wc -l < "$LOG_FILE" | tr -d ' ')
        REMAINING=$((TOTAL_LINES - LAST_SESSION + 1))
        if [ "$REMAINING" -gt 30 ]; then
            REMAINING=30
        fi
        tail -n "$REMAINING" "$LOG_FILE" | head -30
    else
        # No session markers, show last 15 lines
        echo "(Last 15 lines)"
        tail -15 "$LOG_FILE"
    fi
    echo ""
fi

# --- 5. Critical Learnings (project-level) ---
LEARNINGS_FILE="$PROJECT_DIR/LEARNINGS.md"
if [ -f "$LEARNINGS_FILE" ]; then
    # Count failure patterns (most critical to remember)
    FAIL_COUNT=$(grep -c "^### \[FP-" "$LEARNINGS_FILE" 2>/dev/null || echo "0")
    if [ "$FAIL_COUNT" -gt 0 ]; then
        echo "## Failure Patterns ($FAIL_COUNT recorded)"
        # Show titles of failure patterns
        grep "^### \[FP-" "$LEARNINGS_FILE" | head -5
        echo ""
    fi
fi

# --- 6. Git State ---
if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "detached")
    DIRTY=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    echo "## Git State"
    echo "Branch: $BRANCH"
    if [ "$DIRTY" -gt 0 ]; then
        echo "Uncommitted changes: $DIRTY files"
        git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | head -5
    else
        echo "Working tree: clean"
    fi
    echo ""
fi

echo "=============================================="
echo "Context invariants restored. Continuing work."
echo "=============================================="

# Update session state to record reload
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "$STATE" | jq --arg ts "$TIMESTAMP" \
    '. + {last_context_reload: $ts} | del(.compression_pending)' > "$STATE_FILE.tmp" \
    && mv "$STATE_FILE.tmp" "$STATE_FILE"

exit 0
