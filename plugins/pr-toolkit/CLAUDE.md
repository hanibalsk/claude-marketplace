# PR Toolkit

PR lifecycle management and code review workflows.

## Agents

| Agent | Description |
|-------|-------------|
| `pr-shepherd` | Monitors PR status and guides through lifecycle |
| `pr-manager` | Creates and manages pull requests |
| `pr-lifecycle-shepherd` | Full PR lifecycle from creation to merge |
| `code-reviewer` | Code quality and best practices review |
| `security-reviewer` | Security-focused code review |
| `merge-conflict-resolver` | Resolves git merge conflicts |
| `review-comment-handler` | Addresses PR review comments |

## Skills

- **receiving-code-review/** - Process and respond to code review feedback
- **requesting-code-review/** - Dispatch code for review

## Commands

- `/pr-fill` - Auto-fill PR description from commits
- `/pr-status` - Check PR status and CI checks
- `/ci-wait` - Wait for CI checks to complete
- `/sync-main` - Sync current branch with main

## Usage

Spawn agents for specific PR tasks:
```
/spawn pr-shepherd "monitor PR #123 and fix any issues"
/spawn code-reviewer "review the authentication changes"
/spawn merge-conflict-resolver "resolve conflicts in feature-branch"
```
