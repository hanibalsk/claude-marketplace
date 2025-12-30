# Claude Marketplace

A curated marketplace for Claude Code plugins.

## Installation

Add this marketplace to Claude Code:

```
/plugin marketplace add hanibalsk/claude-marketplace
```

Browse and install plugins:

```
/plugin
```

## Available Plugins

### claude-auto-agents

Minimalist autonomous agent framework using Claude Code hooks.

**Features:**
- `/loop` - Start autonomous iteration loop
- `/stop` - Gracefully stop the loop
- `/status` - Check progress and queue status
- `/queue` - Manage work items
- `/spawn` - Launch specific agent types

**Agents included:**
- `developer` - Feature development with TDD
- `reviewer` - Code review (read-only)
- `fixer` - Fix bugs and CI failures
- `orchestrator` - Autonomous workflow control
- `explorer` - Fast codebase exploration
- `pr-shepherd` - PR lifecycle management
- `conflict-resolver` - Merge conflict resolution

**Install:**
```
/plugin install claude-auto-agents@hanibalsk-marketplace
```

## Adding Plugins

To add a plugin to this marketplace, submit a PR with your plugin added to `.claude-plugin/marketplace.json`.

## License

MIT
