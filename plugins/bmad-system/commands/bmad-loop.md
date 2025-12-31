---
description: Run BMAD epics in autonomous loop (requires claude-auto-agents plugin)
argument: epic pattern to process (e.g., "7A", "7A 8A", "10.*")
---

# /bmad-loop - Run BMAD Epics in Autonomous Loop

Process BMAD epics continuously using the autonomous loop from claude-auto-agents plugin.

## Usage

```
/bmad-loop [epic-pattern]
/bmad-loop "7A 8A 10B"
/bmad-loop "sprint-12.*"
```

## Requirements

This command requires the `claude-auto-agents` plugin to be installed for autonomous loop functionality.

## Behavior

1. Scans for BMAD epic files matching the pattern
2. Adds each epic as a work item to `work/queue.md`
3. Starts the autonomous loop
4. For each epic:
   - Creates feature branch
   - Implements stories with TDD
   - Runs code review
   - Creates PR
   - Monitors CI and fixes issues
   - Merges when approved
5. Continues to next epic until queue empty

## Epic Discovery

Epics are found in:
- `_bmad-output/epics/`
- `_bmad-output/stories/epic-*/`
- `docs/epics/`

## Work Queue Format

Each epic is added to the queue as:
```markdown
- [ ] **[EPIC-{id}]** Implement epic {id}: {title}
  - Priority: high
  - Agent: bmad-orchestrator
```

## Monitoring

```bash
# Check loop status
/status

# View queue
/queue list

# Stop the loop
/stop
```

## Example

```
# Process all epics in sprint 12
/bmad-loop "sprint-12.*"

# Process specific epics
/bmad-loop "7A 8A"

# Process all available epics
/bmad-loop
```

## STATUS Signal

```
STATUS: COMPLETE | BLOCKED | WAITING | ERROR
SUMMARY: Brief description of epic processing status
FILES: comma-separated list of changed files
NEXT: Next epic to process or completion message
BLOCKER: Reason if blocked (e.g., CI failure, review required)
```
