# Learnings

Cross-project learnings. Plan agents MUST read before recommending approaches.

---

## Avoid

*Things that failed or caused problems.*

Avoid: Allowing adapter stub implementations (empty returns, nominal amounts) without explicit revert or TODO marker — QA found these as functional correctness bugs (claimRewards no-op, fake withdrawal amounts). Stubs should revert with clear error messages. — anoma-vaults adapter implementation

Avoid: `.unwrap()` on data from untrusted sources (lightwalletd compact blocks) in WASM — Panics crash the entire WASM module and browser tab. Use `into_option().ok_or_else()` or skip with `continue` for malformed data. — zec-ai wallet tree.rs and scanner.rs

<!-- Avoid: [thing] — [why it failed] — [context] -->

---

## Prefer

*Things that worked well or solved problems.*

Prefer: 5-agent team structure (architect + designer + backend + frontend + QA) for full-stack DeFi projects — architect/designer give instructions without writing code, engineers implement, QA catches bugs concurrently. Clear separation prevented context overload and caught 3 critical bugs early. — anoma-vaults MVP sprint

Prefer: QA engineer testing code as it's written (not after completion) — caught fee loss bug, IFeeAccountable cache miss, and overflow that would have been much harder to find in a completed codebase. — anoma-vaults testing strategy

Prefer: Creating explicit tasks in the task list when agents don't respond to message-only instructions — formal task assignment with IDs gets picked up more reliably than inline requests. — anoma-vaults team coordination

Prefer: Mock-to-real swap pattern for parallel frontend/backend implementation — Frontend builds full integration layer with mock, backend builds real implementation independently. Integration becomes a clean swap rather than big-bang merge. — zec-ai MVP team

Prefer: Self-contained Web Worker proving via JSON snapshot — Main thread serializes everything the worker needs into one JSON blob. Worker re-derives keys independently. Avoids SharedArrayBuffer complexity and shared state across threads. — zec-ai Halo2 proving

Prefer: Architect agent reviewing interface contracts before integration — Caught 5 mismatches (function names, parameter counts, address format, sync architecture, proving semantics) before engineers hit them at runtime. Saves significant debugging time. — zec-ai team coordination

Prefer: `zcash_address` crate for unified address encoding in WASM — Confirmed WASM-safe (no secp256k1, no zcash_primitives, pure Rust deps). Use v0.10+ for proper `u1...` format. — zec-ai api.rs address encoding

<!-- Prefer: [thing] — [why it works] — [context] -->
