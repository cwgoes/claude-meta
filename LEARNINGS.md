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

<!-- Example:
### [LP-001] Title
- **Source:** [project, session]
- **Context:** [When this applies]
- **Insight:** [The learning]
- **Applicability:** [Where to use it]
-->

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
| FP-001 | wasm-bindgen-rayon TLS Initialization Failure | allir | 2026-01-30 |
