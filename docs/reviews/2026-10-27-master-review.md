# claude-skills — review (master @ cd2349b)

Whole repository reviewed: `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `README.md`, `skills/review`, `skills/canonicalize`, `skills/pr-description`. No plan or spec exists; reviewed against the intent stated in the README and the first commit (publish the three skills as an auto-updating plugin for the host and devcontainers).

Checked against Claude Code 2.1.311 (installed) and the current docs: [Skills](https://code.claude.com/docs/en/skills), [Plugin manifest reference](https://code.claude.com/docs/en/plugins/manifest-reference), [Marketplace reference](https://code.claude.com/docs/en/plugins/marketplace-reference.md), [Host and maintain a marketplace](https://code.claude.com/docs/en/plugins/host-marketplace.md). Git 2.50.1, gh CLI.

## Review Round 1

### Summary
The packaging is canonical: marketplace and plugin manifests match the docs, commit-based versioning works as intended, and the `review` and `canonicalize` skills are clean. The problem is `pr-description`: its hand-written `detect-repo.sh`, run through `eval`, allows command injection from a repository's branch name and can produce the wrong diff. `gh` and the documented skill features (`!` context injection, `allowed-tools`) replace the script. The rest are small fixes: the README's validate command misses the marketplace file, the repo has no license, and one stale `/review` reference.

### Important

#### 1. `pr-description` runs `eval` on unsanitized git output: command injection
`skills/pr-description/SKILL.md:16`, `skills/pr-description/scripts/detect-repo.sh:23`

The skill tells Claude to run `eval "$(bash …/detect-repo.sh)"`. When the repo has no local `master` or `main`, the script prints `BASE=` followed by the remote's default-branch name, taken unquoted from `git symbolic-ref`. Git ref names may contain `$`, `(`, `)` and `>`, so the branch name becomes shell code inside `eval`.

**Probe:** `git check-ref-format --branch 'x$(date>PWNED)'` accepts the name. I cloned a repo whose default branch has that name and ran the skill's command, and it created `PWNED` with the output of `date`. Anyone who controls a repo you open a PR from (a fork, a third-party project) controls that branch name.

**Fix:** delete the script and the `eval`; see the native replacement in #2.

#### 2. `pr-description` diffs against a possibly stale local base branch
`skills/pr-description/scripts/detect-repo.sh:18-22`, `skills/pr-description/SKILL.md:25-35`

The script picks the local `master` (else `main`) whenever one exists, and the skill diffs `$BASE...HEAD`. If local `master` is behind the remote, the merge base is old, and the description includes other people's commits. The skill's fallback ("if the diff is empty, fetch") only catches the empty case, not this one. The script also prefers a local `master` over the repo's real default branch, and under `set -euo pipefail` its `ERROR: Could not determine base branch` line never prints: the failing `git symbolic-ref | sed` pipeline exits first (probe: exit 128, no message).

**Probe:** the remote `master` gained commit `b-on-master` after the clone; a feature branch was cut from `github/master`. `git log $BASE...HEAD` with the script's `BASE=master` listed `b-on-master` as part of the change.

**Fix (native):** `gh` already resolves the base repository (fork-aware, honoring `gh repo set-default`) and its default branch. Fetching by URL removes the remote-name heuristic (`github` vs `origin`) and the stale-ref problem entirely. Inject the result with the skill's documented `!` syntax and pre-approve it with `allowed-tools`, so it runs before Claude sees the skill:

```markdown
---
name: pr-description
description: …
allowed-tools: Bash(gh repo view *) Bash(git fetch *) Bash(git diff *) Bash(git log *)
---

Base branch and repository: !`gh repo view --json defaultBranchRef,url --jq '.defaultBranchRef.name + " " + .url'`

## Step 1: Get the diff
Fetch the base fresh and diff against it, never against a local branch:

    git fetch -q <url> <base>
    git diff FETCH_HEAD...HEAD
    git log --oneline FETCH_HEAD..HEAD
```

Verified on `gatezh/devcontainers` branch `feat/claude-skills-plugin`: it returns `master https://github.com/gatezh/devcontainers`, and `git log FETCH_HEAD..HEAD` shows exactly the PR's one commit. It works even though that clone's `origin` uses an SSH key that needs confirmation (Secretive), because the fetch goes over HTTPS with `gh`'s credentials. This deletes `scripts/detect-repo.sh` (32 lines) and the stale-base fallback paragraph. The `/path/to/this/skill/` placeholder goes with it; for any future bundled script, the documented form is `${CLAUDE_SKILL_DIR}/scripts/…`, also usable in `allowed-tools`.

### Minor

#### 3. The README's validate command doesn't check `marketplace.json`
`README.md:38-42`

`claude plugin validate .` treats a folder that holds both manifests as a plugin and says so: "This folder also holds a marketplace manifest… these checks cover only the plugin in this folder." Passing the marketplace file instead validates the catalog **and** each relative-path plugin's `plugin.json` (Marketplace reference, "Validation messages": `plugins[i] plugin.json →`).

**Probe:** `claude plugin validate .claude-plugin/marketplace.json` reports `plugins[0] plugin.json → version`, which `validate .` doesn't. **Fix:** document `claude plugin validate .claude-plugin/marketplace.json`, and note that the `version` warning is expected (see Checked and correct).

#### 4. Public repository without a license
`.claude-plugin/plugin.json`, repo root

With no `LICENSE`, the default is all rights reserved: others may read the skills but not reuse them, which undercuts publishing them. `plugin.json` has a `license` field (SPDX identifier, Manifest reference "Fields"). **Fix:** add an MIT `LICENSE` and `"license": "MIT"`, matching the MIT label on every gatezh/devcontainers image. This is a decision for you; MIT is the recommendation.

#### 5. `canonicalize` still calls the review skill `/review`
`skills/canonicalize/SKILL.md:16`

As a plugin skill it's `/dev:review` (Skills docs, "namespaced as `/plugin-name:skill-name`"). In surgegate/template and estimate-tool, `/review` now runs those projects' older copy, which lacks the cost bullet. **Fix:** write `/dev:review`.

### Nits
- `.claude-plugin/marketplace.json:10`: the entry's `description` duplicates `plugin.json`'s. For a relative-path source Claude Code reads `plugin.json` before install, and an entry display field overrides it, so two copies can drift. Keep it in `plugin.json` only.
- No `.gitignore`. The host skill folders already contained `.DS_Store` files (removed before the first commit), and the host now loads skills from this clone, so Finder will recreate them. Add `.DS_Store`.
- `README.md:22-33`: the `extraKnownMarketplaces` example uses a `github` source and then needs a paragraph about `CLAUDE_CODE_PLUGIN_PREFER_HTTPS`. A `git` source with `https://github.com/gatezh/claude-skills.git`, as the devcontainer managed settings use, needs neither.

### Native-first audit
| Custom piece | Built-in checked (where) | Verdict |
| --- | --- | --- |
| `detect-repo.sh` (remote and base detection) | `gh repo view --json defaultBranchRef,url` + `git fetch <url>` (probe above) | **Replace** (#1, #2) |
| `eval "$(bash …)"` to pass values into the session | `!` context injection (Skills docs, "Dynamic context injection") | **Replace** (#2) |
| `/path/to/this/skill/` placeholder | `${CLAUDE_SKILL_DIR}` substitution (Skills docs, "String substitutions") | **Replace**, removed with the script (#2) |
| Bash permission prompts for the skill's commands | `allowed-tools` frontmatter (Skills docs) | **Adopt** (#2) |
| No `version`, commits as releases | Documented "Omit `version`: users track your commits" (Host a marketplace) | **Keep**: verified, the container cache dir is `dev/cd2349b4fa45` |
| Plugin at the marketplace root (`"source": "./"`) | Documented root-plugin form (Marketplace reference, submodules section) | **Keep**: no submodules, one plugin |

### Checked and correct
- **Manifests:** `marketplace.json` has the required `name`, `owner`, `plugins` and the recommended `description`; `gatezh` and `dev` are not reserved names. `plugin.json` fields are all valid. The only `validate --strict` failure is the missing `version`, which is deliberate.
- **Skills:** `claude plugin validate skills` passes. All frontmatter keys are documented; descriptions are well under the 1,536-character listing cap; each `SKILL.md` is under 500 lines.
- **`disable-model-invocation: true` on `canonicalize`** fits: it edits code and opens PRs, so it should run only when asked.
- **`canonicalize` → `../review/SKILL.md`:** resolves in the plugin layout (sibling folders); relative links to supporting files are the documented pattern.
- **README claims:** auto-update off by default for third-party marketplaces, the `/plugin` toggle, in-place loading from a local-path marketplace, and commit-tracking without `version` all match the docs.
- **Security and privacy:** no secrets, personal paths, client names or work email in the repo or its history (author is the GitHub noreply address). `review` and `canonicalize` run no scripts.
- **Cost:** no CI, no paid services.

## Round 1 resolution

| # | Done | Verified |
| --- | --- | --- |
| 1 | Deleted `scripts/detect-repo.sh` and the `eval`. Nothing in the skill passes repo data through a shell any more. | The injection path no longer exists: the base comes from `gh` as data injected into the prompt, and the commands take it as arguments. |
| 2 | `pr-description` injects base and URL with `` !`gh repo view --json defaultBranchRef,url …` ``, fetches by URL and diffs `FETCH_HEAD...HEAD`; `git log` uses `FETCH_HEAD..HEAD` (the old `$BASE...HEAD` log also listed base-only commits). `allowed-tools` pre-approves `gh repo view`, `git fetch`, `git diff`, `git log`. | Ran `claude -p "/dev:pr-description" --model haiku` on gatezh/devcontainers `feat/claude-skills-plugin`: it fetched `https://github.com/gatezh/devcontainers master` (the injected values), `permission_denials: []`, and the description covers exactly the PR's one commit. |
| 3 | README documents `claude plugin validate .claude-plugin/marketplace.json` and that the `version` warning is expected. | Command passes with only the expected `version` warning. |
| 4 | Added MIT `LICENSE` and `"license": "MIT"` in `plugin.json`. | `claude plugin validate` passes. |
| 5 | `canonicalize` refers to `/dev:review`. | — |
| Nit | Dropped the duplicate `description` from the marketplace entry. | `plugin.json` still carries it; validate passes. |
| Nit | Added `.gitignore` with `.DS_Store`. | — |
| Nit | README example uses the `git` HTTPS source; the `CLAUDE_CODE_PLUGIN_PREFER_HTTPS` paragraph is gone. | Same source shape the devcontainer managed settings use, tested there on 2026-10-26. |
