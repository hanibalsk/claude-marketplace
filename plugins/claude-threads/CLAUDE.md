# Claude Threads

Multi-agent threading and git worktree management for parallel agent execution.

## Agents

| Agent | Description |
|-------|-------------|
| `thread-orchestrator` | Thread lifecycle management |
| `chaos-engineer` | Chaos and resilience testing |

## Skills

- **threads/** - Multi-agent threading basics
- **thread-orchestrator/** - Thread lifecycle management
- **thread-spawner/** - Thread creation patterns
- **using-git-worktrees/** - Git worktree management
- **ct-debug/** - Claude Threads debugging

## Commands

- `/threads` - Multi-agent thread management
- `/ct-spawn` - Spawn new Claude Thread
- `/ct-connect` - Connect to remote Claude Thread
- `/ct-debug` - Debug Claude Threads

## How It Works

Claude Threads enables parallel agent execution by:
1. Creating isolated git worktrees for each thread
2. Running agents in separate Claude Code instances
3. Coordinating work through the thread-orchestrator
4. Merging results back to the main branch

## Usage

Spawn parallel threads:
```
/ct-spawn "implement login feature" --branch feature/login
/ct-spawn "add unit tests" --branch test/login
```

Manage threads:
```
/threads status
/threads list
/ct-connect thread-123
```
