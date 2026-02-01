#!/bin/bash
# Constitutional project context capture hook
# Fires on PostToolUse for Read tool to detect project orientation
#
# Per CLAUDE.md Context Persistence:
#   - Session protocol starts with reading OBJECTIVE.md
#   - This hook captures project context when that happens
#   - State is keyed by session_id for parallel window support
#
# Triggers when: Read tool successfully reads an OBJECTIVE.md file

WORKSPACE_DIR="$CLAUDE_PROJECT_DIR"
SESSIONS_DIR="$WORKSPACE_DIR/.claude/sessions"

# Read hook input from stdin
INPUT=$(cat)

# Extract fields from JSON input
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Only process Read tool calls
if [ "$TOOL_NAME" != "Read" ]; then
    exit 0
fi

# Only process OBJECTIVE.md reads
if [[ "$FILE_PATH" != *"OBJECTIVE.md" ]]; then
    exit 0
fi

# Require session_id
if [ -z "$SESSION_ID" ]; then
    exit 0
fi

# Extract project directory from file path
PROJECT_DIR=$(dirname "$FILE_PATH")
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Compute relative path from workspace
if [[ "$PROJECT_DIR" == "$WORKSPACE_DIR"* ]]; then
    REL_PATH="${PROJECT_DIR#$WORKSPACE_DIR/}"
else
    REL_PATH="$PROJECT_DIR"
fi

# Create session directory
SESSION_DIR="$SESSIONS_DIR/$SESSION_ID"
mkdir -p "$SESSION_DIR"

STATE_FILE="$SESSION_DIR/context-state.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Extract objective summary from OBJECTIVE.md (first non-header, non-empty line)
OBJECTIVE_SUMMARY=""
if [ -f "$FILE_PATH" ]; then
    # Try to get the line after "# " title, or first substantive line
    OBJECTIVE_SUMMARY=$(grep -v "^#" "$FILE_PATH" | grep -v "^$" | grep -v "^---" | head -1 | cut -c1-100)
fi

# Build trace - check for parent OBJECTIVE.md
TRACE="[]"
LEVEL="project"

# Check if this is a subproject (has parent with OBJECTIVE.md)
PARENT_DIR=$(dirname "$PROJECT_DIR")
if [ -f "$PARENT_DIR/OBJECTIVE.md" ]; then
    LEVEL="subproject"
    PARENT_NAME=$(basename "$PARENT_DIR")
    PARENT_OBJ=$(grep -v "^#" "$PARENT_DIR/OBJECTIVE.md" | grep -v "^$" | grep -v "^---" | head -1 | cut -c1-50)
    TRACE=$(jq -n --arg p "$PARENT_NAME: $PARENT_OBJ" --arg c "$PROJECT_NAME" '[$p, $c]')
else
    TRACE=$(jq -n --arg c "$PROJECT_NAME" '[$c]')
fi

# Write or update session state
cat > "$STATE_FILE" << EOF
{
  "session_id": "$SESSION_ID",
  "timestamp": "$TIMESTAMP",
  "project": "$REL_PATH",
  "project_name": "$PROJECT_NAME",
  "objective": $(echo "$OBJECTIVE_SUMMARY" | jq -R .),
  "trace": $TRACE,
  "level": "$LEVEL",
  "status": "active"
}
EOF

# Silent success - don't clutter output on every OBJECTIVE.md read
# Only output if this looks like initial project selection (no prior state)
exit 0
