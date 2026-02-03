#!/bin/bash
# Enforcement pre-commit hook - BLOCKS non-compliant commits
#
# Enforces:
#   1. LOG.md entry must exist for this commit
#   2. Evidence block required for Standard+ tier
#   3. Critical tier requires explicit marker
#
# This hook BLOCKS commits that don't meet requirements.

set -e

COMMAND="$1"

# Only check actual git commit commands
if ! echo "$COMMAND" | grep -qE "git commit"; then
    exit 0
fi

# Find project root
PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
LOG_FILE="$PROJECT_DIR/LOG.md"

# === 1. LOG.md Entry Check ===
# Check if LOG.md exists and was modified in staging or recently
if [ -f "$LOG_FILE" ]; then
    # Check if LOG.md is staged
    LOG_STAGED=$(git diff --cached --name-only 2>/dev/null | grep -c "LOG.md" || echo "0")

    if [ "$LOG_STAGED" -eq 0 ]; then
        # LOG.md not staged - check if it was recently modified (within last 5 min)
        if [ "$(uname)" = "Darwin" ]; then
            LOG_MTIME=$(stat -f %m "$LOG_FILE" 2>/dev/null || echo "0")
        else
            LOG_MTIME=$(stat -c %Y "$LOG_FILE" 2>/dev/null || echo "0")
        fi
        NOW=$(date +%s)
        AGE=$((NOW - LOG_MTIME))

        if [ "$AGE" -gt 300 ]; then
            echo ""
            echo "=== BLOCKED: No LOG.md Entry ==="
            echo "Per constitution: Every commit requires LOG.md entry first."
            echo ""
            echo "LOG.md was not staged and hasn't been modified in ${AGE}s."
            echo ""
            echo "Fix: Update LOG.md with session entry, then commit."
            echo "Override: Use --no-verify to bypass (not recommended)."
            exit 1
        fi
    fi
else
    # No LOG.md at all - this might be okay for workspace-level commits
    # Only block if there's an OBJECTIVE.md (indicating this is a project)
    if [ -f "$PROJECT_DIR/OBJECTIVE.md" ]; then
        echo ""
        echo "=== BLOCKED: No LOG.md ==="
        echo "This appears to be a project (OBJECTIVE.md exists) but LOG.md is missing."
        echo ""
        echo "Fix: Create LOG.md with initial session entry."
        exit 1
    fi
fi

# === 2. Verification Tier Detection ===
CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
CHANGED_LINES=$(git diff --cached --stat 2>/dev/null | tail -1 | grep -oE '[0-9]+' | head -1)
CHANGED_FILES=${CHANGED_FILES:-0}
CHANGED_LINES=${CHANGED_LINES:-0}

# Skip further checks if no staged changes
if [ "$CHANGED_FILES" -eq 0 ]; then
    exit 0
fi

# Determine tier
if [ "$CHANGED_FILES" -le 1 ] && [ "${CHANGED_LINES:-0}" -le 10 ]; then
    TIER="Trivial"
elif [ "$CHANGED_FILES" -gt 3 ]; then
    TIER="Critical"
else
    # Check for critical indicators
    CRITICAL_PATTERNS="security|auth|crypto|password|token|secret|migration"
    CHANGED_FILE_LIST=$(git diff --cached --name-only 2>/dev/null)

    if echo "$CHANGED_FILE_LIST" | grep -qiE "$CRITICAL_PATTERNS"; then
        TIER="Critical"
    else
        TIER="Standard"
    fi
fi

# === 3. Evidence Check for Standard+ ===
if [ "$TIER" != "Trivial" ] && [ -f "$LOG_FILE" ]; then
    # Check for Evidence block in recent LOG.md content
    EVIDENCE_FOUND=$(tail -50 "$LOG_FILE" 2>/dev/null | grep -cE "^- Build:|^- Tests:|Evidence:" || echo "0")

    if [ "$EVIDENCE_FOUND" -eq 0 ]; then
        echo ""
        echo "=== BLOCKED: No Evidence Block ==="
        echo "Tier: $TIER ($CHANGED_FILES files, ~${CHANGED_LINES:-?} lines)"
        echo ""
        echo "Per Evidence Protocol: Standard+ tier requires concrete evidence."
        echo ""
        echo "Required in LOG.md:"
        echo "  - Build: \`[command]\` → exit [code]"
        echo "  - Tests: \`[command]\` → [N/M] passed"
        echo "  - SC-N: [measurement or file:line reference]"
        echo ""
        echo "Fix: Add Evidence block to LOG.md session entry."
        echo "Override: Use --no-verify to bypass (not recommended)."
        exit 1
    fi
fi

# === 4. Critical Tier Warning ===
if [ "$TIER" = "Critical" ]; then
    echo ""
    echo "=== Critical Tier Commit ==="
    echo "Scope: $CHANGED_FILES files, ~${CHANGED_LINES:-?} lines"
    echo ""
    echo "Critical tier commits should have:"
    echo "  - Full verification record with evidence"
    echo "  - Explicit user review"
    echo ""
    echo "Proceeding with commit..."
fi

# === 5. Commit Message Format Check ===
if ! echo "$COMMAND" | grep -q "Co-Authored-By"; then
    echo ""
    echo "=== Warning: Missing Co-Author ==="
    echo "Consider adding: Co-Authored-By: Claude <noreply@anthropic.com>"
fi

exit 0
