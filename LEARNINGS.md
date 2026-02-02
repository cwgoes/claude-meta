# Learnings Repository

Cross-project learnings. Plan agents MUST read before recommending approaches.

---

## Failure Pattern Classes

Reference taxonomy for categorizing reasoning errors. See CLAUDE.md for full descriptions.

| Class | Description |
|-------|-------------|
| Ecosystem Overconfidence | Assumed stability based on apparent maturity |
| Insufficient Research | Acted on partial information |
| Scope Creep | Task expanded beyond original boundaries |
| Coupling Blindness | Missed dependencies between components |
| Complexity Escalation | Added abstraction before proving necessity |
| Verification Gap | Insufficient testing of assumptions |
| Specification Ambiguity | Proceeded despite unclear requirements |

---

## Technical Patterns

*Learnings about code patterns, library behaviors, performance insights.*

### [LP-001] Stwo Circle STARK Domain Alignment Requirements
- **Source:** allir, 2026-02-02 Stwo integration
- **Context:** Integrating Stwo STARK prover for cryptographic proof generation
- **Insight:** In Stwo, `CanonicCoset(n)` and `CanonicCoset(n+1)` are ENTIRELY DIFFERENT cosets on the circle, NOT subsets of each other. The trace polynomial must be interpolated on the SAME CanonicCoset where constraints are evaluated. If they differ, the polynomial evaluated at constraint points gives arbitrary values (not trace values), causing ConstraintsNotSatisfied errors.
- **Applicability:** Any Stwo Circle STARK integration. Always ensure `trace_log_size == component_log_size`.

### [LP-002] Stwo Lifted VCS LDE Size Matching
- **Source:** allir, 2026-02-02 Stwo integration
- **Context:** Stwo proof generation with lifted VCS (Vector Commitment Scheme)
- **Insight:** Stwo's lifted VCS requires ALL committed trees to have the same domain size after LDE. FRI queries are sampled from the largest domain and applied to all trees. If trace_lde < composition_lde, you get "index out of bounds" errors during decommit. The formula: `composition_lde = component_log_size + STANDARD_CONSTRAINT_DEGREE - COMPOSITION_LOG_SPLIT + log_blowup`. To match: either increase log_blowup or decrease STANDARD_CONSTRAINT_DEGREE.
- **Applicability:** Any Stwo integration with multiple polynomial commitments.

---

## Process Patterns

*Learnings about workflow improvements, communication patterns.*

<!-- Example:
### [PP-001] Title
- **Source:** [project, session]
- **Context:** [When this applies]
- **Insight:** [The learning]
- **Applicability:** [Where to use it]
-->

---

## Failure Patterns

*What didn't work and why. Prevents repeated mistakes.*

### [FP-002] Stwo Domain Mismatch Debugging Cascade
- **Source:** allir, 2026-02-02 Stwo integration
- **Context:** Implementing cryptographic STARK proofs with Stwo Circle STARK library
- **Insight:** Spent hours debugging ConstraintsNotSatisfied and index-out-of-bounds errors by trying to adjust trace sizes, bit-reversal transformations, and domain padding. The root cause was a fundamental architecture mismatch: trace interpolation domain must equal constraint evaluation domain, AND LDE sizes must match across all committed trees.
- **Avoidance:** When integrating Stwo (or similar STARK provers), FIRST verify: (1) all cosets are identical for trace and constraints, (2) all LDE sizes match. These are hard constraints, not tunable parameters.
- **Reasoning Error:** Treated domain sizes as independent tunable parameters that could be adjusted individually. Attempted fixes like bit-reversal, trace padding, and size offsets without understanding the fundamental coset equality requirement.
- **Counterfactual:** Should have started by reading Stwo's constraint evaluation code to understand exactly where trace values are accessed and what domain they expect. Understanding `CanonicCoset(n) ≠ subset of CanonicCoset(n+1)` would have immediately clarified the constraint.
- **Generalized Lesson:** When cryptographic proof systems fail with opaque errors, the issue is often a fundamental architectural mismatch, not a tunable parameter. Before iterating on parameters, trace through the exact data flow to understand invariants. Circle STARKs have strict coset equality requirements that differ from FFT-based systems.
- **Pattern Class:** Insufficient Research
- **See Also:** LP-001, LP-002

### [FP-001] wasm-bindgen-rayon TLS Initialization Failure
- **Source:** allir, 2026-01-30 bootstrap
- **Context:** WASM threading with nightly + build-std, attempting to use wasm-bindgen-rayon for parallel proving
- **Insight:** `__wasm_init_tls` not found error when using wasm-bindgen-rayon with atomics target feature. This is a known ecosystem instability with WASM threading—the TLS initialization symbol isn't generated correctly with certain toolchain combinations.
- **Avoidance:** Use SIMD-only optimizations or WebWorker-based parallelism instead of wasm-bindgen-rayon. The threading approach requires careful toolchain pinning and may still be unreliable.
- **Reasoning Error:** Documentation appeared complete and the library is widely referenced. Assumed that "widely used + documented" implied production stability, especially given the sophisticated examples in the repo.
- **Counterfactual:** Before committing to the approach, should have searched for GitHub issues mentioning TLS or atomics failures, and tested minimal reproduction before integrating into larger system.
- **Generalized Lesson:** Cutting-edge features at technology intersections (WASM + threading + Rust nightly + build-std) have compounding instability. When stacking 3+ experimental features, assume undocumented failure modes exist. Probe issue trackers and test minimal reproductions before architectural commitment.
- **Pattern Class:** Ecosystem Overconfidence
- **See Also:** —

---

## Propagation Log

| ID | Title | Source | Date Added |
|----|-------|--------|------------|
| LP-001 | Stwo Circle STARK Domain Alignment Requirements | allir | 2026-02-02 |
| LP-002 | Stwo Lifted VCS LDE Size Matching | allir | 2026-02-02 |
| FP-002 | Stwo Domain Mismatch Debugging Cascade | allir | 2026-02-02 |
| FP-001 | wasm-bindgen-rayon TLS Initialization Failure | allir | 2026-01-30 |
