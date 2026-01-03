#!/bin/bash
# agent-recovery.sh - Track and recover interrupted agents
#
# Provides:
# - Agent state tracking (running agents, their tasks, IDs)
# - Context exhaustion detection
# - Recovery state persistence
# - Auto-resume capabilities

# shellcheck source=common.sh
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
source "$SCRIPT_DIR/common.sh" 2>/dev/null || true

# File paths
AGENTS_FILE=""
RECOVERY_FILE=""

# Initialize file paths
init_agent_files() {
    local work_dir
    work_dir="$(get_work_dir 2>/dev/null || echo ".")"
    mkdir -p "$work_dir"
    AGENTS_FILE="$work_dir/.running-agents.json"
    RECOVERY_FILE="$work_dir/.recovery-state.json"
}

# === Running Agents Tracking ===

# Register a running agent
# Usage: register_agent "agent_id" "agent_type" "task_description"
register_agent() {
    local agent_id="$1"
    local agent_type="$2"
    local task="$3"
    local timestamp
    timestamp=$(get_timestamp 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

    init_agent_files

    # Read existing agents or create empty array
    local agents="[]"
    if [[ -f "$AGENTS_FILE" ]]; then
        agents=$(cat "$AGENTS_FILE" 2>/dev/null || echo "[]")
    fi

    # Escape task for JSON
    local escaped_task
    escaped_task=$(printf '%s' "$task" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')

    # Add new agent entry
    local new_agent="{\"id\":\"$agent_id\",\"type\":\"$agent_type\",\"task\":\"$escaped_task\",\"started\":\"$timestamp\",\"status\":\"running\"}"

    # Append to array (simple approach - works for our use case)
    if [[ "$agents" == "[]" ]]; then
        agents="[$new_agent]"
    else
        agents="${agents%]}, $new_agent]"
    fi

    echo "$agents" > "$AGENTS_FILE"
    log_debug "Registered agent: $agent_id ($agent_type)" 2>/dev/null || true
}

# Mark agent as completed
# Usage: complete_agent "agent_id" ["result_summary"]
complete_agent() {
    local agent_id="$1"
    local result="${2:-completed}"

    init_agent_files

    if [[ ! -f "$AGENTS_FILE" ]]; then
        return 0
    fi

    # Remove the agent from the running list
    # Simple grep-based removal (works for our JSON structure)
    local temp_file="${AGENTS_FILE}.tmp"
    grep -v "\"id\":\"$agent_id\"" "$AGENTS_FILE" > "$temp_file" 2>/dev/null || true

    # Fix JSON array if needed
    if [[ -s "$temp_file" ]]; then
        # Clean up any trailing commas and fix array
        sed 's/,\s*]/]/g; s/\[\s*,/[/g' "$temp_file" > "$AGENTS_FILE"
    else
        echo "[]" > "$AGENTS_FILE"
    fi
    rm -f "$temp_file"

    log_debug "Completed agent: $agent_id ($result)" 2>/dev/null || true
}

# Get list of running agents
# Returns JSON array of running agents
get_running_agents() {
    init_agent_files

    if [[ -f "$AGENTS_FILE" ]]; then
        cat "$AGENTS_FILE"
    else
        echo "[]"
    fi
}

# Count running agents
count_running_agents() {
    init_agent_files

    if [[ ! -f "$AGENTS_FILE" ]]; then
        echo "0"
        return
    fi

    # Count entries (simple grep approach)
    grep -c '"id":' "$AGENTS_FILE" 2>/dev/null || echo "0"
}

# Check if any agents are running
has_running_agents() {
    local count
    count=$(count_running_agents)
    [[ $count -gt 0 ]]
}

# === Context Exhaustion Detection ===

# Check if context is low based on various signals
# This is called by hooks to detect context exhaustion
# Returns: 0 if context is low, 1 if context is OK
detect_context_low() {
    local last_output="${CLAUDE_LAST_OUTPUT:-}"

    # Signal 1: Explicit "Context low" message in output
    if [[ "$last_output" == *"Context low"* ]] || \
       [[ "$last_output" == *"context low"* ]] || \
       [[ "$last_output" == *"auto-compact"* ]]; then
        return 0
    fi

    # Signal 2: Check for compaction reminders
    if [[ "$last_output" == *"Run /compact"* ]] || \
       [[ "$last_output" == *"/compact to compact"* ]]; then
        return 0
    fi

    # Signal 3: Check for context percentage warnings
    if [[ "$last_output" =~ Context\ left.*:\ ([0-9]+)% ]]; then
        local pct="${BASH_REMATCH[1]}"
        if [[ $pct -le 10 ]]; then
            return 0
        fi
    fi

    return 1
}

# === Recovery State Management ===

# Save recovery state for interrupted work
# Usage: save_recovery_state "reason" "context"
save_recovery_state() {
    local reason="$1"
    local context="${2:-}"
    local timestamp
    timestamp=$(get_timestamp 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

    init_agent_files

    # Get running agents
    local agents
    agents=$(get_running_agents)

    # Get loop state
    local loop_prompt="${LOOP_PROMPT:-}"
    local loop_iteration="${LOOP_ITERATION:-0}"
    local current_item="${CURRENT_ITEM:-}"

    # Escape context for JSON
    local escaped_context
    escaped_context=$(printf '%s' "$context" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | head -c 1000)
    local escaped_reason
    escaped_reason=$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g')
    local escaped_prompt
    escaped_prompt=$(printf '%s' "$loop_prompt" | sed 's/\\/\\\\/g; s/"/\\"/g')
    local escaped_item
    escaped_item=$(printf '%s' "$current_item" | sed 's/\\/\\\\/g; s/"/\\"/g')

    # Create recovery state JSON
    cat > "$RECOVERY_FILE" << EOF
{
  "timestamp": "$timestamp",
  "reason": "$escaped_reason",
  "loop_prompt": "$escaped_prompt",
  "loop_iteration": $loop_iteration,
  "current_item": "$escaped_item",
  "running_agents": $agents,
  "context": "$escaped_context",
  "needs_recovery": true
}
EOF

    log_info "Saved recovery state: $reason" 2>/dev/null || true
    echo "Recovery state saved to work/.recovery-state.json"
}

# Check if recovery is needed
needs_recovery() {
    init_agent_files

    if [[ ! -f "$RECOVERY_FILE" ]]; then
        return 1
    fi

    # Check if needs_recovery flag is true
    grep -q '"needs_recovery": true' "$RECOVERY_FILE" 2>/dev/null
}

# Get recovery state as human-readable summary
get_recovery_summary() {
    init_agent_files

    if [[ ! -f "$RECOVERY_FILE" ]]; then
        echo "No recovery state found."
        return
    fi

    echo "## Recovery State"
    echo ""

    # Parse JSON manually (portable)
    local reason timestamp loop_prompt agents_count
    reason=$(grep '"reason":' "$RECOVERY_FILE" | sed 's/.*"reason": *"\([^"]*\)".*/\1/' | head -1)
    timestamp=$(grep '"timestamp":' "$RECOVERY_FILE" | sed 's/.*"timestamp": *"\([^"]*\)".*/\1/' | head -1)
    loop_prompt=$(grep '"loop_prompt":' "$RECOVERY_FILE" | sed 's/.*"loop_prompt": *"\([^"]*\)".*/\1/' | head -1)
    agents_count=$(grep -c '"id":' "$RECOVERY_FILE" 2>/dev/null || echo "0")

    echo "- **Time:** $timestamp"
    echo "- **Reason:** $reason"
    if [[ -n "$loop_prompt" ]]; then
        echo "- **Task:** $loop_prompt"
    fi
    echo "- **Interrupted agents:** $agents_count"
    echo ""
    echo "Use \`/loop\` to resume work."
}

# Clear recovery state after successful resume
clear_recovery_state() {
    init_agent_files

    if [[ -f "$RECOVERY_FILE" ]]; then
        # Mark as recovered but keep for reference
        if sed -i.bak 's/"needs_recovery": true/"needs_recovery": false/' "$RECOVERY_FILE" 2>/dev/null; then
            rm -f "${RECOVERY_FILE}.bak"
        else
            # Fallback for systems where -i requires different syntax
            local temp_content
            temp_content=$(sed 's/"needs_recovery": true/"needs_recovery": false/' "$RECOVERY_FILE")
            echo "$temp_content" > "$RECOVERY_FILE"
        fi

        log_info "Recovery state cleared" 2>/dev/null || true
    fi

    # Clear running agents list
    echo "[]" > "$AGENTS_FILE"
}

# === Recovery Actions ===

# Generate recovery instructions for Claude
generate_recovery_prompt() {
    init_agent_files

    if ! needs_recovery; then
        return
    fi

    echo ""
    echo "## 🔄 Context Recovery Required"
    echo ""

    local reason loop_prompt
    reason=$(grep '"reason":' "$RECOVERY_FILE" | sed 's/.*"reason": *"\([^"]*\)".*/\1/' | head -1)
    loop_prompt=$(grep '"loop_prompt":' "$RECOVERY_FILE" | sed 's/.*"loop_prompt": *"\([^"]*\)".*/\1/' | head -1)

    echo "Previous session was interrupted: **$reason**"
    echo ""

    if [[ -n "$loop_prompt" ]]; then
        echo "**Original task:** $loop_prompt"
        echo ""
    fi

    # List interrupted agents
    if has_running_agents; then
        echo "**Interrupted agents:**"
        # Extract agent info from JSON using parameter expansion
        grep '"type":' "$RECOVERY_FILE" | while read -r line; do
            # Extract type value between quotes after "type":
            local temp="${line#*\"type\":}"
            temp="${temp#*\"}"
            local agent_type="${temp%%\"*}"
            echo "- $agent_type agent"
        done
        echo ""
    fi

    echo "**Recovery action:** Resume the task. Check \`work/\` files for state."
    echo "The previous agents may have completed work that was uncommitted."
    echo ""
    echo "1. Check \`git status\` for uncommitted changes"
    echo "2. Review and commit any completed work"
    echo "3. Continue with remaining tasks"
    echo ""
}

# === CLI Interface ===

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        register)
            register_agent "$2" "$3" "$4"
            echo "Agent registered: $2"
            ;;
        complete)
            complete_agent "$2" "$3"
            echo "Agent completed: $2"
            ;;
        list)
            get_running_agents
            ;;
        count)
            count_running_agents
            ;;
        save-state)
            save_recovery_state "$2" "$3"
            ;;
        check-recovery)
            if needs_recovery; then
                echo "Recovery needed"
                get_recovery_summary
            else
                echo "No recovery needed"
            fi
            ;;
        clear-recovery)
            clear_recovery_state
            echo "Recovery state cleared"
            ;;
        recovery-prompt)
            generate_recovery_prompt
            ;;
        detect-context-low)
            if detect_context_low; then
                echo "Context is LOW"
                exit 0
            else
                echo "Context is OK"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 {register|complete|list|count|save-state|check-recovery|clear-recovery|recovery-prompt|detect-context-low}"
            echo ""
            echo "Agent Tracking:"
            echo "  register <id> <type> <task>  - Register a running agent"
            echo "  complete <id> [result]       - Mark agent as completed"
            echo "  list                         - List running agents (JSON)"
            echo "  count                        - Count running agents"
            echo ""
            echo "Recovery:"
            echo "  save-state <reason> [context] - Save recovery state"
            echo "  check-recovery               - Check if recovery needed"
            echo "  clear-recovery               - Clear recovery state"
            echo "  recovery-prompt              - Generate recovery instructions"
            echo ""
            echo "Detection:"
            echo "  detect-context-low           - Check if context is exhausted"
            ;;
    esac
fi
