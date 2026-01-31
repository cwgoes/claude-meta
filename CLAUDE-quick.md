# CLAUDE-quick.md

Quick reference for agents. Full specification: [CLAUDE.md](CLAUDE.md)

## Principles (Priority Order)

1. **User time** — Optimize for user, compute is cheap
2. **Minimal** — Solve exactly the stated problem
3. **Verifiable** — Tests pass, criteria met
4. **Traceable** — Audit trail, rollback capability
5. **Learnings** — Capture reusable insights

## Work Modes

| Mode | When | Structure |
|------|------|-----------|
| **Ad-hoc** | Clear, single-session | Git commits only |
| **Project** | Multi-session, decisions worth recording | OBJECTIVE.md + LOG.md |
| **Autonomous** | Unattended execution (explicit invocation only) | Project + AUTONOMOUS-LOG.md + branch |

Default to ad-hoc. Graduate to project when scope expands. Autonomous only on explicit `/autonomous` invocation.

## Context Invariants

When project active, always know:
- Project path
- Current objective (1 sentence)
- Objective trace (root → current)
- Working level

**Can't state these? Refresh immediately.**

## Override Protocol

User can say:
- "Skip verification" → Trivial tier
- "No logging" → Skip LOG.md
- "Quick mode" → Ad-hoc behavior
- "Minimal ceremony" → All above

## Verification Tiers

| Tier | Scope | Required |
|------|-------|----------|
| Trivial | <10 lines | git diff + inspection |
| Standard | Multi-file | Automated checks |
| Critical | Architecture | Full record + user review |

## Agent Spawning

Always pass context payload:
```
Project: [path]
Objective: [1-2 sentences]
Trace: [root → current]
Scope: [boundaries]
Success criteria: [how to verify]
```

## Anti-Patterns

NEVER:
- Add features beyond request
- Create abstractions for single use
- Handle impossible errors
- Improve adjacent code unprompted

## Failure Protocol

After 2 failed attempts: **STOP** → stash/reset → diagnose → capture learning → change approach or escalate
