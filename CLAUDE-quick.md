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

## Context State (Automatic)

**File:** `.claude/sessions/<session_id>/context-state.json` — managed by hooks, read by statusline.

**Automatic triggers:**
| Event | Hook | Action |
|-------|------|--------|
| Read OBJECTIVE.md | PostToolUse | Captures project context |
| Before compression | PreCompact | Saves state |
| After compression | SessionStart | Restores full context digest |

**Session isolation:** Each Claude Code window has unique session ID — parallel work without conflicts.

**Can't state project/objective/trace? Read OBJECTIVE.md to re-trigger capture.**

## Verification Tiers

| Tier | Scope | Required |
|------|-------|----------|
| Trivial | <10 lines, 1 file | git diff + inspection |
| Standard | Multi-file | Automated checks + LOG.md record |
| Critical | Architecture, security | Full record + user review |

**Pre-commit hook warns if Standard+ without verification record.**

## Checkpoint Model

| Level | When | What |
|-------|------|------|
| Lightweight | Incremental progress | Git commit only |
| Full | Session end, decisions | Git commit + LOG.md entry |
| Autonomous | Decision/discovery/reversal | Git tag + AUTONOMOUS-LOG.md |

## Learning Capture

**Hierarchy:** Workspace → Project → Subproject (each has own LEARNINGS.md)

| Level | Scope |
|-------|-------|
| Workspace | Cross-project (tools, languages, process) |
| Project | Project domain/stack specific |
| Subproject | Component-specific (optional) |

**At session end, ACTIVELY scan for:**
- Failures → Failure pattern
- Non-obvious solutions → Technical pattern
- Workflow improvements → Process pattern

**Capture criteria (≥2):** Reusable, non-documented, cost-saving, failure-derived.

**Plan agents MUST read all applicable LEARNINGS.md levels before recommending approaches.**

## Agent Spawning

Always pass context payload:
```
Project: [path]
Objective: [1-2 sentences]
Trace: [root → current]
Scope: [boundaries]
Success criteria: [how to verify]
```

## Autonomous Checkpoints

Checkpoint when:
- **Decision** — Chose approach A over B
- **Discovery** — Found unexpected behavior
- **Reversal** — Approach failed, changing direction
- **Milestone** — Significant progress

## Override Protocol

User can say:
- "Skip verification" → Trivial tier
- "No logging" → Skip LOG.md
- "Quick mode" → Ad-hoc behavior
- "Minimal ceremony" → All above

## Anti-Patterns

NEVER:
- Add features beyond request
- Create abstractions for single use
- Handle impossible errors
- Improve adjacent code unprompted

## Failure Protocol

After 2 failed attempts: **STOP** → stash/reset → diagnose → capture learning → change approach or escalate
