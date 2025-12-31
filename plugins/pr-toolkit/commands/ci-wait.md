---
description: Wait for all CI checks to complete on a PR
argument: PR number (optional, defaults to current branch's PR)
---

# Wait for CI Completion

Wait for all CI checks to complete on PR #$ARGUMENTS (or current branch's PR).

## Instructions

1. **Get initial status:**
   ```bash
   gh pr checks $ARGUMENTS
   ```

2. **Poll until complete:**
   - Check every 30 seconds
   - Count: passed, failed, pending
   - Continue while pending > 0
   - Maximum wait: 10 minutes (20 iterations)

3. **During polling, show progress:**
   - "Waiting for CI... X passed, Y pending"
   - Update count on each poll

4. **When complete, announce via TTS:**
   - All pass: `.claude/hooks/play-tts.sh "CI complete! All $PASS_COUNT checks passed"`
   - With failures: `.claude/hooks/play-tts.sh "CI complete with $FAIL_COUNT failures"`

5. **Show final summary:**
   - List all checks with status
   - Highlight any failures with details
   - If all passed, suggest "Ready to merge" if reviews are approved

## Example Usage
- `/ci-wait` - Wait for current branch's PR
- `/ci-wait 4` - Wait for PR #4
