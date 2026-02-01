#!/bin/bash
# Constitutional pre-compact hook
# Saves context state before compression, keyed by session ID
#
# Per CLAUDE.md Context Persistence:
#   - Context compression is automatic and invisible
#   - State externalization enables recovery
#   - PreCompact fires before compression (both manual and auto)
#
# Session isolation: Uses session_id from hook input to support
# multiple Claude Code windows working on different projects.

WORKSPACE_DIR="$CLAUDE_PROJECT_DIR"
SESSIONS_DIR="$WORKSPACE_DIR/.claude/sessions"

# Read hook input from stdin (contains session_id and trigger info)
INPUT=$(cat)

# Extract session_id and trigger from JSON input
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "unknown"' 2>/dev/null)

# Require session_id
if [ -z "$SESSION_ID" ]; then
    echo "Warning: No session_id in hook input, cannot save context state"
    exit 0
fi

# Create session directory
SESSION_DIR="$SESSIONS_DIR/$SESSION_ID"
mkdir -p "$SESSION_DIR"

STATE_FILE="$SESSION_DIR/context-state.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if we have existing state for this session
if [ -f "$STATE_FILE" ]; then
    # Update existing state with compression marker
    EXISTING=$(cat "$STATE_FILE" 2>/dev/null)
    echo "$EXISTING" | jq --arg ts "$TIMESTAMP" --arg trigger "$TRIGGER" \
        '. + {last_pre_compact: $ts, compression_trigger: $trigger}' > "$STATE_FILE.tmp" \
        && mv "$STATE_FILE.tmp" "$STATE_FILE"

    PROJECT=$(echo "$EXISTING" | jq -r '.project // "unknown"' 2>/dev/null)
    echo "=== Pre-Compact State Saved ==="
    echo "Session: ${SESSION_ID:0:8}..."
    echo "Project: $PROJECT"
    echo "Trigger: $TRIGGER"
else
    # No existing state - create minimal marker
    cat > "$STATE_FILE" << EOF
{
  "session_id": "$SESSION_ID",
  "timestamp": "$TIMESTAMP",
  "last_pre_compact": "$TIMESTAMP",
  "compression_trigger": "$TRIGGER",
  "status": "no_project_selected"
}
EOF
    echo "=== Pre-Compact: No Active Project ==="
    echo "Session: ${SESSION_ID:0:8}..."
    echo "No project context to save."
fi

exit 0
