#!/bin/bash
# Run autonomous Claude execution in isolated Docker container
#
# Usage: ./run-autonomous.sh <project> [--budget <duration>] [--resume]
#
# This script:
# 1. Validates project and prerequisites
# 2. Builds Docker image if needed
# 3. Launches isolated autonomous execution
# 4. Captures output for review

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_IMAGE="claude-autonomous"

# Parse arguments
PROJECT=""
BUDGET="2h"
RESUME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --budget)
            BUDGET="$2"
            shift 2
            ;;
        --resume)
            RESUME="1"
            shift
            ;;
        *)
            if [[ -z "$PROJECT" ]]; then
                PROJECT="$1"
            fi
            shift
            ;;
    esac
done

# Validate project argument
if [[ -z "$PROJECT" ]]; then
    echo "Usage: $0 <project> [--budget <duration>] [--resume]"
    echo ""
    echo "Available projects:"
    for p in "$WORKSPACE_DIR"/projects/*/; do
        if [[ -f "${p}OBJECTIVE.md" ]]; then
            echo "  - $(basename "$p")"
        fi
    done
    exit 1
fi

PROJECT_DIR="$WORKSPACE_DIR/projects/$PROJECT"

# Validate project exists
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "Error: Project '$PROJECT' not found at $PROJECT_DIR"
    exit 1
fi

# Validate OBJECTIVE.md exists
if [[ ! -f "$PROJECT_DIR/OBJECTIVE.md" ]]; then
    echo "Error: Project '$PROJECT' missing OBJECTIVE.md"
    echo "Autonomous mode requires OBJECTIVE.md with success criteria"
    exit 1
fi

# Check for dirty working tree
if [[ -n "$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null)" ]]; then
    echo "Warning: Project has uncommitted changes"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build Docker image if needed
if ! docker image inspect "$DOCKER_IMAGE" &>/dev/null; then
    echo "Building Docker image '$DOCKER_IMAGE'..."
    docker build -t "$DOCKER_IMAGE" -f "$SCRIPT_DIR/autonomous.Dockerfile" "$WORKSPACE_DIR"
fi

# Generate session ID and timestamp
SESSION_ID=$(date +%s)-$$
TIMESTAMP=$(date +%Y%m%d-%H%M)
OUTPUT_FILE="$PROJECT_DIR/session-$TIMESTAMP.jsonl"

# Build prompt
if [[ -n "$RESUME" ]]; then
    PROMPT="You are RESUMING autonomous execution.

Project: $PROJECT
Budget: $BUDGET
Session ID: $SESSION_ID

Read projects/$PROJECT/AUTONOMOUS-LOG.md for prior state.
Read projects/$PROJECT/DIRECTION.md for new guidance.
Continue from last checkpoint per .claude/agents/autonomous.md protocol."
else
    PROMPT="You are starting AUTONOMOUS execution.

Project: $PROJECT
Budget: $BUDGET
Session ID: $SESSION_ID

Read projects/$PROJECT/OBJECTIVE.md for success criteria.
Read projects/$PROJECT/DIRECTION.md if it exists for guidance.
Read LEARNINGS.md for applicable patterns.

Execute per .claude/agents/autonomous.md protocol."
fi

echo "========================================"
echo "Launching Autonomous Execution"
echo "========================================"
echo "Project:    $PROJECT"
echo "Budget:     $BUDGET"
echo "Session:    $SESSION_ID"
echo "Output:     $OUTPUT_FILE"
echo "========================================"
echo ""

# Convert budget to seconds for timeout
budget_to_seconds() {
    local budget="$1"
    local num="${budget%[hm]}"
    local unit="${budget: -1}"

    case "$unit" in
        h) echo $((num * 3600)) ;;
        m) echo $((num * 60)) ;;
        *) echo $((num * 3600)) ;;  # Default to hours
    esac
}

TIMEOUT_SECONDS=$(budget_to_seconds "$BUDGET")

# Run autonomous execution in Docker
# --network none: No network access (isolation)
# -v workspace: Mount workspace for file access
# -v .claude: Mount claude config (read-only)
timeout "$TIMEOUT_SECONDS" docker run --rm \
    --network none \
    -v "$WORKSPACE_DIR:/workspace" \
    -v "$HOME/.claude:/root/.claude:ro" \
    -e "CLAUDE_PROJECT=$PROJECT" \
    -e "CLAUDE_BUDGET=$BUDGET" \
    -e "CLAUDE_SESSION_ID=$SESSION_ID" \
    -w /workspace \
    "$DOCKER_IMAGE" \
    -p "$PROMPT" \
    --dangerously-skip-permissions \
    --output-format stream-json \
    2>&1 | tee "$OUTPUT_FILE"

EXIT_CODE=$?

echo ""
echo "========================================"
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "Autonomous execution completed"
elif [[ $EXIT_CODE -eq 124 ]]; then
    echo "Autonomous execution terminated (budget exhausted)"
else
    echo "Autonomous execution ended with code $EXIT_CODE"
fi
echo "========================================"
echo ""
echo "Review with: /autonomous-review $PROJECT"
echo "Output log:  $OUTPUT_FILE"
