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

- Leaf criteria (≤80KB files) → verified directly by Claude
- Composite criteria (>80KB files) → decomposed into subproject
- 1:1 mapping: one oversized SC-N = one subproject
- Composition verified: child criteria → parent criterion

## Guarantee

| What | How |
|------|-----|
| Every leaf criterion verified | Bounded Claude call per criterion |
| Context never exceeded | Leaf ≤80KB enforced, composite = subproject |
| All files covered | Coverage check, orphans = violations |
| Composition sound | Claude verifies children → parent |
| Recursive verification | Subprojects verified same way |

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
- **Tests:** `command | test_files` — Test command and files to verify criterion
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

```markdown
# Stwo Prover

## Parent Context
**Project:** alpha
**Parent Criterion:** SC-3 — Performant browser proving (≥1 MHz)

## Success Criteria

### SC-1: Constraint system
**Status:** Done
**Files:**
- `src/constraints.rs`
**Verification:** Unit tests pass
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
| `--no-criterion-tests` | Skip per-criterion test verification |
| `--no-benchmarks` | Skip benchmark threshold verification |
| `--skeptical-passes N` | Number of skeptical passes (default: 2) |
| `--verbose` | Show detailed output |
| `--json` | Output as JSON |

## Verification Phases

| Phase | Name | Purpose |
|-------|------|---------|
| 1 | Structural | OBJECTIVE.md, LOG.md, git, depth |
| 2 | Parse Criteria | Extract SC-N → Files, Tests, Benchmarks |
| 3 | Classify Criteria | Mark each as leaf (≤80KB) or composite (subproject) |
| 4 | Leaf Verification | Claude verifies each leaf criterion (multi-pass skeptical) |
| 4.5 | Criterion Tests | Run per-criterion tests, verify pass |
| 4.6 | Benchmarks | Run benchmarks, verify thresholds |
| 5 | Coverage Check | All files mapped? Violations for orphans |
| 6 | Subproject Recursion | verify(subproject) for each composite |
| 7 | Composition Check | Claude: "Do children compose to parent?" (with code) |
| 8 | External Verify | build.sh, test.sh |
| 9 | Summary | Hierarchical result |

### Multi-Pass Skeptical Verification (Phase 4)

When enabled (default), each leaf criterion gets 3 verification passes:

1. **Pass 1 (existing):** "Does this code implement the criterion?"
2. **Pass 2 (adversarial):** "Find reasons this code does NOT implement it"
3. **Pass 3 (edge cases):** "Identify unhandled edge cases and errors"

**Aggregation:**
- MET: Pass 1 = MET AND Passes 2+3 find no significant gaps
- PARTIAL: Pass 1 = MET but gaps found in skeptical passes
- NOT_MET: Pass 1 = NOT_MET (skip additional passes)

Use `--no-skeptical` for single-pass verification (faster, less thorough).

### Code-Level Composition (Phase 7)

When child criteria total ≤80KB, actual code is included in the composition prompt (not just criterion headers). This provides semantic verification that children truly implement the parent.

## Verification Algorithm

```
verify(objective):
  for each criterion:
    if leaf (files ≤ 80KB):
      Claude: "Do these files implement this criterion?"
    if composite (has **Subproject:** field):
      verify(subproject)  # recursive
      Claude: "Do child criteria compose to implement parent?"
```

## JSON Output (v2)

```json
{
  "version": 2,
  "outcome": "PASS|FAIL",
  "project": {"path": "...", "depth": 1},
  "criteria": {
    "SC-1": {
      "type": "leaf",
      "size_bytes": 45000,
      "status": "MET",
      "evidence": [...]
    },
    "SC-3": {
      "type": "composite",
      "subproject": "crates/stwo-prover/",
      "child_outcome": "PASS",
      "composition": {
        "status": "SOUND",
        "children": ["SC-1", "SC-2", "SC-3"]
      }
    }
  },
  "coverage": {
    "total_files": 25,
    "mapped_files": 25,
    "orphans": []
  },
  "subprojects": {
    "crates/stwo-prover/": {
      "parent_criterion": "SC-3",
      "outcome": "PASS",
      "criteria": {...}
    }
  }
}
```

## Stored Results

```
.project-metadata/
├── last-check.json           # Most recent result summary
└── check-YYYYMMDD-HHMMSS/
    ├── criteria.txt          # Parsed SC-N → files
    ├── criteria-classified.txt  # With type: leaf|composite
    ├── infrastructure.txt
    ├── orphans.txt
    ├── SC-1.json             # Leaf verification
    ├── SC-3-composition.json # Composition verification
    ├── subprojects/          # Recursive results
    │   └── crates-stwo-prover.json
    ├── build.log
    └── test.log
```

## Error Handling

| Error | Response |
|-------|----------|
| OBJECTIVE.md missing | FAIL immediately |
| No SC-N criteria found | FAIL with format instructions |
| Leaf criterion >80KB | VIOLATION: decomposition required |
| Subproject missing parent_criterion | VIOLATION: metadata mismatch |
| Composition incomplete | VIOLATION: gaps in child→parent |

## Use Cases

- **Before declaring complete** — Verify all criteria implemented
- **After decomposition** — Ensure subprojects cover parent criterion
- **Composition audit** — Verify children actually compose to parent
- **CI integration** — `./scripts/project-check.sh $PROJECT --json`
