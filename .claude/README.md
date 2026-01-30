# Claude Configuration

This directory contains Claude Code configuration aligned with the constitutional document (`CLAUDE.md`).

## Constitutional Hierarchy

```
CLAUDE.md                    # Constitution (root authority)
├── .claude/
│   ├── agents/              # Derived agents (all reference constitution)
│   │   ├── explore.md
│   │   ├── plan.md
│   │   ├── implement.md
│   │   ├── verify.md
│   │   └── research.md
│   ├── skills/              # Derived skills (all reference constitution)
│   │   ├── project-check/
│   │   ├── project-management/
│   │   ├── session-end/
│   │   ├── hypercontext/
│   │   └── reasoning/
│   ├── hooks/               # Constitutional enforcement hooks
│   │   ├── session-start.sh # Loads LEARNINGS.md context
│   │   └── pre-commit.sh    # Commit message format reminder
│   └── settings.local.json  # Permissions + hooks configuration
└── LEARNINGS.md             # Global learnings repository
```

## Hooks

Constitutional enforcement via Claude Code hooks:

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | Outputs session context (project, learnings, git state) + protocol reminder |
| `pre-commit.sh` | PreToolUse (Bash) | Reminds about commit message format requirements |

### Session Start Behavior

The `session-start.sh` hook runs automatically and outputs:
- LEARNINGS.md count (workspace-level)
- Git branch and dirty state
- Available project count
- Prompt to use `/project-start <name>`

**Project selection is explicit.** The hook does NOT auto-select a project. Use:
```
/project-start <name>     # Orient on specific project
/project-start --list     # List available projects
```

Hooks are non-blocking reminders, not hard blockers. They support the constitutional requirements without impeding workflow.

## settings.local.json

Permissions are organized by constitutional purpose:

| Section | Constitutional Alignment |
|---------|-------------------------|
| **Web** | Research agent operations |
| **Git** | Traceability System — checkpoints, rollback, verification |
| **Cargo** | Verification System — Rust build/test commands |
| **Forge** | Verification System — Solidity build/test commands |
| **Rustup** | Toolchain management for verification |
| **Utilities** | Exploration and file inspection |
| **Project-specific** | Local scripts and tools |

## Agents

All agents include constitutional headers:
```yaml
constitution: CLAUDE.md
alignment:
  - [section this agent implements]
```

Key constraints enforced:
- **Git Authority:** Only orchestrator commits (subagents have none)
- **LOG.md Authority:** Only orchestrator appends (subagents report findings)
- **Learning Capture:** Subagents report candidates; orchestrator propagates

## Skills

All skills include constitutional headers with alignment declarations.

## Adding New Agents/Skills

New agents and skills must:
1. Include constitutional header referencing `CLAUDE.md`
2. Declare which sections they implement in `alignment`
3. Include "Constitutional Authority" section explaining constraints
4. Follow verification, traceability, and learnings protocols as applicable
