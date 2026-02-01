# Claude Configuration

This directory contains Claude Code configuration aligned with the constitutional document (`CLAUDE.md`).

## Work Modes

Per CLAUDE.md, work scales based on **uncertainty** and **duration**, not complexity:

| Mode | When | Structure | Git |
|------|------|-----------|-----|
| **Ad-hoc** | Clear task, single session | None | Working context (not workspace) |
| **Project** | Multi-session, decisions worth recording | OBJECTIVE.md + LOG.md | Own repository |
| **Autonomous** | Unattended execution (explicit invocation only) | Project + AUTONOMOUS-LOG.md | Dedicated branch |

**Mode selection:**
- Start Ad-hoc for bounded tasks
- Upgrade to Project when scope expands, decisions need recording, or session ends incomplete
- Autonomous only on explicit `/autonomous` invocation — never auto-selected

**Graduation is automatic with notification.** Once a project exists, maintain it.

## Repository Model

Per CLAUDE.md, **one project = one repository, workspace = metadata only**:

```
workspace/                    # May be git repo for metadata
├── CLAUDE.md                 # Constitution (root authority)
├── LEARNINGS.md              # Cross-project learnings (workspace-level)
├── .claude/                  # Configuration (this directory)
└── projects/
    ├── alpha/                # git repo (project)
    │   ├── OBJECTIVE.md
    │   ├── LOG.md
    │   └── LEARNINGS.md      # Alpha-specific learnings
    └── beta/                 # git repo (project)
        ├── OBJECTIVE.md
        ├── LOG.md
        └── LEARNINGS.md      # Beta-specific learnings
```

- **Workspace** holds constitution, cross-project learnings, and Claude configuration — may be a git repo for version control but never contains tracked work
- **Project repos** hold all tracked work with OBJECTIVE.md + LOG.md + LEARNINGS.md
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
│   │   ├── research.md
│   │   └── autonomous.md    # Unattended execution agent
│   ├── skills/              # Derived skills (all reference constitution)
│   │   ├── project-start/   # Orient on project to begin working
│   │   ├── project-create/  # Create new project
│   │   ├── project-check/   # Comprehensive project audit
│   │   ├── session-end/     # End session with memory capture
│   │   ├── commit/          # Create commit with verification awareness
│   │   ├── hypercontext/    # Context visualization
│   │   ├── autonomous/      # Launch autonomous execution
│   │   └── autonomous-review/ # Review and act on autonomous results
│   ├── hooks/               # Constitutional enforcement hooks
│   │   ├── session-start.sh # Outputs workspace context
│   │   └── pre-commit.sh    # Commit message format reminder
│   ├── docker/              # Container definitions for isolation
│   │   ├── autonomous.Dockerfile
│   │   └── run-autonomous.sh
│   └── settings.local.json  # Permissions + hooks configuration
└── LEARNINGS.md             # Workspace-level learnings repository
```

## Statusline

The statusline displays current project with full objective trace + session metrics via `statusline.sh`:

```
[alpha] workspace goal → distributed systems → cache layer | Ctx: 45% | 125K/32K | $12.34
```

| Field | Meaning |
|-------|---------|
| `[alpha]` | Current project name |
| `workspace → ... → current` | Full objective hierarchy trace (root → parent → current) |
| `(30m)` | Staleness warning if >30min since state update |
| `Ctx: N%` | Context window usage (! if >70%) |
| `125K/32K` | Input/output tokens (session total) |
| `$12.34` | Session cost |

**Trace truncation:** If the trace exceeds 60 characters, it truncates from the left with `...` to keep the current objective visible.

**Session-keyed context state:** Context state is stored at `.claude/sessions/<session_id>/context-state.json`. Each Claude Code window has a unique session ID, ensuring parallel windows don't conflict.

**Multiple windows:** Different Claude Code windows can work on different projects simultaneously. Each window's statusline reflects its own session's active project.

## Hooks

Constitutional enforcement via Claude Code hooks:

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | Outputs workspace context (learnings, projects) |
| `post-compact-reload.sh` | SessionStart (compact) | Restores context after compression |
| `pre-compact-save.sh` | PreCompact | Saves context before compression |
| `capture-project-context.sh` | PostToolUse (Read) | Captures project state when OBJECTIVE.md is read |
| `pre-commit.sh` | PreToolUse (Bash) | Reminds about commit message format requirements |

### Session Start Behavior

The `session-start.sh` hook runs automatically and outputs:
- LEARNINGS.md count (workspace-level)
- Workspace git status (if transitionally a repo)
- Available project count
- Prompt to use `/project-start <name>`

**Per Repository Model:** The workspace may be a git repo for its own metadata; each project is a separate git repo. Git status for a specific project is shown via `/project-start`.

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

### Key CLAUDE.md Sections for Agents

| Section | Purpose |
|---------|---------|
| Expertise Registry | What each agent is strong/weak at, when to escalate |
| Domain Specialization | How to add domain overlays to base agents |
| Delegation Contract | Required structured format for task delegation |
| Common Ground Protocol | Acknowledgment before beginning work |
| Verification Depth | Explicit checklists, not vague "verify" |
| Coordination Failure | Detecting and handling multi-agent breakdowns |

## Skills

All skills include constitutional headers with alignment declarations.

| Skill | Purpose | Invocation |
|-------|---------|------------|
| **project-start** | Orient on project to begin working | `/project-start <name>` |
| **project-create** | Create new project with OBJECTIVE.md + LOG.md | `/project-create <name>` |
| **project-check** | Comprehensive audit to detect/fix inconsistencies | `/project-check [name]` |
| **session-end** | End session with appropriate memory capture | `/session-end [quick\|full]` |
| **commit** | Create commit with verification tier awareness | `/commit [message]` |
| **hypercontext** | Visualize session context as ASCII map | `/hypercontext` |
| **autonomous** | Launch unattended execution with time budget | `/autonomous <project> [--budget <time>]` |
| **autonomous-review** | Review results and act (approve/rollback/direct) | `/autonomous-review <project>` |

## Autonomous Mode

Autonomous mode enables unattended execution with full traceability for async review. See CLAUDE.md "Autonomous Execution" section for full specification.

### Quick Start

```bash
# Launch autonomous execution (2h default budget)
/autonomous my-project

# Launch with custom budget
/autonomous my-project --budget 4h

# Review results
/autonomous-review my-project
```

### Requirements

- Project must have OBJECTIVE.md with verifiable success criteria
- Docker must be available (autonomous mode runs in isolated container)

### How It Works

1. **Launch:** `/autonomous` creates branch `auto/<project>-<timestamp>`
2. **Execute:** Claude works toward OBJECTIVE.md success criteria
3. **Checkpoint:** Tags created at decisions, discoveries, reversals
4. **Terminate:** On success, budget exhaustion, or uncertainty
5. **Review:** `/autonomous-review` to approve, rollback, or direct

### Artifacts

| File | Purpose |
|------|---------|
| `AUTONOMOUS-LOG.md` | Structured decision log for async review |
| `session-<timestamp>.jsonl` | Full execution trace |
| `DIRECTION.md` | User guidance for resumed runs |
| `checkpoint-NNN` tags | Rollback points |

### Docker Setup

Build the autonomous container:
```bash
docker build -t claude-autonomous -f .claude/docker/autonomous.Dockerfile .
```

Or use the wrapper script:
```bash
.claude/docker/run-autonomous.sh my-project --budget 2h
```

## Adding New Agents/Skills

New agents and skills must:
1. Include constitutional header referencing `CLAUDE.md`
2. Declare which sections they implement in `alignment`
3. Include "Constitutional Authority" section explaining constraints
4. Follow verification, traceability, and learnings protocols as applicable
