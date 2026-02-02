#!/bin/bash
# Constitutional session start hook
# Outputs workspace context - project selection is explicit via /project-start
#
# Work Modes (per CLAUDE.md):
#   - Ad-hoc: Clear task, single session - no structure needed
#   - Project: Multi-session work - use /project-start <name>
#
# Repository Model:
#   - Workspace repo is metadata-only (constitution, learnings, .claude/)
#   - Each project under projects/ IS its own git repo

WORKSPACE_DIR="$CLAUDE_PROJECT_DIR"
LEARNINGS_FILE="$WORKSPACE_DIR/LEARNINGS.md"

# Read hook input for session_id
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

# Clear session state on new session start
# This ensures /clear gives a fresh slate (no stale project in statusline)
if [ -n "$SESSION_ID" ]; then
    STATE_FILE="$WORKSPACE_DIR/.claude/sessions/$SESSION_ID/context-state.json"
    if [ -f "$STATE_FILE" ]; then
        rm -f "$STATE_FILE"
    fi
fi

echo "=== Workspace Context ==="

# LEARNINGS.md status (workspace-level)
if [ -f "$LEARNINGS_FILE" ]; then
    TECH_COUNT=$(grep -c "^### \[LP-" "$LEARNINGS_FILE" 2>/dev/null || echo "0")
    PROC_COUNT=$(grep -c "^### \[PP-" "$LEARNINGS_FILE" 2>/dev/null || echo "0")
    FAIL_COUNT=$(grep -c "^### \[FP-" "$LEARNINGS_FILE" 2>/dev/null || echo "0")
    TOTAL=$((TECH_COUNT + PROC_COUNT + FAIL_COUNT))

    if [ "$TOTAL" -gt 0 ]; then
        echo "Learnings: $TOTAL (Tech:$TECH_COUNT Proc:$PROC_COUNT Fail:$FAIL_COUNT)"
    else
        echo "Learnings: repository exists, empty"
    fi
fi

# Workspace git status (if workspace itself is a repo - transitional)
if git -C "$WORKSPACE_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$WORKSPACE_DIR" branch --show-current 2>/dev/null || echo "detached")
    DIRTY=$(git -C "$WORKSPACE_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DIRTY" -gt 0 ]; then
        echo "Git: $BRANCH ($DIRTY uncommitted)"
    else
        echo "Git: $BRANCH (clean)"
    fi
fi

# List available projects (each is its own git repo)
PROJECTS_DIR="$WORKSPACE_DIR/projects"
if [ -d "$PROJECTS_DIR" ]; then
    PROJECT_COUNT=$(find "$PROJECTS_DIR" -maxdepth 2 -name "OBJECTIVE.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$PROJECT_COUNT" -gt 0 ]; then
        echo "Projects: $PROJECT_COUNT available"
    fi
fi

echo "========================="
echo ""
echo "Use /project-start <name> to select a project."
