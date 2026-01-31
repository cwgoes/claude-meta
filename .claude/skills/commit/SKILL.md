---
name: commit
description: Create a git commit with proper verification and message format
constitution: CLAUDE.md
alignment:
  - Traceability System / Checkpoint Model
  - Traceability System / Commit Message Format
  - Verification System / Verification Tiers
  - Verification System / Verification Gates
---

# /commit

Create a properly formatted git commit with verification tier awareness.

## Invocation

```
/commit [message]
/commit --full [message]
```

- `message` — Optional commit message summary. If omitted, will be inferred from staged changes.
- `--full` — Force full checkpoint (LOG.md entry required)

## Protocol

### 1. Analyze Staged Changes

```bash
git diff --cached --stat
git diff --cached --name-only
```

Determine:
- Number of files changed
- Approximate lines changed
- File types affected

### 2. Infer Verification Tier

| Condition | Tier |
|-----------|------|
| ≤1 file AND ≤10 lines | Trivial |
| Files match `security\|auth\|crypto\|password\|token\|secret` | Critical |
| Otherwise | Standard |

### 3. Check Verification Status

**Trivial tier:**
- Verification: `git diff --cached` inspection
- No LOG.md record required

**Standard tier:**
- Check LOG.md for recent verification record
- If missing, warn and ask: "Standard tier — add verification record to LOG.md?"

**Critical tier:**
- Require verification record in LOG.md
- Require explicit user confirmation

### 4. Determine Checkpoint Level

| Indicator | Level |
|-----------|-------|
| `--full` flag | Full |
| Significant decision made | Full (ask user) |
| Session boundary | Full |
| Otherwise | Lightweight |

### 5. Compose Commit Message

**Lightweight format:**
```
[type]: [summary]

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Full format:**
```
[type]: [summary]

[Details if provided]

Session: [YYYY-MM-DD HH:MM session title from LOG.md]
Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

Infer type from changes:
- New files/functions → `feat`
- Bug fixes, error handling → `fix`
- Restructuring without behavior change → `refactor`
- Documentation changes → `docs`
- Test additions/changes → `test`
- Config, dependencies, tooling → `chore`

### 6. Execute Commit

```bash
git commit -m "$(cat <<'EOF'
[composed message]
EOF
)"
```

### 7. Report Result

```
## Commit Created

- Hash: [short hash]
- Tier: [Trivial|Standard|Critical]
- Checkpoint: [Lightweight|Full]
- Files: [count]
- Message: [summary]

[If full checkpoint]
Session logged in LOG.md: [session reference]
```

## Verification Record Format

If Standard+ tier needs verification record, guide user to add to LOG.md:

```markdown
## Verification Record
Timestamp: [ISO 8601]
Commit: [pending → will update after commit]
Tier: Standard | Critical

### Automated Checks
- [x] Build: [command] -> pass
- [x] Tests: [command] -> N/M passed

### Criteria Verification
- [x] [Criterion]: [evidence]

### Scope Verification
- [x] Diff within boundaries: yes
- [x] No unrelated changes: yes
```

## Full Checkpoint LOG.md Entry

If full checkpoint, ensure LOG.md has session entry:

```markdown
## Session [YYYY-MM-DD HH:MM] — [brief title]

### Accomplished
- [What was done]

### Decisions
- [Choice]: [Rationale]

### State
- Git: clean (committed)
- Verification: [tier] tier passed

### Next
- [What to do next]
```

## Examples

### Simple commit (trivial tier)
```
User: /commit fix typo in README

Claude: ## Commit Created
- Hash: abc123f
- Tier: Trivial
- Checkpoint: Lightweight
- Files: 1
- Message: docs: fix typo in README
```

### Multi-file commit (standard tier)
```
User: /commit

Claude: Analyzing staged changes...
- 3 files changed
- ~45 lines modified
- Tier: Standard

No verification record found in LOG.md.
Standard tier requires verification. Options:
1. Add verification record now
2. Proceed anyway (not recommended)
3. Cancel

User: 1

Claude: [Guides through verification record, then commits]
```

### Full checkpoint
```
User: /commit --full implemented user authentication

Claude: ## Full Checkpoint

Adding LOG.md session entry...
[Creates or appends session entry]

## Commit Created
- Hash: def456a
- Tier: Critical
- Checkpoint: Full
- Files: 5
- Session: 2024-01-31 14:30 — User authentication implementation
```

## Error Handling

| Error | Response |
|-------|----------|
| No staged changes | "Nothing staged. Use `git add` first." |
| Critical without verification | "Critical tier requires verification record. Add to LOG.md first." |
| Merge conflict | "Resolve conflicts before committing." |

## Integration

### With pre-commit hook
The pre-commit hook will still run and provide warnings. This skill handles verification proactively.

### With /session-end
If committing at session end, prefer `/session-end` which handles LOG.md entry and commit together.
