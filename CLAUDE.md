# CLAUDE.md

## User's Goal

**Rapid, efficient progress on complex projects requiring varied skillsets.**

- Optimize the user's time (compute usage is not a concern)
- Minimal, elegant solutions solving exactly the stated problem
- Nothing speculative, nothing unnecessary

## Why This Structure Exists

I have no memory across sessions. Without external structure, every session starts from zero—re-deriving context, re-debating decisions, duplicating work. But heavy structure creates friction that slows progress.

**Goal: Maximum effective memory with minimum maintenance burden.**

This structure compensates for memory loss while minimizing overhead. Use it when it helps. Skip it when it doesn't.

---

# Cognitive Architecture

## Why This Matters

Context is your scarcest resource. The context window fills fast, and performance degrades as it fills. Every file read, every command output, every exploration consumes tokens that could be used for actual work.

The cognitive architecture manages this constraint through mode separation and parallelization.

## Execution Modes

| Mode | Purpose | Why | Subagent |
|------|---------|-----|----------|
| **Explore** | Gather context without polluting main conversation | Subagents run in isolated context windows; only summaries return | `.claude/agents/explore.md` |
| **Plan** | Consider approaches before committing | Catching wrong approaches early saves more context than it costs | `.claude/agents/plan.md` |
| **Implement** | Surgical changes only | Minimizes diff size and review burden | `.claude/agents/implement.md` or direct |
| **Verify** | Confirm solution is minimal and correct | Catches overengineering before it compounds | `.claude/agents/verify.md` |

**When to use implement subagents:** For bounded, independent tasks that can run in parallel (e.g., separate features, test suites, modules with clear interfaces). Use direct implementation when tasks are sequential or tightly coupled.

## Parallelization

**IMPORTANT:** When tasks are independent, use parallel subagents liberally. Compute is not a constraint; the user's time is.

- Spawn parallel subagents for exploration, research, implementation, and verification
- Do not specify parallelism limits (let scheduling optimize)
- Aggregate and integrate results before proceeding
- For implementation: ensure clear boundaries between parallel tasks to avoid conflicts

**Why:** Parallel exploration trades tokens for wall-clock time. Subagents preserve main context by isolating exploration—they report findings, not raw file contents. This is critical for complex codebases where sequential exploration would exhaust context.

## Reflection Protocol

**YOU MUST** answer these before marking work complete:
1. Does this solve exactly the stated problem?
2. Is there code that could be removed?
3. Have I introduced complexity not requested?

If any answer raises doubt, revise before delivering.

For complex decisions, use triple reflection:
- **Error avoidance** — What could go wrong?
- **Success patterns** — What's worked before?
- **Synthesis** — Unified lesson for this decision

**Why:** Without reflection, solutions drift toward overengineering. The questions force verification against the actual request, not an imagined better version of it.

## Failure Protocol

When stuck or failing:
1. **Stop** after 2 failed attempts at the same approach
2. **Stash or reset** — `git stash` or `git checkout .` to restore clean state before trying alternatives
3. **Diagnose:** What specifically is failing and why?
4. **Decide:** Change approach, decompose further, or escalate to user
5. **If escalating:** Report what was tried, what failed, and what options remain

**NEVER** retry the same approach indefinitely. Structured failure beats infinite loops.

**Why:** [Research shows](https://arxiv.org/abs/2503.13657) multi-agent systems fail 41-86% of the time, primarily from specification problems and coordination failures. Explicit failure handling prevents cascading errors and wasted effort. Git reset prevents polluted state from affecting subsequent attempts.

## Termination Criteria

**Stop working when:**
- Success criteria are met and verified
- 2 distinct approaches have failed with no clear alternative
- Task requires information or access you don't have
- Scope has grown beyond original request (escalate first)

**Why:** Poor stop conditions are a documented failure mode—agents continue past useful completion, wasting context and user time.

## Parallel Conflict Prevention

Before spawning parallel implement agents:
1. **Define explicit file boundaries** for each agent
2. **No agent should modify files another agent reads**
3. **Use feature branches** when boundaries are unclear or tasks may overlap
4. **If conflict detected post-hoc:** Discard conflicting work, re-plan sequentially

**Why:** Parallel agents accept peer output uncritically. Conflicts cascade silently, corrupting the entire implementation. Prevention is cheaper than debugging. Branches provide true isolation when file boundaries are insufficient.

---

# Projects

## Why Projects Exist

Projects are structured memory for work spanning multiple sessions or agents. The two-file structure (OBJECTIVE.md + LOG.md) captures what we're building and what's happened without synchronization overhead.

**Use projects when:**
- Work spans multiple sessions
- Multiple agents work in parallel
- Objective requires decomposition

**Skip projects when:**
- Task completes in one session
- Scope is clear and bounded

For simple tasks: just do them. Don't pay the overhead when memory isn't needed.

## Structure

Every project has two files:

| File | Purpose |
|------|---------|
| OBJECTIVE.md | What we're building. Hierarchical if needed. Verifiable success criteria. Immutable without consent. |
| LOG.md | Append-only. Each entry: what was done, decisions (with rationale), what's next. |

**Why two files:** OBJECTIVE.md is the contract (stable). LOG.md is the history (grows). Separating them prevents the objective from drifting as work progresses. Append-only logging avoids synchronization bugs.

## Constraints

**Context budget:** OBJECTIVE.md + LOG.md ≤ 10% of context (~50-80KB).

*Why:* An agent needs 90% of context for actual work—reading code, tool outputs, reasoning. If project files exceed budget, the agent cannot comprehend its own scope. When exceeded, decompose into subprojects.

**Depth limit:** Maximum 3 levels.

*Why:* Verifying success requires checking all levels. Deeper hierarchies make verification intractable and hide complexity rather than managing it.

## Session Protocol

**Start:**
1. Read OBJECTIVE.md — establishes what success looks like
2. Read LOG.md — context on prior decisions
3. `git status` — understand working tree state
4. Confirm working level

**End:**
1. Append to LOG.md: accomplishments, decisions, what's next
2. Commit if implementation is verified and complete

**Why this order:** Reading objective first establishes success criteria. Reading log provides decision history. Git status reveals uncommitted work or dirty state from prior sessions. Committing at end creates recoverable checkpoints.

## Objective Trace

Always maintain the lineage from current level to root:

```
Root objective
  └── Parent objective
        └── Current ← you are here
```

Every action should serve this trace. If work doesn't connect, you may be drifting.

**Why:** The trace is your compass. It answers "why does this matter?" at any point. Without it, local optimization can diverge from the actual goal.

## Scope Rules

- Modify current level and below freely
- Read parent levels (read-only)
- Delegate subproject internals to sub-agents
- Escalate when crossing boundaries or discovering dependencies

**Why read-only parents:** Modifying parent scope without consent breaks the contract other agents may be working against. Escalation ensures architectural decisions get appropriate attention.

---

# Implementation

## Principles

1. **No assumptions** — State explicitly. If uncertain, ask.
2. **Simplicity** — Minimum code solving the problem. 200 lines → 50 lines.
3. **Surgical** — Touch only what's necessary. Match existing style.
4. **Verifiable** — Define success criteria. Loop until verified.

**Why these four:** They prevent the most common failure modes—hidden assumptions cause rework, overengineering wastes context, scattered changes obscure intent, unverified work ships bugs.

## Verification

Before marking implementation complete:
1. Run `git diff` to confirm changes are surgical
2. Flag if diff touches files unrelated to the request
3. Apply reflection protocol

**Why:** Diff provides objective measure of change scope. Subjective review misses scope creep; line counts don't lie.

## Anti-Patterns

**NEVER:**
- Add features beyond what was asked
- Create abstractions for single-use code
- Add "flexibility" or "configurability" not requested
- Handle errors for impossible scenarios
- Improve adjacent code unprompted

**Test:** Every changed line must trace directly to the user's request.

---

# Git

**Principle:** Safety net, not ceremony.

## When to Commit

- Implementation is verified and complete
- User explicitly requests
- Before attempting risky refactors

## When NOT to Commit

- Broken or unverified code
- "Progress" without working state
- Amending previous commits (unless explicitly requested)

## For Recovery

- `git stash` before attempting alternative approaches
- `git checkout .` to abandon failed attempts cleanly
- `git diff` to verify changes match intent

**Why:** Git provides recoverable checkpoints that LOG.md cannot—actual code state, not descriptions of it. But commits should mark verified milestones, not create noise.

---

# Commands

```bash
# Rust
cargo check && cargo test

# Solidity
forge build && forge test
```

# Gotchas

- Vendor directories may have pinned toolchains (check rust-toolchain.toml)
- SP1/RISC-V targets require specific nightly versions
