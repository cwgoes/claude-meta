# Learnings Repository

Cross-project learnings. Plan agents MUST read before recommending approaches.

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

---

## Propagation Log

| ID | Title | Source | Date Added |
|----|-------|--------|------------|
| FP-001 | wasm-bindgen-rayon TLS Initialization Failure | allir | 2026-01-30 |
