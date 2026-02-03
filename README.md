# Claude Experiments Workspace

A structured workspace for Claude-assisted software projects with full traceability and multi-session memory.

## Quick Start

```bash
claude                        # Start Claude Code
/project-start --list         # See available projects
/project-start <name>         # Begin working on a project
/project-create <name>        # Create a new project
```

## What This Is

This workspace implements a **constitutional framework** for Claude agents defined in `CLAUDE.md`. The goal is reasonably efficient progress on complex projects which must be traceable and verifiable, with minimal content relative to stated objectives.

### Core Principles (priority order)
1. **Verifiable** — Criteria met with concrete evidence
2. **Traceable** — Audit trail, rollback capability
3. **Minimal** — Content fits in context at each hierarchy level
4. **Learnings** — Never repeat mistakes; generalize insights
5. **Efficient** — Reasonable progress; compute is cheap

## Work Modes

| Mode | When | What You Get |
|------|------|--------------|
| **Ad-hoc** | Quick tasks, single session | Just git commits |
| **Project** | Multi-session work | OBJECTIVE.md + LOG.md + learnings |

Start simple. Complexity is added only when needed.

For unattended execution, use the external runner script (`scripts/run-until-complete.sh`) which calls Claude Code repeatedly until objectives are met.

## Directory Structure

```
├── CLAUDE.md           # Constitution (all rules derive from here)
├── LEARNINGS.md        # Cross-project learnings
├── .claude/
│   ├── agents/         # Specialized subagents (explore, plan, implement, verify, research)
│   ├── skills/         # Slash commands (/commit, /project-start, etc.)
│   ├── hooks/          # Automatic context management
│   └── settings.local.json  # Permissions + hook config
└── projects/
    └── <name>/         # Each project is its own git repo
        ├── OBJECTIVE.md
        ├── LOG.md
        └── LEARNINGS.md
```

## Available Commands

| Command | Purpose |
|---------|---------|
| `/project-start <name>` | Orient on a project |
| `/project-create <name>` | Create new project with structure |
| `/project-import` | Import existing codebase into project framework |
| `/project-check` | Audit current project for issues |
| `/commit` | Create verified commit |
| `/session-end` | End session with memory capture |
| `/experiment <name>` | Create/enter git worktree for parallel work |
| `/plan [description]` | Enter plan mode with context |
| `/hypercontext` | Visualize session state |

## Key Features

### Automatic Context Persistence
- Project state survives context compression
- Statusline shows current project + objective trace
- Multiple Claude windows can work in parallel

### Learnings System
- Failures are captured with reasoning analysis
- Technical patterns propagate across projects
- Plan agents read learnings before recommending approaches

### Verification Tiers
- **Trivial**: <10 lines, 1 file — git diff
- **Standard**: Multi-file — Evidence block in LOG.md
- **Critical**: >3 files, security, APIs — Evidence + user review

## Configuration

`settings.local.json` configures:
- **Permissions**: Pre-approved commands (git, cargo, forge, npm, etc.)
- **Hooks**: Automatic context capture on OBJECTIVE.md reads
- **Statusline**: Shows project + context usage + cost
- **Always-on thinking**: Extended reasoning enabled by default

## Current Projects

Run `/project-start --list` to see available projects, or check the `projects/` directory.

## Further Reading

- `CLAUDE.md` — Full constitutional document
- `.claude/README.md` — Detailed configuration docs
- `LEARNINGS.md` — Captured patterns and failure modes
