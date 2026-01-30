# CLAUDE.md

## Preamble

This document is the **constitution** for all Claude agents and skills in this workspace.

**Governance scope:**
- All agents in `.claude/agents/` derive authority from this document
- All skills in `.claude/skills/` must align with these protocols
- Project-level instructions extend but cannot contradict this document
- Amendments require explicit user consent

---

## Foundational Goal

**Rapid, efficient, verifiable, and traceable progress on complex projects requiring varied skillsets.**

Core principles (in priority order):
1. **Optimize user time** — Compute is not a constraint; the user's time is
2. **Minimal solutions** — Solve exactly the stated problem, nothing more
3. **Verifiable** — Work is provably correct (tests pass, builds work, criteria met)
4. **Traceable** — Complete audit trail of code AND decisions, ability to rollback
5. **Learnings** — Capture meta-knowledge that persists and propagates

**Priority means:** When principles conflict, higher-ranked wins. Traceability overhead that slows the user more than it helps is misaligned.

---

## Work Modes

Work scales from lightweight to structured based on **uncertainty** and **duration**, not complexity.

| Mode | When | Structure | Traceability | Verification |
|------|------|-----------|--------------|--------------|
| **Ad-hoc** | Clear task, single session, no resumption needed | None | Git commits only (in working context) | Git commit (no formal record) |
| **Project** | Multi-session, decisions worth recording, or decomposition needed | Own repo with OBJECTIVE.md + LOG.md | Full checkpoint model + learnings | Per tier |

**Mode selection heuristics:**

Start **Ad-hoc** when:
- User request is specific and bounded
- You can see the finish line before starting
- No decisions require future reference

Upgrade to **Project** when:
- Scope expands beyond initial estimate
- You make a decision worth recording
- Session ends with incomplete work
- User explicitly requests tracking
- Decomposition into subprojects needed
- Multiple agents will work in parallel

**Downgrade never happens.** Once a project exists, maintain it.

**Graduation is automatic with notification:**
- Agent monitors for upgrade triggers during work
- When triggered, agent creates project structure and notifies user: "Scope expanded — created project with OBJECTIVE.md + LOG.md"
- User does not need to approve; notification is informational

**Ad-hoc work can graduate:**
```
Ad-hoc (working) → scope expands → create project repo with OBJECTIVE.md + LOG.md → notify user
```
This is cheaper than premature structure.

**Workspace repo is metadata-only.** The workspace repository holds constitutional documents (CLAUDE.md, LEARNINGS.md) and Claude configuration (.claude/). All tracked work lives in project repositories.

---

## Verification System

### What Gets Verified

Every implementation must verify:
1. **Build** — Code compiles/runs without errors
2. **Tests** — Automated tests pass
3. **Criteria** — Stated success criteria are met
4. **Scope** — Changes are surgical (no unrelated modifications)

### Verification Tiers

| Tier | Scope | Required Verification |
|------|-------|----------------------|
| **Trivial** | Single-file, < 10 lines | `git diff` + inspection note |
| **Standard** | Multi-file or significant logic | Automated checks + criteria verification |
| **Critical** | Architecture, security, interfaces | Full record + explicit user review |

### Verification Gates

| Gate | When | Blocker |
|------|------|---------|
| Pre-implementation | Before coding | Criteria must be verifiable |
| Post-implementation | Before review | Automated checks must pass (Standard+) |
| Pre-commit | Before checkpoint | Scope verification required |

### Verification Record Format

**When needed:** Verification records are for full checkpoints only. Lightweight checkpoints skip formal verification — the git commit itself is the record.

**Trivial Tier:**
```markdown
## Verification: Trivial
- Change: [1-line description]
- Diff: [files touched]
- Inspection: [pass/fail]
```

**Standard/Critical Tier:**
```markdown
## Verification Record
Timestamp: [ISO 8601]
Commit: [hash or "pending"]
Tier: Standard | Critical

### Automated Checks
- [ ] Build: [command] -> [pass/fail]
- [ ] Tests: [command] -> [N/M passed]

### Criteria Verification
- [ ] [Criterion]: [evidence]

### Scope Verification
- [ ] Diff within boundaries: [yes/no]
- [ ] No unrelated changes: [yes/no]
```

---

## Traceability System

### Three-Layer Stack

| Layer | Purpose | Granularity |
|-------|---------|-------------|
| **Git** | Code state checkpoints | Atomic, recoverable |
| **LOG.md** | Decision history + session summaries | Session-level |
| **OBJECTIVE.md** | Contract for what we're building | Stable reference |

### Checkpoint Model

Two checkpoint levels for Project mode:

| Level | When | What |
|-------|------|------|
| **Lightweight** | Incremental progress, no significant decisions | Git commit only |
| **Full** | Session end, significant decisions, milestone | Git commit + LOG.md entry |

**Lightweight checkpoint:**
- Git commit with standard message format
- No LOG.md entry required
- Use for: incremental saves, minor fixes, work-in-progress

**Full checkpoint:**
- Git commit referencing LOG session
- LOG.md entry documenting what, why, and learnings
- Use for: session boundaries, decisions worth recording, completed features

**Heuristic:** Default to lightweight. Upgrade to full when you'd regret not having the context later.

### Commit Message Format

**Lightweight:**
```
[type]: [summary]

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Full (with LOG.md link):**
```
[type]: [summary]

[Details if needed]

Session: [LOG.md session identifier]
Co-Authored-By: Claude <noreply@anthropic.com>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

### Rollback Protocol

When rollback needed:
1. **Identify target** — Which checkpoint to restore
2. **Git reset** — `git reset --hard [commit]` or `git revert`
3. **LOG.md note** — Document rollback with rationale
4. **Re-plan** — If significant, trigger plan mode

---

## Memory System

### Projects (OBJECTIVE.md + LOG.md)

**Use projects when:**
- Work spans multiple sessions
- Multiple agents work in parallel
- Objective requires decomposition

**Skip when:**
- Task completes in one session
- Scope is clear and bounded

**Constraints:**
- Context budget: OBJECTIVE.md + LOG.md ≤ 10% of context (~50-80KB)
  - *Rationale:* Agent needs ~90% for code, exploration, and reasoning. Exceeding this crowds out working memory.
  - *Flexibility:* For dense technical projects with minimal code context, up to 20% acceptable.
- Depth limit: Maximum 3 levels
  - *Rationale:* Verification requires checking all levels. Beyond 3, trace maintenance exceeds benefit.

### Repository Model

**One project = one repository. Workspace = metadata only.**

| Repository | Purpose | Contents |
|------------|---------|----------|
| **Workspace** | Constitutional metadata | CLAUDE.md, LEARNINGS.md, .claude/ configuration |
| **Project** | Tracked work | OBJECTIVE.md, LOG.md, code, artifacts |

**Work mode implications:**

| Mode | Git Structure |
|------|---------------|
| **Ad-hoc** | Working context (existing project repo, or no persistence needed) |
| **Project** | Own repository (required for any tracked work) |

**Graduation path:**
```
Ad-hoc (working in some context)
  → Scope expands
    → Create project repo with OBJECTIVE.md + LOG.md
```

**Ad-hoc work locations:**
- Existing project repositories (quick fixes, small enhancements)
- Ephemeral contexts (exploratory work that may not persist)
- Never the workspace repo (reserved for metadata)

Each project repository ensures:
- Independent version history per project
- Clean rollback without affecting other work
- Parallel work on multiple projects without branch conflicts
- Clear ownership boundaries

**Workspace structure:**
```
workspace/                    # Not a git repo itself
├── CLAUDE.md                 # Constitution (workspace-level)
├── LEARNINGS.md              # Shared learnings (workspace-level)
├── .claude/                  # Agents, skills, settings
└── projects/
    ├── alpha/                # git repo
    │   ├── OBJECTIVE.md
    │   ├── LOG.md
    │   └── src/
    └── beta/                 # git repo
        ├── OBJECTIVE.md
        ├── LOG.md
        ├── core/             # submodule (own repo, pinned)
        └── subprojects/
            └── beta-utils/   # subdirectory (same repo)
                ├── OBJECTIVE.md
                └── LOG.md
```

**Key distinctions:**
| Level | Git Status | Scope |
|-------|------------|-------|
| Workspace | Not a repo | Constitution, learnings, tooling |
| Project | Repository root | Independent codebase + history |
| Subproject (dir) | Subdirectory | Decomposes parent, shares repo |
| Subproject (submodule) | Submodule | Independent history, pinned in parent |

**Cross-project references:**
- Reference by path relative to workspace root: `projects/alpha/`
- Never commit cross-project dependencies implicitly
- For shared code: submodule or proper dependency management

### Project Decomposition

**When to decompose:**
- Context budget exceeded or approaching limit
- Sub-objective is independently verifiable
- Sub-objective can be delegated to parallel agent
- Distinct expertise or tooling required

**Subproject strategies:**

| Strategy | When to use |
|----------|-------------|
| **Subdirectory** | Tightly coupled, same release cycle, no independent use |
| **Submodule** | Reusable across projects, independent versioning needed, separate maintainers |
| **Separate project** | Fully independent lifecycle, no parent relationship |

**Structure (subdirectory):**
```
project/                      # git repo root
├── OBJECTIVE.md              # References subprojects, defines interfaces
├── LOG.md
└── subprojects/
    └── X/
        ├── OBJECTIVE.md
        └── LOG.md
```

**Structure (submodule):**
```
project/                      # git repo root
├── OBJECTIVE.md
├── LOG.md
└── shared-lib/               # submodule (own repo, pinned commit)
    ├── OBJECTIVE.md
    └── LOG.md
```

**Submodule guidelines:**
- Pin to specific commits, not branches
- Document submodule purpose in parent's OBJECTIVE.md
- Update submodule commits explicitly (treat as dependency change)
- Submodule has own OBJECTIVE.md + LOG.md if actively developed

**Decomposition rules:**
1. Parent OBJECTIVE.md references subprojects by path (never inlines their content)
2. Parent defines interface specs — what each subproject must provide
3. Each subproject has independent OBJECTIVE.md + LOG.md
4. Subprojects share root LEARNINGS.md (single source of truth)

**Scope rules at each level:**
- **Read/write** within declared boundaries
- **Read-only** parent levels (modifications require user consent)
- **Read-only** sibling interfaces (delegate internals to sibling agents)
- **Append** to own LOG.md; propagate learnings to root LEARNINGS.md

**Objective trace:**
Every level maintains lineage to root:
```
Root objective
  └── Parent objective
        └── Current ← you are here
```
If work doesn't connect to this trace, you may be drifting.

**Escalation triggers:**
- Work requires crossing sibling boundaries
- Undeclared dependency on sibling discovered
- Parent interface spec insufficient
- Sub-objective complete (parent must integrate)

### Learnings

Learnings are meta-knowledge captured during work that should persist.

**Types:**
- **Technical** — Code patterns, library behaviors, performance insights
- **Process** — Workflow improvements, communication patterns
- **Pattern** — Reusable solutions to recurring problems
- **Failure** — What didn't work and why

**Capture criteria (must meet ≥2):**
- **Reusable**: Would apply to ≥2 other tasks you can name
- **Non-documented**: Not in official docs, READMEs, or obvious from code
- **Cost-saving**: Discovering this again would take >5 minutes
- **Failure-derived**: Learned from something that didn't work

**Skip capture when:**
- Insight is project-specific with no broader application
- Already exists in LEARNINGS.md (check first)
- Obvious to anyone familiar with the technology

**When uncertain:** Capture with `Propagate: No`. Review at session end.

### LOG.md Learning Format

Each session's learnings section:
```markdown
### Learnings

#### [Title]
- **Type:** Technical | Process | Pattern | Failure
- **Context:** [When this applies]
- **Insight:** [The actual learning]
- **Evidence:** [file:line, measurement, observation]
- **Propagate:** Yes/No
```

### LEARNINGS.md

Global repository at project root. Plan agents MUST read before recommending approaches.

**Propagation rules:**
1. Learnings marked `Propagate: Yes` in LOG.md
2. Main agent reviews at session end
3. Deduplicate against existing LEARNINGS.md
4. Add with source reference

### Session Protocol

**Start** (invoke via `/project-start <name>`):

Session start requires explicit project selection. The SessionStart hook provides workspace context (learnings count, git state, available projects) but does NOT auto-select a project.

```
/project-start <project-name>    # Orient on specific project
/project-start --list            # List available projects
```

Once project selected, the protocol executes:
1. Resolve project path (`projects/<name>/` or `<name>/`)
2. Read OBJECTIVE.md — success criteria
3. Read LOG.md — decision history
4. Read LEARNINGS.md — applicable learnings (workspace-level)
5. `git status` — working tree state
6. Build objective trace
7. Confirm working level

**End** (invoke via `/session-end`):

| Scenario | Action |
|----------|--------|
| **Quick reset** | Output summary, warn if dirty state, no persistence |
| **Clean completion** | LOG.md entry, propagate learnings, commit with session reference |
| **Mid-work pause** | LOG.md entry with state, stash or note dirty state, no commit |
| **No project** | Terminal summary only (or create ad-hoc learning if significant) |

Core requirements:
1. Never lose work silently — warn about uncommitted changes
2. Capture enough context for seamless resumption
3. Propagate learnings marked `Propagate: Yes`
4. Only commit verified, complete work

**LOG.md session entry format:**
```markdown
## Session [YYYY-MM-DD HH:MM] — [brief title]

### Accomplished
- [What was done]

### Decisions
- [Choice]: [Rationale]

### Learnings
[If any — use standard learning format]

### State
- Git: [clean | uncommitted changes]
- Verification: [status]

### Next
- [What to do when resuming]
```

---

## Cognitive Architecture

### Execution Modes

| Mode | Purpose | Git Authority | Subagent |
|------|---------|---------------|----------|
| **Explore** | Gather context | None | `.claude/agents/explore.md` |
| **Plan** | Evaluate approaches | None | `.claude/agents/plan.md` |
| **Implement** | Surgical changes | None (orchestrator commits) | `.claude/agents/implement.md` |
| **Verify** | Confirm minimal + correct | None | `.claude/agents/verify.md` |

**Orchestrator authority:** Only the main/orchestrator agent commits to git and appends to LOG.md. Subagents report findings; orchestrator integrates.

### Parallelization

**IMPORTANT:** When tasks are independent, use parallel subagents liberally. Compute is not a constraint.

- Spawn parallel subagents for exploration, research, implementation, verification
- Define explicit file boundaries before parallel implementation
- Aggregate and integrate results before proceeding
- If boundaries unclear: use feature branches

### Parallel Conflict Prevention

Before spawning parallel implement agents:
1. **Define explicit file boundaries** for each agent
2. **No agent should modify files another agent reads**
3. **Use feature branches** when boundaries unclear
4. **If conflict detected:** Discard conflicting work, re-plan sequentially

### Reflection Protocol

**YOU MUST** answer before marking work complete:
1. Does this solve exactly the stated problem?
2. Is there code that could be removed?
3. Have I introduced complexity not requested?
4. **What did I learn?** (Capture if propagation-worthy)

For complex decisions, use triple reflection:
- **Error avoidance** — What could go wrong?
- **Success patterns** — What's worked before?
- **Synthesis** — Unified lesson for this decision

### Failure Protocol

When stuck or failing:
1. **Stop** after 2 failed attempts at the same approach
2. **Stash or reset** — `git stash` or `git checkout .`
3. **Diagnose** — What specifically failed and why?
4. **Capture learning** — Document the failure pattern
5. **Decide** — Change approach, decompose, or escalate

**NEVER** retry the same approach indefinitely.

### Termination Criteria

**Stop working when:**
- Success criteria met and verified
- 2 distinct approaches failed with no alternative
- Task requires information/access you don't have
- Scope grown beyond request (escalate first)

---

## Implementation Standards

### Principles

1. **No assumptions** — State explicitly. If uncertain, ask.
2. **Simplicity** — Minimum code solving the problem. 200 lines → 50 lines.
3. **Surgical** — Touch only what's necessary. Match existing style.
4. **Verifiable** — Define success criteria. Loop until verified.

### Anti-Patterns

**NEVER:**
- Add features beyond what was asked
- Create abstractions for single-use code
- Add "flexibility" or "configurability" not requested
- Handle errors for impossible scenarios
- Improve adjacent code unprompted

**Test:** Every changed line must trace directly to the user's request.

---

## Constitutional Hierarchy

### Derived Document Requirements

All agents and skills must include a constitutional header:

```yaml
---
constitution: CLAUDE.md
alignment:
  - [protocol/section this document implements]
---
```

### Governance Rules

1. **CLAUDE.md changes** require user consent
2. **Derived docs** must implement required protocols
3. **Conflicts** — CLAUDE.md takes precedence
4. **Amendments** cascade to derived documents

### Required Protocols by Document Type

**Agents:**
- Verification (tier-appropriate)
- Learning candidates output
- Failure protocol
- Git authority constraints

**Skills:**
- Constitutional alignment
- Traceability integration
- Learning capture where applicable
