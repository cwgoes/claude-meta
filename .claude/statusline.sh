#!/bin/bash
# Statusline script for Claude Code
# Shows current project + session metrics
# Session-keyed state at .claude/sessions/<session_id>/context-state.json
# supports multiple Claude Code windows working in parallel

set -e

# ANSI color codes
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_BLUE="\033[34m"
C_MAGENTA="\033[35m"
C_CYAN="\033[36m"
C_GRAY="\033[90m"

# Read JSON input from Claude Code
input=$(cat)

# Extract session_id for session-specific state lookup
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null)

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

# Context indicator with color based on usage
if [ "$CONTEXT_PERCENT" -gt 85 ]; then
    CTX_COLOR="${C_RED}${C_BOLD}"
    CTX_INDICATOR="Ctx: ${CONTEXT_PERCENT}%!"
elif [ "$CONTEXT_PERCENT" -gt 70 ]; then
    CTX_COLOR="${C_YELLOW}"
    CTX_INDICATOR="Ctx: ${CONTEXT_PERCENT}%"
else
    CTX_COLOR="${C_GRAY}"
    CTX_INDICATOR="Ctx: ${CONTEXT_PERCENT}%"
fi

# Metrics suffix with colors
METRICS="${C_GRAY}|${C_RESET} ${CTX_COLOR}${CTX_INDICATOR}${C_RESET} ${C_GRAY}|${C_RESET} ${C_GRAY}${INPUT_DISPLAY}/${OUTPUT_DISPLAY}${C_RESET} ${C_GRAY}|${C_RESET} ${C_GREEN}\$${COST_DISPLAY}${C_RESET}"

# Find project state - session-specific only (no fallback search)
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // "."')
SESSIONS_DIR="$PROJECT_DIR/.claude/sessions"
LATEST_STATE=""
LATEST_TIME=0

# Session-specific state only (isolated per Claude Code window)
if [ -n "$SESSION_ID" ] && [ -f "$SESSIONS_DIR/$SESSION_ID/context-state.json" ]; then
    LATEST_STATE="$SESSIONS_DIR/$SESSION_ID/context-state.json"
    if stat --version &>/dev/null 2>&1; then
        LATEST_TIME=$(stat -c %Y "$LATEST_STATE" 2>/dev/null || echo 0)
    else
        LATEST_TIME=$(stat -f %m "$LATEST_STATE" 2>/dev/null || echo 0)
    fi
fi

# If no session state, show "no active project" - use /project-start to begin
if [ -z "$LATEST_STATE" ] || [ ! -f "$LATEST_STATE" ]; then
    echo -e "${C_GRAY}-- No active project${C_RESET} ${METRICS}"
    exit 0
fi

# Read project state
PROJECT=$(jq -r '.project // "?"' "$LATEST_STATE")
OBJECTIVE=$(jq -r '.objective // "?"' "$LATEST_STATE")
STATUS=$(jq -r '.status // "?"' "$LATEST_STATE")

# Resolve actual project path from state (not from state file location)
if [[ "$PROJECT" == /* ]]; then
    PROJECT_PATH="$PROJECT"
else
    PROJECT_PATH="$PROJECT_DIR/$PROJECT"
fi

# Get git branch and status for the project
GIT_BRANCH=""
GIT_DIRTY=""
if [ -d "$PROJECT_PATH" ] && { [ -d "$PROJECT_PATH/.git" ] || git -C "$PROJECT_PATH" rev-parse --git-dir &>/dev/null 2>&1; }; then
    GIT_BRANCH=$(git -C "$PROJECT_PATH" branch --show-current 2>/dev/null || echo "")
    # Check if working tree is dirty
    if [ -n "$(git -C "$PROJECT_PATH" status --porcelain 2>/dev/null)" ]; then
        GIT_DIRTY="*"
    fi
fi

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
        STALE_WARNING=" ${C_YELLOW}(${AGE_MIN}m)${C_RESET}"
    fi
fi

# Format branch display with color
BRANCH_DISPLAY=""
if [ -n "$GIT_BRANCH" ]; then
    if [ -n "$GIT_DIRTY" ]; then
        BRANCH_DISPLAY=" ${C_MAGENTA}@${GIT_BRANCH}${C_YELLOW}${GIT_DIRTY}${C_RESET}"
    else
        BRANCH_DISPLAY=" ${C_MAGENTA}@${GIT_BRANCH}${C_RESET}"
    fi
fi

# Format output based on status
case "$STATUS" in
    active)
        echo -e "${C_GRAY}[${C_RESET}${C_CYAN}${C_BOLD}${PROJECT_NAME}${C_RESET}${BRANCH_DISPLAY}${C_GRAY}]${C_RESET} ${TRACE_DISPLAY}${STALE_WARNING} ${METRICS}"
        ;;
    paused)
        echo -e "${C_GRAY}[${C_RESET}${C_CYAN}${C_BOLD}${PROJECT_NAME}${C_RESET}${BRANCH_DISPLAY}${C_GRAY}]${C_RESET} ${C_YELLOW}PAUSED${C_RESET}${STALE_WARNING} ${METRICS}"
        ;;
    completed)
        echo -e "${C_GRAY}[${C_RESET}${C_CYAN}${C_BOLD}${PROJECT_NAME}${C_RESET}${BRANCH_DISPLAY}${C_GRAY}]${C_RESET} ${C_GREEN}DONE${C_RESET} ${METRICS}"
        ;;
    *)
        echo -e "${C_GRAY}[${C_RESET}${C_CYAN}${C_BOLD}${PROJECT_NAME}${C_RESET}${BRANCH_DISPLAY}${C_GRAY}]${C_RESET} ${TRACE_DISPLAY}${STALE_WARNING} ${METRICS}"
        ;;
esac
