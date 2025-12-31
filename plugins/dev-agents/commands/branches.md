---
description: View, cleanup, and manage git branches
argument: action (cleanup, cleanup-remote, delete <branch>)
---

# Branch Management

View, cleanup, and manage git branches.

## Instructions

### Step 1: Show Branch Overview
```bash
echo "=== Current Branch ==="
git branch --show-current

echo "=== Local Branches ==="
git branch -v

echo "=== Remote Branches ==="
git branch -r --list 'origin/*' | head -20
```

### Step 2: Find Stale Branches
Branches merged into main:
```bash
echo "=== Merged into main (safe to delete) ==="
git branch --merged main | grep -v "^\*\|main"
```

Branches with no recent commits (>30 days):
```bash
echo "=== Stale branches (no commits in 30+ days) ==="
for branch in $(git branch --format='%(refname:short)'); do
  last_commit=$(git log -1 --format='%ci' "$branch" 2>/dev/null)
  if [[ -n "$last_commit" ]]; then
    days_ago=$(( ($(date +%s) - $(date -d "$last_commit" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S %z" "$last_commit" +%s)) / 86400 ))
    if [[ $days_ago -gt 30 ]]; then
      echo "  $branch ($days_ago days old)"
    fi
  fi
done
```

### Step 3: Cleanup Options
Based on $ARGUMENTS:

**`/branches`** - Show overview only

**`/branches cleanup`** - Interactive cleanup:
1. List merged branches
2. Ask user to confirm deletion
3. Delete confirmed branches:
   ```bash
   git branch -d <branch>
   ```

**`/branches cleanup-remote`** - Prune deleted remote branches:
```bash
git remote prune origin
git fetch --prune
```

**`/branches delete <name>`** - Delete specific branch:
```bash
git branch -d <name>  # Safe delete (must be merged)
# or
git branch -D <name>  # Force delete
```

### Step 4: Announce Result
```bash
.claude/hooks/play-tts.sh "Branch cleanup complete"
```

## Usage
- `/branches` - Show branch overview
- `/branches cleanup` - Clean merged branches
- `/branches cleanup-remote` - Prune remote tracking branches
- `/branches delete feature/old-branch` - Delete specific branch
