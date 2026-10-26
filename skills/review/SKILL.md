---
name: review
description: Comprehensive code review of an implementation, saved as a review document with numbered rounds. Checks that the code uses built-in features of the platform, framework and libraries instead of hand-written equivalents, follows the official docs for the installed versions, isn't overengineered, and is secure. Use for "review this", "review round 1", "next review round", "check against the latest docs", "are we using native features", "is this overengineered", or after upgrading a library.
argument-hint: "[round1 | next | continue | address] [PR number | branch | path | guidance]"
---

# Review

**Input:** $ARGUMENTS

- Empty, `round1`, or a target (PR number, branch or path): **round 1**. The default target is the current branch's diff against its base branch, plus uncommitted changes.
- `next` or `continue`: **a follow-up round** on the review document from this conversation. If the conversation has none, use the most recently changed `*-review.md` for this branch.
- `address`, optionally followed by guidance such as "skip the nits": **fix the findings** of the latest round. See [Addressing a round](#addressing-a-round).

The question this review exists to answer is not "does this code work?" but **"should this code exist?"** Reviews tend to check that custom code is used correctly and never ask whether the platform already provides it. Treat that as the main failure mode to prevent.

## 1. Establish context

- Find the document the change implements: a plan, spec, design doc or implementation log. Search the docs folder for the branch name, issue key and changed feature (common places are `docs/superpowers/plans/`, `docs/superpowers/specs/` and `docs/implementation-log/`). Review the code against the intent it states. If there is none, review against the PR description and commit messages.
- Read the diff, and enough of the surrounding code to understand it. Read project instructions (CLAUDE.md, rules, ADRs) so you don't flag a deliberate, documented choice. Do still check whether the premise of that choice is true (see step 3).
- List the dependencies the change touches, with the **installed** version from the lockfile, and the latest published version. "Latest docs" means the docs for the installed version. Separately note newer releases that would help.
- Read the native-first ledger `docs/native-first-audit.md` if it exists (the canonicalize skill writes it). Don't raise a **Keep** verdict again unless the library's installed version has changed since.
- If the change upgrades a dependency, read its changelog for every version in between. List the new features this project could adopt, not only the breaking changes.

## 2. Native-first audit (the core of the review)

Inventory every custom piece the change adds or keeps: helpers, hooks, middleware, validators, wrappers, regexes, polling or retry loops, caches, state machines, raw SQL, hand-rolled parsing or formatting, workaround comments. For each one:

1. **Ask what owns this job.** Check, in order: the language and its standard library, the platform or runtime, the framework, the libraries already installed, and finally a well-maintained library not yet installed.
2. **Check the source of truth, not memory.** Read the installed package's types and options (`*.d.ts`, config schemas, plugin lists), then its official docs and changelog. If a docs-fetching skill or a docs MCP server is available, use it. Training data lags behind current releases, so an option you don't remember may still exist.
3. **Before writing "the library can't do X", read where its extension points run** in the library source. A callback may run earlier or later than its name suggests.
4. **Ask whether the custom piece exists only because of a changeable product or UX decision.** If reordering a flow would let the built-in work, say so, and estimate how much code the change would remove.

Examples of the pattern, to show what to look for. This is not a checklist.

- A sign-up email-domain allowlist hand-written as a database hook, through several review rounds, when the auth library had a built-in option for validating user info. The reviews checked that the hook was correct and never asked whether the option existed.
- A polling loop built from `setInterval`, visibility listeners, refs and a custom error class, when the installed data-fetching library already has `refetchInterval`, `refetchOnWindowFocus` and serialized mutations. The custom loop also caused race bugs.
- Raw upsert SQL beside an ORM that has `onConflictDoUpdate`, or a hand-written CORS handler in a framework that ships `cors()` middleware.
- A project rule that said "don't use the built-in X because of bug Y", when the bug had been fixed in the installed version. Probe such rules, don't trust them.

## 3. Canonical and current

- Compare each API usage with the current official docs for the installed version. Flag deprecated APIs, legacy patterns the docs now advise against, and options with a newer recommended replacement.
- Check for a documented "recommended way" for the task, such as an official guide, an example, or a starter template, and compare against it.
- Verify project-doc rules that steer the implementation against the installed version. A rule written for an older version can be the cause of the non-canonical code.

## 4. Simplification and cost

- Recurring cost higher than the requirement needs: CI jobs on premium runners (macOS, Windows, larger sizes) or triggered twice (`push` plus `pull_request` on the same commit), paid services or tiers, oversized cloud resources. Give the cost and the cheaper alternative.
- Indirection that doesn't earn its keep: single-use abstractions, config for one case, layers that only forward calls, generics or types more complex than the problem.
- Code built for hypothetical future needs.
- Duplicate logic, dead code, defensive checks for states that can't happen.
- Code that a step 2 finding would delete. Count it as a simplification too.

## 5. Security

Check what applies to the change: authentication and authorization on every entry point, including the paths that skip the main check (websockets, webhooks, background jobs, admin routes); input validation at trust boundaries; injection (SQL, HTML/XSS, shell, path, header); secrets in code, logs or the client bundle; CSRF, CORS and cookie flags; rate limiting and enumeration on auth flows; tenant and ownership checks on data access; error messages that leak internals; and dependency advisories. Prefer the framework's or library's security features to custom ones, as in step 2.

## 6. Correctness

Report real bugs: race conditions, unhandled errors, edge cases, performance problems such as queries that grow with data, and wrong assumptions about a library's behavior. Check that the code does what the plan or spec says.

## Working method

- **Verify every finding before you report it.** Each one cites evidence: a docs URL, a file and line in the installed package, a changelog entry, or a probe you ran. Drop anything you couldn't verify, or label it clearly as unverified.
- For a large change, run steps 2, 3 and 5 as parallel subagents, give each the dependency list from step 1, then merge and de-duplicate their findings.
- Don't invent issues. If an area is clean, say so in one line.
- Decide; don't hand back a list of questions. Where a finding involves a real trade-off, give a recommendation and the reason for it.
- Don't edit code during a review round. Fixing is the separate `address` step.

## The review document

**Round 1** creates `<doc>-review.md` next to the document from step 1 (`feature-x.md` becomes `feature-x-review.md`). If there is no such document, use `docs/reviews/YYYY-MM-DD-<branch>-review.md`. Structure:

```markdown
# <Feature> — review (PR #N, ISSUE-KEY)

What was reviewed (branch or PR, against which plan or spec), and the installed versions
every finding was checked against.

## Review Round 1

### Summary
Two or three sentences with the overall verdict, then the issues that matter most.

### Important
#### 1. <Finding as a statement>
`path/file.ts:120-134`
What's wrong, the evidence, and the concrete fix (code, or the exact option or API to use).

### Minor
#### 2. …

### Nits
- …

### Native-first audit
| Custom piece | Built-in checked (where) | Verdict |
| --- | --- | --- |
| `validateDomain` hook | `user.validateUserInfo` (auth lib types, v1.7 docs) | **Replace** (#1) |
| Retry wrapper in `fetchJson` | client `retry` option | **Keep**: built-in can't retry on a 200 with an error body |

### Upgrade opportunities
Features from newer or recently adopted versions worth using. Omit if none.

### Checked and correct
Areas checked with no findings, so the reader knows what was covered.
```

Number findings continuously within a round, so later replies can refer to them by number.

**Follow-up rounds** (`next` / `continue`):

1. Read the whole document, including any response to the previous round, and the code changes since that round.
2. For each earlier finding, record whether it is resolved, and check the fix itself. A fix can be non-canonical or introduce a new problem.
3. If you raise a point again, answer the response that was given. Don't repeat the original concern.
4. Run steps 2–6 again on the code that changed, and append `## Review Round N` with the same structure. Start with a table of the earlier findings and their status.

Finish by giving the document's path and the summary in chat.

## Addressing a round

1. Re-check each finding of the latest round before fixing it. If one turns out wrong, don't apply it; record why instead.
2. Fix the rest, applying any guidance given with `address`. Commit in logical chunks.
3. Append `## Round N resolution` to the review document: one table row per finding number, saying what was done and how it was verified (test, probe), or why it was not done.
