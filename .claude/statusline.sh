#!/bin/bash
# Statusline script for Claude Code
# Shows current project (most recently updated) + session metrics
# Per-project state at <project>/context-state.json supports multiple windows

set -e

# Read JSON input from Claude Code
input=$(cat)

# Extract session metrics
CONTEXT_PERCENT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
TOTAL_INPUT=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
TOTAL_OUTPUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
TOTAL_COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Format tokens (K for thousands, M for millions)
format_tokens() {
    local tokens=$1
    if [ "$tokens" -ge 1000000 ]; then
        printf "%.1fM" "$(echo "scale=1; $tokens / 1000000" | bc)"
    elif [ "$tokens" -ge 1000 ]; then
        printf "%.0fK" "$(echo "scale=0; $tokens / 1000" | bc)"
    else
        printf "%d" "$tokens"
    fi
}

INPUT_DISPLAY=$(format_tokens "$TOTAL_INPUT")
OUTPUT_DISPLAY=$(format_tokens "$TOTAL_OUTPUT")

# Format cost
COST_DISPLAY=$(printf "%.2f" "$TOTAL_COST" 2>/dev/null || echo "0.00")

# Context warning indicator
if [ "$CONTEXT_PERCENT" -gt 70 ]; then
    CTX_INDICATOR="Ctx: ${CONTEXT_PERCENT}%!"
else
    CTX_INDICATOR="Ctx: ${CONTEXT_PERCENT}%"
fi

# Metrics suffix
METRICS="| ${CTX_INDICATOR} | ${INPUT_DISPLAY}/${OUTPUT_DISPLAY} | \$${COST_DISPLAY}"

# Find the most recently updated project context-state.json
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // "."')
LATEST_STATE=""
LATEST_TIME=0

# Search for context-state.json files in projects/
if [ -d "$PROJECT_DIR/projects" ]; then
    for state_file in "$PROJECT_DIR"/projects/*/context-state.json; do
        if [ -f "$state_file" ]; then
            # Get file modification time
            if stat --version &>/dev/null 2>&1; then
                # GNU stat
                FILE_TIME=$(stat -c %Y "$state_file" 2>/dev/null || echo 0)
            else
                # BSD/macOS stat
                FILE_TIME=$(stat -f %m "$state_file" 2>/dev/null || echo 0)
            fi
            if [ "$FILE_TIME" -gt "$LATEST_TIME" ]; then
                LATEST_TIME=$FILE_TIME
                LATEST_STATE=$state_file
            fi
        fi
    done
fi

# If no project state found, show metrics only
if [ -z "$LATEST_STATE" ] || [ ! -f "$LATEST_STATE" ]; then
    echo "-- No active project ${METRICS}"
    exit 0
fi

# Read project state
PROJECT=$(jq -r '.project // "?"' "$LATEST_STATE")
OBJECTIVE=$(jq -r '.objective // "?"' "$LATEST_STATE")
STATUS=$(jq -r '.status // "?"' "$LATEST_STATE")

# Read objective trace array and format as "root → parent → current"
TRACE_RAW=$(jq -r '.trace // [] | join(" → ")' "$LATEST_STATE")
if [ -z "$TRACE_RAW" ] || [ "$TRACE_RAW" = "" ]; then
    # Fallback to objective if no trace
    TRACE_RAW="$OBJECTIVE"
fi

# Extract just project name from path
PROJECT_NAME=$(basename "$PROJECT")

# Truncate trace for display (max 60 chars to leave room for metrics)
TRACE_DISPLAY="$TRACE_RAW"
if [ ${#TRACE_RAW} -gt 60 ]; then
    # Truncate from the left (keep most recent objectives visible)
    TRACE_DISPLAY="...${TRACE_RAW: -57}"
fi

# Check staleness (>30 min without update = warning)
STALE_WARNING=""
NOW=$(date +%s)
if [ "$LATEST_TIME" -gt 0 ]; then
    AGE_SEC=$((NOW - LATEST_TIME))
    AGE_MIN=$((AGE_SEC / 60))
    if [ "$AGE_MIN" -gt 30 ]; then
        STALE_WARNING=" (${AGE_MIN}m)"
    fi
fi

# Format output based on status
case "$STATUS" in
    active)
        echo "[${PROJECT_NAME}] ${TRACE_DISPLAY}${STALE_WARNING} ${METRICS}"
        ;;
    paused)
        echo "[${PROJECT_NAME}] PAUSED${STALE_WARNING} ${METRICS}"
        ;;
    completed)
        echo "[${PROJECT_NAME}] DONE ${METRICS}"
        ;;
    *)
        echo "[${PROJECT_NAME}] ${TRACE_DISPLAY}${STALE_WARNING} ${METRICS}"
        ;;
esac
