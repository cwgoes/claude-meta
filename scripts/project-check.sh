#!/bin/bash
# Hierarchical project verification with context-bounded verification
#
# CORE MODEL: The objective hierarchy IS the verification structure.
#
# - Leaf criteria (≤80KB files) → verified directly by Claude
# - Composite criteria (>80KB files) → IS a subproject with child criteria
# - 1:1 mapping: one oversized SC-N = one subproject
# - Composition verified: child criteria → parent criterion
#
# Key invariants:
# - Context Budget: Every leaf criterion's files must total ≤80KB
# - Composition: Composite criteria pass only if all children pass AND compose
# - Coverage: Every source file maps to exactly one criterion
#
# Usage:
#   ./scripts/project-check.sh <project-path> [flags]
#
# Flags:
#   --structure-only    Skip all content verification
#   --no-build          Skip build.sh verification
#   --no-test           Skip test.sh verification
#   --no-orphans        Skip orphan detection
#   --no-subprojects    Skip subproject recursion
#   --verbose           Show detailed output
#   --json              Output results as JSON
#
# Exit codes:
#   0 - PASS (all checks passed)
#   1 - FAIL (violations found)
#   2 - ERROR (script error, invalid input)
#
# Requirements:
#   - OBJECTIVE.md with SC-N sections containing **Files:** lists
#   - Optional: build.sh, test.sh for external verification
#   - Required: claude CLI for content verification

set -euo pipefail

# ============================================
# Configuration
# ============================================

# Handle --help as first argument
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 <project-path> [flags]"
    echo ""
    echo "Flags:"
    echo "  --structure-only      Skip all content verification"
    echo "  --no-build            Skip build.sh verification"
    echo "  --no-test             Skip test.sh verification"
    echo "  --no-orphans          Skip orphan detection"
    echo "  --no-subprojects      Skip subproject recursion"
    echo "  --no-skeptical        Skip multi-pass skeptical verification"
    echo "  --no-criterion-tests  Skip per-criterion test verification"
    echo "  --no-benchmarks       Skip benchmark threshold verification"
    echo "  --no-doc-audit        Skip benchmark documentation audit"
    echo "  --allow-unverified    Allow PASS when verification infrastructure unavailable"
    echo "  --regression-threshold N  Regression threshold percent (default: 20)"
    echo "  --skeptical-passes N  Number of skeptical passes (default: 3)"
    echo "  --verbose             Show detailed output"
    echo "  --json                Output results as JSON"
    exit 0
fi

PROJECT_PATH="${1:-}"
shift || true

STRUCTURE_ONLY=false
SKIP_BUILD=false
SKIP_TEST=false
SKIP_ORPHANS=false
SKIP_SUBPROJECTS=false
SKIP_SKEPTICAL=false
SKIP_CRITERION_TESTS=false
SKIP_BENCHMARKS=false
SKIP_DOC_AUDIT=false
SKEPTICAL_PASSES=3
REGRESSION_THRESHOLD=20
ALLOW_UNVERIFIED=false
VERBOSE=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --structure-only) STRUCTURE_ONLY=true; shift ;;
        --no-build) SKIP_BUILD=true; shift ;;
        --no-test) SKIP_TEST=true; shift ;;
        --no-orphans) SKIP_ORPHANS=true; shift ;;
        --no-subprojects) SKIP_SUBPROJECTS=true; shift ;;
        --no-skeptical) SKIP_SKEPTICAL=true; shift ;;
        --no-criterion-tests) SKIP_CRITERION_TESTS=true; shift ;;
        --no-benchmarks) SKIP_BENCHMARKS=true; shift ;;
        --no-doc-audit) SKIP_DOC_AUDIT=true; shift ;;
        --allow-unverified) ALLOW_UNVERIFIED=true; shift ;;
        --skeptical-passes)
            shift
            SKEPTICAL_PASSES="${1:-3}"
            shift
            ;;
        --regression-threshold)
            shift
            REGRESSION_THRESHOLD="${1:-20}"
            shift
            ;;
        --verbose) VERBOSE=true; shift ;;
        --json) JSON_OUTPUT=true; shift ;;
        -h|--help)
            echo "Usage: $0 <project-path> [flags]"
            echo ""
            echo "Flags:"
            echo "  --structure-only      Skip all content verification"
            echo "  --no-build            Skip build.sh verification"
            echo "  --no-test             Skip test.sh verification"
            echo "  --no-orphans          Skip orphan detection"
            echo "  --no-subprojects      Skip subproject recursion"
            echo "  --no-skeptical        Skip multi-pass skeptical verification"
            echo "  --no-criterion-tests  Skip per-criterion test verification"
            echo "  --no-benchmarks       Skip benchmark threshold verification"
            echo "  --no-doc-audit        Skip benchmark documentation audit"
            echo "  --allow-unverified    Allow PASS when verification infrastructure unavailable"
            echo "  --regression-threshold N  Regression threshold percent (default: 20)"
            echo "  --skeptical-passes N  Number of skeptical passes (default: 3)"
            echo "  --verbose             Show detailed output"
            echo "  --json                Output results as JSON"
            exit 0
            ;;
        *) echo "Unknown flag: $1"; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Resolve project path
if [[ -z "$PROJECT_PATH" ]]; then
    echo "Error: Project path required"
    echo "Usage: $0 <project-path> [flags]"
    exit 2
fi

if [[ "$PROJECT_PATH" == /* ]]; then
    FULL_PROJECT_DIR="$PROJECT_PATH"
else
    FULL_PROJECT_DIR="$WORKSPACE_DIR/projects/$PROJECT_PATH"
fi

if [[ ! -d "$FULL_PROJECT_DIR" ]]; then
    echo "Error: Project directory not found: $FULL_PROJECT_DIR"
    exit 2
fi

# ============================================
# State tracking
# ============================================

RESULTS_DIR="$FULL_PROJECT_DIR/.project-metadata"
mkdir -p "$RESULTS_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CHECK_DIR="$RESULTS_DIR/check-$TIMESTAMP"
mkdir -p "$CHECK_DIR"

declare -a VIOLATIONS=()
declare -a WARNINGS=()
declare -a PASSES=()

# Criteria tracking
declare -A CRITERIA_TYPE=()      # SC-N -> leaf|composite
declare -A CRITERIA_SIZE=()      # SC-N -> total bytes
declare -A CRITERIA_SUBPROJECT=() # SC-N -> subproject path (if composite)
declare -A CRITERIA_FILES=()     # SC-N -> comma-separated files
declare -A CRITERIA_TESTS=()     # SC-N -> test command | test files
declare -A CRITERIA_BENCHMARKS=() # SC-N -> benchmark command | thresholds
declare -A CRITERIA_STATUS=()     # SC-N -> status text (Done, In Progress, etc.)
declare -A CRITERIA_TEST_RESULT=() # SC-N -> PASS|FAIL|NO_TESTS|SKIPPED

log() {
    if $VERBOSE || [[ "${2:-}" == "always" ]]; then
        echo "$1"
    fi
}

log_pass() {
    PASSES+=("$1")
    log "✓ $1"
}

log_warn() {
    WARNINGS+=("$1")
    log "⚠ $1" "always"
}

log_fail() {
    VIOLATIONS+=("$1")
    log "✗ $1" "always"
}

# ============================================
# Phase 1: Structural Checks
# ============================================

phase1_structural() {
    log "=== Phase 1: Structural Checks ===" "always"

    # Check OBJECTIVE.md
    if [[ -f "$FULL_PROJECT_DIR/OBJECTIVE.md" ]]; then
        log_pass "OBJECTIVE.md exists"
    else
        log_fail "STRUCTURE: OBJECTIVE.md missing"
        return 1
    fi

    # Check LOG.md
    if [[ -f "$FULL_PROJECT_DIR/LOG.md" ]]; then
        log_pass "LOG.md exists"
    else
        log_fail "STRUCTURE: LOG.md missing"
    fi

    # Check git repository
    if [[ -d "$FULL_PROJECT_DIR/.git" ]] || git -C "$FULL_PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
        log_pass "Git repository exists"
    else
        log_fail "STRUCTURE: Not in a git repository"
    fi

    # Check depth (count 'subprojects' or follow parent_criterion chain)
    local depth=1
    local obj_file="$FULL_PROJECT_DIR/OBJECTIVE.md"
    if grep -q "^parent_criterion:" "$obj_file" 2>/dev/null || \
       sed -n '1,10p' "$obj_file" 2>/dev/null | grep -q "parent_criterion:"; then
        depth=2
        # Could trace further but 3 levels max
    fi

    if [[ $depth -le 3 ]]; then
        log_pass "Depth: $depth (≤3 limit)"
    else
        log_fail "STRUCTURE: Depth $depth exceeds limit of 3"
    fi

    log ""
}

# ============================================
# Phase 2: Parse SC-N → Files Mapping
# ============================================

phase2_parse_criteria() {
    log "=== Phase 2: Parse Criteria ===" "always"

    local objective_file="$FULL_PROJECT_DIR/OBJECTIVE.md"
    local criteria_file="$CHECK_DIR/criteria.txt"
    local infrastructure_file="$CHECK_DIR/infrastructure.txt"

    local current_sc=""
    local in_files=false
    local files_for_sc=""
    local subproject_for_sc=""
    local tests_for_sc=""
    local benchmark_for_sc=""
    local status_for_sc=""

    > "$criteria_file"
    > "$infrastructure_file"

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Detect SC-N header (matches SC-1, SC-2-1, etc.)
        if [[ "$line" =~ ^###[[:space:]]+(SC-[0-9]+(-[0-9]+)?):[[:space:]]*(.*)$ ]]; then
            # Save previous SC if exists
            if [[ -n "$current_sc" ]]; then
                echo "$current_sc|$files_for_sc|$subproject_for_sc|$tests_for_sc|$benchmark_for_sc" >> "$criteria_file"
                CRITERIA_FILES["$current_sc"]="$files_for_sc"
                CRITERIA_SUBPROJECT["$current_sc"]="$subproject_for_sc"
                CRITERIA_TESTS["$current_sc"]="$tests_for_sc"
                CRITERIA_BENCHMARKS["$current_sc"]="$benchmark_for_sc"
                CRITERIA_STATUS["$current_sc"]="$status_for_sc"
            fi
            current_sc="${BASH_REMATCH[1]}"
            files_for_sc=""
            subproject_for_sc=""
            tests_for_sc=""
            benchmark_for_sc=""
            status_for_sc=""
            in_files=false

        # Detect Files: section
        elif [[ "$line" =~ ^\*\*Files:\*\* ]] || [[ "$line" =~ ^Files: ]]; then
            in_files=true

        # Detect Subproject: field
        elif [[ "$line" =~ ^\*\*Subproject:\*\*[[:space:]]*\`?([^\`]+)\`? ]]; then
            subproject_for_sc="${BASH_REMATCH[1]}"
            subproject_for_sc="${subproject_for_sc%/}"  # Remove trailing slash

        # Detect Tests: field (format: **Tests:** `command` | `test_files`)
        elif [[ "$line" =~ ^\*\*Tests:\*\*[[:space:]]*(.*) ]]; then
            tests_for_sc="${BASH_REMATCH[1]}"
            # Strip backticks if present
            tests_for_sc="${tests_for_sc//\`/}"

        # Detect Benchmark: field (format: **Benchmark:** `command` | metric < threshold, ...)
        elif [[ "$line" =~ ^\*\*Benchmark:\*\*[[:space:]]*(.*) ]]; then
            benchmark_for_sc="${BASH_REMATCH[1]}"
            # Strip backticks if present
            benchmark_for_sc="${benchmark_for_sc//\`/}"

        # Detect Status: field
        elif [[ "$line" =~ ^\*\*Status:\*\*[[:space:]]*(.*) ]]; then
            status_for_sc="${BASH_REMATCH[1]}"

        # Detect end of Files section
        elif [[ "$line" =~ ^\*\*[A-Z] ]] && [[ ! "$line" =~ ^\*\*Files ]] && [[ ! "$line" =~ ^\*\*Tests ]] && [[ ! "$line" =~ ^\*\*Benchmark ]]; then
            in_files=false

        # Detect Infrastructure section
        elif [[ "$line" =~ ^##[[:space:]]+Infrastructure ]]; then
            # Save last SC
            if [[ -n "$current_sc" ]]; then
                echo "$current_sc|$files_for_sc|$subproject_for_sc|$tests_for_sc|$benchmark_for_sc" >> "$criteria_file"
                CRITERIA_FILES["$current_sc"]="$files_for_sc"
                CRITERIA_SUBPROJECT["$current_sc"]="$subproject_for_sc"
                CRITERIA_TESTS["$current_sc"]="$tests_for_sc"
                CRITERIA_BENCHMARKS["$current_sc"]="$benchmark_for_sc"
                CRITERIA_STATUS["$current_sc"]="$status_for_sc"
                current_sc=""
                files_for_sc=""
                subproject_for_sc=""
                tests_for_sc=""
                benchmark_for_sc=""
                status_for_sc=""
            fi
            in_files=true

        # Collect file paths
        elif $in_files && [[ "$line" =~ ^-[[:space:]]+\`([^\`]+)\` ]]; then
            local file_path="${BASH_REMATCH[1]}"
            if [[ -n "$current_sc" ]]; then
                if [[ -n "$files_for_sc" ]]; then
                    files_for_sc="$files_for_sc,$file_path"
                else
                    files_for_sc="$file_path"
                fi
            else
                # Infrastructure file
                echo "$file_path" >> "$infrastructure_file"
            fi
        fi
    done < "$objective_file"

    # Save last SC
    if [[ -n "$current_sc" ]]; then
        echo "$current_sc|$files_for_sc|$subproject_for_sc|$tests_for_sc|$benchmark_for_sc" >> "$criteria_file"
        CRITERIA_FILES["$current_sc"]="$files_for_sc"
        CRITERIA_SUBPROJECT["$current_sc"]="$subproject_for_sc"
        CRITERIA_TESTS["$current_sc"]="$tests_for_sc"
        CRITERIA_BENCHMARKS["$current_sc"]="$benchmark_for_sc"
        CRITERIA_STATUS["$current_sc"]="$status_for_sc"
    fi

    # Report findings
    local criteria_count=$(wc -l < "$criteria_file" | tr -d ' ')
    local infra_count=$(wc -l < "$infrastructure_file" | tr -d ' ')

    log "Found $criteria_count criteria" "always"

    if [[ $criteria_count -eq 0 ]]; then
        log_fail "STRUCTURE: No SC-N criteria found in OBJECTIVE.md"
        log "  Expected format:" "always"
        log "    ### SC-1: Description" "always"
        log "    **Files:**" "always"
        log "    - \`path/to/file\` — purpose" "always"
        return 1
    fi

    if [[ $infra_count -gt 0 ]]; then
        log_pass "Infrastructure: $infra_count files"
    fi

    log ""
}

# ============================================
# Phase 3: Classify Criteria (leaf vs composite)
# ============================================

phase3_classify_criteria() {
    log "=== Phase 3: Classify Criteria ===" "always"

    local criteria_file="$CHECK_DIR/criteria.txt"
    local classified_file="$CHECK_DIR/criteria-classified.txt"
    local max_size=80000  # 80KB context budget

    > "$classified_file"

    while IFS='|' read -r sc files subproject tests benchmark; do
        [[ -z "$sc" ]] && continue

        # If has subproject, it's composite
        if [[ -n "$subproject" ]]; then
            CRITERIA_TYPE["$sc"]="composite"
            CRITERIA_SUBPROJECT["$sc"]="$subproject"
            echo "$sc|composite|$subproject|0" >> "$classified_file"
            log_pass "$sc: COMPOSITE (subproject: $subproject)"
            continue
        fi

        # Calculate total size of mapped files
        local total_size=0
        local file_count=0

        if [[ -n "$files" ]]; then
            IFS=',' read -ra FILE_ARRAY <<< "$files"
            for file_path in "${FILE_ARRAY[@]}"; do
                [[ -z "$file_path" ]] && continue

                # Expand glob patterns
                local expanded_files=()
                if [[ "$file_path" == *"*"* ]] || [[ "$file_path" == *"?"* ]]; then
                    while IFS= read -r matched_file; do
                        expanded_files+=("$matched_file")
                    done < <(cd "$FULL_PROJECT_DIR" && find . -path "./$file_path" -type f 2>/dev/null | sed 's|^\./||')
                else
                    expanded_files+=("$file_path")
                fi

                for exp_file in "${expanded_files[@]}"; do
                    local full_path="$FULL_PROJECT_DIR/$exp_file"
                    if [[ -f "$full_path" ]]; then
                        local file_size=$(wc -c < "$full_path" 2>/dev/null || echo "0")
                        file_size=${file_size//[^0-9]/}
                        total_size=$((total_size + file_size))
                        ((file_count++))
                    fi
                done
            done
        fi

        CRITERIA_SIZE["$sc"]=$total_size

        # Check context budget
        if [[ $total_size -gt $max_size ]]; then
            log_fail "CONTEXT_BUDGET: $sc files exceed 80KB ($total_size bytes) - decomposition required"
            CRITERIA_TYPE["$sc"]="violation"
            echo "$sc|violation||$total_size" >> "$classified_file"
        elif [[ $file_count -eq 0 ]]; then
            log_fail "COVERAGE: $sc has no files mapped"
            CRITERIA_TYPE["$sc"]="empty"
            echo "$sc|empty||0" >> "$classified_file"
        else
            CRITERIA_TYPE["$sc"]="leaf"
            echo "$sc|leaf||$total_size" >> "$classified_file"
            log_pass "$sc: LEAF ($file_count files, $total_size bytes)"
        fi

    done < "$criteria_file"

    log ""
}

# ============================================
# Phase 4: Deterministic Evidence (hard gate)
# ============================================
# Tests run FIRST. Results gate semantic verification in Phase 4.5.
# Done criteria without tests are violations (Evidence Invariant).

phase4_deterministic_evidence() {
    if $STRUCTURE_ONLY || $SKIP_CRITERION_TESTS; then
        log "=== Phase 4: Deterministic Evidence (SKIPPED) ===" "always"
        log ""
        return 0
    fi

    log "=== Phase 4: Deterministic Evidence ===" "always"

    local criteria_file="$CHECK_DIR/criteria.txt"
    local tests_run=0
    local tests_passed=0
    local tests_failed=0
    local evidence_violations=0

    while IFS='|' read -r sc files subproject tests benchmark; do
        [[ -z "$sc" ]] && continue

        # Only check leaf criteria
        if [[ "${CRITERIA_TYPE[$sc]:-}" != "leaf" ]]; then
            CRITERIA_TEST_RESULT["$sc"]="SKIPPED"
            continue
        fi

        local status="${CRITERIA_STATUS[$sc]:-}"
        local status_lower
        status_lower=$(echo "$status" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

        # Evidence gate: Done criteria MUST have tests
        if [[ -z "$tests" ]]; then
            CRITERIA_TEST_RESULT["$sc"]="NO_TESTS"
            if [[ "$status_lower" == *"done"* ]] || [[ "$status_lower" == *"complete"* ]] || [[ "$status" == *"✅"* ]]; then
                ((evidence_violations++))
                log_fail "EVIDENCE: $sc marked Done but has no **Tests:** field — deterministic evidence required"
            else
                log "  $sc: No tests defined (status: ${status:-unset})"
            fi
            continue
        fi

        # Parse test field: "command | test_files" or just "command"
        local test_command=""
        local test_files=""

        if [[ "$tests" == *"|"* ]]; then
            test_command="${tests%%|*}"
            test_files="${tests#*|}"
            test_command="${test_command## }"
            test_command="${test_command%% }"
            test_files="${test_files## }"
            test_files="${test_files%% }"
        else
            test_command="$tests"
        fi

        # Verify test file(s) exist if specified
        if [[ -n "$test_files" ]]; then
            local missing_test_files=""
            IFS=',' read -ra TEST_FILE_ARRAY <<< "${test_files//|/,}"
            for test_file in "${TEST_FILE_ARRAY[@]}"; do
                test_file="${test_file## }"
                test_file="${test_file%% }"
                [[ -z "$test_file" ]] && continue
                local full_test_path="$FULL_PROJECT_DIR/$test_file"
                if [[ ! -f "$full_test_path" ]]; then
                    missing_test_files+="$test_file "
                fi
            done

            if [[ -n "$missing_test_files" ]]; then
                log_warn "$sc: Test file(s) missing: $missing_test_files"
            fi
        fi

        # Run test command
        if [[ -n "$test_command" ]]; then
            ((tests_run++))
            log "  $sc: Running tests..."

            local test_log="$CHECK_DIR/$sc-tests.log"
            if (cd "$FULL_PROJECT_DIR" && eval "$test_command" > "$test_log" 2>&1); then
                ((tests_passed++))
                CRITERIA_TEST_RESULT["$sc"]="PASS"
                log_pass "$sc: Tests passed"
            else
                local exit_code=$?
                ((tests_failed++))
                CRITERIA_TEST_RESULT["$sc"]="FAIL"
                log_fail "CRITERION_TEST: $sc tests failed (exit $exit_code)"
                log "    See: $test_log"
            fi
        fi

    done < "$criteria_file"

    if [[ $tests_run -eq 0 && $evidence_violations -eq 0 ]]; then
        log "  No criterion-level tests defined"
    else
        log "  Tests: $tests_passed/$tests_run passed, $evidence_violations evidence violation(s)"
    fi

    log ""
}

# ============================================
# Phase 4.5: Semantic Verification (gated, fail-closed)
# ============================================
# Gated by Phase 4 test results. Fail-closed on infrastructure errors.
# Much more skeptical: hostile auditor, burden reversal, minimal counterexample.

phase4_5_semantic_verification() {
    if $STRUCTURE_ONLY; then
        log "=== Phase 4.5: Semantic Verification (SKIPPED) ===" "always"
        log ""
        return 0
    fi

    log "=== Phase 4.5: Semantic Verification ===" "always"

    # Fail-closed: Claude CLI is REQUIRED unless --allow-unverified
    if ! command -v claude &> /dev/null; then
        if $ALLOW_UNVERIFIED; then
            log_warn "claude CLI not found — semantic verification skipped (--allow-unverified)"
        else
            log_fail "INFRA: claude CLI required for semantic verification (use --allow-unverified to skip)"
        fi
        log ""
        return 0
    fi

    local criteria_file="$CHECK_DIR/criteria.txt"

    while IFS='|' read -r sc files subproject tests benchmark; do
        [[ -z "$sc" ]] && continue

        # Only verify LEAF criteria
        if [[ "${CRITERIA_TYPE[$sc]:-}" != "leaf" ]]; then
            continue
        fi

        [[ -z "$files" ]] && continue

        # Gate: if tests failed, criterion is NOT_MET — skip expensive Claude call
        local test_result="${CRITERIA_TEST_RESULT[$sc]:-NO_TESTS}"
        if [[ "$test_result" == "FAIL" ]]; then
            log_fail "CONTENT: $sc — tests failed, criterion is NOT_MET"
            continue
        fi

        log "Verifying $sc..." "always"

        # Expand glob patterns
        local expanded_files=""
        IFS=',' read -ra FILE_PATTERNS <<< "$files"
        for pattern in "${FILE_PATTERNS[@]}"; do
            if [[ "$pattern" == *"*"* ]] || [[ "$pattern" == *"?"* ]]; then
                while IFS= read -r matched_file; do
                    [[ -n "$expanded_files" ]] && expanded_files+=","
                    expanded_files+="$matched_file"
                done < <(cd "$FULL_PROJECT_DIR" && find . -path "./$pattern" -type f 2>/dev/null | sed 's|^\./||')
            else
                [[ -n "$expanded_files" ]] && expanded_files+=","
                expanded_files+="$pattern"
            fi
        done

        # Build file contents
        local file_contents=""
        local missing_files=""
        local file_count=0

        IFS=',' read -ra FILE_ARRAY <<< "$expanded_files"
        for file_path in "${FILE_ARRAY[@]}"; do
            [[ -z "$file_path" ]] && continue
            local full_path="$FULL_PROJECT_DIR/$file_path"
            if [[ -f "$full_path" ]]; then
                local line_count=$(wc -l < "$full_path" 2>/dev/null || echo "0")
                line_count=${line_count//[^0-9]/}

                if [[ $line_count -gt 2000 ]]; then
                    file_contents+="
### File: $file_path (TRUNCATED - $line_count lines, showing first 2000)
\`\`\`
$(head -2000 "$full_path")
\`\`\`
"
                else
                    file_contents+="
### File: $file_path
\`\`\`
$(cat "$full_path")
\`\`\`
"
                fi
                ((file_count++))
            else
                missing_files+="$file_path "
                log_fail "FILE_MISSING: $sc references $file_path but file does not exist"
            fi
        done

        if [[ -n "$missing_files" ]]; then
            log "  Missing: $missing_files"
        fi

        if [[ $file_count -eq 0 ]]; then
            log_fail "CONTENT: $sc has no readable files"
            continue
        fi

        # Extract criterion description
        local sc_line
        sc_line=$(grep -E "^### $sc:" "$FULL_PROJECT_DIR/OBJECTIVE.md" || echo "$sc: (description not found)")

        # Determine evidence cap based on test results
        local evidence_cap="MET"
        if [[ "$test_result" == "NO_TESTS" ]]; then
            local status="${CRITERIA_STATUS[$sc]:-}"
            local status_lower
            status_lower=$(echo "$status" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            if [[ "$status_lower" == *"done"* ]] || [[ "$status_lower" == *"complete"* ]] || [[ "$status" == *"✅"* ]]; then
                evidence_cap="PARTIAL"  # No tests + Done → capped
            fi
        fi

        # Pass 1: Bounded verification prompt (skeptical framing)
        local verify_prompt="You are verifying a single success criterion. Be thorough and skeptical — do not give the benefit of the doubt. Require positive evidence for every aspect of the criterion.

## Criterion
$sc_line

## Files Claimed to Implement This Criterion ($file_count files)
$file_contents

## Task

1. Read each file completely
2. Determine if the code FULLY implements the criterion — not approximately, but completely
3. Identify specific evidence (function names, logic, file:line) for each aspect
4. If ANY aspect of the criterion is not demonstrably implemented, the status is PARTIAL or NOT_MET
5. Do not infer implementation from naming or structure — verify logic

## Output Format (JSON only, no markdown)

{
  \"criterion\": \"$sc\",
  \"status\": \"MET\" | \"PARTIAL\" | \"NOT_MET\",
  \"evidence\": [
    {\"file\": \"path\", \"line\": 0, \"description\": \"what it does\"}
  ],
  \"gaps\": [\"what is missing if any\"],
  \"confidence\": \"HIGH\" | \"MEDIUM\" | \"LOW\"
}"

        local result_file="$CHECK_DIR/$sc.json"

        # Run bounded verification — fail-closed on error
        if ! claude --dangerously-skip-permissions -p "$verify_prompt" > "$result_file" 2>&1; then
            if $ALLOW_UNVERIFIED; then
                log_warn "$sc: Verification failed (claude error) — allowed by --allow-unverified"
            else
                log_fail "VERIFY: $sc — claude verification failed (non-zero exit)"
            fi
            continue
        fi

        # Extract JSON — fail-closed on parse error
        local json_content
        json_content=$(sed -n '/^{/,/^}/p' "$result_file" | head -100)
        if [[ -z "$json_content" ]]; then
            json_content=$(grep -A 1000 '{' "$result_file" | grep -B 1000 '}' || true)
        fi

        if [[ -z "$json_content" ]]; then
            if $ALLOW_UNVERIFIED; then
                log_warn "$sc: Could not parse verification output — allowed by --allow-unverified"
            else
                log_fail "PARSE: $sc — verification produced unparseable output"
            fi
            continue
        fi

        echo "$json_content" > "$result_file.clean"

        local status
        status=$(jq -r '.status // "UNKNOWN"' "$result_file.clean" 2>/dev/null || echo "PARSE_ERROR")
        local confidence
        confidence=$(jq -r '.confidence // "UNKNOWN"' "$result_file.clean" 2>/dev/null || echo "UNKNOWN")

        if [[ "$status" == "PARSE_ERROR" ]] || [[ "$status" == "UNKNOWN" ]]; then
            if $ALLOW_UNVERIFIED; then
                log_warn "$sc: Verification status unparseable — allowed by --allow-unverified"
            else
                log_fail "PARSE: $sc — verification returned unparseable status"
            fi
            continue
        fi

        local final_status="$status"
        local skeptical_gaps=""

        # Multi-pass skeptical verification (only if Pass 1 = MET and skeptical enabled)
        if [[ "$status" == "MET" ]] && ! $SKIP_SKEPTICAL && [[ $SKEPTICAL_PASSES -gt 0 ]]; then
            log "  Running skeptical verification ($SKEPTICAL_PASSES passes)..."

            local significant_gaps_found=false

            # Pass 2: Hostile auditor
            if [[ $SKEPTICAL_PASSES -ge 1 ]]; then
                local adversarial_prompt="You are a hostile code auditor. Your professional reputation depends on finding real deficiencies. False negatives (missed flaws) are career-ending. False positives merely require retraction.

Find specific, concrete ways this implementation FAILS to satisfy the criterion. Do NOT hedge. Do NOT soften language. Either the flaw exists or it does not.

## Criterion
$sc_line

## Files
$file_contents

## Task
For each flaw found:
1. Cite the exact file:line
2. State what the criterion requires at that point
3. State what the code actually does (or fails to do)
4. Rate severity: CRITICAL (criterion not met) | SIGNIFICANT (partial gap) | MINOR (cosmetic)

If after exhaustive review you genuinely find no flaws, state: \"No significant deficiencies found\" — but only if this is true under oath.

## Output Format (JSON only)
{
  \"significant_gaps\": [\"CRITICAL/SIGNIFICANT gaps with file:line references\"],
  \"minor_issues\": [\"MINOR issues\"],
  \"verdict\": \"GAPS_FOUND\" | \"NO_SIGNIFICANT_GAPS\"
}"

                local adversarial_file="$CHECK_DIR/$sc-adversarial.json"
                if claude --dangerously-skip-permissions -p "$adversarial_prompt" > "$adversarial_file" 2>&1; then
                    local adv_json
                    adv_json=$(sed -n '/^{/,/^}/p' "$adversarial_file" | head -100)
                    if [[ -z "$adv_json" ]]; then
                        adv_json=$(grep -A 1000 '{' "$adversarial_file" | grep -B 1000 '}' || true)
                    fi
                    if [[ -n "$adv_json" ]]; then
                        echo "$adv_json" > "$adversarial_file.clean"
                        local adv_verdict
                        adv_verdict=$(jq -r '.verdict // "UNKNOWN"' "$adversarial_file.clean" 2>/dev/null || echo "UNKNOWN")
                        if [[ "$adv_verdict" == "GAPS_FOUND" ]]; then
                            significant_gaps_found=true
                            skeptical_gaps=$(jq -r '.significant_gaps[0] // "unspecified"' "$adversarial_file.clean" 2>/dev/null)
                            log "    Pass 2 (hostile auditor): GAPS FOUND"
                        else
                            log "    Pass 2 (hostile auditor): no significant gaps"
                        fi
                    else
                        # Parse failure in skeptical pass — fail-closed
                        significant_gaps_found=true
                        skeptical_gaps="pass 2 output unparseable (fail-closed)"
                        log "    Pass 2 (hostile auditor): UNPARSEABLE — fail-closed, gaps assumed"
                    fi
                else
                    significant_gaps_found=true
                    skeptical_gaps="pass 2 claude call failed (fail-closed)"
                    log "    Pass 2 (hostile auditor): FAILED — fail-closed, gaps assumed"
                fi
            fi

            # Pass 3: Burden of proof reversal
            if [[ $SKEPTICAL_PASSES -ge 2 ]]; then
                local reversal_prompt="Apply REVERSE burden of proof. This criterion is NOT MET until you prove otherwise with irrefutable code evidence.

## Criterion
$sc_line

## Files
$file_contents

## Task
1. List every specific requirement implied by the criterion
2. For EACH requirement, find the exact code (file:line) that satisfies it
3. If you cannot cite concrete code for a requirement, mark it ABSENT
4. Do not infer or assume — cite exact code or mark ABSENT
5. A single ABSENT requirement means the criterion is not fully met

## Output Format (JSON only)
{
  \"requirements\": [
    {\"requirement\": \"what the criterion requires\", \"evidence\": \"file:line and description\", \"status\": \"PROVEN\" | \"ABSENT\" | \"WEAK\"}
  ],
  \"unproven_requirements\": [\"requirements that could not be proven\"],
  \"verdict\": \"ALL_PROVEN\" | \"GAPS_FOUND\"
}"

                local reversal_file="$CHECK_DIR/$sc-reversal.json"
                if claude --dangerously-skip-permissions -p "$reversal_prompt" > "$reversal_file" 2>&1; then
                    local rev_json
                    rev_json=$(sed -n '/^{/,/^}/p' "$reversal_file" | head -100)
                    if [[ -z "$rev_json" ]]; then
                        rev_json=$(grep -A 1000 '{' "$reversal_file" | grep -B 1000 '}' || true)
                    fi
                    if [[ -n "$rev_json" ]]; then
                        echo "$rev_json" > "$reversal_file.clean"
                        local rev_verdict
                        rev_verdict=$(jq -r '.verdict // "UNKNOWN"' "$reversal_file.clean" 2>/dev/null || echo "UNKNOWN")
                        if [[ "$rev_verdict" == "GAPS_FOUND" ]]; then
                            significant_gaps_found=true
                            if [[ -z "$skeptical_gaps" || "$skeptical_gaps" == "unspecified" ]]; then
                                skeptical_gaps=$(jq -r '.unproven_requirements[0] // "unspecified"' "$reversal_file.clean" 2>/dev/null)
                            fi
                            log "    Pass 3 (burden reversal): GAPS FOUND"
                        else
                            log "    Pass 3 (burden reversal): all requirements proven"
                        fi
                    else
                        significant_gaps_found=true
                        [[ -z "$skeptical_gaps" ]] && skeptical_gaps="pass 3 output unparseable (fail-closed)"
                        log "    Pass 3 (burden reversal): UNPARSEABLE — fail-closed, gaps assumed"
                    fi
                else
                    significant_gaps_found=true
                    [[ -z "$skeptical_gaps" ]] && skeptical_gaps="pass 3 claude call failed (fail-closed)"
                    log "    Pass 3 (burden reversal): FAILED — fail-closed, gaps assumed"
                fi
            fi

            # Pass 4: Minimal counterexample
            if [[ $SKEPTICAL_PASSES -ge 3 ]]; then
                local counter_prompt="Construct a MINIMAL COUNTEREXAMPLE: the simplest concrete scenario that would cause this implementation to violate the criterion.

## Criterion
$sc_line

## Files
$file_contents

## Task
1. Find the simplest possible input, state, or execution path that would cause the implementation to produce incorrect results relative to the criterion
2. Be SPECIFIC: name exact input values, the expected behavior per the criterion, and what the code would actually do
3. Trace through the code step by step to verify your counterexample is real
4. If you genuinely cannot construct a valid counterexample after exhaustive analysis, explain WHY no counterexample exists — do not simply give up

## Output Format (JSON only)
{
  \"counterexample\": {
    \"scenario\": \"description of the minimal failing scenario\",
    \"input\": \"specific input or state\",
    \"expected_per_criterion\": \"what should happen\",
    \"actual_code_behavior\": \"what the code would do\",
    \"code_path\": \"file:line trace through the failure\"
  },
  \"verdict\": \"COUNTEREXAMPLE_FOUND\" | \"NO_COUNTEREXAMPLE\"
}"

                local counter_file="$CHECK_DIR/$sc-counterexample.json"
                if claude --dangerously-skip-permissions -p "$counter_prompt" > "$counter_file" 2>&1; then
                    local ctr_json
                    ctr_json=$(sed -n '/^{/,/^}/p' "$counter_file" | head -100)
                    if [[ -z "$ctr_json" ]]; then
                        ctr_json=$(grep -A 1000 '{' "$counter_file" | grep -B 1000 '}' || true)
                    fi
                    if [[ -n "$ctr_json" ]]; then
                        echo "$ctr_json" > "$counter_file.clean"
                        local ctr_verdict
                        ctr_verdict=$(jq -r '.verdict // "UNKNOWN"' "$counter_file.clean" 2>/dev/null || echo "UNKNOWN")
                        if [[ "$ctr_verdict" == "COUNTEREXAMPLE_FOUND" ]]; then
                            significant_gaps_found=true
                            if [[ -z "$skeptical_gaps" || "$skeptical_gaps" == "unspecified" ]]; then
                                skeptical_gaps=$(jq -r '.counterexample.scenario // "unspecified"' "$counter_file.clean" 2>/dev/null)
                            fi
                            log "    Pass 4 (counterexample): COUNTEREXAMPLE FOUND"
                        else
                            log "    Pass 4 (counterexample): no counterexample found"
                        fi
                    else
                        significant_gaps_found=true
                        [[ -z "$skeptical_gaps" ]] && skeptical_gaps="pass 4 output unparseable (fail-closed)"
                        log "    Pass 4 (counterexample): UNPARSEABLE — fail-closed, gaps assumed"
                    fi
                else
                    significant_gaps_found=true
                    [[ -z "$skeptical_gaps" ]] && skeptical_gaps="pass 4 claude call failed (fail-closed)"
                    log "    Pass 4 (counterexample): FAILED — fail-closed, gaps assumed"
                fi
            fi

            # Aggregate: any gap from any pass → PARTIAL
            if $significant_gaps_found; then
                final_status="PARTIAL"
            fi
        fi

        # Apply evidence cap: no tests + Done → PARTIAL at best
        if [[ "$evidence_cap" == "PARTIAL" && "$final_status" == "MET" ]]; then
            final_status="PARTIAL"
            skeptical_gaps="no deterministic tests defined (evidence cap applied)"
        fi

        case "$final_status" in
            MET)
                log_pass "$sc: MET (confidence: $confidence)"
                ;;
            PARTIAL)
                if [[ -n "$skeptical_gaps" ]]; then
                    log_warn "$sc: PARTIAL — $skeptical_gaps"
                else
                    local gaps
                    gaps=$(jq -r '.gaps[0] // "unspecified"' "$result_file.clean" 2>/dev/null)
                    log_warn "$sc: PARTIAL — $gaps"
                fi
                ;;
            NOT_MET)
                local gaps
                gaps=$(jq -r '.gaps[0] // "unspecified"' "$result_file.clean" 2>/dev/null)
                log_fail "CONTENT: $sc not implemented — $gaps"
                ;;
            *)
                if $ALLOW_UNVERIFIED; then
                    log_warn "$sc: Could not verify (status: $final_status) — allowed by --allow-unverified"
                else
                    log_fail "VERIFY: $sc — verification returned unknown status: $final_status"
                fi
                ;;
        esac

    done < "$criteria_file"

    log ""
}

# ============================================
# Phase 4.6: Benchmark Verification
# ============================================

# Try to extract a metric value from JSON-line output first, fall back to regex
extract_metric_value() {
    local output="$1"
    local metric_name="$2"

    # Try JSON-line format: {"metric": "name", "value": 123.4, "unit": "ms"}
    local json_value=""
    json_value=$(echo "$output" | grep -E '^\{' | jq -r "select(.metric == \"$metric_name\") | .value" 2>/dev/null | head -1)
    if [[ -n "$json_value" && "$json_value" != "null" ]]; then
        echo "$json_value"
        return 0
    fi

    # Fall back to regex: look for "metric_name: value" or "metric_name = value" or "metric_name value"
    local regex_value=""
    regex_value=$(echo "$output" | grep -i "$metric_name" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)
    if [[ -n "$regex_value" ]]; then
        echo "$regex_value"
        return 0
    fi

    return 1
}

# Parse all JSON-line metrics from benchmark output into a JSON object
parse_json_line_metrics() {
    local output="$1"
    echo "$output" | grep -E '^\{' | jq -s 'map(select(.metric and .value)) | if length > 0 then . else empty end' 2>/dev/null || echo "[]"
}

phase4_6_benchmark_verification() {
    if $STRUCTURE_ONLY || $SKIP_BENCHMARKS; then
        log "=== Phase 4.6: Benchmark Verification (SKIPPED) ===" "always"
        log ""
        return 0
    fi

    log "=== Phase 4.6: Benchmark Verification ===" "always"

    local criteria_file="$CHECK_DIR/criteria.txt"
    local benchmarks_run=0
    local benchmarks_passed=0
    local benchmarks_failed=0
    local benchmark_results_file="$CHECK_DIR/benchmark-results.json"

    # Initialize results file
    echo "{}" > "$benchmark_results_file"

    # Run bench.sh first (if present) so its data is available for criterion checks and doc audit
    local bench_script="$FULL_PROJECT_DIR/bench.sh"
    if [[ -x "$bench_script" ]]; then
        log "  Running bench.sh..."
        local bench_sh_output=""
        if bench_sh_output=$(cd "$FULL_PROJECT_DIR" && ./bench.sh 2>&1); then
            echo "$bench_sh_output" > "$CHECK_DIR/bench.log"
            log_pass "bench.sh passed"

            local bench_metrics
            bench_metrics=$(parse_json_line_metrics "$bench_sh_output")

            if [[ "$bench_metrics" != "[]" && -n "$bench_metrics" ]]; then
                local tmp_init
                tmp_init=$(jq --argjson res "$bench_metrics" '. + {"bench.sh": $res}' "$benchmark_results_file" 2>/dev/null)
                if [[ -n "$tmp_init" ]]; then
                    echo "$tmp_init" > "$benchmark_results_file"
                fi
                log "  Collected $(echo "$bench_metrics" | jq 'length' 2>/dev/null || echo "?") metrics from bench.sh"
            fi
        else
            local bs_exit=$?
            echo "$bench_sh_output" > "$CHECK_DIR/bench.log"
            log_fail "BENCH: bench.sh failed (exit $bs_exit)"
            log "    See: $CHECK_DIR/bench.log"
        fi
    fi

    while IFS='|' read -r sc files subproject tests benchmark; do
        [[ -z "$sc" ]] && continue
        [[ -z "$benchmark" ]] && continue

        # Parse benchmark field: "command | metric op threshold, metric op threshold, ..."
        local bench_command=""
        local thresholds=""

        if [[ "$benchmark" == *"|"* ]]; then
            bench_command="${benchmark%%|*}"
            thresholds="${benchmark#*|}"
            bench_command="${bench_command## }"
            bench_command="${bench_command%% }"
            thresholds="${thresholds## }"
            thresholds="${thresholds%% }"
        else
            bench_command="$benchmark"
        fi

        if [[ -z "$bench_command" ]]; then
            continue
        fi

        ((benchmarks_run++))
        log "  $sc: Running benchmark..."

        local bench_log="$CHECK_DIR/$sc-benchmark.log"
        local bench_output=""

        if bench_output=$(cd "$FULL_PROJECT_DIR" && eval "$bench_command" 2>&1); then
            echo "$bench_output" > "$bench_log"

            # Collect all JSON-line metrics from output
            local all_metrics
            all_metrics=$(parse_json_line_metrics "$bench_output")

            # Build per-criterion result array
            local sc_results="[]"

            # Check thresholds if specified
            if [[ -n "$thresholds" ]]; then
                local all_thresholds_met=true
                local threshold_results=""

                # Parse each threshold: "metric op value"
                IFS=',' read -ra THRESHOLD_ARRAY <<< "$thresholds"
                for threshold_spec in "${THRESHOLD_ARRAY[@]}"; do
                    threshold_spec="${threshold_spec## }"
                    threshold_spec="${threshold_spec%% }"
                    [[ -z "$threshold_spec" ]] && continue

                    local metric_name=""
                    local operator=""
                    local threshold_value=""

                    if [[ "$threshold_spec" =~ ^([a-zA-Z0-9_]+)[[:space:]]*(\<|\>|=)[[:space:]]*(.+)$ ]]; then
                        metric_name="${BASH_REMATCH[1]}"
                        operator="${BASH_REMATCH[2]}"
                        threshold_value="${BASH_REMATCH[3]}"

                        local actual_value=""
                        actual_value=$(extract_metric_value "$bench_output" "$metric_name")

                        if [[ -n "$actual_value" ]]; then
                            local threshold_numeric
                            threshold_numeric=$(echo "$threshold_value" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)

                            if [[ -n "$threshold_numeric" ]]; then
                                local comparison_result=0
                                case "$operator" in
                                    "<") comparison_result=$(echo "$actual_value < $threshold_numeric" | bc -l 2>/dev/null || echo "0") ;;
                                    ">") comparison_result=$(echo "$actual_value > $threshold_numeric" | bc -l 2>/dev/null || echo "0") ;;
                                    "=") comparison_result=$(echo "$actual_value == $threshold_numeric" | bc -l 2>/dev/null || echo "0") ;;
                                esac

                                local pass_str="true"
                                if [[ "$comparison_result" == "1" ]]; then
                                    threshold_results+="$metric_name=$actual_value (${operator}${threshold_value} OK) "
                                else
                                    threshold_results+="$metric_name=$actual_value (${operator}${threshold_value} FAIL) "
                                    all_thresholds_met=false
                                    pass_str="false"
                                fi

                                # Add to results
                                sc_results=$(echo "$sc_results" | jq \
                                    --arg m "$metric_name" \
                                    --argjson v "$actual_value" \
                                    --arg t "${operator}${threshold_value}" \
                                    --argjson p "$pass_str" \
                                    '. + [{"metric": $m, "value": $v, "threshold": $t, "pass": $p}]' 2>/dev/null || echo "$sc_results")
                            else
                                threshold_results+="$metric_name=$actual_value (threshold parse error) "
                            fi
                        else
                            threshold_results+="$metric_name=? (not found in output) "
                            log_warn "$sc: Could not extract $metric_name from benchmark output"
                        fi
                    fi
                done

                if $all_thresholds_met; then
                    ((benchmarks_passed++))
                    log_pass "$sc: Benchmark passed - $threshold_results"
                else
                    ((benchmarks_failed++))
                    log_fail "BENCHMARK: $sc threshold not met - $threshold_results"
                fi
            else
                # No thresholds — if we got JSON-line metrics, record them
                if [[ "$all_metrics" != "[]" && -n "$all_metrics" ]]; then
                    sc_results="$all_metrics"
                fi
                ((benchmarks_passed++))
                log_pass "$sc: Benchmark completed (no thresholds specified)"
            fi

            # Merge sc_results into benchmark_results_file
            local tmp_results
            tmp_results=$(jq --arg sc "$sc" --argjson res "$sc_results" '. + {($sc): $res}' "$benchmark_results_file" 2>/dev/null)
            if [[ -n "$tmp_results" ]]; then
                echo "$tmp_results" > "$benchmark_results_file"
            fi

        else
            echo "$bench_output" > "$bench_log"
            ((benchmarks_failed++))
            log_fail "BENCHMARK: $sc benchmark command failed"
            log "    See: $bench_log"
        fi

    done < "$criteria_file"

    # Regression detection: compare against previous results
    local latest_file="$RESULTS_DIR/benchmark-latest.json"
    if [[ -f "$latest_file" ]] && [[ -s "$benchmark_results_file" ]]; then
        log "  Checking for regressions (threshold: ${REGRESSION_THRESHOLD}%)..."

        local regressions_found=false
        # Compare each metric in current vs latest
        for sc in $(jq -r 'keys[]' "$benchmark_results_file" 2>/dev/null); do
            local current_metrics
            current_metrics=$(jq -r --arg sc "$sc" '.[$sc] // []' "$benchmark_results_file" 2>/dev/null)
            local latest_metrics
            latest_metrics=$(jq -r --arg sc "$sc" '.[$sc] // []' "$latest_file" 2>/dev/null)

            [[ "$current_metrics" == "[]" || "$latest_metrics" == "[]" ]] && continue

            for metric_name in $(echo "$current_metrics" | jq -r '.[].metric // empty' 2>/dev/null); do
                local cur_val
                cur_val=$(echo "$current_metrics" | jq -r --arg m "$metric_name" 'map(select(.metric == $m)) | .[0].value // empty' 2>/dev/null)
                local prev_val
                prev_val=$(echo "$latest_metrics" | jq -r --arg m "$metric_name" 'map(select(.metric == $m)) | .[0].value // empty' 2>/dev/null)

                [[ -z "$cur_val" || -z "$prev_val" ]] && continue

                # Check if current is worse by more than threshold
                # For thresholds with ">", lower is worse; for "<", higher is worse
                local threshold_dir
                threshold_dir=$(echo "$current_metrics" | jq -r --arg m "$metric_name" 'map(select(.metric == $m)) | .[0].threshold // ""' 2>/dev/null)

                local pct_change
                if [[ "$prev_val" != "0" ]]; then
                    pct_change=$(echo "scale=1; (($cur_val - $prev_val) / $prev_val) * 100" | bc -l 2>/dev/null || echo "0")
                else
                    continue
                fi

                # Determine if regression: ">" threshold means decrease is bad, "<" means increase is bad
                local is_regression=false
                if [[ "$threshold_dir" == ">"* ]]; then
                    # Higher is better — negative pct_change beyond threshold is regression
                    local neg_threshold
                    neg_threshold=$(echo "-$REGRESSION_THRESHOLD" | bc -l)
                    is_regression=$(echo "$pct_change < $neg_threshold" | bc -l 2>/dev/null || echo "0")
                elif [[ "$threshold_dir" == "<"* ]]; then
                    # Lower is better — positive pct_change beyond threshold is regression
                    is_regression=$(echo "$pct_change > $REGRESSION_THRESHOLD" | bc -l 2>/dev/null || echo "0")
                fi

                if [[ "$is_regression" == "1" ]]; then
                    log_warn "REGRESSION: $sc/$metric_name changed ${pct_change}% (${prev_val} → ${cur_val})"
                    regressions_found=true
                fi
            done
        done

        if ! $regressions_found; then
            log_pass "No benchmark regressions detected"
        fi
    fi

    # Save current results as latest (only if benchmarks ran)
    if [[ $benchmarks_run -gt 0 ]]; then
        cp "$benchmark_results_file" "$latest_file" 2>/dev/null || true
    fi

    if [[ $benchmarks_run -eq 0 ]]; then
        log "  No criterion-level benchmarks defined"
    else
        log "  Benchmarks: $benchmarks_passed/$benchmarks_run passed"
    fi

    log ""
}

# ============================================
# Phase 4.7: Benchmark Documentation Audit
# ============================================

phase4_7_documentation_audit() {
    if $STRUCTURE_ONLY || $SKIP_DOC_AUDIT; then
        log "=== Phase 4.7: Documentation Audit (SKIPPED) ===" "always"
        log ""
        return 0
    fi

    log "=== Phase 4.7: Documentation Audit ===" "always"

    # Fail-closed: Claude CLI required unless --allow-unverified
    if ! command -v claude &> /dev/null; then
        if $ALLOW_UNVERIFIED; then
            log_warn "claude CLI not found — documentation audit skipped (--allow-unverified)"
        else
            log_fail "INFRA: claude CLI required for documentation audit (use --allow-unverified to skip)"
        fi
        log ""
        return 0
    fi

    # Collect actual benchmark results from Phase 4.6 and bench.sh
    local benchmark_results_file="$CHECK_DIR/benchmark-results.json"
    local bench_log="$CHECK_DIR/bench.log"
    local actual_results=""

    if [[ -f "$benchmark_results_file" ]] && [[ "$(jq 'length' "$benchmark_results_file" 2>/dev/null)" != "0" ]]; then
        actual_results+="### Criterion Benchmark Results (from Phase 4.6)
\`\`\`json
$(cat "$benchmark_results_file")
\`\`\`
"
    fi

    if [[ -f "$bench_log" ]]; then
        actual_results+="### bench.sh Output
\`\`\`
$(head -200 "$bench_log")
\`\`\`
"
    fi

    # Find markdown files with benchmark claims
    local claim_files=""
    local claim_contents=""
    local files_found=0
    local exclude_dirs="node_modules|target|dist|build|\.git|__pycache__|\.next|vendor|\.project-metadata"

    # Search by name pattern: *BENCHMARK*, *RESULTS*, *PERF*, bench/README*
    while IFS= read -r md_file; do
        [[ -z "$md_file" ]] && continue
        local rel_path="${md_file#$FULL_PROJECT_DIR/}"

        # Skip vendor/node_modules/target etc
        if echo "$rel_path" | grep -qE "($exclude_dirs)"; then
            continue
        fi

        claim_files+="$rel_path "
        local file_size
        file_size=$(wc -c < "$md_file" 2>/dev/null || echo "0")
        file_size=${file_size//[^0-9]/}

        # Truncate large files to avoid blowing context
        if [[ $file_size -gt 10000 ]]; then
            claim_contents+="
### File: $rel_path (truncated, ${file_size} bytes)
\`\`\`
$(head -150 "$md_file")
\`\`\`
"
        else
            claim_contents+="
### File: $rel_path
\`\`\`
$(cat "$md_file")
\`\`\`
"
        fi
        ((files_found++))
    done < <(find "$FULL_PROJECT_DIR" -type f \( \
        -iname "*benchmark*" -o -iname "*results*" -o -iname "*perf*" \
    \) -name "*.md" 2>/dev/null | sort)

    # Also check bench/README.md specifically
    if [[ -f "$FULL_PROJECT_DIR/bench/README.md" ]]; then
        local rel="bench/README.md"
        if [[ "$claim_files" != *"$rel"* ]]; then
            claim_contents+="
### File: $rel
\`\`\`
$(cat "$FULL_PROJECT_DIR/$rel")
\`\`\`
"
            ((files_found++))
        fi
    fi

    # Check OBJECTIVE.md for inline performance claims (numbers with units)
    if [[ -f "$FULL_PROJECT_DIR/OBJECTIVE.md" ]]; then
        if grep -qE '[0-9]+(\.[0-9]+)?\s*(MIPS|MHz|K/s|M/s|ms|μs|ns|cycles|instr/s|c/s)' "$FULL_PROJECT_DIR/OBJECTIVE.md"; then
            claim_contents+="
### File: OBJECTIVE.md (performance claims)
\`\`\`
$(cat "$FULL_PROJECT_DIR/OBJECTIVE.md")
\`\`\`
"
            ((files_found++))
        fi
    fi

    if [[ $files_found -eq 0 ]]; then
        log "  No benchmark documentation files found"
        log ""
        return 0
    fi

    if [[ -z "$actual_results" ]]; then
        log_warn "No benchmark results to compare against (no benchmarks ran)"
        log ""
        return 0
    fi

    log "  Found $files_found documentation file(s) with benchmark claims"

    # Claude cross-reference
    local audit_prompt="You are auditing benchmark documentation for accuracy. Compare documented performance claims against actual benchmark results.

## Actual Benchmark Results (from running benchmarks)
$actual_results

## Documented Benchmark Claims (from markdown files)
$claim_contents

## Task

For each specific numeric performance claim in the documentation files:
1. Find the corresponding actual benchmark result (if any)
2. Compare the documented value against the actual value
3. Classify each claim

## Classification Rules

- **ALIGNED**: Actual result is within 2x of documented claim (accounts for hardware differences, benchmark noise)
- **STALE**: Actual result differs from documented claim by more than 2x
- **UNVERIFIABLE**: No corresponding benchmark was run, so the claim cannot be checked

Focus only on concrete numeric claims (e.g., \"53.24 MIPS\", \"4.4ms\", \"15 K/s\"). Skip vague qualitative statements.

## Output Format (JSON only, no markdown)

{
  \"claims\": [
    {\"file\": \"path/to/file.md\", \"claim\": \"53.24 MIPS\", \"metric\": \"WASM throughput\", \"actual\": \"48.1 MIPS\", \"status\": \"ALIGNED\", \"reason\": \"within 2x\"},
    {\"file\": \"path/to/file.md\", \"claim\": \"114M instr/s\", \"metric\": \"native throughput\", \"actual\": null, \"status\": \"UNVERIFIABLE\", \"reason\": \"no benchmark ran for this metric\"}
  ],
  \"summary\": {
    \"total\": 5,
    \"aligned\": 3,
    \"stale\": 1,
    \"unverifiable\": 1
  },
  \"overall\": \"ALIGNED\" | \"STALE_CLAIMS_FOUND\" | \"UNVERIFIABLE_ONLY\"
}"

    local audit_result_file="$CHECK_DIR/documentation-audit.json"

    if claude --dangerously-skip-permissions -p "$audit_prompt" > "$audit_result_file" 2>&1; then
        # Extract JSON from response
        local json_content
        json_content=$(grep -A 1000 '{' "$audit_result_file" | grep -B 1000 '}' || cat "$audit_result_file")
        echo "$json_content" > "$audit_result_file.clean"

        local overall
        overall=$(jq -r '.overall // "UNKNOWN"' "$audit_result_file.clean" 2>/dev/null || echo "PARSE_ERROR")
        local total
        total=$(jq -r '.summary.total // 0' "$audit_result_file.clean" 2>/dev/null || echo "0")
        local aligned
        aligned=$(jq -r '.summary.aligned // 0' "$audit_result_file.clean" 2>/dev/null || echo "0")
        local stale
        stale=$(jq -r '.summary.stale // 0' "$audit_result_file.clean" 2>/dev/null || echo "0")
        local unverifiable
        unverifiable=$(jq -r '.summary.unverifiable // 0' "$audit_result_file.clean" 2>/dev/null || echo "0")

        case "$overall" in
            ALIGNED)
                log_pass "Documentation audit: $total claims checked, all aligned"
                ;;
            STALE_CLAIMS_FOUND)
                log_fail "DOC_AUDIT: $stale stale claim(s) found ($aligned aligned, $unverifiable unverifiable)"
                # Log individual stale claims
                local stale_claims
                stale_claims=$(jq -r '.claims[] | select(.status == "STALE") | "  \(.file): \(.claim) (actual: \(.actual // "?")) — \(.reason // "")"' "$audit_result_file.clean" 2>/dev/null)
                if [[ -n "$stale_claims" ]]; then
                    echo "$stale_claims" | while IFS= read -r line; do
                        log "$line" "always"
                    done
                fi
                ;;
            UNVERIFIABLE_ONLY)
                log_warn "Documentation audit: $unverifiable unverifiable claim(s), none stale ($aligned aligned)"
                ;;
            *)
                log_warn "Documentation audit: could not determine result (overall: $overall)"
                ;;
        esac
    else
        log_warn "Documentation audit: Claude verification failed"
    fi

    log ""
}

# ============================================
# Phase 5: Coverage Check (orphan detection)
# ============================================

phase5_coverage_check() {
    if $STRUCTURE_ONLY || $SKIP_ORPHANS; then
        log "=== Phase 5: Coverage Check (SKIPPED) ===" "always"
        log ""
        return 0
    fi

    log "=== Phase 5: Coverage Check ===" "always"

    local criteria_file="$CHECK_DIR/criteria.txt"
    local infrastructure_file="$CHECK_DIR/infrastructure.txt"
    local orphans_file="$CHECK_DIR/orphans.txt"

    # Get all mapped files (criteria + infrastructure)
    local all_mapped=""
    while IFS='|' read -r sc files subproject tests benchmark; do
        [[ -n "$files" ]] && all_mapped+="$files,"
    done < "$criteria_file"

    if [[ -f "$infrastructure_file" ]]; then
        while IFS= read -r file; do
            all_mapped+="$file,"
        done < "$infrastructure_file"
    fi

    # Find source files
    local source_extensions="rs|ts|tsx|js|jsx|py|go|java|c|cpp|h|hpp|rb|swift|kt"
    local exclude_dirs="node_modules|target|dist|build|\.git|__pycache__|\.next|vendor|\.project-metadata"

    > "$orphans_file"
    local orphan_count=0

    while IFS= read -r src_file; do
        # Check if file is in mapped list (handle globs)
        local matched=false
        IFS=',' read -ra MAPPED_PATTERNS <<< "$all_mapped"
        for pattern in "${MAPPED_PATTERNS[@]}"; do
            [[ -z "$pattern" ]] && continue
            # Direct match
            if [[ "$src_file" == "$pattern" ]]; then
                matched=true
                break
            fi
            # Glob match
            if [[ "$pattern" == *"*"* ]] && [[ "$src_file" == $pattern ]]; then
                matched=true
                break
            fi
        done

        if ! $matched; then
            echo "$src_file" >> "$orphans_file"
            ((orphan_count++))
        fi
    done < <(cd "$FULL_PROJECT_DIR" && find . -type f -regextype posix-extended -regex ".*\.($source_extensions)$" 2>/dev/null | sed 's|^\./||' | grep -Ev "($exclude_dirs)" | sort)

    if [[ $orphan_count -eq 0 ]]; then
        log_pass "All source files mapped"
    elif [[ $orphan_count -le 5 ]]; then
        log_warn "ORPHAN: $orphan_count file(s) not mapped to any criterion"
        while IFS= read -r orphan; do
            log "  - $orphan"
        done < "$orphans_file"
    else
        log_warn "ORPHAN: $orphan_count file(s) not mapped (see $orphans_file)"
    fi

    log ""
}

# ============================================
# Phase 6: Subproject Recursion
# ============================================

phase6_subproject_recursion() {
    if $SKIP_SUBPROJECTS; then
        log "=== Phase 6: Subproject Recursion (SKIPPED) ===" "always"
        log ""
        return 0
    fi

    log "=== Phase 6: Subproject Recursion ===" "always"

    local criteria_file="$CHECK_DIR/criteria.txt"
    local subprojects_checked=0
    local failed_subprojects=""

    mkdir -p "$CHECK_DIR/subprojects"

    while IFS='|' read -r sc files subproject tests benchmark; do
        [[ -z "$sc" ]] && continue
        [[ "${CRITERIA_TYPE[$sc]:-}" != "composite" ]] && continue
        [[ -z "$subproject" ]] && continue

        local subproject_path="$FULL_PROJECT_DIR/$subproject"

        if [[ ! -d "$subproject_path" ]]; then
            log_fail "SUBPROJECT: $sc references $subproject but directory not found"
            continue
        fi

        if [[ ! -f "$subproject_path/OBJECTIVE.md" ]]; then
            log_fail "SUBPROJECT: $subproject missing OBJECTIVE.md"
            continue
        fi

        ((subprojects_checked++))
        log "Checking subproject: $subproject (for $sc)" "always"

        # Verify parent_criterion metadata in subproject
        local parent_criterion=""
        if head -20 "$subproject_path/OBJECTIVE.md" | grep -q "parent_criterion:"; then
            parent_criterion=$(head -20 "$subproject_path/OBJECTIVE.md" | grep "parent_criterion:" | sed 's/.*parent_criterion:[[:space:]]*//' | tr -d '\r')
        fi

        if [[ -z "$parent_criterion" ]]; then
            log_warn "METADATA: $subproject missing parent_criterion in frontmatter"
        elif [[ "$parent_criterion" != "$sc" ]]; then
            log_fail "METADATA: $subproject declares parent_criterion: $parent_criterion but linked from $sc"
        fi

        # Recursive call
        local subproject_result_file="$CHECK_DIR/subprojects/$(echo "$subproject" | tr '/' '-').json"

        if "$SCRIPT_DIR/project-check.sh" "$subproject_path" \
            $($STRUCTURE_ONLY && echo "--structure-only") \
            $($SKIP_BUILD && echo "--no-build") \
            $($SKIP_TEST && echo "--no-test") \
            $($SKIP_ORPHANS && echo "--no-orphans") \
            $($SKIP_SKEPTICAL && echo "--no-skeptical") \
            $($SKIP_CRITERION_TESTS && echo "--no-criterion-tests") \
            $($SKIP_BENCHMARKS && echo "--no-benchmarks") \
            $($SKIP_DOC_AUDIT && echo "--no-doc-audit") \
            $($ALLOW_UNVERIFIED && echo "--allow-unverified") \
            --skeptical-passes "$SKEPTICAL_PASSES" \
            --regression-threshold "$REGRESSION_THRESHOLD" \
            --json > "$subproject_result_file" 2>&1; then
            log_pass "Subproject $subproject: PASS"
        else
            log_fail "SUBPROJECT: $subproject failed verification"
            failed_subprojects+="$subproject "
        fi

    done < "$criteria_file"

    if [[ $subprojects_checked -eq 0 ]]; then
        log "  No composite criteria with subprojects"
    elif [[ -n "$failed_subprojects" ]]; then
        log "  Failed: $failed_subprojects"
    else
        log_pass "All $subprojects_checked subproject(s) passed"
    fi

    log ""
}

# ============================================
# Phase 7: Composition Check
# ============================================

phase7_composition_check() {
    if $STRUCTURE_ONLY || $SKIP_SUBPROJECTS; then
        log "=== Phase 7: Composition Check (SKIPPED) ===" "always"
        log ""
        return 0
    fi

    log "=== Phase 7: Composition Check ===" "always"

    # Fail-closed: Claude CLI required unless --allow-unverified
    if ! command -v claude &> /dev/null; then
        if $ALLOW_UNVERIFIED; then
            log_warn "claude CLI not found — composition verification skipped (--allow-unverified)"
        else
            log_fail "INFRA: claude CLI required for composition verification (use --allow-unverified to skip)"
        fi
        log ""
        return 0
    fi

    local criteria_file="$CHECK_DIR/criteria.txt"
    local compositions_checked=0
    local max_code_size=80000  # 80KB for code-level composition

    while IFS='|' read -r sc files subproject tests benchmark; do
        [[ -z "$sc" ]] && continue
        [[ "${CRITERIA_TYPE[$sc]:-}" != "composite" ]] && continue
        [[ -z "$subproject" ]] && continue

        local subproject_path="$FULL_PROJECT_DIR/$subproject"
        local subproject_result="$CHECK_DIR/subprojects/$(echo "$subproject" | tr '/' '-').json"

        # Only check composition if subproject passed
        if [[ ! -f "$subproject_result" ]]; then
            continue
        fi

        local subproject_outcome=$(jq -r '.outcome // "UNKNOWN"' "$subproject_result" 2>/dev/null || echo "UNKNOWN")
        if [[ "$subproject_outcome" != "PASS" ]]; then
            log "  Skipping composition for $sc (subproject failed)"
            continue
        fi

        ((compositions_checked++))
        log "Checking composition: $sc" "always"

        # Get parent criterion description
        local parent_desc=$(grep -E "^### $sc:" "$FULL_PROJECT_DIR/OBJECTIVE.md" || echo "$sc")

        # Get child criteria from subproject
        local child_criteria=""
        if [[ -f "$subproject_path/OBJECTIVE.md" ]]; then
            child_criteria=$(grep -E "^### SC-" "$subproject_path/OBJECTIVE.md" | head -20)
        fi

        # Code-level composition: try to include actual code if total size ≤80KB
        local child_code=""
        local total_child_size=0
        local include_code=true

        # Calculate total size of child criteria files
        if [[ -f "$subproject_path/OBJECTIVE.md" ]]; then
            while IFS='|' read -r child_sc child_files _rest; do
                [[ -z "$child_files" ]] && continue
                IFS=',' read -ra CHILD_FILE_ARRAY <<< "$child_files"
                for child_file in "${CHILD_FILE_ARRAY[@]}"; do
                    [[ -z "$child_file" ]] && continue
                    local child_full_path="$subproject_path/$child_file"
                    if [[ -f "$child_full_path" ]]; then
                        local child_file_size=$(wc -c < "$child_full_path" 2>/dev/null || echo "0")
                        child_file_size=${child_file_size//[^0-9]/}
                        total_child_size=$((total_child_size + child_file_size))
                    fi
                done
            done < <(grep -E "^\*\*Files:\*\*" -A 20 "$subproject_path/OBJECTIVE.md" 2>/dev/null | grep -E "^- \`" | sed 's/.*`\([^`]*\)`.*/\1/' | tr '\n' ',' | sed 's/,$//')
        fi

        if [[ $total_child_size -gt $max_code_size ]]; then
            include_code=false
            log "  Code size $total_child_size > 80KB, using header-only composition"
        fi

        # Build child code content if within budget
        if $include_code && [[ -f "$subproject_path/OBJECTIVE.md" ]]; then
            # Extract files from each child criterion and include content
            local child_files_list=""
            while IFS= read -r line; do
                if [[ "$line" =~ ^-[[:space:]]+\`([^\`]+)\` ]]; then
                    local file_path="${BASH_REMATCH[1]}"
                    local full_path="$subproject_path/$file_path"
                    if [[ -f "$full_path" ]]; then
                        local file_size=$(wc -c < "$full_path" 2>/dev/null || echo "0")
                        file_size=${file_size//[^0-9]/}
                        if [[ $((total_child_size)) -le $max_code_size ]]; then
                            child_code+="
### File: $file_path
\`\`\`
$(cat "$full_path")
\`\`\`
"
                        fi
                    fi
                fi
            done < <(sed -n '/^\*\*Files:\*\*/,/^##\|^###/p' "$subproject_path/OBJECTIVE.md" | grep -E "^- \`")
        fi

        # Composition verification prompt - enhanced with code when available
        local code_section=""
        if [[ -n "$child_code" ]]; then
            code_section="

## Child Implementation Code
$child_code"
        else
            code_section="

(Code not included - total size exceeds 80KB budget)"
        fi

        local composition_prompt="You are verifying that child criteria compose to implement a parent criterion.

## Parent Criterion (from parent project)
$parent_desc

## Child Criteria (from subproject at $subproject)
$child_criteria
$code_section

## Task

Determine if the child criteria, when all satisfied, would fully implement the parent criterion.

Check for:
1. Coverage: Do children cover all aspects of the parent?
2. Gaps: Is anything from the parent not addressed by children?
3. Interface: Do children work together correctly?

## Output Format (JSON only)

{
  \"parent_criterion\": \"$sc\",
  \"composition_status\": \"SOUND\" | \"INCOMPLETE\" | \"MISALIGNED\",
  \"coverage_assessment\": \"description of coverage\",
  \"gaps\": [\"any gaps found\"],
  \"confidence\": \"HIGH\" | \"MEDIUM\" | \"LOW\"
}"

        local result_file="$CHECK_DIR/$sc-composition.json"

        if claude --dangerously-skip-permissions -p "$composition_prompt" > "$result_file" 2>&1; then
            local json_content=$(grep -A 1000 '{' "$result_file" | grep -B 1000 '}' || cat "$result_file")
            echo "$json_content" > "$result_file.clean"

            local comp_status=$(jq -r '.composition_status // "UNKNOWN"' "$result_file.clean" 2>/dev/null || echo "PARSE_ERROR")
            local confidence=$(jq -r '.confidence // "UNKNOWN"' "$result_file.clean" 2>/dev/null || echo "UNKNOWN")

            case "$comp_status" in
                SOUND)
                    log_pass "$sc: Composition SOUND (confidence: $confidence)"
                    ;;
                INCOMPLETE)
                    local gaps=$(jq -r '.gaps[0] // "unspecified"' "$result_file.clean" 2>/dev/null)
                    log_warn "$sc: Composition INCOMPLETE - $gaps"
                    ;;
                MISALIGNED)
                    local gaps=$(jq -r '.gaps[0] // "unspecified"' "$result_file.clean" 2>/dev/null)
                    log_fail "COMPOSITION: $sc children don't implement parent - $gaps"
                    ;;
                *)
                    log_warn "$sc: Could not verify composition (status: $comp_status)"
                    ;;
            esac
        else
            log_warn "$sc: Composition verification failed (claude error)"
        fi

    done < "$criteria_file"

    if [[ $compositions_checked -eq 0 ]]; then
        log "  No compositions to verify"
    fi

    log ""
}

# ============================================
# Phase 8: External Build/Test Verification
# ============================================

phase8_external_verification() {
    log "=== Phase 8: External Verification ===" "always"

    local build_script="$FULL_PROJECT_DIR/build.sh"
    local test_script="$FULL_PROJECT_DIR/test.sh"

    # Build verification
    if ! $SKIP_BUILD; then
        if [[ -x "$build_script" ]]; then
            log "Running build.sh..."
            if (cd "$FULL_PROJECT_DIR" && ./build.sh > "$CHECK_DIR/build.log" 2>&1); then
                log_pass "Build passed"
            else
                local exit_code=$?
                log_fail "BUILD: build.sh failed (exit $exit_code)"
                log "  See: $CHECK_DIR/build.log"
            fi
        else
            log "  No build.sh found (skipped)"
        fi
    fi

    # Test verification
    if ! $SKIP_TEST; then
        if [[ -x "$test_script" ]]; then
            log "Running test.sh..."
            if (cd "$FULL_PROJECT_DIR" && ./test.sh > "$CHECK_DIR/test.log" 2>&1); then
                log_pass "Tests passed"
            else
                local exit_code=$?
                log_fail "TEST: test.sh failed (exit $exit_code)"
                log "  See: $CHECK_DIR/test.log"
            fi
        else
            log "  No test.sh found (skipped)"
        fi
    fi

    log ""
}

# ============================================
# Phase 9: Summary
# ============================================

phase9_summary() {
    log "=========================================" "always"

    local total_checks=$((${#PASSES[@]} + ${#WARNINGS[@]} + ${#VIOLATIONS[@]}))

    # Count criteria by type
    local leaf_count=0
    local composite_count=0
    for sc in "${!CRITERIA_TYPE[@]}"; do
        case "${CRITERIA_TYPE[$sc]}" in
            leaf) ((leaf_count++)) ;;
            composite) ((composite_count++)) ;;
        esac
    done

    if $JSON_OUTPUT; then
        # Build criteria JSON
        local criteria_json="{"
        local first=true
        for sc in "${!CRITERIA_TYPE[@]}"; do
            $first || criteria_json+=","
            first=false
            local type="${CRITERIA_TYPE[$sc]}"
            local size="${CRITERIA_SIZE[$sc]:-0}"
            local subproj="${CRITERIA_SUBPROJECT[$sc]:-}"

            criteria_json+="\"$sc\":{\"type\":\"$type\",\"size_bytes\":$size"
            if [[ -n "$subproj" ]]; then
                criteria_json+=",\"subproject\":\"$subproj\""
            fi
            criteria_json+="}"
        done
        criteria_json+="}"

        # Build benchmark data
        local benchmark_json="{}"
        local benchmark_results_file="$CHECK_DIR/benchmark-results.json"
        local audit_result_file="$CHECK_DIR/documentation-audit.json.clean"

        if [[ -f "$benchmark_results_file" ]]; then
            benchmark_json=$(jq '{results: .}' "$benchmark_results_file" 2>/dev/null || echo '{"results": {}}')
        fi

        if [[ -f "$audit_result_file" ]]; then
            local audit_summary
            audit_summary=$(jq '.summary // {}' "$audit_result_file" 2>/dev/null || echo '{}')
            benchmark_json=$(echo "$benchmark_json" | jq --argjson audit "$audit_summary" '. + {documentation_audit: $audit}' 2>/dev/null || echo "$benchmark_json")
        fi

        local latest_file="$RESULTS_DIR/benchmark-latest.json"
        if [[ -f "$latest_file" ]]; then
            local latest_ts
            latest_ts=$(stat -f %Sm -t %Y%m%d-%H%M%S "$latest_file" 2>/dev/null || echo "unknown")
            benchmark_json=$(echo "$benchmark_json" | jq --arg ts "$latest_ts" '. + {regression: {compared_to: $ts}}' 2>/dev/null || echo "$benchmark_json")
        fi

        cat << EOF
{
  "version": 3,
  "outcome": "$([[ ${#VIOLATIONS[@]} -eq 0 ]] && echo "PASS" || echo "FAIL")",
  "timestamp": "$TIMESTAMP",
  "project": {
    "path": "$PROJECT_PATH",
    "full_path": "$FULL_PROJECT_DIR"
  },
  "checks": {
    "total": $total_checks,
    "passed": ${#PASSES[@]},
    "warnings": ${#WARNINGS[@]},
    "violations": ${#VIOLATIONS[@]}
  },
  "criteria_summary": {
    "total": $((leaf_count + composite_count)),
    "leaf": $leaf_count,
    "composite": $composite_count
  },
  "criteria": $criteria_json,
  "benchmarks": $benchmark_json,
  "passes": $(printf '%s\n' "${PASSES[@]}" | jq -R . | jq -s .),
  "warnings": $(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .),
  "violations": $(printf '%s\n' "${VIOLATIONS[@]}" | jq -R . | jq -s .)
}
EOF
    else
        if [[ ${#VIOLATIONS[@]} -eq 0 ]]; then
            if [[ ${#WARNINGS[@]} -eq 0 ]]; then
                echo "## Outcome: PASS"
                echo ""
                echo "All $total_checks checks passed."
                echo "Criteria: $leaf_count leaf, $composite_count composite"
            else
                echo "## Outcome: PASS (with ${#WARNINGS[@]} warnings)"
                echo ""
                echo "Criteria: $leaf_count leaf, $composite_count composite"
                echo ""
                echo "Warnings:"
                printf '  - %s\n' "${WARNINGS[@]}"
            fi
        else
            echo "## Outcome: FAIL"
            echo ""
            echo "Criteria: $leaf_count leaf, $composite_count composite"
            echo ""
            echo "Violations (${#VIOLATIONS[@]}):"
            printf '  - %s\n' "${VIOLATIONS[@]}"
            if [[ ${#WARNINGS[@]} -gt 0 ]]; then
                echo ""
                echo "Warnings (${#WARNINGS[@]}):"
                printf '  - %s\n' "${WARNINGS[@]}"
            fi
        fi

        echo ""
        echo "Results: $CHECK_DIR"
    fi

    # Save last-check.json
    cat > "$RESULTS_DIR/last-check.json" << EOF
{
  "version": 3,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "outcome": "$([[ ${#VIOLATIONS[@]} -eq 0 ]] && echo "PASS" || echo "FAIL")",
  "project": "$PROJECT_PATH",
  "checks": {
    "total": $total_checks,
    "passed": ${#PASSES[@]},
    "warnings": ${#WARNINGS[@]},
    "violations": ${#VIOLATIONS[@]}
  },
  "criteria_summary": {
    "leaf": $leaf_count,
    "composite": $composite_count
  },
  "flags": {
    "structure_only": $STRUCTURE_ONLY,
    "skip_build": $SKIP_BUILD,
    "skip_test": $SKIP_TEST,
    "skip_orphans": $SKIP_ORPHANS,
    "skip_subprojects": $SKIP_SUBPROJECTS,
    "skip_skeptical": $SKIP_SKEPTICAL,
    "skip_criterion_tests": $SKIP_CRITERION_TESTS,
    "skip_benchmarks": $SKIP_BENCHMARKS,
    "skip_doc_audit": $SKIP_DOC_AUDIT,
    "allow_unverified": $ALLOW_UNVERIFIED,
    "skeptical_passes": $SKEPTICAL_PASSES,
    "regression_threshold": $REGRESSION_THRESHOLD
  },
  "results_dir": "$CHECK_DIR"
}
EOF
}

# ============================================
# Main
# ============================================

main() {
    if ! $JSON_OUTPUT; then
        echo "=== Project Check: $PROJECT_PATH ==="
        echo "Directory: $FULL_PROJECT_DIR"
        echo ""
    fi

    phase1_structural
    phase2_parse_criteria
    phase3_classify_criteria
    phase4_deterministic_evidence
    phase4_5_semantic_verification
    phase4_6_benchmark_verification
    phase4_7_documentation_audit
    phase5_coverage_check
    phase6_subproject_recursion
    phase7_composition_check
    phase8_external_verification
    phase9_summary

    # Exit code
    if [[ ${#VIOLATIONS[@]} -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

main
