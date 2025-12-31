# PR Status Dashboard

Check the status of PR #$ARGUMENTS (or current branch's PR if no number provided).

## Instructions

1. **Get PR details:**
   ```bash
   gh pr view $ARGUMENTS --json number,title,state,author,isDraft,mergeable,mergeStateStatus,reviewDecision,additions,deletions,changedFiles
   ```

2. **Get CI check status:**
   ```bash
   gh pr checks $ARGUMENTS
   ```

3. **Summarize the results:**
   - PR title, number, and state (open/closed/merged)
   - Author and draft status
   - Merge status (mergeable, conflicts, blocked)
   - Review decision (approved, changes requested, pending)
   - CI checks: count passed/failed/pending
   - Changes: +additions/-deletions in N files

4. **Announce via TTS:**
   - If all checks pass: `.claude/hooks/play-tts.sh "PR $NUMBER: all checks passed"`
   - If failures: `.claude/hooks/play-tts.sh "PR $NUMBER: $FAIL_COUNT checks failed"`
   - If pending: `.claude/hooks/play-tts.sh "PR $NUMBER: $PENDING_COUNT checks pending"`

5. **Show actionable next steps** if there are issues (failing checks, review needed, conflicts).
