# Auto-Fill PR Description with Epic/Story/UC Context

Extract relevant documentation from the codebase and fill PR description with epic, stories, and use case information.

## Instructions

### Step 1: Get Branch & PR Info
```bash
BRANCH=$(git branch --show-current)
# Extract epic number from branch: feature/epic-5-voting → 5
```

### Step 2: Extract Epic Information
Read `_bmad-output/epics.md` and find the section matching the epic number:
- Look for `## Epic N:` or `## Epic NA:` (e.g., Epic 5, Epic 2A)
- Extract: **Goal**, **FRs covered**, **Key Decisions**
- List all stories under that epic

### Step 3: Extract Story Details
For each story in the epic:
- Extract story title and user story (As a... I want... So that...)
- Extract acceptance criteria
- Note technical implementation details

### Step 4: Find Related Use Cases
From the stories, find UC-XX references and look them up in `docs/use-cases.md`:
- Extract use case titles and brief descriptions
- Group by category

### Step 5: Check Git Changes
```bash
git diff main...HEAD --stat
git log main..HEAD --oneline
```
- List files changed
- List commits included

### Step 6: Generate PR Description
Create PR body in this format:

```markdown
## Summary
{One-line epic goal}

## Epic: {Epic N - Title}
**Goal:** {epic goal}
**FRs Covered:** {FR-1, FR-2, ...}

## Stories Implemented
{For each story:}
### Story N.M: {Title}
- **User Story:** As a {role}, I want {action}, So that {benefit}
- **Key ACs:** {bullet list of acceptance criteria}

## Related Use Cases
| UC ID | Title | Category |
|-------|-------|----------|
| UC-XX.Y | {title} | {category} |

## Technical Changes
- **Files Changed:** {count}
- **Key Components:** {list affected modules}

## Key Decisions
{From epic Key Decisions section}

## Test Plan
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing of ACs
```

### Step 7: Update PR Description
If PR already exists:
```bash
gh pr edit --body "$(cat pr_body.md)"
```

If creating new PR, output the description for use with `gh pr create`.

### Step 8: Update Labels & Milestone
Create labels and milestone if they don't exist, then apply to PR:

```bash
# Create epic label if missing
gh label create "epic-{N}" --description "Epic {N}: {Title}" --color "0E8A16" 2>/dev/null || true

# Create UC label if missing (based on related use cases)
gh label create "UC-{XX}" --description "Use Case: {Category}" --color "1D76DB" 2>/dev/null || true

# Create milestone if missing
gh api repos/{owner}/{repo}/milestones --method POST \
  -f title="Epic {N}: {Title}" \
  -f description="{Epic goal}" 2>/dev/null || true

# Apply labels and milestone to PR
gh pr edit --add-label "epic-{N},UC-{XX},enhancement" --milestone "Epic {N}: {Title}"
```

**Label conventions:**
- `epic-{N}` - Green (#0E8A16) - Epic identifier
- `UC-{XX}` - Blue (#1D76DB) - Primary use case category
- `enhancement` - Standard GitHub label for new features

### Step 9: Announce via TTS
```bash
.claude/hooks/play-tts.sh "PR description filled with Epic {N} context, labels and milestone applied"
```

## Example Usage
- `/pr-fill` - Auto-detect epic from branch name
- `/pr-fill 5` - Use Epic 5 regardless of branch

## Source Files
- `_bmad-output/epics.md` - Epic definitions and stories
- `docs/use-cases.md` - Use case catalog (508 UCs)
- `docs/functional-requirements.md` - FR details
- `docs/CLAUDE.md` - Naming conventions
