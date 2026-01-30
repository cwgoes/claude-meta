#!/bin/bash
# Constitutional pre-commit verification hook
# Checks that commit follows constitutional requirements
#
# Per CLAUDE.md Checkpoint Model:
#   - Lightweight checkpoint: git commit only (no Session: required)
#   - Full checkpoint: git commit + LOG.md entry (Session: reference expected)
#
# This hook is informational only, not blocking.

COMMAND="$1"

# Check if this is a git commit command
if echo "$COMMAND" | grep -qE "^git commit"; then
    # Check if commit message includes session reference
    if echo "$COMMAND" | grep -qE "Session:"; then
        # Full checkpoint format - good
        exit 0
    else
        # Lightweight checkpoint format - also valid
        # Just note the distinction for awareness
        echo "Note: Lightweight checkpoint (no Session: link). Use full checkpoint format for session boundaries or significant decisions."
        exit 0
    fi
fi

exit 0
