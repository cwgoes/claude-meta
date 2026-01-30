# Claude Configuration

This directory contains Claude Code configuration aligned with the constitutional document (`CLAUDE.md`).

## Work Modes

Per CLAUDE.md, work scales based on **uncertainty** and **duration**, not complexity:

| Mode | When | Structure | Git |
|------|------|-----------|-----|
| **Ad-hoc** | Clear task, single session | None | Working context (not workspace) |
| **Project** | Multi-session, decisions worth recording | OBJECTIVE.md + LOG.md | Own repository |

**Mode selection:**
- Start Ad-hoc for bounded tasks
- Upgrade to Project when scope expands, decisions need recording, or session ends incomplete

**Graduation is automatic with notification.** Once a project exists, maintain it.

## Repository Model

Per CLAUDE.md, **one project = one repository, workspace = metadata only**:

```
workspace/                    # Git repo for metadata ONLY
├── CLAUDE.md                 # Constitution (root authority)
├── LEARNINGS.md              # Workspace-level learnings
├── .claude/                  # Configuration (this directory)
└── projects/
    ├── alpha/                # git repo (project)
    └── beta/                 # git repo (project)
```

- **Workspace repo** holds constitution, learnings, and Claude configuration — never tracked work
- **Project repos** hold all tracked work with OBJECTIVE.md + LOG.md
- **Subprojects** are subdirectories or submodules within a project repo

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
│   │   ├── project-start/   # Orient on project to begin working
│   │   ├── project-create/  # Create new project
│   │   ├── project-check/   # Comprehensive project audit
│   │   ├── session-end/     # End session with memory capture
│   │   └── hypercontext/    # Context visualization
│   ├── hooks/               # Constitutional enforcement hooks
│   │   ├── session-start.sh # Outputs workspace context
│   │   └── pre-commit.sh    # Commit message format reminder
│   └── settings.local.json  # Permissions + hooks configuration
└── LEARNINGS.md             # Workspace-level learnings repository
```

## Hooks

Constitutional enforcement via Claude Code hooks:

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | Outputs workspace context (learnings, projects) |
| `pre-commit.sh` | PreToolUse (Bash) | Reminds about commit message format requirements |

### Session Start Behavior

The `session-start.sh` hook runs automatically and outputs:
- LEARNINGS.md count (workspace-level)
- Workspace git status (if transitionally a repo)
- Available project count
- Prompt to use `/project-start <name>`

**Per Repository Model:** The workspace is not a git repo; each project is. Git status for a specific project is shown via `/project-start`.

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
| **Git submodule** | Repository Model — submodule management for subprojects |
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

| Skill | Purpose | Invocation |
|-------|---------|------------|
| **project-start** | Orient on project to begin working | `/project-start <name>` |
| **project-create** | Create new project with OBJECTIVE.md + LOG.md | `/project-create <name>` |
| **project-check** | Comprehensive audit to detect/fix inconsistencies | `/project-check [name]` |
| **session-end** | End session with appropriate memory capture | `/session-end [quick\|full]` |
| **hypercontext** | Visualize session context as ASCII map | `/hypercontext` |

## Adding New Agents/Skills

New agents and skills must:
1. Include constitutional header referencing `CLAUDE.md`
2. Declare which sections they implement in `alignment`
3. Include "Constitutional Authority" section explaining constraints
4. Follow verification, traceability, and learnings protocols as applicable
