---
name: pr-description
description: Writes pull request descriptions. Use when creating a PR, writing a PR description, drafting a PR, or when the user asks to summarize changes for a pull request. Also triggers on phrases like "describe these changes", "what changed on this branch", or "PR summary".
allowed-tools:
  - Bash(gh repo view *)
  - Bash(git fetch *)
  - Bash(git diff *)
  - Bash(git log *)
---

# PR Description

Write a clear, concise pull request description based on the actual diff of the current branch.

## Step 1: Get the diff

Base branch and repository URL, as `gh` resolves them (it follows `gh repo set-default`, so forks diff against the right repo): !`gh repo view --json defaultBranchRef,url --jq '.defaultBranchRef.name + " " + .url'`

Fetch that base fresh and diff against `FETCH_HEAD`. Never diff against a local base branch: it may be stale and pull in other people's commits. Fetching by URL also avoids guessing the remote's name.

```bash
git fetch -q <url> <base>
git diff FETCH_HEAD...HEAD
git log --oneline FETCH_HEAD..HEAD
```

## Step 2: Write the description

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
