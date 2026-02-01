---
name: project-check
description: Enforce project invariants - structure, alignment, and coherency
constitution: CLAUDE.md
alignment:
  - Work Modes
  - Memory System / Projects
  - Memory System / Repository Model
  - Memory System / Project Decomposition
  - Verification System / Verification Depth
  - Traceability System
  - Memory System / Learnings
  - Context Persistence / Context Invariants
  - Context Persistence / State Externalization
  - Foundational Goal
---

# /project-check

**Enforce project invariants.** After this skill completes successfully, all checked invariants are guaranteed to hold. Violations are either auto-repaired or user-resolved (blocking until resolved).

## Invocation

```
/project-check [project-name] [flags]
```

### Core Flags

| Flag | Effect |
|------|--------|
| `--shallow` | Skip recursive subproject checks (current level only) |
| `--force` | Ignore inventory cache, re-read all files |
| `--auto-repair` | Repair auto-fixable violations without prompting |

### Audit Scope Flags

| Flag | Effect | Default |
|------|--------|---------|
| `--no-content` | Skip content alignment audit | Enabled |
| `--no-verification` | Skip build/test verification | Enabled |
| `--no-process` | Skip process compliance (learnings, drift) | Enabled |
| `--structure-only` | Only check structural invariants (implies all `--no-*` flags) | — |

### Audit Inclusion Flags (Opt-In)

| Flag | Effect | Default |
|------|--------|---------|
| `--with-quality` | Include code quality checks (dead code, TODOs, naming, patterns) | Disabled |
| `--with-autonomous` | Include autonomous log audit | Disabled |
| `--with-analyses` | Include analysis directory audit | Disabled |

## Guarantee

**After successful completion (`PASS`):**
- ALL checked invariants hold
- Every violation was either auto-repaired or user-resolved
- Subprojects recursively passed (unless `--shallow`)

**This skill blocks until invariants hold.** Non-auto-repairable violations require user resolution before the skill can pass. The user must either:
1. Fix the violation
2. Acknowledge as explicit exception (with reason)

There is no "report and exit" mode for hard invariants.

## Outcome (Binary)

| Outcome | Meaning |
|---------|---------|
| `PASS` | All checked invariants hold (including any user-resolved) |
| `FAIL` | User explicitly declined to resolve a violation |

**No intermediate states.** The skill either succeeds completely or fails explicitly.

**FAIL requires explicit user action:** The skill only fails if the user actively chooses "decline to fix" for a violation. Abandoned sessions don't produce FAIL — they produce no outcome (incomplete).

## Invariant Classification

**All invariants are blocking.** The skill cannot pass until every checked invariant holds.

### Structural Invariants (Always Checked)

| Invariant | Definition | Auto-Repairable |
|-----------|------------|-----------------|
| **Structure Exists** | OBJECTIVE.md and LOG.md present and parseable | Yes (create from template) |
| **Repository Model** | Project is own git repo, not in workspace repo | No (requires restructure) |
| **Objective Defined** | OBJECTIVE.md has at least one success criterion | No (requires user input) |
| **Depth Limit** | Hierarchy ≤ 3 levels | No (requires restructure) |
| **Trace Connected** | Every level connects to parent objective | Yes (add trace reference) |
| **Submodules Pinned** | Submodules pinned to commits, not branches | Yes (pin to current) |

### Content Invariants (unless `--no-content`)

**These invariants require semantic understanding of file contents, not just structural checks.**

| Invariant | Definition | Auto-Repairable |
|-----------|------------|-----------------|
| **Objective Coverage** | Every success criterion has files that demonstrably implement it | No (requires implementation) |
| **Implementation Alignment** | Files claimed to implement SC-N actually implement SC-N (verified by reading code) | No (requires code fix or reclassification) |
| **Orphan Awareness** | Significant code not connected to objectives is identified and acknowledged | Yes (record in classification.json) |
| **Imports Resolve** | No broken import/require statements | No (requires code fix) |
| **No Circular Dependencies** | No circular module dependencies | No (requires restructure) |
| **Subproject Interfaces** | Subprojects implement declared interfaces (verified semantically) | No (requires implementation) |

**Note on Orphan Awareness:** Unlike "No Orphan Functionality", this invariant doesn't block on orphan code existing. It requires orphan code to be *identified and acknowledged* — either linked to an objective, marked as infrastructure, or explicitly excepted. Unacknowledged orphans block; acknowledged ones don't.

### Verification Invariants (unless `--no-verification`)

**Directly supports CLAUDE.md principle: "Work is provably correct (tests pass, builds work, criteria met)"**

| Invariant | Definition | Auto-Repairable |
|-----------|------------|-----------------|
| **Build Passes** | Project builds/compiles without errors | No (requires code fix) |
| **Tests Pass** | All tests pass (or failures explicitly acknowledged) | No (requires code fix or exception) |
| **Criteria Checkable** | Each SC-N has a defined verification method (test, manual check, etc.) | No (requires adding verification method) |

**Build detection:** Auto-detects build system (package.json, Cargo.toml, Makefile, etc.) and runs appropriate build command. If no build system detected, invariant is skipped.

**Test detection:** Auto-detects test runner and runs tests. If no tests detected, warns but doesn't block (tests are recommended, not required).

### Process Invariants (unless `--no-process`)

| Invariant | Definition | Auto-Repairable |
|-----------|------------|-----------------|
| **Drift Acceptable** | LOG.md work aligns with OBJECTIVE.md (not significant) | No (requires reassessment) |
| **Learnings Propagated** | Propagation-worthy learnings in LEARNINGS.md | Yes (copy to LEARNINGS.md) |

### Quality Invariants (only with `--with-quality`)

**These are code hygiene checks, not core project management. Opt-in only.**

| Invariant | Definition | Auto-Repairable |
|-----------|------------|-----------------|
| **Naming Consistent** | Variables/functions follow same convention | No (requires refactor) |
| **Pattern Consistent** | Similar problems solved similarly | No (requires refactor) |
| **Dead Code Limited** | Unused exports/unreachable code <5% of files | No (requires cleanup) |
| **TODOs Managed** | No TODOs older than 50 commits, total <20 | No (requires triage) |

## Purpose

Unlike `/project-start` (lightweight orientation), this skill **enforces** invariants with **blocking resolution**:
- Detects violations across structure, content, coherency, process, and quality
- Auto-repairs where possible
- **Blocks and waits** for user resolution on non-auto-repairable violations
- Verifies all repairs and fixes
- Recurses into subprojects with same guarantees
- Only passes when ALL checked invariants hold

**Audit scope is configurable** via flags. By default, all audit types are enabled. Use `--no-*` flags to narrow scope, or `--structure-only` for minimal checking.

Use when:
- Resuming after extended break
- Before major milestones
- When something feels wrong
- Periodic health checks
- **Before declaring objective complete** — Verify all code aligns with stated goals
- **After significant refactoring** — Re-establish invariants
- **Before merging branches** — Ensure invariants hold post-merge

## Verification Checklist

All checks are **blocking** — the skill cannot pass until each enabled check passes.

### Structural (Always Enabled)

| Check | Maps to Invariant |
|-------|-------------------|
| OBJECTIVE.md exists and parseable | Structure Exists |
| LOG.md exists and parseable | Structure Exists |
| Project is own git repo | Repository Model |
| At least one success criterion defined | Objective Defined |
| Hierarchy depth ≤ 3 | Depth Limit |
| Objective trace connects to root | Trace Connected |
| Submodules pinned to commits | Submodules Pinned |

### Content (unless `--no-content`)

**Requires semantic analysis — agents read and understand file contents.**

| Check | Maps to Invariant |
|-------|-------------------|
| Every SC-N has implementing files with evidence | Objective Coverage |
| Files classified for SC-N actually implement SC-N | Implementation Alignment |
| Orphan code identified and acknowledged | Orphan Awareness |
| All imports resolve to valid targets | Imports Resolve |
| No circular module dependencies | No Circular Dependencies |
| Subprojects fulfill declared interface contracts | Subproject Interfaces |

### Verification (unless `--no-verification`)

**Directly supports "tests pass, builds work, criteria met".**

| Check | Maps to Invariant |
|-------|-------------------|
| Project builds without errors | Build Passes |
| All tests pass (or failures acknowledged) | Tests Pass |
| Each SC-N has defined verification method | Criteria Checkable |

### Process (unless `--no-process`)

| Check | Maps to Invariant |
|-------|-------------------|
| LOG.md work aligns with OBJECTIVE.md | Drift Acceptable |
| Propagation-worthy learnings in LEARNINGS.md | Learnings Propagated |

### Quality (only with `--with-quality`)

**Opt-in code hygiene checks.**

| Check | Maps to Invariant |
|-------|-------------------|
| Naming follows consistent convention | Naming Consistent |
| Similar problems solved similarly | Pattern Consistent |
| Dead code <5% of files | Dead Code Limited |
| TODOs <20 total, none >50 commits old | TODOs Managed |

### Optional Audits

| Check | Flag Required | Description |
|-------|---------------|-------------|
| AUTONOMOUS-LOG.md valid | `--with-autonomous` | Format and completeness |
| analysis/INDEX.md valid | `--with-analyses` | Entries match files, predictions tracked |

### Subproject (unless `--shallow`)

| Check | Description |
|-------|-------------|
| All subprojects discovered | Subdirectory and submodule |
| Each subproject passes project-check | Recursive with same flags |
| All subprojects pass | Parent cannot pass if any child fails |

## Protocol

The protocol follows a **Detect → Repair → Verify** loop for each invariant class.

### Phase 1: Project Resolution & Baseline

1. **Resolve project** — Find and validate project path
2. **Git state snapshot** — `git status`, `git stash` if needed for clean baseline
3. **Read project metadata** — OBJECTIVE.md, LOG.md, LEARNINGS.md
4. **Initialize violation registry** — Track detected violations and repair status

### Phase 2: Hard Invariant Enforcement (Structural)

For each structural hard invariant:

5. **Detect** — Check if invariant holds
6. **If violated:**
   - If auto-repairable: **Repair** → **Verify** repair succeeded
   - If not auto-repairable: **Register** for user escalation
7. **Record** — Log violation and resolution in registry

Structural invariants checked:
- Structure exists (OBJECTIVE.md, LOG.md)
- Repository model (own git repo)
- Objective defined (has success criteria)
- Depth limit (≤ 3 levels)
- Trace connected (links to parent)
- Context state current

### Phase 3: Content Alignment Enforcement (unless `--no-content`)

**This phase performs semantic analysis — understanding what code does and verifying alignment with objectives.**

8. **Initialize metadata directory** — Create `.project-metadata/` if missing
9. **Load caches** — Read inventory.json and classification.json if exist
10. **Spawn content reading swarm** — Parallel Explore agents per top-level directory:
    - Each agent reads ALL files in its subtree completely
    - Returns semantic summary: `{path, purpose, key_functions, imports, exports, dependencies}`
    - Agents understand what each file does, not just its structure
    - For deep directories, agents spawn sub-agents recursively
11. **Aggregate file understanding** — Merge all agent results into unified codebase model
12. **Detect changed files** — Compare hashes; re-analyze changed files only (unless `--force`)

13. **Spawn semantic analysis swarm** — Parallel agents with access to:
    - Full OBJECTIVE.md with success criteria (SC-1, SC-2, ...)
    - Aggregated file summaries
    - Previous classification.json (for delta analysis)

    **Objective Coverage Agent:**
    - For each success criterion SC-N:
      - Find files that implement it (based on semantic understanding)
      - Assess implementation completeness (full/partial/none)
      - Record evidence: "SC-1 implemented by login.ts:login(), token.ts:refresh()"
    - Violation if: any SC-N has no implementing files

    **Alignment Verification Agent:**
    - For each file classified as implementing SC-N:
      - Read and understand the file
      - Verify it actually implements SC-N (not just named/located appropriately)
      - Record evidence or mismatch
    - Violation if: file claims SC-N but doesn't implement it

    **Orphan Detection Agent:**
    - Find files with significant functionality (not trivial utilities)
    - Check if functionality traces to any objective
    - Classify as orphan if no connection found
    - Violation if: significant orphan code exists (>5% of codebase)

    **Dependency Graph Agent:**
    - Build import/export graph from file summaries
    - Find broken imports, circular dependencies, unused exports
    - Violation if: any broken imports

14. **Enforce content invariants** — For each violation from analysis swarm:
    - Register in violation registry
    - None are auto-repairable (require code changes or objective updates)

15. **Update caches:**
    - `.project-metadata/inventory.json` — File hashes and summaries
    - `.project-metadata/classification.json` — Semantic classifications with evidence

### Phase 4: Subproject Recursion (unless `--shallow`)

18. **Discover subprojects** — Scan for subdirectory and submodule subprojects
19. **Check interface compliance** — Subprojects implement parent-declared interfaces
20. **Spawn subproject swarm** — Parallel project-check on each subproject:
    - Each subproject gets its own swarm for content reading
    - **Inherits parent's audit scope flags** (--no-content, --no-coherency, etc.)
    - Depth-first within each, parallel across siblings
    - **Child FAIL → parent cannot pass** (blocking dependency)
21. **Aggregate** — Roll up child resolution logs to parent report

### Phase 5: Verification Invariants (unless `--no-verification`)

**Directly supports CLAUDE.md: "tests pass, builds work, criteria met"**

16. **Detect build system:**
    - Check for: package.json, Cargo.toml, Makefile, CMakeLists.txt, setup.py, go.mod, etc.
    - If none found: skip Build Passes (warn)

17. **Build Passes:**
    - Run detected build command (npm run build, cargo build, make, etc.)
    - Capture output
    - Violation if: build fails

18. **Detect test runner:**
    - Check for: jest, pytest, cargo test, go test, etc.
    - If none found: warn but don't block

19. **Tests Pass:**
    - Run detected test command
    - Capture output
    - Violation if: tests fail (unless explicitly acknowledged)

20. **Criteria Checkable:**
    - For each SC-N in OBJECTIVE.md:
      - Check if verification method is defined (test file, manual checklist, etc.)
    - Violation if: any SC-N lacks verification method

### Phase 6: Process Invariants (unless `--no-process`)

21. **Drift analysis** — Compare OBJECTIVE.md vs LOG.md work
22. **Learnings propagation** — Check propagation status

### Phase 7: Quality Invariants (only with `--with-quality`)

23. **Naming consistency** — Check convention uniformity
24. **Pattern consistency** — Check similar problems solved similarly
25. **Dead code analysis** — Check <5% threshold
26. **TODO/FIXME audit** — Check <20 total, none >50 commits old

### Phase 8: Optional Audits

27. **Autonomous audit** — If `--with-autonomous`, validate AUTONOMOUS-LOG.md
28. **Analyses audit** — If `--with-analyses`, validate analysis/INDEX.md

All violations from enabled scopes are blocking.

### Phase 9: Resolution Loop (Blocking)

**This phase blocks until all violations are resolved or user explicitly declines.**

29. **Process violation registry** — For each unresolved violation:

```
while violations remain:
    violation = next_unresolved()

    if auto_repairable(violation):
        repair(violation)
        if verify(violation):
            mark_resolved(violation, "Repaired")
        else:
            rollback(violation)
            # Fall through to user resolution

    if not resolved(violation):
        # BLOCKING: Present to user and wait
        present_violation(violation)

        # Semantic invariants get option 4 (dispute)
        if is_semantic_invariant(violation):
            options = [
                "Fix now (I'll verify after)",
                "Acknowledge as exception",
                "Decline to fix (FAIL)",
                "Dispute analysis (provide counter-evidence)"
            ]
        else:
            options = [
                "Fix now (I'll verify after)",
                "Acknowledge as exception",
                "Decline to fix (FAIL)"
            ]

        user_choice = prompt_user(options)

        if user_choice == "Fix now":
            wait_for_user_signal("Ready to verify")
            if verify(violation):
                mark_resolved(violation, "User fixed")
            else:
                # Loop: still unresolved, will re-present
                continue

        elif user_choice == "Acknowledge as exception":
            reason = prompt_user("Reason for exception:")
            expiry = prompt_user("Expiry date (optional):")
            record_exception(violation, reason, expiry)
            mark_resolved(violation, "Exception")

        elif user_choice == "Dispute analysis":
            counter_evidence = prompt_user("Provide counter-evidence:")
            # Re-run semantic analysis with user's context
            new_analysis = reanalyze_with_context(violation, counter_evidence)
            if new_analysis.resolves_violation:
                record_dispute_resolved(violation, counter_evidence, new_analysis)
                mark_resolved(violation, "Dispute resolved")
            else:
                # Analysis unchanged, re-present with explanation
                present_dispute_result(violation, new_analysis)
                # Loop continues, user can choose again
                continue

        elif user_choice == "Decline to fix":
            record_decline(violation)
            terminate_with_fail()
```

**Semantic invariants** (eligible for dispute):
- Objective Coverage
- Implementation Alignment
- No Orphan Functionality
- Subproject Interfaces

30. **Final verification sweep:**
    - Re-check ALL invariants (not just previously violated)
    - Any new violations → return to step 29
    - Confirm all repairs and exceptions still hold

31. **Determine outcome:**
    - All invariants hold (via repair, fix, or exception) → `PASS`
    - User declined any violation → `FAIL`

### Phase 10: Reporting & Persistence

32. **Generate report** — Full output with:
    - Outcome (PASS or FAIL)
    - Scope (which audit types were enabled)
    - Invariant status table (all checked invariants)
    - Resolution log (repairs, user fixes, exceptions)
    - Subproject status (if recursion enabled)

33. **Update metadata:**
    - `.project-metadata/last-check.json` — Outcome, timestamp, scope, counts
    - `.project-metadata/inventory.json` — Updated file hashes
    - `.project-metadata/coherency-cache.json` — Coherency analysis cache (if enabled)
    - `.project-metadata/exceptions.json` — Any new exceptions

34. **Commit repairs** (if any made):
    - Single commit: "chore: project-check invariant repairs"
    - Only committed if outcome is PASS (don't commit partial repairs on FAIL)

## File Scanning Strategy

**All files are read.** The skill reads the entire repository contents using parallel sub-agent swarms for speed.

### Sub-Agent Swarm Architecture

```
Orchestrator (project-check)
│
├── Phase A: Content Reading Swarm (parallel)
│   ├── src/ agent → reads and summarizes all files in src/
│   ├── lib/ agent → reads and summarizes all files in lib/
│   ├── test/ agent → reads and summarizes all files in test/
│   └── ... (one agent per top-level directory)
│
├── Phase B: Semantic Analysis Swarm (parallel, after aggregation)
│   ├── Objective Coverage agent → for each SC-N, find implementing files
│   ├── Alignment Verification agent → verify claimed implementations actually implement
│   ├── Orphan Detection agent → find significant code not connected to objectives
│   ├── Dependency Graph agent → trace imports/exports, find broken refs
│   └── Coherency agent → check naming/patterns/architecture
│
├── Phase C: Subproject Swarm (parallel)
│   └── ... (recursive project-check per subproject)
│
└── Synthesize findings and enforce invariants
```

**Phase A: Content Reading**
- Spawn one Explore agent per top-level directory (parallel)
- Each agent reads ALL files in its subtree completely
- Agents return semantic summaries: `{path, purpose, key_functions, imports, exports, dependencies}`
- For deep directories, agents spawn sub-agents recursively
- Maximum fan-out: 10 parallel agents per level

**Phase B: Semantic Analysis (the core of content checking)**
- Receives aggregated file summaries + full OBJECTIVE.md with success criteria
- Each analysis agent performs deep semantic reasoning:

| Agent | Task |
|-------|------|
| **Objective Coverage** | For each SC-N: find files that implement it, assess completeness |
| **Alignment Verification** | For each "core" file: verify it actually does what it claims |
| **Orphan Detection** | Find files with significant logic not traceable to any objective |
| **Dependency Graph** | Build import graph, find broken refs, circular deps, unused exports |
| **Coherency** | Assess naming consistency, pattern consistency, architecture coherence |

**File type handling:**

| Type | Action |
|------|--------|
| Source code (.py, .js, .ts, .rs, etc.) | Full read, extract imports/exports |
| Config files (.json, .yaml, .toml, etc.) | Full read, extract settings |
| Documentation (.md, .txt, .rst) | Full read, extract structure |
| Binary files | Hash only, note existence |
| Generated directories (node_modules, build/, dist/) | Skip contents, verify in .gitignore |
| Large files (>500KB) | Read in chunks, summarize |

**Inventory caching:**
- File inventory stored in `.project-metadata/inventory.json`
- Includes file hash for change detection
- On subsequent runs, only re-read files with changed hash
- Full re-scan if `--force` flag provided

### Classification Categories

| Category | Definition | Examples |
|----------|------------|----------|
| **Core** | Directly implements success criteria | Main application code |
| **Infrastructure** | Supports core but not criteria-specific | Build config, CI, tooling |
| **Documentation** | Explains or documents the project | README, docs/, comments |
| **Test** | Verifies implementation | test/, spec/, *_test.* |
| **Generated** | Output of build/tooling | dist/, node_modules/ |
| **Unknown** | Cannot map to any objective | Requires investigation |

## Output Format

```
## Outcome: PASS | FAIL

## Summary
[1-2 sentence: what was enforced, how violations were resolved]

## Scope
- Structural: ✓ (always)
- Content: ✓ / ✗ (--no-content)
- Verification: ✓ / ✗ (--no-verification)
- Process: ✓ / ✗ (--no-process)
- Quality: ✗ / ✓ (--with-quality)
- Subprojects: ✓ / ✗ (--shallow)
- Repository: [N] files scanned

---

## Invariant Status

All checked invariants must show ✓ for PASS.

### Structural (Always)

| Invariant | Initial | Resolution | Final |
|-----------|---------|------------|-------|
| Structure Exists | ✓/✗ | — / Repaired | ✓ |
| Repository Model | ✓/✗ | — / User fixed | ✓ |
| Objective Defined | ✓/✗ | — / User fixed | ✓ |
| Depth Limit | ✓/✗ | — | ✓ |
| Trace Connected | ✓/✗ | — / Repaired | ✓ |
| Submodules Pinned | ✓/✗/N/A | — / Repaired | ✓ |

### Content (if enabled)

| Invariant | Initial | Resolution | Final |
|-----------|---------|------------|-------|
| Objective Coverage | ✓/✗ | — / User implemented | ✓ |
| Implementation Alignment | ✓/✗ | — / User fixed / Reclassified | ✓ |
| Orphan Awareness | ✓/✗ | — / Acknowledged | ✓ |
| Imports Resolve | ✓/✗ | — / User fixed | ✓ |
| No Circular Dependencies | ✓/✗ | — / User fixed | ✓ |
| Subproject Interfaces | ✓/✗/N/A | — / User implemented | ✓ |

### Verification (if enabled)

| Invariant | Initial | Resolution | Final |
|-----------|---------|------------|-------|
| Build Passes | ✓/✗/N/A | — / User fixed | ✓ |
| Tests Pass | ✓/✗/N/A | — / User fixed / Exception | ✓ |
| Criteria Checkable | ✓/✗ | — / User added verification | ✓ |

### Process (if enabled)

| Invariant | Initial | Resolution | Final |
|-----------|---------|------------|-------|
| Drift Acceptable | ✓/✗ | — / User reassessed | ✓ |
| Learnings Propagated | ✓/✗ | — / Repaired | ✓ |

### Quality (if enabled via --with-quality)

| Invariant | Initial | Resolution | Final |
|-----------|---------|------------|-------|
| Naming Consistent | ✓/✗ | — / User fixed / Exception | ✓ |
| Pattern Consistent | ✓/✗ | — / User fixed / Exception | ✓ |
| Dead Code Limited | ✓/✗ | — / User fixed / Exception | ✓ |
| TODOs Managed | ✓/✗ | — / User fixed / Exception | ✓ |

**Checked: [N] | Holding: [N] | Repaired: [N] | User Fixed: [N] | Disputes Resolved: [N] | Exceptions: [N]**

---

## Resolution Log

### Auto-Repaired

| ID | Invariant | Violation | Action | Verified |
|----|-----------|-----------|--------|----------|
| V001 | Learnings Propagated | 2 unpropagated | Copied to LEARNINGS.md | ✓ |

### User-Resolved

| ID | Invariant | Violation | User Action | Verified |
|----|-----------|-----------|-------------|----------|
| V003 | Objective Coverage | SC-3 not implemented | User implemented notifications | ✓ |
| V004 | Imports Resolve | `src/foo.ts:12` missing | User fixed import | ✓ |
| V005 | Objective Defined | No criteria | User added SC-1, SC-2 | ✓ |

### Disputes Resolved

| ID | Invariant | Original Analysis | Counter-Evidence | Revised Analysis |
|----|-----------|-------------------|------------------|------------------|
| V006 | Implementation Alignment | "utils/format.ts: Only string formatting" | "formatToken() used by auth system" | Reclassified: infrastructure supporting SC-1 |
| V007 | Orphan Functionality | "helpers/crypto.ts: No objective connection" | "Provides encryption for SC-2 data storage" | Reclassified: infrastructure supporting SC-2 |

### Exceptions

| ID | Invariant | Violation | Reason | Expiry |
|----|-----------|-----------|--------|--------|
| V008 | No Orphan Functionality | `src/legacy/xml-parser.ts` | "Keeping for potential data migration" | 2024-04-15 |
| V009 | Dead Code Limited | `utils/old-helpers.ts` | "Referenced by external scripts" | — |

### Declined (if FAIL)

| ID | Invariant | Violation |
|----|-----------|-----------|
| V010 | Circular Deps | A→B→C→A cycle |

---

## Subproject Status

| Subproject | Outcome | Checked | Repaired | Exceptions |
|------------|---------|---------|----------|------------|
| subprojects/auth | PASS | 15 | 1 | 0 |
| subprojects/api | PASS | 15 | 0 | 1 |

**All subprojects must PASS for parent to PASS.**

<details>
<summary>Subproject: [path] — PASS</summary>

[Full project-check output for subproject]

</details>

## Traceability Audit
- Full checkpoints (with Session: link): [count]
- Lightweight checkpoints (no Session: link): [count]
- LOG sessions: [count]
- Unlinked LOG sessions: [list if any]

## Learnings Audit
- Learnings marked Propagate: Yes in LOG.md: [count]
- Learnings in LEARNINGS.md: [count]
- Unpropagated learnings: [list if any]

## Failure Learning Quality Audit
For Failure-type learnings (FP-NNN), verify quality criteria:

| Learning | Reasoning | Counterfactual | Generalized | Pattern Class |
|----------|-----------|----------------|-------------|---------------|
| [FP-NNN] | ✓/✗       | ✓/✗            | ✓/✗         | ✓/✗           |

- Failure learnings meeting all criteria: [N/M]
- Missing fields: [list specific gaps]
- Quality compliance: [%]
- Recommendation: [none | generalize before propagating | add missing fields]

## Drift Analysis
[Comparison of stated objectives vs. actual work logged]
- Objective focus: [what OBJECTIVE.md says]
- Actual work: [what LOG.md shows]
- Alignment: [aligned | minor drift | significant drift]

## Semantic Content Analysis

### Objective Coverage (with Evidence)

For each success criterion, show implementing files with semantic evidence:

```
### SC-1: User authentication with OAuth support

**Status:** ✓ Complete
**Implementing Files:**

| File | Role | Evidence |
|------|------|----------|
| src/auth/login.ts | Primary | Implements `login()` with OAuth flow, `validateSession()` for token validation |
| src/auth/token.ts | Supporting | Implements `refreshToken()`, `revokeToken()` for token lifecycle |
| src/auth/providers/google.ts | Supporting | Google OAuth provider implementation |
| src/auth/providers/github.ts | Supporting | GitHub OAuth provider implementation |

**Assessment:** Full implementation of OAuth login with Google and GitHub providers.
Token refresh and revocation implemented. Session validation complete.

---

### SC-2: REST API for user management

**Status:** ⚠ Partial
**Implementing Files:**

| File | Role | Evidence |
|------|------|----------|
| src/api/users.ts | Primary | Implements GET /users, POST /users, GET /users/:id |
| src/api/middleware/auth.ts | Supporting | JWT validation middleware |

**Assessment:** CRUD operations partially implemented. Missing:
- PUT /users/:id (update user)
- DELETE /users/:id (delete user)

**Violation:** Objective Coverage — SC-2 incomplete

---

### SC-3: Real-time notifications

**Status:** ✗ Not Implemented
**Implementing Files:** None found

**Assessment:** No files implement WebSocket or notification logic.

**Violation:** Objective Coverage — SC-3 has no implementing files
```

### Implementation Alignment Verification

Files claiming to implement objectives, verified semantically:

| File | Claims | Verified | Evidence |
|------|--------|----------|----------|
| src/auth/login.ts | SC-1 | ✓ Yes | OAuth flow present, tokens handled correctly |
| src/api/users.ts | SC-2 | ⚠ Partial | CRUD incomplete (missing PUT, DELETE) |
| src/utils/format.ts | SC-1 | ✗ No | Only string formatting, no auth logic |

**Misalignment Violation:** src/utils/format.ts classified for SC-1 but doesn't implement it

### Orphan Functionality Detection

Significant code not connected to any objective:

| File | Functionality | Lines | Assessment |
|------|---------------|-------|------------|
| src/legacy/xml-parser.ts | XML parsing and transformation | 450 | No objective mentions XML; not imported by any other file |
| src/experiments/cache.ts | Redis caching layer | 200 | Caching not in objectives; partially imported but unused |

**Orphan Violation:** 650 lines (8% of codebase) not connected to objectives

### File Inventory Summary
```
- Total files analyzed: [N]
- By semantic category:
  - Core (implementing objectives): [N] files
  - Infrastructure (supporting core): [N] files
  - Test (verifying core): [N] files
  - Documentation: [N] files
  - Orphan (disconnected): [N] files
  - Exception (acknowledged): [N] files
```

### Coherency Analysis
```
- Naming consistency: [Pass/Warning/Fail] — [details]
- Pattern consistency: [Pass/Warning/Fail] — [details]
- Architecture coherence: [Pass/Warning/Fail] — [details]
- Style consistency: [Pass/Warning/Fail] — [details]
```

**Inconsistencies found:**
| Location | Issue | Severity |
|----------|-------|----------|
| [file:line] | [description] | low/medium/high |

### Cross-Reference Integrity
```
- Import statements checked: [N]
- Broken imports: [N]
- Circular dependencies: [N]
- Unused imports: [N]
```

**Broken references:**
- [file:line]: `import X` — X not found at [expected path]

### Dead Code Detection
```
- Unused exports: [N]
- Unreachable code paths: [N]
- Stale dependencies in package files: [N]
```

**Dead code identified:**
| Location | Type | Evidence |
|----------|------|----------|
| [file:line] | unused export | no importers found |
| [file:line] | unreachable | condition always false |

### TODO/FIXME Audit
```
- Total markers: [N]
- By priority:
  - FIXME (urgent): [N]
  - TODO (planned): [N]
  - HACK (technical debt): [N]
  - XXX (attention needed): [N]
```

**Outstanding markers:**
| Location | Marker | Content | Age |
|----------|--------|---------|-----|
| [file:line] | TODO | [text] | [commits since introduced] |

### Configuration Consistency
```
- Config files found: [list]
- Cross-config consistency: [Pass/Warning/Fail]
- Config-code alignment: [Pass/Warning/Fail]
```

**Issues:**
- [config file]: [inconsistency with other config or code]

## Subproject Audit

### Discovery
```
- Subdirectory subprojects: [N]
  - [path]: [objective summary]
- Submodule subprojects: [N]
  - [path] @ [commit]: [objective summary]
```

### Interface Compliance
For each subproject, verify it implements interfaces declared in parent:

| Subproject | Declared Interface | Implementation | Status |
|------------|-------------------|----------------|--------|
| [path] | [interface from parent OBJECTIVE.md] | [implementing files] | ✓/✗ |

### Recursive Health Summary
| Subproject | Health | Critical Issues | Warnings |
|------------|--------|-----------------|----------|
| [path] | HEALTHY/ISSUES/CRITICAL | [N] | [N] |

**Subproject details** (for any non-HEALTHY):
<details>
<summary>[subproject path] — [health status]</summary>

[Full project-check output for subproject, indented]

</details>

### Cross-Subproject Coherency
```
- Shared patterns consistent: [Pass/Warning/Fail]
- Naming conventions aligned: [Pass/Warning/Fail]
- Dependency versions aligned: [Pass/Warning/Fail]
```

**Cross-subproject issues:**
- [issue description spanning multiple subprojects]

## Verification Compliance Audit

Audit whether verification protocols are being followed.

**Method:**
1. Get commits since last session: `git log --oneline --since="[last LOG.md session date]"`
2. For each commit, estimate tier from diff size
3. Check LOG.md for corresponding verification records

**Output:**
```
- Commits since last session: [N]
- Estimated Standard+ tier commits: [N]
- Commits with verification record in LOG.md: [N]
- Compliance rate: [N/M = %]
- Missing verification (Standard+ without record):
  - [commit hash]: [summary] — [estimated tier]
  - ...
```

**Interpretation:**
| Compliance | Status |
|------------|--------|
| 100% | Pass |
| 75-99% | Warning — minor gaps |
| <75% | Fail — systematic skip |

## Plan Agent Audit

Check whether Plan agents consulted LEARNINGS.md.

**Method:**
1. Search LOG.md for plan-related entries (approach selection, trade-off analysis)
2. Check if "Applicable Learnings" or LEARNINGS.md reference exists
3. Flag plans without learnings consultation

**Output:**
```
- Planning sessions in LOG.md: [N]
- Plans citing LEARNINGS.md: [N]
- Plans without learnings reference:
  - Session [date]: [plan topic]
  - ...
- Compliance rate: [%]
```

## Autonomous Audit

If AUTONOMOUS-LOG.md exists, validate format and completeness.

**Checks:**
| Check | Expected |
|-------|----------|
| File exists | If autonomous mode was used |
| Run header present | Configuration section with branch, budget, session ID |
| Checkpoints numbered | Sequential checkpoint-NNN |
| Checkpoint format valid | Context, Choice/Finding/Problem, Rationale, Confidence, Files, Tag |
| Termination recorded | Reason, Elapsed, Summary, Unresolved, For Review |
| Tags exist | `git tag` includes checkpoint-NNN for each logged checkpoint |

**Output:**
```
- AUTONOMOUS-LOG.md exists: [yes/no/N/A]
- Runs logged: [N]
- Last run: [date] — [status]
- Checkpoints: [N]
- Tags matching checkpoints: [N/M]
- Format valid: [yes/no]
- Issues:
  - [issue description]
```

## Analyses Audit

If analysis/ directory exists, validate structure and consistency.

**Checks:**
| Check | Expected |
|-------|----------|
| INDEX.md exists | If analysis/ directory exists |
| INDEX.md format valid | Main table + Topic Index |
| Entries match files | Each A###-*.md in directory has INDEX.md entry |
| Files match entries | Each INDEX.md entry has corresponding file |
| Topics consistent | Topic Index references valid analysis IDs |
| Status values valid | active, validated, superseded, or archived |
| Predictions tracked | Predictions have validation status (⏳/✓/✗) |

**Output:**
```
- analysis/ exists: [yes/no]
- INDEX.md valid: [yes/no]
- Analyses: [N]
- Status breakdown: [N active, N validated, N superseded]
- Orphaned files (no INDEX entry): [list]
- Missing files (INDEX entry, no file): [list]
- Pending predictions: [N]
- Falsified predictions without learnings: [list]
- Issues:
  - [issue description]
```

## Issues
1. [Issue] — [severity: low/medium/high] — [remediation]
2. ...

## Recommendations
1. [Priority 1 action]
2. [Priority 2 action]
```

## User Resolution (Blocking)

When a non-auto-repairable violation is detected, the skill **blocks and waits** for user resolution. The user must choose one of three options:

### Option 1: Fix Now

```
Violation: Imports Resolve
Location: src/foo.ts:12
Issue: Cannot resolve import './bar'

[1] Fix now (I'll verify after)
[2] Acknowledge as exception
[3] Decline to fix (FAIL)

> 1

Make your fix, then signal when ready...
> ready

Verifying... ✓ Import now resolves.
```

The skill waits for the user to make the fix, then re-verifies.

### Option 2: Acknowledge as Exception

```
Violation: Dead Code Limited
Location: utils/legacy.ts
Issue: File has no importers (unused)

[1] Fix now (I'll verify after)
[2] Acknowledge as exception
[3] Decline to fix (FAIL)

> 2

Reason for exception: Migration reference, needed for rollback
Expiry (optional, YYYY-MM-DD): 2024-04-15

Exception recorded. Continuing...
```

Exceptions are logged and the violation is marked resolved. On future checks, exceptions are noted but not re-escalated (unless expired).

### Option 3: Decline to Fix

```
Violation: Circular Deps
Location: A.ts → B.ts → C.ts → A.ts
Issue: Circular module dependency detected

[1] Fix now (I'll verify after)
[2] Acknowledge as exception
[3] Decline to fix (FAIL)

> 3

Check terminated with FAIL.
Reason: User declined to resolve violation V007 (Circular Deps)
```

The skill immediately terminates with FAIL. No further violations are processed.

### Option 4: Dispute Analysis (Semantic Invariants Only)

For semantic invariants, the agent's analysis might be wrong. Option 4 allows disputing the analysis with counter-evidence.

```
Violation: Implementation Alignment
File: src/utils/format.ts
Agent's Analysis: "Only string formatting utilities, no authentication logic"
Claimed Objective: SC-1 (User authentication)

[1] Fix now (I'll verify after)
[2] Acknowledge as exception
[3] Decline to fix (FAIL)
[4] Dispute analysis (provide counter-evidence)

> 4

Provide counter-evidence for why this analysis is incorrect:
> This file provides formatToken() and parseAuthHeader() which are
> essential utilities for the auth system. See usage in login.ts:45
> and middleware/auth.ts:12. The function names don't mention "auth"
> but they're specifically designed for token handling.

Re-analyzing src/utils/format.ts with additional context...

Updated Analysis:
- formatToken(): Formats JWT tokens for storage/transmission
- parseAuthHeader(): Extracts bearer token from Authorization header
- Used by: src/auth/login.ts, src/middleware/auth.ts

Revised Classification: infrastructure (supports SC-1)
Violation resolved: File correctly supports authentication objective.
```

**When dispute is rejected:**

```
Re-analyzing src/legacy/parser.ts with additional context...

Analysis Unchanged:
- Your counter-evidence: "Used for config parsing"
- Finding: File parses XML, but config files are JSON (see config/*.json)
- No imports of this file found in codebase
- Original analysis stands: Orphan functionality

Violation remains. Choose another option:
[1] Fix now
[2] Acknowledge as exception
[3] Decline to fix (FAIL)
[4] Dispute again with different evidence
```

**Dispute eligibility:**

| Invariant | Disputable | Rationale |
|-----------|------------|-----------|
| Objective Coverage | Yes | Agent may miss implementing files |
| Implementation Alignment | Yes | Agent may misunderstand code purpose |
| No Orphan Functionality | Yes | Agent may miss connections to objectives |
| Subproject Interfaces | Yes | Agent may misjudge interface fulfillment |
| Imports Resolve | No | Syntactic, objectively verifiable |
| Structural invariants | No | Objectively verifiable |
| Coherency invariants | Partial | Naming/patterns somewhat subjective |
| Process invariants | No | Based on document analysis, not code semantics |
| Quality invariants | No | Based on metrics, not interpretation |

### Violation-Specific Guidance

| Violation | Typical Resolution |
|-----------|-------------------|
| **Repository Model** | Create separate repo and move project |
| **Objective Undefined** | Add success criteria to OBJECTIVE.md |
| **Depth Exceeded** | Flatten hierarchy or convert subproject to separate repo |
| **Objective Coverage (missing)** | Implement the missing functionality or revise objective |
| **Objective Coverage (partial)** | Complete the implementation |
| **Implementation Alignment** | Fix code to match claim, or reclassify file correctly |
| **Orphan Functionality** | Link to objective, add objective, remove code, or acknowledge as exception |
| **Broken Imports** | Fix import path, add dependency, or remove dead import |
| **Interface Not Implemented** | Implement interface or revise parent spec |
| **Naming Inconsistent** | Refactor to consistent convention or acknowledge |
| **Circular Deps** | Restructure to break cycle |
| **Drift Significant** | Reassess objectives or realign work |
| **Dead Code Excessive** | Clean up or acknowledge files individually |
| **TODOs Excessive** | Triage: resolve, remove, or schedule |

### Exception Constraints

- Exceptions require a reason (not optional)
- Expiry is optional but recommended for temporary exceptions
- Accumulated exceptions (>5 active) trigger a meta-warning
- On subsequent checks:
  - Non-expired exceptions are noted, not re-escalated
  - Expired exceptions are re-escalated for review
  - User can choose to extend, resolve, or decline

## Auto-Repair Capabilities

The following violations are automatically repairable (no user interaction needed):

| Invariant | Auto-Repair Action |
|-----------|-------------------|
| **Structure Missing** | Create OBJECTIVE.md and LOG.md from templates |
| **Trace Disconnected** | Add parent reference to OBJECTIVE.md |
| **Submodule Unpinned** | Run `git submodule update --init`, record commit hash |
| **Learnings Unpropagated** | Copy to appropriate LEARNINGS.md level |
| **Analysis INDEX Stale** | Regenerate INDEX.md from analysis/*.md files (if `--with-analyses`) |

**Content invariants are NOT auto-repairable** because they require semantic understanding:
- Objective Coverage → requires implementation
- Implementation Alignment → requires code changes or reclassification decision
- Orphan Functionality → requires linking to objective or removal decision
- Imports Resolve → requires code fix

**Repair protocol:**
1. Attempt repair
2. Re-verify the specific invariant
3. If verification passes → mark resolved as "Repaired"
4. If verification fails → rollback repair, escalate to user resolution

**Repair commit:**
All repairs in a single check run are committed together:
```
chore: project-check invariant repairs

Repaired:
- [V001] Context state regenerated
- [V002] 3 files classified

Session: [LOG.md session if active]
Co-Authored-By: Claude <noreply@anthropic.com>
```

## Invariant Thresholds

Some invariants use thresholds to define "violation":

| Invariant | Threshold | Rationale |
|-----------|-----------|-----------|
| **Dead Code Limited** | <5% of files | Some dead code is acceptable during development |
| **TODOs Managed** | <20 total, none >50 commits old | Prevents accumulation, allows short-term markers |
| **Verification Compliant** | ≥75% of Standard+ commits | Allows occasional gaps, catches systematic skip |
| **Drift Acceptable** | Not classified as "significant" | Minor drift is normal; significant requires reassessment |

**Threshold violations are still blocking.** The threshold defines what constitutes a violation, not whether violations block.

## Metadata Directory

All project-check metadata is stored in `.project-metadata/`:

```
.project-metadata/
├── inventory.json        # File inventory with hashes (for incremental checks)
├── classification.json   # File-to-objective mappings
├── exceptions.json       # Acknowledged violations
├── coherency-cache.json  # Cached coherency analysis
└── last-check.json       # Results of last check run
```

**Directory should be committed** to the repository (not gitignored) so that:
- Classification decisions persist across sessions
- Exceptions are tracked in version control
- Inventory cache enables incremental checks

### inventory.json Format

Contains semantic understanding of each file, not just structural data:

```json
{
  "version": 2,
  "generated": "2024-01-15T10:30:00Z",
  "files": {
    "src/auth/login.ts": {
      "size": 2048,
      "hash": "sha256:abc123...",
      "last_analyzed": "2024-01-15T10:30:00Z",
      "semantic": {
        "purpose": "Handles user authentication via OAuth providers",
        "key_functions": [
          {"name": "login", "does": "Initiates OAuth flow, returns session token"},
          {"name": "logout", "does": "Invalidates session, revokes tokens"},
          {"name": "refreshToken", "does": "Exchanges refresh token for new access token"}
        ],
        "imports": ["./utils", "../config", "express"],
        "exports": ["login", "logout", "refreshToken"],
        "dependencies": ["src/auth/token.ts", "src/config/oauth.ts"],
        "dependents": ["src/api/auth-routes.ts", "src/middleware/auth.ts"]
      }
    }
  },
  "directories": {
    "src/": {"file_count": 42, "total_size": 128000},
    "test/": {"file_count": 15, "total_size": 32000}
  },
  "dependency_graph": {
    "nodes": ["src/auth/login.ts", "src/auth/token.ts", "..."],
    "edges": [
      {"from": "src/auth/login.ts", "to": "src/auth/token.ts", "type": "import"}
    ],
    "circular": [],
    "orphans": ["src/legacy/xml-parser.ts"]
  }
}
```

### last-check.json Format

```json
{
  "version": 1,
  "timestamp": "2024-01-15T10:30:00Z",
  "outcome": "PASS",
  "scope": {
    "structural": true,
    "content": true,
    "coherency": true,
    "process": false,
    "quality": true,
    "subprojects": true
  },
  "invariants": {
    "checked": 18,
    "initial_pass": 14,
    "repaired": 2,
    "user_fixed": 1,
    "disputes_resolved": 1,
    "exceptions": 0
  },
  "subprojects": {
    "checked": 2,
    "passed": 2
  },
  "files_scanned": 142,
  "duration_ms": 45000
}
```

## File Classification System

Every file in the repository must be classified **based on semantic analysis of its contents**, not path patterns. Classification is stored in `.project-metadata/classification.json`:

```json
{
  "version": 1,
  "generated": "2024-01-15T10:30:00Z",
  "objective_criteria": ["SC-1", "SC-2", "SC-3"],
  "classifications": {
    "src/auth/login.ts": {
      "category": "core",
      "objective": "SC-1",
      "evidence": "Implements OAuth login flow with token refresh, directly fulfilling SC-1 (user authentication)",
      "key_functions": ["login()", "refreshToken()", "validateSession()"],
      "confidence": "high",
      "classified_by": "semantic-agent"
    },
    "src/utils/format.ts": {
      "category": "infrastructure",
      "supports": "SC-1",
      "purpose": "Token formatting utilities supporting auth flow",
      "used_by": ["src/auth/login.ts", "src/middleware/auth.ts"],
      "confidence": "high",
      "classified_by": "semantic-agent",
      "dispute_history": [
        {
          "date": "2024-01-15T10:30:00Z",
          "original_analysis": "Only string formatting, no auth logic",
          "original_category": "orphan",
          "user_counter_evidence": "formatToken() and parseAuthHeader() are essential for auth system",
          "revised_analysis": "Token formatting utilities supporting auth flow",
          "revised_category": "infrastructure",
          "outcome": "resolved"
        }
      ]
    },
    "src/legacy/old-parser.ts": {
      "category": "orphan",
      "analysis": "Contains XML parsing logic not referenced by any current objective or other files",
      "recommendation": "Remove or link to objective",
      "confidence": "high",
      "classified_by": "semantic-agent"
    },
    "scripts/legacy-migrate.sh": {
      "category": "exception",
      "reason": "One-time migration script, keeping for reference",
      "acknowledged": "2024-01-10",
      "confidence": "explicit",
      "classified_by": "user"
    }
  },
  "unclassified": []
}
```

**Classification requires semantic understanding:**

| Category | Definition | Required Evidence |
|----------|------------|-------------------|
| `core` | Implements success criteria | Which SC-N, how it implements it, key functions/classes |
| `infrastructure` | Supports core functionality | What it provides, which core files use it |
| `test` | Verifies implementation | Which core files/criteria it tests |
| `documentation` | Explains project | What it documents, currency assessment |
| `generated` | Build output | Build process that generates it |
| `orphan` | Significant code not connected to objectives | Analysis of what it does, why it's disconnected |
| `exception` | Explicit exception | User-provided reason |

**Classification process (semantic, not pattern-based):**

1. **Read file contents** — Full file, not just path
2. **Understand purpose** — What does this code do?
3. **Map to objectives** — Which success criterion does this implement/support?
4. **Trace dependencies** — What uses this? What does this use?
5. **Assess alignment** — Does the implementation actually fulfill the claimed objective?
6. **Record evidence** — Concrete evidence for the classification

**Path patterns are hints, not classifications.** A file in `src/` is *likely* core, but classification is confirmed by reading and understanding the code.

## Coherency Heuristics

When assessing coherency, check for these patterns:

### Naming Consistency
- Variables/functions follow same convention (camelCase, snake_case, etc.)
- Similar concepts use similar names across files
- No misleading names (function does what name suggests)

### Pattern Consistency
- Similar problems solved similarly across codebase
- Error handling approach is uniform
- Logging/debugging approach is uniform
- State management follows consistent pattern

### Architecture Coherence
- Clear separation of concerns
- Dependencies flow in consistent direction
- No circular module dependencies
- Abstraction levels are consistent

### Style Consistency
- Formatting is uniform (or enforced by tooling)
- Comments follow similar style
- File organization follows similar structure

## Implementation Notes

### Detect-Repair-Verify Loop

For each hard invariant:

```
detect(invariant) → violation?
  ├── no  → record ✓, continue
  └── yes → auto-repairable?
              ├── yes → repair() → verify(invariant)
              │           ├── holds → record "Repaired", continue
              │           └── fails → rollback(), escalate()
              └── no  → escalate(), record "Needs User"
```

**Verification is mandatory.** Never assume a repair worked — always re-check the specific invariant.

**Rollback on failure:** If a repair doesn't verify, undo it before escalating. Don't leave partial repairs.

### Sub-Agent Swarm Implementation

The skill uses recursive sub-agent swarms at multiple levels:

**Level 1: Directory Reading Swarm**
```
orchestrator
├── spawn explore-agent(src/)      ─┐
├── spawn explore-agent(lib/)       │ parallel
├── spawn explore-agent(test/)      │
└── spawn explore-agent(docs/)     ─┘
    each returns: [{path, size, hash, summary, imports, exports}, ...]
```

**Level 2: Analysis Swarm**
```
orchestrator (with aggregated inventory)
├── spawn classification-agent(files, objectives)  ─┐
├── spawn coherency-agent(files)                    │ parallel
├── spawn import-agent(files)                       │
└── spawn deadcode-agent(files)                    ─┘
    each returns: {findings: [...], violations: [...]}
```

**Level 3: Subproject Swarm**
```
orchestrator
├── spawn project-check(subprojects/auth)  ─┐
├── spawn project-check(subprojects/api)    │ parallel
└── spawn project-check(lib/shared)        ─┘
    each returns: {outcome, violations, warnings}
    each internally spawns its own Level 1 + Level 2 swarms
```

**Recursion within directories:**
For deep directory trees, directory agents spawn sub-agents:
```
explore-agent(src/)
├── read files in src/*.ts directly
├── spawn explore-agent(src/components/)  ─┐
├── spawn explore-agent(src/services/)     │ parallel
└── spawn explore-agent(src/utils/)       ─┘
    aggregate all results before returning
```

**Fan-out limits:**
- Maximum 10 parallel agents per orchestrator level
- If >10 directories, batch into groups
- Prevents resource exhaustion while maintaining parallelism

### Context Management

Content audit can be context-intensive. Strategies:
1. **Parallel swarm** — Distribute file reading across sub-agents
2. **Inventory cache** — Use `.project-metadata/inventory.json` to detect changed files
3. **Hash-based skip** — Only re-read files with changed hash since last check
4. **Chunked aggregation** — Sub-agents return summaries, orchestrator synthesizes
5. **Coherency cache** — Use `.project-metadata/coherency-cache.json` for unchanged modules

### Subproject Recursion

Recursion depth controlled by:
- Constitutional depth limit (max 3 levels)
- `--shallow` flag (skip recursion entirely)

When recursing:
1. Pass parent objective trace to child
2. Child check runs with full protocol (including its own detect-repair-verify)
3. Child outcome determines contribution to parent:
   - Child `PASS` → no impact on parent
   - Child `PASS_WITH_WARNINGS` → warnings roll up to parent
   - Child `FAIL_*` → parent cannot pass (hard dependency)
4. Child repairs are committed within child's scope
5. Parent aggregates all child violation registries

### Exception Persistence

Exceptions are stored in `.project-metadata/exceptions.json`:

```json
{
  "version": 1,
  "exceptions": [
    {
      "id": "EX001",
      "invariant": "Dead Code",
      "location": "utils/legacy.ts",
      "reason": "Keeping for reference during migration",
      "acknowledged_by": "user",
      "acknowledged_at": "2024-01-15T10:30:00Z",
      "expires": "2024-04-15",
      "review_count": 2
    }
  ]
}
```

**Exception lifecycle:**
1. User acknowledges violation as exception
2. Exception recorded with reason and optional expiry
3. On subsequent checks, exception is noted (not re-escalated)
4. If expiry passed, exception is re-escalated for review
5. `review_count` tracks how many checks have seen this exception

### Invariant Addition

To add a new invariant:
1. Classify as hard (blocking) or soft (warning)
2. Define detection logic
3. If hard: determine if auto-repairable
4. If auto-repairable: implement repair function + verification
5. Add to appropriate checklist and output sections
6. Document in this skill file
