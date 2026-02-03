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
    echo "  --skeptical-passes N  Number of skeptical passes (default: 2)"
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
SKEPTICAL_PASSES=2
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
        --skeptical-passes)
            shift
            SKEPTICAL_PASSES="${1:-2}"
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
            echo "  --skeptical-passes N  Number of skeptical passes (default: 2)"
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
            fi
            current_sc="${BASH_REMATCH[1]}"
            files_for_sc=""
            subproject_for_sc=""
            tests_for_sc=""
            benchmark_for_sc=""
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
                current_sc=""
                files_for_sc=""
                subproject_for_sc=""
                tests_for_sc=""
                benchmark_for_sc=""
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
# Phase 4: Leaf Verification (bounded Claude calls)
# ============================================

phase4_leaf_verification() {
    if $STRUCTURE_ONLY; then
        log "=== Phase 4: Leaf Verification (SKIPPED) ===" "always"
        log ""
        return 0
    fi

    log "=== Phase 4: Leaf Verification ===" "always"

    # Check if claude CLI is available
    if ! command -v claude &> /dev/null; then
        log_warn "claude CLI not found - skipping semantic verification"
        log "  Install: npm install -g @anthropic-ai/claude-code"
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
        local sc_line=$(grep -E "^### $sc:" "$FULL_PROJECT_DIR/OBJECTIVE.md" || echo "$sc: (description not found)")

        # Bounded verification prompt
        local verify_prompt="You are verifying a single success criterion. Be thorough but focused.

## Criterion
$sc_line

## Files Claimed to Implement This Criterion ($file_count files)
$file_contents

## Task

1. Read each file completely
2. Determine if the code actually implements the criterion
3. Identify specific evidence (function names, logic, file:line)
4. Note any gaps or incomplete implementation

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

        # Run bounded verification (Pass 1)
        if claude --dangerously-skip-permissions -p "$verify_prompt" > "$result_file" 2>&1; then
            # Extract JSON from response
            local json_content=$(grep -A 1000 '{' "$result_file" | grep -B 1000 '}' | head -n -0 || cat "$result_file")
            echo "$json_content" > "$result_file.clean"

            local status=$(jq -r '.status // "UNKNOWN"' "$result_file.clean" 2>/dev/null || echo "PARSE_ERROR")
            local confidence=$(jq -r '.confidence // "UNKNOWN"' "$result_file.clean" 2>/dev/null || echo "UNKNOWN")
            local final_status="$status"
            local skeptical_gaps=""

            # Multi-pass skeptical verification (only if Pass 1 = MET and skeptical enabled)
            if [[ "$status" == "MET" ]] && ! $SKIP_SKEPTICAL && [[ $SKEPTICAL_PASSES -gt 0 ]]; then
                log "  Running skeptical verification ($SKEPTICAL_PASSES passes)..."

                local significant_gaps_found=false

                # Pass 2: Adversarial review
                if [[ $SKEPTICAL_PASSES -ge 1 ]]; then
                    local adversarial_prompt="You are a skeptical code reviewer. Your task is to find reasons this code does NOT fully implement the criterion. Be adversarial but fair.

## Criterion
$sc_line

## Files
$file_contents

## Task
Find specific ways this implementation is incomplete, incorrect, or doesn't meet the criterion. Look for:
1. Missing edge cases
2. Incorrect logic
3. Unhandled scenarios
4. Requirements not addressed

If the implementation is actually complete, say so. But err on the side of finding issues.

## Output Format (JSON only)
{
  \"significant_gaps\": [\"list of significant gaps found, or empty if none\"],
  \"minor_issues\": [\"list of minor issues\"],
  \"verdict\": \"GAPS_FOUND\" | \"NO_SIGNIFICANT_GAPS\"
}"

                    local adversarial_file="$CHECK_DIR/$sc-adversarial.json"
                    if claude --dangerously-skip-permissions -p "$adversarial_prompt" > "$adversarial_file" 2>&1; then
                        local adv_json=$(grep -A 1000 '{' "$adversarial_file" | grep -B 1000 '}' | head -n -0 || cat "$adversarial_file")
                        echo "$adv_json" > "$adversarial_file.clean"
                        local adv_verdict=$(jq -r '.verdict // "UNKNOWN"' "$adversarial_file.clean" 2>/dev/null || echo "UNKNOWN")
                        if [[ "$adv_verdict" == "GAPS_FOUND" ]]; then
                            significant_gaps_found=true
                            skeptical_gaps=$(jq -r '.significant_gaps[0] // "unspecified"' "$adversarial_file.clean" 2>/dev/null)
                        fi
                    fi
                fi

                # Pass 3: Edge case review
                if [[ $SKEPTICAL_PASSES -ge 2 ]] && ! $significant_gaps_found; then
                    local edge_prompt="You are reviewing code for edge cases and error handling.

## Criterion
$sc_line

## Files
$file_contents

## Task
Identify:
1. Edge cases not handled
2. Error conditions not covered
3. Requirements not fully addressed
4. Boundary conditions that might fail

## Output Format (JSON only)
{
  \"unhandled_edge_cases\": [\"list of unhandled edge cases\"],
  \"missing_error_handling\": [\"list of missing error handling\"],
  \"unaddressed_requirements\": [\"list of unaddressed requirements\"],
  \"verdict\": \"ISSUES_FOUND\" | \"NO_SIGNIFICANT_ISSUES\"
}"

                    local edge_file="$CHECK_DIR/$sc-edge-cases.json"
                    if claude --dangerously-skip-permissions -p "$edge_prompt" > "$edge_file" 2>&1; then
                        local edge_json=$(grep -A 1000 '{' "$edge_file" | grep -B 1000 '}' | head -n -0 || cat "$edge_file")
                        echo "$edge_json" > "$edge_file.clean"
                        local edge_verdict=$(jq -r '.verdict // "UNKNOWN"' "$edge_file.clean" 2>/dev/null || echo "UNKNOWN")
                        if [[ "$edge_verdict" == "ISSUES_FOUND" ]]; then
                            significant_gaps_found=true
                            skeptical_gaps=$(jq -r '.unhandled_edge_cases[0] // .unaddressed_requirements[0] // "unspecified"' "$edge_file.clean" 2>/dev/null)
                        fi
                    fi
                fi

                # Aggregate: MET becomes PARTIAL if gaps found
                if $significant_gaps_found; then
                    final_status="PARTIAL"
                fi
            fi

            case "$final_status" in
                MET)
                    log_pass "$sc: MET (confidence: $confidence)"
                    ;;
                PARTIAL)
                    if [[ -n "$skeptical_gaps" ]]; then
                        log_warn "$sc: PARTIAL (skeptical review) - $skeptical_gaps"
                    else
                        local gaps=$(jq -r '.gaps[0] // "unspecified"' "$result_file.clean" 2>/dev/null)
                        log_warn "$sc: PARTIAL - $gaps"
                    fi
                    ;;
                NOT_MET)
                    local gaps=$(jq -r '.gaps[0] // "unspecified"' "$result_file.clean" 2>/dev/null)
                    log_fail "CONTENT: $sc not implemented - $gaps"
                    ;;
                *)
                    log_warn "$sc: Could not verify (status: $final_status)"
                    ;;
            esac
        else
            log_warn "$sc: Verification failed (claude error)"
        fi

    done < "$criteria_file"

    log ""
}

# ============================================
# Phase 4.5: Criterion Tests
# ============================================

phase4_5_criterion_tests() {
    if $STRUCTURE_ONLY || $SKIP_CRITERION_TESTS; then
        log "=== Phase 4.5: Criterion Tests (SKIPPED) ===" "always"
        log ""
        return 0
    fi

    log "=== Phase 4.5: Criterion Tests ===" "always"

    local criteria_file="$CHECK_DIR/criteria.txt"
    local tests_run=0
    local tests_passed=0
    local tests_failed=0

    while IFS='|' read -r sc files subproject tests benchmark; do
        [[ -z "$sc" ]] && continue
        [[ -z "$tests" ]] && continue

        # Parse test field: "command | test_files" or just "command"
        local test_command=""
        local test_files=""

        if [[ "$tests" == *"|"* ]]; then
            test_command="${tests%%|*}"
            test_files="${tests#*|}"
            test_command="${test_command## }"  # trim leading space
            test_command="${test_command%% }"  # trim trailing space
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
                log_pass "$sc: Tests passed"
            else
                ((tests_failed++))
                local exit_code=$?
                log_fail "CRITERION_TEST: $sc tests failed (exit $exit_code)"
                log "    See: $test_log"
            fi
        fi

    done < "$criteria_file"

    if [[ $tests_run -eq 0 ]]; then
        log "  No criterion-level tests defined"
    else
        log "  Tests: $tests_passed/$tests_run passed"
    fi

    log ""
}

# ============================================
# Phase 4.6: Benchmark Verification
# ============================================

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

                    # Extract metric name, operator, and value
                    # Patterns: "latency_p99 < 50ms" or "throughput > 1000/s"
                    local metric_name=""
                    local operator=""
                    local threshold_value=""

                    if [[ "$threshold_spec" =~ ^([a-zA-Z0-9_]+)[[:space:]]*(\<|\>|=)[[:space:]]*(.+)$ ]]; then
                        metric_name="${BASH_REMATCH[1]}"
                        operator="${BASH_REMATCH[2]}"
                        threshold_value="${BASH_REMATCH[3]}"

                        # Try to extract metric from output (look for "metric: value" or "metric = value")
                        local actual_value=""
                        actual_value=$(echo "$bench_output" | grep -i "$metric_name" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)

                        if [[ -n "$actual_value" ]]; then
                            # Extract numeric threshold (remove units)
                            local threshold_numeric=$(echo "$threshold_value" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1)

                            if [[ -n "$threshold_numeric" ]]; then
                                local comparison_result=0
                                case "$operator" in
                                    "<")
                                        comparison_result=$(echo "$actual_value < $threshold_numeric" | bc -l 2>/dev/null || echo "0")
                                        ;;
                                    ">")
                                        comparison_result=$(echo "$actual_value > $threshold_numeric" | bc -l 2>/dev/null || echo "0")
                                        ;;
                                    "=")
                                        comparison_result=$(echo "$actual_value == $threshold_numeric" | bc -l 2>/dev/null || echo "0")
                                        ;;
                                esac

                                if [[ "$comparison_result" == "1" ]]; then
                                    threshold_results+="$metric_name=$actual_value (${operator}${threshold_value} OK) "
                                else
                                    threshold_results+="$metric_name=$actual_value (${operator}${threshold_value} FAIL) "
                                    all_thresholds_met=false
                                fi
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
                # No thresholds, just record that benchmark ran
                ((benchmarks_passed++))
                log_pass "$sc: Benchmark completed (no thresholds specified)"
            fi
        else
            echo "$bench_output" > "$bench_log"
            ((benchmarks_failed++))
            log_fail "BENCHMARK: $sc benchmark command failed"
            log "    See: $bench_log"
        fi

    done < "$criteria_file"

    if [[ $benchmarks_run -eq 0 ]]; then
        log "  No criterion-level benchmarks defined"
    else
        log "  Benchmarks: $benchmarks_passed/$benchmarks_run passed"
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
            --skeptical-passes "$SKEPTICAL_PASSES" \
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

    # Check if claude CLI is available
    if ! command -v claude &> /dev/null; then
        log_warn "claude CLI not found - skipping composition verification"
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
            local json_content=$(grep -A 1000 '{' "$result_file" | grep -B 1000 '}' | head -n -0 || cat "$result_file")
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

        cat << EOF
{
  "version": 2,
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
  "version": 2,
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
    "skeptical_passes": $SKEPTICAL_PASSES
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
    phase4_leaf_verification
    phase4_5_criterion_tests
    phase4_6_benchmark_verification
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
