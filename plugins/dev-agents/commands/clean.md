---
description: Remove build artifacts and caches across all project components
argument: scope (all, rust, node, kotlin)
---

# Clean Build Artifacts

Remove build artifacts and caches across all project components.

## Instructions

### Step 1: Announce Start
```bash
.claude/hooks/play-tts.sh "Cleaning build artifacts"
```

### Step 2: Calculate Current Size
```bash
echo "=== Current artifact sizes ==="
du -sh backend/target 2>/dev/null || echo "backend/target: not found"
du -sh frontend/node_modules 2>/dev/null || echo "frontend/node_modules: not found"
du -sh mobile-native/build 2>/dev/null || echo "mobile-native/build: not found"
du -sh mobile-native/.gradle 2>/dev/null || echo "mobile-native/.gradle: not found"
```

### Step 3: Clean Based on Arguments

**`/clean`** - Clean build outputs only (safe):
```bash
# Rust
cd backend && cargo clean

# Node (build outputs, not node_modules)
cd frontend
rm -rf dist .next .turbo

# Kotlin
cd mobile-native && ./gradlew clean
```

**`/clean all`** - Full clean including dependencies:
```bash
# Rust
cd backend && cargo clean

# Node (including node_modules)
cd frontend
rm -rf dist .next .turbo node_modules

# Kotlin
cd mobile-native
./gradlew clean
rm -rf .gradle build
```

**`/clean rust`** - Clean only Rust:
```bash
cd backend && cargo clean
```

**`/clean node`** - Clean only Node:
```bash
cd frontend && rm -rf dist .next .turbo node_modules
```

**`/clean kotlin`** - Clean only Kotlin:
```bash
cd mobile-native && ./gradlew clean && rm -rf .gradle
```

### Step 4: Report Space Freed
```bash
echo "=== Space freed ==="
# Compare before/after
```

### Step 5: Announce Result
```bash
.claude/hooks/play-tts.sh "Cleanup complete. X gigabytes freed."
```

## Usage
- `/clean` - Clean build outputs (keeps dependencies)
- `/clean all` - Full clean including node_modules
- `/clean rust` - Clean only Rust target
- `/clean node` - Clean only Node artifacts
- `/clean kotlin` - Clean only Kotlin build
