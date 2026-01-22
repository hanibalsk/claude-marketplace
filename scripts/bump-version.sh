#!/usr/bin/env bash
# bump-version.sh - Bump plugin version in plugin.json and marketplace.json
#
# Usage:
#   ./scripts/bump-version.sh <plugin-name> <new-version>
#   ./scripts/bump-version.sh <plugin-name> patch|minor|major
#
# Examples:
#   ./scripts/bump-version.sh k8s-toolkit 1.2.0
#   ./scripts/bump-version.sh k8s-toolkit patch    # 1.1.0 -> 1.1.1
#   ./scripts/bump-version.sh k8s-toolkit minor    # 1.1.0 -> 1.2.0
#   ./scripts/bump-version.sh k8s-toolkit major    # 1.1.0 -> 2.0.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $*"; }
log_err() { echo -e "${RED}[✗]${NC} $*" >&2; }

usage() {
    cat << 'EOF'
Usage: bump-version.sh <plugin-name> <version|patch|minor|major>

Arguments:
  plugin-name    Name of the plugin (directory name in plugins/)
  version        Either a semver version (e.g., 1.2.0) or: patch, minor, major

Examples:
  ./scripts/bump-version.sh k8s-toolkit 1.2.0
  ./scripts/bump-version.sh dev-agents patch
  ./scripts/bump-version.sh pr-toolkit minor
EOF
    exit 1
}

# Increment version
increment_version() {
    local version="$1"
    local type="$2"

    IFS='.' read -r major minor patch <<< "$version"

    case "$type" in
        major) echo "$((major + 1)).0.0" ;;
        minor) echo "${major}.$((minor + 1)).0" ;;
        patch) echo "${major}.${minor}.$((patch + 1))" ;;
        *) echo "$type" ;;  # Assume it's a version string
    esac
}

# Validate semver
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_err "Invalid version format: $version (expected: X.Y.Z)"
        exit 1
    fi
}

# Main
[[ $# -lt 2 ]] && usage

PLUGIN_NAME="$1"
VERSION_ARG="$2"

PLUGIN_DIR="$REPO_ROOT/plugins/$PLUGIN_NAME"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

# Validate plugin exists
if [[ ! -d "$PLUGIN_DIR" ]]; then
    log_err "Plugin not found: $PLUGIN_NAME"
    echo "Available plugins:"
    ls -1 "$REPO_ROOT/plugins/"
    exit 1
fi

if [[ ! -f "$PLUGIN_JSON" ]]; then
    log_err "plugin.json not found: $PLUGIN_JSON"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(grep -o '"version": *"[^"]*"' "$PLUGIN_JSON" | head -1 | sed 's/.*"\([^"]*\)"/\1/')
log_info "Current version: $CURRENT_VERSION"

# Calculate new version
if [[ "$VERSION_ARG" =~ ^(patch|minor|major)$ ]]; then
    NEW_VERSION=$(increment_version "$CURRENT_VERSION" "$VERSION_ARG")
else
    NEW_VERSION="$VERSION_ARG"
fi

validate_version "$NEW_VERSION"

if [[ "$CURRENT_VERSION" == "$NEW_VERSION" ]]; then
    log_warn "Version unchanged: $NEW_VERSION"
    exit 0
fi

log_info "New version: $NEW_VERSION"

# Update plugin.json
if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/\"version\": *\"$CURRENT_VERSION\"/\"version\": \"$NEW_VERSION\"/" "$PLUGIN_JSON"
else
    sed -i "s/\"version\": *\"$CURRENT_VERSION\"/\"version\": \"$NEW_VERSION\"/" "$PLUGIN_JSON"
fi
log_info "Updated: $PLUGIN_JSON"

# Update marketplace.json
if [[ -f "$MARKETPLACE_JSON" ]]; then
    # Find and update the version for this specific plugin
    if grep -q "\"name\": *\"$PLUGIN_NAME\"" "$MARKETPLACE_JSON"; then
        # Use awk for more precise update (only update version after matching plugin name)
        awk -v plugin="$PLUGIN_NAME" -v old="$CURRENT_VERSION" -v new="$NEW_VERSION" '
            /"name":/ && $0 ~ "\"" plugin "\"" { found=1 }
            found && /"version":/ {
                gsub("\"" old "\"", "\"" new "\"")
                found=0
            }
            { print }
        ' "$MARKETPLACE_JSON" > "${MARKETPLACE_JSON}.tmp" && mv "${MARKETPLACE_JSON}.tmp" "$MARKETPLACE_JSON"
        log_info "Updated: $MARKETPLACE_JSON"
    else
        log_warn "Plugin not found in marketplace.json"
    fi
fi

echo ""
log_info "Version bumped: $PLUGIN_NAME $CURRENT_VERSION → $NEW_VERSION"
echo ""
echo "Next steps:"
echo "  git add -A && git commit -m \"chore($PLUGIN_NAME): bump version to $NEW_VERSION\""
