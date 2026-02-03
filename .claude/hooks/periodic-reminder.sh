#!/bin/bash
# Periodic reminder hook - injects re-read reminders every N tool calls
#
# Tracks tool call count per session and outputs reminder at intervals.
# Per constitution: Mandatory re-reads every 15 tool calls.

set -e

# Get session ID from environment (provided by Claude Code)
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Counter file location (session-specific)
COUNTER_DIR="$PROJECT_DIR/.claude/sessions/$SESSION_ID"
COUNTER_FILE="$COUNTER_DIR/tool-count"

# Reminder interval
INTERVAL=15

# Ensure directory exists
mkdir -p "$COUNTER_DIR"

# Read current count
if [ -f "$COUNTER_FILE" ]; then
    COUNT=$(cat "$COUNTER_FILE")
else
    COUNT=0
fi

# Increment
COUNT=$((COUNT + 1))

# Save
echo "$COUNT" > "$COUNTER_FILE"

# Check if reminder is due
if [ $((COUNT % INTERVAL)) -eq 0 ]; then
    # Check if we're in a project (has OBJECTIVE.md)
    # Look for OBJECTIVE.md in project directories
    OBJECTIVE_FILE=""

    # Check session state for active project
    STATE_FILE="$COUNTER_DIR/context-state.json"
    if [ -f "$STATE_FILE" ]; then
        PROJECT_PATH=$(jq -r '.project // empty' "$STATE_FILE" 2>/dev/null)
        if [ -n "$PROJECT_PATH" ]; then
            if [ -f "$PROJECT_DIR/$PROJECT_PATH/OBJECTIVE.md" ]; then
                OBJECTIVE_FILE="$PROJECT_DIR/$PROJECT_PATH/OBJECTIVE.md"
            elif [ -f "$PROJECT_PATH/OBJECTIVE.md" ]; then
                OBJECTIVE_FILE="$PROJECT_PATH/OBJECTIVE.md"
            fi
        fi
    fi

    if [ -n "$OBJECTIVE_FILE" ]; then
        # Find LEARNINGS.md (project-level or workspace-level)
        LEARNINGS_FILE=""
        OBJECTIVE_DIR=$(dirname "$OBJECTIVE_FILE")
        if [ -f "$OBJECTIVE_DIR/LEARNINGS.md" ]; then
            LEARNINGS_FILE="$OBJECTIVE_DIR/LEARNINGS.md"
        elif [ -f "$PROJECT_DIR/LEARNINGS.md" ]; then
            LEARNINGS_FILE="$PROJECT_DIR/LEARNINGS.md"
        fi

        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "  REMINDER ($COUNT tool calls)"
        echo "  1. Re-read OBJECTIVE.md — verify alignment to criteria"
        echo "     File: $OBJECTIVE_FILE"
        if [ -n "$LEARNINGS_FILE" ]; then
            echo "  2. Check LEARNINGS.md — review Avoid/Prefer entries"
            echo "     File: $LEARNINGS_FILE"
        else
            echo "  2. Check LEARNINGS.md (not found in project)"
        fi
        echo "═══════════════════════════════════════════════════════════"
        echo ""
    fi
fi

exit 0
