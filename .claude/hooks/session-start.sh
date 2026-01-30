#!/bin/bash
# Constitutional session start hook
# Outputs workspace context - project selection is explicit via /project-start

PROJECT_DIR="$CLAUDE_PROJECT_DIR"
LEARNINGS_FILE="$PROJECT_DIR/LEARNINGS.md"

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

# Git status summary
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
    DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DIRTY" -gt 0 ]; then
        echo "Git: $BRANCH ($DIRTY uncommitted)"
    else
        echo "Git: $BRANCH (clean)"
    fi
fi

# List available projects
PROJECTS_DIR="$PROJECT_DIR/projects"
if [ -d "$PROJECTS_DIR" ]; then
    PROJECT_COUNT=$(find "$PROJECTS_DIR" -maxdepth 2 -name "OBJECTIVE.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$PROJECT_COUNT" -gt 0 ]; then
        echo "Projects: $PROJECT_COUNT available"
    fi
fi

echo "========================="
echo ""
echo "Use /project-start <name> to select a project."
