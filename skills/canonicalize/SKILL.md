---
name: canonicalize
description: Sweep existing code for hand-written logic that the language, platform, framework or an installed library already provides, or that departs from the current official docs, and replace the 5–10 most valuable cases in one small PR. Use for "canonicalize", "go native", "find hand-written code we can replace with built-ins", "bring this up to the latest docs".
argument-hint: "[path or area] [list]"
disable-model-invocation: true
---

# Canonicalize

**Input:** $ARGUMENTS

- A path or area (`services/api`, "auth", "the editing lock") limits the sweep. Default: the whole repository, application code first.
- `list` stops after step 3: it writes the ledger and reports, without changing code.

`/dev:review` checks a diff. This skill checks code that already exists, and fixes what it finds, **5–10 items per run**, so each run is a small PR whose changes are easy to verify and to revert. Run it again for the next batch.

## 1. Inventory

- List the dependencies with their **installed** version (from the lockfile) and the latest published one. Include the runtime and infrastructure settings that decide which platform features exist, such as compatibility dates, runtime flags and framework config.
- Read the ledger `docs/native-first-audit.md` if it exists. Skip pieces marked **Keep** unless the library's installed version has changed since the verdict: a newer version may have added the built-in. Reconsider **Later** items.
- Inventory the custom pieces in scope: helpers, hooks, middleware, validators, wrappers, regexes, polling or retry loops, caches, state machines, raw SQL, hand-rolled parsing or formatting, workaround comments.

## 2. Audit

Judge each piece with steps 2 and 3 of the review skill ([../review/SKILL.md](../review/SKILL.md)): what owns this job, checked against the installed package's types and source and its official docs, not memory. Only a verified built-in or documented canonical approach counts.

For a wide scope, split the inventory by area and audit in parallel subagents, each given the dependency list.

## 3. Pick 5–10

Rank the candidates by value against risk.

- **Value:** code deleted, bugs or races fixed, security gained, a deprecated API removed.
- **Risk:** behavior visible to users, data or schema migrations, public API or auth changes, code without tests.

Pick the 5–10 with the best balance: contained, same behavior, ideally covered by tests. Record the rest as **Later**, with the reason, especially anything that needs a product decision, a migration or wide changes. If fewer than 5 are real, do fewer. Never pad the list.

Then write the ledger (below). With `list`, stop here and report the picks.

## 4. Replace

Work on a new branch, following the repository's branch and worktree conventions. One commit per item:

1. Read the tests that cover the piece. If its behavior isn't pinned by a test, first add one that passes against the current code. It proves the replacement is equivalent.
2. Replace the code with the built-in. Delete the custom code, helpers that are now unused, and tests of internals that no longer exist.
3. Run the affected tests, lint and typecheck.
4. If the built-in differs in a way that matters, or the item grows beyond what was planned, revert it and move it to **Later** with what you learned. Don't force it.

## 5. Record and ship

- Update the ledger, then run the repository's full checks.
- Open one PR following the repository's conventions. For each item, give what was replaced, the built-in, and the evidence (docs URL or file and line in the installed package). Name any behavior change explicitly, even a small one.

## The ledger

`docs/native-first-audit.md` remembers verdicts across runs, so a later sweep doesn't redo settled questions. One table, newest verdict per piece:

```markdown
| Custom piece | Location | Built-in checked (installed version) | Verdict | Date |
| --- | --- | --- | --- | --- |
| Email-domain allowlist hook | `api/src/lib/auth.ts` | `user.validateUserInfo` (better-auth 1.7.7) | **Replaced** (`a1b2c3d`) | 2026-10-13 |
| Retry wrapper in `fetchJson` | `app/src/lib/api.ts` | client `retry` option (ky 1.8.0) | **Keep**: built-in can't retry on a 200 with an error body | 2026-10-13 |
| Raw upsert in `saveDraft` | `api/src/drafts.ts` | `onConflictDoUpdate` (drizzle-orm 0.45.3) | **Later**: needs a unique index, so a migration | 2026-10-13 |
```
