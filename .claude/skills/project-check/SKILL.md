---
name: project-check
description: Enforce project invariants - structure, alignment, and coherency
constitution: CLAUDE.md
alignment:
  - Foundational Goal
  - Core Invariants
  - Verification Tiers
  - Project Hierarchy
---

# /project-check

**Enforce project invariants with hierarchical verification.**

## Core Model

**The objective hierarchy IS the verification structure.**

- Leaf criteria (≤80KB files) → verified by deterministic tests + skeptical Claude
- Composite criteria (>80KB files) → decomposed into subproject
- 1:1 mapping: one oversized SC-N = one subproject
- Composition verified: child criteria → parent criterion

## Guarantee

| What | How |
|------|-----|
| Every leaf criterion verified | Tests (hard gate) + bounded Claude call per criterion |
| Deterministic evidence required | Done criteria must have **Tests:** field or FAIL |
| Fail-closed verification | Infrastructure errors → violation, not silent skip |
| Context never exceeded | Leaf ≤80KB enforced, composite = subproject |
| All files covered | Coverage check, orphans = violations |
| Composition sound | Claude verifies children → parent |
| Recursive verification | Subprojects verified same way |
| Benchmark claims accurate | Documentation audit against actual results |

## Verification Philosophy

**Tests are the hard gate. Claude is supplementary.**

The system addresses the self-verification problem (Claude judging Claude's work) by:

1. **Deterministic evidence first**: Tests run before any Claude call. Failed tests = NOT_MET, period.
2. **Evidence cap**: Done criteria without `**Tests:**` are capped at PARTIAL regardless of Claude's semantic judgment.
3. **Fail-closed**: If Claude CLI is unavailable, output is unparseable, or any verification step errors → violation (not warning). Use `--allow-unverified` to opt out explicitly.
4. **Skeptical multi-pass**: 4 passes with distinct adversarial framings, not just "be skeptical."

## Criteria Types

### Leaf Criterion (fits in context)

```markdown
### SC-1: User authentication
**Status:** Done
**Files:**
- `src/auth/login.ts` — OAuth flow
- `src/auth/token.ts` — Token management
**Tests:** `npm test -- auth.test.ts` | `tests/auth.test.ts`
**Benchmark:** `npm run bench:auth` | latency_p99 < 50ms, throughput > 1000/s
**Verification:** `npm test -- --grep auth`
```

**Field descriptions:**
- **Status:** Current state (Done, In Progress, etc.) — parsed and used for evidence gate
- **Tests:** `command | test_files` — **Required for Done criteria.** Hard gate for verification.
- **Benchmark:** `command | metric op threshold, ...` — Benchmark with thresholds

### Composite Criterion (exceeds context, has subproject)

```markdown
### SC-3: Performant browser proving
**Status:** In Progress
**Subproject:** `crates/stwo-prover/`   # Flexible path
**Interface:**
- **Inputs:** Circuit constraints from parent
- **Outputs:** Valid STARK proof
- **Guarantees:** Soundness, performance ≥1MHz
```

### Subproject OBJECTIVE.md

```yaml
---
parent: ../../OBJECTIVE.md           # Relative path to parent
parent_criterion: SC-3               # Which parent criterion this decomposes
---
```

## bench.sh Output Contract

Projects may include `bench.sh` alongside `build.sh` and `test.sh`. The output contract:

- Exits 0 on success, non-zero on failure
- stdout is JSON lines, one per metric:

```json
{"metric": "throughput", "value": 53.24, "unit": "MIPS"}
{"metric": "latency_p99", "value": 4.4, "unit": "ms"}
{"metric": "memory_peak", "value": 128, "unit": "MB"}
```

## Invocation

```bash
# External script (guaranteed execution)
./scripts/project-check.sh <project-path> [flags]

# Interactive skill (Claude-assisted)
/project-check [project-name]
```

### Flags

| Flag | Effect |
|------|--------|
| `--structure-only` | Skip all content verification (fast) |
| `--no-build` | Skip build.sh |
| `--no-test` | Skip test.sh |
| `--no-orphans` | Skip orphan detection |
| `--no-subprojects` | Skip subproject recursion |
| `--no-skeptical` | Skip multi-pass skeptical verification |
| `--no-criterion-tests` | Skip deterministic evidence (Phase 4) |
| `--no-benchmarks` | Skip benchmark threshold verification |
| `--no-doc-audit` | Skip benchmark documentation audit |
| `--allow-unverified` | Allow PASS when verification infrastructure unavailable |
| `--regression-threshold N` | Regression threshold percent (default: 20) |
| `--skeptical-passes N` | Number of skeptical passes (default: 3) |
| `--verbose` | Show detailed output |
| `--json` | Output as JSON |

## Verification Phases

| Phase | Name | Purpose |
|-------|------|---------|
| 1 | Structural | OBJECTIVE.md, LOG.md, git, depth |
| 2 | Parse Criteria | Extract SC-N → Files, Tests, Benchmarks, Status |
| 3 | Classify Criteria | Mark each as leaf (≤80KB) or composite (subproject) |
| 4 | Deterministic Evidence | Run tests (hard gate), check Done criteria have tests |
| 4.5 | Semantic Verification | Claude verifies each leaf (gated by Phase 4, fail-closed, multi-pass skeptical) |
| 4.6 | Benchmarks | Run bench.sh + criterion benchmarks, verify thresholds, save results, detect regressions |
| 4.7 | Documentation Audit | Cross-reference markdown claims against actual benchmark results |
| 5 | Coverage Check | All files mapped? Violations for orphans |
| 6 | Subproject Recursion | verify(subproject) for each composite |
| 7 | Composition Check | Claude: "Do children compose to parent?" (with code) |
| 8 | External Verify | build.sh, test.sh |
| 9 | Summary | Hierarchical result with benchmark data |

### Deterministic Evidence (Phase 4)

**Tests are the hard gate.** Phase 4 runs before any Claude semantic verification:

1. For each leaf criterion, check if `**Tests:**` field exists
2. If criterion has `**Status:** Done` but no `**Tests:**` → **VIOLATION** (Evidence Invariant)
3. Run test commands, store results per criterion (PASS/FAIL/NO_TESTS)
4. Results gate Phase 4.5:
   - Tests FAIL → criterion is NOT_MET (Claude is never called)
   - Tests PASS → Claude can evaluate up to MET
   - No tests + Done → Claude verdict capped at PARTIAL

### Multi-Pass Skeptical Verification (Phase 4.5)

**Fail-closed by default.** Claude CLI unavailable or output unparseable → VIOLATION (not warning).
Use `--allow-unverified` to degrade to warnings instead.

When enabled (default 3 skeptical passes), each leaf criterion gets up to 4 verification passes:

1. **Pass 1 (verification):** "Does this code fully implement the criterion? Do not give benefit of the doubt."
2. **Pass 2 (hostile auditor):** "Your reputation depends on finding real deficiencies. False negatives are career-ending. Find concrete flaws with file:line citations."
3. **Pass 3 (burden reversal):** "This criterion is NOT MET until proven otherwise. List every requirement, cite exact code for each, mark ABSENT if not found."
4. **Pass 4 (minimal counterexample):** "Construct the simplest input/scenario that would cause this implementation to violate the criterion. Trace through the code."

**Aggregation (strict):**
- MET: Pass 1 = MET AND ALL skeptical passes find no significant issues
- PARTIAL: Pass 1 = MET but ANY skeptical pass finds issues
- NOT_MET: Pass 1 = NOT_MET OR tests failed (Phase 4)

**Fail-closed in skeptical passes:** If any skeptical pass produces unparseable output or fails to run, gaps are ASSUMED (not ignored). This prevents infrastructure failures from inflating verification results.

Use `--no-skeptical` for single-pass verification (faster, less thorough).

### Benchmark Verification (Phase 4.6)

Runs `bench.sh` first (if present) to collect project-level metrics, then runs `**Benchmark:**` commands from each SC-N section and checks thresholds.

**Output parsing priority:**
1. JSON-line format: `{"metric": "name", "value": 123.4}` — parsed with jq
2. Regex fallback: `metric_name: value` or `metric_name = value` — grep extraction

**Saved results:** `$CHECK_DIR/benchmark-results.json` — structured per-criterion metrics.

**Regression detection:** Compares current results against `.project-metadata/benchmark-latest.json` from the previous run. Flags metrics that regressed by more than `--regression-threshold` percent (default: 20%). Direction-aware: for `>` thresholds (higher is better), a decrease is a regression; for `<` thresholds (lower is better), an increase is a regression.

### Documentation Audit (Phase 4.7)

Cross-references documented benchmark claims in markdown files against actual results from Phase 4.6 and bench.sh.

**Claim discovery:**
- Files matching `*BENCHMARK*`, `*RESULTS*`, `*PERF*` (case-insensitive)
- `bench/README.md` if present
- OBJECTIVE.md when it contains inline performance numbers (e.g., `~53 MIPS`, `15 K/s`)
- Excludes vendor/, node_modules/, target/, .git/

**Classification:**

| Status | Meaning | Severity |
|--------|---------|----------|
| ALIGNED | Actual result within 2x of documented claim | Pass |
| STALE | Actual result differs by >2x from documented claim | Violation |
| UNVERIFIABLE | No benchmark ran for this claim | Warning |

### Code-Level Composition (Phase 7)

When child criteria total ≤80KB, actual code is included in the composition prompt (not just criterion headers). This provides semantic verification that children truly implement the parent.

## Verification Algorithm

```
verify(objective):
  for each criterion:
    if leaf (files ≤ 80KB):
      run tests (hard gate)
      if tests fail: NOT_MET
      Claude pass 1: "Does this code implement this criterion?"
      Claude pass 2: "Find flaws as a hostile auditor" (file:line)
      Claude pass 3: "Prove each requirement with code or mark ABSENT"
      Claude pass 4: "Construct minimal counterexample"
      aggregate: MET only if tests pass AND all passes clean
    if composite (has **Subproject:** field):
      verify(subproject)  # recursive
      Claude: "Do child criteria compose to implement parent?"
  run benchmarks, check thresholds, save results
  audit documented claims against actual results
```

## Stored Results

```
.project-metadata/
├── last-check.json              # Most recent result summary
├── benchmark-latest.json        # Latest benchmark results (for regression detection)
└── check-YYYYMMDD-HHMMSS/
    ├── criteria.txt             # Parsed SC-N → files
    ├── criteria-classified.txt  # With type: leaf|composite
    ├── infrastructure.txt
    ├── orphans.txt
    ├── benchmark-results.json   # Structured benchmark results
    ├── documentation-audit.json # Claim cross-reference results
    ├── SC-1.json                # Pass 1 verification
    ├── SC-1-adversarial.json    # Pass 2 hostile auditor
    ├── SC-1-reversal.json       # Pass 3 burden reversal
    ├── SC-1-counterexample.json # Pass 4 minimal counterexample
    ├── SC-1-tests.log           # Test output
    ├── SC-1-benchmark.log       # Raw benchmark output
    ├── SC-3-composition.json    # Composition verification
    ├── subprojects/             # Recursive results
    │   └── crates-stwo-prover.json
    ├── build.log
    ├── test.log
    └── bench.log                # bench.sh output
```

## Error Handling

| Error | Response |
|-------|----------|
| OBJECTIVE.md missing | FAIL immediately |
| No SC-N criteria found | FAIL with format instructions |
| Leaf criterion >80KB | VIOLATION: decomposition required |
| Done criterion without tests | VIOLATION: deterministic evidence required |
| Claude CLI unavailable | VIOLATION (or WARNING with --allow-unverified) |
| Verification output unparseable | VIOLATION (or WARNING with --allow-unverified) |
| Skeptical pass fails/unparseable | Gaps ASSUMED (fail-closed) |
| Tests fail | NOT_MET (Claude verification skipped) |
| Subproject missing parent_criterion | VIOLATION: metadata mismatch |
| Composition incomplete | VIOLATION: gaps in child→parent |
| Stale benchmark documentation | VIOLATION: documented claim >2x off from actual |
| Benchmark regression detected | WARNING: metric regressed beyond threshold |

## Use Cases

- **Before declaring complete** — Verify all criteria implemented with deterministic evidence
- **After decomposition** — Ensure subprojects cover parent criterion
- **Composition audit** — Verify children actually compose to parent
- **Benchmark integrity** — Ensure documented performance claims match reality
- **Regression guard** — Detect performance regressions between runs
- **CI integration** — `./scripts/project-check.sh $PROJECT --json`
