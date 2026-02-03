#!/bin/bash
# External runner for unattended Claude Code execution with rigorous verification
#
# Two-phase model per iteration:
#   1. WORK: Progress toward objectives (receives feedback from previous verification)
#   2. VERIFY: Skeptical, comprehensive check that objectives are met
#
# Usage:
#   ./scripts/run-until-complete.sh <project-path> [max-iterations]
#
# Examples:
#   ./scripts/run-until-complete.sh my-project
#   ./scripts/run-until-complete.sh my-project/subprojects/cache 20
#
# Project Requirements:
#   - OBJECTIVE.md with success criteria (SC-1, SC-2, ...)
#   - build.sh (optional) - exits 0 on successful build
#   - test.sh (optional) - exits 0 on all tests passing
#
# External Verification:
#   When Claude claims completion, the script independently runs build.sh
#   and test.sh to verify. This catches cases where Claude fabricates
#   evidence or misinterprets criteria. Without these scripts, the runner
#   relies solely on Claude's self-assessment.
#
# The verification phase:
#   - Runs /project-check
#   - Reads ALL source files
#   - Checks EACH success criterion with explicit evidence
#   - Runs build and tests
#   - Is skeptical: assumes incomplete until proven otherwise
#
# Feedback loop:
#   - Verification failure reasons are passed to the next work phase
#   - This directs work toward specific gaps

set -e

PROJECT_PATH="$1"
MAX_ITERATIONS="${2:-10}"
WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Parse project path (supports subprojects)
# e.g., "my-project" or "my-project/subprojects/cache"
PROJECT_NAME=$(echo "$PROJECT_PATH" | cut -d'/' -f1)
SUBPROJECT_PATH=$(echo "$PROJECT_PATH" | cut -d'/' -f2-)
if [ "$SUBPROJECT_PATH" = "$PROJECT_NAME" ]; then
    SUBPROJECT_PATH=""
    FULL_PROJECT_DIR="$WORKSPACE_DIR/projects/$PROJECT_NAME"
else
    FULL_PROJECT_DIR="$WORKSPACE_DIR/projects/$PROJECT_PATH"
fi

# Validate inputs
if [ -z "$PROJECT_PATH" ]; then
    echo "Usage: $0 <project-path> [max-iterations]"
    echo ""
    echo "Examples:"
    echo "  $0 my-project                        # Top-level project"
    echo "  $0 my-project/subprojects/cache      # Subproject"
    exit 1
fi

if [ ! -f "$FULL_PROJECT_DIR/OBJECTIVE.md" ]; then
    echo "Error: Project not found at $FULL_PROJECT_DIR"
    echo "OBJECTIVE.md missing"
    exit 1
fi

# Check for standard build/test scripts
BUILD_SCRIPT="$FULL_PROJECT_DIR/build.sh"
TEST_SCRIPT="$FULL_PROJECT_DIR/test.sh"

if [ ! -f "$BUILD_SCRIPT" ]; then
    echo "Warning: No build.sh found at $BUILD_SCRIPT"
    echo "External build verification will be skipped."
    BUILD_SCRIPT=""
fi

if [ ! -f "$TEST_SCRIPT" ]; then
    echo "Warning: No test.sh found at $TEST_SCRIPT"
    echo "External test verification will be skipped."
    TEST_SCRIPT=""
fi

if [ -z "$BUILD_SCRIPT" ] && [ -z "$TEST_SCRIPT" ]; then
    echo ""
    echo "WARNING: No build.sh or test.sh found."
    echo "External verification disabled - relying solely on Claude's claims."
    echo "For rigorous verification, create:"
    echo "  $FULL_PROJECT_DIR/build.sh  - exits 0 on success"
    echo "  $FULL_PROJECT_DIR/test.sh   - exits 0 on success, outputs pass/fail counts"
    echo ""
fi

echo "=== Unattended Execution with Rigorous Verification ==="
echo "Project: $PROJECT_PATH"
echo "Directory: $FULL_PROJECT_DIR"
echo "Max iterations: $MAX_ITERATIONS"
echo ""

# Create run log
RUN_LOG="$FULL_PROJECT_DIR/run-$(date +%Y%m%d-%H%M%S).log"
echo "Run log: $RUN_LOG"
echo ""

# Track verification feedback for next work phase
VERIFICATION_FEEDBACK=""

# Verification phase prompt - this is the rigorous, skeptical check
VERIFY_PROMPT='
/project-start '"$PROJECT_PATH"'

You are in the VERIFICATION PHASE. Your job is to SKEPTICALLY verify whether ALL objectives are FULLY met.

## Your Mindset
- Assume the objective is NOT complete until you have concrete evidence for EVERY criterion
- Look for gaps, edge cases, missing functionality
- Do not trust claims in LOG.md - verify independently
- Be adversarial: actively try to find reasons the work is incomplete

## Verification Protocol

### Step 1: Run Project Check
Run /project-check to verify structural integrity.
If it fails, output "INCOMPLETE: project-check failed - [details]" and stop.

### Step 2: Read ALL Source Files
Use Glob to find ALL source files in the project (e.g., **/*.rs, **/*.ts, **/*.py).
Read EVERY file. You must see the actual implementation, not just trust that it exists.
List the files you read.

### Step 3: Read OBJECTIVE.md
Extract EVERY success criterion (SC-N format).
List them explicitly.

### Step 4: Run Build and Tests
Run build commands. Capture exact command and exit code.
Run test commands. Capture exact command and pass/fail counts.

### Step 5: Verify Each Criterion WITH EVIDENCE
For EACH criterion, provide:

```
SC-N: [criterion text]
Status: MET | NOT MET
Evidence: [REQUIRED - concrete evidence below]
  - Command: [exact command run]
  - Output: [relevant output or measurement]
  - File refs: [file:line if applicable]
Gaps: [what is missing, or "none"]
```

Evidence must be CONCRETE:
- For build: exact command + exit code
- For tests: command + "N/M passed"
- For measurements: actual numbers from running commands
- For code presence: file:line references
- "no evidence" means NOT MET

### Step 6: Final Judgment

Count: X of Y criteria met WITH EVIDENCE.

If ALL criteria have status MET with concrete evidence, output:

```
VERIFIED: ALL_CRITERIA_MET

Evidence Summary:
- Build: [command] → exit [code]
- Tests: [command] → [N/M] passed
- SC-1: [concrete evidence]
- SC-2: [concrete evidence]
...
```

If ANY criterion lacks concrete evidence, output:
  "INCOMPLETE: [specific list of unmet criteria and what evidence is missing]"

The INCOMPLETE message will be passed to the next work phase, so be specific and actionable.
Example: "INCOMPLETE: SC-2 not met - no error handling for network timeouts in client.rs; SC-4 not met - test coverage is 45%, required 80%"
'

for i in $(seq 1 $MAX_ITERATIONS); do
    echo "========================================" | tee -a "$RUN_LOG"
    echo "=== Iteration $i of $MAX_ITERATIONS ===" | tee -a "$RUN_LOG"
    echo "========================================" | tee -a "$RUN_LOG"

    # === WORK PHASE ===
    echo "" | tee -a "$RUN_LOG"
    echo "--- WORK PHASE ---" | tee -a "$RUN_LOG"
    echo "Started: $(date)" | tee -a "$RUN_LOG"

    # Build work prompt with feedback from previous verification
    if [ -z "$VERIFICATION_FEEDBACK" ]; then
        FEEDBACK_SECTION="This is the first iteration. No previous verification feedback."
    else
        FEEDBACK_SECTION="## Previous Verification Feedback

The previous verification phase found these issues that MUST be addressed:

$VERIFICATION_FEEDBACK

Focus on fixing these specific issues first."
    fi

    WORK_PROMPT='/project-start '"$PROJECT_PATH"'

You are in the WORK PHASE. Your job is to make progress toward the objectives.

'"$FEEDBACK_SECTION"'

## Instructions

1. Read OBJECTIVE.md - understand ALL success criteria
2. Read LOG.md - understand what has been done
3. If there is verification feedback above, address those specific issues FIRST
4. Otherwise, assess current state against each criterion and work on incomplete items

For each criterion that is NOT yet met:
- Implement what is needed
- Write tests if applicable
- Ensure edge cases are handled
- Update LOG.md with what you did

Requirements:
- Create LOG.md entry before any commit
- Commit your work before stopping
- Be thorough - partial implementations are not acceptable
- Address ALL issues from verification feedback if present

If you encounter a blocker you cannot resolve, output "BLOCKED: <reason>" and stop.

When you have made progress, stop. Do NOT claim completion - that is determined by the verification phase.
'

    WORK_OUTPUT=$(cd "$WORKSPACE_DIR" && claude --dangerously-skip-permissions -p "$WORK_PROMPT" 2>&1) || true
    echo "$WORK_OUTPUT" >> "$RUN_LOG"

    # Check for blocker during work
    if echo "$WORK_OUTPUT" | grep -q "BLOCKED:"; then
        echo "" | tee -a "$RUN_LOG"
        echo "=== BLOCKED ===" | tee -a "$RUN_LOG"
        echo "$WORK_OUTPUT" | grep "BLOCKED:" | tee -a "$RUN_LOG"
        exit 1
    fi

    echo "Work phase complete" | tee -a "$RUN_LOG"

    # Brief pause before verification
    sleep 2

    # === VERIFICATION PHASE ===
    echo "" | tee -a "$RUN_LOG"
    echo "--- VERIFICATION PHASE ---" | tee -a "$RUN_LOG"
    echo "Started: $(date)" | tee -a "$RUN_LOG"

    VERIFY_OUTPUT=$(cd "$WORKSPACE_DIR" && claude --dangerously-skip-permissions -p "$VERIFY_PROMPT" 2>&1) || true
    echo "$VERIFY_OUTPUT" >> "$RUN_LOG"

    # Check verification result
    if echo "$VERIFY_OUTPUT" | grep -q "VERIFIED: ALL_CRITERIA_MET"; then
        # Evidence Protocol: Require Evidence Summary block
        if echo "$VERIFY_OUTPUT" | grep -q "Evidence Summary:"; then
            # Extract Claude's evidence claim
            EVIDENCE=$(echo "$VERIFY_OUTPUT" | grep -A 20 "Evidence Summary:" | head -20)

            echo "" | tee -a "$RUN_LOG"
            echo "=== EXTERNAL VERIFICATION ===" | tee -a "$RUN_LOG"
            echo "Claude claims completion. Running independent checks..." | tee -a "$RUN_LOG"

            EXTERNAL_FAILED=""

            # Run build.sh independently if it exists
            if [ -n "$BUILD_SCRIPT" ] && [ -x "$BUILD_SCRIPT" ]; then
                echo "" | tee -a "$RUN_LOG"
                echo "Running: $BUILD_SCRIPT" | tee -a "$RUN_LOG"
                BUILD_OUTPUT=$(cd "$FULL_PROJECT_DIR" && ./build.sh 2>&1)
                BUILD_EXIT=$?
                echo "$BUILD_OUTPUT" >> "$RUN_LOG"

                if [ "$BUILD_EXIT" -ne 0 ]; then
                    echo "EXTERNAL BUILD FAILED (exit $BUILD_EXIT)" | tee -a "$RUN_LOG"
                    EXTERNAL_FAILED="Build failed with exit code $BUILD_EXIT. Claude claimed success but external build.sh disagrees."
                else
                    echo "EXTERNAL BUILD PASSED (exit 0)" | tee -a "$RUN_LOG"
                fi
            fi

            # Run test.sh independently if it exists (and build passed)
            if [ -z "$EXTERNAL_FAILED" ] && [ -n "$TEST_SCRIPT" ] && [ -x "$TEST_SCRIPT" ]; then
                echo "" | tee -a "$RUN_LOG"
                echo "Running: $TEST_SCRIPT" | tee -a "$RUN_LOG"
                TEST_OUTPUT=$(cd "$FULL_PROJECT_DIR" && ./test.sh 2>&1)
                TEST_EXIT=$?
                echo "$TEST_OUTPUT" >> "$RUN_LOG"

                if [ "$TEST_EXIT" -ne 0 ]; then
                    echo "EXTERNAL TESTS FAILED (exit $TEST_EXIT)" | tee -a "$RUN_LOG"
                    # Extract any useful info from test output
                    FAIL_INFO=$(echo "$TEST_OUTPUT" | grep -iE "fail|error|FAILED" | head -5)
                    EXTERNAL_FAILED="Tests failed with exit code $TEST_EXIT. Claude claimed success but external test.sh disagrees. Failures: $FAIL_INFO"
                else
                    echo "EXTERNAL TESTS PASSED (exit 0)" | tee -a "$RUN_LOG"
                fi
            fi

            # If external verification failed, feed back to work phase
            if [ -n "$EXTERNAL_FAILED" ]; then
                echo "" | tee -a "$RUN_LOG"
                echo "=== EXTERNAL VERIFICATION FAILED ===" | tee -a "$RUN_LOG"
                echo "$EXTERNAL_FAILED" | tee -a "$RUN_LOG"
                VERIFICATION_FEEDBACK="EXTERNAL VERIFICATION FAILED: $EXTERNAL_FAILED"
            else
                # All checks passed - accept success
                echo "" | tee -a "$RUN_LOG"
                echo "========================================" | tee -a "$RUN_LOG"
                echo "=== SUCCESS (externally verified) ===" | tee -a "$RUN_LOG"
                echo "========================================" | tee -a "$RUN_LOG"
                echo "All criteria verified after $i iteration(s)" | tee -a "$RUN_LOG"
                if [ -n "$BUILD_SCRIPT" ] || [ -n "$TEST_SCRIPT" ]; then
                    echo "External verification: PASSED" | tee -a "$RUN_LOG"
                else
                    echo "External verification: SKIPPED (no build.sh/test.sh)" | tee -a "$RUN_LOG"
                fi
                echo "" | tee -a "$RUN_LOG"
                echo "Claude's Evidence:" | tee -a "$RUN_LOG"
                echo "$EVIDENCE" | tee -a "$RUN_LOG"
                echo "" | tee -a "$RUN_LOG"
                echo "Finished: $(date)" | tee -a "$RUN_LOG"
                exit 0
            fi
        else
            # VERIFIED claimed but no evidence - treat as incomplete
            echo "" | tee -a "$RUN_LOG"
            echo "=== EVIDENCE MISSING ===" | tee -a "$RUN_LOG"
            echo "Verification claimed complete but no Evidence Summary block found." | tee -a "$RUN_LOG"
            echo "Per Evidence Protocol, claims without evidence are unverified." | tee -a "$RUN_LOG"
            VERIFICATION_FEEDBACK="EVIDENCE MISSING: Verification claimed ALL_CRITERIA_MET but did not provide Evidence Summary block. Re-run verification with concrete evidence for each criterion (commands run, outputs, measurements)."
        fi
    fi

    # Extract incompleteness reason for feedback to next work phase
    # Capture everything after "INCOMPLETE:" until end of that logical block
    VERIFICATION_FEEDBACK=$(echo "$VERIFY_OUTPUT" | grep -A 50 "INCOMPLETE:" | head -50)

    if [ -z "$VERIFICATION_FEEDBACK" ]; then
        # Fallback: try to extract any useful context about what's missing
        VERIFICATION_FEEDBACK="Verification did not pass. Review the verification output for details."
    fi

    echo "" | tee -a "$RUN_LOG"
    echo "Verification feedback for next iteration:" | tee -a "$RUN_LOG"
    echo "$VERIFICATION_FEEDBACK" | tee -a "$RUN_LOG"
    echo "" | tee -a "$RUN_LOG"

    # Brief pause between iterations
    sleep 2
done

echo "" | tee -a "$RUN_LOG"
echo "========================================" | tee -a "$RUN_LOG"
echo "=== MAX ITERATIONS REACHED ===" | tee -a "$RUN_LOG"
echo "========================================" | tee -a "$RUN_LOG"
echo "Stopped after $MAX_ITERATIONS iterations" | tee -a "$RUN_LOG"
echo "" | tee -a "$RUN_LOG"
echo "Last verification feedback:" | tee -a "$RUN_LOG"
echo "$VERIFICATION_FEEDBACK" | tee -a "$RUN_LOG"
echo "" | tee -a "$RUN_LOG"
echo "Review $RUN_LOG and project LOG.md" | tee -a "$RUN_LOG"
exit 1
