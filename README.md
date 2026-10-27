# claude-skills

My Claude Code skills, published as a plugin marketplace so every machine and devcontainer gets the same version.

| Skill | Run as | What it does |
| --- | --- | --- |
| `review` | `/dev:review` | Code review in numbered rounds, saved as a review document. Asks whether custom code should exist when the platform already provides it. |
| `canonicalize` | `/dev:canonicalize` | Sweeps existing code for hand-written logic a built-in replaces, and fixes 5–10 cases per PR. |
| `pr-description` | `/dev:pr-description` | Writes a PR description from the branch diff. |

## Install

```bash
claude plugin marketplace add gatezh/claude-skills
claude plugin install dev@gatezh
```

Auto-update is off by default for third-party marketplaces. Turn it on in `/plugin` → **Marketplaces** → `gatezh` → **Enable auto-update**, or declare the marketplace in settings:

```json
{
  "extraKnownMarketplaces": {
    "gatezh": {
      "source": { "source": "git", "url": "https://github.com/gatezh/claude-skills.git" },
      "autoUpdate": true
    }
  }
}
```

The `git` source with an HTTPS URL clones without a GitHub SSH key. The `owner/repo` shorthand tries SSH first, and background updates don't fall back to HTTPS.

## Editing

The plugin has no `version`, so every commit is a release: installs update when the commit changes.

To edit with live reload, add the marketplace from a local clone instead (`claude plugin marketplace add ~/Code/claude-skills`). Claude Code then reads the files in place, and an edit takes effect at the next session or after `/reload-plugins`.

Check the manifests after editing them. Validating the marketplace file also checks the plugin's `plugin.json`; `validate .` checks only the plugin:

```bash
claude plugin validate .claude-plugin/marketplace.json
```

The `No version specified` warning is expected: the plugin has no `version` on purpose.
