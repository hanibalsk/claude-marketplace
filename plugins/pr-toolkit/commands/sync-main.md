---
description: Sync current feature branch with latest changes from main
argument: strategy (rebase, merge) - optional, auto-detects
---

# Sync Current Branch with Main

Safely synchronize the current feature branch with the latest changes from main.

## Instructions

### Step 1: Check Current State
```bash
BRANCH=$(git branch --show-current)
git status --short
```

Verify:
- No uncommitted changes (or stash them)
- Not on main branch

### Step 2: Fetch Latest
```bash
git fetch origin main
```

### Step 3: Determine Sync Strategy
Check if branch has been pushed:
```bash
git rev-parse --abbrev-ref @{upstream} 2>/dev/null
```

- If pushed: Use `git merge origin/main` (safer for shared branches)
- If local only: Use `git rebase origin/main` (cleaner history)

### Step 4: Perform Sync
```bash
# For rebase (local branches):
git rebase origin/main

# For merge (pushed branches):
git merge origin/main --no-edit
```

### Step 5: Handle Conflicts
If conflicts occur:
1. List conflicting files: `git diff --name-only --diff-filter=U`
2. Show conflict details for each file
3. Ask user how to proceed:
   - Resolve manually
   - Accept theirs: `git checkout --theirs <file>`
   - Accept ours: `git checkout --ours <file>`
   - Abort: `git rebase --abort` or `git merge --abort`

### Step 6: Verify & Announce
```bash
git log --oneline -5
```

Announce via TTS:
```bash
.claude/hooks/play-tts.sh "Branch synced with main successfully"
```

## Usage
- `/sync-main` - Sync current branch with origin/main
- `/sync-main rebase` - Force rebase strategy
- `/sync-main merge` - Force merge strategy
