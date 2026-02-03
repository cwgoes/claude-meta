---
name: commit
description: Create a git commit with proper verification and message format
constitution: CLAUDE.md
alignment:
  - Checkpoint Model
  - Verification Tiers
  - Core Invariants / Evidence Invariant
---

# /commit

Create a properly formatted git commit with verification tier awareness.

## Invocation

```
/commit [message]
```

- `message` — Optional commit message summary. If omitted, will be inferred from staged changes.

**Note:** All commits require a LOG.md entry (created before the commit). The entry can be brief for incremental progress.

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
- LOG.md entry required (can be brief)

**Standard tier:**
- Check LOG.md for recent verification record
- If missing, warn and ask: "Standard tier — add verification record to LOG.md?"

**Critical tier:**
- Require verification record in LOG.md
- Require explicit user confirmation

### 4. Ensure LOG.md Entry Exists

Before committing, verify LOG.md has an entry for this work:
- If no entry exists, create one (can be brief for incremental progress)
- Entry must be saved before git commit so it's included in the commit

### 5. Compose Commit Message

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
- Files: [count]
- Message: [summary]
- Session: [LOG.md session reference]
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

Claude: Adding LOG.md entry...

## Commit Created
- Hash: abc123f
- Tier: Trivial
- Files: 1
- Message: docs: fix typo in README
- Session: 2024-01-31 10:00 — Typo fix
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

Claude: [Guides through verification record, creates LOG.md entry, then commits]
```

### Significant work commit
```
User: /commit implemented user authentication

Claude: Adding LOG.md session entry...

## Commit Created
- Hash: def456a
- Tier: Critical
- Files: 5
- Message: feat: implemented user authentication
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
