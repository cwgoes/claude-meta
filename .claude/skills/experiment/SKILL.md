---
name: experiment
description: Manage git worktrees for parallel project work
constitution: CLAUDE.md
alignment:
  - Work Modes / Experiments
---

# /experiment

Manage git worktrees for working on a project in parallel across multiple branches.

## Invocation

```
/experiment <name> [--from <branch>]   # Create and/or enter experiment
/experiment --list                      # List experiments for current project
/experiment --exit                      # Exit to parent project directory
/experiment --end [--merge|--pr|--discard]  # End experiment
```

## Overview

Experiments are git worktrees. They contain the full project structure (OBJECTIVE.md, LOG.md, etc.) on a separate branch. Use `/project-start` after entering an experiment — it works identically.

## Subcommands

### Create/Enter: `/experiment <name> [--from <branch>]`

Creates a worktree if it doesn't exist, then changes to that directory.

**Protocol:**

1. **Resolve project context**
   - Read current session state or detect from working directory
   - Must be in a project with a git repository
   - Error if not: "Not in a project. Use /project-start first."

2. **Determine paths**
   - Project directory: `[workspace]/projects/[project]/`
   - Experiment directory: `[workspace]/projects/[project]-exp-[name]/`
   - Branch name: `exp/[name]`

3. **Check if experiment exists**
   - If worktree exists at experiment directory, skip to step 6

4. **Validate** (if creating)
   - Warn if uncommitted changes in current directory
   - Verify base branch exists (default: current branch)

5. **Create worktree**
   ```bash
   cd [project_dir]
   git worktree add ../[project]-exp-[name] -b exp/[name] [base-branch]
   ```

6. **Enter experiment**
   - Change working directory to experiment worktree
   - Create `.experiment` marker (for detection):
     ```json
     {
       "parent_project": "projects/[project]",
       "parent_branch": "[base-branch]",
       "experiment_name": "[name]"
     }
     ```

7. **Output confirmation**

**Output (created):**
```
## Created Experiment: [name]

Branch: exp/[name] (from [base-branch])
Path: projects/[project]-exp-[name]/

Working directory changed.
Use /project-start [project] to orient (works the same as in main project).

To end: /experiment --end
```

**Output (entered existing):**
```
## Entered Experiment: [name]

Branch: exp/[name]
Path: projects/[project]-exp-[name]/
Commits ahead of [parent-branch]: [N]

Working directory changed.
```

### List: `/experiment --list`

Lists all experiments (worktrees) for the current project.

**Protocol:**
1. Get project directory from session state or current directory
2. Run `git worktree list` from project directory
3. Filter to show experiment worktrees (exp/* branches)
4. For each, count commits ahead of parent branch

**Output:**
```
## Experiments for [project]

| Name | Branch | Commits Ahead | Path |
|------|--------|---------------|------|
| redis | exp/redis | 3 | projects/[project]-exp-redis |
| cache | exp/cache | 0 | projects/[project]-exp-cache |

Enter: /experiment <name>
End:   /experiment --end (from within experiment)
```

If no experiments exist:
```
## Experiments for [project]

No experiments found.

Create: /experiment <name>
```

### Exit: `/experiment --exit`

Returns to the parent project directory without ending the experiment.

**Protocol:**
1. Verify in an experiment (`.experiment` marker exists in current directory)
2. Read parent project path from marker
3. Change working directory to parent
4. Output confirmation

**Output:**
```
## Exited Experiment: [name]

Experiment preserved. Re-enter with: /experiment [name]
Working directory: projects/[project]/
```

**Error if not in experiment:**
```
Not in an experiment. Nothing to exit.
```

### End: `/experiment --end [--merge|--pr|--discard]`

Ends the experiment by merging, creating a PR, or discarding.

**Protocol:**

1. **Verify context**
   - Must be in experiment worktree (`.experiment` marker exists)
   - Must have clean working tree (no uncommitted changes)

2. **Gather state**
   - Read `.experiment` for parent info
   - Count commits ahead of parent branch
   - Get commit summaries for merge message

3. **Prompt if no action specified**
   ```
   ## End Experiment: [name]

   Branch: exp/[name]
   Commits: [N] ahead of [parent-branch]

   Recent commits:
   - [hash] [message]
   - [hash] [message]

   Options:
   1. **Merge** — Merge to [parent-branch]
   2. **PR** — Push and create pull request
   3. **Discard** — Delete branch and worktree
   4. **Cancel** — Keep working

   Which option?
   ```

4. **Execute action**

   **--merge:**
   ```bash
   parent_dir="[parent project path]"
   exp_dir="[experiment path]"
   branch="exp/[name]"

   cd "$parent_dir"
   git merge "$branch" --no-ff -m "Merge experiment: [name]

   [commit summaries]

   Co-Authored-By: Claude <noreply@anthropic.com>"

   git worktree remove "$exp_dir"
   git branch -d "$branch"
   ```

   **--pr:**
   ```bash
   git push -u origin exp/[name]
   gh pr create --base [parent-branch] --head exp/[name] \
     --title "Experiment: [name]" \
     --body "$(cat <<'EOF'
   ## Summary
   [generated from commits]

   ## Commits
   [list]

   ---
   Generated with Claude Code
   EOF
   )"
   ```
   Output PR URL. Worktree remains for continued work.

   **--discard:**
   ```bash
   cd "$parent_dir"
   git worktree remove --force "$exp_dir"
   git branch -D "exp/[name]"
   ```

5. **Return to parent** (for merge/discard)
   - Change working directory to parent project

**Output (merge):**
```
## Experiment Merged: [name]

Merged [N] commits to [parent-branch]
Worktree removed: projects/[project]-exp-[name]/
Branch deleted: exp/[name]

Working directory: projects/[project]/
```

**Output (PR):**
```
## Pull Request Created

PR: [URL]
Branch: exp/[name] → [parent-branch]

Worktree preserved for continued work.
After PR merges, run /experiment --end --discard to clean up.
```

**Output (discard):**
```
## Experiment Discarded: [name]

Worktree removed: projects/[project]-exp-[name]/
Branch deleted: exp/[name]

Working directory: projects/[project]/
```

## Error Handling

| Condition | Response |
|-----------|----------|
| Not in a project | "Not in a project. Use /project-start first." |
| Experiment already exists | Enter it (no error) |
| Not in experiment (for --exit/--end) | "Not in an experiment." |
| Uncommitted changes (for --end merge/pr) | "Uncommitted changes. Commit or stash first." |
| Merge conflict | Abort merge, report conflicts, stay in experiment |
| No git remote (for --pr) | "No remote configured. Push manually or use --merge." |

## Implementation Notes

### Detecting Project Context

Check in order:
1. Session state at `.claude/sessions/[session_id]/context-state.json`
2. Current directory contains OBJECTIVE.md
3. Parent directory is `projects/` and current dir has OBJECTIVE.md

### Detecting Experiment Context

Check for `.experiment` file in current working directory.

### Working Directory Changes

Use Bash `cd` command to change directories. This persists for the session.

### The .experiment Marker

Created in experiment root on first entry:
```json
{
  "parent_project": "projects/alpha",
  "parent_branch": "main",
  "experiment_name": "redis-cache",
  "created": "2024-01-15T10:30:00Z"
}
```

**Gitignore handling:** When creating the marker, check if `.experiment` is in the project's `.gitignore`. If not, add it:
```bash
# In experiment worktree
if ! grep -q "^\.experiment$" .gitignore 2>/dev/null; then
    echo ".experiment" >> .gitignore
fi
```

This ensures the marker is local metadata only and doesn't get committed to the branch.
