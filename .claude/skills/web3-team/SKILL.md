---
name: web3-team
description: Spawn an agent team to design, implement, verify, and audit full-stack web3 applications
constitution: CLAUDE.md
alignment:
  - Agent Registry
  - Delegation
  - Learnings
  - Verification Tiers
  - Core Invariants
---

# /web3-team

Spawn a coordinated agent team for full-stack web3 application development.

## Invocation

```
/web3-team <project-path> --phase <design|implementation|verification>
```

- `<project-path>` — Path to project directory (must contain OBJECTIVE.md)
- `--phase` — Starting phase (required)

## Team Structure

| Role | Agent Name | Model | Lead | Design | Impl | Verify |
|------|-----------|-------|------|--------|------|--------|
| Technical Architect | `architect` | opus | Yes | active | active | active |
| UI/UX Designer | `designer` | sonnet | No | active | on-call | active |
| Senior Backend Engineer | `backend` | sonnet | No | active | active | on-call |
| Senior Frontend Engineer | `frontend` | sonnet | No | active | active | on-call |
| Senior QA Engineer | `qa` | sonnet | No | active | active | on-call |
| Senior Auditor | `auditor` | opus | No | active | active | active |

**On-call** = not spawned until needed. **Standby** = not spawned in this phase.

## Communication Topology

```
User ←→ Orchestrator (you) ←→ architect ←──→ designer
                                  ↕       ╲        ↕↘
                               backend    auditor  frontend
                                  ↕                  ↕
                                 qa ←───────────────→
```
(Simplified. See table below for authoritative topology.)

| Agent | Can message |
|-------|-------------|
| architect | designer, backend, frontend, qa, auditor, orchestrator |
| designer | architect, frontend, auditor |
| backend | architect, qa |
| frontend | architect, designer, qa |
| qa | architect, backend, frontend |
| auditor | architect, designer |

**Routing rule:** Important decisions flow: agent → architect → orchestrator → user (via AskUserQuestion).

Engineers do NOT message each other directly — coordination goes through architect.

## Decision Delegation Boundaries

The architect must classify every decision into one of three tiers:

### User-Required (architect MUST route to orchestrator → user)

- Tech stack choices (framework, language, chain, library)
- Adding new external dependencies or third-party services
- Scope changes affecting OBJECTIVE.md success criteria
- Security model decisions (auth scheme, key management, access control)
- Deployment architecture (hosting, infrastructure, CI/CD)
- Any deviation from the approved ARCHITECTURE.md or DESIGN.html
- Data model changes that affect user-facing behavior
- Smart contract upgradeability or immutability decisions
- Removing or deferring a feature from the approved design

### Architect-Autonomous (architect decides, documents in ARCHITECTURE.md)

- Implementation ordering and task decomposition
- File and directory structure within approved architecture
- Internal API design (private functions, helper modules) within approved contracts
- Task assignment to specific engineers
- Bug fix prioritization (severity ordering)
- Choice between equivalent implementation approaches that don't affect external behavior
- Test strategy details within the approved test framework
- Error message wording and logging strategy

### Inform-Only (architect decides, mentions in next status update)

- Minor refactors within spec (renaming internals, extracting helpers)
- Build tooling configuration (tsconfig, eslint, compiler flags)
- Code formatting and style choices
- Dependency version pinning (within compatible range)
- Test file organization

**When uncertain:** Escalate to User-Required. The cost of asking is low; the cost of a wrong autonomous decision is high.

## Document Authority

When spec documents and code disagree, authority follows this hierarchy:

**OBJECTIVE.md > ARCHITECTURE.md > DESIGN.html > COMPONENTS.md > WIRING.md > code**

If code is correct and a spec document is stale, update the spec document first, then mark any related audit finding as resolved. Never treat stale documentation as "the code is wrong."

---

## Protocol

### 1. Validate Project

1. Verify `{project-path}/OBJECTIVE.md` exists — error if missing
2. Read OBJECTIVE.md — extract objective summary and success criteria
3. Read LOG.md if it exists — understand prior work
4. Read workspace LEARNINGS.md — check for applicable patterns
5. Verify project has a git repository

### 2. Validate Phase Prerequisites

| Starting Phase | Required Artifacts |
|----------------|-------------------|
| design | OBJECTIVE.md |
| implementation | OBJECTIVE.md, ARCHITECTURE.md, DESIGN.html, COMPONENTS.md |
| verification | OBJECTIVE.md, ARCHITECTURE.md, DESIGN.html, COMPONENTS.md, WIRING.md, passing build |

If prerequisites are missing, report what's missing and ask user whether to proceed (potentially starting from an earlier phase).

### 3. Create PHASE.md

Write `{project-path}/PHASE.md`:

```markdown
---
phase: {phase}
started: {ISO 8601}
project: {project-path}
team: web3-{project-name}
---
# Phase: {Phase Name}

## Team
| Role | Agent | Status |
|------|-------|--------|
| Technical Architect (Lead) | architect | active |
| UI/UX Designer | designer | active |
| Senior Backend Engineer | backend | {active|on-call|standby} |
| Senior Frontend Engineer | frontend | {active|on-call|standby} |
| Senior QA Engineer | qa | {active|on-call|standby} |
| Senior Auditor | auditor | active |

## Phase Objective
{phase-specific objective from Phase Definitions below}

## Expected Artifacts
{list from Phase Definitions below}

## Exit Criteria
{list from Phase Definitions below}
```

### 4. Create Team

```
TeamCreate:
  team_name: "web3-{project-name}"
  description: "Web3 full-stack team for {project-name}: {phase} phase"
```

### 5. Create Tasks and Spawn Agents

Create tasks per the active Phase Definition (below), then spawn agents using the Agent Prompts (below).

**Spawn order:** architect first (orient and plan), then remaining phase-active agents.

**Task assignment:** Use TaskCreate for all work items. Use TaskUpdate to assign owners. Per LEARNINGS.md: formal task assignment with IDs gets picked up more reliably than inline requests.

### 6. Orchestrate

Your ongoing responsibilities as orchestrator:

- **Route decisions:** When architect sends you a message flagged as needing user input, use AskUserQuestion to get the user's decision and relay it back
- **Monitor progress:** Check TaskList periodically; intervene if agents are stuck
- **Intervene on breakdown:** If agents stop communicating, create explicit tasks (per LEARNINGS.md)
- **Phase transitions:** Only on explicit user instruction (see Phase Transition below)
- **Report:** When user asks for status, summarize from TaskList and recent agent messages

**Do NOT micromanage.** Let the architect coordinate. Only intervene for user-facing decisions and breakdowns.

### Status Report Format

When the user asks for status, output:

```
## Team Status: {project-name} — {phase} phase

**Tasks:** {completed}/{total} ({in_progress} active, {blocked} blocked)
**Build:** {pass/fail/not-run}
**Tests:** {pass/fail/not-run} ({N}/{M} passed)

### Active Work
- {agent}: {current task summary}

### Completed Since Last Report
- {task}: {1-line summary}

### Blockers
- {blocker description} (assigned to: {agent})

### Pending Decisions
- {decision needed} — awaiting user input
```

---

## Phase Definitions

### Design Phase

**Objective:** Comprehensively design and specify the application before any implementation begins.

**Active agents:** All 6.

**Tasks:**

| # | Task | Owner | Blocked By | Description |
|---|------|-------|------------|-------------|
| 1 | System Architecture Design | architect | — | Read OBJECTIVE.md. Design system architecture. Produce ARCHITECTURE.md with: system diagram (ASCII), component specs, API contracts, data models, blockchain integration, deployment architecture, security considerations, test strategy (specifying test frameworks for frontend, backend, contracts), patterns section (naming conventions, error handling approach, module structure, state management). Identify engineering hypotheses to validate. |
| 2 | Visual Design | designer | — | Read OBJECTIVE.md. Coordinate with architect on component list. Design all user-facing flows. Produce DESIGN.html (single self-contained HTML file) with: mockups for every screen, component hierarchy, interaction patterns, responsive behavior, color/typography system. |
| 3 | Backend Hypothesis Validation | backend | 1 | Receive hypothesis list from architect. Write throwaway PoC code to validate technical feasibility (blockchain interactions, performance characteristics, integration patterns). Report findings to architect. |
| 4 | Frontend Hypothesis Validation | frontend | 1, 2 | Receive hypothesis list from architect/designer. Write throwaway PoC code for UI/interaction patterns. Report findings to architect/designer. |
| 5 | Test Infrastructure Validation | qa | 1 | Read ARCHITECTURE.md Test Strategy for framework choices. Set up test framework scaffolding per specified frameworks. Validate key components are testable as designed. Report testability concerns to architect. |
| 6 | Design Review | auditor | 1, 2 | Devil's advocate on both system and visual design. Review ARCHITECTURE.md for: inconsistencies, missing edge cases, security gaps, over-engineering, under-specification. Review DESIGN.html for: UX issues, missing flows, accessibility gaps, inconsistency with architecture. Explicitly flag every component, abstraction, or flow that could be removed or merged without violating OBJECTIVE.md. Report findings to architect and designer. |
| 7 | Simplification Review | architect | 6 | Gate: before producing COMPONENTS.md, review ARCHITECTURE.md and DESIGN.html with one question: "what can we remove or merge while still meeting every OBJECTIVE.md criterion?" Eliminate components that exist for hypothetical future needs, merge components with a single consumer into their consumer, collapse abstraction layers that add indirection without value. Document each removal/merge decision briefly in ARCHITECTURE.md. Send simplification summary to orchestrator for user awareness. |
| 8 | Component Map | architect | 7 | After architecture and design are stable, auditor feedback is incorporated, and simplification review is complete, produce COMPONENTS.md mapping every module to its spec section and owning engineer. Ensure complete coverage of OBJECTIVE.md. |
| 9 | Design Approval | architect | 8 | Synthesize all feedback. Send final ARCHITECTURE.md + DESIGN.html + COMPONENTS.md summary to orchestrator for user approval. ALL important decisions must be explicitly cleared with user (see Decision Delegation Boundaries). |
| 10 | PoC Cleanup | architect | 9 | After design approval, delete ALL throwaway PoC code from the source tree. If any PoC is worth preserving for reference, move it to `scratch/` (gitignored). Verify no PoC artifacts remain in the production source directories. |

**Exit criteria:**
- ARCHITECTURE.md complete (including Patterns section)
- DESIGN.html (HTML) complete with mockups for all flows
- COMPONENTS.md complete with full coverage
- Auditor review complete, all findings resolved
- Simplification review complete — architect has justified every component's existence against OBJECTIVE.md
- User has approved all important design decisions
- All throwaway PoC code deleted or isolated to `scratch/` (gitignored) — zero PoC artifacts in production source tree

### Implementation Phase

**Objective:** Implement the application per the design specification.

**Active agents:** architect, backend, frontend, qa, auditor (active). Designer on-call (spawned when QA captures screenshots for visual review).

#### Existing Code Reconciliation (if starting fresh at this phase)

If the team is starting at implementation phase (not transitioning from design) and the project already has code:

1. **Architect explores existing codebase** — read all source files, understand current structure
2. **Reconcile with ARCHITECTURE.md** — identify what's already implemented vs. what remains. Update COMPONENTS.md status column to reflect reality.
3. **Auditor does quick review** — scan existing code for obvious issues, flag to architect
4. **Architect reports to orchestrator** — summary of existing state, proposed implementation plan for remaining work, any inconsistencies between existing code and spec
5. **Orchestrator routes to user** for approval before proceeding

Only after reconciliation does the architect create the implementation task breakdown below.

**Initial tasks (architect creates detailed breakdown after orienting):**

| # | Task | Owner | Description |
|---|------|-------|-------------|
| 1 | Implementation Planning + WIRING.md | architect | Read ARCHITECTURE.md, DESIGN.html, COMPONENTS.md. Produce WIRING.md listing ALL expected inter-component connections (all "unwired" initially). Decompose into implementation tasks with explicit file boundaries. Define mock interface contracts (see Mock-to-Real Pattern). Assign to backend/frontend. |
| 2 | Mock Interface Contracts | architect | Define TypeScript/Solidity interfaces for every cross-boundary dependency (backend↔frontend, app↔contracts). These are the FIRST implementation artifact — engineers build against these, not against each other's code. Commit as standalone files. |
| 3 | Continuous Testing | qa | Write tests as implementation progresses (NOT after). Frontend: Playwright E2E. Backend: unit + integration. Contracts: Forge/Hardhat. Report failures immediately to the appropriate engineer. |
| 4 | Implementation Audit | auditor | Review code as it's produced. Check spec compliance (ARCHITECTURE.md) and visual compliance (DESIGN.html). Cross-reference WIRING.md — flag any "unwired" connections that should be wired by now. Check pattern consistency (ARCHITECTURE.md Patterns section) — flag deviations in naming, error handling, module structure. Flag unnecessary complexity and simplification opportunities as findings. Report findings to architect ONLY. |
| 5 | Design Sync | designer | Monitor frontend implementation for visual fidelity. Update DESIGN.html if design decisions change. Coordinate with frontend engineer on deviations. |
| 6 | Architecture Sync | architect | Monitor implementation for architectural fidelity. Update ARCHITECTURE.md, COMPONENTS.md, and WIRING.md to reflect actual implementation. Route all important changes through orchestrator to user. |

The architect creates additional numbered tasks from COMPONENTS.md, assigning each to `backend` or `frontend` with explicit `files_writable` boundaries. See also Mock-to-Real Pattern and Wire-Up Tasks below.

#### Mock-to-Real Pattern

Per LEARNINGS.md, parallel frontend/backend implementation works best with mock-to-real swap:

1. **Architect defines mock interface contracts** (task 2 above) — TypeScript interfaces, mock implementations with realistic fake data, Solidity interface files
2. **Frontend builds against mocks** — imports from mock files, full UI integration works end-to-end with fake data
3. **Backend builds real implementations** — implements the same interfaces with actual blockchain/API logic
4. **Explicit swap task** — architect creates a dedicated task: "Replace mock implementations with real" assigned to the appropriate engineer. This is NOT implicit — it is a tracked, verified task.
5. **Integration checkpoint** — after swap, run full E2E flow to verify real implementations work where mocks did

Mock files live in a dedicated directory (e.g., `src/mocks/` or `test/mocks/`) and are deleted after swap is verified.

**Exit criteria:**
- All COMPONENTS.md components implemented
- All WIRING.md connections marked "wired" (zero unwired)
- build.sh and test.sh exit 0
- ARCHITECTURE.md, DESIGN.html, and WIRING.md in sync with implementation
- Auditor has reviewed all produced code
- All mock implementations replaced with real (no mocks in production code)

### Verification Phase

**Objective:** Verify completeness, coherency, and minimality of the implementation.

**Active agents:** architect, designer, auditor (primary). Engineers and QA on-call.

#### Existing Code Reconciliation (if starting fresh at this phase)

If the team is starting at verification phase (not transitioning from implementation):

1. **Architect explores entire codebase** — read all source files, understand structure and completeness
2. **Reconcile with ARCHITECTURE.md and COMPONENTS.md** — verify they describe what's actually built. Update if stale.
3. **Create WIRING.md if missing** — enumerate all inter-component connections and their wired/unwired status by grepping the code
4. **Architect reports to orchestrator** — summary of codebase state, any spec/code discrepancies found, proposed verification plan
5. **Orchestrator routes to user** for approval before full verification begins

**Tasks:**

| # | Task | Owner | Description |
|---|------|-------|-------------|
| 1 | Verification Planning | architect | Define verification checklist from OBJECTIVE.md success criteria. Assign auditor to comprehensive code review. Coordinate with designer on visual verification. |
| 2 | Full Code Audit | auditor | Read EVERY line of code. Check against ARCHITECTURE.md, DESIGN.html, and WIRING.md. Verify every WIRING.md connection is actually wired in code. Verify pattern consistency (ARCHITECTURE.md Patterns section) across all files. Produce AUDIT.md with categorized findings (critical/high/medium/low). Check for: bugs, dead code, missing error handling, security issues, inconsistencies. Dedicate an AUDIT.md section to **Simplification Opportunities** — every abstraction, wrapper, indirection layer, or component that could be removed or inlined without violating OBJECTIVE.md criteria. |
| 3 | Visual Verification | designer | Review every UI screen against DESIGN.html mockups. Flag inconsistencies, missing interactions, accessibility issues. Report to architect. |
| 4 | Architecture Verification | architect | Verify all OBJECTIVE.md criteria are met with evidence. Review AUDIT.md findings and prioritize. Assign fix tasks to appropriate engineer (spawn on-call agents as needed). |
| 5 | Final Consistency Check | architect | (Blocked by all fixes.) Verify all spec/doc/code consistent. Verify all audit findings resolved. Verify build.sh and test.sh pass. Present verification summary to orchestrator for user approval. |

Engineers and QA are spawned on-call when needed. Each fix task gets explicit scope and acceptance criteria.

**Exit criteria:**
- AUDIT.md exists with all findings resolved
- All OBJECTIVE.md success criteria met with evidence
- All documentation (ARCHITECTURE.md, DESIGN.html, COMPONENTS.md, WIRING.md) consistent with implementation
- WIRING.md: zero unwired connections, zero unjustified orphans
- build.sh, test.sh exit 0
- User has approved final state

---

## Agent Prompt Files

Agent prompts are in the `prompts/` subdirectory (relative to this skill file). Each file contains the base prompt and phase-specific instruction variants for one agent.

| Agent | File | Model |
|-------|------|-------|
| architect | `prompts/architect.md` | opus |
| designer | `prompts/designer.md` | sonnet |
| backend | `prompts/backend.md` | sonnet |
| frontend | `prompts/frontend.md` | sonnet |
| qa | `prompts/qa.md` | sonnet |
| auditor | `prompts/auditor.md` | opus |

### Spawning Protocol

1. Read the agent's prompt file from the table above
2. Extract the **Base Prompt** section (everything from "## Base Prompt" to "## Phase Instructions")
3. From **Phase Instructions**, extract the subsection matching the current phase
4. In the base prompt, replace `{phase_instructions}` with the extracted phase instructions
5. Substitute remaining variables: `{project_path}`, `{objective_summary}`, `{phase}`
6. Spawn via `Task` tool with `subagent_type: "general-purpose"`, `team_name: "web3-{project-name}"`, the agent's `model` from the table above, and `name` matching the agent name

---

## Artifact Definitions

### ARCHITECTURE.md

System architecture specification. Owned by architect.

```markdown
# Architecture: {Project Name}

## Overview
[1-paragraph system description]

## System Diagram
[ASCII diagram: all components, data flow, external dependencies]

## Components

### {Component Name}
- **Purpose:** [what it does]
- **Technology:** [stack]
- **Interfaces:** [API contracts, events, function signatures]
- **Data Model:** [key structures]

## Blockchain Integration
- **Network:** [chain(s)]
- **Contracts:** [list with purposes]
- **Transaction Flow:** [creation → signing → submission → confirmation]
- **State Sync:** [how frontend stays in sync with chain state]

## API Contracts
[Endpoint/function definitions, request/response schemas]

## Data Models
[Key structures and relationships]

## Deployment
[How the system is deployed]

## Patterns
- **Naming:** [conventions for files, functions, variables, components]
- **Error handling:** [approach — e.g., Result types, try/catch boundaries, error propagation]
- **Module structure:** [standard file layout, export conventions]
- **State management:** [where state lives, how it flows]

## Security Considerations
[Auth, key management, input validation, access control]
```

### DESIGN.html

Single self-contained HTML file with visual mockups. Owned by designer. **Must use .html extension** so it can be opened directly in a browser. No external dependencies — all CSS inline. Viewable by double-clicking the file.

### COMPONENTS.md

Component-to-specification map. Owned by architect.

```markdown
# Component Map

## Coverage
- Components: N
- Mapped to spec: N/N
- OBJECTIVE.md criteria covered: N/N

## Components

| Component | Spec Section | Owner | Files | Status |
|-----------|-------------|-------|-------|--------|
| {name} | ARCHITECTURE.md §X | backend | path/to/files | designed / implemented / verified |

## Criteria Trace

| Criterion | Components |
|-----------|-----------|
| SC-1 | Component A, Component B |
| SC-2 | Component C |
```

### WIRING.md

Inter-component connection map. Owned by architect. Tracks every dependency between components — imports, function calls, event subscriptions, route registrations, config references. Created at the start of implementation phase, updated as implementation proceeds.

```markdown
# Wiring Map

## Legend
- `-->` = imports/calls
- `==>` = event/subscription
- `~~>` = config/env reference

## Connections

| Source | Target | Type | Wire | Status |
|--------|--------|------|------|--------|
| Frontend:WalletConnect | Backend:WalletProvider | import | `import { WalletProvider } from '../providers/wallet'` | wired / unwired |
| Backend:TxSubmitter | Contract:Vault.deposit | call | `vault.deposit(amount, { value: msg.value })` | wired / unwired |
| Frontend:App | Frontend:Dashboard | route | `<Route path="/dashboard" element={<Dashboard />} />` | wired / unwired |
| Backend:EventListener | Contract:Vault.Deposit | event | `vault.on('Deposit', handler)` | wired / unwired |
| Backend:Config | Env:RPC_URL | config | `process.env.RPC_URL` | wired / unwired |

## Unwired Count
- Total connections: N
- Wired: N
- Unwired: N ← MUST be 0 before implementation phase exit

## Orphan Check
Components with no incoming connections (not imported/called by anything):
- [list — each must be justified as an entry point or flagged as dead code]
```

The auditor uses WIRING.md as a checklist during implementation: every row marked "unwired" is a HIGH finding. The architect updates WIRING.md as engineers complete wire-up tasks.

### AUDIT.md (Verification phase)

Audit findings. Owned by auditor.

```markdown
# Audit Report

## Summary
- Files reviewed: N
- Total findings: N (C critical, H high, M medium, L low)
- Resolved: N/N

## Findings

### [SEVERITY] #N: {Title}
- **File:** path:line
- **Description:** [what's wrong]
- **Expected:** [per spec]
- **Actual:** [in code]
- **Patchable:** yes / `NOT PATCHABLE` (if structural flaw — triggers escalation)
- **Status:** open / fixed / wontfix
- **Resolution:** [how fixed, or why wontfix]
```

---

## Completion Verification Protocol

Claude agents frequently declare tasks "done" when implementation is partial — components exist but aren't wired together, functions are defined but never called, imports are missing. This is mitigated at four levels:

| Level | Who | What |
|-------|-----|------|
| Self-check | Engineers | Completion gate before marking task done (build, grep imports, verify wiring, smoke test) |
| Lead check | Architect | Run build.sh/test.sh before acknowledging any completion |
| Audit check | Auditor | Flag dead code, missing imports, stubs, orphaned components, remaining mocks |
| Spot-check | Orchestrator | Independently verify build/test results (see below) |

Detailed instructions for each level are in the agent prompt files.

### Orchestrator Spot-Checks

Every 3-4 completed tasks, independently run `build.sh` and `test.sh` and compare against what agents report. If agents claim success but scripts fail, flag the discrepancy immediately.

### Integration Checkpoints

The architect schedules explicit integration checkpoint tasks at natural boundaries (contracts↔backend, backend↔frontend, mock-to-real swap, routes↔navigation). Each checkpoint requires running the app end-to-end through one user flow — not just "code exists" but "code runs." See architect implementation instructions in `prompts/architect.md`.

### Wire-Up Tasks

The architect creates explicit tasks for connecting components — separate from "implement component X." Each corresponds to WIRING.md rows changing from "unwired" to "wired." This separation exists because the dominant failure mode is implementing X without connecting it.

---

## Verification Escalation Protocol

When verification finds discrepancies that aren't fixable with targeted patches, the standard fix loop is insufficient. This protocol defines detection, classification, and response.

### Severity Bands

After AUDIT.md is produced and designer reports are in, the architect classifies the overall verification result:

| Band | Meaning | Example |
|------|---------|---------|
| **Patch** | All findings individually fixable without changing interfaces or architecture | Missing error handling, off-by-one, styling bugs, minor wiring gaps |
| **Re-implement** | Components need rewriting but architecture and design are sound | Feature entirely missing, component built against wrong spec section, large portion of WIRING.md unwired |
| **Re-design** | Architectural or design flaws that targeted fixes cannot resolve | Reentrancy surface requiring contract redesign, data model can't support a success criterion, UI flow fundamentally doesn't match user stories |

### Escalation Triggers

Architect MUST escalate beyond Patch when ANY of these hold:

- 3+ CRITICAL findings in AUDIT.md
- Any OBJECTIVE.md success criterion has zero implementation (not a bug — the feature doesn't exist)
- WIRING.md unwired connections > 30% of total
- Auditor marks a finding as `NOT PATCHABLE` (auditor has this authority — see auditor verification instructions)
- Designer reports a screen/flow with no correspondence to any DESIGN.html mockup

When a trigger fires, the architect MUST classify the band and report to orchestrator. Do NOT attempt to fix-forward through structural problems.

### Response: Patch (Normal Path)

No change to standard verification flow. Architect spawns engineers, assigns fix tasks, auditor re-reviews, final consistency check.

### Response: Re-implement

1. Architect produces a **Remediation Plan**: which components need rewriting, why, estimated scope, which WIRING.md connections are affected
2. Architect sends Remediation Plan to orchestrator
3. Orchestrator presents to user with options:
   - (a) Approve re-implementation of listed components
   - (b) Reduce scope / accept current state with known limitations
   - (c) Abort
4. If approved: transition back to implementation phase for **only** the affected components
   - PHASE.md records: `phase: implementation (remediation)`
   - Unaffected code is frozen — engineers may NOT touch it
   - Architect creates scoped tasks for only the remediation work
   - Normal implementation phase gates apply (build-on-every-completion, wiring checks, auditor review)
5. After remediation complete: re-enter verification phase
   - Auditor re-audits only changed files + their WIRING.md connections
   - Designer re-verifies only affected screens (fresh screenshots)
   - Unchanged code is NOT re-audited

### Response: Re-design

1. Architect produces a **Design Flaw Report**: what's wrong, why it can't be patched, what needs to change in ARCHITECTURE.md or DESIGN.html
2. Architect sends Design Flaw Report to orchestrator
3. Orchestrator presents to user with options:
   - (a) Approve return to design phase for affected areas
   - (b) Accept current state with known limitations documented
   - (c) Abort
4. If approved: transition to design phase scoped to the flaw
   - PHASE.md records: `phase: design (remediation — {flaw description})`
   - Only the affected components go through redesign → re-implementation → re-verification
   - Full design phase gates apply (auditor review of revised design, user approval, PoC cleanup)
   - Unaffected components are frozen
5. After redesign approved: proceed through implementation (remediation) → verification as above

### Decision Authority

| Band | Authority |
|------|-----------|
| Patch | Architect-Autonomous (assign fixes without user approval for each) |
| Re-implement | User-Required (scope regression needs explicit approval) |
| Re-design | User-Required (architectural changes always need approval) |

### Regression Limit

Maximum **2 regressions** per project. If verification fails a third time, the architect MUST:

1. Produce a frank assessment: what keeps failing and why
2. Send to orchestrator
3. Orchestrator presents to user with options: continue (with acknowledged risk), descope, or abandon
4. No further regressions without explicit user override

This prevents infinite regression loops.

---

## Project Completion

When verification phase exit criteria are met and the user approves the final state:

### 1. Final Summary

Architect produces a completion summary:
- All OBJECTIVE.md success criteria with evidence
- AUDIT.md status (all findings resolved)
- WIRING.md status (zero unwired, zero unjustified orphans)
- build.sh and test.sh results

### 2. Learnings Capture

Architect identifies learning candidates from the project:
- **Avoid:** patterns that caused problems, repeated failures, wasted effort
- **Prefer:** patterns that worked well, efficient approaches, useful tools/libraries

Architect sends candidates to orchestrator. Orchestrator adds confirmed learnings to:
- Project LEARNINGS.md (project-specific insights)
- Workspace LEARNINGS.md (generalizable patterns)

### 3. Log Entry

Orchestrator creates a LOG.md entry summarizing:
- What was built
- Key decisions made
- Verification results
- Learnings captured

### 4. Git Add and Push

Orchestrator prompts the user with options:
- **(a) Add, commit, and push** — stage all project files, commit, push to remote
- **(b) Commit only** — stage and commit, no push
- **(c) Skip** — leave changes uncommitted

If (a) or (b), use the `/commit` skill for proper commit format and verification.

### 5. Team Shutdown

Orchestrator sends `shutdown_request` to all active agents. After all agents confirm shutdown, run `TeamDelete` to clean up team resources.

---

## Phase Transition

Phases progress ONLY when the user explicitly instructs (e.g., "move to implementation").

**Transition protocol (forward):**

1. **Check exit criteria** for current phase — report any gaps to user
2. **Design→Implementation specific:** Verify no throwaway PoC code remains in production source directories. Run `find` for scratch files, check `scratch/` is gitignored. This is a hard gate — do not proceed with PoC contamination.
3. **Ask user** whether to proceed despite gaps (if any) or address them first
4. **Update PHASE.md** with new phase, timestamp, agent statuses
5. **Adjust team:**
   - Spawn new agents needed for next phase
   - Send shutdown_request to agents not needed (standby)
   - Notify active agents of phase change via message
6. **Create tasks** for new phase per Phase Definitions
7. **Architect orients** on new phase — reads updated PHASE.md and artifacts

**Transition protocol (remediation regression — see Verification Escalation Protocol):**

1. **User has approved** regression (Re-implement or Re-design band)
2. **Update PHASE.md:** `phase: {target phase} (remediation)` with description of what's being remediated and which components are in scope
3. **Freeze unaffected code:** Architect explicitly lists frozen files/components. Engineers may NOT touch frozen code — boundary violations are rejected.
4. **Spawn scoped agents:** Only spawn engineers needed for the affected components. Auditor and designer remain active but scoped to affected areas.
5. **Create scoped tasks:** Only for the remediation work. Normal phase gates apply within scope.
6. **Track regression count:** Record in PHASE.md: `regression_count: {N}`. If N reaches 2, the next failure triggers the regression limit protocol (architect produces frank assessment, user decides).
7. **On remediation completion:** Re-enter verification phase scoped to changed files + their connections. Update PHASE.md to `phase: verification (post-remediation)`.

---

## Failure Protocol

| Condition | Response |
|-----------|----------|
| Project path invalid | Report error, suggest `/project-start --list` |
| No OBJECTIVE.md | Report error, suggest `/project-create` |
| Missing phase prerequisites | Report what's missing, suggest earlier phase |
| Team already exists for project | Offer to resume or restart |
| Agent stuck / unresponsive | Create explicit task (per LEARNINGS.md) |
| Communication breakdown | Orchestrator creates tasks and directly assigns |
| Agent reports scope expansion | Architect re-plans, creates new tasks |
| Build/test failure | Route to appropriate engineer via architect |
| Verification finds substantial discrepancies | Architect classifies band (see Verification Escalation Protocol), routes Re-implement/Re-design to orchestrator → user |
| Regression limit reached (2 regressions) | Architect produces frank assessment, orchestrator presents to user: continue/descope/abandon |
| All verification exit criteria met | Begin Project Completion protocol (summary, learnings, log, git, shutdown) |

---

## Integration

- Respects OBJECTIVE.md success criteria and verification hierarchy
- LOG.md entries via `/commit` skill
- Learnings captured in project and workspace LEARNINGS.md
- Follows verification tiers for all changes
- Checkpoint model for commits (orchestrator authority only)
