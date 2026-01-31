#!/bin/bash
# Constitutional pre-commit hook
# Checks: commit message format, verification tier
#
# Per CLAUDE.md:
#   - Verification Tiers: Trivial (<10 lines, 1 file), Standard, Critical
#   - Standard+ tier requires verification record before commit
#
# This hook is informational only, not blocking.

COMMAND="$1"

# Only check actual git commit commands
if ! echo "$COMMAND" | grep -qE "git commit"; then
    exit 0
fi

# === Commit Message Format Check ===
if ! echo "$COMMAND" | grep -q "Co-Authored-By"; then
    echo ""
    echo "=== Commit Message Check ==="
    echo "Reminder: Include 'Co-Authored-By: Claude <noreply@anthropic.com>'"
fi

# Check for Session: reference (full checkpoint indicator)
if echo "$COMMAND" | grep -qE "Session:"; then
    CHECKPOINT_TYPE="Full"
else
    CHECKPOINT_TYPE="Lightweight"
fi

# === Verification Tier Check ===

# Get staged changes stats
CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
CHANGED_LINES=$(git diff --cached --stat 2>/dev/null | tail -1 | grep -oE '[0-9]+' | head -1)

# Default to 0 if parsing fails
CHANGED_FILES=${CHANGED_FILES:-0}
CHANGED_LINES=${CHANGED_LINES:-0}

# Skip if no staged changes
if [ "$CHANGED_FILES" -eq 0 ]; then
    exit 0
fi

# Determine tier based on scope
if [ "$CHANGED_FILES" -le 1 ] && [ "${CHANGED_LINES:-0}" -le 10 ]; then
    TIER="Trivial"
else
    # Check for critical indicators in changed files or commit message
    CRITICAL_PATTERNS="security|auth|crypto|interface|api|schema|password|token|secret"
    CHANGED_FILE_LIST=$(git diff --cached --name-only 2>/dev/null)

    if echo "$CHANGED_FILE_LIST" | grep -qiE "$CRITICAL_PATTERNS" || \
       echo "$COMMAND" | grep -qiE "$CRITICAL_PATTERNS"; then
        TIER="Critical"
    else
        TIER="Standard"
    fi
fi

# For Standard+ tier, check for verification
if [ "$TIER" != "Trivial" ]; then
    # Find project root (look for OBJECTIVE.md)
    PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
    VERIFICATION_FOUND=""

    if [ -f "$PROJECT_DIR/LOG.md" ]; then
        # Check if verification record exists in last 100 lines
        if tail -100 "$PROJECT_DIR/LOG.md" 2>/dev/null | grep -qE "## Verification|### Automated Checks|### Criteria Verification"; then
            VERIFICATION_FOUND="yes"
        fi
    fi

    echo ""
    echo "=== Verification Check ==="
    echo "Checkpoint: $CHECKPOINT_TYPE"
    echo "Tier: $TIER ($CHANGED_FILES files, ~${CHANGED_LINES:-?} lines)"

    if [ -z "$VERIFICATION_FOUND" ]; then
        echo "Warning: No recent verification record found in LOG.md"
        echo ""
        echo "Per CLAUDE.md, $TIER tier requires:"
        if [ "$TIER" = "Standard" ]; then
            echo "  - Automated checks (build, tests)"
            echo "  - Criteria verification"
            echo "  - Scope verification"
        else
            echo "  - Full verification record"
            echo "  - Explicit user review"
        fi
        echo ""
        echo "Consider running verification before committing."
    else
        echo "Verification record found in LOG.md"
    fi
fi

exit 0
