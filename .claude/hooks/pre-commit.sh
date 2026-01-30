#!/bin/bash
# Constitutional pre-commit verification hook
# Checks that commit follows constitutional requirements

# This hook outputs JSON to control Claude's behavior
# Exit 0 with JSON to allow/deny, exit non-zero to proceed normally

COMMAND="$1"

# Check if this is a git commit command
if echo "$COMMAND" | grep -qE "^git commit"; then
    # Check if commit message includes session reference
    if echo "$COMMAND" | grep -qE "Session:"; then
        # Has session reference - allow
        exit 0
    else
        # Output reminder as feedback (not blocking)
        echo "Reminder: Commit messages should include 'Session: [identifier]' per CLAUDE.md traceability requirements"
        exit 0
    fi
fi

exit 0
