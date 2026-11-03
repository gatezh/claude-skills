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

## Step 2: Link any Linear issue

If the work relates to a Linear issue, reference it as a **clickable markdown link** so readers reach it in one click.

**Find the issue ID.** Look for a `TEAM-NUMBER` identifier (e.g. `ENG-123`) in the branch name (`git rev-parse --abbrev-ref HEAD`; Linear branches look like `user/eng-123-…`), the commit log, or what the user told you.

**Build the URL.** If the Linear MCP is available, `get_issue` returns the exact `url` (and the title, useful for the description). Otherwise use `https://linear.app/<workspace>/issue/<ID>`, taking the workspace slug from a Linear URL in the repo, its docs or the conversation. If you can't find the workspace, ask; never guess it.

**Put the magic word directly before the linked ID:**

```
Closes [ENG-123](https://linear.app/<workspace>/issue/ENG-123)
```

The link is one click, and the keyword still fires on merge: Linear reads the ID from the link *text*, so wrapping it in `[…](…)` breaks neither the PR↔issue link nor the auto-close.

- **Closing keywords** move the issue to Done when the PR merges: `Close`/`Closes`/`Closed`, `Fix`/`Fixes`/`Fixed`, `Resolve`/`Resolves`/`Resolved`.
- **Non-closing keywords** link without a state change: `Related to`, `Part of`, `Ref`.
- Use a closing keyword **only when merging completes the issue**. For partial work, link without one (e.g. `Part of [ENG-123](…)`).
- Multiple issues: one keyword and link per issue, e.g. `Closes [ENG-123](…), closes [ENG-124](…)`.
- **Link every issue ID you mention**, not only the keyworded one. Incidental references ("prerequisite for ENG-42", "deferred to ENG-150") must be links too; a body that mixes linked IDs with plain or `code`-wrapped IDs is a defect. Only the associated issues get a keyword; any other mention is a plain link, which navigates but doesn't link the PR or change the issue's state.

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

Closes [ENG-123](https://linear.app/<workspace>/issue/ENG-123)
```

Keep it concise. Don't repeat the diff — summarize intent and impact. Put the `Closes [ID](url)` line at the end of the body; the keyword fires wherever it sits. Drop the line if there's no associated issue — never invent one. If there are migration steps, breaking changes, or things reviewers should pay attention to, add a **## Notes** section.
