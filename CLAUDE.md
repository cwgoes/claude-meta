# CLAUDE.md

> **Quick reference:** [CLAUDE-quick.md](CLAUDE-quick.md) (~50 lines) for agents needing fast orientation.

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

**Conflict resolution:** When protocols conflict, apply principle priority:
1. Would following this protocol waste user time? → Skip it
2. Is this adding structure not needed for the task? → Skip it
3. Otherwise → Follow the protocol

### Override Protocol

User can invoke streamlined operation at any time:

| Override | Effect |
|----------|--------|
| "Skip verification" | Trivial tier regardless of scope |
| "No logging" | Skip LOG.md entry for this work |
| "Quick mode" | Ad-hoc behavior even within active project |
| "Minimal ceremony" | Combine all above |

Claude acknowledges the override and proceeds. No justification required from user.

**Restoration:** Overrides apply to current task only. Next task resumes normal protocol unless user extends override.

---

## Work Modes

Work scales from lightweight to structured based on **uncertainty** and **duration**, not complexity.

| Mode | When | Structure | Traceability | Verification |
|------|------|-----------|--------------|--------------|
| **Ad-hoc** | Clear task, single session, no resumption needed | None | Git commits only (in working context) | Git commit (no formal record) |
| **Project** | Multi-session, decisions worth recording, or decomposition needed | Own repo with OBJECTIVE.md + LOG.md | Full checkpoint model + learnings | Per tier |
| **Autonomous** | Unattended execution, async user review (explicit invocation only) | Project structure + AUTONOMOUS-LOG.md + dedicated branch | Per-checkpoint tags + structured log | Per-checkpoint |

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

### Autonomous Mode

Autonomous mode enables unattended execution with full traceability for async review. It extends Project mode with additional structure for non-interactive operation.

**Invocation:** User explicitly requests via `/autonomous <project>`. Claude never auto-selects or suggests autonomous mode.

**Autonomous mode requires:**
- Explicit user invocation
- Existing project with OBJECTIVE.md (success criteria = termination conditions)
- Docker isolation (full permission bypass)
- Time budget specified at invocation

**Autonomous mode provides:**
- Dedicated branch: `auto/<project>-<YYYYMMDD-HHMM>`
- Structured log: AUTONOMOUS-LOG.md
- Tagged checkpoints for rollback
- Direction mechanism for async steering

**Relationship to Project mode:**
```
Project mode (interactive)
  ↓ user invokes /autonomous
Autonomous mode (unattended)
  ↓ terminates or budget exhausted
Project mode (review via /review-autonomous)
```

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

### Verification Depth

Research shows verifiers perform superficial checks despite being prompted for thoroughness. Use explicit checklists, not "verify thoroughly."

**Code changes:**
- [ ] Stated problem is solved (not adjacent problems)
- [ ] No unrelated modifications in diff
- [ ] Error paths handled (or explicitly noted as out-of-scope)
- [ ] Tests exercise the change (not just pass incidentally)
- [ ] No debug code, TODOs, or commented-out code left behind

**Analysis/Research:**
- [ ] Claims have citations or evidence
- [ ] Assumptions surfaced explicitly
- [ ] Confidence levels stated (high/medium/verify)
- [ ] Gaps in knowledge acknowledged

**Architectural decisions:**
- [ ] Alternatives considered and rejected with rationale
- [ ] Trade-offs explicit (what we're giving up)
- [ ] Reversibility assessed
- [ ] Impact on existing code identified

**Delegation outputs:**
- [ ] Output matches delegation contract schema
- [ ] Success criteria addressed (each one)
- [ ] Boundaries respected (no out-of-scope changes)
- [ ] Escalation conditions evaluated

---

## Traceability System

### Three-Layer Stack

| Layer | Purpose | Granularity |
|-------|---------|-------------|
| **Git** | Code state checkpoints | Atomic, recoverable |
| **LOG.md** | Decision history + session summaries | Session-level |
| **OBJECTIVE.md** | Contract for what we're building | Stable reference |

### Checkpoint Model

Three checkpoint levels based on execution mode:

| Level | When | What |
|-------|------|------|
| **Lightweight** | Incremental progress, no significant decisions | Git commit only |
| **Full** | Session end, significant decisions, milestone | Git commit + LOG.md entry |
| **Autonomous** | Decision, discovery, or reversal during unattended execution | Git tag + AUTONOMOUS-LOG.md entry |

**Lightweight checkpoint:**
- Git commit with standard message format
- No LOG.md entry required
- Use for: incremental saves, minor fixes, work-in-progress

**Full checkpoint:**
- Git commit referencing LOG session
- LOG.md entry documenting what, why, and learnings
- Use for: session boundaries, decisions worth recording, completed features

**Heuristic:** Default to lightweight. Upgrade to full when you'd regret not having the context later.

**Autonomous checkpoint:**
- Git tag: `checkpoint-NNN` on dedicated branch
- AUTONOMOUS-LOG.md entry with structured format
- Triggered by Claude's judgment, not time or line count
- Use for: decisions (chose approach A over B), discoveries (found constraint), reversals (approach failed)

**Autonomous checkpoint triggers:**
| Trigger | Example |
|---------|---------|
| **Decision** | Selected library, chose architecture, resolved ambiguity |
| **Discovery** | Found unexpected behavior, identified root cause, learned constraint |
| **Reversal** | Approach failed, rolling back, changing direction |
| **Milestone** | Feature complete, tests passing, objective partially met |

**Heuristic:** Checkpoint when a future reviewer would want to understand "why did it go this way?"

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

## Autonomous Execution

Autonomous mode enables Claude to make sustained progress without user interaction, maintaining full traceability for async review and course correction.

### Invocation

```
/autonomous <project> [--budget <duration>]
```

- **project**: Must have OBJECTIVE.md with verifiable success criteria
- **budget**: Time limit (default: 2h). Format: `30m`, `2h`, `4h`

### Isolation

Autonomous execution runs in Docker with `--dangerously-skip-permissions`:

```bash
docker run --rm --network none \
  -v "<workspace>:/workspace" \
  claude-autonomous -p "<prompt>" --dangerously-skip-permissions
```

**Rationale:** Full isolation replaces fine-grained permission checking. Blast radius is contained by the container, not by permission prompts.

### Branch Strategy

Every autonomous run creates a dedicated branch:

```
main (or current branch)
 └── auto/<project>-<YYYYMMDD-HHMM>
      ├── checkpoint-001 (tag)
      ├── checkpoint-002 (tag)
      └── checkpoint-003 (tag)
```

**Benefits:**
- Clean separation from mainline development
- Easy rollback to any checkpoint
- Merge, cherry-pick, or discard entire run
- Multiple concurrent autonomous runs don't conflict

### AUTONOMOUS-LOG.md

Append-only structured log for async review. Lives in project root alongside LOG.md.

```markdown
# Autonomous Execution Log

## Run [YYYY-MM-DD HH:MM] — [objective summary]

### Configuration
- Branch: `auto/<project>-<timestamp>`
- Budget: [duration]
- Session ID: [for resumption]

---

### Checkpoint NNN — [HH:MM] [Decision|Discovery|Reversal|Milestone]

**Context:** [what was being attempted]
**[Choice|Finding|Problem|Achievement]:** [what happened]
**Rationale:** [why this path]
**Confidence:** [High|Medium|Low]
**Files:** [modified files, or "none"]
**Tag:** `checkpoint-NNN`

---

### Termination — [HH:MM]

**Reason:** [Criteria met | Budget exhausted | Uncertainty threshold | Error]
**Elapsed:** [duration]
**Summary:** [what was accomplished]
**Unresolved:** [what remains]
**For Review:** [specific items needing human attention]
```

### Time Budget

Budget is specified in elapsed time, not tokens or cost.

**Behavior:**
1. Agent tracks elapsed time internally
2. At ~90% of budget, creates "budget approaching" checkpoint
3. Writes termination summary with resumption instructions
4. Exits gracefully

**No partial work loss:** Budget exhaustion triggers checkpoint, not abrupt termination.

### Termination Conditions

Autonomous execution terminates when ANY of:

| Condition | Action |
|-----------|--------|
| **Success criteria met** | Log achievement, merge candidate |
| **Budget exhausted** | Checkpoint state, document "Next" |
| **Uncertainty threshold** | Log uncertainty, request direction |
| **Unrecoverable error** | Log error, preserve state for debugging |
| **2 failed approaches** | Per Failure Protocol, stop and document |

**Uncertainty threshold:** When confidence drops below acceptable level for autonomous decision-making, stop rather than guess. Document the uncertainty and what information would resolve it.

### Direction Mechanism

User can steer autonomous execution async via DIRECTION.md:

```markdown
# Direction for Autonomous Execution

## Written: [timestamp]
## Applies From: checkpoint-NNN

### Guidance
- [Specific direction]
- [Constraint to enforce]
- [Approach to try or avoid]

### Priority Override
[Any constitutional defaults to adjust for this run]
```

**Flow:**
1. User reviews AUTONOMOUS-LOG.md
2. User creates/updates DIRECTION.md
3. User invokes `/autonomous <project> --resume`
4. Agent reads DIRECTION.md before continuing

### Review Protocol

Invoke via `/review-autonomous <project>`:

1. Parse AUTONOMOUS-LOG.md
2. Show checkpoint summary with decision points
3. Offer options:
   - **Approve**: Merge branch to main
   - **Rollback**: Reset to specific checkpoint
   - **Direct**: Write DIRECTION.md, continue
   - **Discard**: Delete branch entirely

### Integration with Existing Systems

| System | Autonomous Behavior |
|--------|---------------------|
| **Verification** | Per-checkpoint, not just final |
| **Learnings** | Captured in AUTONOMOUS-LOG.md, propagated on review |
| **Failure Protocol** | Honored — 2 failures triggers termination |
| **Context Persistence** | Session ID enables resumption |
| **Subagents** | Spawned normally within autonomous execution |

### Constraints

- **Explicit invocation only:** User must invoke `/autonomous` — Claude never auto-selects or suggests this mode
- **OBJECTIVE.md required:** Success criteria define termination conditions
- **Docker required:** Full permission bypass only in isolation
- **Single project:** One autonomous run per project at a time
- **No interactive prompts:** All decisions logged, not asked

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

*See Context Persistence for how this trace is maintained across compression.*

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
8. **Initialize context invariants** (see Context Persistence)

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

### Context Persistence

Context compression is automatic and invisible. Without explicit protocols, project awareness degrades silently during long sessions.

#### Context Invariants

When a project is active, these elements must be accessible at all times:

| Invariant | Source | Recovery |
|-----------|--------|----------|
| **Project path** | Session state | Re-read from workspace structure |
| **Current objective** | OBJECTIVE.md | Re-read file |
| **Objective trace** | OBJECTIVE.md hierarchy | Rebuild from parent references (see Project Decomposition) |
| **Working level** | Session state | Derive from project path |
| **Recent decisions** | LOG.md (last 2-3 sessions) | Re-read file tail |

**Invariant format** (maintain in working memory):
```
Project: [path relative to workspace]
Objective: [1-line summary from OBJECTIVE.md]
Trace: [root] → [parent] → [current]
Level: [project | subproject]
```

#### Refresh Triggers

Re-read project files when any of these occur:

| Trigger | Action |
|---------|--------|
| **Before major decision** | Verify objective trace alignment |
| **Before spawning subagent** | Prepare context payload |
| **Uncertainty about scope** | Re-read OBJECTIVE.md success criteria |
| **After extended exploration** (>10 tool calls without implementation) | Re-anchor to objective |
| **Context feels thin** | Refresh all invariants |

**Heuristic:** If you cannot state the current objective in one sentence without reading a file, refresh immediately.

#### Compression Recovery

When context has been compressed (detected by gaps in recall or thin context feel):

1. **Acknowledge** — "Context compressed, re-anchoring to project state"
2. **Re-read** — OBJECTIVE.md, then LOG.md (recent sessions)
3. **Rebuild** — Objective trace from current level upward
4. **Resume** — Continue work with restored context

This is not failure — it's normal operation for long sessions.

#### Delegation Contract

Every subagent delegation must specify (not optional):

```yaml
delegation:
  # Context
  project: [path relative to workspace]
  trace: [root] → [parent] → [current objective]

  # Task specification
  objective: [single sentence, measurable outcome]
  output_format:
    type: code | analysis | decision | artifact
    schema: [if structured, define expected fields]

  # Boundaries (explicit, not implicit)
  boundaries:
    files_writable: [explicit list, or "none"]
    files_readable: [explicit list, or "any within project"]
    tools_allowed: [explicit list]

  # Verification
  success_criteria:
    - [criterion 1 - binary verifiable]
    - [criterion 2 - binary verifiable]

  # Resource constraints
  effort_budget: small | medium | large

  # Escalation
  escalate_when:
    - [condition that should return to orchestrator]
    - [condition that indicates scope exceeded]
```

**Vague delegations fail.** Research shows 41.77% of multi-agent failures stem from specification problems.

| Bad | Good |
|-----|------|
| "Investigate the bug" | "Find root cause of TypeError in auth.py:142, report failing code path" |
| "Improve performance" | "Reduce response time of /api/users endpoint, measure before/after" |
| "Review the code" | "Verify auth.py changes match PR #42 spec, check error handling" |

Subagents operate within their boundaries and inherit the objective trace. They cannot modify parent objectives or LOG.md — only report findings for orchestrator integration.

#### Common Ground Protocol

Before acting on delegation, subagents must:

1. **Echo understanding**: Restate the objective in own words
2. **Surface assumptions**: List what you're assuming that wasn't stated
3. **Flag ambiguity**: Note terms or requirements open to interpretation
4. **Confirm scope**: Explicit acknowledgment of boundaries

Orchestrator reviews acknowledgment before subagent proceeds with significant work.

**Rationale:** Research shows "silent misunderstandings" propagate through downstream work undetected. Explicit acknowledgment catches divergence early. This adds one round-trip but prevents wasted work from misaligned execution.

#### State Externalization

Context state is tracked **per-project** at `<project-path>/context-state.json`. This supports multiple Claude Code windows in a workspace (each window works on its own project).

**Per-project state file:** `<project-path>/context-state.json`

```json
{
  "timestamp": "2024-01-15T14:30:00Z",
  "project": "projects/alpha",
  "objective": "Build distributed cache with <10ms p99 latency",
  "trace": ["workspace goal", "alpha: distributed systems", "current: cache layer"],
  "level": "project | subproject",
  "status": "active | paused | completed"
}
```

**Write triggers:**
- `/project-start` — initialize or update project's context-state.json
- After any refresh trigger — update that project's context-state.json
- `/session-end` — update status to "paused" or "completed"

**Statusline resolution:** The statusline displays the project whose context-state.json was most recently updated. This reflects the project currently being worked on in that Claude Code window.

**Self-check:** If Claude cannot populate these fields from working memory without reading files, that indicates context loss. Trigger Compression Recovery *before* writing state.

**Verification model:** The statusline shows the current project's objective trace and session metrics. If the user observes discrepancy between the statusline and Claude's actual behavior, the context invariant has failed. User can prompt: "Refresh your context state."

---

## Cognitive Architecture

### Execution Modes

| Mode | Purpose | Git Authority | Subagent |
|------|---------|---------------|----------|
| **Explore** | Gather codebase context | None | `.claude/agents/explore.md` |
| **Plan** | Evaluate approaches | None | `.claude/agents/plan.md` |
| **Implement** | Surgical changes | None (orchestrator commits) | `.claude/agents/implement.md` |
| **Verify** | Confirm minimal + correct | None | `.claude/agents/verify.md` |
| **Research** | External docs, papers, APIs | None | `.claude/agents/research.md` |
| **Autonomous** | Unattended long-running execution | Full (within dedicated branch) | `.claude/agents/autonomous.md` |

**Orchestrator authority:** Only the main/orchestrator agent commits to git and appends to LOG.md. Subagents report findings; orchestrator integrates.

**Autonomous authority:** In autonomous mode, the autonomous agent has full git authority within its dedicated branch. It cannot modify main/master directly.

### Skillset Matching

Match task characteristics to agent capabilities:

| Task Type | Primary Agent | When to Delegate |
|-----------|---------------|------------------|
| Codebase understanding | Explore | Unknown structure, need orientation |
| External information | Research | Docs, APIs, papers, specifications |
| Approach selection | Plan | Multiple valid paths, trade-offs unclear |
| Bounded code changes | Implement | Clear spec, defined file boundaries |
| Correctness checking | Verify | After implementation, before commit |

**Delegation heuristics:**
- **Parallelize** when tasks are independent and boundaries clear
- **Serialize** when output of one informs another
- **Escalate** when task exceeds agent's declared scope

**Skill selection:** When user request maps to a known skill (e.g., `/commit`, `/project-start`), invoke that skill rather than reimplementing its logic.

### Expertise Registry

Beyond task-agent mapping, maintain awareness of agent limitations:

| Agent | Strong At | Weak At | Escalate When |
|-------|-----------|---------|---------------|
| Explore | Codebase orientation, pattern finding | Implementation decisions, code changes | Need to modify code |
| Plan | Trade-off analysis, approach selection, decomposition | Execution details, actual implementation | Plan validated, ready to implement |
| Implement | Bounded code changes, surgical edits, following specs | Architectural decisions, unbounded scope | Scope exceeds stated boundaries |
| Verify | Correctness checking, criteria validation, diff review | Subjective quality, domain expertise | Verification requires specialized knowledge |
| Research | External docs, API references, papers, synthesis | Codebase-specific questions, implementation | Information found, ready to apply |
| Autonomous | Long-running unattended work, sustained progress, parallel exploration | Interactive decisions, ambiguous requirements, subjective judgment | Uncertainty exceeds threshold, requires user input |

**Anti-patterns (don't do these):**
- Explore for implementation → will drift without boundaries
- Implement for unbounded scope → will over-engineer
- Plan after implementation started → sunk cost bias
- Verify without explicit criteria → superficial checks

### Domain Specialization

Base agent types provide stable interaction protocols. Domain overlays provide specialized expertise.

**When to specialize:**
- Problem requires domain knowledge not in base agent
- Domain has known pitfalls worth pre-loading
- Multiple agents need consistent domain understanding

**When NOT to specialize:**
- Generic programming tasks
- Problem well-specified without domain context
- Quick tasks where specification overhead exceeds benefit

**Specialization format:**

```yaml
agent:
  base: Implement  # Stable archetype
  domain:
    name: "Rust async programming"
    context: |
      Working with tokio runtime, async/await patterns.
      Common issues: deadlocks from blocking in async context.
    patterns:
      - "Check for blocking calls in async functions"
      - "Verify spawn vs spawn_blocking usage"
    pitfalls:
      - "Don't hold locks across .await points"
    relevant_learnings:
      - [Reference from LEARNINGS.md if applicable]
```

Domain overlays augment, not replace, the base agent's protocols. Verification, failure handling, and git authority remain unchanged.

### Parallelization

**IMPORTANT:** When tasks are independent, use parallel subagents liberally. Compute is not a constraint.

- Spawn parallel subagents for exploration, research, implementation, verification
- **Pass context payload** to every subagent (see Context Persistence)
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

### Coordination Failure

Distinct from implementation failure. Research shows coordination problems cause 36.94% of multi-agent breakdowns.

**Detect when:**
- Subagent output doesn't match delegation contract
- Multiple agents modified overlapping files
- Subagent asks questions already answered in context payload
- Results from parallel agents contradict each other
- Aggregated results don't compose into coherent whole
- Subagent exceeded stated boundaries

**Response:**
1. **Stop** parallel work immediately
2. **Discard** conflicting outputs (don't attempt to merge)
3. **Diagnose** — specification problem or execution problem?
4. **If specification problem:** Improve delegation contract, re-delegate with explicit boundaries
5. **If execution problem:** Serialize work (don't re-parallelize same task)
6. **Capture learning** — What made the coordination fail?

**Key insight:** Adding more agents to broken coordination makes it worse, not better (Brooks' Law: coordination cost scales O(n²)). When coordination fails, reduce parallelism, don't increase it.

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
