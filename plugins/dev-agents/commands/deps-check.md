# Check Dependencies

Check for outdated dependencies across all project components.

## Instructions

### Step 1: Announce Start
```bash
.claude/hooks/play-tts.sh "Checking dependencies across all platforms"
```

### Step 2: Check Rust Dependencies
```bash
echo "=== Rust Dependencies (backend) ==="
cd backend
cargo outdated 2>/dev/null || echo "Install with: cargo install cargo-outdated"
```

### Step 3: Check Node Dependencies
```bash
echo "=== Node Dependencies (frontend) ==="
cd frontend
pnpm outdated 2>/dev/null || npm outdated 2>/dev/null
```

### Step 4: Check Kotlin Dependencies
```bash
echo "=== Kotlin Dependencies (mobile-native) ==="
cd mobile-native
./gradlew dependencyUpdates 2>/dev/null || echo "Plugin not configured"
```

### Step 5: Security Audit
```bash
echo "=== Security Audit ==="

# Rust
echo "Rust security:"
cd backend
cargo audit 2>/dev/null || echo "Install with: cargo install cargo-audit"

# Node
echo "Node security:"
cd frontend
pnpm audit 2>/dev/null || npm audit 2>/dev/null
```

### Step 6: Summary
Provide summary:
- Total outdated packages per platform
- Critical security issues (if any)
- Recommended updates

### Step 7: Announce Result
```bash
.claude/hooks/play-tts.sh "Dependency check complete. X packages need updates."
```

## Usage
- `/deps-check` - Check all dependencies
- `/deps-check rust` - Check only Rust
- `/deps-check node` - Check only Node
- `/deps-check kotlin` - Check only Kotlin
- `/deps-check security` - Run security audits only
