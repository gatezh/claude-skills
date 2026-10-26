---
name: pr-description
description: Writes pull request descriptions. Use when creating a PR, writing a PR description, drafting a PR, or when the user asks to summarize changes for a pull request. Also triggers on phrases like "describe these changes", "what changed on this branch", or "PR summary".
---

# PR Description

Write a clear, concise pull request description based on the actual diff of the current branch.

## Step 1: Detect repo conventions

Run the detection script to determine the correct remote and base branch. Do NOT hardcode `origin` or `main` — this script handles it:

```bash
eval "$(bash /path/to/this/skill/scripts/detect-repo.sh)"
```

This sets `$REMOTE` and `$BASE` for use in subsequent commands.

## Step 2: Get the diff

```bash
git diff $BASE...HEAD
```

If the diff is empty, the local base branch is probably stale. Fetch and retry:

```bash
git fetch $REMOTE $BASE
git diff $REMOTE/$BASE...HEAD
```

Also gather the commit log for additional context:

```bash
git log $BASE...HEAD --oneline
```

## Step 3: Write the description

Use this format:

```
## What
One sentence explaining what this PR does.

## Why
Brief context on why this change is needed.

## Changes
- Bullet points of specific changes made
- Group related changes together
- Mention any files deleted or renamed
```

Keep it concise. Don't repeat the diff — summarize intent and impact. If there are migration steps, breaking changes, or things reviewers should pay attention to, add a **## Notes** section.