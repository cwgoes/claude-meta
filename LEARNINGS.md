# Learnings

Cross-project learnings. Plan agents MUST read before recommending approaches.

---

## Avoid

*Things that failed or caused problems.*

Avoid: Allowing adapter stub implementations (empty returns, nominal amounts) without explicit revert or TODO marker — QA found these as functional correctness bugs (claimRewards no-op, fake withdrawal amounts). Stubs should revert with clear error messages. — anoma-vaults adapter implementation

<!-- Avoid: [thing] — [why it failed] — [context] -->

---

## Prefer

*Things that worked well or solved problems.*

Prefer: 5-agent team structure (architect + designer + backend + frontend + QA) for full-stack DeFi projects — architect/designer give instructions without writing code, engineers implement, QA catches bugs concurrently. Clear separation prevented context overload and caught 3 critical bugs early. — anoma-vaults MVP sprint

Prefer: QA engineer testing code as it's written (not after completion) — caught fee loss bug, IFeeAccountable cache miss, and overflow that would have been much harder to find in a completed codebase. — anoma-vaults testing strategy

Prefer: Creating explicit tasks in the task list when agents don't respond to message-only instructions — formal task assignment with IDs gets picked up more reliably than inline requests. — anoma-vaults team coordination

<!-- Prefer: [thing] — [why it works] — [context] -->
